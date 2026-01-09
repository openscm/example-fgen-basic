"""
Tests of `example_fgen_basic.error_v.creation`
"""

import numpy as np
import pytest

from example_fgen_basic.error_v import ErrorV
from example_fgen_basic.result import ResultGen


def test_create_integer_result():
    ResultGen.free_fortran_memory()

    result_in = ResultGen(data_v=42, error_v=None)

    result_instance_index = result_in.build_fortran_instance()
    result_out = ResultGen.from_instance_index(result_instance_index)

    assert result_in.data_v == result_out.data_v
    assert result_in.error_v == result_out.error_v


def test_create_float_result():
    ResultGen.free_fortran_memory()

    result_in = ResultGen(data_v=3.21, error_v=None)

    result_instance_index = result_in.build_fortran_instance()
    result_out = ResultGen.from_instance_index(result_instance_index)

    assert result_in.data_v == result_out.data_v
    assert result_in.error_v == result_out.error_v


def test_create_error_result():
    ResultGen.free_fortran_memory()

    result_in = ResultGen(data_v=None, error_v=ErrorV(code=1, message="Error message"))

    result_instance_index = result_in.build_fortran_instance()
    result_out = ResultGen.from_instance_index(result_instance_index)
    result_out.error_v.message = result_out.error_v.message

    assert result_in.data_v == result_out.data_v
    assert result_in.error_v == result_out.error_v


@pytest.mark.parametrize(
    "array, exp_error",
    [
        (np.array([4, 4, 5]), None),
        (np.array([[1, 2, 3], [4, 5, 6]]), None),
        (
            np.array(
                [
                    [[1, 2, 34, 35, 36], [4, 5, 6, 7, 8], [14, 15, 16, 17, 18]],
                    [[21, 22, 23, 24, 25], [44, 45, 46, 47, 48], [51, 52, 53, 54, 55]],
                ]
            ),
            None,
        ),
    ],
)
def test_get_pass_int_array(array, exp_error):
    ResultGen.free_fortran_memory()

    result_int_arr = ResultGen(data_v=array, error_v=exp_error)
    result_instance_index = result_int_arr.build_fortran_instance()
    result_out = ResultGen.from_instance_index(result_instance_index)

    assert np.array_equal(array, result_out.data_v)
    assert exp_error == result_out.error_v


def test_create_mix_results():
    ResultGen.free_fortran_memory()

    result_err = ResultGen(data_v=None, error_v=ErrorV(code=1, message="Error message"))
    result_dp = ResultGen(data_v=3.21, error_v=None)
    result_int = ResultGen(data_v=42, error_v=None)
    result_int_arr = ResultGen(data_v=np.array([42, 34, 11], dtype=int), error_v=None)

    results = [result_err, result_int, result_dp, result_int_arr]

    for res in results:
        result_instance_index = res.build_fortran_instance()
        result_out = ResultGen.from_instance_index(result_instance_index)

        if result_out.error_v:
            result_out.error_v.message = result_out.error_v.message

        assert np.array_equal(res.data_v, result_out.data_v)
        assert res.error_v == result_out.error_v


def test_out_of_alloc_and_bound_error():
    ResultGen.free_fortran_memory()

    result_int = ResultGen(data_v=21, error_v=None)

    result_out = ResultGen.from_instance_index(1)

    if result_out.error_v:
        result_out.error_v.message = result_out.error_v.message

    assert (
        result_out.error_v.message
        == "Probe instance ERROR:\n Previous error --> instance array in NOT allocated"
    )

    result_instance_index = result_int.build_fortran_instance()
    result_out = ResultGen.from_instance_index(result_instance_index + 10)

    if result_out.error_v:
        result_out.error_v.message = result_out.error_v.message

    assert (
        result_out.error_v.message
        == "Probe instance ERROR:\n Previous error --> Requested index is: 12 ==> out of boundary"  # noqa: E501
    )


@pytest.mark.parametrize("array", [np.array([1.5, 2]), [[1, 2], [3]], ["a", 1]])
def test_invalid_data_v_raises_valueerror(array):
    with pytest.raises(ValueError, match="data_v="):
        result_int_arr = ResultGen(data_v=array, error_v=None)
        result_int_arr.build_fortran_instance()
