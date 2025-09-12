!> Get square root of a number
module m_get_square_root

    use kind_parameters, only: dp
    use m_error_v, only: ErrorV
    use m_result_dp, only: ResultDP

    implicit none(type, external)
    private

    public :: get_square_root

contains

    function get_square_root(inv) result(res)
        !! Get square root of a number

        real(kind=dp), intent(in) :: inv
        !! Frequency

        type(ResultDP) :: res
        !! Result
        !!
        !! Square root if the number is positive or zero.
        !! Error otherwise.

        if (inv >= 0) then
            res = ResultDP(data_v=sqrt(inv))
        else
            ! TODO: include input value in the message
            res = ResultDP(error_v=ErrorV(code=1, message="Input value was negative"))
        end if

    end function get_square_root

end module m_get_square_root
