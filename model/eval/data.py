"""Dataset loading for deterministic causal-LM PPL evaluation."""

from __future__ import annotations

import argparse
from itertools import islice

import torch
from datasets import load_dataset


def add_dataset_args(parser: argparse.ArgumentParser) -> None:
    """Expose a generic Hugging Face text dataset through argparse."""
    parser.add_argument("--dataset-path", default="wikitext")
    parser.add_argument("--dataset-name", default="wikitext-2-raw-v1")
    parser.add_argument("--dataset-split", default="test")
    parser.add_argument("--dataset-text-column", default="text")
    parser.add_argument(
        "--dataset-data-file",
        dest="dataset_data_files",
        action="append",
        default=[],
        help=(
            "Local path or URL passed to datasets as an explicit data file; "
            "repeat for multiple files"
        ),
    )
    parser.add_argument(
        "--dataset-streaming",
        action=argparse.BooleanOptionalAction,
        default=False,
    )
    parser.add_argument(
        "--dataset-max-documents",
        type=int,
        default=0,
        help="0 uses every document exposed by the selected split",
    )
    parser.add_argument(
        "--dataset-blocks-per-document",
        type=int,
        default=0,
        help=(
            "0 concatenates documents; a positive value keeps at most this "
            "many complete blocks from each document"
        ),
    )


def dataset_id_from_args(args: argparse.Namespace) -> str:
    configured_name = args.dataset_name.strip()
    suffix = f"/{configured_name}" if configured_name else ""
    return f"{args.dataset_path}{suffix}:{args.dataset_split}"


def load_text_blocks(
    tokenizer,
    *,
    dataset_path: str,
    dataset_name: str = "",
    dataset_split: str,
    dataset_text_column: str,
    dataset_data_files: list[str] | tuple[str, ...] = (),
    dataset_streaming: bool,
    dataset_max_documents: int,
    dataset_blocks_per_document: int = 0,
    seqlen: int,
    nsamples: int,
) -> torch.Tensor:
    """Tokenize one text split into contiguous, non-overlapping blocks.

    ``nsamples=0`` uses every complete block available after the optional
    document limit.  A positive value caps the number of returned blocks.
    """
    if seqlen < 2:
        raise ValueError("seqlen must be at least 2")
    if nsamples < 0:
        raise ValueError("nsamples must be zero or positive")
    if dataset_max_documents < 0:
        raise ValueError("dataset_max_documents must be zero or positive")
    if dataset_blocks_per_document < 0:
        raise ValueError(
            "dataset_blocks_per_document must be zero or positive"
        )
    if dataset_streaming and dataset_max_documents == 0:
        raise ValueError(
            "streaming datasets require a positive dataset_max_documents"
        )

    configured_name = dataset_name.strip() or None
    load_kwargs = {
        "split": dataset_split,
        "streaming": dataset_streaming,
    }
    if dataset_data_files:
        load_kwargs["data_files"] = {
            dataset_split: list(dataset_data_files)
        }
    dataset = load_dataset(dataset_path, configured_name, **load_kwargs)
    rows = iter(dataset)
    if dataset_max_documents > 0:
        rows = islice(rows, dataset_max_documents)

    texts: list[str] = []
    for row_index, row in enumerate(rows):
        if dataset_text_column not in row:
            available = ", ".join(sorted(row))
            raise KeyError(
                f"dataset row {row_index} has no column "
                f"{dataset_text_column!r}; available columns: {available}"
            )
        value = row[dataset_text_column]
        if value is None:
            continue
        if not isinstance(value, str):
            raise TypeError(
                f"dataset text column must contain strings, got "
                f"{type(value).__name__} at row {row_index}"
            )
        texts.append(value)

    if not texts:
        raise ValueError("selected dataset split contains no text documents")

    if dataset_blocks_per_document > 0:
        blocks: list[torch.Tensor] = []
        for text in texts:
            encoded_document = tokenizer(
                text,
                return_tensors="pt",
            ).input_ids
            document_blocks = min(
                encoded_document.numel() // seqlen,
                dataset_blocks_per_document,
            )
            for block_index in range(document_blocks):
                start = block_index * seqlen
                blocks.append(
                    encoded_document[:, start : start + seqlen]
                )
                if nsamples > 0 and len(blocks) >= nsamples:
                    return torch.cat(blocks, dim=0).contiguous()
        if not blocks:
            raise ValueError(
                f"no individual document contains {seqlen} tokens"
            )
        return torch.cat(blocks, dim=0).contiguous()

    encoded = tokenizer(
        "\n\n".join(texts),
        return_tensors="pt",
    ).input_ids
    available_samples = encoded.numel() // seqlen
    actual_samples = (
        available_samples
        if nsamples == 0
        else min(nsamples, available_samples)
    )
    if actual_samples < 1:
        raise ValueError(
            f"dataset has fewer than {seqlen} tokens after tokenization"
        )
    return (
        encoded[:, : actual_samples * seqlen]
        .reshape(actual_samples, seqlen)
        .contiguous()
    )


def load_text_blocks_from_args(
    tokenizer,
    args: argparse.Namespace,
) -> torch.Tensor:
    return load_text_blocks(
        tokenizer,
        dataset_path=args.dataset_path,
        dataset_name=args.dataset_name,
        dataset_split=args.dataset_split,
        dataset_text_column=args.dataset_text_column,
        dataset_data_files=args.dataset_data_files,
        dataset_streaming=args.dataset_streaming,
        dataset_max_documents=args.dataset_max_documents,
        dataset_blocks_per_document=args.dataset_blocks_per_document,
        seqlen=args.seqlen,
        nsamples=args.nsamples,
    )


def load_wikitext2_blocks(
    tokenizer,
    *,
    seqlen: int,
    nsamples: int,
) -> torch.Tensor:
    """Backward-compatible WikiText2 wrapper."""
    return load_text_blocks(
        tokenizer,
        dataset_path="wikitext",
        dataset_name="wikitext-2-raw-v1",
        dataset_split="test",
        dataset_text_column="text",
        dataset_data_files=(),
        dataset_streaming=False,
        dataset_max_documents=0,
        dataset_blocks_per_document=0,
        seqlen=seqlen,
        nsamples=nsamples,
    )
