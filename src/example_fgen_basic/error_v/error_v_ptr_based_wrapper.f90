!> Wrapper for interfacing `m_error_v` with Python, using pointer only (no instance array)
!>
!> Written by hand here.
!> Generation to be automated in future (including docstrings of some sort).
module m_error_v_ptr_based_w

    use iso_c_binding, only: c_ptr, c_f_pointer

    use m_error_v, only: ErrorV

    implicit none
    private

    public :: iget_code, iget_message

contains

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
