#
# Copyright 2020-2025 Comcast Cable Communications Management, LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0

cmake_minimum_required(VERSION 3.16)

project(tasecureapi-src)

set(CMAKE_CXX_STANDARD 11 CACHE STRING "C++ standard to be used")
set(CMAKE_C_STANDARD 11 CACHE STRING "C standard to be used")

# Option to enable ThreadSanitizer (disabled by default for performance)
option(ENABLE_THREAD_SANITIZER "Enable ThreadSanitizer for race condition detection" OFF)

# Option to build util_openssl (requires OpenSSL, disable for mbedTLS-only builds)
option(BUILD_UTIL_OPENSSL "Build util_openssl tests (requires OpenSSL)" ON)

# Option to enable -march=native optimization (auto-detected, can be overridden)
# OFF = safe for cross-compilation or when targeting a different arch than the build host
# ON  = optimize for the build host's CPU (x86_64 SSE/AVX, ARM64 NEON/Crypto, etc.)
option(ENABLE_MARCH_NATIVE "Use -march=native -mtune=native for host-optimized builds" OFF)

# Auto-detect: enable -march=native by default for native (non-cross) builds
if(NOT DEFINED ENABLE_MARCH_NATIVE OR NOT ENABLE_MARCH_NATIVE)
    if(NOT CMAKE_CROSSCOMPILING)
        # Check if building natively on x86_64 or ARM64
        if(CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64|amd64|i[3-6]86|AMD64")
            message(STATUS "Detected x86 native build - use -DENABLE_MARCH_NATIVE=ON to enable -march=native")
        elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64|arm64|ARM64")
            message(STATUS "Detected ARM64 native build - use -DENABLE_MARCH_NATIVE=ON to enable -march=native")
        endif()
    endif()
endif()

# Aggressive optimization flags
# -O3: Maximum optimization
# -march=native: Use all CPU features (gated by ENABLE_MARCH_NATIVE)
# -mtune=native: Tune for this specific CPU
# -ffast-math: Aggressive floating point optimizations
# -funroll-loops: Unroll loops for better performance
# -fomit-frame-pointer: Free up a register

# Determine architecture-specific flags
if(CMAKE_CROSSCOMPILING)
    # Cross-compilation: never use -march=native
    set(OPTIMIZATION_FLAGS "-O3 -ffast-math -funroll-loops -fomit-frame-pointer")
    message(STATUS "Cross-compiling: using generic optimization flags (no -march=native)")
elseif(ENABLE_MARCH_NATIVE)
    # Native build with -march=native explicitly enabled
    if(CMAKE_CXX_COMPILER_ID MATCHES "GNU")
        set(OPTIMIZATION_FLAGS "-O3 -march=native -mtune=native -ffast-math -funroll-loops -fomit-frame-pointer")
        message(STATUS "Using GCC with -march=native (host-optimized build)")
    elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
        set(OPTIMIZATION_FLAGS "-O3 -march=native -mtune=native -ffast-math -funroll-loops -fomit-frame-pointer")
        message(STATUS "Using Clang with -march=native (host-optimized build)")
    else()
        set(OPTIMIZATION_FLAGS "-O3 -march=native -mtune=native -ffast-math -funroll-loops -fomit-frame-pointer")
        message(STATUS "Using -march=native with unknown compiler")
    endif()
else()
    # Native build WITHOUT -march=native (safe default, portable binary)
    set(OPTIMIZATION_FLAGS "-O3 -ffast-math -funroll-loops -fomit-frame-pointer")
    message(STATUS "Native build without -march=native (portable). Use -DENABLE_MARCH_NATIVE=ON to optimize for this host.")
endif()

set(CMAKE_CXX_FLAGS "-D_GNU_SOURCE -fPIC ${OPTIMIZATION_FLAGS} ${CMAKE_CXX_FLAGS}")
set(CMAKE_C_FLAGS "-D_GNU_SOURCE -fPIC ${OPTIMIZATION_FLAGS} ${CMAKE_C_FLAGS}")

# Enable Link-Time Optimization (LTO) for maximum performance
set(CMAKE_INTERPROCEDURAL_OPTIMIZATION TRUE)

if(ENABLE_THREAD_SANITIZER)
    message(STATUS "ThreadSanitizer ENABLED - for debug purpose build only")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fsanitize=thread -g -O1")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fsanitize=thread -g -O1")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fsanitize=thread")
else()
    message(STATUS "Using optimized build with ARM64 NEON/Crypto optimizations")
endif()

if (COVERAGE AND CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    set(CMAKE_CXX_FLAGS "-g -fprofile-arcs -ftest-coverage ${CMAKE_CXX_FLAGS}")
    set(CMAKE_C_FLAGS "-g -fprofile-arcs -ftest-coverage ${CMAKE_C_FLAGS}")
endif ()

set(CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/../cmake" ${CMAKE_MODULE_PATH})
message("CMAKE_MODULE_PATH=${CMAKE_MODULE_PATH}")
include(ClangFormat)

if (DEFINED ENABLE_SOC_KEY_TESTS)
    set(CMAKE_CXX_FLAGS "-DENABLE_SOC_KEY_TESTS ${CMAKE_CXX_FLAGS}")
    set(CMAKE_C_FLAGS "-DENABLE_SOC_KEY_TESTS ${CMAKE_C_FLAGS}")
endif ()

if (DEFINED DISABLE_CENC_TIMING)
    set(CMAKE_CXX_FLAGS "-DDISABLE_CENC_TIMING ${CMAKE_CXX_FLAGS}")
    set(CMAKE_C_FLAGS "-DDISABLE_CENC_TIMING ${CMAKE_C_FLAGS}")
endif ()

if (ENABLE_SVP)
    set(CMAKE_CXX_FLAGS "-DENABLE_SVP ${CMAKE_CXX_FLAGS}")
    set(CMAKE_C_FLAGS "-DENABLE_SVP ${CMAKE_C_FLAGS}")
endif ()

add_subdirectory(util)
add_subdirectory(util_mbedtls)
if(BUILD_UTIL_OPENSSL)
    add_subdirectory(util_openssl)
endif()
add_subdirectory(client)
add_subdirectory(clientimpl)
add_subdirectory(taimpl)

# 'make install' to the correct locations (provided by GNUInstallDirs).
include(GNUInstallDirs)
install(TARGETS saclient EXPORT sa-client-config
        ARCHIVE DESTINATION lib
        LIBRARY DESTINATION lib
        RUNTIME DESTINATION bin
        )
install(DIRECTORY client/include/ DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})

install(TARGETS taimpl saclientimpl
        ARCHIVE DESTINATION lib
        LIBRARY DESTINATION lib
        RUNTIME DESTINATION bin
        )

if (BUILD_TESTS)
    set(TEST_TARGETS saclienttest taimpltest util_mbedtls_test)
    if(BUILD_UTIL_OPENSSL)
        list(APPEND TEST_TARGETS util_openssl_test)
    endif()
    install(TARGETS ${TEST_TARGETS}
            ARCHIVE DESTINATION lib
            LIBRARY DESTINATION lib
            RUNTIME DESTINATION bin
            )
endif ()
