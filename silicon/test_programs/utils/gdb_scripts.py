# ------------------------------------------------------------------------------
# Description:     GDB script generator for loading and running a program
# Author:          Mingxuan Li
# Acknowledgement: VSCode GitHub Copilot
# Date:            2025-12-20
# ------------------------------------------------------------------------------

import os
import argparse

def generate_gdb_script(main_name, output_file):
    """
    Generate a GDB debug script
    """
    script_content = f"""# Auto-generated GDB script for {main_name}
# Author:           Mingxuan Li
# Acknowledgement:  VSCode GitHub Copilot

# load the ELF file
file bin/{main_name}.elf

# load the program into the target
load

# set a breakpoint at loop
break loop

# run the program
continue

# show full information
echo {main_name.upper()} testing completed\\n
"""

    # create the output directory
    os.makedirs(os.path.dirname(output_file), exist_ok=True)

    # write the file
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(script_content)


def main():
    parser = argparse.ArgumentParser(description='Generate GDB script for RISC-V debugging')
    parser.add_argument('MAIN', help='Main function file name (without .c extension)')

    args = parser.parse_args()

    # generate the GDB script
    output_file = os.path.join('scripts', f"{args.MAIN}.gdb")
    generate_gdb_script(args.MAIN, output_file)

if __name__ == "__main__":
    main()
