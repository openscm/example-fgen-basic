!> Get square root of a number
module m_get_square_root

    use kind_parameters, only: dp
    use m_error_v, only: ErrorV
    use m_result_gen, only: ResultGen, T_DP, T_ERR

    implicit none
    private

    public :: get_square_root

contains

    function get_square_root(inv) result(res)
        !! Get square root of a number

        real(kind=dp), intent(in) :: inv
        !! Frequency

        type(ResultGen) :: res
        !! Result
        !!
        !! Square root if the number is positive or zero.
        !! Error otherwise.

        if (inv >= 0) then
            res = ResultGen(tag=T_DP,data_dp=sqrt(inv))
        else
            ! TODO: include input value in the message
            res = ResultGen(tag=T_ERR,error_v=ErrorV(code=1, message="Input value was negative"))
        end if

    end function get_square_root

end module m_get_square_root
