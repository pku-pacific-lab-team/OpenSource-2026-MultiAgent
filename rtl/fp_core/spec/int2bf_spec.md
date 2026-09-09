# INT2BF Module Specification

- Author:      Hongou Li [Peking University]
- Acknowledge: Google AI Studio + Gemini-3-Pro
- DUT File:    `fp_core/src/int2bf.sv`
- TB File:     `fp_core/tb/int2bf_tb.sv`

## 1. Overview

The `int2bf` module converts MX format values (16-bit mantissa + 8-bit scale factor) to BF16 (Brain Floating Point 16) format.

## 2. Module Interface

### 2.1 Ports

| Port | Width | Direction | Description |
|------|-------|-----------|-------------|
| `mx_man_i` | 16 | Input | MX format mantissa (signed integer) |
| `mx_sf_i` | 8 | Input | MX format scale factor |
| `rnd_mode_i` | - | Input | Rounding mode (fpnew_pkg::roundmode_e type) |
| `bf_o` | 16 | Output | BF16 format output |

### 2.2 Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| `BfAbsWidth` | 15 | Width of BF16 absolute value (excluding sign bit) |

## 3. BF16 Format

BF16 is a 16-bit floating-point format:
- Bit 15: Sign bit
- Bits 14-7: 8-bit exponent
- Bits 6-0: 7-bit mantissa

## 4. Conversion Algorithm

### 4.1 Processing Steps

1. **Sign Extraction**
   - Extract sign from MSB of `mx_man_i`
   - Convert to absolute value using two's complement if negative

2. **Normalization**
   - Count leading zeros using `lzc` module
   - Left-shift to normalize the value

3. **Exponent Calculation**
   - Formula: `exponent = mx_sf_i + (15 - leading_zero_count)`
   - Check for overflow (exponent ≥ 255)

4. **Mantissa Extraction**
   - Take bits [14:8] from normalized value as 7-bit mantissa
   - Bit [7] becomes round bit
   - Bits [6:0] contribute to sticky bit

5. **Rounding**
   - Uses `fpnew_rounding` module for IEEE-compliant rounding
   - Supports various rounding modes via `rnd_mode_i`

### 4.2 Special Cases

| Condition | Output |
|-----------|--------|
| Input is zero (`is_empty`) | Zero value with appropriate sign |
| Exponent overflow (`pre_exp ≥ 255`) | Infinity representation (exp=0xFF, mantissa=0) |

## 5. Module Dependencies

- **lzc**: Leading zero counter module
  - WIDTH=16, MODE=1 (leading zero count mode)
- **fpnew_rounding**: IEEE-compliant rounding module from fpnew package
  - Handles rounding based on round and sticky bits

## 6. Design Notes

1. **Two's Complement Handling**: Module properly handles signed MX mantissa values
2. **Overflow Protection**: Saturates to infinity when exponent exceeds BF16 range
3. **IEEE Compliance**: Uses standard fpnew rounding module for correct IEEE-754 behavior
4. **Precision Loss**: Conversion from 16-bit integer to 7-bit mantissa involves truncation

---

*Module Version: Based on current implementation*
