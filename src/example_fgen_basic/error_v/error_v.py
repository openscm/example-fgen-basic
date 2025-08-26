"""
Wrapper of the Fortran :class:`ErrorV`
"""

from __future__ import annotations

from typing import Any

from attrs import define

from example_fgen_basic.pyfgen_runtime.base_finalisable import (
    FinalisableWrapperBase,
    FinalisableWrapperBasePtrBased,
    check_initialised,
    check_initialised_ptr_based,
    execute_finalise_on_fail_ptr_based,
)
from example_fgen_basic.pyfgen_runtime.exceptions import CompiledExtensionNotFoundError

try:
    from example_fgen_basic._lib import (  # type: ignore
        m_error_v_ptr_based_w,
        m_error_v_w,
    )
except (ModuleNotFoundError, ImportError) as exc:  # pragma: no cover
    raise CompiledExtensionNotFoundError("example._lib.m_error_v_w") from exc


@define
class ErrorV(FinalisableWrapperBase):
    """
    TODO: auto docstring e.g. "Wrapper around the Fortran :class:`ErrorV`"
    """

    # Bug in Ipython pretty hence have to put this on every object?
    def _repr_pretty_(self, p: Any, cycle: bool) -> None:
        """
        Get pretty representation of self

        Used by IPython notebooks and other tools
        """
        super()._repr_pretty_(p=p, cycle=cycle)

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
        code: int = m_error_v_w.iget_code(instance_index=self.instance_index)

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
        message: str = m_error_v_w.iget_message(
            instance_index=self.instance_index
        ).decode()

        return message


@define
class ErrorVPtrBased(FinalisableWrapperBasePtrBased):
    """
    TODO: auto docstring e.g. "Wrapper around the Fortran :class:`ErrorV`"

    Uses the pointer-based passing logic
    """

    # Bug in Ipython pretty hence have to put this on every object?
    def _repr_pretty_(self, p: Any, cycle: bool) -> None:
        """
        Get pretty representation of self

        Used by IPython notebooks and other tools
        """
        super()._repr_pretty_(p=p, cycle=cycle)

    @property
    def exposed_attributes(self) -> tuple[str, ...]:
        """
        Attributes exposed by this wrapper
        """
        return ("code", "message")

    @classmethod
    def from_new_connection(cls) -> ErrorVPtrBased:
        """
        Initialise from a new connection

        The user is responsible for releasing this connection
        using :attr:`~finalise` when it is no longer needed.
        Alternatively a :obj:`~AtmosphereToOceanCarbonFluxCalculatorContext`
        can be used to handle the finalisation using a context manager.

        Returns
        -------
            A new instance with a unique instance index

        Raises
        ------
        WrapperErrorUnknownCause
            If a new instance could not be allocated

            This could occur if too many instances are allocated at any one time
        """
        instance_ptr = m_error_v_ptr_based_w.get_instance_ptr()
        # TODO: result type handling here

        return cls(instance_ptr)

    # TODO: from_build_args, from_new_connection, context manager, finalise
    @classmethod
    def from_build_args(
        cls,
        code: int,
        message: str = "",
    ) -> ErrorVPtrBased:
        """
        Build the class (including connecting to Fortran)
        """
        out = cls.from_new_connection()
        # TODO: remove or update this construct when we have result types
        execute_finalise_on_fail_ptr_based(
            out,
            m_error_v_ptr_based_w.instance_build,
            code=code,
            message=message,
        )

        return out

    @check_initialised
    def finalise(self) -> None:
        """
        Close the connection with the Fortran module
        """
        m_error_v_ptr_based_w.instance_finalise(self.instance_ptr)
        self._uninitialise_instance_ptr()

    @property
    def is_associated(self) -> bool:
        """
        Check whether `self`'s pointer is associated on the Fortran side

        Returns
        -------
        :
            Whether `self`'s pointer is associated on the Fortran side
        """
        if self.instance_ptr is None:
            return False

        res: bool = bool(m_error_v_ptr_based_w.is_associated(self.instance_ptr))  # type: ignore

        return res

    @property
    @check_initialised_ptr_based
    def code(self) -> int:
        """
        Error code

        Returns
        -------
        :
            Error code, retrieved from Fortran
        """
        code: int = m_error_v_ptr_based_w.iget_code(instance_ptr=self.instance_ptr)

        return code

    @property
    @check_initialised_ptr_based
    def message(self) -> str:
        """
        Error message

        Returns
        -------
        :
            Error message, retrieved from Fortran
        """
        message: str = m_error_v_ptr_based_w.iget_message(
            instance_ptr=self.instance_ptr
        ).decode()

        return message
