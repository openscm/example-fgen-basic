!> Wrapper for interfacing `m_get_square_root` with python
module m_get_square_root_w

    use m_result_dp, only: ResultDP
    use m_get_square_root, only: o_get_square_root => get_square_root

    ! The manager module, which makes this all work
    use m_result_dp_manager, only: &
        result_dp_manager_get_available_instance_index => get_available_instance_index, &
        result_dp_manager_set_instance_index_to => set_instance_index_to, &
        result_dp_manager_ensure_instance_array_size_is_at_least => ensure_instance_array_size_is_at_least

    implicit none(type, external)
    private

    public :: get_square_root

contains

    function get_square_root(inv) result(res_instance_index)

        ! Annoying that this has to be injected everywhere,
        ! but ok it can be automated.
        integer, parameter :: dp = selected_real_kind(15, 307)

        real(kind=dp), intent(in) :: inv
        !! inv

        integer :: res_instance_index
        !! Instance index of the result type

        type(ResultDP) :: res

        res = o_get_square_root(inv)

        call result_dp_manager_ensure_instance_array_size_is_at_least(1)

        ! Get the instance index to return to Python
        call result_dp_manager_get_available_instance_index(res_instance_index)

        ! Set the derived type value in the manager's array,
        ! ready for its attributes to be retrieved from Python.
        call result_dp_manager_set_instance_index_to(res_instance_index, res)

    end function get_square_root

end module m_get_square_root_w
