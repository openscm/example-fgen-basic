!> Result value for integers
!>
!> Inspired by the excellent, MIT licensed
!> https://github.com/samharrison7/fortran-error-handler
module m_result_int

    use m_error_v, only: ErrorV
    use m_result, only: Result

    implicit none
    private

    type, extends(Result), public :: ResultInteger0D
    !! Result type that holds integer values
    !!
    !! Holds either an integer value or an error.

        integer, allocatable :: data_v
        !! Data i.e. the result (if no error occurs)

       ! class(ErrorV), allocatable :: error_v
        !! Error

    contains

        private

        procedure, public:: build
        ! `finalise` and `is_error` come from abstract base class
        final :: finalise

    end type ResultInteger0D

    interface ResultInteger0D
    !! Constructor interface - see build (TODO: figure out cross-ref syntax) for details
        module procedure :: constructor
    end interface ResultInteger0D

contains

    function constructor(data_v, error_v) result(self)
        !! Build instance

        type(ResultInteger0D), intent(inout) :: self
        ! Hopefully can leave without docstring (like Python)

        class(ErrorV), intent(in) :: error_v
        !! Error message

        integer, optional, intent(in) :: data_v
        !! Data

        call self%build(data_v=data_v, error_v=error_v)

    end function constructor

    subroutine build(self, data_v, error_v)
        !! Build instance

        type(ResultInteger0D), intent(inout) :: self
        ! Hopefully can leave without docstring (like Python)

        integer, optional, intent(in) :: data_v
        !! Data

        class(ErrorV), optional, intent(in) :: error_v
        !! Error message

        if (present(data_v) .and. present(error_v)) then
            call self % build(message="Both data and error were provided")
        elseif (present(data_v)) then
            allocate(self % data_v, source=data_v)
            ! No error - no need to call res % build
        elseif (present(error_v)) then
            allocate(self % error_v, source=error_v)
            ! No error - no need to call res % build
        else
            call self % build(message="Neither data nor error were provided")
        end if

    end subroutine build

end module m_result_int
