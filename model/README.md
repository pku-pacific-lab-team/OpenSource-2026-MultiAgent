# Model: MXINT quantization and SF-hinted block-sparse attention

**PyTorch reference implementation for evaluating MXINT4/8 quantization
error and scaling-factor-hinted block selection in causal language models.**

This directory contains the implementation, environment configuration,
tests, and reproducible experimental data.

The implementation uses floating-point quantize-dequantize operations. It
does not pack weights into INT4/INT8 storage or use integer GEMM. Sparse
attention computes QK and PV for selected key blocks, but it is an eager
reference implementation without an optimized sparse CUDA/Triton kernel.

[Installation](#installation) |
[Quick start](#quick-start) |
[Reproduction](#reproduce-the-included-experiments) |
[Results](data/results/model_summary.md) |
[Algorithm](#algorithm) |
[Debugging](#debugging-and-statistics)

## Installation

The tested environment uses Python 3.12, PyTorch 2.5.1, CUDA 12.4, NumPy
2.1.3, and Transformers 4.57.1. GPU model evaluations require an NVIDIA GPU
with enough memory for the selected model and its intermediate tensors.
Fake quantization retains floating-point storage.

Run from the directory where you want to clone the repository:

```bash
git clone https://github.com/pku-pacific-lab-team/OpenSource-2026-MultiAgent.git
cd OpenSource-2026-MultiAgent/model
conda env create -f environment.yml
conda activate mxint-sf
python -m pytest tests -q
```

All commands below assume that the terminal is in `model/`. As an alternative
to Conda, use a Python 3.12 virtual environment and install
`requirements-dev.txt`, selecting the appropriate PyTorch wheel for your
CPU/CUDA platform. CPU regression tests do not download model weights.

Model weights and dataset text are not bundled. The quick-start command
downloads uncached artifacts on first use. Review the
[upstream model and dataset terms](../THIRD_PARTY.md) and obtain any required
access before running an evaluation.

## Quick start

### Check one model

This small run evaluates the floating-point reference first, then evaluates
MXINT8 fake quantization with SF Top-K selection on the same token blocks:

```bash
python run_evaluation.py \
  --model-path Qwen/Qwen3-1.7B \
  --seqlen 512 --nsamples 1 --batch-size 1 \
  --mxint-bits 8 --group-size 32 --e8-scale-op ceil \
  --w-quant-inplace --sf-sparse-attention --topk 8 \
  --kl-topk 16 \
  --metrics-output results/quickstart_int8.json
```

The JSON contains reference and evaluated loss/PPL, top-K-renormalized KL,
top-1 agreement, quantization settings, and per-layer sparse statistics.
Omit `--sf-sparse-attention` to evaluate dense fake quantization.

### Generate text

```bash
python run_quant_inference.py \
  --model-path Qwen/Qwen3-1.7B \
  --mxint-bits 8 \
  --prompt "Introduce yourself in one sentence." \
  --max-new-tokens 32
```

`--prompt-format auto` uses a tokenizer's chat template when available and
otherwise tokenizes plain text. Explicit `chat` and `text` modes are also
available. SF selection targets aligned prefill; unequal query/key lengths
during cached decoding use the dense fallback by default.

## Supported models

The included benchmark covers the following 11 model configurations:

| Family | Included model sizes | Adapter |
|---|---|---|
| Qwen3 | 1.7B, 4B, 8B | `qwen3` |
| Llama 3.2 | 1B, 3B | `llama` |
| SmolLM2 | 1.7B | `llama` |
| Llama 2 | 7B | `llama` |
| Mistral | 7B | `mistral` |
| Pythia | 6.9B | `gpt_neox` |
| Gemma 3 | 1B | `gemma3_text` |
| Phi-2 | 2.7B | `phi` |

Qwen2/Qwen2.5 adapters are also implemented; they are not part of this
11-model result set. Exact model IDs, including the mirrors used for measured
runs, are listed in the [benchmark manifest](configs/scale_model_queue.json)
and [result provenance](data/results/provenance.json).

## Reproduce the included experiments

The common protocol is WikiText-2 raw test, 64 non-overlapping blocks of
2,048 tokens, batch size 1, seed 42, group size 32, E8M0-style `ceil` scales,
and SF block size 32. K32/K40 include forced first and diagonal blocks when
those blocks are valid. MXINT8 uses no rotation; MXINT4 uses attention
Hadamard rotation with seed 0.

### Dense versus SF Top-K

Each command evaluates the BF16 reference, dense fake quantization, and
SF Top-K 32/40 in one process:

```bash
python run_sparse_comparison.py \
  --model-path Qwen/Qwen3-1.7B --no-local-files-only \
  --seqlen 2048 --nsamples 64 --batch-size 1 --seed 42 \
  --mxint-bits 8 --group-size 32 --e8-scale-op ceil \
  --topk 32 40 --kl-topk 16 \
  --output results/qwen3_1_7b_int8.json

python run_sparse_comparison.py \
  --model-path Qwen/Qwen3-1.7B --no-local-files-only \
  --seqlen 2048 --nsamples 64 --batch-size 1 --seed 42 \
  --mxint-bits 4 --group-size 32 --e8-scale-op ceil \
  --attention-hadamard --attention-hadamard-seed 0 \
  --topk 32 40 --kl-topk 16 \
  --output results/qwen3_1_7b_int4_hadamard.json
```

The sweep runner enables SF attention and in-place weight quantization by
default. It defaults to local model files; `--no-local-files-only` permits
downloads for a fresh setup. Replace the model ID to evaluate another
supported architecture.

### Run the full model queue

```bash
python run_model_queue.py \
  --e8-scale-op ceil \
  --models qwen3_1_7b qwen3_4b qwen3_8b \
    llama3_2_1b smollm2_1_7b llama3_2_3b llama2_7b \
    mistral_7b pythia_6_9b gemma3_1b phi2_2_7b \
  --output-dir results/model_queue
```

The queue validates a small dense/K-all smoke run before the full MXINT8 and
MXINT4+Hadamard jobs. Each job writes a JSON report and log; `queue_state.json`
tracks progress. Rerunning the same command resumes completed work after
validation. Configure the cache with `HF_HOME` or `--hf-home`.
The queue checks available disk space before downloading uncached models.

### Inspect and verify the data

The directory includes [22 raw reports](data/results/raw/),
a [CSV summary](data/results/model_summary.csv), and a
[readable result table](data/results/model_summary.md).
The [data guide](data/README.md) defines units, sampling, provenance,
and interpretation.

```bash
python scripts/write_checksums.py --check
```

This check needs only the Python standard library and no GPU. To regenerate
the summary from the included reports, run
`python scripts/summarize_results.py`. New evaluation runs write to
`results/`; the committed benchmark data is under `data/results/`.

## Algorithm

### MXINT fake quantization

`int_quant()` groups values along the selected tensor dimension. For a
nonzero group in the symmetric `ceil` configuration, the core operation is:

```text
qmax  = 2 ** (bits - 1) - 1
xmax  = max(abs(x_group))
scale = 2 ** ceil(log2(xmax / qmax))
codes = clamp(round(x_group / scale), -qmax, qmax)
x_hat = codes * scale
```

The implementation also bounds exponents and scales to handle numerical edge
cases. `x_hat` remains floating point; `return_scale=True` additionally returns
the group scales. Here MXINT4/8 names the integer-grid simulation used by this
project, not a claim of bit-exact conformance with every MX hardware format.

`--mxint-bits` controls weights, linear activations, and attention Q/K/P/V.
Per-tensor overrides are available through `--weight-bits`,
`--activation-bits`, and `--attn-{q,k,p,v}-bits`. The measured results use
`--clip-style sym`, `--group-size 32`, and `--e8-scale-op ceil`.

### SF block selection

1. Fake-quantize Q/K and obtain scales of shape `[B,H,S,G]`.
2. Pool scales over 32-token blocks to `[B,H,N,G]`.
3. Compute block proxy scores as `Q_block_SF @ K_block_SF.transpose(-1,-2)`.
4. Restrict candidates to causal, model-visible blocks, including local-window
   masks. Apply the fixed Top-K budget independently to each query block,
   batch item, and query head.
5. Sort selected block IDs by token position, gather K/V, and evaluate QK,
   softmax, P fake quantization, and PV for those blocks.

The score depends on scaling factors rather than a dense token-level QK map.
The MX group size counts channels; the SF block size counts tokens. These are
separate settings even when both equal 32.

Mean pooling is the default. Sum pooling multiplies all scores by the same
constant for equal full blocks, preserving their ranking; partial blocks can
rank differently. Forced first/diagonal blocks consume the Top-K budget and
can be disabled using their `--no-sf-sparse-force-...` options.

### Optional attention rotation

Q and K share a normalized orthogonal rotation after RoPE. V uses a separate
rotation compensated in the O projection before weight quantization:

```text
(Q R)(K R)^T = Q K^T
W_O' = W_O blockdiag(R_V)
```

These identities describe unquantized algebra. Quantization can still change
model outputs. Non-power-of-two head dimensions use block-diagonal Hadamard
factors; Phi-2's 80 channels use 64+16 blocks.

## Metrics and limitations

- **PPL:** `exp(total_nll / predicted_tokens)`, with `S-1` predictions per
  non-overlapping length-`S` block. Compare variants within the same model;
  absolute PPL across different tokenizers is not directly comparable.
- **KL:** mean `KL(reference || evaluated)` after both distributions are
  restricted to reference-selected top-K token IDs and renormalized. This is
  not full-vocabulary KL. Metric `--kl-topk` is separate from attention
  `--topk`.
- **Top-1 agreement:** the fraction of evaluated argmax tokens matching the
  reference argmax on the same prediction positions.
- **Block sparsity:** `1 - kept_blocks / total_valid_blocks`. Reports also
  retain the causal-block baseline and executed QK-pair ratios. Gemma local
  attention has a different valid-block denominator from full causal attention.
- **Timing:** reported evaluation time includes model execution and metric
  processing. The sweep synchronizes CUDA and performs warmup. These timings
  are not standalone sparse-kernel latency measurements.
- **Coverage:** aligned prefill/PPL is supported. Unequal query/key lengths
  use a counted dense fallback by default. Training/backpropagation and
  optimized sparse kernels are outside this component.
- **Precision:** MXINT4+Hadamard can substantially degrade some models.
  The full data set includes those results; rotation does not guarantee
  preservation of PPL.
- **Datasets:** bundled measurements use WikiText-2. PG-19 and LongBench
  evaluation entry points are available, but their text and benchmark results
  are not included in this release.

## Debugging and statistics

Open this directory as the VS Code workspace, select the installed Python
environment, then use `01 | run_evaluation.py | Main flow walkthrough` for
the entry-point tour. See the [evaluation guide](docs/debug/01_run_evaluation.md)
and [SF data-flow guide](DEBUG_DATAFLOW.md) for breakpoints and tensors.

Sparse execution counters are recorded when SF attention is enabled.
Detailed quantization statistics are disabled by default. Enable
`--collect-stats` to record quantization errors, scale/code distributions,
and per-layer summaries.
Use `--plot-all-stats` for plots, or regenerate them from a saved report:

```bash
python plot_quant_stats.py results/ppl_quant_stats.json \
  --output-dir results/plots --per-layer
```

Bounded attention-map capture is available through `--plot-attention-maps`.
For all dataset, precision, and diagnostic options, run an entry point with
`--help`.

## Directory layout

| Path | Purpose |
|---|---|
| [quant/](quant/) | Layer replacement, fake quantization, SF selection, rotation, and statistics |
| [eval/](eval/) | Dataset preparation and PPL/KL/agreement evaluation |
| [configs/](configs/) | Model queue configuration |
| [data/](data/) | Experimental results, provenance, and checksums |
| [tests/](tests/) | CPU regression tests |
| [scripts/](scripts/) | Result validation and summarization |
| [docs/](docs/) | Debugging documentation |
| [environment.yml](environment.yml) | Tested Conda environment |

The core execution path is `run_evaluation.py:main` ->
`wrap_to_quant_model` -> `evaluate_model` -> model forward ->
`QuantLinear.quant_forward` / quantized attention ->
`int_quant` and SF block selection. The reference evaluation occurs before
layer replacement.

## License

Source code in this directory is licensed under Apache-2.0 and the numerical
measurements under `data/results/` under CC BY 4.0; see the license map in
[LICENSE.md](../LICENSE.md), which also states the attribution to give when
reusing the data. Model weights and dataset text remain subject to their
[upstream terms](../THIRD_PARTY.md).
