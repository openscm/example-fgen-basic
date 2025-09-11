"""
Wrappers of `m_error_v_creation` [TODO think about naming and x-referencing]

At the moment, all written by hand.
We will auto-generate this in future.
"""

from __future__ import annotations

from typing import TYPE_CHECKING

from example_fgen_basic.error_v import ErrorV
from example_fgen_basic.pyfgen_runtime.exceptions import CompiledExtensionNotFoundError

try:
    from example_fgen_basic._lib import (  # type: ignore
        m_error_v_w,
    )
except (ModuleNotFoundError, ImportError) as exc:  # pragma: no cover
    raise CompiledExtensionNotFoundError("example_fgen_basic._lib.m_error_v_w") from exc
try:
    from example_fgen_basic._lib import m_error_v_creation_w
except (ModuleNotFoundError, ImportError) as exc:  # pragma: no cover
    raise CompiledExtensionNotFoundError(
        "example_fgen_basic._lib.m_error_v_creation_w"
    ) from exc

if TYPE_CHECKING:
    from example_fgen_basic.typing import NP_ARRAY_OF_INT


def create_error(inv: int) -> ErrorV:
    """
    Create an error

    Parameters
    ----------
    inv
        Input value

        If odd, the error code is
        [NO_ERROR_CODE][example_fgen_basic.error_v.error_v.NO_ERROR_CODE].
        If even, the error code is 1.
        If a negative number is supplied, the error code is 2.

    Returns
    -------
    :
        Created error
    """
    # Get the result, but receiving an instance index rather than the object itself
    instance_index: int = m_error_v_creation_w.create_error(inv)

    # Initialise the result from the received index
    res = ErrorV.from_instance_index(instance_index)

    return res


def create_errors(invs: NP_ARRAY_OF_INT) -> tuple[ErrorV, ...]:
    """
    Create a number of errors

    Parameters
    ----------
    invs
        Input values from which to create errors

        For each value in `invs`,
        if the value is even, an error is created,
        if the value is odd, an error with a no error code is created.

    Returns
    -------
    :
        Created errors
    """
    # Get the result, but receiving an instance index rather than the object itself
    instance_indexes: NP_ARRAY_OF_INT = m_error_v_creation_w.create_errors(invs)

    # Initialise the result from the received index
    res = tuple(ErrorV.from_instance_index(i) for i in instance_indexes)

    # Tell Fortran to finalise the object on the Fortran side
    # (all data has been copied to Python now)
    m_error_v_w.finalise_instances(instance_indexes)

    return res
