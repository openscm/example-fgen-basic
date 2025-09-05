!> Base class for classes that can be wrapped with pyfgen.
!>
!> Such classes must always be finalisable, to help with memory management
!> across the Python-Fortran interface.
module fpyfgen_base_finalisable

    implicit none
    private

    integer, parameter, public :: INVALID_INSTANCE_INDEX = -1
    !! Value that denotes an invalid model index

    public :: BaseFinalisable

    type, abstract :: BaseFinalisable

        integer :: instance_index = INVALID_INSTANCE_INDEX
        !! Unique identifier for the instance.
        !!
        !! Set to a value > 0 when the instance is in use,
        !! set to `INVALID_INSTANCE_INDEX` (TODO xref) otherwise.
        !! The value is linked to the position in a manager array stored elsewhere.
        !! This value shouldn't be modified from outside the manager
        !! unless you really know what you're doing.

    contains

        private

        procedure(derived_type_finalise), public, deferred :: finalise

    end type BaseFinalisable

    interface

        subroutine derived_type_finalise(self)
            !! Finalise the instance (i.e. free/deallocate)

            import :: BaseFinalisable

            implicit none

            class(BaseFinalisable), intent(inout) :: self

        end subroutine derived_type_finalise

    end interface

end module fpyfgen_base_finalisable
