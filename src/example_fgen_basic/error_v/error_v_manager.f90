!> Manager of `ErrorV` (TODO: xref) across the Fortran-Python interface
!>
!> Written by hand here.
!> Generation to be automated in future (including docstrings of some sort).
!
! TODO: make it possible to reallocate the number of instances
module m_error_v_manager

    use m_error_v, only: ErrorV

    implicit none
    private

    type(ErrorV), dimension(1) :: instance_array
    logical, dimension(1) :: instance_available = .true.

    public :: finalise_instance, get_available_instance_index, get_instance, set_instance_index_to

contains

    subroutine finalise_instance(instance_index)
        !! Finalise an instance

        integer, intent(in) :: instance_index
        !! Index of the instance to finalise

        call check_index_claimed(instance_index)

        call instance_array(instance_index) % finalise()
        instance_available(instance_index) = .true.

    end subroutine finalise_instance

    subroutine get_available_instance_index(available_instance_index)
        !! Get a free instance index

        ! TODO: think through whether race conditions are possible
        ! e.g. while returning a free index number to one Python call
        ! a different one can be looking up a free instance index at the same time
        ! and something goes wrong (maybe we need a lock)

        integer, intent(out) :: available_instance_index
        !! Available instance index

        integer :: i

        do i = 1, size(instance_array)

            if (instance_available(i)) then

                instance_available(i) = .false.
                available_instance_index = i
                return

            end if

        end do

        ! TODO: switch to returning a Result type with an error set
        print *, "No free indexes"
        error stop 1

    end subroutine get_available_instance_index

    ! Change to pure function when we update check_index_claimed to be pure
    function get_instance(instance_index) result(inst)

        integer, intent(in) :: instance_index
        !! Index in `instance_array` of which to set the value equal to `val`

        type(ErrorV) :: inst
        !! Instance at `instance_array(instance_index)`

        call check_index_claimed(instance_index)
        inst = instance_array(instance_index)

    end function get_instance

    subroutine set_instance_index_to(instance_index, val)

        integer, intent(in) :: instance_index
        !! Index in `instance_array` of which to set the value equal to `val`

        type(ErrorV), intent(in) :: val

        call check_index_claimed(instance_index)
        instance_array(instance_index) = val

    end subroutine set_instance_index_to

    subroutine check_index_claimed(instance_index)
        !! Check that an index has already been claimed
        !!
        !! Stops execution if the index has not been claimed.

        integer, intent(in) :: instance_index
        !! Instance index to check

        if (instance_available(instance_index)) then
            ! TODO: switch to errors here - will require some thinking
            print *, "Index ", instance_index, " has not been claimed"
            error stop 1
        end if

        if (instance_index < 1) then
            ! TODO: switch to errors here - will require some thinking
            print *, "Requested index is ", instance_index, " which is less than 1"
            error stop 1
        end if

    end subroutine check_index_claimed

end module m_error_v_manager
