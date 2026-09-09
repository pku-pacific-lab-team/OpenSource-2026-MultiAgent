# ------------------------------------------------------------------------------
# Description:     RISC-V startup code: disables the D-cache, sets up the stack and calls main
# Author:          Zhantong Zhu, Mingxuan Li
# Acknowledgement: GitHub Copilot
# Date:            2026-07-14
# ------------------------------------------------------------------------------

.section .text.init
.global _start
.extern main

# Entry point - calls main and halts
_start:
    # die0 silicon bug (bringup summary section 14): D-cache must be off before
    # any debug halt request, or the debug ROM go-flag poll wedges. Must stay
    # the first instruction so every reset path lands here.
    csrw 0x7c1, zero          # disable D-cache

    # Setup stack frame & return address
    li   sp, 0x80008000       # Initialize stack pointer
    li   ra, 0x80000000       # Initialize return address (bootrom)

    # enable floating point unit
    li   t0, (1 << 13)        # Set FS field to 01 (initial)
    csrs mstatus, t0          # Update mstatus register

    # Clear .bss section
    la t0, __bss_start
    la t1, __bss_end
bss_clear_loop:
    bge t0, t1, bss_clear_done
    sd zero, 0(t0)
    addi t0, t0, 8
    j bss_clear_loop
bss_clear_done:

    # Call main function
    call main

loop:
    # Infinite loop to halt execution
    j loop

