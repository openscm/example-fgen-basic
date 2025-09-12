!> Helpers for derived type managers
module fpyfgen_derived_type_manager_helpers

    use fpyfgen_base_finalisable, only: BaseFinalisable, invalid_instance_index

    implicit none(type, external)
    private

    public :: get_derived_type_free_instance_number, &
              finalise_derived_type_instance_number

contains

    subroutine get_derived_type_free_instance_number(instance_index, n_instances, instance_avail, instance_array)
        !! Get the next available instance number
        !!
        !! If successful, `instance_index` will contain a positive value.
        !! If no available instances are found,
        !! instance_index will be set to `invalid_instance_index`.
        !! TODO: change the above to return a Result type instead

        integer, intent(out) :: instance_index
        !! Free index
        !!
        !! If no available instances are found, set to `invalid_instance_index`.

        integer, intent(in) :: n_instances
        !! Size of `instance_avail`

        logical, dimension(n_instances), intent(inout) :: instance_avail
        !! Array that indicates whether each index is available or not

        class(BaseFinalisable), dimension(n_instances), intent(inout) :: instance_array
        !! Array of instances

        integer :: i

        ! Default if no available models are found
        instance_index = invalid_instance_index

        do i = 1, n_instances

            if (instance_avail(i)) then

                instance_avail(i) = .false.
                instance_array(i) % instance_index = i
                instance_index = i
                return

            end if

        end do

        ! Should be an error or similar here

    end subroutine get_derived_type_free_instance_number

    subroutine finalise_derived_type_instance_number(instance_index, n_instances, instance_avail, instance_array)
        !! Finalise the derived type with the given instance index

        integer, intent(in) :: instance_index
        !! Index of the instance to finalise

        integer, intent(in) :: n_instances
        !! Size of `instance_avail`

        logical, dimension(n_instances), intent(inout) :: instance_avail
        !! Array that indicates whether each index is available or not

        class(BaseFinalisable), dimension(n_instances), intent(inout) :: instance_array
        !! Array of instances

        call instance_array(instance_index) % finalise()
        instance_array(instance_index) % instance_index = invalid_instance_index
        instance_avail(instance_index) = .true.

    end subroutine finalise_derived_type_instance_number

end module fpyfgen_derived_type_manager_helpers
