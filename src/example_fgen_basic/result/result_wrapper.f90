module m_result_w

  ! use kind_parameters, only: dp, i8
  use m_error_v, only: ErrorV
  use m_result_gen, only: ResultGen, T_CLAIM, T_NONE, T_INT, T_DP, T_ERR

  ! The manager module, which makes this all work
  use m_error_v_manager, only: &
      error_v_manager_get_instance => get_instance, &
      error_v_manager_ensure_instance_array_size_is_at_least => ensure_instance_array_size_is_at_least, &
      error_v_manager_get_available_instance_index => get_available_instance_index, &
      error_v_manager_set_instance_index_to => set_instance_index_to

  use m_result_manager, only: &
      result_manager_build_instance => build_instance, &
      result_manager_finalise_instance => finalise_instance, &
      result_manager_get_instance => get_instance, &
      result_manager_ensure_instance_array_size_is_at_least => ensure_instance_array_size_is_at_least, &
      result_manager_force_claim_instance_index => force_claim_instance_index, &
      result_manager_set_instance_index_to => set_instance_index_to, &
      result_manager_check_index_claimed => check_index_claimed

  implicit none
  private

  public :: build_instance_int, build_instance_dp, build_instance_err,&
            get_instance_tag, get_data_int, get_data_dp, &
            finalise_instance, finalise_instances

contains

! ---------------- Setters/builders ---------------------
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

  function build_instance_err(error_v_instance_index) result(instance_index)

    integer, intent(in) :: error_v_instance_index

    integer :: instance_index

    type(ErrorV) :: error_v
    type(ResultGen) :: res_check

    if (error_v_instance_index > 0) then

      error_v = error_v_manager_get_instance(error_v_instance_index)

      ! Setting Result with error
      call result_manager_build_instance(&
        tag = T_ERR, &
        error_v = error_v, &
        instance_index= instance_index,&
        res_check = res_check &
        )

    else

      ! maybe generate an error
      print *, "Provided code does NOT match any ERROR type"

    end if

    if (res_check % is_error()) then
      ! FAILED build
      !
      ! Could not allocate a result type to handle the return to Python.
      !
      call escape_hatch(instance_index)

    end if

  end function build_instance_err

! ---------------- Getters ---------------------
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

    if(res_stored % tag /= T_INT) then
      ! ERROR in a smarter way
      print *, "TAG type does not match the expected type"
      return
    end if

    data_int = res_stored % data_int

  end function get_data_int

  function get_data_dp(instance_index) result(data_dp)

    integer, parameter :: dp = selected_real_kind(15, 307)
    integer, intent(in) :: instance_index
    real(kind=dp) :: data_dp

    type(ResultGen) :: res_stored

    res_stored = result_manager_get_instance(instance_index)

    ! Think if it is worth checking
    if(res_stored % tag /= T_DP) then
      ! ERROR in a smarter way
      print *, "TAG type does not match the expected type"
      return
    end if

    data_dp = res_stored% data_dp

  end function get_data_dp

  ! NOT entirely sure of what should happen here: discuss with Zeb
  subroutine get_error(instance_index,code,message)

    integer, intent(in) :: instance_index
    integer, intent(out) :: code
    character(len=*), intent(out) :: message
    type(ResultGen) :: res_stored

    res_stored = result_manager_get_instance(instance_index)

    ! Think if it is worth checking
    if(res_stored % tag /= T_ERR) then
      ! ERROR in a smarter way
      print *, "TAG type does not match the expected type"
      return
    end if

    code = res_stored % error_v % code
    message = res_stored % error_v % message

  end subroutine get_error

! ---------------- Destructor ---------------------
  subroutine finalise_instance(instance_index)
      !! Finalise an instance

      integer, intent(in) :: instance_index
      !! Instance index
      !
      ! This is the major trick for wrapping.
      ! We pass instance indexes (integers) to Python rather than the instance itself.

      call result_manager_finalise_instance(instance_index)

  end subroutine finalise_instance

  subroutine finalise_instances(instance_indexes)
      !! Finalise an instance

      integer, dimension(:), intent(in) :: instance_indexes
      !! Instance indexes to finalise
      integer :: i

      do i = 1, size(instance_indexes)
          call result_manager_finalise_instance(instance_indexes(i))
      end do

  end subroutine finalise_instances

! ---------------- Auxiliar ---------------------
  subroutine escape_hatch(instance_index)

    integer, intent(out) :: instance_index

    type(ResultGen) :: res_check

    ! Logic here is trickier.
    ! If you can't create a result type to return to Python,
    ! then you also can't return errors so you're stuck.
    ! As an escape hatch
    call result_manager_ensure_instance_array_size_is_at_least(1)
    instance_index = 1

    ! Just use the first instance and write a message that the program
    ! is fully broken.
    res_check = ResultGen(tag=T_ERR,&
        error_v = ErrorV( &
            code=1, &
            message=( &
                "I wanted to return an error, " &
                // "but I couldn't even get an available instance to do so. " &
                // "I have forced a return, but your program is probably fully broken. " &
                // "Please be very careful." &
            ) &
        ) &
    )

    call result_manager_force_claim_instance_index(instance_index)
    call result_manager_set_instance_index_to(instance_index=instance_index,res_check=res_check)

  end subroutine escape_hatch

end module m_result_w
