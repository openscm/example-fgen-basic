"""
Tests of `example_fgen_basic.error_v.creation`
"""

import numpy as np

from example_fgen_basic.error_v import ErrorV
from example_fgen_basic.error_v.creation import create_error, create_errors

# Tests to write:
# - passing derived types to Fortran (new test module)
# - retrieving multiple derived type instances from Fortran
#   (basically checking the manager's auto-resizing of the number of instances)


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


def test_create_error_lots_of_repeated_calls():
    # We should be able to just keep calling `create_error`
    # without hitting segfaults or other weirdness.
    # This is basically testing that we're freeing the temporary
    # Fortran derived types correctly
    # (and sort of a speed test, this shouldn't be noticeably slow)
    # hence we may move this test somewhere more generic at some point.
    for _ in range(1e5):
        create_error(1)


def test_create_multiple_errors():
    res = create_errors(np.arange(6))

    for i, v in enumerate(res):
        if i % 2 == 0:
            assert res.code == 1
            assert res.message == "Even number supplied"
        else:
            assert res.code == 0
            assert res.message == ""
