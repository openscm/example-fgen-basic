from example_fgen_basic.error_v import ErrorVPtrBased


def test_build_finalise():
    inst = ErrorVPtrBased.from_build_args(code=2, message="Hello world")

    assert inst.code == 2
    assert inst.message == "Hello world"

    inst_same_ptr = ErrorVPtrBased(inst.instance_ptr)

    assert inst_same_ptr.code == 2
    assert inst_same_ptr.message == "Hello world"
    assert inst.initialised
    assert inst.is_associated

    inst.finalise()
    inst_same_ptr.finalise()
    assert not inst.initialised
    assert not inst.is_associated

    # Fun mess you can get yourself into if you use the same pointer
    # and it is finalised elsewhere
    assert inst_same_ptr.code != 2
    # This is true as the Python has no way of knowing
    # that it has been finalised elsewhere
    # (you basically need rust's borrow checker to not stuff this up)
    assert inst_same_ptr.initialised
    # This is how you can check for actual association
    # (given this, maybe want to change how `initialised` works)
    assert not inst_same_ptr.is_associated
