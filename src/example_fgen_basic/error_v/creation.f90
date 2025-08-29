!> Error creation
!>
!> A very basic demo to get the idea.
!
! TODO: discuss - we should probably have some convention for module names.
! The hard part is avoiding them becoming too long...
module m_error_v_creation

    use m_error_v, only: ErrorV, NO_ERROR_CODE

    implicit none
    private

    public :: create_error, create_errors

contains

    function create_error(inv) result(err)
        !! Create an error
        !!
        !! If an odd number is supplied, the error code is no error (TODO: cross-ref).
        !! If an even number is supplied, the error code is 1.
        !! If a negative number is supplied, the error code is 2.

        integer, intent(in) :: inv
        !! Value to use to create the error

        type(ErrorV) :: err
        !! Created error

        if (inv < 0) then
            err = ErrorV(code=2, message="Negative number supplied")
            return
        end if

        if (mod(inv, 2) .eq. 0) then
            err = ErrorV(code=1, message="Even number supplied")
        else
            err = ErrorV(code=NO_ERROR_CODE)
        end if

    end function create_error

    function create_errors(invs, n) result(errs)
        !! Create a number of errors
        !!
        !! If an odd number is supplied, the error code is no error (TODO: cross-ref).
        !! If an even number is supplied, the error code is 1.
        !! If a negative number is supplied, the error code is 2.

        integer, dimension(n), intent(in) :: invs
        !! Values to use to create the error

        integer, intent(in) :: n
        !! Number of values to create

        type(ErrorV), dimension(n) :: errs
        !! Created errors

        integer :: i

        do i = 1, n

            errs(i) = create_error(invs(i))

        end do

    end function create_errors

end module m_error_v_creation
