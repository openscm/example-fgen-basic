"""
Tests of `example_fgen_basic.error_v.creation`
"""

import numpy as np
import pytest

from example_fgen_basic.error_v import ErrorV
from example_fgen_basic.error_v.creation import create_error, create_errors
from example_fgen_basic.pyfgen_runtime.exceptions import FortranError


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


@pytest.mark.xfail(reason="Not implemented")
def test_create_error_negative_raises():
    # TODO: switch to more precise error type
    with pytest.raises(FortranError):
        create_error(-1.0)


def test_create_error_lots_of_repeated_calls():
    # We should be able to just keep calling `create_error`
    # without hitting segfaults or other weirdness.
    # This is basically testing that we're freeing the temporary
    # Fortran derived types correctly
    # (and sort of a speed test, this shouldn't be noticeably slow)
    # hence we may move this test somewhere more generic at some point.
    for _ in range(int(1e5)):
        create_error(1)


def test_create_multiple_errors():
    res = create_errors(np.arange(6))
    for i, v in enumerate(res):
        if i % 2 == 0:
            print(v.code, v.message)
            assert v.code == 1
            assert v.message == "Even number supplied"
        else:
            print(v.code, v.message)
            assert v.code == 0
            assert v.message == ""
