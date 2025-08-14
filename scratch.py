"""
Run with `uv run --no-editable --reinstall-package example python scratch.py`

Requires no editable to avoid Fortran fun headaches
(although there are better ways to do this,
TODO: read https://mesonbuild.com/meson-python/how-to-guides/editable-installs.html).
Requires reinstall to pick up changes to src.
"""

import pint

from example.get_wavelength import get_wavelength, get_wavelength_plain

ur = pint.get_application_registry()

print(f"{get_wavelength_plain(400.0e12)=}")

print(f"{get_wavelength(ur.Quantity(400.0, 'THz')).to('nm')=}")
