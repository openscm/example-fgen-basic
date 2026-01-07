module m_result_w

  ! use kind_parameters, only: dp, i8
  use m_error_v, only: ErrorV
  use m_result_gen, only: ResultGen, T_CLAIM, T_NONE, T_INT, T_DP, T_ERR

  ! The manager module, which makes this all work
  use m_error_v_manager, only: &
      error_v_manager_get_instance => get_instance, &
      error_v_manager_get_available_instance_index => get_available_instance_index, &
      error_v_manager_get_error_message => get_error_message, &
      error_v_manager_set_instance_index_to => set_instance_index_to, &
      error_v_manager_deallocate_instance_arrays => deallocate_instance_arrays

  use m_result_manager, only: &
      result_manager_build_instance => build_instance, &
      result_manager_finalise_instance => finalise_instance, &
      result_manager_get_instance => get_instance, &
      result_manager_probe_instance => probe_instance, &
      result_manager_ensure_array_capacity_for_instances => ensure_array_capacity_for_instances, &
      result_manager_force_claim_instance_index => force_claim_instance_index, &
      result_manager_set_instance_index_to => set_instance_index_to, &
      result_manager_check_index_claimed => check_index_claimed, &
      result_manager_deallocate_instance_array => deallocate_instance_array

  implicit none
  private

  public :: build_instance_int, build_instance_dp, build_instance_err,&
            finalise_instance, finalise_instances, free_resources,&
            get_instance_tag, get_data_int, get_data_dp, get_error, &
            probe_instance

  integer, parameter, public :: s_claimed=T_CLAIM, s_none=T_NONE, s_int=T_INT, s_dp=T_DP, s_err=T_ERR

contains

! ---------------- Builders ---------------------
  function build_instance_int(data_int) result(instance_index)

    integer, parameter :: i8 = selected_int_kind(18)
    integer(kind=i8), intent(in) :: data_int

    integer :: instance_index

    type(ResultGen) :: res_check

    ! Setting Result with data
    call result_manager_build_instance(&
      tag = T_INT, &
      data_int = data_int, &
      instance_index= instance_index,&
      res_check = res_check &
    )

    if (res_check % is_error()) then
      ! FAILED build
      !
      ! Could not allocate a result type to handle the return to Python.
      !
      call escape_hatch(instance_index)

    end if

  end function build_instance_int

  function build_instance_dp(data_dp) result(instance_index)

    integer, parameter :: dp = selected_real_kind(15, 307)
    real(kind=dp), intent(in) :: data_dp

    integer :: instance_index

    type(ResultGen) :: res_check

    ! Setting Result with data
    call result_manager_build_instance(&
      tag = T_DP, &
      data_dp = data_dp, &
      instance_index= instance_index,&
      res_check = res_check &
    )

    if (res_check % is_error()) then
      ! FAILED build
      !
      ! Could not allocate a result type to handle the return to Python.
      !
      call escape_hatch(instance_index)

    end if

  end function build_instance_dp

  function build_instance_err(code,message) result(instance_index)

    integer, intent(in) :: code
    character(len=*), intent(in) :: message

    integer :: instance_index

    type(ErrorV) :: error_v
    type(ResultGen) :: res_check
    if (code > 0) then

!      error_v = error_v_manager_get_instance(error_v_instance_index)
      call error_v % build(code=code, message=message)

      ! Setting Result with error
      call result_manager_build_instance(&
        tag = T_ERR, &
        error_v = error_v, &
        instance_index= instance_index,&
        res_check = res_check &
        )

    else

      call error_v % build(code = 1, message = "Provided code does NOT match any ERROR type")
      call result_manager_build_instance(&
        tag = T_ERR, &
        error_v = error_v, &
        instance_index= instance_index,&
        res_check = res_check &
        )

    end if

    if (res_check % is_error() .and. instance_index==-1) then
      ! FAILED build
      !
      ! Could not allocate a result type to handle the return to Python.
      !
      call escape_hatch(instance_index)

    end if

  end function build_instance_err

! ---------------- Getters ---------------------
  function probe_instance(instance_index) result(state_index)

    integer, intent(in) :: instance_index
    integer :: state_index

    state_index = result_manager_probe_instance(instance_index)

  end function probe_instance

  ! pure function get_instance_tag(instance_index) result(tag)
  function get_instance_tag(instance_index) result(tag)

    integer, intent(in) :: instance_index
    integer :: tag

    type(ResultGen) :: res_stored

    res_stored = result_manager_get_instance(instance_index)

    tag = res_stored % tag

  end function get_instance_tag

  function get_data_int(instance_index) result(data_int)

    integer, parameter :: i8 = selected_int_kind(18)
    integer, intent(in) :: instance_index
    integer(kind=i8) :: data_int

    type(ResultGen) :: res_stored

    res_stored = result_manager_get_instance(instance_index)

    data_int = res_stored % data_int

  end function get_data_int

  function get_data_dp(instance_index) result(data_dp)

    integer, parameter :: dp = selected_real_kind(15, 307)
    integer, intent(in) :: instance_index
    real(kind=dp) :: data_dp

    type(ResultGen) :: res_stored

    res_stored = result_manager_get_instance(instance_index)

    data_dp = res_stored % data_dp

  end function get_data_dp

  ! NOT entirely sure of what should happen here: discuss with Zeb
  subroutine get_error(instance_index,code,message)

    integer, intent(in) :: instance_index
    integer, intent(out) :: code
    ! MZ: How to avoid long fixed length??
    character(len=1000), intent(out) :: message
    character(len=10) :: int2char
    type(ResultGen) :: res_stored

    res_stored = result_manager_get_instance(instance_index)

    ! Think if it is worth checking as the Python side should already deal with it. Should be built an error?
    if(res_stored % tag /= T_ERR) then
      ! ERROR in a smarter way?
      code = 1
      write(int2char,"(I0)") instance_index
      message = "TAG mismatch! Expected -> ERROR but index: " // adjustl(trim(int2char))
      write(int2char,"(I0)") res_stored % tag
      message = adjustl(trim(message)) // " has TAG = " // adjustl(trim(int2char))
      return
    end if

    code = res_stored % error_v % code
    message = error_v_manager_get_error_message(res_stored%error_v)

  end subroutine get_error

! ---------------- Destructor ---------------------
  function finalise_instance(instance_index) result(state_index)
      !! Finalise an instance

      integer, intent(in) :: instance_index
      !! Instance index
      !
      integer :: state_index
      ! This is the major trick for wrapping.
      ! We pass instance indexes (integers) to Python rather than the instance itself.

      state_index = result_manager_finalise_instance(instance_index)

  end function finalise_instance

  function finalise_instances(instance_indexes) result(state_index)
      !! Finalise an instance

      integer, dimension(:), intent(in) :: instance_indexes
      !! Instance indexes to finalise
      integer :: i, state_index

      finalise_loop: do i = 1, size(instance_indexes)
          state_index = result_manager_finalise_instance(instance_indexes(i))
          if (state_index /= 0) exit finalise_loop
      end do finalise_loop

  end function finalise_instances

  subroutine free_resources()
    call result_manager_deallocate_instance_array()
    call error_v_manager_deallocate_instance_arrays()
  end subroutine free_resources

! ---------------- Auxiliar ---------------------
  subroutine escape_hatch(instance_index)

    integer, intent(out) :: instance_index

    type(ErrorV) :: error_v
    type(ResultGen) :: res_check

    ! Logic here is trickier.
    ! If you can't create a result type to return to Python,
    ! then you also can't return errors so you're stuck.
    ! As an escape hatch
    call result_manager_ensure_array_capacity_for_instances(1)
    instance_index = 1

    ! Just use the first instance and write a message that the program
    ! is fully broken.
    error_v = ErrorV( &
                     code=1, &
                     message=( &
                             "I wanted to return an error, " &
                          // "but I couldn't even get an available instance to do so. " &
                          // "I have forced a return, but your program is probably fully broken. " &
                          // "Please be very careful." &
                     ) &
              )

    call result_manager_force_claim_instance_index(instance_index)
    call result_manager_set_instance_index_to(instance_index=instance_index,error_v=error_v,res_check=res_check)

  end subroutine escape_hatch

end module m_result_w
