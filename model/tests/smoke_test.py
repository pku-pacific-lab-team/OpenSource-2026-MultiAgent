"""CPU smoke tests for the clean quantization path."""

from __future__ import annotations

import argparse
import json
import copy
import tempfile
from pathlib import Path

import torch
import torch.nn.functional as F
from transformers import (
    Gemma3ForCausalLM,
    Gemma3TextConfig,
    GPTNeoXConfig,
    GPTNeoXForCausalLM,
    LlamaConfig,
    LlamaForCausalLM,
    MistralConfig,
    MistralForCausalLM,
    PhiConfig,
    PhiForCausalLM,
    Qwen2Config,
    Qwen2ForCausalLM,
    Qwen3Config,
    Qwen3ForCausalLM,
)
from transformers.cache_utils import DynamicCache

from eval.ppl import evaluate_model
from run_quant_inference import prepare_prompt_inputs
from run_longbench_retrieval import length_bucket, retrieval_score
from quant.cli import (
    add_quant_format_args,
    add_sparse_attention_args,
    quant_config_kwargs,
    quant_format_label,
    validate_common_args,
)
from quant.config import QuantConfig
from quant.hadamard import (
    compensate_output_projection_weight_,
    hadamard_block_sizes,
    randomized_hadamard_matrix,
    right_rotate_head_dim,
)
from quant.quant_attention import (
    QuantGemma3Attention,
    QuantGPTNeoXAttention,
    QuantLlamaAttention,
    QuantMistralAttention,
    QuantQwen2Attention,
    QuantQwen3Attention,
    QuantPhiAttention,
)
from quant.quant_func import int_quant
from quant.quant_linear import QuantLinear
from quant.sparse_attention import (
    build_sf_topk_selection,
    causal_topk_block_selection,
    pool_token_scales,
)
from quant.stats import (
    get_quant_stats,
    get_sparse_attention_stats,
    reset_quant_stats,
    save_quant_stats,
)
from quant.utils import wrap_to_quant_model


def test_int_quant() -> None:
    x = torch.tensor(
        [[-1.0, -0.3, 0.2, 0.9, 0.0, 0.7, 1.6, -2.0]]
    )
    actual, scales = int_quant(
        x,
        8,
        group_size=4,
        e8_scale=True,
        return_scale=True,
    )
    expected = torch.tensor(
        [[-1.0, -0.296875, 0.203125, 0.90625,
          0.0, 0.6875, 1.59375, -2.0]]
    )
    expected_scales = torch.tensor([[0.015625, 0.03125]])
    torch.testing.assert_close(actual, expected)
    torch.testing.assert_close(scales, expected_scales)
    assert torch.isfinite(int_quant(torch.zeros(2, 4), 8)).all()

    int4_actual, int4_scales = int_quant(
        x,
        4,
        group_size=4,
        e8_scale=True,
        return_scale=True,
    )
    int4_expected = torch.tensor(
        [[-1.0, -0.25, 0.25, 1.0, 0.0, 0.5, 1.5, -2.0]]
    )
    torch.testing.assert_close(int4_actual, int4_expected)
    torch.testing.assert_close(
        int4_scales,
        torch.tensor([[0.25, 0.5]]),
    )


def test_quant_cli() -> None:
    parser = argparse.ArgumentParser()
    add_quant_format_args(parser)
    add_sparse_attention_args(parser, multiple_topk=True)
    args = parser.parse_args(
        [
            "--mxint-bits",
            "4",
            "--attn-p-bits",
            "8",
            "--topk",
            "8",
            "16",
            "--attention-hadamard",
            "--attention-hadamard-seed",
            "17",
        ]
    )
    validate_common_args(parser, args)
    kwargs = quant_config_kwargs(args)
    assert args.e8_scale_op == "ceil"
    assert kwargs["e8_scale_op"] == "ceil"
    assert kwargs["q1_w"] == 4
    assert kwargs["q1_x"] == 4
    assert kwargs["attn_q_bits"] == 4
    assert kwargs["attn_p_bits"] == 8
    assert kwargs["attention_hadamard"] is True
    assert kwargs["attention_hadamard_seed"] == 17
    assert args.topk == [8, 16]
    assert quant_format_label(args).startswith("Mixed-MXINT")


def test_longbench_retrieval_metric() -> None:
    assert retrieval_score("Paragraph 17", "Paragraph 17") == 1.0
    assert retrieval_score("17", "Paragraph 17") == 1.0
    assert retrieval_score("Paragraph 3", "Paragraph 17") == 0.0
    assert length_bucket(3999) == "0-4k"
    assert length_bucket(4000) == "4-8k"
    assert length_bucket(8000) == "8k+"


def test_quant_linear() -> None:
    torch.manual_seed(0)
    reset_quant_stats()
    config = QuantConfig(group_size=4, collect_stats=True)
    original = torch.nn.Linear(8, 4, bias=True)
    quant = QuantLinear.from_original_module(original, config, "test")
    x = torch.randn(2, 3, 8)
    expected = F.linear(
        int_quant(x, 8, group_size=4, e8_scale=True),
        int_quant(original.weight, 8, group_size=4, e8_scale=True),
        original.bias,
    )
    torch.testing.assert_close(quant(x), expected)
    stats = get_quant_stats()
    assert {"activation", "weight"} <= set(stats["test"])
    assert stats["test"]["activation"]["calls"] == 1
    assert stats["test"]["weight"]["calls"] == 1
    assert stats["test"]["activation"]["code_elements"] == x.numel()
    assert stats["test"]["activation"]["mae"] >= 0.0


def test_attention_hadamard_algebra() -> None:
    """Q/K scores and compensated V/O output are algebraically unchanged."""
    torch.manual_seed(7)
    qk_rotation = randomized_hadamard_matrix(
        8,
        seed=11,
        dtype=torch.float64,
    )
    v_rotation = randomized_hadamard_matrix(
        8,
        seed=12,
        dtype=torch.float64,
    )
    identity = torch.eye(8, dtype=torch.float64)
    torch.testing.assert_close(
        qk_rotation @ qk_rotation.T,
        identity,
        rtol=0.0,
        atol=1e-14,
    )

    query = torch.randn(2, 4, 5, 8, dtype=torch.float64)
    key = torch.randn(2, 4, 6, 8, dtype=torch.float64)
    value = torch.randn(2, 4, 6, 8, dtype=torch.float64)
    scores = query @ key.transpose(-1, -2)
    rotated_scores = right_rotate_head_dim(
        query,
        qk_rotation,
    ) @ right_rotate_head_dim(key, qk_rotation).transpose(-1, -2)
    torch.testing.assert_close(rotated_scores, scores, rtol=1e-12, atol=1e-12)

    probabilities = torch.softmax(scores, dim=-1)
    attention_output = (probabilities @ value).transpose(1, 2).reshape(2, 5, 32)
    rotated_value = right_rotate_head_dim(value, v_rotation)
    rotated_output = (
        (probabilities @ rotated_value).transpose(1, 2).reshape(2, 5, 32)
    )
    output_weight = torch.randn(32, 32, dtype=torch.float64)
    compensated_weight = output_weight.clone()
    inferred_heads = compensate_output_projection_weight_(
        compensated_weight,
        v_rotation,
        head_dim=8,
    )
    assert inferred_heads == 4
    torch.testing.assert_close(
        F.linear(rotated_output, compensated_weight),
        F.linear(attention_output, output_weight),
        rtol=1e-12,
        atol=1e-12,
    )

    # Phi-2 uses head_dim=80. A 64+16 block-Hadamard remains orthogonal
    # and therefore preserves the same QK and V/O algebra.
    assert hadamard_block_sizes(80) == (64, 16)
    rotation_80 = randomized_hadamard_matrix(
        80,
        seed=19,
        dtype=torch.float64,
    )
    torch.testing.assert_close(
        rotation_80 @ rotation_80.T,
        torch.eye(80, dtype=torch.float64),
        rtol=0.0,
        atol=1e-14,
    )


def test_sf_block_selection() -> None:
    scales = torch.tensor(
        [[[[1.0, 2.0], [3.0, 4.0], [5.0, 6.0], [7.0, 8.0],
           [9.0, 10.0]]]]
    )
    pooled, counts = pool_token_scales(scales, block_size=2)
    expected = torch.tensor(
        [[[[2.0, 3.0], [6.0, 7.0], [9.0, 10.0]]]]
    )
    torch.testing.assert_close(pooled, expected)
    torch.testing.assert_close(counts, torch.tensor([2, 2, 1]))

    selection = build_sf_topk_selection(
        scales,
        scales,
        block_size=2,
        topk_blocks=2,
    )
    assert selection.block_scores.shape == (1, 1, 3, 3)
    expected_mask = torch.tensor(
        [[[[True, False, False],
           [True, True, False],
           [True, False, True]]]]
    )
    torch.testing.assert_close(selection.block_mask, expected_mask)
    expected_indices = torch.tensor(
        [[[[0, -1], [0, 1], [0, 2]]]]
    )
    torch.testing.assert_close(
        selection.selected_block_indices,
        expected_indices,
    )

    manual_scores = torch.zeros(1, 1, 4, 4)
    manual_scores[0, 0, 3, 1] = 9.0
    manual_scores[0, 0, 3, 2] = 1.0
    _, manual_indices = causal_topk_block_selection(
        manual_scores,
        topk_blocks=3,
    )
    torch.testing.assert_close(
        manual_indices[0, 0, 3],
        torch.tensor([0, 1, 3]),
    )


def test_mask_aware_sf_block_selection() -> None:
    scales = torch.ones(1, 1, 16, 1)
    scales[:, :, :8] = 100.0
    block_valid_mask = torch.tensor(
        [[[[True, False, False, False],
           [True, True, False, False],
           [False, True, True, False],
           [False, False, True, True]]]]
    )
    selection = build_sf_topk_selection(
        scales,
        scales,
        block_size=4,
        topk_blocks=3,
        block_valid_mask=block_valid_mask,
    )
    torch.testing.assert_close(
        selection.candidate_block_mask,
        block_valid_mask,
    )
    torch.testing.assert_close(
        selection.selected_block_indices[0, 0, 3],
        torch.tensor([2, 3, -1]),
    )
    assert not selection.block_mask[0, 0, 3, 0]


def test_prompt_tokenization_without_chat_template() -> None:
    class DummyTokenizer:
        chat_template = None

        def __call__(self, prompt, *, return_tensors):
            assert prompt == "hello"
            assert return_tensors == "pt"
            return {"input_ids": torch.tensor([[1, 2]])}

        def apply_chat_template(self, *args, **kwargs):
            raise AssertionError("chat template should not be used")

    tokenizer = DummyTokenizer()
    inputs = prepare_prompt_inputs(tokenizer, "hello", "auto")
    torch.testing.assert_close(inputs["input_ids"], torch.tensor([[1, 2]]))
    try:
        prepare_prompt_inputs(tokenizer, "hello", "chat")
    except ValueError as error:
        assert "requires tokenizer.chat_template" in str(error)
    else:
        raise AssertionError("chat mode must reject a missing chat template")


def _tiny_qwen3_config() -> Qwen3Config:
    config = Qwen3Config(
        vocab_size=128,
        hidden_size=128,
        intermediate_size=256,
        num_hidden_layers=1,
        num_attention_heads=4,
        num_key_value_heads=2,
        head_dim=32,
        max_position_embeddings=64,
        attention_dropout=0.0,
        tie_word_embeddings=False,
    )
    config._attn_implementation = "eager"
    return config


def test_tiny_sf_sparse_attention() -> None:
    torch.manual_seed(1)
    original = Qwen3ForCausalLM(_tiny_qwen3_config()).to(
        dtype=torch.bfloat16
    )
    dense_model = copy.deepcopy(original)
    all_blocks_model = copy.deepcopy(original)
    sparse_model = copy.deepcopy(original)
    wrap_to_quant_model(
        dense_model,
        QuantConfig(group_size=32),
        verbose=False,
    )
    wrap_to_quant_model(
        all_blocks_model,
        QuantConfig(
            group_size=32,
            sf_sparse_enabled=True,
            sf_sparse_block_size=4,
            sf_sparse_topk_blocks=3,
        ),
        verbose=False,
    )
    wrap_to_quant_model(
        sparse_model,
        QuantConfig(
            group_size=32,
            attention_hadamard=True,
            attention_hadamard_seed=5,
            sf_sparse_enabled=True,
            sf_sparse_block_size=4,
            sf_sparse_topk_blocks=2,
        ),
        verbose=False,
    )
    input_ids = torch.tensor([[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]])
    dense_model.eval()
    all_blocks_model.eval()
    sparse_model.eval()
    with torch.inference_mode():
        dense_logits = dense_model(input_ids=input_ids, use_cache=False).logits
        all_blocks_logits = all_blocks_model(
            input_ids=input_ids,
            use_cache=False,
        ).logits
        reset_quant_stats()
        sparse_logits = sparse_model(
            input_ids=input_ids,
            use_cache=False,
        ).logits
    torch.testing.assert_close(
        all_blocks_logits,
        dense_logits,
        rtol=2e-2,
        atol=2e-2,
    )
    assert torch.isfinite(sparse_logits).all()
    sparse_stats = get_sparse_attention_stats()
    record = sparse_stats["model.layers.0.self_attn"]
    assert record["kept_block_ratio"] < 1.0
    assert record["qk_compute_ratio"] < 1.0
    assert record["fallback_calls"] == 0


def test_tiny_attention_hadamard() -> None:
    """Exercise full-model equivalence, KV-cache use, and inplace W4 order."""
    torch.manual_seed(3)
    reference = Qwen3ForCausalLM(_tiny_qwen3_config()).eval()
    rotated = copy.deepcopy(reference)
    input_ids = torch.tensor([[1, 2, 3, 4, 5, 6, 7, 8]])
    with torch.inference_mode():
        reference_logits = reference(
            input_ids=input_ids,
            use_cache=False,
        ).logits

    exact_config = QuantConfig(
        q1_w=16,
        q1_x=16,
        attn_q_bits=16,
        attn_k_bits=16,
        attn_p_bits=16,
        attn_v_bits=16,
        group_size=32,
        attention_hadamard=True,
        attention_hadamard_seed=23,
    )
    wrap_to_quant_model(rotated, exact_config, verbose=False)
    attention = rotated.model.layers[0].self_attn
    assert attention.attention_hadamard is True
    torch.testing.assert_close(
        attention.qk_hadamard @ attention.qk_hadamard.T,
        torch.eye(attention.head_dim),
        rtol=1e-5,
        atol=1e-5,
    )
    with torch.inference_mode():
        rotated_logits = rotated(
            input_ids=input_ids,
            use_cache=False,
        ).logits
        generated = rotated.generate(
            input_ids=input_ids,
            max_new_tokens=2,
            do_sample=False,
            pad_token_id=0,
        )
    torch.testing.assert_close(
        rotated_logits,
        reference_logits,
        rtol=2e-4,
        atol=2e-4,
    )
    assert generated.shape == (1, 10)
    assert torch.isfinite(rotated_logits).all()

    quantized = copy.deepcopy(reference)
    original_o_weight = (
        quantized.model.layers[0].self_attn.o_proj.weight.detach().clone()
    )
    quant_config = QuantConfig(
        q1_w=4,
        q1_x=4,
        group_size=32,
        w_quant_inplace=True,
        attention_hadamard=True,
        attention_hadamard_seed=23,
        attn_q_bits=4,
        attn_k_bits=4,
        attn_p_bits=4,
        attn_v_bits=4,
    )
    wrap_to_quant_model(quantized, quant_config, verbose=False)
    quant_attention = quantized.model.layers[0].self_attn
    expected_o_weight = original_o_weight.clone()
    compensate_output_projection_weight_(
        expected_o_weight,
        quant_attention.v_hadamard,
        head_dim=quant_attention.head_dim,
    )
    expected_o_weight = int_quant(
        expected_o_weight,
        4,
        group_size=32,
        e8_scale=True,
    )
    assert quant_attention.o_proj.weight_prequantized is True
    torch.testing.assert_close(
        quant_attention.o_proj.weight,
        expected_o_weight,
    )


def test_tiny_gpt_neox_hadamard_equivalence() -> None:
    """Check packed-QKV partial-RoPE equivalence and cache generation."""
    torch.manual_seed(13)
    config = GPTNeoXConfig(
        vocab_size=128,
        hidden_size=128,
        intermediate_size=256,
        num_hidden_layers=1,
        num_attention_heads=4,
        max_position_embeddings=64,
        rotary_pct=0.25,
        attention_dropout=0.0,
        hidden_dropout=0.0,
        tie_word_embeddings=False,
    )
    config._attn_implementation = "eager"
    reference = GPTNeoXForCausalLM(config).eval()
    rotated = copy.deepcopy(reference)
    input_ids = torch.tensor([[1, 2, 3, 4, 5, 6, 7, 8]])
    with torch.inference_mode():
        reference_logits = reference(
            input_ids=input_ids,
            use_cache=False,
        ).logits

    wrap_to_quant_model(
        rotated,
        QuantConfig(
            q1_w=16,
            q1_x=16,
            attn_q_bits=16,
            attn_k_bits=16,
            attn_p_bits=16,
            attn_v_bits=16,
            group_size=32,
            attention_hadamard=True,
            attention_hadamard_seed=29,
        ),
        verbose=False,
    )
    rotated.eval()
    with torch.inference_mode():
        rotated_logits = rotated(
            input_ids=input_ids,
            use_cache=False,
        ).logits
        generated = rotated.generate(
            input_ids=input_ids,
            max_new_tokens=2,
            do_sample=False,
            pad_token_id=0,
        )
    torch.testing.assert_close(
        rotated_logits,
        reference_logits,
        rtol=2e-4,
        atol=2e-4,
    )
    assert generated.shape == (1, 10)


def test_tiny_qwen3() -> None:
    model = Qwen3ForCausalLM(_tiny_qwen3_config()).to(dtype=torch.bfloat16)
    reset_quant_stats()
    quant_config = QuantConfig(group_size=32, collect_stats=True)
    wrap_to_quant_model(model, quant_config, verbose=False)
    wrap_to_quant_model(model, quant_config, verbose=False)

    assert isinstance(model.model.layers[0].self_attn, QuantQwen3Attention)
    assert isinstance(model.model.layers[0].self_attn.q_proj, QuantLinear)
    assert isinstance(model.lm_head, torch.nn.Linear)

    model.eval()
    input_ids = torch.tensor([[1, 2, 3, 4, 5, 6, 7, 8]])
    with torch.inference_mode():
        output = model(input_ids=input_ids, use_cache=False)
        generated = model.generate(
            input_ids=input_ids,
            max_new_tokens=2,
            do_sample=False,
            pad_token_id=0,
        )
    assert output.logits.shape == (1, 8, 128)
    assert torch.isfinite(output.logits).all()
    assert generated.shape == (1, 10)

    reference_metrics, reference_topk = evaluate_model(
        model,
        input_ids,
        batch_size=1,
        description="tiny reference metrics",
        cache_reference_topk=8,
    )
    repeated_metrics, _ = evaluate_model(
        model,
        input_ids,
        batch_size=1,
        description="tiny repeated metrics",
        reference_topk=reference_topk,
    )
    assert reference_metrics.predicted_tokens == 7
    assert repeated_metrics.topk_renormalized_kl_nats is not None
    assert abs(repeated_metrics.topk_renormalized_kl_nats) < 1e-7
    assert repeated_metrics.reference_top1_agreement == 1.0

    stats = get_quant_stats()
    attention_stats = stats["model.layers.0.self_attn"]
    assert {"q", "k", "v", "p"} <= set(attention_stats)
    assert attention_stats["p"]["calls"] >= 1
    assert attention_stats["p"]["scale_elements"] >= 1
    assert attention_stats["q"]["per_head_integer_code_histogram"]

    with tempfile.TemporaryDirectory() as directory:
        output_path = Path(directory) / "stats.json"
        save_quant_stats(
            output_path,
            config=quant_config.to_dict(),
            metadata={"test": True},
        )
        with output_path.open(encoding="utf-8") as handle:
            payload = json.load(handle)
        assert payload["format_version"] == 1
        assert payload["metadata"]["test"] is True
        assert "model.layers.0.self_attn" in payload["records"]


def test_other_rotary_model_adapters() -> None:
    common = {
        "vocab_size": 128,
        "hidden_size": 128,
        "intermediate_size": 256,
        "num_hidden_layers": 1,
        "num_attention_heads": 4,
        "num_key_value_heads": 2,
        "max_position_embeddings": 64,
        "attention_dropout": 0.0,
        "tie_word_embeddings": False,
    }
    cases = (
        (
            LlamaForCausalLM(LlamaConfig(**common)),
            QuantLlamaAttention,
            "model.layers.0.self_attn",
        ),
        (
            Qwen2ForCausalLM(Qwen2Config(**common)),
            QuantQwen2Attention,
            "model.layers.0.self_attn",
        ),
        (
            MistralForCausalLM(MistralConfig(**common)),
            QuantMistralAttention,
            "model.layers.0.self_attn",
        ),
        (
            GPTNeoXForCausalLM(
                GPTNeoXConfig(
                    vocab_size=128,
                    hidden_size=128,
                    intermediate_size=256,
                    num_hidden_layers=1,
                    num_attention_heads=4,
                    max_position_embeddings=64,
                    rotary_pct=0.25,
                    attention_dropout=0.0,
                    hidden_dropout=0.0,
                    tie_word_embeddings=False,
                )
            ),
            QuantGPTNeoXAttention,
            "gpt_neox.layers.0.attention",
        ),
        (
            Gemma3ForCausalLM(
                Gemma3TextConfig(
                    vocab_size=128,
                    hidden_size=128,
                    intermediate_size=256,
                    num_hidden_layers=1,
                    num_attention_heads=4,
                    num_key_value_heads=2,
                    head_dim=32,
                    max_position_embeddings=64,
                    sliding_window=32,
                    attention_dropout=0.0,
                    tie_word_embeddings=False,
                )
            ),
            QuantGemma3Attention,
            "model.layers.0.self_attn",
        ),
        (
            PhiForCausalLM(
                PhiConfig(
                    vocab_size=128,
                    hidden_size=160,
                    intermediate_size=320,
                    num_hidden_layers=1,
                    num_attention_heads=4,
                    num_key_value_heads=4,
                    max_position_embeddings=64,
                    attention_dropout=0.0,
                    resid_pdrop=0.0,
                    embd_pdrop=0.0,
                    tie_word_embeddings=False,
                )
            ),
            QuantPhiAttention,
            "model.layers.0.self_attn",
        ),
    )
    input_ids = torch.tensor([[1, 2, 3, 4, 5, 6, 7, 8]])
    for model, expected_attention_type, attention_path in cases:
        model.config._attn_implementation = "eager"
        reference = copy.deepcopy(model).eval()
        exact_rotated = copy.deepcopy(model).eval()
        wrap_to_quant_model(
            exact_rotated,
            QuantConfig(
                q1_w=16,
                q1_x=16,
                attn_q_bits=16,
                attn_k_bits=16,
                attn_p_bits=16,
                attn_v_bits=16,
                group_size=32,
                attention_hadamard=True,
                attention_hadamard_seed=7,
            ),
            verbose=False,
        )
        with torch.inference_mode():
            reference_logits = reference(
                input_ids=input_ids,
                use_cache=False,
            ).logits
            exact_logits = exact_rotated(
                input_ids=input_ids,
                use_cache=False,
            ).logits
        torch.testing.assert_close(
            exact_logits,
            reference_logits,
            rtol=2e-4,
            atol=2e-4,
        )

        model.to(dtype=torch.bfloat16)
        wrap_to_quant_model(
            model,
            QuantConfig(
                group_size=32,
                attention_hadamard=True,
                attention_hadamard_seed=7,
                sf_sparse_enabled=True,
                sf_sparse_block_size=4,
                sf_sparse_topk_blocks=2,
            ),
            verbose=False,
        )
        assert isinstance(
            model.get_submodule(attention_path),
            expected_attention_type,
        )
        assert isinstance(model.get_output_embeddings(), torch.nn.Linear)
        model.eval()
        with torch.inference_mode():
            logits = model(input_ids=input_ids, use_cache=False).logits
        assert logits.shape == (1, 8, 128)
        assert torch.isfinite(logits).all()


def test_gemma_sliding_window_sparse_equivalence() -> None:
    config = Gemma3TextConfig(
        vocab_size=128,
        hidden_size=128,
        intermediate_size=256,
        num_hidden_layers=1,
        num_attention_heads=4,
        num_key_value_heads=2,
        head_dim=32,
        max_position_embeddings=64,
        sliding_window=8,
        attention_dropout=0.0,
        tie_word_embeddings=False,
    )
    config.layer_types = ["sliding_attention"]
    config._attn_implementation = "eager"
    original = Gemma3ForCausalLM(config).to(dtype=torch.bfloat16)
    dense = copy.deepcopy(original).eval()
    sparse = copy.deepcopy(original).eval()
    wrap_to_quant_model(dense, QuantConfig(group_size=32), verbose=False)
    wrap_to_quant_model(
        sparse,
        QuantConfig(
            group_size=32,
            sf_sparse_enabled=True,
            sf_sparse_block_size=4,
            sf_sparse_topk_blocks=4,
        ),
        verbose=False,
    )
    input_ids = torch.arange(1, 17).unsqueeze(0)
    with torch.inference_mode():
        dense_logits = dense(input_ids=input_ids, use_cache=False).logits
        reset_quant_stats()
        sparse_logits = sparse(input_ids=input_ids, use_cache=False).logits
    torch.testing.assert_close(
        sparse_logits,
        dense_logits,
        rtol=2e-2,
        atol=2e-2,
    )
    record = get_sparse_attention_stats()["model.layers.0.self_attn"]
    assert record["total_valid_blocks"] < record["total_causal_blocks"]
    assert record["kept_blocks"] == record["total_valid_blocks"]
    assert record["block_sparsity_ratio"] == 0.0


def test_phi_head80_partial_quant_group() -> None:
    config = PhiConfig(
        vocab_size=128,
        hidden_size=320,
        intermediate_size=640,
        num_hidden_layers=1,
        num_attention_heads=4,
        num_key_value_heads=4,
        max_position_embeddings=64,
        attention_dropout=0.0,
        resid_pdrop=0.0,
        embd_pdrop=0.0,
        tie_word_embeddings=False,
    )
    config._attn_implementation = "eager"
    model = PhiForCausalLM(config)
    wrap_to_quant_model(model, QuantConfig(group_size=32), verbose=False)
    attention = model.model.layers[0].self_attn
    values = torch.randn(1, 4, 7, 80)
    quantized, scales = attention._fake_quant_last_dim(
        values,
        8,
        "q",
        pad_to_group=True,
        return_scale=True,
    )
    assert quantized.shape == values.shape
    assert scales.shape == (1, 4, 7, 3)
    assert torch.isfinite(quantized).all()
    assert torch.isfinite(scales).all()


def test_phi_legacy_cache_alias() -> None:
    config = PhiConfig(
        vocab_size=128,
        hidden_size=128,
        intermediate_size=256,
        num_hidden_layers=1,
        num_attention_heads=4,
        num_key_value_heads=4,
        max_position_embeddings=64,
        attention_dropout=0.0,
        resid_pdrop=0.0,
        embd_pdrop=0.0,
        tie_word_embeddings=False,
    )
    config._attn_implementation = "eager"
    model = PhiForCausalLM(config).eval()
    wrap_to_quant_model(
        model,
        QuantConfig(
            q1_w=16,
            q1_x=16,
            attn_q_bits=16,
            attn_k_bits=16,
            attn_p_bits=16,
            attn_v_bits=16,
            group_size=32,
        ),
        verbose=False,
    )
    input_ids = torch.tensor([[1, 2, 3, 4]])
    hidden_states = model.get_input_embeddings()(input_ids)
    position_ids = torch.arange(4).unsqueeze(0)
    position_embeddings = model.model.rotary_emb(hidden_states, position_ids)
    attention_mask = torch.zeros(1, 1, 4, 4)
    attention_mask.masked_fill_(
        torch.triu(torch.ones_like(attention_mask, dtype=torch.bool), diagonal=1),
        -torch.inf,
    )
    cache = DynamicCache(config=model.config)
    with torch.inference_mode():
        model.model.layers[0].self_attn(
            hidden_states=hidden_states,
            position_embeddings=position_embeddings,
            attention_mask=attention_mask,
            past_key_value=cache,
            cache_position=torch.arange(4),
        )
    assert cache.get_seq_length() == 4


def test_new_adapter_sparse_generation() -> None:
    gemma_config = Gemma3TextConfig(
        vocab_size=128,
        hidden_size=128,
        intermediate_size=256,
        num_hidden_layers=1,
        num_attention_heads=4,
        num_key_value_heads=2,
        head_dim=32,
        max_position_embeddings=64,
        sliding_window=32,
        attention_dropout=0.0,
        tie_word_embeddings=False,
    )
    phi_config = PhiConfig(
        vocab_size=128,
        hidden_size=128,
        intermediate_size=256,
        num_hidden_layers=1,
        num_attention_heads=4,
        num_key_value_heads=4,
        max_position_embeddings=64,
        attention_dropout=0.0,
        resid_pdrop=0.0,
        embd_pdrop=0.0,
        tie_word_embeddings=False,
    )
    for model in (
        Gemma3ForCausalLM(gemma_config),
        PhiForCausalLM(phi_config),
    ):
        model.config._attn_implementation = "eager"
        model.to(dtype=torch.bfloat16).eval()
        wrap_to_quant_model(
            model,
            QuantConfig(
                group_size=32,
                sf_sparse_enabled=True,
                sf_sparse_block_size=4,
                sf_sparse_topk_blocks=2,
            ),
            verbose=False,
        )
        reset_quant_stats()
        with torch.inference_mode():
            generated = model.generate(
                input_ids=torch.tensor([[1, 2, 3, 4, 5, 6, 7, 8]]),
                max_new_tokens=2,
                do_sample=False,
                pad_token_id=0,
                eos_token_id=127,
            )
        assert generated.shape == (1, 10)
        assert sum(
            record["fallback_calls"]
            for record in get_sparse_attention_stats().values()
        ) > 0


if __name__ == "__main__":
    test_int_quant()
    test_quant_cli()
    test_longbench_retrieval_metric()
    test_quant_linear()
    test_attention_hadamard_algebra()
    test_sf_block_selection()
    test_mask_aware_sf_block_selection()
    test_prompt_tokenization_without_chat_template()
    test_tiny_sf_sparse_attention()
    test_tiny_attention_hadamard()
    test_tiny_gpt_neox_hadamard_equivalence()
    test_tiny_qwen3()
    test_other_rotary_model_adapters()
    test_gemma_sliding_window_sparse_equivalence()
    test_phi_head80_partial_quant_group()
    test_phi_legacy_cache_alias()
    test_new_adapter_sparse_generation()
    print("All clean MXINT CPU smoke tests passed.")
