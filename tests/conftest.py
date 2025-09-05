"""
Re-useable fixtures etc. for tests

See https://docs.pytest.org/en/7.1.x/reference/fixtures.html#conftest-py-sharing-fixtures-across-multiple-files
"""

import os
import sys

if os.environ.get("CI", "false") == "true" and sys.platform == "win32":
    os.add_dll_directory("C:\\mingw64\\bin")
