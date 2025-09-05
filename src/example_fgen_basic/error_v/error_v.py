"""
Python equivalent of the Fortran [ErrorV](/fortran-api/type/errorv.html) class.

At the moment, all written by hand.
We will auto-generate this in future.
"""

from __future__ import annotations

from attrs import define

from example_fgen_basic.pyfgen_runtime.exceptions import CompiledExtensionNotFoundError

try:
    from example_fgen_basic._lib import (  # type: ignore
        m_error_v_w,
    )
except (ModuleNotFoundError, ImportError) as exc:  # pragma: no cover
    raise CompiledExtensionNotFoundError("example_fgen_basic._lib.m_error_v_w") from exc

NO_ERROR_CODE = 0
"""Code that indicates no error"""


@define
class ErrorV:
    """
    Error value
    """

    code: int = 1
    """Error code"""

    message: str = ""
    """Error message"""

    @classmethod
    def from_instance_index(cls, instance_index: int) -> ErrorV:
        """
        Initialise from an instance index received from Fortran

        Parameters
        ----------
        instance_index
            Instance index received from Fortran

        Returns
        -------
        ErrorV
            Python instance containing Fortran data
        """
        # Different wrapping strategies are needed

        # Integer is very simple
        code = m_error_v_w.get_code(instance_index)

        # String requires decode
        message = m_error_v_w.get_message(instance_index).decode()

        res = cls(code=code, message=message)

        return res
