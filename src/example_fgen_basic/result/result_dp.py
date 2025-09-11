"""
Python equivalent of the Fortran `ResultDP` class [TODO: x-refs]
"""

from __future__ import annotations

from attrs import define

from example_fgen_basic.error_v import ErrorV
from example_fgen_basic.pyfgen_runtime.exceptions import CompiledExtensionNotFoundError

try:
    from example_fgen_basic._lib import (  # type: ignore
        m_result_dp_w,
    )
except (ModuleNotFoundError, ImportError) as exc:  # pragma: no cover
    raise CompiledExtensionNotFoundError(
        "example_fgen_basic._lib.m_result_dp_w"
    ) from exc


@define
class ResultDP:
    """
    Result type that can hold double precision real values
    """

    # TODO: add validation that one of data_v and error_v is provided but not both

    # data_v: np.Float64
    data_v: float
    """Data"""

    error_v: ErrorV
    """Error"""

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
        :
            Initialised index
        """
        # Different wrapping strategies are needed

        # Integer is very simple
        if m_result_dp_w.data_v_is_set(instance_index):
            data_v = m_result_dp_w.get_data_v(instance_index)

        else:
            data_v = None

        # Error type requires derived type handling
        if m_result_dp_w.error_v_is_set(instance_index):
            error_v_instance_index: int = m_result_dp_w.get_error_v(instance_index)

            # Initialise the result from the received index
            error_v = ErrorV.from_instance_index(error_v_instance_index)

        else:
            error_v = None

        res = cls(data_v=data_v, error_v=error_v)

        return res

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
        raise NotImplementedError
        # instance_index: int = m_error_v_w.build_instance(
        #     code=self.code, message=self.message
        # )
        #
        # return instance_index
