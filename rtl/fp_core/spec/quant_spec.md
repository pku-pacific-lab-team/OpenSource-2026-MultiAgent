# QUANT Module Specification

- Author:      Hongou Li [Peking University]
- Acknowledge: Google AI Studio + Gemini-3-Pro
- DUT File:    `fp_core/src/quant.sv`
- TB File:     `fp_core/tb/quant_tb.sv`

## 1. Overview

The `quant` module quantizes a group of 32 BF16 (Brain Float 16) values into MX format, which uses 4-bit mantissas with a shared 8-bit scale factor.

## 2. Module Interface

### 2.1 Ports

| Port | Width | Direction | Description |
|------|-------|-----------|-------------|
| `bf_group_i` | 32×16 | Input | Group of 32 BF16 values |
| `mode_i` | 1 | Input | Quantization mode: 0=asymmetric (-8 to 7), 1=symmetric (-7 to 7) |
| `mx_man_group_o` | 32×4 | Output | Group of 32 4-bit MX mantissas |
| `mx_sf_o` | 8 | Output | Shared 8-bit scale factor for the group |

## 3. BF16 Format Parsing

Each 16-bit BF16 input is parsed as:
- Bit 15: Sign
- Bits 14-7: 8-bit exponent
- Bits 6-0: 7-bit mantissa

### 3.1 Special Value Detection

| Type | Condition |
|------|-----------|
| Zero | `exponent == 0` AND `mantissa == 0` |
| Subnormal | `exponent == 0` AND `mantissa != 0` |
| Infinity | `exponent == 255` AND `mantissa == 0` |
| NaN | `exponent == 255` AND `mantissa != 0` |

## 4. Quantization Algorithm

### 4.1 Shared Scale Factor Calculation

1. **Maximum Exponent Finding**
   - Excludes Infinity and NaN values (treated as exponent 0)
   - Uses 5-level tree reduction to find maximum exponent:
     - Level 0: 32 → 16 comparisons
     - Level 1: 16 → 8 comparisons
     - Level 2: 8 → 4 comparisons
     - Level 3: 4 → 2 comparisons
     - Final: 2 → 1 comparison

2. **Scale Factor Assignment**
   - `mx_sf_o = max(max_exponent - 2, 0)`

### 4.2 Per-Element Quantization

For each BF16 element:

1. **Exponent Delta Calculation**
   - `exp_delta = max_exponent - element_exponent`

2. **Value Shifting**
   - Normal values: `{1, mantissa, 12'b0} >> exp_delta` (includes implicit leading 1)
   - Subnormal values: `{mantissa, 13'b0} >> exp_delta` (no implicit leading 1)
   - Zero values: Output is 0

3. **Rounding**
   - Extract round bit from position [14] of shifted value
   - Round-to-nearest by adding round bit to magnitude

4. **Saturation and Conversion**
   - Positive values: Saturate to +7 if overflow
   - Negative values: Saturate to -8 if overflow, then convert using two's complement

### 4.3 Special Cases

| Input | Output |
|-------|--------|
| +Infinity | +7 (4'b0111) |
| -Infinity | -8 (4'b1000) or -7 in symmetric mode |
| NaN | 0 (4'b0000) |
| Any value when group contains Infinity | 0 (except Infinity itself) |

### 4.4 Quantization Modes

- **Asymmetric Mode (`mode_i = 0`)**: Range [-8, +7]
- **Symmetric Mode (`mode_i = 1`)**: Range [-7, +7]
  - In symmetric mode, -8 is mapped to -7

## 5. Design Features

1. **Group-wise Processing**: Processes 32 BF16 values simultaneously
2. **Shared Scaling**: Single scale factor for entire group reduces storage
3. **IEEE Special Value Handling**: Proper handling of Infinity and NaN
4. **Overflow Protection**: Saturation logic prevents wraparound
5. **Configurable Symmetry**: Supports both symmetric and asymmetric quantization

## 6. Implementation Notes

- Tree reduction for maximum finding is fully combinational
- All 32 quantization lanes operate in parallel
- Magnitude round-half-up followed by saturation (legacy RTL behavior; not round-to-nearest-even)
- Infinity in group forces all other values to zero (preserves relative scale)

---

*Module Version: Based on current implementation*
