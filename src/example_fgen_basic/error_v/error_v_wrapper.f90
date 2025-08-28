!> Wrapper for interfacing `m_error_v` with Python
!>
!> Written by hand here.
!> Generation to be automated in future (including docstrings of some sort).
module m_error_v_w

    ! => allows us to rename on import to avoid clashes
    use m_error_v, only: ErrorV

    ! The manager module, which makes this all work
    use m_error_v_manager, only: &
        error_v_manager_get_free_instance_number => get_free_instance_number, &
        error_v_manager_finalise_instance => finalise_instance, &
        error_v_manager_associate_pointer_with_instance => associate_pointer_with_instance
        ! TODO: build and finalisation

    implicit none
    private

    public :: get_free_instance_number, instance_build, instance_finalise, &
              iget_code, iget_message

contains

    function get_free_instance_number() result(instance_index)

        integer :: instance_index

        instance_index = error_v_manager_get_free_instance_number()

    end function get_free_instance_number

    subroutine instance_build(instance_index, code, message)
        !> Build an instance

        integer, intent(in) :: instance_index
        !! Instance index
        !
        ! This is the major trick for wrapping.
        ! We pass instance indexes (integers) to Python rather than the instance itself.

        integer, intent(in) :: code
        character(len=*), optional, intent(in) :: message

        type(ErrorV), pointer :: instance

        call error_v_manager_associate_pointer_with_instance(instance_index, instance)

        call instance % build(code, message)

    end subroutine instance_build

    subroutine instance_finalise(instance_index)
        !> Finalise an instance

        integer, intent(in) :: instance_index
        !! Instance index
        !
        ! This is the major trick for wrapping.
        ! We pass instance indexes (integers) to Python rather than the instance itself.

        call error_v_manager_finalise_instance(instance_index)

    end subroutine instance_finalise

    ! Full set of wrapping strategies to pass different types in e.g.
    ! https://gitlab.com/magicc/fgen/-/blob/switch-to-uv/tests/test-data/exposed_attrs/src/exposed_attrs/exposed_attrs_wrapped.f90
    ! (we will do a full re-write of the code which generates this,
    ! but the strategies will probably stay as they are)
    subroutine iget_code( &
        instance_index, &
        code &
        )

        integer, intent(in) :: instance_index

        integer, intent(out) :: code

        type(ErrorV), pointer :: instance

        call error_v_manager_associate_pointer_with_instance(instance_index, instance)

        code = instance % code

    end subroutine iget_code

    subroutine iget_message( &
        instance_index, &
        message &
        )

        integer, intent(in) :: instance_index

        ! TODO: make this variable length
        character(len=128), intent(out) :: message

        type(ErrorV), pointer :: instance

        call error_v_manager_associate_pointer_with_instance(instance_index, instance)

        message = instance % message

    end subroutine iget_message

end module m_error_v_w
