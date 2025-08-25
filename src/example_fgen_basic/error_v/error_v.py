"""
Wrapper of the Fortran :class:`ErrorV`
"""

from __future__ import annotations

from attrs import define

from example_fgen_basic.pyfgen_runtime.base_finalisable import (
    FinalisableWrapperBase,
    check_initialised,
)
from example_fgen_basic.pyfgen_runtime.exceptions import CompiledExtensionNotFoundError

try:
    from example._lib import (  # type: ignore
        m_error_v_creation_w,
    )
except (ModuleNotFoundError, ImportError) as exc:
    raise CompiledExtensionNotFoundError("example._lib.m_error_v_creation_w") from exc


@define
class ErrorV(FinalisableWrapperBase):
    """
    TODO: auto docstring e.g. "Wrapper around the Fortran :class:`ErrorV`"
    """

    @property
    def exposed_attributes(self) -> tuple[str, ...]:
        """
        Attributes exposed by this wrapper
        """
        return ("code", "message")

    # TODO: from_build_args, from_new_connection, context manager, finalise

    @property
    @check_initialised
    def code(self) -> int:
        """
        Error code

        Returns
        -------
        :
            Error code, retrieved from Fortran
        """
        code: int = m_error_v_creation_w.iget_code(instance_index=self.instance_index)

        return code

    @property
    @check_initialised
    def message(self) -> str:
        """
        Error message

        Returns
        -------
        :
            Error message, retrieved from Fortran
        """
        message: str = m_error_v_creation_w.iget_message(
            instance_index=self.instance_index
        ).decode()

        return message
