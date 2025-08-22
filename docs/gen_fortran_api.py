"""
Drive Ford to create Fortran API docs
"""

from __future__ import annotations

import shutil
import subprocess
from pathlib import Path

import mkdocs_gen_files

REPO_ROOT = Path(__file__).parents[1]
PACKAGE_NAME_ROOT = "example_fgen_basic"
ROOT_DIR = Path("fortran-api")
nav = mkdocs_gen_files.Nav()

ford = shutil.which("ford")
if ford is None:
    msg = "Could not find FORD executable"
    raise AssertionError(msg)

subprocess.run(  # noqa: S603
    [ford, "ford_config.md"],
    check=True,
)

# Put back the gitkeep file which ford deletes
(REPO_ROOT / "docs" / ROOT_DIR / ".gitkeep").touch()
