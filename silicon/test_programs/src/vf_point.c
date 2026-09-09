// -----------------------------------------------------------------------------
// Description:     V-F screening point runner for the multi-die campaign: DCO code sweep,
//                  cycle-counter frequency measurement and functional golden test (case F5m)
// Author:          Mingxuan Li
// Acknowledgement: Claude Code + Claude Fable 5
// Date:            2026-07-16
// -----------------------------------------------------------------------------
//
// One ELF replaces the per-code {cpu_fp_func + scaling_pwr pregate +
// baseline_pwr + scaling_pwr formal} load carousel of the die0 F5 flow
// (~15 s of JTAG loads per code). One load per slice; per code the driver
// just sets `phase`/spin vars and `jump _start`.
//
//   phase=1  A1 gate + all40 formal window:
//            a1_lite (the full 27-check FP suite, constants verbatim from
//            cpu_fp_func.c, silicon-proven) -- on any fail: park with
//            PROGRESS=0xDEADF5A1 BEFORE touching accelerators (gate
//            semantics). Then gates=all40 -> gen+load (seed 20260101,
//            scaling_pwr verbatim) -> st_before -> start 32 INT
//            (COMPUTE_PWR, enables 0x3) + 8 FP (mode1+power) ->
//            quiet_spin(spin1) -> stop -> drain -> per-core liveness
//            (changed+drained / FP done; B3/F2 protocol) -> DONE -> loop.
//   phase=2  baseline window + idle anchor: gates=0 -> quiet_spin(spin2) ->
//            DONE -> WFI forever (F3 posture; with tiny spin2 the WFI tail
//            IS the per-voltage idle anchor; mcycle keeps ticking in WFI,
//            silicon-proven, so the driver bracket stays valid).
//
// Volatile params (.data, gdb set var; jump _start does not reload them):
//   phase   1 / 2
//   spin1   all40 window ticks   (driver: win1 x f_est + (code+1)*7919
//                                 + attempt*12345 -- replay-collision salt)
//   spin2   baseline window ticks
//
// Result area (u64, cleared at start, gdb: x/10gx 0x80007000):
//   0x80007000  DONE      0xF5000000000005A5
//   0x80007008  PROGRESS  phase1: 1=a1 ok 2=loaded+started 3=stopped
//                          4=drained 5=checked(final)
//                          phase2: 1=gates off+spinning 2=done (in WFI)
//                          0xDEADF5A1 = a1_lite failed, parked
//   0x80007010  A1_FAIL   a1_lite fail count (expect 0)
//   0x80007018  A1_FF     first a1 fail: id<<32 | fflags readback
//   0x80007020  CG_RB     gate readback (ph1: 0xFF_FFFFFFFF, ph2: 0)
//   0x80007028  ERR_LIVE  liveness violations (expect 0)
//   0x80007030  FF_ID     first violation: type<<8 | idx (1=INT 2=FP)
//   0x80007038  SAMPLE    first core status/CSR after stop
//   0x80007040  SPIN_RB   spin used this run
//   0x80007048  PHASE_RB  phase echo
//////////////////////////////////////////////////////////////////////////////////

#include <stdint.h>

#define CG_CONFIG_ADDR 0x20000020UL
#define INT_BASE(X, Y) (0x60000000UL + ((uint64_t)((X) * 8 + (Y)) << 24))
#define FP_BASE(Y)     (0x50000000UL + ((uint64_t)(Y) << 24))

#define RES_BASE 0x80007000UL
#define R_DONE     ((volatile uint64_t *)(RES_BASE + 0x00))
#define R_PROGRESS ((volatile uint64_t *)(RES_BASE + 0x08))
#define R_A1_FAIL  ((volatile uint64_t *)(RES_BASE + 0x10))
#define R_A1_FF    ((volatile uint64_t *)(RES_BASE + 0x18))
#define R_CG_RB    ((volatile uint64_t *)(RES_BASE + 0x20))
#define R_ERR_LIVE ((volatile uint64_t *)(RES_BASE + 0x28))
#define R_FF_ID    ((volatile uint64_t *)(RES_BASE + 0x30))
#define R_SAMPLE   ((volatile uint64_t *)(RES_BASE + 0x38))
#define R_SPIN_RB  ((volatile uint64_t *)(RES_BASE + 0x40))
#define R_PHASE_RB ((volatile uint64_t *)(RES_BASE + 0x48))

#define DONE_MAGIC 0xF5000000000005A5UL
#define A1_PARKED  0xDEADF5A1UL
#define GATE_ALL40 0xFFFFFFFFFFUL

// PE geometry (B3/F2 identical)
#define M 8
#define N 8
#define K 128
#define NUM_TILES 4

volatile uint64_t phase __attribute__((section(".data"))) = 1;
volatile uint64_t spin1 __attribute__((section(".data"))) = 350000000ULL;
volatile uint64_t spin2 __attribute__((section(".data"))) = 280000000ULL;

// DMA landing page first in bss (B2 alignment lesson); shared/sacrificial
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

// ---------------------------------------------------------------------------
// a1_lite: the full A1 suite (27 checks), constants verbatim from
// cpu_fp_func.c (silicon-proven golden). Fail -> count + first-id only.
// ---------------------------------------------------------------------------
typedef union { float  f; uint32_t u; } fbits;
typedef union { double d; uint64_t u; } dbits;

static void a1_check(int id, uint64_t got, uint64_t exp) {
  if (got != exp) {
    if (*R_A1_FAIL == 0) *R_A1_FF = ((uint64_t)id) << 32;
    *R_A1_FAIL += 1;
  }
}

static void a1_lite(void) {
  __asm__ volatile("csrw fflags, zero");
  fbits a, b, c, res, exp;
  dbits da, db, dc, dres, dexp;

  a.u = 0x3FC00000; b.u = 0x40100000; exp.u = 0x40700000;
  res.f = a.f + b.f;                      a1_check(1, res.u, exp.u);
  a.u = 0x40400000; b.u = 0x40200000; exp.u = 0x40F00000;
  res.f = a.f * b.f;                      a1_check(2, res.u, exp.u);
  a.u = 0x41200000; b.u = 0x40900000; exp.u = 0x40B00000;
  res.f = a.f - b.f;                      a1_check(3, res.u, exp.u);
  a.u = 0x40E00000; b.u = 0x40000000; exp.u = 0x40600000;
  res.f = a.f / b.f;                      a1_check(4, res.u, exp.u);
  a.u = 0x40100000; exp.u = 0x3FC00000;
  __asm__ volatile("fsqrt.s %0, %1" : "=f"(res.f) : "f"(a.f));
  a1_check(5, res.u, exp.u);
  { volatile int vi = 7; res.f = (float)vi; }
  exp.u = 0x40E00000;                     a1_check(6, res.u, exp.u);
  { a.u = 0x40700000; volatile int vo = (int)a.f;
    a1_check(7, (uint32_t)vo, 3); }
  a.u = 0; b.u = 0; exp.u = 0x7FC00000;
  res.f = a.f / b.f;                      a1_check(8, res.u, exp.u);
  a.u = 0x3F800000; b.u = 0; exp.u = 0x7F800000;
  res.f = a.f / b.f;                      a1_check(9, res.u, exp.u);
  a.u = 0x40000000; b.u = 0x40400000; c.u = 0x3FC00000; exp.u = 0x40F00000;
  __asm__ volatile("fmadd.s %0, %1, %2, %3"
                   : "=f"(res.f) : "f"(a.f), "f"(b.f), "f"(c.f));
  a1_check(10, res.u, exp.u);
  a.u = 0x3FC00000; b.u = 0x40000000;
  a1_check(11, (a.f < b.f) ? 1u : 0u, 1u);
  { fbits n; n.u = 0x7FC00000; a.u = 0x3F800000;
    a1_check(12, (n.f < a.f) ? 1u : 0u, 0u); }

  da.u = 0x3FF8000000000000; db.u = 0x4002000000000000;
  dexp.u = 0x400E000000000000;
  dres.d = da.d + db.d;                   a1_check(13, dres.u, dexp.u);
  da.u = 0x4008000000000000; db.u = 0x4004000000000000;
  dexp.u = 0x401E000000000000;
  dres.d = da.d * db.d;                   a1_check(14, dres.u, dexp.u);
  da.u = 0x4024000000000000; db.u = 0x4012000000000000;
  dexp.u = 0x4016000000000000;
  dres.d = da.d - db.d;                   a1_check(15, dres.u, dexp.u);
  da.u = 0x401C000000000000; db.u = 0x4000000000000000;
  dexp.u = 0x400C000000000000;
  dres.d = da.d / db.d;                   a1_check(16, dres.u, dexp.u);
  da.u = 0x4002000000000000; dexp.u = 0x3FF8000000000000;
  __asm__ volatile("fsqrt.d %0, %1" : "=f"(dres.d) : "f"(da.d));
  a1_check(17, dres.u, dexp.u);
  { volatile int vi = 7; dres.d = (double)vi; }
  dexp.u = 0x401C000000000000;            a1_check(18, dres.u, dexp.u);
  { da.u = 0x400E000000000000; volatile int vo = (int)da.d;
    a1_check(19, (uint32_t)vo, 3); }
  a.u = 0x3FC00000; dres.d = (double)a.f;
  dexp.u = 0x3FF8000000000000;            a1_check(20, dres.u, dexp.u);
  da.u = 0x400E000000000000; res.f = (float)da.d;
  exp.u = 0x40700000;                     a1_check(21, res.u, exp.u);
  da.u = 0; db.u = 0; dexp.u = 0x7FF8000000000000;
  dres.d = da.d / db.d;                   a1_check(22, dres.u, dexp.u);
  da.u = 0x3FF0000000000000; db.u = 0; dexp.u = 0x7FF0000000000000;
  dres.d = da.d / db.d;                   a1_check(23, dres.u, dexp.u);
  da.u = 0x4000000000000000; db.u = 0x4008000000000000;
  dc.u = 0x3FF8000000000000; dexp.u = 0x401E000000000000;
  __asm__ volatile("fmadd.d %0, %1, %2, %3"
                   : "=f"(dres.d) : "f"(da.d), "f"(db.d), "f"(dc.d));
  a1_check(24, dres.u, dexp.u);
  da.u = 0x3FF8000000000000; db.u = 0x4000000000000000;
  a1_check(25, (da.d < db.d) ? 1u : 0u, 1u);
  { dbits n; n.u = 0x7FF8000000000000; da.u = 0x3FF0000000000000;
    a1_check(26, (n.d < da.d) ? 1u : 0u, 0u); }
  { uint64_t fl;
    __asm__ volatile("csrr %0, fflags" : "=r"(fl));
    if (*R_A1_FAIL == 0) *R_A1_FF |= fl;
    a1_check(27, fl & 0x18, 0x18u); }
}

// ---------------------------------------------------------------------------
// all40 data gen + load, verbatim from scaling_pwr.c (F2, silicon-proven)
// ---------------------------------------------------------------------------
static uint8_t rnd8(void) {
  lcg_seed = (lcg_seed * 1103515245 + 12345) & 0x7FFFFFFF;
  return (uint8_t)(lcg_seed >> 24);
}

static uint8_t pat(uint8_t *prev, int width) {
  uint8_t mask = (1 << width) - 1, tog = 0;
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

static void load_fp_core(uint64_t base) {
  volatile uint64_t *man = (volatile uint64_t *)(base + 0x0000);
  volatile uint64_t *sf = (volatile uint64_t *)(base + 0x0800);
  lcg_seed = 20260101;
  for (int w = 0; w < 256; w++) {
    uint64_t word = 0;
    for (int e = 0; e < 4; e++) {
      uint16_t m = (uint16_t)((uint32_t)rnd8() << 8 | rnd8());
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
  for (int i = 0; i < 10; i++) r[i] = 0;
  *R_PHASE_RB = phase;

  if (phase == 2) {
    // baseline window + WFI anchor tail (F3 posture)
    *R_SPIN_RB = spin2;
    *(volatile uint64_t *)CG_CONFIG_ADDR = 0;
    *R_CG_RB = *(volatile uint64_t *)CG_CONFIG_ADDR;
    *R_PROGRESS = 1;
    quiet_spin_cycles(spin2);
    *R_DONE = DONE_MAGIC;
    *R_PROGRESS = 2;
    for (;;) asm volatile("wfi");
  }

  // ---- phase 1: A1 gate + all40 formal ----
  *R_SPIN_RB = spin1;
  a1_lite();
  if (*R_A1_FAIL != 0) {
    *R_PROGRESS = A1_PARKED;   // park before touching accelerators
    return 0;
  }
  *R_PROGRESS = 1;

  *(volatile uint64_t *)CG_CONFIG_ADDR = GATE_ALL40;
  *R_CG_RB = *(volatile uint64_t *)CG_CONFIG_ADDR;

  gen_int_data();
  for (int y = 0; y < 8; y++)
    for (int x = 0; x < 4; x++) load_int_core(INT_BASE(x, y));
  for (int y = 0; y < 8; y++) load_fp_core(FP_BASE(y));

  int n = 0;
  for (int y = 0; y < 8; y++)
    for (int x = 0; x < 4; x++)
      st_before[n++] = *(volatile uint64_t *)(INT_BASE(x, y) + 0xF00);

  for (int y = 0; y < 8; y++)
    for (int x = 0; x < 4; x++)
      *(volatile uint64_t *)(INT_BASE(x, y) + 0xF00) = 0x3 | (1UL << 8);
  for (int y = 0; y < 8; y++)
    *(volatile uint64_t *)(FP_BASE(y) + 0x0CD0) = 0x11;  // mode1 + power
  *R_PROGRESS = 2;

  quiet_spin_cycles(spin1);   // measurement window (Rigol reads here)

  for (int y = 0; y < 8; y++)
    for (int x = 0; x < 4; x++)
      *(volatile uint64_t *)(INT_BASE(x, y) + 0xF00) = 0;
  for (int y = 0; y < 8; y++)
    *(volatile uint64_t *)(FP_BASE(y) + 0x0CD0) = 0x01;  // keep mode1
  *R_PROGRESS = 3;
  quiet_spin_cycles(100000);  // drain
  *R_PROGRESS = 4;

  n = 0;
  for (int y = 0; y < 8; y++)
    for (int x = 0; x < 4; x++) {
      uint64_t after = *(volatile uint64_t *)(INT_BASE(x, y) + 0xF00);
      if (n == 0) *R_SAMPLE = after;
      int changed = ((after ^ st_before[n]) & 0xFFFFFFFFUL) != 0;
      int drained = ((after >> 48) & 0x3) == 0x3;
      if (!changed || !drained) {
        (*R_ERR_LIVE)++;
        if (*R_FF_ID == 0) *R_FF_ID = (1UL << 8) | (uint64_t)n;
      }
      n++;
    }
  for (int y = 0; y < 8; y++) {
    uint64_t csr = *(volatile uint64_t *)(FP_BASE(y) + 0x0CD0);
    if (!(csr & 0x4)) {
      (*R_ERR_LIVE)++;
      if (*R_FF_ID == 0) *R_FF_ID = (2UL << 8) | (uint64_t)y;
    }
  }
  *R_PROGRESS = 5;
  *R_DONE = DONE_MAGIC;
  return 0;  // falls into startup.S loop (harvest point)
}
