# ------------------------------------------------------------------------------
# Description:     Convert an objdump listing to a hex image
# Author:          Mingxuan Li
# Acknowledgement: Cursor + Claude
# Date:            2025-12-20
# ------------------------------------------------------------------------------

import os
import sys

if len(sys.argv) != 3:
    print("Usage: python asm2hex.py <input_asm_file> <output_hex_file>")
    sys.exit(1)

input_asm_file = sys.argv[1]
output_hex_file = sys.argv[2]

if not os.path.isfile(input_asm_file):
    print(f"Error: {input_asm_file} does not exist.")
    sys.exit(1)

data_sections = ['.text', '.rodata', '.data']
data = {'.text': [], '.rodata': [], '.data': []}
current_section = None

def big_to_little_endian(hex_str):
    # convert a big-endian hex string to little-endian
    byte_array = bytearray.fromhex(hex_str)
    byte_array.reverse()
    little_endian_hex = ''.join(format(x, '02x') for x in byte_array)
    # make sure the output has 8 hex digits (4 bytes), zero-padded on the left
    return little_endian_hex.zfill(8)

with open(input_asm_file, 'r') as f:
    for line in f:
        line = line.strip()
        # check whether a new section starts
        if line.startswith('Contents of section'):
            for sec in data_sections:
                if line.endswith(f'{sec}:'):
                    current_section = sec
                    break
            else:
                current_section = None
        # inside a target section, process the data lines
        elif current_section:
            if line:
                parts = line.split()
                if len(parts) >= 5:
                    data_values = [big_to_little_endian(val) for val in parts[1:5] if all(c in '0123456789abcdefABCDEF' for c in val)]  # extract and convert 4 data words
                    data[current_section].append(data_values)
                elif len(parts) > 1:
                    address = parts[0]
                    data_values = [big_to_little_endian(val) for val in parts[1:] if all(c in '0123456789abcdefABCDEF' for c in val)]  # extract and convert all data words
                    data[current_section].append(data_values)
            else:
                # an empty line ends the section
                current_section = None

# pair the data words and write them to the file
with open(output_hex_file, 'w') as output_file:
    for section in data_sections:
        for data_values in data[section]:
            # if the number of data_values is odd, pad with 0
            if len(data_values) % 2 != 0:
                data_values.append('00000000')
            for i in range(0, len(data_values), 2):
                paired_value = data_values[i+1] + data_values[i]
                output_file.write(paired_value + '\n')
