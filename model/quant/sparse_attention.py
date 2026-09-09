"""Pure SF-based block selection for the sparse-attention reference path."""

from __future__ import annotations

from dataclasses import dataclass

import torch
import torch.nn.functional as F


@dataclass(frozen=True)
class SFBlockSelection:
    """Block proxy scores, boolean mask, and sorted selected block ids."""

    block_scores: torch.Tensor
    candidate_block_mask: torch.Tensor
    block_mask: torch.Tensor
    selected_block_indices: torch.Tensor
    query_block_token_counts: torch.Tensor
    key_block_token_counts: torch.Tensor


def pool_token_scales(
    scales: torch.Tensor,
    block_size: int,
    *,
    reduction: str = "mean",
) -> tuple[torch.Tensor, torch.Tensor]:
    """Pool ``[B,H,S,G]`` group scales into ``[B,H,N,G]`` blocks.

    ``mean`` divides partial final blocks by their number of real tokens rather
    than by the padded block size.  ``sum`` is also exposed for hand-checking
    the factorized all-token-pair SF score.
    """
    if scales.ndim != 4:
        raise ValueError("scales must have shape [B, H, S, G]")
    if block_size < 1:
        raise ValueError("block_size must be positive")
    if reduction not in {"mean", "sum"}:
        raise ValueError("reduction must be 'mean' or 'sum'")

    batch, heads, sequence_length, groups = scales.shape
    if sequence_length < 1:
        raise ValueError("scale sequence dimension must be non-empty")
    num_blocks = (sequence_length + block_size - 1) // block_size
    padded_length = num_blocks * block_size
    padded = F.pad(scales, (0, 0, 0, padded_length - sequence_length))
    grouped = padded.reshape(
        batch,
        heads,
        num_blocks,
        block_size,
        groups,
    )
    summaries = grouped.float().sum(dim=3)

    counts = torch.full(
        (num_blocks,),
        block_size,
        dtype=torch.int64,
        device=scales.device,
    )
    counts[-1] = sequence_length - (num_blocks - 1) * block_size
    if reduction == "mean":
        summaries = summaries / counts.to(summaries.dtype).view(1, 1, -1, 1)
    return summaries, counts


def sf_block_scores(
    query_scales: torch.Tensor,
    key_scales: torch.Tensor,
    block_size: int,
    *,
    reduction: str = "mean",
) -> tuple[torch.Tensor, torch.Tensor, torch.Tensor]:
    """Calculate the pure-SF proxy ``Q_block_SF @ K_block_SF^T``.

    With mean pooling, one score is exactly the valid-token-pair mean of
    ``sum_g SF_Q[i,g] * SF_K[j,g]``. For full equally sized blocks, using sum
    instead multiplies every score by the same ``block_size**2`` constant.
    """
    if query_scales.shape[:2] != key_scales.shape[:2]:
        raise ValueError("Q/K scales must have matching batch and head axes")
    if query_scales.shape[-1] != key_scales.shape[-1]:
        raise ValueError("Q/K scales must have the same number of groups")
    query_summary, query_counts = pool_token_scales(
        query_scales,
        block_size,
        reduction=reduction,
    )
    key_summary, key_counts = pool_token_scales(
        key_scales,
        block_size,
        reduction=reduction,
    )
    scores = torch.matmul(query_summary, key_summary.transpose(-1, -2))
    return scores, query_counts, key_counts


def causal_topk_block_selection(
    block_scores: torch.Tensor,
    topk_blocks: int,
    *,
    force_first_block: bool = True,
    force_diagonal_block: bool = True,
    block_valid_mask: torch.Tensor | None = None,
) -> tuple[torch.Tensor, torch.Tensor]:
    """Select a fixed-budget set of causal key blocks for every query block.

    The budget includes forced blocks. Selected ids are sorted in chronological
    order and padded with ``-1`` for early causal rows that contain fewer than
    ``topk_blocks`` blocks.
    """
    if block_scores.ndim != 4:
        raise ValueError("block_scores must have shape [B, H, Nq, Nk]")
    if topk_blocks < 1:
        raise ValueError("topk_blocks must be positive")

    batch, heads, num_query_blocks, num_key_blocks = block_scores.shape
    if num_query_blocks != num_key_blocks:
        raise ValueError(
            "the aligned causal selector currently requires Nq == Nk"
        )
    if (
        num_query_blocks > 1
        and force_first_block
        and force_diagonal_block
        and topk_blocks < 2
    ):
        raise ValueError(
            "topk_blocks must be at least 2 when first and diagonal blocks "
            "are both forced"
        )

    query_ids = torch.arange(
        num_query_blocks,
        device=block_scores.device,
    ).view(1, 1, num_query_blocks, 1)
    key_ids = torch.arange(
        num_key_blocks,
        device=block_scores.device,
    ).view(1, 1, 1, num_key_blocks)
    candidate_block_mask = (key_ids <= query_ids).expand(
        batch,
        heads,
        -1,
        -1,
    )
    if block_valid_mask is not None:
        if block_valid_mask.dtype != torch.bool:
            raise TypeError("block_valid_mask must be boolean")
        try:
            block_valid_mask = torch.broadcast_to(
                block_valid_mask.to(block_scores.device),
                block_scores.shape,
            )
        except RuntimeError as error:
            raise ValueError(
                "block_valid_mask must be broadcastable to block_scores"
            ) from error
        candidate_block_mask = candidate_block_mask & block_valid_mask

    block_mask = torch.zeros_like(block_scores, dtype=torch.bool)
    for query_block in range(num_query_blocks):
        valid_row = candidate_block_mask[:, :, query_block]
        forced_mask = torch.zeros_like(valid_row)
        if force_first_block:
            forced_mask[:, :, 0] = valid_row[:, :, 0]
        if force_diagonal_block and query_block < num_key_blocks:
            forced_mask[:, :, query_block] = valid_row[:, :, query_block]

        block_mask[:, :, query_block] = forced_mask
        valid_counts = valid_row.sum(dim=-1)
        budgets = torch.clamp(valid_counts, max=topk_blocks)
        dynamic_counts = budgets - forced_mask.sum(dim=-1)
        max_dynamic = int(dynamic_counts.max().item())
        if max_dynamic == 0:
            continue

        dynamic_candidates = valid_row & ~forced_mask
        candidate_scores = block_scores[:, :, query_block].masked_fill(
            ~dynamic_candidates,
            -torch.inf,
        )
        absolute_ids = torch.topk(
            candidate_scores,
            k=max_dynamic,
            dim=-1,
            largest=True,
            sorted=False,
        ).indices
        selected_ranks = torch.arange(
            max_dynamic,
            device=block_scores.device,
        ).view(1, 1, -1) < dynamic_counts.unsqueeze(-1)
        dynamic_mask = torch.zeros_like(valid_row)
        dynamic_mask.scatter_(-1, absolute_ids, selected_ranks)
        block_mask[:, :, query_block] |= dynamic_mask

    selected_width = min(topk_blocks, num_key_blocks)
    positions = torch.arange(
        num_key_blocks,
        device=block_scores.device,
    ).view(1, 1, 1, num_key_blocks)
    positions = positions.expand(batch, heads, num_query_blocks, -1)
    sentinel = torch.full_like(positions, num_key_blocks)
    selected = torch.where(block_mask, positions, sentinel)
    selected = selected.sort(dim=-1).values[..., :selected_width]
    selected = selected.masked_fill(selected == num_key_blocks, -1)
    return block_mask, selected


def build_sf_topk_selection(
    query_scales: torch.Tensor,
    key_scales: torch.Tensor,
    *,
    block_size: int,
    topk_blocks: int,
    reduction: str = "mean",
    force_first_block: bool = True,
    force_diagonal_block: bool = True,
    block_valid_mask: torch.Tensor | None = None,
) -> SFBlockSelection:
    """Pool scales, calculate SF proxy scores, and perform causal Top-K."""
    scores, query_counts, key_counts = sf_block_scores(
        query_scales,
        key_scales,
        block_size,
        reduction=reduction,
    )
    mask, selected = causal_topk_block_selection(
        scores,
        topk_blocks,
        force_first_block=force_first_block,
        force_diagonal_block=force_diagonal_block,
        block_valid_mask=block_valid_mask,
    )
    query_ids = torch.arange(
        scores.shape[-2],
        device=scores.device,
    ).view(1, 1, -1, 1)
    key_ids = torch.arange(
        scores.shape[-1],
        device=scores.device,
    ).view(1, 1, 1, -1)
    candidate_mask = (key_ids <= query_ids).expand_as(scores)
    if block_valid_mask is not None:
        candidate_mask = candidate_mask & torch.broadcast_to(
            block_valid_mask.to(device=scores.device, dtype=torch.bool),
            scores.shape,
        )
    return SFBlockSelection(
        block_scores=scores,
        candidate_block_mask=candidate_mask,
        block_mask=mask,
        selected_block_indices=selected,
        query_block_token_counts=query_counts,
        key_block_token_counts=key_counts,
    )
