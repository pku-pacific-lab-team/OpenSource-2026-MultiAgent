// -----------------------------------------------------------------------------
// Description:     FP core power test across mode, data sparsity and Huffman coding (case C3)
// Author:          Mingxuan Li
// Acknowledgement: Claude Code + Claude Fable 5
// Date:            2026-07-15
// -----------------------------------------------------------------------------
//
// One run = one power point (gdb set var + jump _start, B3 pattern). CPU
// posture during the window is quiet_spin_cycles(), verbatim from
// baseline_pwr.c (F3).
//
// RTL facts (fp_core.sv, verified 2026-07-15):
//   - CSR 0x0CD0: bit0 mode / bit1 start / bit2 done / bit3 huffman_en /
//     bit4 power_mode. Writing start auto-clears done (C2-proven protocol).
//   - power_mode=1: FSM self-starts from IDLE, loops forever; with
//     huffman_en=1 each pass is COMPUTE->HUFF_PAD->HUFF_DRAIN->COMPUTE, so
//     the encoder genuinely participates in the power loop.
//   - power_mode suppresses done; clearing bit4 lets the current pass finish
//     to IDLE and THEN done sets -> done==1 after stop proves both "stopped"
//     and "was really running".
//   - All 6 rows use mode1 (symmetric quant): errata D2 mandates it for the
//     huffman rows, off rows follow so the huffman on/off differential has a
//     single variable.
//
// Liveness (FP has no hardware cycle counter): pre-window functional pass
// (XOR checksum of man_out 16 words + sf_out), done==1 after stop, and a
// post-window rerun whose checksum must equal the pre value bit-for-bit.
//
// Volatile params (.data, gdb `set var`):
//   sparsity_pct 0/50/90   huf_en 0/1   spin_cycles (default ~70s @69.26M)
//
// Result area (u64, cleared at start, gdb: x/8gx 0x80007000):
//   0x80007000  DONE      0xC3000000000005A5
//   0x80007008  PROGRESS  1=data 2=pre-vec 3=loop on 4=stopped+done 5=post-vec
//                          0xDEADC31/2/3/4 = pre-timeout / no-done-after-stop
//                          / post-timeout / checksum mismatch (parked)
//   0x80007010  PARAM     sparsity<<16 | huf<<8 | 1 (mode1 echo)
//   0x80007018  CG_RB     0x2000_0020 readback (expect 0x1_00000000)
//   0x80007020  PRE_SUM   pre-window functional checksum
//   0x80007028  POST_SUM  post-window checksum (must equal PRE_SUM)
//   0x80007030  CSR_RB    CSR after stop+blind-wait (done bit2 expected 1)
//   0x80007038  SPIN_RB   spin_cycles used this run
//////////////////////////////////////////////////////////////////////////////////

#include <stdint.h>

#define CG_CONFIG_ADDR 0x20000020UL

#define FP_CORE_BASE 0x50000000UL
#define MAN_IN  ((volatile uint64_t *)(FP_CORE_BASE + 0x0000))  // 256 x 64b
#define SF_IN   ((volatile uint64_t *)(FP_CORE_BASE + 0x0800))  // 128 x 64b
#define MAN_OUT ((volatile uint64_t *)(FP_CORE_BASE + 0x0C00))  // 16 x 64b
#define SF_OUT  ((volatile uint64_t *)(FP_CORE_BASE + 0x0C80))
#define FP_CSR  ((volatile uint64_t *)(FP_CORE_BASE + 0x0CD0))

#define CSR_MODE1 0x1UL
#define CSR_START 0x2UL
#define CSR_DONE  0x4UL
#define CSR_HUF   0x8UL
#define CSR_PWR   0x10UL

#define RES_BASE 0x80007000UL
#define R_DONE     ((volatile uint64_t *)(RES_BASE + 0x00))
#define R_PROGRESS ((volatile uint64_t *)(RES_BASE + 0x08))
#define R_PARAM    ((volatile uint64_t *)(RES_BASE + 0x10))
#define R_CG_RB    ((volatile uint64_t *)(RES_BASE + 0x18))
#define R_PRE_SUM  ((volatile uint64_t *)(RES_BASE + 0x20))
#define R_POST_SUM ((volatile uint64_t *)(RES_BASE + 0x28))
#define R_CSR_RB   ((volatile uint64_t *)(RES_BASE + 0x30))
#define R_SPIN_RB  ((volatile uint64_t *)(RES_BASE + 0x38))

#define DONE_MAGIC 0xC3000000000005A5UL
#define WAIT_TIMEOUT_CYC 1000000UL

volatile uint64_t sparsity_pct __attribute__((section(".data"))) = 0;
volatile uint64_t huf_en       __attribute__((section(".data"))) = 0;
volatile uint64_t spin_cycles  __attribute__((section(".data"))) = 4850000000ULL;

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

// 1024 elements: 16b mantissa (sparsity% forced 0, else random) + 8b SF in
// [0,200] (C2 lesson: avoids accidental Inf). Streams straight to MMIO.
static void fill_inputs(void) {
  lcg_seed = 20260101;
  for (int w = 0; w < 256; w++) {
    uint64_t word = 0;
    for (int e = 0; e < 4; e++) {
      uint16_t man = 0;
      if ((lcg() >> 8) % 100 >= sparsity_pct) man = (uint16_t)(lcg() >> 8);
      word |= ((uint64_t)man) << (e * 16);
    }
    MAN_IN[w] = word;
  }
  for (int w = 0; w < 128; w++) {
    uint64_t word = 0;
    for (int e = 0; e < 8; e++) {
      word |= ((uint64_t)((lcg() >> 8) % 201)) << (e * 8);
    }
    SF_IN[w] = word;
  }
}

// One functional pass, mode1, no huffman: start, poll done, XOR-checksum
static uint64_t run_vector(uint64_t fail_code) {
  *FP_CSR = CSR_START | CSR_MODE1;  // start auto-clears done
  uint64_t t0 = rd_mcycle();
  while (!(*FP_CSR & CSR_DONE)) {
    if (rd_mcycle() - t0 > WAIT_TIMEOUT_CYC) park(fail_code);
  }
  uint64_t sum = 0;
  for (int i = 0; i < 16; i++) sum ^= MAN_OUT[i];
  sum ^= *SF_OUT;
  return sum;
}

int main(void) {
  volatile uint64_t *r = (volatile uint64_t *)RES_BASE;
  for (int i = 0; i < 8; i++) r[i] = 0;

  // gate on FP Y0 only (bit 32+Y)
  *(volatile uint64_t *)CG_CONFIG_ADDR = (1ULL << 32);
  *R_CG_RB = *(volatile uint64_t *)CG_CONFIG_ADDR;
  *R_SPIN_RB = spin_cycles;
  *R_PARAM = (sparsity_pct << 16) | (huf_en << 8) | 1;

  fill_inputs();
  *R_PROGRESS = 1;

  *R_PRE_SUM = run_vector(0xDEADC31UL);
  *R_PROGRESS = 2;

  uint64_t loop_csr = CSR_MODE1 | (huf_en ? CSR_HUF : 0);
  *FP_CSR = loop_csr | CSR_PWR;     // power loop on (self-starts from IDLE)
  *R_PROGRESS = 3;

  quiet_spin_cycles(spin_cycles);   // measurement window (Rigol reads here)

  *FP_CSR = loop_csr;               // clear bit4 only; pass drains to IDLE
  quiet_spin_cycles(100000);        // >> one pass (~40 / few hundred cycles)

  uint64_t csr_rb = *FP_CSR;
  *R_CSR_RB = csr_rb;
  if (!(csr_rb & CSR_DONE)) park(0xDEADC32UL);
  *R_PROGRESS = 4;

  uint64_t post = run_vector(0xDEADC33UL);
  *R_POST_SUM = post;
  if (post != *R_PRE_SUM) park(0xDEADC34UL);
  *R_PROGRESS = 5;

  *R_DONE = DONE_MAGIC;
  return 0;  // falls into startup.S loop (breakpoint = harvest point)
}
