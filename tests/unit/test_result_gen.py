"""
Tests of `example_fgen_basic.error_v.creation`
"""

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
    result_out.error_v.message = result_out.error_v.message.decode("utf-8")

    assert result_in.data_v == result_out.data_v
    assert result_in.error_v == result_out.error_v


def test_create_mix_results():
    ResultGen.free_fortran_memory()

    result_err = ResultGen(data_v=None, error_v=ErrorV(code=1, message="Error message"))
    result_dp = ResultGen(data_v=3.21, error_v=None)
    result_int = ResultGen(data_v=42, error_v=None)

    results = [result_err, result_int, result_dp]

    for res in results:
        result_instance_index = res.build_fortran_instance()
        result_out = ResultGen.from_instance_index(result_instance_index)

        if result_out.error_v:
            result_out.error_v.message = result_out.error_v.message.decode("utf-8")

        assert res.data_v == result_out.data_v
        assert res.error_v == result_out.error_v


def test_out_of_alloc_and_bound_error():
    ResultGen.free_fortran_memory()

    result_int = ResultGen(data_v=21, error_v=None)

    result_out = ResultGen.from_instance_index(1)

    if result_out.error_v:
        result_out.error_v.message = result_out.error_v.message.decode("utf-8")

    assert (
        result_out.error_v.message
        == "Probe instance ERROR:\n Previous error --> instance array in NOT allocated"
    )

    result_instance_index = result_int.build_fortran_instance()
    result_out = ResultGen.from_instance_index(result_instance_index + 10)

    if result_out.error_v:
        result_out.error_v.message = result_out.error_v.message.decode("utf-8")

    assert (
        result_out.error_v.message
        == "Probe instance ERROR:\n Previous error --> Requested index is: 12 ==> out of boundary"  # noqa: E501
    )
