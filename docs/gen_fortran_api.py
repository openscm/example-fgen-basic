"""
Drive Ford to create Fortran API docs
"""

from __future__ import annotations

import shutil
import subprocess

ford = shutil.which("ford")
if ford is None:
    msg = "Could not find FORD executable"
    raise AssertionError(msg)

subprocess.run(  # noqa: S603
    [ford, "ford_config.md"],
    check=True,
)
