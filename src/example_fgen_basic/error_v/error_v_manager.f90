!> Manager of `ErrorV` (TODO: xref) across the Fortran-Python interface
!>
!> Written by hand here.
!> Generation to be automated in future (including docstrings of some sort).
!
! TODO: make it possible to reallocate the number of instances
module m_error_v_manager

    use fpyfgen_derived_type_manager_helpers, only: finalise_derived_type_instance_number, &
                                              get_derived_type_free_instance_number
    use m_error_v, only: ErrorV

    implicit none
    private

    integer, public, parameter :: N_INSTANCES_DEFAULT = 4096
    !! Default maximum number of instances which can be created simultaneously
    !
    ! TODO: allow reallocation if possible

    ! This is the other trick, we hold an array of instances
    ! for tracking what is being passed back and forth across the interface.
    type(ErrorV), target, dimension(N_INSTANCES_DEFAULT) :: instance_array
    logical, dimension(N_INSTANCES_DEFAULT) :: instance_available = .true.

    public :: get_free_instance_number, &
              associate_pointer_with_instance, &
              finalise_instance

contains

    function get_free_instance_number() result(instance_index)
        !! Get the index of a free instance

        integer :: instance_index
        !! Free instance index

        call get_derived_type_free_instance_number( &
            instance_index, &
            N_INSTANCES_DEFAULT, &
            instance_available, &
            instance_array &
            )

    end function get_free_instance_number

    ! Might be a better way to do this as the pointers are a bit confusing, let's see
    subroutine associate_pointer_with_instance(instance_index, instance_pointer)
        !! Associate a pointer with the instance corresponding to the given model index
        !!
        !! Stops execution if the instance has not already been initialised.

        integer, intent(in) :: instance_index
        !! Index of the instance to point to

        type(ErrorV), pointer, intent(inout) :: instance_pointer
        !! Pointer to associate

        call check_index_claimed(instance_index)
        instance_pointer => instance_array(instance_index)

    end subroutine associate_pointer_with_instance

    subroutine finalise_instance(instance_index)
        !! Finalise an instance

        integer, intent(in) :: instance_index
        !! Index of the instance to finalise

        call check_index_claimed(instance_index)
        call finalise_derived_type_instance_number( &
            instance_index, &
            N_INSTANCES_DEFAULT, &
            instance_available, &
            instance_array &
            )

    end subroutine finalise_instance

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

        if (instance_array(instance_index) % instance_index < 1) then
            ! TODO: switch to errors here - will require some thinking
            print *, "Index ", instance_index, " is associated with an instance that has instance index < 1", &
                "instance's instance_index attribute ", instance_array(instance_index) % instance_index
            error stop 1
        end if

    end subroutine check_index_claimed

end module m_error_v_manager
