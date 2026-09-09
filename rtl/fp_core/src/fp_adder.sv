// Copyright 2019 ETH Zurich and University of Bologna.
//
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// SPDX-License-Identifier: SHL-0.51
// Author: Stefan Mach <smach@iis.ee.ethz.ch>
// Modifier: Hongou Li [Peking University]
module fp_adder #(
  parameter fpnew_pkg::fp_format_e FpFormat = fpnew_pkg::fp_format_e'(0),
  localparam int unsigned WIDTH = fpnew_pkg::fp_width(FpFormat) // do not change
) (
  // Input signals
  input logic [1:0][WIDTH-1:0] operands_i, // 2 operands: [0] = a, [1] = c
  input logic [1:0] is_boxed_i, // 2 operands
  input fpnew_pkg::roundmode_e rnd_mode_i,
  input fpnew_pkg::operation_e op_i,
  // Output signals
  output logic [WIDTH-1:0] result_o,
  output fpnew_pkg::status_t status_o
);
  // ----------
  // Constants
  // ----------
  localparam int unsigned EXP_BITS = fpnew_pkg::exp_bits(FpFormat);
  localparam int unsigned MAN_BITS = fpnew_pkg::man_bits(FpFormat);
  localparam int unsigned BIAS = fpnew_pkg::bias(FpFormat);
  // Precision bits 'p' include the implicit bit
  localparam int unsigned PRECISION_BITS = MAN_BITS + 1;
  // The lower 2p+3 bits of the internal FMA result will be needed for leading-zero detection
  localparam int unsigned LOWER_SUM_WIDTH = 2 * PRECISION_BITS + 3;
  localparam int unsigned LZC_RESULT_WIDTH = $clog2(LOWER_SUM_WIDTH);
  // Internal exponent width of FMA must accomodate all meaningful exponent values in order to avoid
  // datapath leakage. This is either given by the exponent bits or the width of the LZC result.
  // In most reasonable FP formats the internal exponent will be wider than the LZC result.
  localparam int unsigned EXP_WIDTH = unsigned'(fpnew_pkg::maximum(EXP_BITS + 2, LZC_RESULT_WIDTH));
  // Shift amount width: maximum internal mantissa size is 3p+4 bits
  localparam int unsigned SHIFT_AMOUNT_WIDTH = $clog2(3 * PRECISION_BITS + 5);
  // ----------------
  // Type definition
  // ----------------
  typedef struct packed {
    logic sign;
    logic [EXP_BITS-1:0] exponent;
    logic [MAN_BITS-1:0] mantissa;
  } fp_t;
  // -----------------
  // Input processing
  // -----------------
  fpnew_pkg::fp_info_t [1:0] info;
  // Classify input
  fpnew_classifier #(
    .FpFormat ( FpFormat ),
    .NumOperands ( 2 )
    ) i_class_inputs (
    .operands_i ( operands_i ),
    .is_boxed_i ( is_boxed_i ),
    .info_o ( info )
  );
  fp_t operand_a, operand_c;
  fpnew_pkg::fp_info_t info_a, info_c;
  // Operation selection and operand adjustment
  always_comb begin : op_select
    // Default assignments - packing-order-agnostic
    operand_a = operands_i[0];
    operand_c = operands_i[1];
    info_a = info[0];
    info_c = info[1];
    // op_mod_i inverts sign of operand C for subtraction
    // operand_c.sign = operand_c.sign ^ op_mod_i;
    // Only support ADD operation
    if (op_i != fpnew_pkg::ADD) begin
      operand_a = '{default: fpnew_pkg::DONT_CARE};
      operand_c = '{default: fpnew_pkg::DONT_CARE};
      info_a = '{default: fpnew_pkg::DONT_CARE};
      info_c = '{default: fpnew_pkg::DONT_CARE};
    end
  end
  // ---------------------
  // Input classification
  // ---------------------
  logic any_operand_inf;
  logic any_operand_nan;
  logic signalling_nan;
  logic effective_subtraction;
  logic tentative_sign;
  // Reduction for special case handling
  assign any_operand_inf = (| {info_a.is_inf, info_c.is_inf});
  assign any_operand_nan = (| {info_a.is_nan, info_c.is_nan});
  assign signalling_nan = (| {info_a.is_signalling, info_c.is_signalling});
  // Effective subtraction occurs when signs differ
  assign effective_subtraction = operand_a.sign ^ operand_c.sign;
  // The tentative sign shall be the sign of operand A (as if product with +1.0)
  assign tentative_sign = operand_a.sign;
  // ----------------------
  // Special case handling
  // ----------------------
  fp_t special_result;
  fpnew_pkg::status_t special_status;
  logic result_is_special;
  always_comb begin : special_cases
    // Default assignments
    special_result = '{sign: 1'b0, exponent: '1, mantissa: 2**(MAN_BITS-1)}; // canonical qNaN
    special_status = '0;
    result_is_special = 1'b0;
    // NaN Inputs cause canonical quiet NaN at the output and maybe invalid OP
    if (any_operand_nan) begin
      result_is_special = 1'b1; // bypass, output is the canonical qNaN
      special_status.NV = signalling_nan; // raise the invalid operation flag if signalling
    // Special cases involving infinity
    end else if (any_operand_inf) begin
      result_is_special = 1'b1; // bypass
      // Effective addition of opposite infinities (±inf - ±inf) is invalid!
      if (info_a.is_inf && info_c.is_inf && effective_subtraction)
        special_status.NV = 1'b1; // invalid operation
      // Handle cases where "product" (A) is inf
      else if (info_a.is_inf) begin
        // Result is infinity with the sign of A
        special_result = '{sign: operand_a.sign, exponent: '1, mantissa: '0};
      // Handle cases where the addend is inf
      end else if (info_c.is_inf) begin
        // Result is inifinity with sign of the addend (= operand_c)
        special_result = '{sign: operand_c.sign, exponent: '1, mantissa: '0};
      end
    end
  end
  // ---------------------------
  // Initial exponent data path
  // ---------------------------
  logic signed [EXP_WIDTH-1:0] exponent_a, exponent_c;
  logic signed [EXP_WIDTH-1:0] exponent_addend, exponent_product, exponent_difference;
  logic signed [EXP_WIDTH-1:0] tentative_exponent;
  // Zero-extend exponents into signed container - implicit width extension
  assign exponent_a = signed'({1'b0, operand_a.exponent});
  assign exponent_c = signed'({1'b0, operand_c.exponent});
  // Calculate internal exponents from encoded values.
  assign exponent_addend = signed'(exponent_c + $signed({1'b0, ~info_c.is_normal})); // 0 as subnorm
  // For "product" which is now A (as if multiplied by +1.0)
  assign exponent_product = (info_a.is_zero)
                            ? 2 - signed'(BIAS) // in case A is zero, set minimum exp.
                            : signed'(exponent_a + info_a.is_subnormal);
  // Exponent difference is the addend exponent minus the product exponent
  assign exponent_difference = exponent_addend - exponent_product;
  // The tentative exponent will be the larger of the product or addend exponent
  assign tentative_exponent = (exponent_difference > 0) ? exponent_addend : exponent_product;
  // Shift amount for addend based on exponents (unsigned as only right shifts)
  logic [SHIFT_AMOUNT_WIDTH-1:0] addend_shamt;
  always_comb begin : addend_shift_amount
    // Product-anchored case, saturated shift (addend is only in the sticky bit)
    if (exponent_difference <= signed'(-2 * PRECISION_BITS - 1))
      addend_shamt = 3 * PRECISION_BITS + 4;
    // Addend and product will have mutual bits to add
    else if (exponent_difference <= signed'(PRECISION_BITS + 2))
      addend_shamt = unsigned'(signed'(PRECISION_BITS) + 3 - exponent_difference);
    // Addend-anchored case, saturated shift (product is only in the sticky bit)
    else
      addend_shamt = 0;
  end
  // ------------------
  // "Product" data path (now A as if multiplied by +1.0)
  // ------------------
  logic [PRECISION_BITS-1:0] mantissa_a, mantissa_c;
  logic [2*PRECISION_BITS-1:0] product; // emulated "product" is 2p bits wide
  logic [3*PRECISION_BITS+3:0] product_shifted; // addends are 3p+4 bit wide (including G/R)
  // Add implicit bits to mantissae
  assign mantissa_a = {info_a.is_normal, operand_a.mantissa};
  assign mantissa_c = {info_c.is_normal, operand_c.mantissa};
  // Emulate product without multiplier: equivalent to mantissa_a * 2^(PRECISION_BITS-1)
  assign product = mantissa_a << (PRECISION_BITS - 1);
  // Product is placed into a 3p+4 bit wide vector, padded with 2 bits for round and sticky:
  // | 000...000 | product | RS |
  // <- p+2 -> <- 2p -> < 2>
  assign product_shifted = product << 2; // constant shift
  // -----------------
  // Addend data path
  // -----------------
  logic [3*PRECISION_BITS+3:0] addend_after_shift; // upper 3p+4 bits are needed to go on
  logic [PRECISION_BITS-1:0] addend_sticky_bits; // up to p bit of shifted addend are sticky
  logic sticky_before_add; // they are compressed into a single sticky bit
  logic [3*PRECISION_BITS+3:0] addend_shifted; // addends are 3p+4 bit wide (including G/R)
  logic inject_carry_in; // inject carry for subtractions if needed
  // In parallel, the addend is right-shifted according to the exponent difference. Up to p bits
  // are shifted out and compressed into a sticky bit.
  // BEFORE THE SHIFT:
  // | mantissa_c | 000..000 |
  // <- p -> <- 3p+4 ->
  // AFTER THE SHIFT:
  // | 000..........000 | mantissa_c | 000...............0GR | sticky bits |
  // <- addend_shamt -> <- p -> <- 2p+4-addend_shamt -> <- up to p ->
  assign {addend_after_shift, addend_sticky_bits} =
      (mantissa_c << (3 * PRECISION_BITS + 4)) >> addend_shamt;
  assign sticky_before_add = (| addend_sticky_bits);
  // In case of a subtraction, the addend is inverted
  assign addend_shifted = (effective_subtraction) ? ~addend_after_shift : addend_after_shift;
  assign inject_carry_in = effective_subtraction & ~sticky_before_add;
  // ------
  // Adder
  // ------
  logic [3*PRECISION_BITS+4:0] sum_raw; // added one bit for the carry
  logic sum_carry; // observe carry bit from sum for sign fixing
  logic [3*PRECISION_BITS+3:0] sum; // discard carry as sum won't overflow
  logic final_sign;
  //Mantissa adder (a + c). In normal addition, it cannot overflow.
  assign sum_raw = product_shifted + addend_shifted + inject_carry_in;
  assign sum_carry = sum_raw[3*PRECISION_BITS+4];
  // Complement negative sum (can only happen in subtraction -> overflows for positive results)
  assign sum = (effective_subtraction && ~sum_carry) ? -sum_raw : sum_raw;
  // In case of a mispredicted subtraction result, do a sign flip
  assign final_sign = (effective_subtraction && (sum_carry == tentative_sign))
                      ? 1'b1
                      : (effective_subtraction ? 1'b0 : tentative_sign);
  // --------------
  // Normalization
  // --------------
  logic [LOWER_SUM_WIDTH-1:0] sum_lower; // lower 2p+3 bits of sum are searched
  logic [LZC_RESULT_WIDTH-1:0] leading_zero_count; // the number of leading zeroes
  logic signed [LZC_RESULT_WIDTH:0] leading_zero_count_sgn; // signed leading-zero count
  logic lzc_zeroes; // in case only zeroes found
  logic [SHIFT_AMOUNT_WIDTH-1:0] norm_shamt; // Normalization shift amount
  logic signed [EXP_WIDTH-1:0] normalized_exponent;
  logic [3*PRECISION_BITS+4:0] sum_shifted; // result after first normalization shift
  logic [PRECISION_BITS:0] final_mantissa; // final mantissa before rounding with round bit
  logic [2*PRECISION_BITS+2:0] sum_sticky_bits; // remaining 2p+3 sticky bits after normalization
  logic sticky_after_norm; // sticky bit after normalization
  logic signed [EXP_WIDTH-1:0] final_exponent;
  assign sum_lower = sum[LOWER_SUM_WIDTH-1:0];
  // Leading zero counter for cancellations
  lzc #(
    .WIDTH ( LOWER_SUM_WIDTH ),
    .MODE ( 1 ) // MODE = 1 counts leading zeroes
  ) i_lzc (
    .in_i ( sum_lower ),
    .cnt_o ( leading_zero_count ),
    .empty_o ( lzc_zeroes )
  );
  assign leading_zero_count_sgn = signed'({1'b0, leading_zero_count});
  // Normalization shift amount based on exponents and LZC (unsigned as only left shifts)
  always_comb begin : norm_shift_amount
    // Product-anchored case or cancellations require LZC
    if ((exponent_difference <= 0) || (effective_subtraction && (exponent_difference <= 2))) begin
      // Normal result (biased exponent > 0 and not a zero)
      if ((exponent_product - leading_zero_count_sgn + 1 >= 0) && !lzc_zeroes) begin
        // Undo initial product shift, remove the counted zeroes
        norm_shamt = PRECISION_BITS + 2 + leading_zero_count;
        normalized_exponent = exponent_product - leading_zero_count_sgn + 1; // account for shift
      // Subnormal result
      end else begin
        // Cap the shift distance to align mantissa with minimum exponent
        norm_shamt = unsigned'(signed'(PRECISION_BITS) + 2 + exponent_product);
        normalized_exponent = 0; // subnormals encoded as 0
      end
    // Addend-anchored case
    end else begin
      norm_shamt = addend_shamt; // Undo the initial shift
      normalized_exponent = tentative_exponent;
    end
  end
  // Do the large normalization shift
  assign sum_shifted = sum << norm_shamt;
  // The addend-anchored case needs a 1-bit normalization since the leading-one can be to the left
  // or right of the (non-carry) MSB of the sum.
  always_comb begin : small_norm
    // Default assignment, discarding carry bit
    {final_mantissa, sum_sticky_bits} = sum_shifted;
    final_exponent = normalized_exponent;
    // The normalized sum has overflown, align right and fix exponent
    if (sum_shifted[3*PRECISION_BITS+4]) begin // check the carry bit
      {final_mantissa, sum_sticky_bits} = sum_shifted >> 1;
      final_exponent = normalized_exponent + 1;
    // The normalized sum is normal, nothing to do
    end else if (sum_shifted[3*PRECISION_BITS+3]) begin // check the sum MSB
      // do nothing
    // The normalized sum is still denormal, align left - unless the result is not already subnormal
    end else if (normalized_exponent > 1) begin
      {final_mantissa, sum_sticky_bits} = sum_shifted << 1;
      final_exponent = normalized_exponent - 1;
    // Otherwise we're denormal
    end else begin
      final_exponent = '0;
    end
  end
  // Update the sticky bit with the shifted-out bits
  assign sticky_after_norm = (| {sum_sticky_bits}) | sticky_before_add;
  // ----------------------------
  // Rounding and classification
  // ----------------------------
  logic pre_round_sign;
  logic [EXP_BITS-1:0] pre_round_exponent;
  logic [MAN_BITS-1:0] pre_round_mantissa;
  logic [EXP_BITS+MAN_BITS-1:0] pre_round_abs; // absolute value of result before rounding
  logic [1:0] round_sticky_bits;
  logic of_before_round, of_after_round; // overflow
  logic uf_before_round, uf_after_round; // underflow
  logic result_zero;
  logic rounded_sign;
  logic [EXP_BITS+MAN_BITS-1:0] rounded_abs; // absolute value of result after rounding
  // Classification before round. RISC-V mandates checking underflow AFTER rounding!
  assign of_before_round = final_exponent >= 2**(EXP_BITS)-1; // infinity exponent is all ones
  assign uf_before_round = final_exponent == 0; // exponent for subnormals capped to 0
  // Assemble result before rounding. In case of overflow, the largest normal value is set.
  assign pre_round_sign = final_sign;
  assign pre_round_exponent = (of_before_round) ? 2**EXP_BITS-2 : unsigned'(final_exponent[EXP_BITS-1:0]);
  assign pre_round_mantissa = (of_before_round) ? '1 : final_mantissa[MAN_BITS:1]; // bit 0 is R bit
  assign pre_round_abs = {pre_round_exponent, pre_round_mantissa};
  // In case of overflow, the round and sticky bits are set for proper rounding
  assign round_sticky_bits = (of_before_round) ? 2'b11 : {final_mantissa[0], sticky_after_norm};
  // Perform the rounding
  fpnew_rounding #(
    .AbsWidth ( EXP_BITS + MAN_BITS )
  ) i_fpnew_rounding (
    .abs_value_i ( pre_round_abs ),
    .sign_i ( pre_round_sign ),
    .round_sticky_bits_i ( round_sticky_bits ),
    .rnd_mode_i ( rnd_mode_i ),
    .effective_subtraction_i ( effective_subtraction ),
    .abs_rounded_o ( rounded_abs ),
    .sign_o ( rounded_sign ),
    .exact_zero_o ( result_zero )
  );
  // Classification after rounding
  assign uf_after_round = rounded_abs[EXP_BITS+MAN_BITS-1:MAN_BITS] == '0; // exponent = 0
  assign of_after_round = rounded_abs[EXP_BITS+MAN_BITS-1:MAN_BITS] == '1; // exponent all ones
  // -----------------
  // Result selection
  // -----------------
  logic [WIDTH-1:0] regular_result;
  fpnew_pkg::status_t regular_status;
  // Assemble regular result
  assign regular_result = {rounded_sign, rounded_abs};
  assign regular_status.NV = 1'b0; // only valid cases are handled in regular path
  assign regular_status.DZ = 1'b0; // no divisions
  assign regular_status.OF = of_before_round | of_after_round; // rounding can introduce overflow
  assign regular_status.UF = uf_after_round & regular_status.NX; // only inexact results raise UF
  assign regular_status.NX = (| round_sticky_bits) | of_before_round | of_after_round;
  // Final results
  fp_t result_d;
  fpnew_pkg::status_t status_d;
  // Select output depending on special case detection
  assign result_d = result_is_special ? special_result : regular_result;
  assign status_d = result_is_special ? special_status : regular_status;
  // Assign outputs
  assign result_o = result_d;
  assign status_o = status_d;
endmodule