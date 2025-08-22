"""
Drive Ford to create Fortran API docs
"""

from __future__ import annotations

import shutil
import subprocess
from pathlib import Path

REPO_ROOT = Path(__file__).parents[1]

ford = shutil.which("ford")
if ford is None:
    msg = "Could not find FORD executable"
    raise AssertionError(msg)

subprocess.run(  # noqa: S603
    [ford, "ford_config.md"],
    check=True,
)

# Put back the gitkeep file which ford deletes
(REPO_ROOT / "docs" / "fortran-api" / ".gitkeep").touch()
