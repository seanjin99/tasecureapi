cmake_minimum_required(VERSION 3.10)

# mbedTLS cryptographic library provider
project(mbedtls_provider C)

include(ExternalProject)

message(STATUS "Configuring mbedTLS 2.16.10 provider...")

# Suppress warnings from mbedTLS's old CMake code
set(CMAKE_WARN_DEPRECATED OFF CACHE BOOL "" FORCE)

ExternalProject_Add(
    mbedtls_external
    GIT_REPOSITORY https://github.com/Mbed-TLS/mbedtls.git
    GIT_TAG mbedtls-2.16.10
    GIT_SHALLOW TRUE
    PREFIX ${CMAKE_BINARY_DIR}/mbedtls
    PATCH_COMMAND ${CMAKE_COMMAND} -E echo "Patching mbedTLS CMakeLists.txt to require CMake 3.10...3.28"
        COMMAND ${CMAKE_COMMAND} -P ${CMAKE_SOURCE_DIR}/cmake/patch_mbedtls.cmake <SOURCE_DIR>
        COMMAND ${CMAKE_COMMAND} -E echo "Enabling mbedTLS threading support for concurrent operations"
        COMMAND sed -i.bak "s|//#define MBEDTLS_THREADING_PTHREAD|#define MBEDTLS_THREADING_PTHREAD|g" <SOURCE_DIR>/include/mbedtls/config.h
        COMMAND sed -i.bak "s|//#define MBEDTLS_THREADING_C|#define MBEDTLS_THREADING_C|g" <SOURCE_DIR>/include/mbedtls/config.h
        COMMAND ${CMAKE_COMMAND} -E echo "Fixing build warnings in mbedTLS source files"
        COMMAND ${CMAKE_COMMAND} -DMBEDTLS_SOURCE_DIR=<SOURCE_DIR> -P ${CMAKE_SOURCE_DIR}/cmake/patch_mbedtls_warnings.cmake
    CMAKE_ARGS 
        -DENABLE_PROGRAMS=OFF 
        -DENABLE_TESTING=OFF 
        -DUSE_SHARED_MBEDTLS_LIBRARY=OFF 
        -DUSE_STATIC_MBEDTLS_LIBRARY=ON
        -DENABLE_ZLIB_SUPPORT=OFF
        -DCMAKE_WARN_DEPRECATED=OFF
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON
    INSTALL_COMMAND ""
)

# Re-enable deprecation warnings for our own code
set(CMAKE_WARN_DEPRECATED ON CACHE BOOL "" FORCE)

# Set mbedTLS variables (will be populated after ExternalProject builds)
set(MBEDTLS_INCLUDE_DIR ${CMAKE_BINARY_DIR}/mbedtls/src/mbedtls_external/include CACHE PATH "mbedTLS include directory")
set(MBEDTLS_LIBRARY_DIR ${CMAKE_BINARY_DIR}/mbedtls/src/mbedtls_external-build/library CACHE PATH "mbedTLS library directory")

# Create IMPORTED library targets for mbedTLS libraries
add_library(mbedtls_lib STATIC IMPORTED GLOBAL)
set_target_properties(mbedtls_lib PROPERTIES
    IMPORTED_LOCATION ${MBEDTLS_LIBRARY_DIR}/libmbedtls.a
)
add_dependencies(mbedtls_lib mbedtls_external)

add_library(mbedcrypto_lib STATIC IMPORTED GLOBAL)
set_target_properties(mbedcrypto_lib PROPERTIES
    IMPORTED_LOCATION ${MBEDTLS_LIBRARY_DIR}/libmbedcrypto.a
)
add_dependencies(mbedcrypto_lib mbedtls_external)

add_library(mbedx509_lib STATIC IMPORTED GLOBAL)
set_target_properties(mbedx509_lib PROPERTIES
    IMPORTED_LOCATION ${MBEDTLS_LIBRARY_DIR}/libmbedx509.a
)
add_dependencies(mbedx509_lib mbedtls_external)

set(MBEDTLS_LIBRARIES mbedtls_lib mbedcrypto_lib mbedx509_lib CACHE STRING "mbedTLS libraries")

message(STATUS "mbedTLS provider configured successfully")
message(STATUS "mbedTLS include dir: ${MBEDTLS_INCLUDE_DIR}")
message(STATUS "mbedTLS libraries: ${MBEDTLS_LIBRARIES}")
