module m_result_gen

  use kind_parameters, only: dp,i8
  use m_error_v, only: ErrorV

  implicit none
  private

  integer, parameter, public :: T_NONE = 0, T_CLAIM = -1, &
                        T_INT = 1, T_DP = 2, T_ERR = 3

  type, public :: ResultGen

    integer :: tag = T_NONE
    class(ErrorV), allocatable :: error_v

    integer(kind=i8) :: data_int
    real(kind=dp) :: data_dp
  contains
    procedure :: is_free => is_none
    procedure :: is_error
    procedure :: is_int
    procedure :: is_dp
    procedure :: build
    procedure :: finalise
    final     :: finalise_auto
  end type ResultGen

  interface ResultGen
    module procedure :: constructor
  end interface

contains
! ------------------ Constructor -------------------------
  function constructor(tag,data_int,data_dp,error_v) result(self)

    type(ResultGen) :: self
    type(ResultGen) :: res_check

    integer(kind=i8), optional, intent(in) :: data_int
    real(kind=dp), optional, intent(in) :: data_dp
    type(ErrorV), optional, intent(in) :: error_v

    integer, intent(in) :: tag

    call self % build (tag = tag, data_int = data_int, data_dp = data_dp,&
      error_v = error_v, res=res_check)

    if (res_check % is_error()) then
      print *, res_check % error_v % message
      error stop
    end if

  end function constructor

! ------------------ Setter -------------------------
  subroutine build(self,tag,data_int,data_dp,error_v,res)

    class(ResultGen),intent(out) :: self
    type(ResultGen),intent(out), optional :: res

    type(ErrorV), intent(in), optional :: error_v
    real(kind=dp), intent(in), optional :: data_dp
    integer(kind=i8), intent(in), optional :: data_int
    integer, intent(in) :: tag

    self % tag = tag

    if (tag == T_CLAIM) then
      return
    else if (present(data_int) .and. tag == T_INT) then
      self % data_int = data_int
    else if (present(data_dp) .and. tag == T_DP)then
      self % data_dp = data_dp
    else if (present(error_v) .and. tag == T_ERR)then
      allocate(self % error_v, source = error_v)
    else
      ! MZ is it really needed?
      res % error_v % code = 11
      res % error_v % message = "Build Error: TAG / INPUT mismatch"
    end if

  end subroutine build

! ------------------ Destructor -------------------------

  subroutine finalise(self)

    class(ResultGen),intent(inout) :: self

    self%tag = T_NONE
    if (allocated(self % error_v)) deallocate(self % error_v)

  end subroutine finalise

  subroutine finalise_auto(self)

    type(ResultGen),intent(inout) :: self

    call self % finalise()

  end subroutine finalise_auto

! ------------------ Checker -------------------------
  pure logical function is_none(self)

    class(ResultGen), intent(in) :: self

    is_none = (self % tag == T_NONE)

  end function is_none

  pure logical function is_error(self)

    class(ResultGen), intent(in) :: self

    if (self % tag == T_ERR)  then
      is_error = allocated(self % error_v)
      ! MZ : might make sense to check tag/allocation mismatch?
    else
      is_error = .false.
    end if

  end function is_error

  pure logical function is_int(self)

    class(ResultGen), intent(in) :: self

    is_int = (self % tag == T_INT)

  end function is_int

  pure logical function is_dp(self)

    class(ResultGen), intent(in) :: self

    is_dp = (self % tag == T_DP)

  end function is_dp

! ------------------ Getter -------------------------
  !
  ! pure function get_int(self) result(data_int)
  !
  !   class(ResultGen), intent(in) :: self
  !   integer(kind=i8) :: data_int
  !
  !   data_int = self % data_int
  !
  ! end function get_int
  !
  ! pure function get_dp(self) result(data_dp)
  !
  !   class(ResultGen), intent(in) :: self
  !   real(kind=dp) :: data_dp
  !
  !   data_dp = self % data_dp
  !
  ! end function get_dp
  !
  ! function get_error(self) result(error_v)
  !
  !   class(ResultGen), intent(in) :: self
  !   type(ErrorV) :: error_v
  !
  !   error_v = self % error_v
  !
  ! end function get_error

end module m_result_gen
