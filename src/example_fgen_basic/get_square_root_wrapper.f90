!> Wrapper for interfacing `m_get_square_root` with python
module m_get_square_root_w

    use m_result_gen, only: ResultGen,T_ERR

    use m_get_square_root, only: o_get_square_root => get_square_root

    ! The manager module, which makes this all work
    use m_result_manager, only: &
        result_manager_get_available_instance_index => get_available_instance_index, &
        result_manager_set_instance_index_to => set_instance_index_to, &
        result_manager_ensure_instance_array_size_is_at_least => ensure_instance_array_size_is_at_least

    implicit none
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

        type(ResultGen) :: res
        type(ResultGen) :: res_get_available_instance_index
        type(ResultGen) :: res_chk

        res = o_get_square_root(inv)

        call result_manager_ensure_instance_array_size_is_at_least(1)

        ! Get the instance index to return to Python
        ! res_get_available_instance_index = result_dp_manager_get_available_instance_index()
        call result_manager_get_available_instance_index(res_instance_index,res_chk)

        ! Logic here is trickier.
        ! If you can't create a result type to return to Python,
        ! then you also can't return errors so you're a bit cooked.

        ! Set the derived type value in the manager's array,
        ! ready for its attributes to be retrieved from Python.
        ! MZ it would be probably good to check "res_chk" for errors
        ! res_chk = result_dp_manager_set_instance_index_to(res_instance_index, res)
        if (res%tag == T_ERR) then
            call result_manager_set_instance_index_to(instance_index=res_instance_index,&
                 error_v=res%error_v, res_check = res_chk)
            return
        end if

        call result_manager_set_instance_index_to(instance_index=res_instance_index,&
                 data_dp=res%data_dp, res_check = res_chk)

        ! res_instance_index = int(res_get_available_instance_index % data_v, kind = 4)

    end function get_square_root

end module m_get_square_root_w
