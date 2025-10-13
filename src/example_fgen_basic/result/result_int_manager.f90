!> Manager of `ResultInt` (TODO: xref) across the Fortran-Python interface
module m_result_int_manager

    use kind_parameters, only: i8
    use m_error_v, only: ErrorV
    use m_result_int, only: ResultInt
    use m_result_none, only: ResultNone

    implicit none
    private

    type(ResultInt), dimension(:), allocatable :: instance_array
    logical, dimension(:), allocatable :: instance_available

    ! TODO: think about ordering here, alphabetical probably easiest
    public :: build_instance, finalise_instance, &
              get_available_instance_index, force_claim_instance_index, &
              get_instance, set_instance_index_to, &
              ensure_instance_array_size_is_at_least

contains

    function build_instance(data_v_in, error_v_in) result(res_instance_index)
        !! Build an instance

        integer(kind=i8), intent(in), optional :: data_v_in
        !! Data

        class(ErrorV), intent(in), optional :: error_v_in
        !! Error message

        type(ResultInt) :: res_instance_index
        !! Result i.e. index of the built instance (within a result type)

        type(ResultNone) :: res_build

        call ensure_instance_array_size_is_at_least(1)
        ! ! TODO: switch to
        ! instance_index = get_available_instance_index()
        call get_available_instance_index(res_instance_index)

        if (res_instance_index % is_error()) then
            ! Already hit an error, quick return
            return
        end if

        call instance_array(res_instance_index%data_v) % build( &
            data_v_in=data_v_in, error_v_in=error_v_in, res=res_build &
        )

        if (.not. (res_build % is_error())) then
            ! All happy
            return
        end if

        ! Error occured
        !
        ! Free the slot again
        instance_available(res_instance_index % data_v) = .true.

        ! Bubble the error up.
        ! This is a good example of where stacking errors would be nice.
        ! It would be great to be able to say,
        ! "We got an instance index,
        ! but when we tried to build the instance,
        ! the following error occured...".
        ! (Stacking error messages like this
        ! would even let us do stack traces in a way...)
        res_instance_index = ResultInt(error_v=res_build%error_v)

    end function build_instance

    subroutine finalise_instance(instance_index)
        !! Finalise an instance

        integer, intent(in) :: instance_index
        !! Index of the instance to finalise

        call check_index_claimed(instance_index)

        call instance_array(instance_index) % finalise()
        instance_available(instance_index) = .true.

    end subroutine finalise_instance

    subroutine get_available_instance_index(res_available_instance_index)
        !! Get a free instance index

        ! TODO: think through whether race conditions are possible
        ! e.g. while returning a free index number to one Python call
        ! a different one can be looking up a free instance index at the same time
        ! and something goes wrong (maybe we need a lock)
        ! MZ: I think this is of order O(N) that for large arrays can be very slow
        ! maybe use something like linked lists?? /

        type(ResultInt), intent(out) :: res_available_instance_index
        !! Available instance index

        integer :: i

        if (.not. allocated(instance_array)) then

            res_available_instance_index = ResultInt( &
                error_v=ErrorV( &
                    code=1, &
                    message="instance_array has not been allocated yet" &
                ) &
            )
            return

        end if

        do i = 1, size(instance_array)

            if (instance_available(i)) then

                instance_available(i) = .false.
                res_available_instance_index = ResultInt(data_v=i)
                return

            end if

        end do

        res_available_instance_index = ResultInt( &
            error_v=ErrorV( &
                code=1, &
                message="No available instances" &
                ! TODO: add total number of instances to the error message
                ! as that is useful information when debugging
                ! (requires a int_to_str function first)
            ) &
        )

    end subroutine get_available_instance_index

    subroutine force_claim_instance_index(instance_index)

        integer, intent(in) :: instance_index
        !! Instnace index of which to force claim
        !!
        !! Whether it has already been claimed or not,
        !! the instance at this index will be set as being claimed.

        instance_available(instance_index) = .false.

    end subroutine force_claim_instance_index

    ! Change to pure function when we update check_index_claimed to be pure
    function get_instance(instance_index) result(inst)

        integer, intent(in) :: instance_index
        !! Index in `instance_array` of which to set the value equal to `val`

        type(ResultInt) :: inst
        !! Instance at `instance_array(instance_index)`

        call check_index_claimed(instance_index)
        inst = instance_array(instance_index)

    end function get_instance

    subroutine set_instance_index_to(instance_index, val, check_claimed)

        integer, intent(in) :: instance_index
        !! Index in `instance_array` of which to set the value equal to `val`

        type(ResultInt), intent(in) :: val

        logical, intent(in), optional :: check_claimed

        logical :: a_check_claimed

        if (present(check_claimed)) then
            a_check_claimed = check_claimed
        else
            a_check_claimed = .true.
        end if

        if (a_check_claimed) then
            call check_index_claimed(instance_index)
        end if

        instance_array(instance_index) = val
        ! MZ: Shouldn't be instance_available be set to .false.?

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
            ! if it fails, the result_dp attribute will be set).
            ! So the code would be something like
            ! res = ResultNone(ResultInt(code=1, message="Index ", instance_index, " has not been claimed"))
            print *, "Index ", instance_index, " has not been claimed"
            error stop 1
        end if

        if (instance_index < 1) then
            ! TODO: Switch to using Result here
            ! Use `ResultNone` which is a Result type
            ! that doesn't have a `data` attribute
            ! (i.e. if this succeeds, there is no data to check,
            ! if it fails, the result_dp attribute will be set).
            ! So the code would be something like
            ! res = ResultNone(ResultInt(code=2, message="Requested index is ", instance_index, " which is less than 1"))
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
        ! MZ: shouldn't this check the available slots as well?
        integer, intent(in) :: n

        type(ResultInt), dimension(:), allocatable :: tmp_instances
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

end module m_result_int_manager
