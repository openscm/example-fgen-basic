!> Wrapper for interfacing `m_error_v` with Python
!>
!> Written by hand here.
!> Generation to be automated in future (including docstrings of some sort).
module m_error_v_w

    ! => allows us to rename on import to avoid clashes
    use m_error_v, only: ErrorV

    ! The manager module, which makes this all work
    use m_error_v_manager, only: &
        error_v_manager_finalise_instance => finalise_instance, &
        error_v_manager_get_instance => get_instance

    implicit none
    private

    public :: finalise_instance, finalise_instances, &
              get_code, get_message

contains

    subroutine finalise_instance(instance_index)
        !! Finalise an instance

        integer, intent(in) :: instance_index
        !! Instance index
        !
        ! This is the major trick for wrapping.
        ! We pass instance indexes (integers) to Python rather than the instance itself.

        call error_v_manager_finalise_instance(instance_index)

    end subroutine finalise_instance


    subroutine finalise_instances(instance_indexes)
        !! Finalise an instance

        integer, dimension(:), intent(in) :: instance_indexes
        !! Instance indexes to finalise
        !
        ! This is the major trick for wrapping.
        ! We pass instance indexes (integers) to Python rather than the instance itself.

        integer :: i

        do i = 1, size(instance_indexes)
            call error_v_manager_finalise_instance(instance_indexes(i))
        end do

    end subroutine finalise_instances

    ! Full set of wrapping strategies to get/pass different types in e.g.
    ! https://gitlab.com/magicc/fgen/-/blob/switch-to-uv/tests/test-data/exposed_attrs/src/exposed_attrs/exposed_attrs_wrapped.f90
    ! (we will do a full re-write of the code which generates this,
    ! but the strategies will probably stay as they are)
    subroutine get_code( &
        instance_index, &
        code &
        )

        integer, intent(in) :: instance_index

        integer, intent(out) :: code

        type(ErrorV)  :: instance

        instance = error_v_manager_get_instance(instance_index)

        code = instance % code

    end subroutine get_code

    subroutine get_message( &
        instance_index, &
        message &
        )

        integer, intent(in) :: instance_index

        ! TODO: make this variable length
        character(len=128), intent(out) :: message

        type(ErrorV)  :: instance

        instance = error_v_manager_get_instance(instance_index)

        message = instance % message

    end subroutine get_message

end module m_error_v_w
