!> Result value
!>
!> Inspired by the excellent, MIT licensed
!> https://github.com/samharrison7/fortran-error-handler
module m_result

    use m_error_v, only: ErrorV, NO_ERROR_CODE

    implicit none (type, external)
    private

    type, abstract, public :: Result
    !! Result type
    !!
    !! Holds either the result or an error.

        ! class(*), allocatable :: data_v(..)
        ! MZ: assumed rank can only be dummy argument NOT type/class argument
        ! Data i.e. the result (if no error occurs)
        !
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
        procedure, public :: is_error
        procedure, public :: clean_up

    end type Result

    !  interface Result
    !! Constructor interface - see build (TODO: figure out cross-ref syntax) for details
    !    module procedure :: constructor
    ! end interface Result

contains

    subroutine clean_up(self)
        !! Finalise the instance (i.e. free/deallocate)

        class(Result), intent(inout) :: self
        ! Hopefully can leave without docstring (like Python)

        deallocate (self % error_v)

    end subroutine clean_up

    pure function is_error(self) result(is_err)
        !! Determine whether `self` contains an error or not

        class(Result), intent(in) :: self
        ! Hopefully can leave without docstring (like Python)

        logical :: is_err
        ! Whether `self` is an error or not

        is_err = allocated(self % error_v)

    end function is_error

end module m_result
