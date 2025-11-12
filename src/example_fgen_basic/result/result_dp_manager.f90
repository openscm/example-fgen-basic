!> manager of `resultdp` (todo: xref) across the fortran-python interface
module m_result_dp_manager

    use kind_parameters, only: dp
    use m_error_v, only: errorv
    use m_result_dp, only: ResultDP
    use m_result_int, only: ResultInt
    use m_result_none, only: resultnone

    implicit none
    private

    type(ResultDP), dimension(:), allocatable :: instance_array
    logical, dimension(:), allocatable :: instance_available

    ! todo: think about ordering here, alphabetical probably easiest
    public :: build_instance, finalise_instance, get_available_instance_index, get_instance, set_instance_index_to, &
              ensure_instance_array_size_is_at_least

contains

    subroutine build_instance(data_v_in, error_v_in, instance_index)
        !! Build an instance

        real(kind=dp), intent(in), optional :: data_v_in
        !! Data

        class(ErrorV), intent(in), optional :: error_v_in
        !! Error message

        type(ResultInt) , intent(out) :: instance_index
        !! Result i.e. index of the built instance (within a result type)

        type(ResultNone) :: res_build

        call ensure_instance_array_size_is_at_least(1)

        instance_index = get_available_instance_index()

        if (instance_index % is_error()) then
          !Already hit an error, quick return
          return
        end if

        call instance_array(instance_index % data_v) % &
                      build(data_v_in=data_v_in, error_v_in=error_v_in, res=res_build)

        if (.not. res_build % is_error()) then
            ! All happy
            instance_available(instance_index % data_v) = .False.
            return
        end if
        !
        ! Error occured
        !
        ! Free the slot again
        instance_available(instance_index % data_v) = .True.

        ! Bubble the error up.
        ! This is a good example of where stacking errors would be nice.
        ! It would be great to be able to say,
        ! "We got an instance index,
        ! but when we tried to build the instance,
        ! the following error occured...".
        ! (Stacking error messages like this
        ! would even let us do stack traces in a way...)
        instance_index = ResultInt(error_v = ErrorV(code=1, message=("Build error : "), cause=res_build%error_v))
        !            instance_index = ResultInt(error_v=res_build%error_v)

    end subroutine build_instance

    subroutine finalise_instance(instance_index)
        !! Finalise an instance

        integer, intent(in) :: instance_index
        !! Index of the instance to finalise

        type(ResultNone) :: res_check_index_claimed

        res_check_index_claimed = check_index_claimed(instance_index)
        ! MZ how do we handle unsuccefull finalisation?
        if(res_check_index_claimed%is_error()) return

        call instance_array(instance_index) % finalise()
        instance_available(instance_index) = .true.

    end subroutine finalise_instance

    function get_available_instance_index() result (res_available_instance_index)
        !! Get a free instance index

        ! TODO: think through whether race conditions are possible
        ! e.g. while returning a free index number to one Python call
        ! a different one can be looking up a free instance index at the same time
        ! and something goes wrong (maybe we need a lock)
        type(ResultInt) :: res_available_instance_index
        !! Available instance index
        character(len=:), allocatable :: msg
        character(len=20), allocatable :: str_size_array
        integer :: i

        if(allocated(instance_array)) then
            do i = 1, size(instance_array)

                if (instance_available(i)) then
                    !MZ: design choice -> getting an index sets its availabilty(?) (similar to malloc)
                    instance_available(i) = .false.
                    res_available_instance_index = ResultInt(data_v=i)
                    return

                end if

            end do

            write(str_size_array, "(I0)") size(instance_array)
            msg = "FULL ARRAY: None of the " // trim(adjustl(str_size_array)) // " slots is available"

        else
            msg = "instance_array NOT allocated"
        end if

        res_available_instance_index = ResultInt( &
             error_v=ErrorV( &
                 code=1, &
                 message=msg &
             ) &
         )
    end function get_available_instance_index

    ! Change to pure function when we update check_index_claimed to be pure
    function get_instance(instance_index) result(res_inst)

        integer, intent(in) :: instance_index
        !! Index in `instance_array` of which to set the value equal to `val`

        type(ResultDP) :: res_inst
        !! Instance at `instance_array(instance_index)`
        type(ResultNone), target :: res_check_index_claimed
        character(len=20) :: idx_str
        character(len=:), allocatable :: msg

        res_check_index_claimed = check_index_claimed(instance_index)

        if(res_check_index_claimed%is_error()) then

            write(idx_str, "(I0)") instance_index
            msg = "Error at get_instance -> " // trim(adjustl(idx_str))

            res_inst = ResultDP(error_v = ErrorV( &
                    code= res_check_index_claimed%error_v%code,&
                    message = msg, &
                    cause = res_check_index_claimed%error_v &
                    )&
                    )

        else
            res_inst = instance_array(instance_index)
        end if

    end function get_instance

    function set_instance_index_to(instance_index, val) result(res)
        !! Replace/Update slot value(?)
        ! MZ: what to do in case of free slot? It is my understanding that here we want to
        ! set a specific "instance_index" to a specific "val". What should we do when things
        ! go wrong? My idea is to not touch neiter "val" nor "instance_array(instance_index)"
        ! and return an error to be handled on the Python side?

        integer, intent(in) :: instance_index
        !! Index in `instance_array` of which to set the value equal to `val`

        character(len=:), allocatable :: msg

        type(ResultDP), intent(in) :: val
        type(ResultNone) :: res_check_index_claimed, res_build
        type(ResultNone) :: res

        res_check_index_claimed = check_index_claimed(instance_index)

        if(res_check_index_claimed%is_error()) then

            ! if there is an error to be handled
            if(res_check_index_claimed % error_v % code > 1) then
                msg ="Setting Instance Error: "
                res = ResultNone(error_v = ErrorV ( &
                        code = res_check_index_claimed % error_v % code, &
                        message = msg, &
                        cause = res_check_index_claimed% error_v &
                        ) &
                )
                return
            end if

            !MZ: WHAT to do when the index is not claimed?
            ! Building the slot
            call instance_array(instance_index)%build(data_v_in=val%data_v, error_v_in=val%error_v, res=res_build)

            if (res_build%is_error()) then
                msg ="Setting Instance Error: "
                res = ResultNone(error_v = ErrorV ( &
                        code = res_build % error_v % code, &
                        message = msg, &
                        cause = res_build%error_v &
                        ) &
                )
                return
            end if

            res = ResultNone()

        else
            !MZ: When there's no error the index is claimed and the value is updated/overwritten(?)
            !Manually finalising before updating
            !Fortran intrinsic assignment does free allocatables automatically.
            ! But calling finalise(): guarantees immediate release, handles non-allocatable resources,
            ! avoids temporary double memory
            call instance_array(instance_index)%finalise()
            ! Reassigning the slot
            call instance_array(instance_index)%build(data_v_in=val%data_v, error_v_in=val%error_v, res=res_build)

            if (res_build%is_error()) then
                msg ="Setting Instance Error: "
                res = ResultNone(error_v = ErrorV ( &
                        code = res_build % error_v % code, &
                        message = msg, &
                        cause = res_build%error_v &
                        ) &
                )
                return
            end if

            res = ResultNone()

        end if

    end function set_instance_index_to

    function check_index_claimed(instance_index) result(res_check_index_claimed)
        !! Check that an index has already been claimed
        !!
        !! Stops execution if the index has not been claimed.

        integer, intent(in) :: instance_index
        !! Instance index to check
        type(ResultNone) :: res_check_index_claimed
        character(len=20) :: idx_str
        character(len=:), allocatable :: msg

        if (.not. allocated(instance_available)) then

            msg = "instance_available in NOT allocated"
            res_check_index_claimed = ResultNone(error_v=ErrorV(code=3, message=msg))

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

            res_check_index_claimed = ResultNone(error_v=ErrorV(code=1, message=msg))

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
            res_check_index_claimed = ResultNone(error_v=ErrorV(code=2, message=msg))

            return
        end if

        ! ! Here, result becomes
        ! ! Now that I've thought about this, it's also clear
        ! ! that we will only use functions
        ! ! or subroutines with a result type that has `intent(out)`.
        ! ! We will no longer have subroutines that return nothing
        ! ! (like this one currently does).
        ! res = ResultNone()
        res_check_index_claimed = ResultNone()

    end function check_index_claimed

    subroutine ensure_instance_array_size_is_at_least(n)
        !! Ensure that `instance_array` and `instance_available` have at least `n` slots

        integer, intent(in) :: n

        type(ResultDP), dimension(:), allocatable :: tmp_instances
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

end module m_result_dp_manager
