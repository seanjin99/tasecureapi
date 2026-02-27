cmake_minimum_required(VERSION 3.10)

# curve25519-donna provider for X25519 ECDH operations
project(curve25519_provider C)

include(FetchContent)

# Include centralized dependency versions
include(${CMAKE_SOURCE_DIR}/cmake/deps.cmake)

message(STATUS "Configuring curve25519-donna provider...")
message(STATUS "  Using: ${DEPS_CURVE25519_DONNA_GIT_REPO} @ ${DEPS_CURVE25519_DONNA_GIT_TAG}")

FetchContent_Declare(
    curve25519_donna
    GIT_REPOSITORY ${DEPS_CURVE25519_DONNA_GIT_REPO}
    GIT_TAG        ${DEPS_CURVE25519_DONNA_GIT_TAG}
    GIT_SHALLOW    TRUE
)

FetchContent_MakeAvailable(curve25519_donna)

FetchContent_GetProperties(curve25519_donna)
if(curve25519_donna_POPULATED)
    # Copy custom headers for SecAPI integration
    file(COPY ${CMAKE_SOURCE_DIR}/cmake/custom_headers/curve25519-donna.h
         DESTINATION ${curve25519_donna_SOURCE_DIR})
    file(COPY ${CMAKE_SOURCE_DIR}/cmake/custom_headers/curve25519-randombytes-custom.h
         DESTINATION ${curve25519_donna_SOURCE_DIR})

    # Create build configuration
    set(CURVE25519_SOURCES ${curve25519_donna_SOURCE_DIR}/curve25519-donna.c)
    add_library(curve25519_provider STATIC ${CURVE25519_SOURCES})

    target_include_directories(curve25519_provider
        PUBLIC ${curve25519_donna_SOURCE_DIR}
        PRIVATE ${CMAKE_SOURCE_DIR}/src/taimpl/include
    )

    target_compile_options(curve25519_provider PRIVATE
        -Werror
        -Wall
        -Wextra
        -Wno-unused-parameter
        -Wno-unused-function
    )

    set_property(TARGET curve25519_provider PROPERTY C_STANDARD 99)

    message(STATUS "curve25519-donna provider configured successfully")
endif()
