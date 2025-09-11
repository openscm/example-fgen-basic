!> Result value for integers
!>
!> Inspired by the excellent, MIT licensed
!> https://github.com/samharrison7/fortran-error-handler
module m_result_int

    use m_error_v, only: ErrorV
    use m_result, only: Result_base

    implicit none (type, external)
    private

    type, extends(Result_base), public :: ResultInteger0D
    !! Result type that holds integer values
    !!
    !! Holds either an integer value or an error.

        integer, allocatable :: data_v
        !! Data i.e. the result (if no error occurs)

        ! class(ErrorV), allocatable :: error_v
        !! Error

    contains

        private

        procedure, public :: build
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

        type(ResultInteger0D) :: self
        ! Hopefully can leave without docstring (like Python)

        class(ErrorV), intent(inout), optional :: error_v
        !! Error message

        integer, intent(in), optional :: data_v
        !! Data

        call self % build(data_v_in=data_v, error_v_in=error_v)

    end function constructor

    function build(data_v_in, error_v_in) result(res)
        !! Build instance

        class(Result_base), intent(out) :: res
        ! Hopefully can leave without docstring (like Python)

        integer, intent(in), optional :: data_v_in
        !! Data

        class(ErrorV), intent(inout), optional :: error_v_in
        !! Error message

        if (present(data_v_in) .and. present(error_v_in)) then
            allocate(Result_base :: res)
            res % error_v % message = "Both data and error were provided"
        else if (present(data_v_in)) then
            allocate (ResultInteger0D :: res)
            allocate (self % data_v, source=data_v_in)
            ! No error - no need to call res % build
        else if (present(error_v_in)) then
            allocate(Result_base :: res)
            allocate (res % error_v, source=error_v_in)
            ! No error - no need to call res % build
        else
            allocate(Result_base :: res)
            res % error_v % message = "Neither data nor error were provided"
        end if

    end function build

    subroutine finalise(self)
      !! Finalise instance

        type(ResultInteger0D), intent(inout) :: self
        ! Hopefully can leave without docstring (like Python)

        if (allocated(self % data_v)) deallocate (self % data_v)
        call self % clean_up()

    end subroutine finalise

end module m_result_int
