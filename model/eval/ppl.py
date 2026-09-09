"""Causal-LM perplexity and BF16-reference agreement metrics."""

from __future__ import annotations

import math
from dataclasses import asdict, dataclass
from typing import Optional

import torch
import torch.nn.functional as F
from tqdm import tqdm


ReferenceTopK = list[tuple[torch.Tensor, torch.Tensor]]


@dataclass(frozen=True)
class EvaluationMetrics:
    """Token-weighted metrics for one model pass."""

    loss: float
    ppl: float
    total_nll: float
    predicted_tokens: int
    topk_renormalized_kl_nats: Optional[float] = None
    topk_renormalized_kl_micro_nats: Optional[float] = None
    reference_top1_agreement: Optional[float] = None
    reference_topk: Optional[int] = None

    def to_dict(self) -> dict[str, float | int | None]:
        return asdict(self)


@torch.inference_mode()
def evaluate_model(
    model,
    token_blocks: torch.Tensor,
    *,
    batch_size: int,
    description: str,
    cache_reference_topk: int = 0,
    reference_topk: Optional[ReferenceTopK] = None,
) -> tuple[EvaluationMetrics, ReferenceTopK]:
    """Evaluate PPL and optionally cache/compare BF16 top-k logits.

    PPL uses the Hugging Face causal-LM loss, which predicts positions
    ``1..S-1``.  Every batch loss is therefore weighted by ``B * (S - 1)``.

    The optional KL is intentionally named *top-k renormalized KL*: both BF16
    and evaluated-model logits are restricted to the ids selected by BF16 and
    renormalized on that subset.  It is a useful agreement diagnostic but is
    not the full-vocabulary KL divergence.
    """
    if batch_size < 1:
        raise ValueError("batch_size must be positive")
    if (
        token_blocks.ndim != 2
        or token_blocks.shape[0] < 1
        or token_blocks.shape[1] < 2
    ):
        raise ValueError("token_blocks must have shape [N, S] with N >= 1, S >= 2")

    model.eval()
    input_device = model.get_input_embeddings().weight.device
    total_nll = 0.0
    total_tokens = 0
    cached_topk: ReferenceTopK = []
    kl_sum = 0.0
    agreement_count = 0
    reference_tokens = 0
    reference_batches_used = 0

    starts = range(0, token_blocks.shape[0], batch_size)
    for batch_index, start in enumerate(tqdm(starts, desc=description)):
        batch = token_blocks[start : start + batch_size].to(input_device)
        outputs = model(
            input_ids=batch,
            labels=batch,
            use_cache=False,
        )
        predicted_tokens = batch.shape[0] * (batch.shape[1] - 1)
        batch_loss = outputs.loss.float().item()
        total_nll += batch_loss * predicted_tokens
        total_tokens += predicted_tokens

        if cache_reference_topk > 0 or reference_topk is not None:
            # Logit position t predicts label position t+1.  The final logit
            # has no label in this non-overlapping-block PPL definition.
            shifted_logits = outputs.logits[:, :-1, :].float()

        if cache_reference_topk > 0:
            k = min(cache_reference_topk, shifted_logits.shape[-1])
            values, indices = torch.topk(shifted_logits, k=k, dim=-1)
            cached_topk.append((values.cpu(), indices.cpu()))

        if reference_topk is not None:
            if batch_index >= len(reference_topk):
                raise ValueError("reference_topk has fewer batches than input")
            reference_logits_cpu, reference_ids_cpu = reference_topk[batch_index]
            reference_logits = reference_logits_cpu.to(
                shifted_logits.device,
                dtype=torch.float32,
            )
            reference_ids = reference_ids_cpu.to(shifted_logits.device)
            if reference_ids.shape[:-1] != shifted_logits.shape[:-1]:
                raise ValueError(
                    "reference top-k leading dimensions do not match logits"
                )
            evaluated_logits = torch.gather(
                shifted_logits,
                dim=-1,
                index=reference_ids,
            )
            reference_probs = reference_logits.softmax(dim=-1)
            evaluated_log_probs = evaluated_logits.log_softmax(dim=-1)
            kl_per_token = F.kl_div(
                evaluated_log_probs,
                reference_probs,
                reduction="none",
            ).sum(dim=-1)
            kl_sum += float(kl_per_token.double().sum().item())
            reference_tokens += kl_per_token.numel()
            agreement_count += int(
                (
                    shifted_logits.argmax(dim=-1)
                    == reference_ids[..., 0]
                ).sum().item()
            )
            reference_batches_used += 1

    if total_tokens == 0:
        raise ValueError("no predicted tokens were evaluated")
    if reference_topk is not None and reference_batches_used != len(reference_topk):
        raise ValueError("reference_topk has more batches than input")

    mean_loss = total_nll / total_tokens
    mean_kl = kl_sum / reference_tokens if reference_tokens else None
    agreement = (
        agreement_count / reference_tokens if reference_tokens else None
    )
    reference_k = (
        int(reference_topk[0][1].shape[-1])
        if reference_topk
        else (min(cache_reference_topk, outputs.logits.shape[-1])
              if cache_reference_topk > 0 else None)
    )
    metrics = EvaluationMetrics(
        loss=mean_loss,
        ppl=math.exp(mean_loss),
        total_nll=total_nll,
        predicted_tokens=total_tokens,
        topk_renormalized_kl_nats=mean_kl,
        topk_renormalized_kl_micro_nats=(
            mean_kl * 1e6 if mean_kl is not None else None
        ),
        reference_top1_agreement=agreement,
        reference_topk=reference_k,
    )
    return metrics, cached_topk


@torch.inference_mode()
def evaluate_ppl(
    model,
    token_blocks: torch.Tensor,
    *,
    batch_size: int,
    description: str,
) -> tuple[float, float]:
    """Backward-compatible ``(ppl, loss)`` wrapper."""
    metrics, _ = evaluate_model(
        model,
        token_blocks,
        batch_size=batch_size,
        description=description,
    )
    return metrics.ppl, metrics.loss
