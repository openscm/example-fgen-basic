!> *Error passing*
!>
!> A very basic demo to get the idea.
!
module m_error_v_passing

    use m_error_v, only: ErrorV, NO_ERROR_CODE

    implicit none(type, external)
    private

    public :: pass_error, pass_errors

contains

    function pass_error(inv) result(is_err)
        !! Pass an error
        !!
        !! If an error is supplied, we return `.true.`, otherwise `.false.`.

        type(ErrorV), intent(in) :: inv
        !! Input error value

        logical :: is_err
        !! Whether `inv` is an error or not

        is_err = (inv % code /= NO_ERROR_CODE)

    end function pass_error

    function pass_errors(invs, n) result(is_errs)
        !! Pass a number of errors
        !!
        !! For each value in `invs`, if an error is supplied, we return `.true.`, otherwise `.false.`.

        type(ErrorV), dimension(n), intent(in) :: invs
        !! Input error values

        integer, intent(in) :: n
        !! Number of values being passed

        logical, dimension(n) :: is_errs
        !! Whether each value in `invs` is an error or not

        integer :: i

        do i = 1, n

            is_errs(i) = pass_error(invs(i))

        end do

    end function pass_errors

end module m_error_v_passing
