!> Error value
!>
!> Inspired by the excellent, MIT licensed
!> https://github.com/samharrison7/fortran-error-handler
!>
!> Fortran doesn't have a null value.
!> As a result, we introduce this derived type
!> with the convention that a code of `NO_ERROR_CODE` (0)
!> indicates no error (i.e. is our equivalent of a null value).
module m_error_v

    implicit none
    private

    integer, parameter, public :: NO_ERROR_CODE = 0
    !! Code that indicates no error

    type, public :: ErrorV
    !! Error value

        integer :: code = 1
        !! Error code

        character(len=128) :: message = ""
        !! Error message
        ! TODO: think about making the message allocatable to handle long messages

        ! TODO: think about adding idea of critical
        ! (means you can stop but also unwind errors and traceback along the way)

        ! TODO: think about adding trace (might be simpler than compiling with traceback)
        ! type(ErrorV), allocatable, dimension(:) :: causes

    contains

        private

        procedure, public:: build, finalise
        ! get_res sort of not needed (?)
        ! get_err sort of not needed (?)

    end type ErrorV

    interface ErrorV
    !! Constructor interface - see build (TODO: figure out cross-ref syntax) for details
        module procedure :: constructor
    end interface ErrorV

contains

    function constructor(code, message) result(self)
        !! Constructor - see build (TODO: figure out cross-ref syntax) for details

        integer, intent(in) :: code
        character(len=*), optional, intent(in) :: message

        type(ErrorV) :: self

        call self % build(code, message)

    end function constructor

    subroutine build(self, code, message)
        !! Build instance

        class(ErrorV), intent(inout) :: self
        ! Hopefully can leave without docstring (like Python)

        integer, intent(in) :: code
        !! Error code
        !!
        !! Use [TODO: figure out xref] `NO_ERROR_CODE` if there is no error

        character(len=*), optional, intent(in) :: message
        !! Error message

        self % code = code
        if (present(message)) then
            self % message = message
        end if

    end subroutine build

    subroutine finalise(self)
        !! Finalise the instance (i.e. free/deallocate)

        class(ErrorV), intent(inout) :: self
        ! Hopefully can leave without docstring (like Python)

        ! If we make message allocatable, deallocate here
        self % code = 1
        self % message = ""

    end subroutine finalise

end module m_error_v
