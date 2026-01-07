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

    __fs_int = m_result_w.s_int
    __fs_dp = m_result_w.s_dp
    __fs_err = m_result_w.s_err

    @classmethod
    def from_instance_index(cls, instance_index: int) -> ResultGen:
        """
        Get from an instance index received from Fortran

        Parameters
        ----------
        instance_index
            Instance index received form Fortran

        Returns
        -------
        :
            Initialised index
        """
        valid_instance = m_result_w.probe_instance(instance_index)

        if valid_instance != 0:
            instance_index = valid_instance

        tag = m_result_w.get_instance_tag(instance_index)

        if tag == cls.__fs_int:
            data_v_int: int | None = m_result_w.get_data_int(instance_index)
            error_v = None
            res = cls(data_v=data_v_int, error_v=error_v)

        elif tag == cls.__fs_dp:
            data_v_float: float | None = m_result_w.get_data_dp(instance_index)
            error_v = None
            res = cls(data_v=data_v_float, error_v=error_v)

        elif tag == cls.__fs_err:
            data_v_err = None
            code, message = m_result_w.get_error(instance_index)
            # if code is None or message is None:
            # raise ValueError("Fortran returned incomplete error information")
            error_v = ErrorV(code=code, message=message)

            res = cls(data_v=data_v_err, error_v=error_v)
        else:
            msg = f"Undefinded tag: {tag}"
            raise ValueError(msg)

        return res

    @classmethod
    def free_fortran_memory(cls) -> None:
        """
        Free memory on the Fortran side.
        """
        m_result_w.free_resources()

    def build_fortran_instance(self) -> int:
        """
        Build an instance equivalent to `self` on the Fortran side

        Intended for use mainly by wrapping functions.
        Most users should not need to use this method directly.

        Returns
        -------
        :
            Instance index of the object which has been created on the Fortran side
        """
        instance_index: int

        if self.data_v is None and self.error_v is not None:
            instance_index = m_result_w.build_instance_err(
                self.error_v.code, self.error_v.message
            )
        elif isinstance(self.data_v, int):
            instance_index = m_result_w.build_instance_int(self.data_v)
        elif isinstance(self.data_v, float):
            instance_index = m_result_w.build_instance_dp(self.data_v)
        else:
            msg = f"data_v={self.data_v}, error_v={self.error_v}"
            raise KeyError(msg)

        return instance_index
