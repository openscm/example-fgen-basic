"""
Python equivalent of the Fortran `ResultGen` class
"""

from __future__ import annotations

from attrs import define

from example_fgen_basic.error_v import ErrorV
from example_fgen_basic.pyfgen_runtime.exceptions import CompiledExtensionNotFoundError

try:
    from example_fgen_basic._lib import (  # type: ignore
        m_result_w,
    )
except (ModuleNotFoundError, ImportError) as exc:  # pragma: no cover
    raise CompiledExtensionNotFoundError("example_fgen_basic._lib.m_result_w") from exc


@define
class ResultGen:
    """
    Result type that can hold values
    """

    data_v: int | float | None
    """ Data"""

    error_v: ErrorV | None
    """Error"""

    @classmethod
    def from_instance_index(cls, instance_index: int) -> ResultGen:
        """
        Initialise from an instance index received from Fortran

        Parameters
        ----------
        intance_index
           Instance index received form Fortran

        Returns
        -------
        :
           Initalised index
        """
        T_INT = 1
        T_DP = 2
        T_ERR = 3

        tag = m_result_w.get_instance_tag(instance_index)

        if tag == T_INT:
            data_v: int | None = m_result_w.get_data_int(instance_index)
            error_v = None

        elif tag == T_DP:
            data_v: float | None = m_result_w.get_data_dp(instance_index)
            error_v = None

        elif tag == T_ERR:
            data_v = None
            error_tuple: tuple[int | None, str | None] = m_result_w.get_error(
                instance_index
            )
            code, message = error_tuple
            error_v = ErrorV(code=code, message=message)
        else:
            print("ERRRORRR")

        res = cls(data_v=data_v, error_v=error_v)

        return res
