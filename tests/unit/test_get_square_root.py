"""
Tests of `example_fgen_basic.get_square_root`
"""

import pytest

from example_fgen_basic.get_square_root import get_square_root
from example_fgen_basic.pyfgen_runtime.exceptions import FortranError


@pytest.mark.parametrize(
    "inv, exp, exp_error",
    (
        (4.0, 2.0, None),
        (-4.0, None, pytest.raises(FortranError, match="Input value was negative")),
    ),
)
def test_basic(inv, exp, exp_error):
    if exp is not None:
        assert get_square_root(inv) == exp

    else:
        if exp_error is None:
            raise AssertionError

        with exp_error:
            get_square_root(inv)
