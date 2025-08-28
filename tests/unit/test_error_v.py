"""
Tests of `example_fgen_basic.error_v`
"""

import pytest

from example_fgen_basic.error_v import ErrorV


def test_build_finalise():
    inst = ErrorV.from_build_args(code=2, message="Hello world")

    assert inst.code == 2
    assert inst.message == "Hello world"

    assert inst.initialised

    inst.finalise()
    assert not inst.initialised


def test_build_finalise_multiple_instances_same_index():
    inst = ErrorV.from_build_args(code=2, message="Hello world")

    original_instance_index = inst.instance_index

    assert inst.code == 2
    assert inst.message == "Hello world"

    inst_same_index = ErrorV(inst.instance_index)

    assert inst_same_index.code == 2
    assert inst_same_index.message == "Hello world"
    assert inst.initialised

    inst.finalise()
    # # Currently this causes a hard stop.
    # # That's the right behaviour.
    # # We will make it not be a hard fail when we switch to result types.
    # inst_same_index.finalise()
    assert not inst.initialised

    ### Problem 1 ###
    # # With the current implementation,
    # # finalising via `inst` does not cause `inst_same_index` to also be finalised
    # assert not inst_same_index.initialised

    inst_new = ErrorV.from_build_args(code=3, message="Didn't expect this")
    # New instance uses the newly freed index.
    assert inst_new.instance_index == original_instance_index
    # Which means the new instance and the instance
    # which was initialised previously now have the same instance index
    assert inst_new.instance_index == inst_same_index.instance_index

    ### Problem 2 ###
    # So, if we look at `inst_same_index`'s attribute values, we get a surprise
    # The code isn't 2 as was set above.
    # Instead, the value has changed 'in the background' i.e. our view is 'stale'.
    assert inst_same_index.code == 3
    assert inst_same_index.message == "Didn't expect this"

    # Something like this is what we actually want to happen
    # (if we try to access via inst_same_index again,
    # we get told that our view is out of date).
    # Could be warning or error, not sure what makes more sense...
    with pytest.raises(StaleViewError):
        inst_same_index.code
        inst_same_index.message
