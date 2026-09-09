// -----------------------------------------------------------------------------
// Description:     INT core power test across compute modes and data sparsity (case B3)
// Author:          Mingxuan Li
// Acknowledgement: Claude Code + Claude Fable 5 (silicon rework of the GitHub Copilot +
//                  Gemini-3-Pro simulation skeleton)
// Date:            2026-07-15
// -----------------------------------------------------------------------------
//
// One run = ONE power point: gdb sets the volatile params at the loop
// breakpoint, `jump _start` reruns everything (bss recleared, data regenerated
// from a fixed seed -- deterministic reload per the power cheat-sheet). CPU posture during
// the measurement window is quiet_spin_cycles(), copied verbatim from
// baseline_pwr.c (F3) so the module-minus-baseline subtraction holds.
//
// RTL facts this test relies on (int_core.sv, verified 2026-07-15):
//   - run_mode ctrl[9:8]: FUNC=0 COMPUTE_PWR=1 DMA_PWR=2 ALL_PWR=3; power
//     modes loop forever; writing ctrl=0 flips run_mode to FUNC and the FSM
//     drains the current pass (<~1.4k cycles), sets finish, returns to IDLE.
//   - status: [15:0] pe / [31:16] sf / [47:32] spattn 16b cycle counters,
//     cleared at start, +1 per active cycle, wrap; [51:48] finish bits.
//     Liveness = counter delta != 0 (mod 2^16) for each enabled unit.
//   - SF and SpAttn SHARE one FSM; IDLE arbitration is `if (sf_enable) else
//     if (spattn_enable)` and power modes never revisit IDLE -> sf|spattn
//     both set means SpAttn silently never runs. Standard points therefore
//     use enables=0x3 (PE+SF, the F1 path-A workload posture); the extra
//     SpAttn row uses enables=0x4 alone.
//   - DMA csr: hardware rewrites low 12 bits, CPU owns [63:12]; dst MUST be
//     a private 4K page (note 4 of the test plan) -- drain pass does DMA even from
//     COMPUTE_PWR (FUNC drain path walks the DMA states).
//
// Volatile params (.data, gdb `set var`):
//   pwr_mode     1=COMPUTE_PWR 2=DMA_PWR 3=ALL_PWR
//   sparsity_pct 0 / 50 / 90 (% of elements forced to zero)
//   enables      0x3=PE+SF (standard 9 points), 0x4=SpAttn row
//   spin_cycles  measurement window, default 4.85e9 (~70 s @ 69.26M)
//
// Result area (u64, cleared at start, gdb: x/8gx 0x80007000):
//   0x80007000  DONE      0xB3000000000005A5
//   0x80007008  PROGRESS  1=mode started  2=stopped+harvested
//   0x80007010  PARAM     sparsity<<16 | mode<<8 | enables (echo)
//   0x80007018  CG_RB     0x2000_0020 readback (expect 0x1, X0Y0 only)
//   0x80007020  ST_BEFORE full status word before enable
//   0x80007028  ST_AFTER  full status word after stop+drain
//   0x80007030  DELTA     finish[3:0]<<48 | spattn_d<<32 | sf_d<<16 | pe_d
//   0x80007038  SPIN_RB   spin_cycles used this run
//////////////////////////////////////////////////////////////////////////////////

#include <stdint.h>

// RTL Parameters
#define PE_ARRAY_SIZE 8
#define PE_MAX_ACCUM_NUM 32
#define PE_TILE 4

#define SF_ARRAY_SIZE 8
#define SF_SPATTN_CNT_MAX 128

#define M PE_ARRAY_SIZE
#define N PE_ARRAY_SIZE
#define NUM_TILES PE_TILE
#define K (PE_TILE * PE_MAX_ACCUM_NUM)

#define CG_CONFIG_ADDR 0x20000020UL

#define INT_CORE_BASE 0x60000000UL

#define INT_CORE_MAT0_OFFSET 0x000
#define INT_CORE_MAT1_OFFSET 0x200
#define INT_CORE_SF0_OFFSET  0x500
#define INT_CORE_SF1_OFFSET  0x520
#define INT_CORE_SF0_PRED_OFFSET 0x540
#define INT_CORE_SF1_PRED_OFFSET 0x560
#define INT_CORE_SIGN0_OFFSET    0x600
#define INT_CORE_SIGN1_OFFSET    0x680

#define INT_CORE_CTRL_OFFSET     0xF00
#define INT_CORE_DMA_SRC_OFFSET  0x1008
#define INT_CORE_DMA_DST_OFFSET  0x1010

#define CTRL_REG ((volatile uint64_t *)(INT_CORE_BASE + INT_CORE_CTRL_OFFSET))

// Result area
#define RES_BASE 0x80007000UL
#define R_DONE      ((volatile uint64_t *)(RES_BASE + 0x00))
#define R_PROGRESS  ((volatile uint64_t *)(RES_BASE + 0x08))
#define R_PARAM     ((volatile uint64_t *)(RES_BASE + 0x10))
#define R_CG_RB     ((volatile uint64_t *)(RES_BASE + 0x18))
#define R_ST_BEFORE ((volatile uint64_t *)(RES_BASE + 0x20))
#define R_ST_AFTER  ((volatile uint64_t *)(RES_BASE + 0x28))
#define R_DELTA     ((volatile uint64_t *)(RES_BASE + 0x30))
#define R_SPIN_RB   ((volatile uint64_t *)(RES_BASE + 0x38))

#define DONE_MAGIC 0xB3000000000005A5UL

// gdb-settable per point (pinned .data; jump _start does not reload them)
volatile uint64_t pwr_mode     __attribute__((section(".data"))) = 1;
volatile uint64_t sparsity_pct __attribute__((section(".data"))) = 0;
volatile uint64_t enables      __attribute__((section(".data"))) = 0x3;
volatile uint64_t spin_cycles  __attribute__((section(".data"))) = 4850000000ULL;

// DMA landing page: whole page, 4K-aligned, declared before other bss arrays
// (B2 lesson: nothing may push its alignment; verify low 12 bits with nm)
static uint64_t dma_page[512] __attribute__((aligned(4096)));

// Inputs (bss, regenerated every run)
static int8_t weights[K][N];
static int8_t activations[M][K];
static uint8_t sf0[NUM_TILES][SF_ARRAY_SIZE];
static uint8_t sf1[NUM_TILES][SF_ARRAY_SIZE];
static uint8_t sf0_pred[NUM_TILES][SF_ARRAY_SIZE];
static uint8_t sf1_pred[NUM_TILES][SF_ARRAY_SIZE];
static uint8_t sign0[SF_SPATTN_CNT_MAX][SF_ARRAY_SIZE];
static uint8_t sign1[SF_SPATTN_CNT_MAX][SF_ARRAY_SIZE];

// Pattern config: element sparsity comes from the volatile param each run;
// non-zero elements toggle 50% of bits vs the previous value (skeleton default)
static uint8_t CFG_DATA_SPARSITY;
#define CFG_TOGGLE_RATE 50

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

static uint8_t get_random_uint8(void) {
  lcg_seed = (lcg_seed * 1103515245 + 12345) & 0x7FFFFFFF;
  return (uint8_t)(lcg_seed >> 24);
}

static uint8_t generate_pattern_data(uint8_t *prev_val, int width) {
  uint8_t val = 0;
  uint8_t mask = (1 << width) - 1;

  if ((get_random_uint8() % 100) < CFG_DATA_SPARSITY) {
    val = 0;
  } else {
    uint8_t toggle_mask = 0;
    for (int i = 0; i < width; i++) {
      if ((get_random_uint8() % 100) < CFG_TOGGLE_RATE) {
        toggle_mask |= (1 << i);
      }
    }
    val = (*prev_val ^ toggle_mask) & mask;
  }

  *prev_val = val;
  return val;
}

static void init_data(void) {
  uint8_t prev_val = 0;

  lcg_seed = 20260101;  // reset EVERY run: jump _start keeps old .data/.bss values

  for (int k = 0; k < K; k++)
    for (int j = 0; j < N; j++) {
      uint8_t raw = generate_pattern_data(&prev_val, 4);
      weights[k][j] = (int8_t)(raw >= 8 ? raw - 16 : raw);
    }

  prev_val = 0;
  for (int i = 0; i < M; i++)
    for (int k = 0; k < K; k++) {
      uint8_t raw = generate_pattern_data(&prev_val, 4);
      activations[i][k] = (int8_t)(raw >= 8 ? raw - 16 : raw);
    }

  prev_val = 0;
  for (int t = 0; t < NUM_TILES; t++)
    for (int i = 0; i < SF_ARRAY_SIZE; i++) {
      sf0[t][i] = generate_pattern_data(&prev_val, 8);
      sf1[t][i] = generate_pattern_data(&prev_val, 8);
    }

  prev_val = 0;
  for (int t = 0; t < NUM_TILES; t++)
    for (int i = 0; i < SF_ARRAY_SIZE; i++) {
      sf0_pred[t][i] = generate_pattern_data(&prev_val, 8);
      sf1_pred[t][i] = generate_pattern_data(&prev_val, 8);
    }

  prev_val = 0;
  for (int t = 0; t < SF_SPATTN_CNT_MAX; t++)
    for (int i = 0; i < SF_ARRAY_SIZE; i++) {
      sign0[t][i] = generate_pattern_data(&prev_val, 1) & 1;
      sign1[t][i] = generate_pattern_data(&prev_val, 1) & 1;
    }
}

static void config_dma(void) {
  volatile uint64_t *dma_src = (volatile uint64_t *)(INT_CORE_BASE + INT_CORE_DMA_SRC_OFFSET);
  volatile uint64_t *dma_dst = (volatile uint64_t *)(INT_CORE_BASE + INT_CORE_DMA_DST_OFFSET);
  *dma_src = INT_CORE_BASE;
  *dma_dst = (uint64_t)dma_page;
  // hardware owns low 12 bits; mismatch above bit 12 = wedged csr path,
  // flagged via PARAM echo corruption in the result area readout
  if (((*dma_src) >> 12) != (INT_CORE_BASE >> 12) ||
      ((*dma_dst) >> 12) != (((uint64_t)dma_page) >> 12)) {
    *R_PARAM = 0xDEADD0AUL;
    for (;;) { }  // park; visible as missing DONE + poisoned PARAM
  }
}

static void load_pe(void) {
  volatile uint64_t *pe_weight_buf = (volatile uint64_t *)(INT_CORE_BASE + INT_CORE_MAT0_OFFSET);
  volatile uint64_t *pe_act_buf = (volatile uint64_t *)(INT_CORE_BASE + INT_CORE_MAT1_OFFSET);

  for (int k = 0; k < K / 2; k++) {
    uint64_t two_rows = 0;
    for (int j = 0; j < N; j++)
      two_rows |= ((uint64_t)((uint8_t)weights[2 * k][j] & 0xF)) << (j * 4);
    for (int j = 0; j < N; j++)
      two_rows |= ((uint64_t)((uint8_t)weights[2 * k + 1][j] & 0xF)) << (32 + j * 4);
    pe_weight_buf[k] = two_rows;
  }

  for (int k = 0; k < K / 2; k++) {
    uint64_t two_cols = 0;
    for (int i = 0; i < M; i++)
      two_cols |= ((uint64_t)((uint8_t)activations[i][2 * k] & 0xF)) << (i * 4);
    for (int i = 0; i < M; i++)
      two_cols |= ((uint64_t)((uint8_t)activations[i][2 * k + 1] & 0xF)) << (32 + i * 4);
    pe_act_buf[k] = two_cols;
  }
}

static void load_sf(void) {
  volatile uint64_t *sf0_buf = (volatile uint64_t *)(INT_CORE_BASE + INT_CORE_SF0_OFFSET);
  volatile uint64_t *sf1_buf = (volatile uint64_t *)(INT_CORE_BASE + INT_CORE_SF1_OFFSET);

  for (int t = 0; t < NUM_TILES; t++) {
    uint64_t d0 = 0, d1 = 0;
    for (int i = 0; i < SF_ARRAY_SIZE; i++) {
      d0 |= ((uint64_t)sf0[t][i]) << (i * 8);
      d1 |= ((uint64_t)sf1[t][i]) << (i * 8);
    }
    sf0_buf[t] = d0;
    sf1_buf[t] = d1;
  }
}

static void load_spattn(void) {
  volatile uint64_t *sf0_pred_buf = (volatile uint64_t *)(INT_CORE_BASE + INT_CORE_SF0_PRED_OFFSET);
  volatile uint64_t *sf1_pred_buf = (volatile uint64_t *)(INT_CORE_BASE + INT_CORE_SF1_PRED_OFFSET);
  volatile uint64_t *sign0_buf = (volatile uint64_t *)(INT_CORE_BASE + INT_CORE_SIGN0_OFFSET);
  volatile uint64_t *sign1_buf = (volatile uint64_t *)(INT_CORE_BASE + INT_CORE_SIGN1_OFFSET);

  for (int t = 0; t < NUM_TILES; t++) {
    uint64_t w0 = 0, w1 = 0;
    for (int i = 0; i < SF_ARRAY_SIZE; i++) {
      w0 |= ((uint64_t)sf0_pred[t][i]) << (i * 8);
      w1 |= ((uint64_t)sf1_pred[t][i]) << (i * 8);
    }
    sf0_pred_buf[t] = w0;
    sf1_pred_buf[t] = w1;
  }

  for (int w = 0; w < 16; w++) {
    uint64_t w0 = 0, w1 = 0;
    for (int b = 0; b < 8; b++) {
      int t = w * 8 + b;
      uint8_t byte0 = 0, byte1 = 0;
      for (int i = 0; i < SF_ARRAY_SIZE; i++) {
        if (sign0[t][i]) byte0 |= (1 << i);
        if (sign1[t][i]) byte1 |= (1 << i);
      }
      w0 |= ((uint64_t)byte0) << (b * 8);
      w1 |= ((uint64_t)byte1) << (b * 8);
    }
    sign0_buf[w] = w0;
    sign1_buf[w] = w1;
  }
}

int main(void) {
  volatile uint64_t *r = (volatile uint64_t *)RES_BASE;
  for (int i = 0; i < 8; i++) r[i] = 0;

  // gate on INT X0Y0 only (bit 4Y+X = bit0), B2-style independent gating
  *(volatile uint64_t *)CG_CONFIG_ADDR = 0x1;
  *R_CG_RB = *(volatile uint64_t *)CG_CONFIG_ADDR;
  *R_SPIN_RB = spin_cycles;
  *R_PARAM = (sparsity_pct << 16) | (pwr_mode << 8) | enables;

  CFG_DATA_SPARSITY = (uint8_t)sparsity_pct;
  init_data();
  config_dma();
  load_pe();
  load_sf();
  load_spattn();

  uint64_t st_before = *CTRL_REG;
  *R_ST_BEFORE = st_before;

  *R_PROGRESS = 1;
  *CTRL_REG = enables | (pwr_mode << 8);

  quiet_spin_cycles(spin_cycles);   // measurement window (Rigol reads here)

  *CTRL_REG = 0;                    // stop: FSM drains current pass to IDLE
  quiet_spin_cycles(100000);        // blind wait >> drain time (~1.4k cycles)

  uint64_t st_after = *CTRL_REG;
  *R_ST_AFTER = st_after;

  uint64_t pe_d = (st_after - st_before) & 0xFFFF;
  uint64_t sf_d = ((st_after >> 16) - (st_before >> 16)) & 0xFFFF;
  uint64_t sp_d = ((st_after >> 32) - (st_before >> 32)) & 0xFFFF;
  uint64_t fin  = (st_after >> 48) & 0xF;
  *R_DELTA = (fin << 48) | (sp_d << 32) | (sf_d << 16) | pe_d;

  *R_PROGRESS = 2;
  *R_DONE = DONE_MAGIC;

  return 0;  // falls into startup.S loop (breakpoint = harvest point)
}
