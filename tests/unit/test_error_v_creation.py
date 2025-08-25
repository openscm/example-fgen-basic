"""
Tests of `example_fgen_basic.error_v.creation`

Note that this is the only test of the Fortran code.
I haven't written unit tests for the Fortran directly
(deliberately, just to see how it goes).
"""

from example_fgen_basic.error_v import ErrorV
from example_fgen_basic.error_v.creation import create_error


def test_create_error_odd():
    res = create_error(1.0)

    assert isinstance(res, ErrorV)

    assert res.code == 0
    assert res.message == ""


def test_create_error_even():
    res = create_error(2.0)

    assert isinstance(res, ErrorV)

    assert res.code != 0
    assert res.code == 1
    assert res.message == "Even number supplied"


def test_create_error_negative():
    res = create_error(-1.0)

    assert isinstance(res, ErrorV)

    assert res.code == 2
    assert res.message == "Negative number supplied"


# Tests to write:
# - if we create more errors than we have available, we don't segfault.
#   Instead, we should get an error back.
#   That error should just use the instance ID of the last available array index
#   (it is ok to overwrite an already used error to avoid a complete failure,
#   but we should probably include that we did this in the error message).
# - we can resize the available number of error instances to avoid hitting limits
