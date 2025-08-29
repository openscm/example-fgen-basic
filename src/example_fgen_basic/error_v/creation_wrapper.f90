!> Wrapper for interfacing `m_error_v_creation` with Python
!>
!> Written by hand here.
!> Generation to be automated in future (including docstrings of some sort).
module m_error_v_creation_w

    ! => allows us to rename on import to avoid clashes
    ! "o_" for original (TODO: better naming convention)
    use m_error_v_creation, only: o_create_error => create_error
    use m_error_v, only: ErrorV

    ! The manager module, which makes this all work
    use m_error_v_manager, only: &
        error_v_manager_get_available_instance_index => get_available_instance_index, &
        error_v_manager_set_instance_index_to => set_instance_index_to

    implicit none
    private

    public :: create_error

contains

    function create_error(inv) result(res_instance_index)
        !! Wrapper around `m_error_v_creation.create_error` (TODO: x-ref)

        integer, intent(in) :: inv
        !! Input value to use to create the error
        !!
        !! See docstring of `m_error_v_creation.create_error` for details.
        !! [TODO: x-ref]

        integer :: res_instance_index
        !! Instance index of the result
        !
        ! This is the major trick for wrapping.
        ! We return instance indexes (integers) to Python rather than the instance itself.

        type(ErrorV) :: res

        ! Do the Fortran call
        res = o_create_error(inv)

        ! Get the instance index to return to Python
        call error_v_manager_get_available_instance_index(res_instance_index)

        ! Set the derived type value in the manager's array,
        ! ready for its attributes to be retrieved from Python.
        call error_v_manager_set_instance_index_to(res_instance_index, res)

    end function create_error

end module m_error_v_creation_w
