!> Tests of m_error_v_creation
module test_error_v_creation

    ! How to print to stdout
    use ISO_Fortran_env, only: stdout => OUTPUT_UNIT
    use testdrive, only: new_unittest, unittest_type, error_type, check

    use kind_parameters, only: dp

    implicit none
    private

    public :: collect_error_v_creation_tests

contains

    subroutine collect_error_v_creation_tests(testsuite)
        !> Collection of tests
        type(unittest_type), allocatable, intent(out) :: testsuite(:)

        testsuite = [ &
            new_unittest("test_error_v_creation_basic", test_error_v_creation_basic), &
            new_unittest("test_error_v_creation_edge", test_error_v_creation_edge) &
        ]

    end subroutine collect_error_v_creation_tests

    subroutine test_error_v_creation_basic(error)
        use m_error_v, only: ErrorV
        use m_error_v_creation, only: create_error

        type(error_type), allocatable, intent(out) :: error

        type(ErrorV) :: res

        res = create_error(1)

        ! ! How to print to stdout
        ! write( stdout, '(e13.4e2)') res
        ! write( stdout, '(e13.4e2)') exp

        call check(error, res % code, 0)
        call check(error, res % message, "")

    end subroutine test_error_v_creation_basic

    subroutine test_error_v_creation_edge(error)
        use m_error_v, only: ErrorV
        use m_error_v_creation, only: create_error

        type(error_type), allocatable, intent(out) :: error

        ! type(ErrorV), target :: res
        ! type(ErrorV), pointer :: res_ptr
        !
        ! res = create_error(1)
        ! res_ptr => res
        type(ErrorV), pointer :: res

        allocate(res)
        res = create_error(1)

        ! ! How to print to stdout
        ! write( stdout, '(e13.4e2)') res
        ! write( stdout, '(e13.4e2)') exp

        call check(error, res % code, 0)
        call check(error, res % message, "")

    end subroutine test_error_v_creation_edge

end module test_error_v_creation
