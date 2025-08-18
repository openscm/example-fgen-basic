#!/usr/bin/env python3
"""
Script file to strip unwanted files from dist tarball

"""

import os
import shutil

dist_root = os.environ.get("MESON_DIST_ROOT")

# Files/Folders to strip from the *.tar.gz
exclude = [
    ".github",
    "docs",
    "tests",
    "changelog",
    "stubs",
    "scripts",
    ".pre-commit-config.yaml",
    ".gitignore",
    ".readthedocs.yaml",
    "Makefile",
    "environment-docs-conda-base.yml",
    "mkdocs.yml",
    "uv.lock",
    "requirements-docs-locked.txt",
    "requirements-incl-optional-locked.txt",
    "requirements-locked.txt",
    "requirements-only-tests-locked.txt",
    "requirements-only-tests-min-locked.txt",
    "requirements-upstream-dev.txt",
    ".copier-answers.yml",
    ".fprettify.rc",
]

# Stripping
for path in exclude:
    abs_path = os.path.join(dist_root, path)
    if not os.path.exists(abs_path):
        print(f"File not found: {abs_path}")
    if os.path.isdir(abs_path):
        shutil.rmtree(abs_path)
    elif os.path.isfile(abs_path):
        os.remove(abs_path)
