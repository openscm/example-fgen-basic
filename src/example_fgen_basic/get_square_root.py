"""
Get square root of a number
"""

from __future__ import annotations

from example_fgen_basic.pyfgen_runtime.exceptions import (
    CompiledExtensionNotFoundError,
    FortranError,
)
from example_fgen_basic.result import ResultDP

try:
    from example_fgen_basic._lib import m_get_square_root_w  # type: ignore
except (ModuleNotFoundError, ImportError) as exc:  # pragma: no cover
    raise CompiledExtensionNotFoundError(
        "example_fgen_basic._lib.m_get_square_root_w"
    ) from exc

try:
    from example_fgen_basic._lib import m_result_dp_w  # type: ignore
except (ModuleNotFoundError, ImportError) as exc:  # pragma: no cover
    raise CompiledExtensionNotFoundError(
        "example_fgen_basic._lib.m_result_dp_w"
    ) from exc


def get_square_root(inv: float) -> float:
    """
    Get square root

    Parameters
    ----------
    inv
        Value for which to get the square root

    Returns
    -------
    :
        Square root of `inv`

    Raises
    ------
    FortranError
        `inv` is negative

        TODO: use a more specific error
    """
    result_instance_index: int = m_get_square_root_w.get_square_root(inv)

    result = ResultDP.from_instance_index(result_instance_index)

    if result.has_error:
        # TODO: be more specific
        raise FortranError(result.error_v.message)

    res = result.data_v

    m_result_dp_w.finalise_instance(result_instance_index)

    return res
