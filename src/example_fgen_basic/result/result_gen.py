"""
Python equivalent of the Fortran `ResultGen` class
"""

from __future__ import annotations

import numpy as np
from attrs import define
from numpy.typing import NDArray

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

    data_v: int | float | NDArray[np.int_] | None
    """ Data"""

    error_v: ErrorV | None
    """Error"""

    __fs_int = m_result_w.s_int
    __fs_dp = m_result_w.s_dp
    __farr_int = m_result_w.arr_int
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

        elif tag == cls.__farr_int:
            data_v_arr_int: NDArray[np.int_]
            data_shape: NDArray[np.int_] = m_result_w.get_data_dims(instance_index)
            ndims = (data_shape > 0).sum()

            DIM1D = 1
            if ndims == DIM1D:
                data_v_arr_int = m_result_w.get_data_arr_int_1d(
                    instance_index, d1=data_shape[0]
                )
                error_v = None
            elif ndims == DIM1D + 1:
                data_v_arr_int = m_result_w.get_data_arr_int_2d(
                    instance_index, d1=data_shape[0], d2=data_shape[1]
                )
                error_v = None
            elif ndims == DIM1D + 2:
                data_v_arr_int = m_result_w.get_data_arr_int_3d(
                    instance_index, d1=data_shape[0], d2=data_shape[1], d3=data_shape[2]
                )
                error_v = None
            else:
                msg = "Getter ERROR: Null array dimensions"
                raise ValueError(msg)

            res = cls(data_v=data_v_arr_int, error_v=error_v)

        elif tag == cls.__fs_err:
            data_v_err = None
            code, message = m_result_w.get_error(instance_index)
            # if code is None or message is None:
            # raise ValueError("Fortran returned incomplete error information")
            clean_msg = message.decode("utf-8").strip()
            error_v = ErrorV(code=code, message=clean_msg)

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
        elif isinstance(self.data_v, np.ndarray) and np.issubdtype(
            self.data_v.dtype, np.integer
        ):
            DIM1D = 1
            ndarray = np.array(self.data_v)
            if ndarray.ndim == DIM1D:
                instance_index = m_result_w.build_instance_arr_int_1d(self.data_v)
            elif ndarray.ndim == DIM1D + 1:
                instance_index = m_result_w.build_instance_arr_int_2d(self.data_v)
            elif ndarray.ndim == DIM1D + 2:
                instance_index = m_result_w.build_instance_arr_int_3d(self.data_v)
        else:
            msg = f"Unexpected data_v={self.data_v}, error_v={self.error_v}"
            if isinstance(self.data_v, np.ndarray) and not np.issubdtype(
                self.data_v.dtype, np.integer
            ):
                msg = f"Unexpected data_v={self.data_v} does not contain all integers"

            raise ValueError(msg)

        return instance_index
