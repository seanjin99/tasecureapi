cmake_minimum_required(VERSION 3.10)

# curve25519-donna provider for X25519 ECDH operations
project(curve25519_provider C)

include(FetchContent)

message(STATUS "Configuring curve25519-donna provider...")

FetchContent_Declare(
    curve25519_donna
    GIT_REPOSITORY https://github.com/agl/curve25519-donna.git
    GIT_TAG        master
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

    # Suppress clang static analyzer warnings for external curve25519-donna library (CI only)
    if(DEFINED ENV{CI})
        target_compile_options(curve25519_provider PRIVATE
            -Wno-analyzer-security-insecure-api-strcpy
            -Wno-analyzer-deadcode.DeadStores
            -Wno-analyzer-unix.Malloc
        )
    endif()

    set_property(TARGET curve25519_provider PROPERTY C_STANDARD 99)

    message(STATUS "curve25519-donna provider configured successfully")
endif()
