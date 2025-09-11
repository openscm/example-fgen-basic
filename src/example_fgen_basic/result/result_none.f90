!> Result value where no data is carried around
!>
!> Inspired by the excellent, MIT licensed
!> https://github.com/samharrison7/fortran-error-handler
module m_result_none

    use m_error_v, only: ErrorV
    use m_result, only: ResultBase

    implicit none (type, external)
    private

    type, extends(ResultBase), public :: ResultNone
    !! Result type that cannot hold data

    contains

        private

        procedure, public :: build
        procedure, public :: finalise
        final :: finalise_auto

    end type ResultNone

    interface ResultNone
       module procedure :: constructor
    end interface ResultNone

contains

    function constructor(error_v) result(self)
        !! Build instance

        type(ResultNone) :: self
        ! Hopefully can leave without docstring (like Python)

        class(ErrorV), intent(in), optional :: error_v
        !! Error message

        call self % build(error_v_in=error_v)

    end function constructor

    subroutine build(self, error_v_in)
        !! Build instance

        class(ResultNone), intent(inout) :: self
        ! Hopefully can leave without docstring (like Python)

        class(ErrorV), intent(in), optional :: error_v_in
        !! Error message

        if (present(error_v_in)) then
            allocate (self % error_v, source=error_v_in)
            ! No error - no need to call res % build

        ! else
            !     ! Special case - users can initialise ResultNone without an error if they want
        !     res % error_v % message = "No error was provided"

        end if

    end subroutine build

    subroutine finalise(self)
        !! Finalise the instance (i.e. free/deallocate)

        class(ResultNone), intent(inout) :: self
        ! Hopefully can leave without docstring (like Python)

        if (allocated(self % error_v)) deallocate(self % error_v)

    end subroutine finalise

    subroutine finalise_auto(self)
        !! Finalise the instance (i.e. free/deallocate)
        !!
        !! This method is expected to be called automatically
        !! by clever clean up, which is why it differs from [TODO x-ref] `finalise`

        type(ResultNone), intent(inout) :: self
        ! Hopefully can leave without docstring (like Python)

        call self % finalise()

    end subroutine finalise_auto

end module m_result_none
