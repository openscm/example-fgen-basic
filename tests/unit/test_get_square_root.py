"""
Tests of `example_fgen_basic.get_square_root`
"""

from unittest.mock import MagicMock, patch

import pytest

from example_fgen_basic.get_square_root import get_square_root
from example_fgen_basic.pyfgen_runtime.exceptions import (
    FortranError,
)
from example_fgen_basic.result import ResultGen


@pytest.mark.parametrize(
    "inv, exp, exp_error",
    [
        (4.0, 2.0, None),
        (
            -4.0,
            None,
            pytest.raises(FortranError, match="Error: Negative Input -> -4.000"),
        ),
    ],
)
def test_basic(inv, exp, exp_error):
    ResultGen.free_fortran_memory()
    if exp is not None:
        assert get_square_root(inv) == exp

    else:
        if exp_error is None:
            raise AssertionError

        with exp_error:
            get_square_root(inv)


@pytest.mark.parametrize(
    "code, msg, expected_exception, expected_match",
    [
        (None, None, AssertionError, "Finalisation of index"),
        (1, "Failed finalisation!", FortranError, "Failed finalisation!"),
    ],
)
# This replaces 'm_result_w' with a MagicMock entirely.
@patch("example_fgen_basic.get_square_root.m_result_w")
@patch("example_fgen_basic.get_square_root.m_get_square_root_w")
@patch("example_fgen_basic.get_square_root.ResultGen")
# ruff: noqa: PLR0913
def test_fortran_finalization_failure(
    mock_result_gen_class,
    mock_f_get_sqrt,
    mock_f_result_module,
    code,
    msg,
    expected_exception,
    expected_match,
):
    # Setup the mock for the main Fortran call
    mock_f_get_sqrt.get_square_root.return_value = 1

    # Setup the ResultGen factory mock
    mock_success = MagicMock()
    mock_success.error_v = None
    mock_success.data_v = 25.0

    mock_error = MagicMock()
    if code is None:
        mock_error.error_v = None
    else:
        mock_error.error_v.code = code
        mock_error.error_v.message = msg
        mock_error.data_v = None

    mock_result_gen_class.from_instance_index.side_effect = [mock_success, mock_error]

    # Setup the failure on the module mock
    mock_f_result_module.finalise_instance.return_value = 1

    with pytest.raises(expected_exception, match=expected_match):
        get_square_root(625.0)
