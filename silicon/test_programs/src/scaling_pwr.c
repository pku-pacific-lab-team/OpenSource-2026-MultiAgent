// -----------------------------------------------------------------------------
// Description:     Full-load power test with 1 INT / 1 FP / 4+1 cluster / all 40 cores and a
//                  data-sparsity knob (cases F2 and F5m)
// Author:          Mingxuan Li
// Acknowledgement: Claude Code + Claude Fable 5
// Date:            2026-07-16 (revised 2026-07-18)
// -----------------------------------------------------------------------------
// Revision 2026-07-18: sparsity_pct added (all40 x sparsity for the F5m
// multi-die campaign); the dense path is bit-identical to the silicon-proven
// original -- the dice draw only exists when sparsity_pct != 0.
//
// Four points, ONLY the instance count moves: INT cores run COMPUTE_PWR with
// enables=0x3 (B3 standard-row posture), FP cores run mode1+power_mode
// (C3 posture, huffman off), all cores get the SAME dense seed-20260101 data.
// sparsity_pct (0/50/90) forces that % of INT weight/act/sf elements and FP
// mantissas to zero (B3/C3 generator semantics); hardware loops replay the
// loaded buffers, so sparsity is purely a data-content knob.
// CPU posture during the window is quiet_spin_cycles(), verbatim from
// baseline_pwr.c (F3). One run = one point (gdb set var + jump _start).
//
// Numbering (B2 silicon-proven): INT address index = X*8+Y, gate bit = 4Y+X
// (two DIFFERENT schemes); FP base = Y<<24, gate bit = 32+Y.
//
// Liveness:
//   INT per core: full status word saved before start; after stop the
//     counter half (pe|sf, low 32b) must have changed AND finish bits
//     [49:48] must read 11 (drained). 1/2^32-ish blind spot accepted.
//   FP per core: done (bit2) must read 1 after clearing bit4 -- power_mode=1
//     auto-clears done at window start (fp_core.sv:330), so a set done bit
//     is fresh, no residue false-positive.
// Violations are counted (not parked) -- ERR_LIVE + FF_ID tell the story.
//
// Volatile params (.data, gdb `set var`):
//   scale_sel   0=1 INT (X0Y0)  1=1 FP (Y0)  2=cluster0 (4 INT + FP Y0)
//               3=all 40 (32 INT + 8 FP)
//   spin_cycles measurement window, default 1.2e9 (~17 s @ 69.26M)
//
// Result area (u64, cleared at start, gdb: x/8gx 0x80007000):
//   0x80007000  DONE      0xF2000000000005A5
//   0x80007008  PROGRESS  1=data 2=loaded 3=running 4=stopped 5=checked
//   0x80007010  PARAM     n_fp<<16 | n_int<<8 | scale_sel
//   0x80007018  CG_RB     0x2000_0020 readback
//   0x80007020  ERR_LIVE  liveness violations (expect 0)
//   0x80007028  FF_ID     first violation: type<<8 | linear idx (1=INT 2=FP)
//   0x80007030  SAMPLE    first enabled core's status/CSR after stop
//   0x80007038  SPIN_RB   spin_cycles used this run
//////////////////////////////////////////////////////////////////////////////////

#include <stdint.h>

#define CG_CONFIG_ADDR 0x20000020UL

#define INT_BASE(X, Y) (0x60000000UL + ((uint64_t)((X) * 8 + (Y)) << 24))
#define FP_BASE(Y)     (0x50000000UL + ((uint64_t)(Y) << 24))

#define RES_BASE 0x80007000UL
#define R_DONE     ((volatile uint64_t *)(RES_BASE + 0x00))
#define R_PROGRESS ((volatile uint64_t *)(RES_BASE + 0x08))
#define R_PARAM    ((volatile uint64_t *)(RES_BASE + 0x10))
#define R_CG_RB    ((volatile uint64_t *)(RES_BASE + 0x18))
#define R_ERR_LIVE ((volatile uint64_t *)(RES_BASE + 0x20))
#define R_FF_ID    ((volatile uint64_t *)(RES_BASE + 0x28))
#define R_SAMPLE   ((volatile uint64_t *)(RES_BASE + 0x30))
#define R_SPIN_RB  ((volatile uint64_t *)(RES_BASE + 0x38))

#define DONE_MAGIC 0xF2000000000005A5UL

// PE geometry (B3 identical)
#define M 8
#define N 8
#define K 128
#define NUM_TILES 4

volatile uint64_t scale_sel   __attribute__((section(".data"))) = 0;
volatile uint64_t spin_cycles __attribute__((section(".data"))) = 1200000000ULL;
volatile uint64_t sparsity_pct __attribute__((section(".data"))) = 0;

// DMA landing page first in bss (B2 alignment lesson); shared by all INT
// cores -- drain collisions are harmless, the page is sacrificial
static uint64_t dma_page[512] __attribute__((aligned(4096)));

static int8_t weights[K][N];
static int8_t activations[M][K];
static uint8_t sf0[NUM_TILES][8];
static uint8_t sf1[NUM_TILES][8];
static uint64_t st_before[32];

static uint32_t lcg_seed;

static inline uint64_t rd_mcycle(void) {
  uint64_t v;
  asm volatile("csrr %0, mcycle" : "=r"(v));
  return v;
}

// Canonical quiet-spin posture, verbatim from baseline_pwr.c (F3)
void quiet_spin_cycles(uint64_t n) {
  uint64_t start = rd_mcycle();
  while ((rd_mcycle() - start) < n) { }
}

static uint8_t rnd8(void) {
  lcg_seed = (lcg_seed * 1103515245 + 12345) & 0x7FFFFFFF;
  return (uint8_t)(lcg_seed >> 24);
}

// toggle-50 pattern (B3 generator); sparsity dice only when sparsity_pct!=0
// so the dense LCG sequence stays bit-identical to the original
static uint8_t pat(uint8_t *prev, int width) {
  uint8_t mask = (1 << width) - 1, tog = 0;
  if (sparsity_pct && (rnd8() % 100) < sparsity_pct) {
    *prev = 0;
    return 0;
  }
  for (int i = 0; i < width; i++)
    if (rnd8() % 100 < 50) tog |= (1 << i);
  *prev = (*prev ^ tog) & mask;
  return *prev;
}

static void gen_int_data(void) {
  uint8_t prev = 0;
  lcg_seed = 20260101;
  for (int k = 0; k < K; k++)
    for (int j = 0; j < N; j++) {
      uint8_t raw = pat(&prev, 4);
      weights[k][j] = (int8_t)(raw >= 8 ? raw - 16 : raw);
    }
  prev = 0;
  for (int i = 0; i < M; i++)
    for (int k = 0; k < K; k++) {
      uint8_t raw = pat(&prev, 4);
      activations[i][k] = (int8_t)(raw >= 8 ? raw - 16 : raw);
    }
  prev = 0;
  for (int t = 0; t < NUM_TILES; t++)
    for (int i = 0; i < 8; i++) {
      sf0[t][i] = pat(&prev, 8);
      sf1[t][i] = pat(&prev, 8);
    }
}

static void load_int_core(uint64_t base) {
  volatile uint64_t *wbuf = (volatile uint64_t *)(base + 0x000);
  volatile uint64_t *abuf = (volatile uint64_t *)(base + 0x200);
  volatile uint64_t *s0 = (volatile uint64_t *)(base + 0x500);
  volatile uint64_t *s1 = (volatile uint64_t *)(base + 0x520);

  for (int k = 0; k < K / 2; k++) {
    uint64_t w = 0;
    for (int j = 0; j < N; j++)
      w |= ((uint64_t)((uint8_t)weights[2 * k][j] & 0xF)) << (j * 4);
    for (int j = 0; j < N; j++)
      w |= ((uint64_t)((uint8_t)weights[2 * k + 1][j] & 0xF)) << (32 + j * 4);
    wbuf[k] = w;
  }
  for (int k = 0; k < K / 2; k++) {
    uint64_t a = 0;
    for (int i = 0; i < M; i++)
      a |= ((uint64_t)((uint8_t)activations[i][2 * k] & 0xF)) << (i * 4);
    for (int i = 0; i < M; i++)
      a |= ((uint64_t)((uint8_t)activations[i][2 * k + 1] & 0xF)) << (32 + i * 4);
    abuf[k] = a;
  }
  for (int t = 0; t < NUM_TILES; t++) {
    uint64_t d0 = 0, d1 = 0;
    for (int i = 0; i < 8; i++) {
      d0 |= ((uint64_t)sf0[t][i]) << (i * 8);
      d1 |= ((uint64_t)sf1[t][i]) << (i * 8);
    }
    s0[t] = d0;
    s1[t] = d1;
  }
  *(volatile uint64_t *)(base + 0x1008) = base;               // DMA src
  *(volatile uint64_t *)(base + 0x1010) = (uint64_t)dma_page; // DMA dst
}

// C3 fill, re-seeded per core so every FP core gets identical data
static void load_fp_core(uint64_t base) {
  volatile uint64_t *man = (volatile uint64_t *)(base + 0x0000);
  volatile uint64_t *sf = (volatile uint64_t *)(base + 0x0800);
  lcg_seed = 20260101;
  for (int w = 0; w < 256; w++) {
    uint64_t word = 0;
    for (int e = 0; e < 4; e++) {
      uint16_t m = 0;
      if (sparsity_pct == 0 || (rnd8() % 100) >= sparsity_pct)
        m = (uint16_t)((uint32_t)rnd8() << 8 | rnd8());
      word |= ((uint64_t)m) << (e * 16);
    }
    man[w] = word;
  }
  lcg_seed = 20260102;
  for (int w = 0; w < 128; w++) {
    uint64_t word = 0;
    for (int e = 0; e < 8; e++)
      word |= ((uint64_t)(rnd8() % 201)) << (e * 8);
    sf[w] = word;
  }
}

int main(void) {
  volatile uint64_t *r = (volatile uint64_t *)RES_BASE;
  for (int i = 0; i < 8; i++) r[i] = 0;

  // enumerate the instance set
  int n_int = 0, n_fp = 0;
  int ix[32], iy[32], fy[8];
  uint64_t gate = 0;
  switch (scale_sel) {
    case 0: n_int = 1; ix[0] = 0; iy[0] = 0; break;
    case 1: n_fp = 1; fy[0] = 0; break;
    case 2:
      for (int x = 0; x < 4; x++) { ix[n_int] = x; iy[n_int] = 0; n_int++; }
      n_fp = 1; fy[0] = 0;
      break;
    default:
      for (int y = 0; y < 8; y++)
        for (int x = 0; x < 4; x++) { ix[n_int] = x; iy[n_int] = y; n_int++; }
      for (int y = 0; y < 8; y++) fy[n_fp++] = y;
      break;
  }
  for (int i = 0; i < n_int; i++) gate |= 1ULL << (4 * iy[i] + ix[i]);
  for (int j = 0; j < n_fp; j++) gate |= 1ULL << (32 + fy[j]);

  *(volatile uint64_t *)CG_CONFIG_ADDR = gate;
  *R_CG_RB = *(volatile uint64_t *)CG_CONFIG_ADDR;
  *R_SPIN_RB = spin_cycles;
  *R_PARAM = (sparsity_pct << 24) | ((uint64_t)n_fp << 16) |
             ((uint64_t)n_int << 8) | scale_sel;

  gen_int_data();
  *R_PROGRESS = 1;

  for (int i = 0; i < n_int; i++) load_int_core(INT_BASE(ix[i], iy[i]));
  for (int j = 0; j < n_fp; j++) load_fp_core(FP_BASE(fy[j]));
  *R_PROGRESS = 2;

  for (int i = 0; i < n_int; i++)
    st_before[i] = *(volatile uint64_t *)(INT_BASE(ix[i], iy[i]) + 0xF00);

  // start everything (fixed order), then the quiet window
  for (int i = 0; i < n_int; i++)
    *(volatile uint64_t *)(INT_BASE(ix[i], iy[i]) + 0xF00) = 0x3 | (1UL << 8);
  for (int j = 0; j < n_fp; j++)
    *(volatile uint64_t *)(FP_BASE(fy[j]) + 0x0CD0) = 0x11;  // mode1 + power
  *R_PROGRESS = 3;

  quiet_spin_cycles(spin_cycles);   // measurement window (Rigol reads here)

  for (int i = 0; i < n_int; i++)
    *(volatile uint64_t *)(INT_BASE(ix[i], iy[i]) + 0xF00) = 0;
  for (int j = 0; j < n_fp; j++)
    *(volatile uint64_t *)(FP_BASE(fy[j]) + 0x0CD0) = 0x01;  // keep mode1
  quiet_spin_cycles(100000);        // drain
  *R_PROGRESS = 4;

  // liveness
  for (int i = 0; i < n_int; i++) {
    uint64_t after = *(volatile uint64_t *)(INT_BASE(ix[i], iy[i]) + 0xF00);
    if (i == 0 && n_int) *R_SAMPLE = after;
    int changed = ((after ^ st_before[i]) & 0xFFFFFFFFUL) != 0;
    int drained = ((after >> 48) & 0x3) == 0x3;
    if (!changed || !drained) {
      (*R_ERR_LIVE)++;
      if (*R_FF_ID == 0) *R_FF_ID = (1UL << 8) | (uint64_t)i;
    }
  }
  for (int j = 0; j < n_fp; j++) {
    uint64_t csr = *(volatile uint64_t *)(FP_BASE(fy[j]) + 0x0CD0);
    if (!n_int && j == 0) *R_SAMPLE = csr;
    if (!(csr & 0x4)) {
      (*R_ERR_LIVE)++;
      if (*R_FF_ID == 0) *R_FF_ID = (2UL << 8) | (uint64_t)j;
    }
  }
  *R_PROGRESS = 5;

  *R_DONE = DONE_MAGIC;
  return 0;  // falls into startup.S loop (breakpoint = harvest point)
}
