!> Wrapper for interfacing `m_error_v_creation` with Python
!>
!> Written by hand here.
!> Generation to be automated in future (including docstrings of some sort).
module m_error_v_creation_w

    ! => allows us to rename on import to avoid clashes
    use m_error_v_creation, only: o_create_error => create_error
    use m_error_v, only: ErrorV

    ! The manager module, which makes this all work
    use m_error_v_manager, only: &
        error_v_manager_get_free_instance_number => get_free_instance_number, &
        error_v_manager_associate_pointer_with_instance => associate_pointer_with_instance
        ! TODO: finalisation

    implicit none
    private

    public :: create_error, iget_code, iget_message

contains

    subroutine create_error(inv, res_instance_index)
    ! Needs to be subroutine to have the created instance persist I think
    ! (we can check)
    ! function create_error(inv) result(res_instance_index)

        integer, intent(in) :: inv
        !! Input value to use to create the error

        integer, intent(out) :: res_instance_index
        !! Instance index of the result
        !
        ! This is the major trick for wrapping.
        ! We return instance indexes (integers) to Python rather than the instance itself.

        type(ErrorV), pointer :: res

        ! This is the other trick for wrapping.
        ! We have to ensure that we have correctly associated pointers
        ! with the derived type instances we want to 'pass' across the Python-Fortran interface.
        ! Once we've done this, we can then set them more or less like normal derived types.
        res_instance_index = error_v_manager_get_free_instance_number()
        call error_v_manager_associate_pointer_with_instance(res_instance_index, res)

        ! Use the pointer more or less like a normal instance of the derived type
        res = o_create_error(inv)
        ! Ensure that the instance index is set correctly
        res % instance_index = res_instance_index

    end subroutine create_error

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

        character(len=128), intent(out) :: message

        type(ErrorV), pointer :: instance

        call error_v_manager_associate_pointer_with_instance(instance_index, instance)

        message = instance % message

    end subroutine iget_message

end module m_error_v_creation_w
