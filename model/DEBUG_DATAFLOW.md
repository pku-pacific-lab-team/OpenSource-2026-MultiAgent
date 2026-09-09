# SF sparse attention data-flow debugging

Start with the [evaluation walkthrough](docs/debug/01_run_evaluation.md) and
`01 | run_evaluation.py | Main flow walkthrough` if you are new to the
entry-point script. This guide follows Q/K fake quantization and SF selection.

All file paths below are relative to `model/`.

## Launch

1. Open `model/` as the VS Code workspace, locally or through Remote-SSH,
   so that `.vscode/launch.json` is loaded.
2. Select a Python environment that can run the evaluation and enable the
   Microsoft Python Debugger extension.
3. In **Run and Debug**, select
   `SF Dataflow: Evaluation (project code)` and press `F5`.
4. Enter the model path, bit width, Top-K budget, sequence length, sample
   count, and GPU index when prompted.

The project-code configuration uses `justMyCode=true`.
`SF Dataflow: Evaluation (full stack)` also allows stepping into
Transformers and PyTorch.

Defaults are Qwen3-8B, MXINT8, 512 tokens, one sample, 32-token blocks, and
Top-K=8. Evaluation runs the floating-point reference first. The later
wrapped-model pass enters the fake-quantization and SF-selection path.

Use a sequence length divisible by 32 and choose
`topk < seqlen / 32` to observe actual block pruning. With 512 tokens,
there are 16 key blocks and the default budget is 8.

## Breakpoint sequence

| Step | Function or statement | What to inspect |
|---|---|---|
| 1 | `run_evaluation.py: wrap_to_quant_model(...)` | The boundary between reference evaluation and module replacement |
| 2 | `quant/utils.py: wrap_to_quant_model`, `_replace_module` | Module names, parent modules, and replacements |
| 3 | `quant/quant_func.py: int_quant` | Grouping, maxima, scales, rounded integer codes, and dequantized values |
| 4 | `quant/quant_attention.py: _quantized_attention_forward` | Fake-quantized Q/K and their returned group scales |
| 5 | `quant/sparse_attention.py: pool_token_scales` | Pooling token scales into block summaries |
| 6 | `quant/sparse_attention.py: sf_block_scores` | The `Q_summary @ K_summary.T` proxy over blocks |
| 7 | `quant/sparse_attention.py: causal_topk_block_selection` | Valid candidates, forced blocks, and selected IDs |
| 8 | `quant/quant_attention.py: _sf_sparse_attention_forward` | Gathered K/V and selected-block QK, softmax, and PV |

Break on the statement after an assignment to inspect its newly assigned
value. Module replacement can prequantize weights when
`--w-quant-inplace` is enabled. Activation and attention tensor quantization
occur during forward execution.

## Conditional breakpoints

For Q/K-scale calls in `int_quant`, use:

```python
return_scale and x.ndim == 4
```

To focus on the first Qwen attention layer:

```python
self.layer_name.endswith("layers.0.self_attn")
```

Inside the query-block loop:

```python
query_block in (0, 1)
```

These expressions belong to different stack frames. `self` is available in
attention methods, while `x` and `return_scale` are local to `int_quant`.
Select the relevant frame in the call stack before using the Debug Console.

## Tensor shapes

Let `B` be batch size, `H` query heads, `S` sequence length, `D` head
dimension, `G=ceil(D/group_size)` channel groups, `T` tokens per SF block,
`N=ceil(S/T)` sequence blocks, and `K` the selection budget.

| Tensor | Shape | Meaning |
|---|---|---|
| `query_states` | `[B,H,S,D]` | Floating-point Q values after fake quantization |
| `query_scales` | `[B,H,S,G]` | Shared power-of-two scales for Q channel groups |
| `query_summary` | `[B,H,N,G]` | Pooled SF features for each token block |
| `block_scores` | `[B,H,N,N]` | SF proxy scores between query and key blocks |
| `selected_block_indices` | `[B,H,N,min(K,N)]` | Selected IDs; unused slots are padded with `-1` |
| `selected_keys` | `[B,H,active_blocks*T,D]` | Gathered keys; padded or invalid positions are masked |
| `attention_scores` | `[B,H,query_tokens,active_blocks*T]` | QK scores for one query block |

The channel-group count and attention-head count are independent of the
SF token-block count. Attention adapters pad head dimensions when needed
and crop dequantized values back to the original width. For GQA, K/V heads
are repeated to match Q heads before SF scoring.

Inspect these expressions only in frames where the variables exist:

```python
tuple(query_states.shape)
tuple(query_scales.shape)
tuple(selection.block_scores.shape)
selection.selected_block_indices[0, 0, query_block]
safe_key_positions[0, 0]
tuple(attention_scores.shape)
tuple(attention_probs.shape)
```

If execution stops only in the reference pass, disable attention breakpoints
until `wrap_to_quant_model(...)` has returned, then enable them for the
second evaluation.

Cached decoding with unequal Q/K lengths uses a counted dense fallback by
default. Use aligned prefill/PPL evaluation to inspect the sparse path.
