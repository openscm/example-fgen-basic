"""
Tests of `example_fgen_basic.error_v.passing`
"""

import numpy as np

from example_fgen_basic.error_v import ErrorV
from example_fgen_basic.error_v.passing import pass_error, pass_errors


def test_pass_error_odd():
    res = pass_error(ErrorV(code=1, message="hi"))

    assert res


def test_pass_error_even():
    res = pass_error(ErrorV(code=0))

    assert not res


def test_pass_error_lots_of_repeated_calls():
    # We should be able to just keep calling `pass_error`
    # without hitting segfaults or other weirdness.
    # This is basically testing that we're freeing the temporary
    # Fortran derived types correctly
    # (and sort of a speed test, this shouldn't be noticeably slow)
    # hence we may move this test somewhere more generic at some point.
    for _ in range(1e5):
        pass_error(ErrorV(code=0))


def test_pass_multiple_errors():
    res = pass_errors([ErrorV(code=0), ErrorV(code=0), ErrorV(code=1)])

    np.testing.assert_all_equal(res, np.array([True, True, False]))
