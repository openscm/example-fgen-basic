!> Manager of `ErrorV` (TODO: xref) across the Fortran-Python interface
!>
!> Written by hand here.
!> Generation to be automated in future (including docstrings of some sort).
module m_error_v_manager

    use m_error_v, only: ErrorV, NO_ERROR_CODE

    implicit none
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
        type(ErrorV) :: err_check_index_claimed

        err_check_index_claimed = check_index_claimed(instance_index)

        ! MZ how do we handle unsuccefull finalisation?
        if(err_check_index_claimed% code /= 0) return

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
    function get_instance(instance_index) result(err_inst)

        integer, intent(in) :: instance_index
        !! Index in `instance_array` of which to set the value equal to `val`

        type(ErrorV) :: err_inst
        !! Instance at `instance_array(instance_index)`

        type(ErrorV) :: err_check_index_claimed
        character(len=20) :: idx_str
        character(len=:), allocatable :: msg

        err_check_index_claimed = check_index_claimed(instance_index)

        if (err_check_index_claimed % code == 0) then

            err_inst = instance_array(instance_index)

        else
            write(idx_str, "(I0)") instance_index
            msg = "Error at get_instance -> " // trim(adjustl(idx_str))

            err_inst = ErrorV( &
                    code= err_check_index_claimed%code,&
                    message = msg, &
                    cause = err_check_index_claimed &
                    )
        end if

    end function get_instance

    function set_instance_index_to(instance_index, val) result(err)

        integer, intent(in) :: instance_index
        !! Index in `instance_array` of which to set the value equal to `val`

        type(ErrorV), intent(in) :: val
        type(ErrorV) :: err

        type(ErrorV) :: err_check_index_claimed
        character(len=:), allocatable :: msg

        err_check_index_claimed = check_index_claimed(instance_index)

        if(err_check_index_claimed%code /= NO_ERROR_CODE) then
            ! MZ: here we do not set if the index has not been claimed.
            ! Must be harmonised with Results type
            msg ="Setting Instance Error: "
            err = ErrorV ( &
                    code = err_check_index_claimed% code, &
                    message = msg, &
                    cause = err_check_index_claimed &
                    )

        else
            !MZ: When there's no error the index is claimed and the value is updated/overwritten(?)
            !Manually finalising before updating
            !Fortran intrinsic assignment does free allocatables automatically.
            ! But calling finalise(): guarantees immediate release, handles non-allocatable resources,
            ! avoids temporary double memory
            call instance_array(instance_index)%finalise()

            ! Reassigning the slot
            call instance_array(instance_index)%build(code=val%code, message=val%message, cause=val%cause)

            err = ErrorV(code=NO_ERROR_CODE)

        end if

    end function set_instance_index_to

    function check_index_claimed(instance_index) result(err_check_index_claimed)
        !! Check that an index has already been claimed
        !!
        !! Stops execution if the index has not been claimed.

        integer, intent(in) :: instance_index
        !! Instance index to check
        type(ErrorV) :: err_check_index_claimed
        character(len=20) :: idx_str
        character(len=:), allocatable :: msg


        if (.not. allocated(instance_available)) then

            msg = "instance_available in NOT allocated"
            err_check_index_claimed = ErrorV(code=3, message=msg)

            return
        end if

        write(idx_str, "(I0)") instance_index

        if (instance_available(instance_index)) then
            ! TODO: Switch to using Result here
            ! Use `ResultNone` which is a Result type
            ! that doesn't have a `data` attribute
            ! (i.e. if this succeeds, there is no data to check,
            ! if it fails, the result_dp attribute will be set).
            ! So the code would be something like
            ! res = ResultNone(ResultDP(code=1, message="Index ", instance_index, " has not been claimed"))
            ! print *, "Index ", instance_index, " has not been claimed"
            ! error stop 1
            msg = "Index " // trim(adjustl(idx_str)) // " has not been claimed"

            err_check_index_claimed = ErrorV(code=1, message=msg)

            return
        end if

        if (instance_index < 1 .or. instance_index > size(instance_array)) then
            ! TODO: Switch to using Result here
            ! Use `ResultNone` which is a Result type
            ! that doesn't have a `data` attribute
            ! (i.e. if this succeeds, there is no data to check,
            ! if it fails, the result_dp attribute will be set).
            ! So the code would be something like
            ! res = ResultNone(ResultDP(code=2, message="Requested index is ", instance_index, " which is less than 1"))
            ! print *, "Requested index is ", instance_index, " which is less than 1"
            ! error stop 1
            msg = "Requested index is: " // trim(adjustl(idx_str)) // " ==> out of boundary"
            err_check_index_claimed = ErrorV(code=2, message=msg)

            return
        end if

        err_check_index_claimed = ErrorV(code=NO_ERROR_CODE)

    end function check_index_claimed

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
