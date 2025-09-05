# ---
# jupyter:
#   jupytext:
#     text_representation:
#       extension: .py
#       format_name: percent
#       format_version: '1.3'
#       jupytext_version: 1.17.2
#   kernelspec:
#     display_name: Python 3 (ipykernel)
#     language: python
#     name: python3
# ---

# %% [markdown]
# # Basic demo
#
# Here we show a very basic demo of how to use the package.
# The actual behaviour isn't so interesting,
# but it demonstrates that we can wrap code
# that is ultimately written in Fortran.

# %% [markdown]
# ## Imports

# %%
import pint

from example_fgen_basic.error_v import ErrorV
from example_fgen_basic.error_v.creation import create_error, create_errors
from example_fgen_basic.error_v.passing import pass_error, pass_errors
from example_fgen_basic.get_wavelength import get_wavelength, get_wavelength_plain

# %% [markdown]
# ## Calculation with basic types
#
# Here we show how we can use a basic wrapped function.
# This functionality isn't actually specific to our wrappers
# (you can do the same with f2py),
# but it's a useful starting demonstration.

# %%
# `_plain` because this works on plain floats,
# not quantities with units (see below for this demonstration)
get_wavelength_plain(400.0e12)

# %% [markdown]
# With these python wrappers,
# we can also do nice things like support interfaces that use units
# (this would be much more work to implement directly in Fortran).

# %%
ur = pint.get_application_registry()

# %%
get_wavelength(ur.Quantity(400.0, "THz")).to("nm")

# %% [markdown]
# ## Receiving and passing derived types
#
# TODO: more docs and cross-references on how this actually works

# %% [markdown]
# We can receive a Python-equivalent of a Fortran derived type.

# %%
create_error(3)

# %% [markdown]
# Or multiple derived types.

# %%
create_errors([1, 2, 1, 5])

# %% [markdown]
# We can also pass Python-equivalent of Fortran derived types back into Fortran.

# %%
pass_error(ErrorV(code=0))

# %%
pass_errors([ErrorV(code=0), ErrorV(code=3), ErrorV(code=5), ErrorV(code=-2)])
