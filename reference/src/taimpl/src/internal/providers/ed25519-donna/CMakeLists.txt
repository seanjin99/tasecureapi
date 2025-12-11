cmake_minimum_required(VERSION 3.10)

# ed25519-donna provider for Ed25519 EdDSA operations
project(edwards_provider C)

include(FetchContent)

message(STATUS "Configuring ed25519-donna provider...")

FetchContent_Declare(
    ed25519_donna
    GIT_REPOSITORY https://github.com/floodyberry/ed25519-donna.git
    GIT_TAG        master
    GIT_SHALLOW    TRUE
)

FetchContent_MakeAvailable(ed25519_donna)

FetchContent_GetProperties(ed25519_donna)
if(ed25519_donna_POPULATED)
    # Copy custom headers for SecAPI integration
    file(COPY ${CMAKE_SOURCE_DIR}/cmake/custom_headers/ed25519-hash-custom.h
         DESTINATION ${ed25519_donna_SOURCE_DIR})
    file(COPY ${CMAKE_SOURCE_DIR}/cmake/custom_headers/ed25519-randombytes-custom.h
         DESTINATION ${ed25519_donna_SOURCE_DIR})

    # Create build configuration
    set(ED25519_SOURCES ${ed25519_donna_SOURCE_DIR}/ed25519.c)
    add_library(edwards_provider STATIC ${ED25519_SOURCES})

    target_include_directories(edwards_provider
        PUBLIC ${ed25519_donna_SOURCE_DIR}
        PRIVATE
            ${CMAKE_SOURCE_DIR}/src/taimpl/include
            ${MBEDTLS_INCLUDE_DIR}
    )

    target_compile_options(edwards_provider PRIVATE
        -Werror
        -Wall
        -Wextra
        -Wno-unused-parameter
        -Wno-unused-function
        -Wno-macro-redefined
        -Wno-implicit-fallthrough
    )

    # Define ED25519_CUSTOMHASH and ED25519_CUSTOMRANDOM to use our custom implementations
    target_compile_definitions(edwards_provider PRIVATE
        ED25519_CUSTOMHASH
        ED25519_CUSTOMRANDOM
    )

    # Ensure mbedTLS is built before edwards_provider (needed for SHA-512 headers)
    add_dependencies(edwards_provider mbedtls_external)

    set_property(TARGET edwards_provider PROPERTY C_STANDARD 99)

    message(STATUS "ed25519-donna provider configured successfully")
endif()
