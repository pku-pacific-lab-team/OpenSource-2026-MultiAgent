// -----------------------------------------------------------------------------
// Description:     Speculative-prefill engine power test: three engines and all-on envelope (case E3)
// Author:          Mingxuan Li
// Acknowledgement: Claude Code + Claude Fable 5
// Date:            2026-07-16
// -----------------------------------------------------------------------------
//
// One run = one power point (gdb set var + jump _start). CPU posture during
// the window is quiet_spin_cycles(), verbatim from baseline_pwr.c (F3) --
// which also satisfies the E2 CSR-preemption discipline for free: zero SP
// accesses while any engine is running.
//
// RTL facts (spec_prefill_unit.sv, verified 2026-07-16):
//   - CSR 0x3010: [1:0] cmd, [3:2]/[5:4]/[7:6] encoder/predictor/learner
//     power mode: 00=IDLE 01=WORK(needs matching cmd) 10=POWER_TEST(en held
//     1, loops forever, ignores cmd). CPU CSR writes have top mux priority
//     and gate off the engines' own CSR writeback -> writing 0 stops cleanly.
//   - SRAM master mux (lines 238-256) is fixed-priority combinational with
//     NO handshake: CPU(req) > encoder > predictor > learner. Engines are
//     fixed-latency FSMs (<600 cycles/pass), so concurrent POWER_TEST cannot
//     deadlock, BUT with all three on: SRAM traffic is encoder's alone,
//     predictor computes on encoder's read data, and LEARNER WEIGHT WRITES
//     NEVER LAND. The all-engines row is therefore an "all datapaths
//     toggling" envelope, not a sum of three SRAM streams.
//
// Liveness: pre-window encoder vector (token T1 -> history slot0, 32-word
// XOR checksum) must be reproduced bit-exactly by the post-window vector
// (after weight reload); per-engine window evidence = a state word that the
// looping engine should have changed (known blind spots recorded, primary
// evidence is the current elevation vs baseline):
//   engine_sel=0 encoder:   slot1 checksum (window encodes token T2 -> slot1)
//   engine_sel=1 predictor: PRED_OUT (accumulates per pass; blind if
//                            N*delta = 0 mod 2048)
//   engine_sel=2 learner:   weight row0 word (+-1 per pass; blind if N = 0
//                            mod 64)
//   engine_sel=3 all-on:    slot1 checksum + PRED_OUT (learner evidence
//                            physically invalid here, see mux fact above)
//
// Result area (u64, cleared at start, gdb: x/9gx 0x80007000):
//   0x80007000  DONE      0xE3000000000005A5
//   0x80007008  PROGRESS  1=weights 2=pre-vec 3=window 4=stopped 5=post-ok
//                          0xDEADE31=pre status bad  0xDEADE32=post sum bad
//   0x80007010  PARAM     engine_sel<<8 | window CSR value (echo, low byte)
//   0x80007018  CG_RB     0x2000_0020 readback (expect 1<<40)
//   0x80007020  SUM_PRE   pre-vector slot0 checksum
//   0x80007028  EV_BEFORE evidence word before window
//   0x80007030  EV_AFTER  evidence word after window (should differ)
//   0x80007038  SUM_POST  post-vector slot0 checksum (must equal SUM_PRE)
//   0x80007040  ST_RB     STATUS after stop
//////////////////////////////////////////////////////////////////////////////////

#include <stdint.h>

#define CG_CONFIG_ADDR 0x20000020UL

#define SP_BASE 0x40000000UL
#define SP_MEM(off) (*(volatile uint64_t *)(SP_BASE + (off)))
#define SP_TOKEN  (*(volatile uint64_t *)(SP_BASE + 0x3000))
#define SP_PRED_O (*(volatile uint64_t *)(SP_BASE + 0x3008))
#define SP_CSR    (*(volatile uint64_t *)(SP_BASE + 0x3010))
#define SP_STATUS (*(volatile uint64_t *)(SP_BASE + 0x3018))

// window CSR values (cmd=00; POWER_TEST fields only)
#define PT_ENCODER   0x08UL
#define PT_PREDICTOR 0x20UL
#define PT_LEARNER   0x80UL           // + agent0 (bits 9:8 = 0) + reward bit13
#define PT_ALL       (PT_ENCODER | PT_PREDICTOR | PT_LEARNER)

#define RES_BASE 0x80007000UL
#define R_DONE      ((volatile uint64_t *)(RES_BASE + 0x00))
#define R_PROGRESS  ((volatile uint64_t *)(RES_BASE + 0x08))
#define R_PARAM     ((volatile uint64_t *)(RES_BASE + 0x10))
#define R_CG_RB     ((volatile uint64_t *)(RES_BASE + 0x18))
#define R_SUM_PRE   ((volatile uint64_t *)(RES_BASE + 0x20))
#define R_EV_BEFORE ((volatile uint64_t *)(RES_BASE + 0x28))
#define R_EV_AFTER  ((volatile uint64_t *)(RES_BASE + 0x30))
#define R_SUM_POST  ((volatile uint64_t *)(RES_BASE + 0x38))
#define R_ST_RB     ((volatile uint64_t *)(RES_BASE + 0x40))

#define DONE_MAGIC 0xE3000000000005A5UL
#define BLIND_WAIT_CYC 100000UL  // engines take <600 cycles (E2-proven)

#define TOKEN_T1 0x123UL
#define TOKEN_T2 0x3EDUL

volatile uint64_t engine_sel  __attribute__((section(".data"))) = 0;
volatile uint64_t spin_cycles __attribute__((section(".data"))) = 4850000000ULL;

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

static uint32_t lcg(void) {
  lcg_seed = (lcg_seed * 1103515245 + 12345) & 0x7FFFFFFF;
  return lcg_seed;
}

static void park(uint64_t code) {
  *R_PROGRESS = code;
  for (;;) { }
}

// deterministic weight image: 256 rows x 3 parts (E2-proven address formula)
static void load_weights(void) {
  lcg_seed = 20260101;
  for (int row = 0; row < 256; row++)
    for (int p = 0; p < 3; p++)
      SP_MEM(0x1000 + row * 0x20 + p * 8) =
          ((uint64_t)lcg() << 33) ^ ((uint64_t)lcg() << 11) ^ (uint64_t)lcg();
}

// E2 recipe: issue command, then zero SP access for the blind wait
static void run_engine(uint64_t csr_val) {
  SP_CSR = csr_val;
  uint64_t t0 = rd_mcycle();
  while (rd_mcycle() - t0 < BLIND_WAIT_CYC) ;
}

// history slot checksum: slot h lives at rows h*12.. (E2 silicon fact:
// sp_hist_row = {0, 60} for h = {0, 5}); 32 chunks, 3 per row
static uint64_t slot_checksum(int h) {
  uint64_t sum = 0;
  for (int k = 0; k < 32; k++)
    sum ^= SP_MEM((uint64_t)(h * 12 + k / 3) * 0x20 + (uint64_t)(k % 3) * 8);
  return sum;
}

// one encoder WORK pass: token -> history slot h (agent0)
static void encode_once(uint64_t token, uint64_t h) {
  SP_TOKEN = token;
  run_engine(0x1UL | 0x4UL | (h << 10));
}

int main(void) {
  volatile uint64_t *r = (volatile uint64_t *)RES_BASE;
  for (int i = 0; i < 9; i++) r[i] = 0;

  // gate on SP only (bit 40)
  *(volatile uint64_t *)CG_CONFIG_ADDR = (1ULL << 40);
  *R_CG_RB = *(volatile uint64_t *)CG_CONFIG_ADDR;
  SP_CSR = 0;

  uint64_t win_csr;
  switch (engine_sel) {
    case 0:  win_csr = PT_ENCODER; break;
    case 1:  win_csr = PT_PREDICTOR; break;
    case 2:  win_csr = PT_LEARNER | (1UL << 13); break;   // reward=1, agent0
    default: win_csr = PT_ALL | (1UL << 13); break;
  }
  *R_PARAM = (engine_sel << 8) | (win_csr & 0xFF);

  load_weights();
  *R_PROGRESS = 1;

  // pre-vector: token T1 -> slot0; STATUS low 2b must read finished (10)
  encode_once(TOKEN_T1, 0);
  if ((SP_STATUS & 0x3) != 0x2) park(0xDEADE31UL);
  *R_SUM_PRE = slot_checksum(0);
  *R_PROGRESS = 2;

  // window setup + evidence-before
  switch (engine_sel) {
    case 1:  *R_EV_BEFORE = SP_PRED_O; break;
    case 2:  *R_EV_BEFORE = SP_MEM(0x1000); break;        // agent0 row0 part0
    default: SP_TOKEN = TOKEN_T2;                          // encoder rows: slot1
             // poison slot1 first: enc(T2) is deterministic, so residue from
             // a previous run would equal the new write and blind the check
             for (int k = 0; k < 32; k++)
               SP_MEM((uint64_t)(12 + k / 3) * 0x20 + (uint64_t)(k % 3) * 8) =
                   0xA5A5000000000000UL | (uint64_t)k;
             *R_EV_BEFORE = slot_checksum(1);
             win_csr |= (1UL << 10);                       // history slot 1
             break;
  }

  *R_PROGRESS = 3;
  SP_CSR = win_csr;                 // engines loop; ZERO SP access from here
  quiet_spin_cycles(spin_cycles);   // measurement window (Rigol reads here)
  SP_CSR = 0;                       // stop all engines (CPU write wins mux)
  quiet_spin_cycles(BLIND_WAIT_CYC);

  *R_ST_RB = SP_STATUS;
  switch (engine_sel) {
    case 1:  *R_EV_AFTER = SP_PRED_O; break;
    case 2:  *R_EV_AFTER = SP_MEM(0x1000); break;
    default: *R_EV_AFTER = slot_checksum(1); break;
  }
  *R_PROGRESS = 4;

  // recovery + post-vector: weights back to the fixed image, T1 -> slot0
  load_weights();
  encode_once(TOKEN_T1, 0);
  uint64_t post = slot_checksum(0);
  *R_SUM_POST = post;
  if (post != *R_SUM_PRE) park(0xDEADE32UL);
  *R_PROGRESS = 5;

  *R_DONE = DONE_MAGIC;
  return 0;  // falls into startup.S loop (breakpoint = harvest point)
}
