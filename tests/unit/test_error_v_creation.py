"""
Tests of `example_fgen_basic.error_v.creation`

Note that this is the only test of the Fortran code.
I haven't written unit tests for the Fortran directly
(deliberately, just to see how it goes).
"""

import re

import pytest
from IPython.lib.pretty import pretty

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


def test_error_too_many_instances():
    # @Marco we will fix this when we introduce a result type in a future step
    pytest.skip("Causes segfault right now")
    # - if we create more errors than we have available, we don't segfault.
    #   Instead, we should get an error back.
    #   That error should just use the instance ID of the last available array index
    #   (it is ok to overwrite an already used error to avoid a complete failure,
    #   but we should probably include that we did this in the error message).
    # TODO: expect error here
    for _ in range(4097):
        create_error(1)


@pytest.mark.xfail(
    reason="Not implemented yet - do in a future PR once we have a result type"
)
def test_increase_number_of_instances():
    raise NotImplementedError
    # - Make 4096 instances
    # - show that making one more raises an error
    # - increase number of instances
    # - show that making one more now works without error


# Some test to illustrate what the formatting does
def test_error_str(file_regression):
    res = create_error(1.0)

    # Don't worry about the value of instance_index
    res_check = re.sub(r"instance_index=\d*", "instance_index=n", str(res))
    file_regression.check(res_check)


def test_error_pprint(file_regression):
    res = create_error(1.0)

    # Don't worry about the value of instance_index
    res_check = re.sub(r"instance_index=\d*", "instance_index=n", pretty(res))
    file_regression.check(res_check)


def test_error_html(file_regression):
    res = create_error(1.0)

    # Don't worry about the value of instance_index
    res_check = re.sub(r"instance_index=\d*", "instance_index=n", res._repr_html_())
    file_regression.check(res_check, extension=".html")
