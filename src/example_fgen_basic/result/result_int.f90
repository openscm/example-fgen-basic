!> Result type for integers
!>
!> Inspired by the excellent, MIT licensed
!> https://github.com/samharrison7/fortran-error-handler
module m_result_int

    use kind_parameters, only: i8
    use m_error_v, only: ErrorV
    use m_result, only: ResultBase
    use m_result_none, only: ResultNone

    implicit none (type, external)
    private

    type, extends(ResultBase), public :: ResultInt
    !! Result type that holds integer values

        integer(kind=i8), allocatable :: data_v
        !! Data i.e. the result (if no error occurs)

        ! Note: the error_v attribute comes from ResultBase

    contains

        private

        procedure, public :: build
        procedure, public :: finalise
        final :: finalise_auto

    end type ResultInt

    interface ResultInt
    !! Constructor interface - see build [TODO: x-ref] for details
        module procedure :: constructor
    end interface ResultInt

contains

    function constructor(data_v, error_v) result(self)
        !! Build instance

        type(ResultInt) :: self
        ! Hopefully can leave without docstring (like Python)

        integer(kind=i8), intent(in), optional :: data_v
        !! Data

        class(ErrorV), intent(in), optional :: error_v
        !! Error

        type(ResultNone) :: build_res

        call self % build(data_v_in=data_v, error_v_in=error_v, res= build_res)

        if (build_res % is_error()) then

            ! This interface has to return the initialised object,
            ! it cannot return a Result type,
            ! so we have no choice but to raise a fatal error here.
            print *, build_res % error_v % message
            error stop build_res % error_v % code

        ! else
            ! Assume no error occurred and initialisation was fine

        end if

    end function constructor

    subroutine build(self, data_v_in, error_v_in, res)
        !! Build instance

        integer(kind=i8), intent(in), optional :: data_v_in
        !! Data

        class(ErrorV), intent(in), optional :: error_v_in
        !! Error message

        class(ResultInt), intent(inout) :: self
        ! Hopefully can leave without docstring (like Python)

        type(ResultNone), intent(inout) :: res
        !! Result

        if (present(data_v_in) .and. present(error_v_in)) then
            res % error_v % message = "Both data and error were provided"

        else if (present(data_v_in)) then
            allocate (self % data_v, source=data_v_in)
            ! No error - no need to call res % build

        else if (present(error_v_in)) then
            allocate (self % error_v, source=error_v_in)
            ! No error - no need to call res % build

        else
            res % error_v % message = "Neither data nor error were provided"

        end if

    end subroutine build

    subroutine finalise(self)
        !! Finalise the instance (i.e. free/deallocate)

        class(ResultInt), intent(inout) :: self
        ! Hopefully can leave without docstring (like Python)

        if (allocated(self % data_v)) deallocate (self % data_v)
        if (allocated(self % error_v)) deallocate(self % error_v)

    end subroutine finalise

    subroutine finalise_auto(self)
        !! Finalise the instance (i.e. free/deallocate)
        !!
        !! This method is expected to be called automatically
        !! by clever clean up, which is why it differs from [TODO x-ref] `finalise`

        type(ResultInt), intent(inout) :: self
        ! Hopefully can leave without docstring (like Python)

        call self % finalise()

    end subroutine finalise_auto

end module m_result_int
