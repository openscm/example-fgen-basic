"""
Wrappers of `m_error_v_passing` [TODO think about naming and x-referencing]

At the moment, all written by hand.
We will auto-generate this in future.
"""

from __future__ import annotations

from typing import TYPE_CHECKING

import numpy as np

from example_fgen_basic.error_v import ErrorV
from example_fgen_basic.pyfgen_runtime.exceptions import CompiledExtensionNotFoundError

try:
    from example_fgen_basic._lib import (  # type: ignore
        m_error_v_w,
    )
except (ModuleNotFoundError, ImportError) as exc:  # pragma: no cover
    raise CompiledExtensionNotFoundError("example_fgen_basic._lib.m_error_v_w") from exc
try:
    from example_fgen_basic._lib import (  # type: ignore
        m_error_v_passing_w,
    )
except (ModuleNotFoundError, ImportError) as exc:  # pragma: no cover
    raise CompiledExtensionNotFoundError(
        "example_fgen_basic._lib.m_error_v_passing_w"
    ) from exc

if TYPE_CHECKING:
    # TODO: bring back in numpy type hints
    NP_ARRAY_OF_INT = None
    NP_ARRAY_OF_BOOL = None


def pass_error(inv: ErrorV) -> bool:
    """
    Pass an error to Fortran

    Parameters
    ----------
    inv
        Input value to pass to Fortran

    Returns
    -------
    :
        If `inv` is an error, `True`, otherwise `False`.
    """
    # Tell Fortran to build the object on the Fortran side
    instance_index: int = m_error_v_w.build_instance(code=inv.code, message=inv.message)

    # Call the Fortran function
    # Boolean wrapping strategy, have to cast to bool
    res_raw: int = m_error_v_passing_w.pass_error(instance_index)
    res = bool(res_raw)

    # Tell Fortran to finalise the object on the Fortran side
    # (all data has been used for the call now)
    m_error_v_w.finalise_instance(instance_index)

    return res


def pass_errors(invs: tuple[ErrorV, ...]) -> NP_ARRAY_OF_BOOL:
    """
    Pass a number of errors to Fortran

    Parameters
    ----------
    invs
        Errors to pass to Fortran

    Returns
    -------
    :
        Whether each value in `invs` is an error or not
    """
    # Controlling memory from the Python side
    m_error_v_w.ensure_at_least_n_instances_can_be_passed_simultaneously(len(invs))
    # TODO: consider adding `build_instances` too, might be headache
    instance_indexes: NP_ARRAY_OF_INT = np.array(
        [m_error_v_w.build_instance(code=inv.code, message=inv.message) for inv in invs]
    )

    # Convert the result to boolean
    res_raw = m_error_v_passing_w.pass_errors(instance_indexes, n=instance_indexes.size)
    res = res_raw.astype(bool)

    # Tell Fortran to finalise the objects on the Fortran side
    # (all data has been copied to Python now)
    m_error_v_w.finalise_instances(instance_indexes)

    return res
