# run_evaluation.py: main-flow walkthrough

This guide follows evaluation setup, reference inference, module replacement,
and result calculation. Use the separate
[SF data-flow guide](../../DEBUG_DATAFLOW.md) to inspect quantization and block
selection in detail.

Paths below are relative to `model/`.

## Start the debugger

1. Open `model/` as the VS Code workspace, locally or through Remote-SSH.
2. Select the Python environment used for evaluation.
3. In **Run and Debug**, choose
   `01 | run_evaluation.py | Main flow walkthrough`.
4. Press `F5`. The script pauses on entry with `justMyCode=true`.

The default walkthrough uses one 512-token sample, MXINT8, channel groups of
32, and SF Top-K=8. Launch `run_evaluation.py`, not a package module such as
`quant/quant_linear.py`: those files use relative imports and have no
standalone evaluation entry point.

Use `F5` to reach the stage breakpoints below. Use `F10` to step over model
loading and model calls. Use `F11` only when you deliberately want to enter a
project function; `Shift+F11` returns to its caller.

## Six stage breakpoints

Choose the named statements in `main()` rather than relying on fixed line
numbers. A breakpoint pauses before its statement executes; inspect an
assignment's result on the next statement.

| Stage | Pause at | State already available |
|---|---|---|
| 1 | `reference_label = {...}` | Parsed arguments and `quant_config` |
| 2 | `print("Evaluation token blocks: ...")` | Tokenizer and `token_blocks` |
| 3 | The first `model.eval()` | Loaded pretrained model |
| 4 | `reset_quant_stats()` | Reference metrics and cached reference top-K logits |
| 5 | The second `model.eval()` | In-place module replacement has completed |
| 6 | `print("\\nEvaluation results")` | Quantized metrics, differences, and sparse statistics |

## 1. Configuration

At the first breakpoint, inspect:

```python
args.model_path
args.seqlen
args.nsamples
args.mxint_bits
args.group_size
args.topk
quant_config.to_dict()
```

For the default walkthrough, expect `seqlen=512`, `nsamples=1`, 8-bit
weight/activation/Q/K/P/V settings, `group_size=32`, `e8_scale=True`,
`sf_sparse_enabled=True`, and `sf_sparse_topk_blocks=8`.

`QuantConfig` is the class; `quant_config` is this run's instance.
`args` is an `argparse.Namespace`. These are configuration objects, not
model tensors.

## 2. Input tokens

```python
type(token_blocks)
tuple(token_blocks.shape)
token_blocks.dtype
token_blocks.device
token_blocks[0, :16]
```

Expect an integer token-ID tensor of shape `[1,512]`, initially on the CPU.
The embedding layer maps IDs to vectors during model inference.

## 3. Loaded model

The example expressions below are for Qwen3:

```python
type(model).__name__
model.config.model_type
model.config.num_hidden_layers
model.config.hidden_size
model.config.num_attention_heads
model.config.num_key_value_heads
next(model.parameters()).dtype
next(model.parameters()).device
type(model.model.layers[0].self_attn).__name__
type(model.model.layers[0].self_attn.q_proj).__name__
```

Before wrapping, the first layer normally contains `Qwen3Attention` and
ordinary `Linear` modules. The weights came from the selected pretrained
checkpoint. This evaluation uses inference mode and does not train them.

## 4. Reference evaluation

At `reset_quant_stats()`, the first `evaluate_model()` call has returned:

```python
bf16_metrics.loss
bf16_metrics.ppl
bf16_metrics.predicted_tokens
len(bf16_topk)
tuple(bf16_topk[0][0].shape)
tuple(bf16_topk[0][1].shape)
```

A 512-token block contributes 511 next-token prediction positions.
With the default `--kl-topk 16`, each cached value/ID tensor has shape
`[1,511,16]`. Inspect these cache entries only when metric Top-K is enabled.

This cache records reference vocabulary logits for KL and top-1 agreement.
It is independent of attention block Top-K.

To inspect inference output, pause inside `eval/ppl.py: evaluate_model`
after `outputs = model(...)`:

```python
tuple(batch.shape)
outputs.loss.item()
tuple(outputs.logits.shape)
outputs.logits[0, 0, :8].detach().float().cpu()
```

The final logit dimension is vocabulary size. Inspect shapes and small
slices rather than expanding the complete tensor.

## 5. Module replacement

At the second `model.eval()`, inspect:

```python
model._mxint8_wrap_summary
type(model.model.layers[0].self_attn).__name__
type(model.model.layers[0].self_attn.q_proj).__name__
model.model.layers[0].self_attn.quant_config.to_dict()
```

For Qwen3, attention becomes `QuantQwen3Attention` and projections become
`QuantLinear`. Wrapping modifies the same model in place, which is why the
reference evaluation runs first. In-place weight quantization may occur
during replacement; activation and attention tensor quantization execute in
the wrapped forward methods.

`eval/ppl.py` does not need explicit quantization calls: its `model(...)`
invocation now dispatches to the replacement modules.

## 6. Evaluated metrics

At result printing, inspect:

```python
quant_variant
quant_metrics.loss
quant_metrics.ppl
quant_metrics.topk_renormalized_kl_nats
quant_metrics.reference_top1_agreement
loss_delta
relative_change
len(sparse_stats)
```

The second pass uses the same `token_blocks`. Sparse statistics include kept
blocks, valid/causal denominators, executed QK pairs, and fallback counts.
If the dictionary is nonempty, inspect one record:

```python
first_sparse_name = next(iter(sparse_stats))
sparse_stats[first_sparse_name]
```

## Inspecting tensors and stack frames

Start with:

```python
type(x)
tuple(x.shape)
x.dtype
x.device
x.numel()
x.flatten()[:8].detach().float().cpu()
```

Each function has its own local variables. If `args` is missing while paused
inside the wrapper, select the `main()` frame in the call stack. A temporary
such as `kl_per_token` is only available inside `evaluate_model()` after that
branch has executed. Returning to `main()` exposes returned metrics, not the
callee's local variables.

After these six stages, the flow should be clear:

```text
CLI arguments -> QuantConfig -> token blocks
  -> reference evaluation -> module replacement
  -> fake-quantized/SF evaluation -> metrics and JSON
```

Continue with the [SF data-flow guide](../../DEBUG_DATAFLOW.md) for
`int_quant`, channel groups, token blocks, and Top-K selection.
