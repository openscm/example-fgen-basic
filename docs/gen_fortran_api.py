"""
Drive Ford to create Fortran API docs
"""

from __future__ import annotations

import shutil
import subprocess
from pathlib import Path

import mkdocs_gen_files

REPO_ROOT = Path(__file__).parents[1]

FORD_OUTPUT_DIR = Path("docs") / "fortran-api"

ford = shutil.which("ford")
if ford is None:
    msg = "Could not find FORD executable"
    raise AssertionError(msg)

subprocess.run(  # noqa: S603
    [ford, "ford_config.md", "--output_dir", str(FORD_OUTPUT_DIR)],
    check=True,
)

# Copy files across using mkdocs_gen_files
# so it knows to include the files in the final docs.
for entry in (REPO_ROOT / FORD_OUTPUT_DIR).rglob("*"):
    if not entry.is_file():
        continue

    with open(entry, "rb") as fh:
        contents = fh.read()

    target_file = entry.relative_to(REPO_ROOT / "docs")
    with mkdocs_gen_files.open(target_file, "wb") as fh:
        fh.write(contents)
    if target_file.name == "index.html":
        target_file = target_file.parent / "home.html"

        with mkdocs_gen_files.open(target_file, "wb") as fh:
            fh.write(contents)

# with mkdocs_gen_files.open(
#     (FORD_OUTPUT_DIR).relative_to("docs") / "NAVIGATION.md", "w"
# ) as fh:
#     fh.writelines("* [example_fgen_basic](home.html)")

# Remove the ford files (which were just copied)
shutil.rmtree(REPO_ROOT / FORD_OUTPUT_DIR)

# Put back the gitkeep file which ford deletes
gitkeep = REPO_ROOT / FORD_OUTPUT_DIR / ".gitkeep"
gitkeep.parent.mkdir()
gitkeep.touch()
