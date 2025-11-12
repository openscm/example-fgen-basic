from example_fgen_basic._lib import m_result_int_w
from example_fgen_basic.result.result_int import ResultInt


def test_build_no_argument_supplied():
    res_instance_index: int = m_result_int_w.build_instance(
        data_v=5, error_v_instance_index=0
    )
    res: int = ResultInt(res_instance_index)

    assert res.has_error
    assert res.error_v.message == (
        "I wanted to return an error, "
        "but I couldn't even get an available instance to do so. "
        "I have forced a return, but your program is probably fully broken. "
        "Please be very careful."
    )
