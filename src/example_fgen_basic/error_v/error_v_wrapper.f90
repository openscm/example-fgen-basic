!> Wrapper for interfacing `m_error_v` with Python
!>
!> Written by hand here.
!> Generation to be automated in future (including docstrings of some sort).
module m_error_v_w

    ! => allows us to rename on import to avoid clashes
    use m_error_v, only: ErrorV

    ! The manager module, which makes this all work
    use m_error_v_manager, only: &
        get_free_instance_number, &
        error_v_manager_associate_pointer_with_instance => associate_pointer_with_instance
        ! TODO: build and finalisation

    implicit none
    private

    public :: get_free_instance_number, iget_code, iget_message

contains

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

end module m_error_v_w
