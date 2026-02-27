cmake_minimum_required(VERSION 3.10)

# GoogleTest provider for unit testing
project(gtest_provider CXX)

message(STATUS "Configuring GoogleTest provider...")

# For cross-compile builds (like Yocto), use system-provided GTest
# For native builds, use FetchContent
if(CMAKE_CROSSCOMPILING)
    message(STATUS "Cross-compiling: using system GTest")
    find_package(GTest REQUIRED)
    
    # Create interface targets that properly propagate dependencies
    # ALIAS targets don't propagate transitive deps, so use INTERFACE libraries
    if(NOT TARGET gtest)
        add_library(gtest INTERFACE)
        target_link_libraries(gtest INTERFACE GTest::gtest)
    endif()
    if(NOT TARGET gtest_main)
        add_library(gtest_main INTERFACE)
        target_link_libraries(gtest_main INTERFACE GTest::gtest_main GTest::gtest)
    endif()
    if(NOT TARGET gmock)
        add_library(gmock INTERFACE)
        target_link_libraries(gmock INTERFACE GTest::gmock GTest::gtest)
    endif()
    if(NOT TARGET gmock_main)
        add_library(gmock_main INTERFACE)
        # gmock_main needs gmock and gtest - ensure proper link order
        target_link_libraries(gmock_main INTERFACE GTest::gmock_main GTest::gmock GTest::gtest)
    endif()
else()
    message(STATUS "Native build: fetching GoogleTest")
    include(FetchContent)

    FetchContent_Declare(
        googletest
        GIT_REPOSITORY https://github.com/google/googletest.git
        GIT_TAG v1.13.0
    )

    # Suppress deprecation warnings from googletest's CMakeLists.txt
    # googletest v1.13.0 uses cmake_minimum_required(VERSION 3.5) which is deprecated
    set(CMAKE_WARN_DEPRECATED OFF CACHE BOOL "" FORCE)

    # FetchContent_MakeAvailable automatically populates and adds the subdirectory
    set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
    FetchContent_MakeAvailable(googletest)

    # Re-enable deprecation warnings for our own code
    set(CMAKE_WARN_DEPRECATED ON CACHE BOOL "" FORCE)
endif()

set_property(GLOBAL PROPERTY CTEST_TARGETS_ADDED 1)
include(CTest)
include(GoogleTest)

message(STATUS "GoogleTest provider configured successfully")
