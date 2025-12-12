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

        character(len=:), allocatable :: message

        !! Error message
        ! TODO: think about making the message allocatable to handle long messages

        ! TODO: think about adding idea of critical
        ! (means you can stop but also unwind errors and traceback along the way)

        ! TODO: think about adding trace (might be simpler than compiling with traceback)
!        class(ErrorV), allocatable :: cause
         type(ErrorV), pointer :: cause => null()

    contains

        private

        procedure, public :: build
        procedure, public :: finalise
!        procedure, public :: get_error_message
        final :: finalise_auto
        ! get_res sort of not needed (?)
        ! get_err sort of not needed (?)

    end type ErrorV

    interface ErrorV
        !! Constructor interface - see build (TODO: figure out cross-ref syntax) for details
        module procedure :: constructor
    end interface ErrorV

contains

!    pure recursive function get_error_message(self) result(full_msg)
!
!        class(ErrorV), target, intent(in) :: self
!
!        character(len=:), allocatable :: full_msg
!        character(len=:), allocatable :: cause_msg
!
!        full_msg = self%message
!        if (associated(self%cause)) then
!            cause_msg = self%cause%get_error_message()
!            full_msg = trim(full_msg) // ' Previous error: ' // trim(cause_msg)
!        end if
!
!    end function
!        function get_error_message(self) result(full_msg)
!
!            class(ErrorV), target, intent(in) :: self
!            class(ErrorV), pointer :: p_errorv
!
!            character(len=:), allocatable :: full_msg
!
!            full_msg = ""
!
!            if (allocated(self%message)) full_msg = trim(self%message)
!            p_errorv => self
!
!            do while (associated(p_errorv))
!
!                if(len(full_msg)>0)then
!                    full_msg = trim(full_msg) // " --> Cause: " // p_errorv % message
!                else
!                    full_msg = p_errorv % message
!                end if
!
!                p_errorv => p_errorv % cause
!
!            end do
!
!        end function

    function constructor(code, message, cause) result(self)
        !! Constructor - see build (TODO: figure out cross-ref syntax) for details

        integer, intent(in) :: code
        character(len=*), optional, intent(in) :: message
        type(ErrorV), target, optional, intent(in) :: cause

        type(ErrorV) :: self

        call self % build(code, message, cause)

    end function constructor

    subroutine build(self, code, message, cause)
        !! Build instance

        class(ErrorV), intent(out) :: self
        ! Hopefully can leave without docstring (like Python)

        integer, intent(in) :: code
        !! Error code
        !!
        !! Use [TODO: figure out xref] `NO_ERROR_CODE` if there is no error

        character(len=*), optional, intent(in) :: message
        !! Error message
        type(ErrorV), target, optional, intent(in) :: cause

        self % code = code

        if (present(cause)) then
!            self % cause => cause
!            allocate(self % cause)
!            call self%cause%build(cause%code, cause%message, cause%cause)
!            self%cause = cause
            if (present(message)) then
                self % message = adjustl(trim(message)) // " --> Cause: " // cause % message
            else
                self % message = " --> Cause: " // cause % message
            end if

        else
            if (present(message)) then
                self % message = adjustl(trim(message))
            end if
        end if

    end subroutine build
!    subroutine build(self, code, message, cause)
!        !! Build instance
!
!        class(ErrorV), intent(out) :: self
!        ! Hopefully can leave without docstring (like Python)
!
!        integer, intent(in) :: code
!        !! Error code
!        !!
!        !! Use [TODO: figure out xref] `NO_ERROR_CODE` if there is no error
!
!        character(len=*), optional, intent(in) :: message
!        !! Error message
!        type(ErrorV), target, optional, intent(in) :: cause
!
!        self % code = code
!
!        if (present(cause)) then
! !            self % cause => cause
! !            allocate(self % cause)
! !            call self%cause%build(cause%code, cause%message, cause%cause)
! !            self%cause = cause
!            if (present(message)) then
!                self % message = adjustl(trim(message)) // " --> Cause: " // cause % message
!            else
!                self % message = " --> Cause: " // cause % message
!            end if
!
!        else
!            if (present(message)) then
!                self % message = adjustl(trim(message))
!            end if
!        end if
!
!    end subroutine build

    subroutine finalise(self)
        !! Finalise the instance (i.e. free/deallocate)

        class(ErrorV), intent(inout) :: self
        ! Hopefully can leave without docstring (like Python)

        ! If we make message allocatable, deallocate here
        self % code = 1
        if (allocated(self%message)) deallocate(self%message)
        ! MZ when the object is finalized or goes out of scope, its pointer components are destroyed.
        ! Hopefully no shared ownership??
         if (associated(self%cause)) nullify(self%cause)
!        if (allocated(self%cause)) deallocate(self%cause)

    end subroutine finalise

    subroutine finalise_auto(self)
        !! Finalise the instance (i.e. free/deallocate)
        !!
        !! This method is expected to be called automatically
        !! by clever clean up, which is why it differs from [TODO x-ref] `finalise`

        type(ErrorV), intent(inout) :: self
        ! Hopefully can leave without docstring (like Python)

        call self % finalise()

    end subroutine finalise_auto

end module m_error_v
