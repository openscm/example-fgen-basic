!> Wrapper for interfacing `m_error_v_passing` with Python
!>
!> Written by hand here.
!> Generation to be automated in future (including docstrings of some sort).
module m_error_v_passing_w

    ! => allows us to rename on import to avoid clashes
    ! "o_" for original (TODO: better naming convention)
    use m_error_v_passing, only: &
        o_pass_error => pass_error, &
        o_pass_errors => pass_errors
    use m_error_v, only: ErrorV

    ! The manager module, which makes this all work
    use m_error_v_manager, only: &
        error_v_manager_get_instance => get_instance
    !     error_v_manager_get_available_instance_index => get_available_instance_index, &
    !     error_v_manager_set_instance_index_to => set_instance_index_to, &
    !     error_v_manager_ensure_instance_array_size_is_at_least => ensure_instance_array_size_is_at_least

    implicit none(type, external)
    private

    public :: pass_error, pass_errors

contains

    function pass_error(inv_instance_index) result(res)
        !> Wrapper around `m_error_v_passing.pass_error` [[m_error_v_passing(module):pass_error(function)]].

        integer, intent(in) :: inv_instance_index
        !! Input values
        !> See docstring of [[m_error_v_passing(module):pass_error(function)]] for details.

        !! The trick here is to pass in the instance index, not the instance itself

        logical :: res
        !! Whether the instance referred to by `inv_instance_index` is an error or not

        type(ErrorV) :: instance

        instance = error_v_manager_get_instance(inv_instance_index)

        ! Do the Fortran call
        res = o_pass_error(instance)

    end function pass_error

    function pass_errors(inv_instance_indexes, n) result(res)
        !> Wrapper around `m_error_v_passing.pass_error` [[m_error_v_passing(module):pass_errors(function)]].

        integer, dimension(n), intent(in) :: inv_instance_indexes
        !! Input values
        !!
        !! See docstring of [[m_error_v_passing(module):pass_errors(function)]] for details.

        integer, intent(in) :: n
        !! Number of values to pass

        logical, dimension(n) :: res
        !! Whether each instance in the array backed by `inv_instance_indexes` is an error or not
        !
        ! This is the major trick for wrapping.
        ! We pass instance indexes (integers) from Python rather than the instance itself.

        type(ErrorV), dimension(n) :: instances

        integer :: i

        do i = 1, n
            instances(i) = error_v_manager_get_instance(inv_instance_indexes(i))
        end do

        ! Do the Fortran call
        res = o_pass_errors(instances, n)

    end function pass_errors

end module m_error_v_passing_w
