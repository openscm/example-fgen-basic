from example_fgen_basic._lib import m_result_dp_w
from example_fgen_basic.result.result_int import ResultInt


def test_build_no_argument_supplied():
    res_instance_index: int = m_result_dp_w.build_instance(
        data_v=1.23, error_v_instance_index=0
    )
    res: ResultInt = ResultInt.from_instance_index(res_instance_index)
    # Previously this would segfault.
    # Now we can actually handle the error on the Python side as we wish
    # rather than our only choice being a seg fault or hard stop in Fortran
    # (for this particular error message,
    # probably the Python just has to raise an exception too,
    # but other errors will be things we can recover).
    assert res.has_error
    assert res.error_v.message == (
        "I wanted to return an error, "
        "but I couldn't even get an available instance to do so. "
        "I have forced a return, but your program is probably fully broken. "
        "Please be very careful."
    )
