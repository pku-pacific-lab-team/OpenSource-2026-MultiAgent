"""Run a configurable MXINT fake-quantized generation smoke test."""

from __future__ import annotations

import argparse

import torch
from transformers import AutoModelForCausalLM, AutoTokenizer

from quant.cli import (
    add_quant_format_args,
    add_sparse_attention_args,
    quant_config_kwargs,
    sparse_config_kwargs,
    torch_dtype_from_name,
    validate_common_args,
)
from quant.config import QuantConfig
from quant.plotting import plot_attention_maps, plot_quant_stats
from quant.stats import (
    get_quant_stats,
    get_sparse_attention_stats,
    reset_quant_stats,
    save_quant_stats,
)
from quant.utils import wrap_to_quant_model


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--model-path", default="Qwen/Qwen3-8B")
    parser.add_argument(
        "--local-files-only",
        action=argparse.BooleanOptionalAction,
        default=False,
    )
    parser.add_argument("--prompt", default="Introduce yourself in one sentence.")
    parser.add_argument(
        "--prompt-format",
        choices=("auto", "chat", "text"),
        default="auto",
        help=(
            "auto uses a tokenizer chat template when available and otherwise "
            "tokenizes the prompt as plain text"
        ),
    )
    parser.add_argument("--max-new-tokens", type=int, default=32)
    add_quant_format_args(parser)
    add_sparse_attention_args(parser)
    parser.add_argument("--collect-stats", action="store_true")
    parser.add_argument(
        "--stats-output",
        default="results/inference_quant_stats.json",
    )
    parser.add_argument("--plot-all-stats", action="store_true")
    parser.add_argument("--plot-per-layer", action="store_true")
    parser.add_argument("--plot-attention-maps", action="store_true")
    parser.add_argument("--plot-output-dir", default="results/inference_plots")
    parser.add_argument("--attention-map-max-tokens", type=int, default=256)
    parser.add_argument("--attention-map-max-heads", type=int, default=4)
    args = parser.parse_args()
    validate_common_args(parser, args)
    if args.max_new_tokens < 1:
        parser.error("--max-new-tokens must be positive")
    return args


def make_quant_config(args: argparse.Namespace) -> QuantConfig:
    return QuantConfig(
        **quant_config_kwargs(args),
        **sparse_config_kwargs(args),
        collect_stats=(
            args.collect_stats or args.plot_all_stats or args.plot_per_layer
        ),
        capture_attention_maps=args.plot_attention_maps,
        attention_map_max_tokens=args.attention_map_max_tokens,
        attention_map_max_heads=args.attention_map_max_heads,
    )


def prepare_prompt_inputs(tokenizer, prompt: str, prompt_format: str):
    """Tokenize chat or base-model prompts without assuming a chat template."""
    has_chat_template = bool(getattr(tokenizer, "chat_template", None))
    use_chat_template = prompt_format == "chat" or (
        prompt_format == "auto" and has_chat_template
    )
    if use_chat_template:
        if not has_chat_template:
            raise ValueError(
                "--prompt-format chat requires tokenizer.chat_template; "
                "use --prompt-format text for a base model"
            )
        return tokenizer.apply_chat_template(
            [{"role": "user", "content": prompt}],
            add_generation_prompt=True,
            tokenize=True,
            return_dict=True,
            return_tensors="pt",
        )
    return tokenizer(prompt, return_tensors="pt")


def main() -> None:
    args = parse_args()
    quant_config = make_quant_config(args)
    print("Quantization configuration:")
    for key, value in quant_config.to_dict().items():
        print(f"  {key}: {value}")

    tokenizer = AutoTokenizer.from_pretrained(
        args.model_path,
        trust_remote_code=True,
        local_files_only=args.local_files_only,
    )
    model = AutoModelForCausalLM.from_pretrained(
        args.model_path,
        trust_remote_code=True,
        local_files_only=args.local_files_only,
        device_map="auto",
        dtype=torch_dtype_from_name(args.model_dtype),
        attn_implementation="eager",
    )
    reset_quant_stats()
    wrap_to_quant_model(model, quant_config)
    model.eval()

    inputs = prepare_prompt_inputs(
        tokenizer,
        args.prompt,
        args.prompt_format,
    )
    input_device = model.get_input_embeddings().weight.device
    inputs = {key: value.to(input_device) for key, value in inputs.items()}

    with torch.inference_mode():
        outputs = model.generate(
            **inputs,
            max_new_tokens=args.max_new_tokens,
            do_sample=False,
            pad_token_id=tokenizer.eos_token_id,
        )

    prompt_length = inputs["input_ids"].shape[-1]
    response_ids = outputs[0, prompt_length:]
    print("\nModel response:")
    response_text = tokenizer.decode(response_ids, skip_special_tokens=True)
    print(response_text)

    if quant_config.collect_stats or quant_config.sf_sparse_enabled:
        stats_path = save_quant_stats(
            args.stats_output,
            config=quant_config.to_dict(),
            metadata={
                "model_path": args.model_path,
                "prompt_tokens": prompt_length,
                "generated_tokens": response_ids.numel(),
                "mode": "generation",
            },
        )
        print(f"\nQuantization statistics saved to: {stats_path}")

    sparse_stats = get_sparse_attention_stats()
    if sparse_stats:
        total_blocks = sum(
            record["total_valid_blocks"] for record in sparse_stats.values()
        )
        kept_blocks = sum(
            record["kept_blocks"] for record in sparse_stats.values()
        )
        dense_pairs = sum(
            record["dense_qk_pairs"] for record in sparse_stats.values()
        )
        executed_pairs = sum(
            record["executed_qk_pairs"] for record in sparse_stats.values()
        )
        if total_blocks:
            print(f"SF kept-block ratio: {kept_blocks / total_blocks:.3%}")
        if dense_pairs:
            print(
                "Selected QK pair ratio: "
                f"{executed_pairs / dense_pairs:.3%}"
            )

    if args.plot_all_stats or args.plot_per_layer:
        plot_paths = plot_quant_stats(
            {
                "records": get_quant_stats(),
                "sparse_attention": sparse_stats,
            },
            args.plot_output_dir,
            per_layer=args.plot_per_layer,
        )
        print(
            f"Quantization plots saved: {len(plot_paths)} in "
            f"{args.plot_output_dir}"
        )

    if args.plot_attention_maps:
        attention_paths = plot_attention_maps(model, args.plot_output_dir)
        print(
            f"Attention-map plots saved: {len(attention_paths)} in "
            f"{args.plot_output_dir}/attention_maps"
        )


if __name__ == "__main__":
    main()
