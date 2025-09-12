!> Manager of `ErrorV` (TODO: xref) across the Fortran-Python interface
!>
!> Written by hand here.
!> Generation to be automated in future (including docstrings of some sort).
module m_error_v_manager

    use m_error_v, only: ErrorV

    implicit none(type, external)
    private

    type(ErrorV), dimension(:), allocatable :: instance_array
    logical, dimension(:), allocatable :: instance_available

    ! TODO: think about ordering here, alphabetical probably easiest
    public :: build_instance, finalise_instance, get_available_instance_index, get_instance, set_instance_index_to, &
              ensure_instance_array_size_is_at_least

contains

    function build_instance(code, message) result(instance_index)
        !! Build an instance

        integer, intent(in) :: code
        !! Error code

        character(len=*), optional, intent(in) :: message
        !! Error message

        integer :: instance_index
        !! Index of the built instance

        call ensure_instance_array_size_is_at_least(1)
        call get_available_instance_index(instance_index)
        call instance_array(instance_index) % build(code=code, message=message)

    end function build_instance

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
                ! TODO: switch to returning a Result type
                ! res = ResultInt(data=i)
                return

            end if

        end do

        ! TODO: switch to returning a Result type with an error set
        ! res = ResultInt(ErrorV(code=1, message="No available instances"))
        print *, "print"
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
            ! TODO: Switch to using Result here
            ! Use `ResultNone` which is a Result type
            ! that doesn't have a `data` attribute
            ! (i.e. if this succeeds, there is no data to check,
            ! if it fails, the error_v attribute will be set).
            ! So the code would be something like
            ! res = ResultNone(ErrorV(code=1, message="Index ", instance_index, " has not been claimed"))
            print *, "Index ", instance_index, " has not been claimed"
            error stop 1
        end if

        if (instance_index < 1) then
            ! TODO: Switch to using Result here
            ! Use `ResultNone` which is a Result type
            ! that doesn't have a `data` attribute
            ! (i.e. if this succeeds, there is no data to check,
            ! if it fails, the error_v attribute will be set).
            ! So the code would be something like
            ! res = ResultNone(ErrorV(code=2, message="Requested index is ", instance_index, " which is less than 1"))
            print *, "Requested index is ", instance_index, " which is less than 1"
            error stop 1
        end if

        ! ! Here, result becomes
        ! ! Now that I've thought about this, it's also clear
        ! ! that we will only use functions
        ! ! or subroutines with a result type that has `intent(out)`.
        ! ! We will no longer have subroutines that return nothing
        ! ! (like this one currently does).
        ! res = ResultNone()

    end subroutine check_index_claimed

    subroutine ensure_instance_array_size_is_at_least(n)
        !! Ensure that `instance_array` and `instance_available` have at least `n` slots

        integer, intent(in) :: n

        type(ErrorV), dimension(:), allocatable :: tmp_instances
        logical, dimension(:), allocatable :: tmp_available

        if (.not. allocated(instance_array)) then

            allocate (instance_array(n))

            allocate (instance_available(n))
            ! Race conditions ?
            instance_available = .true.

        else if (size(instance_available) < n) then

            allocate (tmp_instances(n))
            tmp_instances(1:size(instance_array)) = instance_array
            call move_alloc(tmp_instances, instance_array)

            allocate (tmp_available(n))
            tmp_available(1:size(instance_available)) = instance_available
            tmp_available(size(instance_available) + 1:size(tmp_available)) = .true.
            call move_alloc(tmp_available, instance_available)

        end if

    end subroutine ensure_instance_array_size_is_at_least

end module m_error_v_manager
