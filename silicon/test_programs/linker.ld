/* ----------------------------------------------------------------------------
 * Description:     Linker script: 32 KB scratchpad at 0x8000_0000, entry point _start
 * Author:          Mingxuan Li, Zhantong Zhu
 * Acknowledgement: Cursor + Claude
 * Date:            2026-07-15
 * ---------------------------------------------------------------------------- */

OUTPUT_ARCH( "riscv" )
ENTRY( _start )

SECTIONS
{
    . = 0x80000000;

    .text : {
        *(.text.init)
        *(.text)
        *(.text.*)
    }

    .rodata : {
        *(.rodata)
        *(.rodata.*)
    }

    .data : {
        . = ALIGN(16);
        *(.data)
        *(.data.*)
    }

    .bss : {
        . = ALIGN(16);
        __bss_start = .;
        *(.bss)
        *(.bss.*)
        *(COMMON)
        __bss_end = .;
    }

    /* . = 0x30000000;
    .custom_data : {
        *(.custom_data)
        *(.custom_data.*)
    } */
}
