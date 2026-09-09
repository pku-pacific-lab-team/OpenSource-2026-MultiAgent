"""Orthogonal Hadamard rotations used by quantized attention."""

from __future__ import annotations

import math

import torch


def hadamard_block_sizes(size: int) -> tuple[int, ...]:
    """Decompose a positive width into descending power-of-two blocks."""
    if size < 1:
        raise ValueError(f"Hadamard size must be positive, got {size}")
    blocks: list[int] = []
    remaining = size
    while remaining:
        block_size = 1 << (remaining.bit_length() - 1)
        blocks.append(block_size)
        remaining -= block_size
    return tuple(blocks)


def _normalized_walsh_hadamard(size: int) -> torch.Tensor:
    """Construct one normalized power-of-two Walsh-Hadamard block."""
    matrix = torch.ones((1, 1), dtype=torch.float64)
    while matrix.shape[0] < size:
        matrix = torch.cat(
            (
                torch.cat((matrix, matrix), dim=1),
                torch.cat((matrix, -matrix), dim=1),
            ),
            dim=0,
        )
    return matrix / math.sqrt(size)


def randomized_hadamard_matrix(
    size: int,
    *,
    seed: int,
    dtype: torch.dtype = torch.float32,
    device: torch.device | str | None = None,
) -> torch.Tensor:
    """Return a normalized randomized block-Walsh-Hadamard matrix.

    Power-of-two widths use the original ``D @ H / sqrt(size)`` construction.
    Other widths use a block diagonal matrix over the width's descending
    binary decomposition.  For example, Phi-2's head dimension 80 uses
    normalized 64 and 16 blocks.  Both forms are orthogonal, preserving QK^T
    and permitting exact compensation in the output projection.
    """
    block_sizes = hadamard_block_sizes(size)
    if seed < 0:
        raise ValueError(f"Hadamard seed must be non-negative, got {seed}")
    if not (dtype.is_floating_point or dtype.is_complex):
        raise TypeError("Hadamard matrix dtype must be floating point")

    # Construct on CPU for deterministic seeded signs regardless of the model
    # device, then transfer the small head-dimension matrix once per layer.
    generator = torch.Generator(device="cpu")
    generator.manual_seed(seed)
    blocks: list[torch.Tensor] = []
    for block_size in block_sizes:
        block = _normalized_walsh_hadamard(block_size)
        signs = torch.randint(
            0,
            2,
            (block_size,),
            generator=generator,
            dtype=torch.int64,
        )
        signs = signs.mul(2).sub(1).to(torch.float64)
        blocks.append(signs[:, None] * block)
    matrix = torch.block_diag(*blocks)
    return matrix.to(dtype=dtype, device=device)


def right_rotate_head_dim(
    tensor: torch.Tensor,
    rotation: torch.Tensor,
) -> torch.Tensor:
    """Right-multiply the last dimension by an orthogonal rotation."""
    if tensor.shape[-1] != rotation.shape[0]:
        raise ValueError(
            f"tensor head dimension {tensor.shape[-1]} does not match "
            f"rotation size {rotation.shape[0]}"
        )
    if rotation.ndim != 2 or rotation.shape[0] != rotation.shape[1]:
        raise ValueError("rotation must be a square matrix")

    compute_dtype = (
        torch.float64 if tensor.dtype == torch.float64 else torch.float32
    )
    rotated = torch.matmul(
        tensor.to(compute_dtype),
        rotation.to(device=tensor.device, dtype=compute_dtype),
    )
    return rotated.to(tensor.dtype)


def compensate_output_projection_weight_(
    weight: torch.Tensor,
    rotation: torch.Tensor,
    *,
    head_dim: int,
) -> int:
    """Apply ``W_O <- W_O @ blockdiag(R, ..., R)`` in place.

    PyTorch Linear weights have shape ``[out_features, in_features]``.  If the
    concatenated attention output is right-rotated independently in every
    head, multiplying each corresponding input block of ``W_O`` by the same
    ``R`` exactly compensates that rotation.  The returned integer is the
    inferred number of query heads.
    """
    if weight.ndim != 2:
        raise ValueError("output projection weight must be two-dimensional")
    if weight.shape[1] % head_dim:
        raise ValueError(
            f"output projection input width {weight.shape[1]} is not "
            f"divisible by head_dim {head_dim}"
        )
    if rotation.shape != (head_dim, head_dim):
        raise ValueError(
            f"rotation must have shape {(head_dim, head_dim)}, got "
            f"{tuple(rotation.shape)}"
        )

    num_heads = weight.shape[1] // head_dim
    compute_dtype = (
        torch.float64 if weight.dtype == torch.float64 else torch.float32
    )
    blocks = weight.detach().reshape(weight.shape[0], num_heads, head_dim)
    compensated = torch.matmul(
        blocks.to(compute_dtype),
        rotation.to(device=weight.device, dtype=compute_dtype),
    )
    with torch.no_grad():
        weight.copy_(compensated.reshape_as(weight).to(weight.dtype))
    return num_heads
