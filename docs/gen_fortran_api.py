"""
Drive Ford to create Fortran API docs
"""

from __future__ import annotations

import shutil
import subprocess


def main():
    """
    Generate the Fortran docs woth FORD
    """
    ford = shutil.which("ford")
    if ford is None:
        msg = "Could not find FORD executable"
        raise AssertionError(msg)

    subprocess.run(  # noqa: S603
        [ford, "ford_example.md"],
        check=True,
    )


if __name__ == "__main__":
    main()
