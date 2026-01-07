module m_result_manager

  use kind_parameters, only: dp,i8
  use m_error_v, only: ErrorV
  use m_error_v_manager, only: error_v_manager_build_instance => build_instance
  use m_result_gen, only: ResultGen, T_CLAIM, T_NONE, T_INT, T_DP, T_ERR

  implicit none
  private

  type(ResultGen), allocatable, dimension(:) :: instance_array

  public :: build_instance, finalise_instance,&
            set_instance_index_to, get_available_instance_index, get_instance, probe_instance,&
            force_claim_instance_index, check_index_claimed, &
            ensure_array_capacity_for_instances, deallocate_instance_array

contains

  subroutine build_instance(tag, data_int, data_dp, error_v, instance_index, res_check)

    integer, intent(in) :: tag
    integer(kind=i8), optional, intent(in) :: data_int
    real(kind=dp), optional, intent(in) :: data_dp
    type(ErrorV), optional, intent(in) :: error_v

    integer, intent(out) :: instance_index
    type(ResultGen),optional, intent(out) :: res_check
    integer :: cause

    call ensure_array_capacity_for_instances(1)

    call get_available_instance_index(instance_index,res_check)

    if (res_check % is_error()) then
        !Already hit an error, quick return
        return
    end if

    ! CHECK whether the instance_array(instance_index) % tag = T_CLAIM ?
    call instance_array(instance_index) % &
                  build(tag=tag,data_int=data_int,data_dp=data_dp,&
                        error_v=error_v,res=res_check)

    if (.not. res_check % is_error()) then
        ! All happy
        return
    end if
    !
    ! Error occured
    !
    ! Free the slot again
    !
    call instance_array(instance_index) % build(tag=T_NONE)

    ! Bubble the error up.
    ! This is a good example of where stacking errors would be nice.
    ! It would be great to be able to say,
    ! "We got an instance index,
    ! but when we tried to build the instance,
    ! the following error occured...".
    ! (Stacking error messages like this
    ! would even let us do stack traces in a way...)
    ! res_check = ResultGen(tag=T_ERR,error_v = ErrorV(code=1, message=("Build error : "), cause=res_check%error_v))

    ! MZ here we build an instance into the ErrorV instance array and we return the correspondant index
    cause = error_v_manager_build_instance(code = res_check % error_v % code, message = res_check % error_v % message)

    call instance_array(instance_index) % &
            build(tag=T_ERR, error_v = ErrorV(code=1, message=("Build Instance error : "), cause=cause))

  end subroutine build_instance

  function finalise_instance(instance_index) result(state_index)
      !! Finalise an instance

      integer, intent(in) :: instance_index
      !! Index of the instance to finalise

      type(ResultGen) :: res_check
      integer :: cause, state_index

      res_check = check_index_claimed(instance_index)

      ! MZ how do we handle unsuccefull finalisation?
      if((res_check%is_error()) .and. (&
          res_check%error_v%code /= 33)) then

          cause = error_v_manager_build_instance(code = res_check % error_v % code, &
                                                message = res_check % error_v % message)

          call build_instance (tag = T_ERR,&
                               error_v = ErrorV(code=1,message="Finalise Instance error : ",cause=cause),&
                               instance_index = state_index, &
                               res_check=res_check &
                              )

          return

      end if

      state_index = 0
      call instance_array(instance_index) % finalise()

  end function finalise_instance

  subroutine set_instance_index_to(instance_index, data_int, data_dp, error_v, res_check)

    integer, intent(in) :: instance_index
    integer(kind=i8),optional, intent(in) :: data_int
    real(kind=dp),optional, intent(in) :: data_dp
    type(ErrorV),optional, intent(in) :: error_v

    type(ResultGen), intent(out) :: res_check

    integer :: input_check

    input_check = merge(1,0,present(data_int)) + merge(1,0,present(data_dp)) + merge(1,0,present(error_v))

    if (input_check == 0) then

      call res_check % build (tag = T_ERR,&
                          error_v = ErrorV(code=1,message="Setting instance ERROR: Empty Input"))

    else if (input_check > 1) then

      call res_check % build (tag = T_ERR,&
                          error_v = ErrorV(code=1,message="Setting instance ERROR: Multiple Input"))

    else

      if(present(data_int)) then
        call instance_array(instance_index) % build (tag = T_INT,data_int=data_int)
      else if(present(data_dp)) then
        call instance_array(instance_index) % build (tag = T_DP,data_dp=data_dp)
      else if(present(error_v)) then
        call instance_array(instance_index) % build (tag = T_ERR,error_v = error_v)
      end if

    end if

  end subroutine set_instance_index_to

! ---------------- Getters ---------------------
  function probe_instance(instance_index) result(res_instance_index)

    integer, intent(in) :: instance_index
    type(ResultGen) :: res_check_index_claimed,res_check
    integer :: errorv_instance_index
    integer :: res_instance_index

    res_check_index_claimed = check_index_claimed(instance_index)

    if(res_check_index_claimed % tag /= T_CLAIM) then

      errorv_instance_index = error_v_manager_build_instance (res_check_index_claimed%error_v% code,&
                                                              res_check_index_claimed%error_v% message)

      call build_instance (tag = T_ERR,&
              error_v = ErrorV(code=1,message="Probe instance ERROR: ",cause=errorv_instance_index),&
              instance_index = res_instance_index, &
              res_check=res_check &
      )

      ! if (.not. res_check % is_error()) then
      return
      ! end if

    end if

    res_instance_index = 0

  end function probe_instance

  function get_instance(instance_index) result(res_gen)

    integer, intent(in) :: instance_index
    type(ResultGen) :: res_gen

    res_gen = instance_array(instance_index)

  end function get_instance

  ! pure subroutine get_available_instance_index(available_instance_index,res_check)
  subroutine get_available_instance_index(available_instance_index,res_check)
      !! Get a free instance index

      ! TODO: think through whether race conditions are possible
      ! e.g. while returning a free index number to one Python call
      ! a different one can be looking up a free instance index at the same time
      ! and something goes wrong (maybe we need a lock)
      type(ResultGen), intent(out), optional :: res_check
      integer, intent(out) :: available_instance_index
      !! Available instance index
      character(len=:), allocatable :: msg
      character(len=20) :: str_size_array
      integer :: i

      if(allocated(instance_array)) then
          do i = 1, size(instance_array)

              if (instance_array(i)%tag == 0) then
                  !MZ: check the tag, is it very slow?
                  !MZ: design choice -> getting an index sets its availabilty(?) (similar to malloc)
                  instance_array(i)%tag = T_CLAIM
                  available_instance_index = i
                  return

              end if

          end do

          write(str_size_array, "(I0)") size(instance_array)
          msg = "FULL ARRAY: None of the " // trim(adjustl(str_size_array)) // " slots is available"

      else
          msg = "instance_array NOT allocated"
      end if

      available_instance_index = -1
      call res_check % build(tag=T_ERR, &
           error_v=ErrorV( &
               code=1, &
               message=msg &
           ) &
       )

  end subroutine get_available_instance_index

! ---------------- Array management ---------------------

  ! pure function check_index_claimed(instance_index) result(res_check_index_claimed)
  function check_index_claimed(instance_index) result(res_check_index_claimed)
      !! Check that an index has already been claimed

      integer, intent(in) :: instance_index
      !! Instance index to check
      type(ResultGen) :: res_check_index_claimed
      character(len=20) :: idx_str
      character(len=:), allocatable :: msg

      if (.not. allocated(instance_array)) then

          msg = "instance array in NOT allocated"
          call res_check_index_claimed % build(tag=T_ERR,error_v=ErrorV(code=3, message=msg))
          return

      end if

      write(idx_str, "(I0)") instance_index

      if (instance_index < 1 .or. instance_index > size(instance_array)) then
          msg = "Requested index is: " // trim(adjustl(idx_str)) // " ==> out of boundary"
          call res_check_index_claimed % build(tag=T_ERR,error_v=ErrorV(code=3, message=msg))

          return
      end if

      if (instance_array(instance_index)%tag==T_NONE) then

          msg = "Index " // trim(adjustl(idx_str)) // " has not been claimed"
          call res_check_index_claimed % build(tag=T_ERR,error_v=ErrorV(code=33, message=msg))
          return

      end if

      call res_check_index_claimed % build(tag=T_CLAIM)

  end function check_index_claimed

  subroutine ensure_array_capacity_for_instances(n)
      !! Ensure that `instance_array` has at least `n` slots

      integer, intent(in) :: n

      type(ResultGen), dimension(:), allocatable :: tmp_instances
      integer :: free_count

      if (.not. allocated(instance_array)) then

          allocate (instance_array(n))

      else if (size(instance_array) < n) then
        ! MZ: in this case we just add n spaces on top

          allocate(tmp_instances(n+size(instance_array)))
          tmp_instances(1:size(instance_array)) = instance_array
          call move_alloc(tmp_instances, instance_array)

      else

        free_count = count(instance_array%tag == 0)

        if (free_count < n) then
          ! MZ: doubling the size might be more efficient in the long run??
          allocate (tmp_instances(size(instance_array)*2))
          tmp_instances(1:size(instance_array)) = instance_array
          call move_alloc(tmp_instances, instance_array)
        end if

      end if

  end subroutine ensure_array_capacity_for_instances

  subroutine force_claim_instance_index(instance_index)
      !! Ensure that `instance_array` has at least `n` slots

      integer, intent(in) :: instance_index

      instance_array(instance_index)%tag = T_CLAIM

  end subroutine force_claim_instance_index

  subroutine deallocate_instance_array()

    if (allocated (instance_array))then
      deallocate(instance_array)
    end if

  end subroutine deallocate_instance_array

end module m_result_manager
