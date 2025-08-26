"""
Demonstration of how to return an error (i.e. derived type)
"""

from __future__ import annotations

from example_fgen_basic.error_v.error_v import ErrorV, ErrorVPtrBased
from example_fgen_basic.pyfgen_runtime.exceptions import CompiledExtensionNotFoundError

try:
    from example_fgen_basic._lib import (  # type: ignore
        m_error_v_creation_w,
    )
except (ModuleNotFoundError, ImportError) as exc:  # pragma: no cover
    raise CompiledExtensionNotFoundError("example._lib.m_error_v_creation_w") from exc


def create_error(inv: int) -> ErrorV:
    """
    Create an instance of error (a wrapper around our Fortran derived type)
    """
    instance_index = m_error_v_creation_w.create_error(inv)

    error = ErrorV(instance_index)

    return error


def create_error_ptr_based(inv: int) -> ErrorVPtrBased:
    """
    Create an instance of error (a wrapper around our Fortran derived type)

    Uses the pointer based logic
    """
    instance_ptr = m_error_v_creation_w.create_error_ptr_based(inv)

    error = ErrorVPtrBased(instance_ptr)

    return error
