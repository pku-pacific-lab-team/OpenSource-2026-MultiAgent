// -----------------------------------------------------------------------------
// Description:     Baseline power test: all clock gates off, quiet CPU spin and WFI window (case F3)
// Author:          Mingxuan Li
// Acknowledgement: Claude Code + Claude Fable 5
// Date:            2026-07-15
// -----------------------------------------------------------------------------
//
// Defines the canonical CPU posture for the whole power batch:
// quiet_spin_cycles() -- an mcycle-polling timed spin. Every power case
// (B3/C3/E3/F2) must sit in this exact loop during its measurement window so
// the module-minus-baseline subtraction is apples-to-apples.
//
// Completely silent: no UART init, no prints, no accelerator access. One
// continue covers two measurement windows with no halt in between:
//   window 1: all clock gates off + quiet spin (spin_cycles, ~100 s @69.26M)
//   window 2: WFI forever (characterization row only, not a subtraction base)
// Halt (Ctrl-C) is allowed only after the last Rigol reading; debug halt
// wakes a WFI'd hart, and PC parked at the wfi loop is the liveness proof.
//
// spin_cycles is a volatile .data global: gdb `set var spin_cycles = N`
// before continue at other frequency points (no rebuild).
//
// Result area (u64, cleared at start, gdb: x/4gx 0x80007000):
//   0x80007000  DONE      0xF3000000000005A5 = spin window completed (set
//                          right before entering WFI; still 0 after the spin
//                          deadline means the spin never finished)
//   0x80007008  PROGRESS  1=gates closed+spin entered  2=spin done, in WFI
//   0x80007010  CG_RB     0x2000_0020 readback after writing 0 (expect 0)
//   0x80007018  SPIN_RB   spin_cycles actually used this run
//////////////////////////////////////////////////////////////////////////////////

#include <stdint.h>

#define CG_CONFIG_ADDR 0x20000020UL

#define RES_BASE 0x80007000UL
#define R_DONE     ((volatile uint64_t *)(RES_BASE + 0x00))
#define R_PROGRESS ((volatile uint64_t *)(RES_BASE + 0x08))
#define R_CG_RB    ((volatile uint64_t *)(RES_BASE + 0x10))
#define R_SPIN_RB  ((volatile uint64_t *)(RES_BASE + 0x18))

#define DONE_MAGIC 0xF3000000000005A5UL

// ~100 s at the default 69.26 MHz band; gdb-settable per frequency point
volatile uint64_t spin_cycles __attribute__((section(".data"))) = 6930000000ULL;

static inline uint64_t rd_mcycle(void) {
  uint64_t v;
  asm volatile("csrr %0, mcycle" : "=r"(v));
  return v;
}

// Canonical quiet-spin posture for ALL power cases (see header).
void quiet_spin_cycles(uint64_t n) {
  uint64_t start = rd_mcycle();
  while ((rd_mcycle() - start) < n) { }
}

int main(void) {
  volatile uint64_t *r = (volatile uint64_t *)RES_BASE;
  for (int i = 0; i < 4; i++) r[i] = 0;

  *(volatile uint64_t *)CG_CONFIG_ADDR = 0;
  *R_CG_RB = *(volatile uint64_t *)CG_CONFIG_ADDR;
  *R_SPIN_RB = spin_cycles;

  *R_PROGRESS = 1;
  quiet_spin_cycles(spin_cycles);

  *R_DONE = DONE_MAGIC;
  *R_PROGRESS = 2;

  for (;;) asm volatile("wfi");

  return 0;  // unreachable
}
