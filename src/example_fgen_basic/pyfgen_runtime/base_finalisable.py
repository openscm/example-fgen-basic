"""
Runtime helper to support wrapping of Fortran derived types
"""

from __future__ import annotations

from abc import ABC, abstractmethod
from functools import wraps
from typing import Any, Callable, Concatenate, ParamSpec, TypeVar

import attrs
from attrs import define, field

from example_fgen_basic.pyfgen_runtime.exceptions import (
    NotInitialisedError,
)
from example_fgen_basic.pyfgen_runtime.formatting import to_html, to_pretty, to_str

# Might be needed for Python 3.9
# from typing_extensions import Concatenate, ParamSpec


INVALID_INSTANCE_INDEX: int = -1
"""
Value used to denote an invalid `instance_index`.

This can occur value when a wrapper class
has not yet been initialised (connected to a Fortran instance).
"""


@define
class FinalisableWrapperBase(ABC):
    """
    Base class for Fortran derived type wrappers
    """

    instance_index: int = field(
        validator=attrs.validators.instance_of(int),
        default=INVALID_INSTANCE_INDEX,
    )
    """
    Model index of wrapper Fortran instance
    """

    def __str__(self) -> str:
        """
        Get string representation of self
        """
        return to_str(
            self,
            self.exposed_attributes,
        )

    def _repr_pretty_(self, p: Any, cycle: bool) -> None:
        """
        Get pretty representation of self

        Used by IPython notebooks and other tools
        """
        to_pretty(
            self,
            self.exposed_attributes,
            p=p,
            cycle=cycle,
        )

    def _repr_html_(self) -> str:
        """
        Get html representation of self

        Used by IPython notebooks and other tools
        """
        return to_html(
            self,
            self.exposed_attributes,
        )

    @property
    def initialised(self) -> bool:
        """
        Is the instance initialised, i.e. connected to a Fortran instance?
        """
        return self.instance_index != INVALID_INSTANCE_INDEX

    @property
    @abstractmethod
    def exposed_attributes(self) -> tuple[str, ...]:
        """
        Attributes exposed by this wrapper
        """
        ...

    # TODO: consider whether we need these
    # @classmethod
    # @abstractmethod
    # def from_new_connection(cls) -> FinalisableWrapperBase:
    #     """
    #     Initialise by establishing a new connection with the Fortran module
    #
    #     This requests a new model index from the Fortran module and then
    #     initialises a class instance
    #
    #     Returns
    #     -------
    #     New class instance
    #     """
    #     ...
    #
    # @abstractmethod
    # def finalise(self) -> None:
    #     """
    #     Finalise the Fortran instance and set self back to being uninitialised
    #
    #     This method resets ``self.instance_index`` back to
    #     ``_UNINITIALISED_instance_index``
    #
    #     Should be decorated with :func:`check_initialised`
    #     """
    #     # call to Fortran module goes here when implementing
    #     self._uninitialise_instance_index()

    def _uninitialise_instance_index(self) -> None:
        self.instance_index = INVALID_INSTANCE_INDEX


P = ParamSpec("P")
T = TypeVar("T")
Wrapper = TypeVar("Wrapper", bound=FinalisableWrapperBase)


def check_initialised(
    method: Callable[Concatenate[Wrapper, P], T],
) -> Callable[Concatenate[Wrapper, P], T]:
    """
    Check that the wrapper object has been initialised before executing the method

    Parameters
    ----------
    method
        Method to wrap

    Returns
    -------
    :
        Wrapped method

    Raises
    ------
    InitialisationError
        Wrapper is not initialised
    """

    @wraps(method)
    def checked(
        ref: Wrapper,
        *args: P.args,
        **kwargs: P.kwargs,
    ) -> Any:
        if not ref.initialised:
            raise NotInitialisedError(ref, method)

        return method(ref, *args, **kwargs)

    return checked  # type: ignore


# Thank you for type hints info
# https://adamj.eu/tech/2021/05/11/python-type-hints-args-and-kwargs/
def execute_finalise_on_fail(
    inst: FinalisableWrapperBase,
    func_to_try: Callable[Concatenate[int, P], T],
    *args: P.args,
    **kwargs: P.kwargs,
) -> T:
    """
    Execute a function, finalising the instance before raising if any error occurs

    This function is most useful in factory functions where it provides a
    clean way of ensuring that any Fortran is freed up in the event of an
    initialisation failure for any reason

    @Marco note: I'm not sure this is a very good pattern,
    we may get rid of it.

    Parameters
    ----------
    inst
        Instance whose model index we will use when executing the functin

    func_to_try
        Function to try executing, must take `inst`'s instance pointer as its
        first argument

    *args
        Passed to `func_to_try`

    **kwargs
        Passed to `func_to_try`

    Returns
    -------
    :
        Result of calling `func_to_try(inst.instance_ptr, *args, **kwargs)`

    Raises
    ------
    Exception
        Any exception which occurs when calling `func_to_try`. Before the
        exception is raised, `inst.finalise()` is called.
    """
    try:
        return func_to_try(inst.instance_index, *args, **kwargs)
    except RuntimeError:
        # finalise the instance before raising
        inst.finalise()

        raise
