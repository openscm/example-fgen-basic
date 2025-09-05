"""
Re-useable fixtures etc. for tests

See https://docs.pytest.org/en/7.1.x/reference/fixtures.html#conftest-py-sharing-fixtures-across-multiple-files
"""

import os

if dll_directory_to_add := os.environ.get("PYTHON_ADD_DLL_DIRECTORY", None):
    # Add the directory which has the libgfortran.dll file.
    #
    # A super deep dive into this is here:
    # https://stackoverflow.com/a/78276248
    # The tl;dr is - mingw64's linker can be tricked by windows craziness
    # into linking a dynamic library even when we wanted only static links,
    # so if you want to avoid this, link with something else (e.g. the MS linker).
    # (From what I know, this isn't an issue for the built wheels
    # thanks to the cleverness of delvewheel)
    os.add_dll_directory(dll_directory_to_add)
    # os.add_dll_directory("C:\\mingw64\\bin")
