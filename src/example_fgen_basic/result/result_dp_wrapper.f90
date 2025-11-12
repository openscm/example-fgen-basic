!> Wrapper for interfacing `m_result_dp` with Python
module m_result_dp_w

    use m_error_v, only: ErrorV, NO_ERROR_CODE
    use m_result_dp, only: ResultDP
    use m_result_int, only: ResultInt
    use m_result_none, only: ResultNone

    ! The manager module, which makes this all work
    use m_error_v_manager, only: &
        error_v_manager_get_instance => get_instance, &
        error_v_manager_ensure_instance_array_size_is_at_least => ensure_instance_array_size_is_at_least, &
        error_v_manager_get_available_instance_index => get_available_instance_index, &
        error_v_manager_set_instance_index_to => set_instance_index_to

    use m_result_dp_manager, only: &
        result_dp_manager_build_instance => build_instance, &
        result_dp_manager_finalise_instance => finalise_instance, &
        result_dp_manager_get_instance => get_instance, &
        result_dp_manager_ensure_instance_array_size_is_at_least => ensure_instance_array_size_is_at_least

    use m_result_int_manager, only: &
        result_int_manager_force_claim_instance_index => force_claim_instance_index, &
        result_int_manager_get_available_instance_index => get_available_instance_index, &
        result_int_manager_ensure_instance_array_size_is_at_least => ensure_instance_array_size_is_at_least, &
        result_int_manager_set_instance_index_to => set_instance_index_to

    implicit none
    private

    public :: build_instance, finalise_instance, finalise_instances, &
              ensure_at_least_n_instances_can_be_passed_simultaneously, &
              data_v_is_set, get_data_v, error_v_is_set, get_error_v

   ! Annoying that this has to be injected everywhere,
   ! but ok it can be automated.
   integer, parameter :: dp = selected_real_kind(15, 307)
   integer, parameter :: i4 = selected_int_kind(9)

contains

!    subroutine build_instance(data_v, error_v_instance_index, res_build_instance_index)
    !f2py needs extra work when dealing with subroutines. SEE notes
    function build_instance(data_v, error_v_instance_index) result(res_build_instance_index)
        !! Build an instance
        integer, parameter :: dp = selected_real_kind(15, 307)
        real(kind=dp), intent(in) :: data_v
        !! Data

        integer, intent(in) :: error_v_instance_index
        !! Error

        integer :: res_build_instance_index
        !! Instance index of the built instance
        !
        ! This is the major trick for wrapping.
        ! We pass instance indexes (integers) to Python rather than the instance itself.

        type(ResultInt) :: res_build

        ! This is the major trick for wrapping derived types with other derived types as attributes.
        ! We use the manager layer to initialise the attributes before passing on.
        type(ErrorV) :: error_v

        ! MZ: do we want some error code convention?
        if (error_v_instance_index > 0) then

            error_v = error_v_manager_get_instance(error_v_instance_index)

            ! Setting ResultDP with error
            call result_dp_manager_build_instance(&
              error_v_in = error_v, &
              instance_index=res_build &
            )

        else
            ! Setting ResultDP with data
            ! res_build contains the index
            call result_dp_manager_build_instance(&
              data_v_in = data_v, &
              instance_index=res_build &
            )
        end if

        if (.not. res_build % is_error()) then

            ! Could allocate a result type to handle the return to Python.
            ! Returning the instance index
            res_build_instance_index = int(res_build % data_v, kind=i4)
            return

        end if

        ! Could not allocate a result type to handle the return to Python.
        !
        ! Logic here is trickier.
        ! If you can't create a result type to return to Python,
        ! then you also can't return errors so you're stuck.
        ! As an escape hatch
        ! MZ: Not sure whether result_int_manager is appropriate here
        call result_int_manager_ensure_instance_array_size_is_at_least(1)
        res_build_instance_index = 1

        ! Just use the first instance and write a message that the program
        ! is fully broken.
        res_build = ResultInt( &
            error_v = ErrorV( &
                code=1, &
                message=( &
                    "I wanted to return an error, " &
                    // "but I couldn't even get an available instance to do so. " &
                    // "I have forced a return, but your program is probably fully broken. " &
                    // "Please be very careful." &
                ) &
            ) &
        )

        call result_int_manager_force_claim_instance_index(res_build_instance_index)
        call result_int_manager_set_instance_index_to(res_build_instance_index, res_build)

    end function build_instance

    ! build_instances is very hard to do
    ! because you need to pass an array of variable-length characters which is non-trivial.
    ! Maybe we will try this another day, for now this isn't that important
    ! (we can just use a loop from the Python side)
    ! so we just don't bother implementing `build_instances`.

    subroutine finalise_instance(instance_index)
        !! Finalise an instance

        integer, intent(in) :: instance_index
        !! Instance index
        !
        ! This is the major trick for wrapping.
        ! We pass instance indexes (integers) to Python rather than the instance itself.

        call result_dp_manager_finalise_instance(instance_index)

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
            call result_dp_manager_finalise_instance(instance_indexes(i))
        end do

    end subroutine finalise_instances

    subroutine ensure_at_least_n_instances_can_be_passed_simultaneously(n)
        !! Ensure that at least `n` instances of `ResultDP` can be passed via the manager simultaneously

        integer, intent(in) :: n

        call result_dp_manager_ensure_instance_array_size_is_at_least(n)

    end subroutine ensure_at_least_n_instances_can_be_passed_simultaneously

    ! Full set of wrapping strategies to get/pass different types in e.g.
    ! https://gitlab.com/magicc/fgen/-/blob/switch-to-uv/tests/test-data/exposed_attrs/src/exposed_attrs/exposed_attrs_wrapped.f90
    ! (we will do a full re-write of the code which generates this,
    ! but the strategies will probably stay as they are)

    ! For optional stuff, need to be able to check whether they're set or not
    function data_v_is_set(instance_index) result(res)

        integer, intent(in) :: instance_index

        logical :: res

        type(ResultDP)  :: instance

        instance = result_dp_manager_get_instance(instance_index)
        res = allocated(instance % data_v)

    end function data_v_is_set

    function get_data_v(instance_index) result(data_v)

        integer, intent(in) :: instance_index

        real(kind=dp) :: data_v

        type(ResultDP)  :: instance

        instance = result_dp_manager_get_instance(instance_index)

        data_v = instance % data_v

    end function get_data_v

    subroutine error_v_is_set( &
        instance_index, &
        res &
        )

        integer, intent(in) :: instance_index

        logical, intent(out) :: res

        type(ResultDP)  :: instance

        instance = result_dp_manager_get_instance(instance_index)
        res = allocated(instance % error_v)

    end subroutine error_v_is_set

    subroutine get_error_v( &
        instance_index, &
        error_v_instance_index &
        )

        integer, intent(in) :: instance_index

        ! trick: return instance index, not the instance.
        ! Build on the python side
        integer, intent(out) :: error_v_instance_index

        type(ResultDP)  :: instance
        type(ErrorV)  :: error_v, err

        instance = result_dp_manager_get_instance(instance_index)

        error_v = instance % error_v

        call error_v_manager_ensure_instance_array_size_is_at_least(1)
        call error_v_manager_get_available_instance_index(error_v_instance_index)

        err = error_v_manager_set_instance_index_to(error_v_instance_index, error_v)
        !MZ: check for errors ?
    end subroutine get_error_v

end module m_result_dp_w
