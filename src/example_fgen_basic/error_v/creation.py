"""
Demonstration of how to return an error (i.e. derived type)
"""

from __future__ import annotations

from example_fgen_basic.error_v.error_v import ErrorV
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
