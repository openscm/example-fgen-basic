!> Result value
!>
!> Inspired by the excellent, MIT licensed
!> https://github.com/samharrison7/fortran-error-handler
module m_result

    use m_error_v, only: ErrorV, NO_ERROR_CODE

    implicit none (type, external)
    private

    type, abstract, public :: ResultBase
    !! Result type
    !!
    !! Holds either the result or an error.

        ! class(*), allocatable :: data_v(..)
        ! assumed rank can only be dummy argument NOT type/class argument
        ! hence leave this undefined
        ! Sub-classes have to define what kind of data value they support

        class(ErrorV), allocatable :: error_v
        !! Error

    contains

        private

        ! Expect sub-classes to implement
        ! procedure, public:: build
        procedure, public :: is_error
        ! Expect sub-classes to implement
        ! procedure, public :: finalise
        ! final :: finalise_auto

    end type ResultBase

    ! Expect sub-classes to implement
    ! interface ResultSubClass
    !! Constructor interface - see build [cross-ref goes here] for details
    !    module procedure :: constructor
    ! end interface ResultSubClass

contains

    pure function is_error(self) result(is_err)
        !! Determine whether `self` contains an error or not

        class(ResultBase), intent(in) :: self
        ! Hopefully can leave without docstring (like Python)

        logical :: is_err
        ! Whether `self` is an error or not

        is_err = allocated(self % error_v)

    end function is_error

end module m_result
