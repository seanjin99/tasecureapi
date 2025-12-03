cmake_minimum_required(VERSION 3.10)

# GoogleTest provider for unit testing
project(gtest_provider CXX)

include(FetchContent)

message(STATUS "Configuring GoogleTest provider...")

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

set_property(GLOBAL PROPERTY CTEST_TARGETS_ADDED 1)
include(CTest)
include(GoogleTest)

message(STATUS "GoogleTest provider configured successfully")
