"""
Tests of `example_fgen_basic.result_dp`
"""

import pytest

from example_fgen_basic._lib import m_result_dp_w
from example_fgen_basic.result.result_dp import ResultDP


@pytest.mark.parametrize(
    "data_v, error_v_instance_index, exp, exp_error",
    [
        (1.23, 0, 1.23, False),
        (
            1.23,
            1,
            "Error at get_instance -> 1 --> Cause: Index 1 has not been claimed",
            True,
        ),
    ],
)
# MZ: in the second case the error should be:
# "Error at get_instance -> 1 --> Cause: instance_available in NOT allocated"
# but the error_v memory side is not being managed correctly
def test_build_no_argument_supplied(data_v, error_v_instance_index, exp, exp_error):
    res_instance_index: int = m_result_dp_w.build_instance(
        data_v=data_v, error_v_instance_index=error_v_instance_index
    )
    res: ResultDP = ResultDP.from_instance_index(res_instance_index)
    m_result_dp_w.finalise_instance(res_instance_index)

    # Previously this would segfault.
    # Now we can actually handle the error on the Python side as we wish
    # rather than our only choice being a seg fault or hard stop in Fortran
    # (for this particular error message,
    # probably the Python just has to raise an exception too,
    # but other errors will be things we can recover).
    assert res.has_error == exp_error

    if exp_error:
        assert res.error_v.message == exp
    else:
        assert res.data_v == exp
