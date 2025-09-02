!> Result value
!>
!> Inspired by the excellent, MIT licensed
!> https://github.com/samharrison7/fortran-error-handler
module m_result

    use m_error_v, only: ErrorV

    implicit none
    private

    type, abstract, public :: Result
    !! Result type
    !!
    !! Holds either the result or an error.

        class(*), allocatable :: data_v(..)
        !! Data i.e. the result (if no error occurs)
        !!
        ! Assumed rank array
        ! (https://fortran-lang.discourse.group/t/assumed-rank-arrays/1049)
        ! Technically a Fortran 2018 feature,
        ! so maybe we need to update our file extensions.
        ! If we can't use this, just comment this out
        ! and leave each subclass of Result to set its data type
        ! (e.g. ResultInteger will have `integer :: data`,
        ! ResultDP1D will have `real(dp), dimension(:), allocatable :: data`)

        class(ErrorV), allocatable :: error_v
        !! Error

    contains

        private

        ! procedure, public:: build
        ! TODO: Think about whether build should be on the abstract class
        ! or just on each concrete implementation
        procedure, public:: finalise, is_error

    end type Result

    interface Result
    !! Constructor interface - see build (TODO: figure out cross-ref syntax) for details
        module procedure :: constructor
    end interface Result

contains

    ! See above about whether we include this here or not
    ! Build should return a Result with an error if we try to set/allocate both
    ! data and error
    ! subroutine build(self, code, message)
    !     !! Build instance
    !
    !     class(ErrorV), intent(inout) :: self
    !     ! Hopefully can leave without docstring (like Python)
    !
    !     integer, intent(in) :: code
    !     !! Error code
    !     !!
    !     !! Use [TODO: figure out xref] `NO_ERROR_CODE` if there is no error
    !
    !     character(len=*), optional, intent(in) :: message
    !     !! Error message
    !
    !     self % code = code
    !     if (present(message)) then
    !         self % message = message
    !     end if
    !
    ! end subroutine build

    function finalise(self) result(res)
        !! Finalise the instance (i.e. free/deallocate)

        class(Result), intent(inout) :: self
        ! Hopefully can leave without docstring (like Python)

!        type(ResultNone) :: res

        res = Result()

        if (allocated(self % data_v) .and. allocated(self % error_v)) then
            deallocate(self % data_v)
            deallocate(self % error_v)
            call res % build(message="Both data and error were allocated")

        elseif (allocated(self % data_v)) then
            deallocate(self % data_v)
            ! No error - no need to call res % build

        elseif (allocated(self % error_v)) then
            deallocate(self % error_v)
            ! No error - no need to call res % build

        else
            call res % build(message="Neither data nor error was allocated")

        end if

    end function finalise

    pure function is_error(self) result(is_err)
        !! Determine whether `self` contains an error or not

        class(Result), intent(in) :: self
        ! Hopefully can leave without docstring (like Python)

        logical :: is_err
        ! Whether `self` is an error or not

        is_err = allocated(self % error_v)

    end function is_error

end module m_result
