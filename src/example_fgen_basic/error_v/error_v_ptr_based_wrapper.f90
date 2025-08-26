!> Wrapper for interfacing `m_error_v` with Python, using pointer only (no instance array)
!>
!> Written by hand here.
!> Generation to be automated in future (including docstrings of some sort).
module m_error_v_ptr_based_w

    use iso_c_binding, only: c_f_pointer, c_loc, c_null_ptr, c_ptr

    use m_error_v, only: ErrorV

    implicit none
    private

    public :: get_instance_ptr, instance_build, instance_finalise, is_associated, &
              iget_code, iget_message

contains

    subroutine get_instance_ptr(res_instance_ptr)
        !> Get a pointer to a new instance
        !
        ! Needs to be subroutine to have the created instance persist I think
        ! (we can check)
        ! function create_error(inv) result(res_instance_index)

        !f2py integer(8), intent(out) :: res_instance_ptr
        type(c_ptr), intent(out) :: res_instance_ptr
        !! Pointer to the resulting instance
        !
        ! This is the major trick for wrapping.
        ! We return pointers (passed as integers) to Python rather than the instance itself.

        type(ErrorV), pointer :: res
        ! Question is: when does this get deallocated?
        ! When we go out of scope?
        ! If yes, that will be why we had to do this array thing.
        allocate(res)

        res_instance_ptr = c_loc(res)

    end subroutine get_instance_ptr

    subroutine instance_build(instance_ptr, code, message)
        !> Build an instance

        !f2py integer(8), intent(in) :: instance_ptr
        type(c_ptr), intent(in) :: instance_ptr
        !! Pointer to the instance
        !
        ! This is the major trick for wrapping.
        ! We pass pointers (passed as integers) to Python rather than the instance itself.

        integer, intent(in) :: code
        character(len=*), optional, intent(in) :: message

        type(ErrorV), pointer :: inst

        call c_f_pointer(instance_ptr, inst)

        call inst % build(code, message)

    end subroutine instance_build

    subroutine instance_finalise(instance_ptr)
        !> Finalise an instance

        !f2py integer(8), intent(inout) :: instance_ptr
        type(c_ptr), intent(inout) :: instance_ptr
        !! Pointer to the instance
        !
        ! This is the major trick for wrapping.
        ! We pass pointers (passed as integers) to Python rather than the instance itself.

        type(ErrorV), pointer :: inst

        call c_f_pointer(instance_ptr, inst)

        ! This may be why we used the array approach.
        ! The issue here is that, if you call this method twice,
        ! there is no way to work out that you're the 'second caller'.
        ! When the first call calls `deallocate(inst)`,
        ! this puts any other pointers to the instance in an undefined status
        ! (https://www.ibm.com/docs/en/xl-fortran-aix/16.1.0?topic=attributes-deallocate).
        ! The result of calling associated on an undefined pointer
        ! can be anything (https://stackoverflow.com/questions/72140217/can-you-test-for-nullpointers-in-fortran),
        ! i.e. there is no way to tell that someone else
        ! has already called finalise before you have.
        ! This also explains the undefined status issue nicely:
        ! community.intel.com/t5/Intel-Fortran-Compiler/DEALLOCATING-DATA-TYPE-POINTERS/m-p/982338#M100027
        !
        ! We'd have to introduce some reference counter to make this work I think.
        ! Probably better advice for now, don't share pointer values
        ! on the Python side, you have to be super careful about uninitialising if you do.
        ! Avoiding pointers and using allocatable instead
        ! was probably the other reason we did it how we did
        ! community.intel.com/t5/Intel-Fortran-Compiler/how-to-test-if-pointer-array-is-allocated/m-p/1138643#M136486.
        if (associated(inst)) then
            call inst % finalise()
            deallocate(inst)
        end if

    end subroutine instance_finalise

    subroutine is_associated(instance_ptr, res)
        !> Check if a pointer is associated with an instance

        !f2py integer(8), intent(in) :: instance_ptr
        type(c_ptr), intent(in) :: instance_ptr
        !! Pointer to the instance
        !
        ! This is the major trick for wrapping.
        ! We pass pointers (passed as integers) to Python rather than the instance itself.

        logical, intent(out) :: res
        !! Whether `instance_ptr` is associated or not

        type(ErrorV), pointer :: inst

        call c_f_pointer(instance_ptr, inst)

        print *, instance_ptr
        print *, inst
        res = associated(inst)
        print *, res

    end subroutine is_associated

    ! Full set of wrapping strategies to pass different types in e.g.
    ! https://gitlab.com/magicc/fgen/-/blob/switch-to-uv/tests/test-data/exposed_attrs/src/exposed_attrs/exposed_attrs_wrapped.f90
    ! (we will do a full re-write of the code which generates this,
    ! but the strategies will probably stay as they are)
    subroutine iget_code( &
        instance_ptr, &
        code &
        )

        !f2py integer(8), intent(in) :: instance_ptr
        type(c_ptr), intent(in) :: instance_ptr

        integer, intent(out) :: code

        type(ErrorV), pointer :: instance

        call c_f_pointer(instance_ptr, instance)

        code = instance % code

    end subroutine iget_code

    subroutine iget_message( &
        instance_ptr, &
        message &
        )

        !f2py integer(8), intent(in) :: instance_ptr
        type(c_ptr), intent(in) :: instance_ptr

        character(len=128), intent(out) :: message

        type(ErrorV), pointer :: instance

        call c_f_pointer(instance_ptr, instance)

        message = instance % message

    end subroutine iget_message

end module m_error_v_ptr_based_w
