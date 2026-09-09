"""MXINT-style integer fake-quantization primitives.

The returned tensor remains floating point. Values are quantized to an integer
grid and immediately dequantized so the numerical effect can be evaluated with
ordinary PyTorch operators.
"""

from __future__ import annotations

from typing import Literal

import torch

ClipStyle = Literal["sym", "asym"]
E8ScaleOp = Literal["ceil", "floor", "round", "ocp"]


def _identity_scales(
    x: torch.Tensor,
    *,
    dim: int,
    group_size: int,
) -> torch.Tensor:
    """Return correctly shaped unit scales for a non-quantized tensor."""
    dim = dim % x.ndim
    dim_size = x.shape[dim]
    effective_group_size = dim_size if group_size <= 0 else group_size
    if dim_size % effective_group_size != 0:
        raise ValueError(
            f"dimension size {dim_size} must be divisible by "
            f"group_size {effective_group_size}"
        )

    scale_shape = list(x.shape)
    scale_shape[dim] = dim_size // effective_group_size
    return torch.ones(scale_shape, dtype=x.dtype, device=x.device)


def _power_of_two_scale(
    scale: torch.Tensor,
    *,
    xmax: torch.Tensor,
    qmax: int,
    op: E8ScaleOp,
) -> torch.Tensor:
    """Round a scale to an E8M0-style power of two."""
    if op == "ceil":
        exponent = scale.log2().ceil()
    elif op == "floor":
        exponent = scale.log2().floor()
    elif op == "round":
        exponent = scale.log2().round()
    elif op == "ocp":
        qmax_exponent = torch.tensor(
            qmax,
            dtype=torch.float32,
            device=scale.device,
        ).log2().floor()
        exponent = xmax.log2().floor() - qmax_exponent
    else:
        raise ValueError(
            "e8_scale_op must be one of: ceil, floor, round, ocp"
        )

    return torch.pow(2.0, exponent.clamp(-127, 127)).to(scale.dtype)


def int_quant(
    x: torch.Tensor,
    bit: int,
    *,
    dim: int = -1,
    group_size: int = -1,
    e8_scale: bool = False,
    e8_scale_op: E8ScaleOp = "ceil",
    clip_style: ClipStyle = "sym",
    return_scale: bool = False,
) -> torch.Tensor | tuple[torch.Tensor, torch.Tensor]:
    """Apply group-wise integer fake quantization.

    For the initial MXINT8 baseline, use ``bit=8``, ``group_size=32``,
    ``e8_scale=True``, ``e8_scale_op="ceil"``, and ``clip_style="sym"``.
    A bit width of 16 or greater is treated as a pass-through.
    """
    if not isinstance(bit, int):
        raise TypeError(f"bit must be int, got {type(bit).__name__}")
    if bit < 2:
        raise ValueError(f"bit must be at least 2, got {bit}")
    if x.ndim == 0:
        raise ValueError("int_quant expects a tensor with at least one dimension")

    dim = dim % x.ndim

    if bit >= 16:
        if return_scale:
            return x, _identity_scales(
                x,
                dim=dim,
                group_size=group_size,
            )
        return x

    qmax = 2 ** (bit - 1) - 1
    if clip_style == "sym":
        qmin = -qmax
    elif clip_style == "asym":
        qmin = -(2 ** (bit - 1))
    else:
        raise ValueError("clip_style must be 'sym' or 'asym'")

    shape = x.shape
    dim_size = shape[dim]
    effective_group_size = dim_size if group_size <= 0 else group_size
    if dim_size % effective_group_size != 0:
        raise ValueError(
            f"dimension size {dim_size} must be divisible by "
            f"group_size {effective_group_size}"
        )

    num_groups = dim_size // effective_group_size
    grouped_shape = (
        shape[:dim]
        + (num_groups, effective_group_size)
        + shape[dim + 1 :]
    )
    grouped = x.reshape(grouped_shape)
    reduction_dim = dim + 1

    xmax = grouped.abs().amax(dim=reduction_dim, keepdim=True)
    scale = xmax / qmax
    if e8_scale:
        scale = _power_of_two_scale(
            scale,
            xmax=xmax,
            qmax=qmax,
            op=e8_scale_op,
        )

    scale = scale.clamp(1e-25, 1e25)
    integer_values = (grouped / scale).round().clamp(qmin, qmax)
    dequantized = (integer_values * scale).reshape(shape)

    if return_scale:
        return dequantized, scale.squeeze(reduction_dim)
    return dequantized
