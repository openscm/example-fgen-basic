!> Wrapper for interfacing `m_error_v_creation` with Python
!>
!> Written by hand here.
!> Generation to be automated in future (including docstrings of some sort).
module m_error_v_creation_w

    ! => allows us to rename on import to avoid clashes
    ! "o_" for original (TODO: better naming convention)
    use m_error_v_creation, only: &
        o_create_error => create_error, &
        o_create_errors => create_errors
    use m_error_v, only: ErrorV

    ! The manager module, which makes this all work
    use m_error_v_manager, only: &
        error_v_manager_get_available_instance_index => get_available_instance_index, &
        error_v_manager_set_instance_index_to => set_instance_index_to, &
        error_v_manager_ensure_instance_array_size_is_at_least => ensure_instance_array_size_is_at_least

    implicit none
    private

    public :: create_error, create_errors

contains

    function create_error(inv) result(res_instance_index)
        !> Wrapper around `m_error_v_creation.create_error` ([[m_error_v_creation(module):create_error(function)]])

        integer, intent(in) :: inv
        !> Input value to use to create the error
        !>
        !> See docstring of [[m_error_v_creation(module):create_error(function)]] for details.

        integer :: res_instance_index
        !! Instance index of the result
        !
        ! This is the major trick for wrapping.
        ! We return instance indexes (integers) to Python rather than the instance itself.

        type(ErrorV) :: res

        ! Do the Fortran call
        res = o_create_error(inv)

        call error_v_manager_ensure_instance_array_size_is_at_least(1)

        ! Get the instance index to return to Python
        call error_v_manager_get_available_instance_index(res_instance_index)

        ! Set the derived type value in the manager's array,
        ! ready for its attributes to be retrieved from Python.
        call error_v_manager_set_instance_index_to(res_instance_index, res)

    end function create_error

    function create_errors(invs, n) result(res_instance_indexes)
        !> Wrapper around `m_error_v_creation.create_errors` ([[m_error_v_creation(module):create_errors(function)]])

        integer, dimension(n), intent(in) :: invs
        !! Input value to use to create the error
        !!
        !> See docstring of [[m_error_v_creation(module):create_errors(function)]] for details.

        integer, intent(in) :: n
        !! Number of values to create

        integer, dimension(n) :: res_instance_indexes
        !! Instance indexes of the result
        !
        ! This is the major trick for wrapping.
        ! We return instance indexes (integers) to Python rather than the instance itself.

        type(ErrorV), dimension(n) :: res

        integer :: i, tmp

        ! Lots of ways resizing could work.
        ! Optimising could be very tricky.
        ! Just do something stupid for now to see the pattern.
        call error_v_manager_ensure_instance_array_size_is_at_least(n)

        ! Do the Fortran call
        res = o_create_errors(invs, n)

        do i = 1, n

            ! Get the instance index to return to Python
            call error_v_manager_get_available_instance_index(tmp)
            ! Set the derived type value in the manager's array,
            ! ready for its attributes to be retrieved from Python.
            call error_v_manager_set_instance_index_to(tmp, res(i))
            ! Set the result in the output array
            res_instance_indexes(i) = tmp

        end do

    end function create_errors

end module m_error_v_creation_w
