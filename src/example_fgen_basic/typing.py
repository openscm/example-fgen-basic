"""
Type hints which are too annoying to remember
"""

from __future__ import annotations

from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from typing import Any, TypeAlias, Union

    import numpy as np
    import numpy.typing as npt

    NP_ARRAY_OF_INT: TypeAlias = npt.NDArray[np.integer]
    """
    Type alias for an array of numpy int
    """

    NP_ARRAY_OF_FLOAT: TypeAlias = npt.NDArray[np.floating]
    """
    Type alias for an array of numpy floats
    """

    NP_FLOAT_OR_INT: TypeAlias = Union[np.floating, np.integer]
    """
    Type alias for a numpy float or int (not complex)
    """

    NP_ARRAY_OF_FLOAT_OR_INT: TypeAlias = npt.NDArray[NP_FLOAT_OR_INT]
    """
    Type alias for an array of numpy float or int (not complex)
    """

    NP_ARRAY_OF_NUMBER: TypeAlias = npt.NDArray[np.number[Any]]
    """
    Type alias for an array of numpy float or int (including complex)
    """

    NP_ARRAY_OF_BOOL: TypeAlias = npt.NDArray[np.bool]
    """
    Type alias for an array of booleans
    """
