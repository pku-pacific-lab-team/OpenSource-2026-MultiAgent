# Experimental result data

This directory contains machine-readable outputs from the MXINT and
scaling-factor-hinted sparse-attention evaluation code.

## Scope

- Dataset: WikiText-2 raw test split.
- Sampling: 64 non-overlapping blocks of 2,048 tokens per model.
- Reference: BF16 causal-language-model inference.
- Quantization: symmetric group-wise fake quantization, group size 32, E8M0
  power-of-two scale with `ceil`.
- MXINT8: weights, activations, and Attention Q/K/P/V use 8-bit fake quant;
  Attention Hadamard is disabled.
- MXINT4+H: the same tensors use 4-bit fake quant; Attention Hadamard is
  enabled.
- Sparse Attention: SF block size 32 tokens. K is the Top-K budget of the
  SF block selection, i.e. the number of key blocks kept for each query
  block, evaluated at K=32 and K=40. The budget includes block 0 and the
  diagonal block, which are forced whenever they are valid candidates. A
  2,048-token sequence has 64 key blocks, so K32/K40 keep at most 32/40 of
  the key blocks visible to each query block. The achieved block sparsity is
  reported in the `*_block_sparsity_percent` columns of the summary.

## Files

- `results/model_summary.csv`: compact table of the principal PPL and sparse
  metrics.
- `results/model_summary.md`: human-readable view of the same principal data.
- `results/raw/<model>/full_int8.json`: complete MXINT8 report.
- `results/raw/<model>/full_int4_hadamard.json`: complete MXINT4+H report.
- `results/SHA256SUMS.json`: file hashes for integrity checking.

No model weights, tokenizer files, or WikiText text are included.

The numerical measurement files in this directory are licensed under
CC BY 4.0; see the license map in [LICENSE.md](../../LICENSE.md).

## Units and interpretation

- `loss` and KL divergence are in natural-log units (nats).
- `ppl` is dimensionless and equals `exp(mean next-token NLL)`.
- latency is in seconds; memory is in GiB.
- ratio fields are fractions in `[0, 1]`; fields ending in `_percent` are
  percentages.
- `*_valid_block_sparsity_percent` is the fraction of model-visible key
  blocks (causal and, for Gemma 3, inside the sliding window) that were
  skipped. `*_causal_block_sparsity_percent` uses the full causal triangle as
  the denominator, so for Gemma 3 it also counts blocks that the model itself
  never attends to. For full-causal models the two are equal: K32 skips 25.4%
  and K40 skips 14.4% of the key blocks at 2,048 tokens. The sparsity is
  identical for MXINT8 and MXINT4+H because the Top-K budget is structural.
- absolute PPL values should not be ranked across model families because each
  model uses its own tokenizer. Compare each variant against the BF16 or dense
  fake-quant baseline for the same model.
- this is eager PyTorch software simulation. QK/PV arithmetic is restricted to
  selected blocks, but no optimized sparse CUDA/Triton kernel is included.

## Provenance

The reports cover the 11-model configuration set described in the root
README. Each report records its model ID, quantization settings, sampling
protocol, and measured outputs. For models with sliding-window attention,
including Gemma 3, SF Top-K selection ranks only blocks permitted by the
model's attention mask. Additional result metadata is recorded in
`results/provenance.json`.

To rebuild the compact table after replacing a raw result, run from `model/`
(first `cd model` if the terminal is at the repository root):

```bash
python scripts/summarize_results.py
python scripts/write_checksums.py
python scripts/write_checksums.py --check
```

The paths inside `results/SHA256SUMS.json` are relative to `model/`. The
verification script resolves that directory from its own location, so it can
also be invoked as `python model/scripts/write_checksums.py --check` from the
repository root.

See the [root README](../../README.md) and [third-party terms](../../THIRD_PARTY.md)
for environment and upstream artifact requirements.
