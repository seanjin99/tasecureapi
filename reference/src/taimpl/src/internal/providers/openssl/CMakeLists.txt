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

# OpenSSL provider — auto-fetch from source when not available on the system
project(openssl_provider C)

include(ExternalProject)

# Include centralized dependency versions
include(${CMAKE_SOURCE_DIR}/cmake/deps.cmake)

message(STATUS "Configuring OpenSSL provider...")

# Priority order:
#   1. OPENSSL_INCLUDE_DIR already set (cross-compile / Yocto sysroot) → use as-is
#   2. System OpenSSL found via find_package → use system copy
#   3. Neither available → fetch from GitHub and build from source

if(OPENSSL_INCLUDE_DIR AND EXISTS "${OPENSSL_INCLUDE_DIR}/openssl/ssl.h")
    # Case 1: Cross-compile — paths provided externally (e.g. BitBake recipe)
    message(STATUS "  Using provided OpenSSL: ${OPENSSL_INCLUDE_DIR}")
    set(OPENSSL_FROM_SOURCE FALSE CACHE BOOL "" FORCE)

elseif(NOT OPENSSL_FROM_SOURCE)
    # Case 2: Try system OpenSSL
    find_package(OpenSSL QUIET)
    if(OPENSSL_FOUND)
        message(STATUS "  Using system OpenSSL ${OPENSSL_VERSION}: ${OPENSSL_INCLUDE_DIR}")
        set(OPENSSL_FROM_SOURCE FALSE CACHE BOOL "" FORCE)
    else()
        message(STATUS "  System OpenSSL not found — will build from source")
        set(OPENSSL_FROM_SOURCE TRUE CACHE BOOL "" FORCE)
    endif()
endif()

if(OPENSSL_FROM_SOURCE)
    message(STATUS "  Fetching: ${DEPS_OPENSSL_GIT_REPO} @ ${DEPS_OPENSSL_GIT_TAG}")

    # Determine Configure target for the host platform
    if(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
        if(CMAKE_SYSTEM_PROCESSOR MATCHES "arm64|aarch64")
            set(OPENSSL_CONFIGURE_TARGET "darwin64-arm64-cc")
        else()
            set(OPENSSL_CONFIGURE_TARGET "darwin64-x86_64-cc")
        endif()
    elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
        if(CMAKE_SYSTEM_PROCESSOR MATCHES "arm|armv7")
            set(OPENSSL_CONFIGURE_TARGET "linux-armv4")
        elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64")
            set(OPENSSL_CONFIGURE_TARGET "linux-aarch64")
        else()
            set(OPENSSL_CONFIGURE_TARGET "linux-x86_64")
        endif()
    else()
        set(OPENSSL_CONFIGURE_TARGET "")
    endif()

    set(OPENSSL_INSTALL_DIR ${CMAKE_BINARY_DIR}/openssl/install)

    ExternalProject_Add(
        openssl_external
        GIT_REPOSITORY ${DEPS_OPENSSL_GIT_REPO}
        GIT_TAG ${DEPS_OPENSSL_GIT_TAG}
        GIT_SHALLOW TRUE
        PREFIX ${CMAKE_BINARY_DIR}/openssl
        CONFIGURE_COMMAND <SOURCE_DIR>/Configure
            ${OPENSSL_CONFIGURE_TARGET}
            --prefix=${OPENSSL_INSTALL_DIR}
            --openssldir=${OPENSSL_INSTALL_DIR}/ssl
            no-shared
            no-tests
            no-apps
            no-docs
        BUILD_COMMAND make -j$ENV{CMAKE_BUILD_PARALLEL_LEVEL}
        INSTALL_COMMAND make install_sw
        BUILD_IN_SOURCE 1
        BUILD_BYPRODUCTS
            ${OPENSSL_INSTALL_DIR}/lib/libssl.a
            ${OPENSSL_INSTALL_DIR}/lib/libcrypto.a
    )

    # Set variables for downstream consumers
    set(OPENSSL_INCLUDE_DIR ${OPENSSL_INSTALL_DIR}/include
        CACHE PATH "OpenSSL include directory" FORCE)
    set(OPENSSL_CRYPTO_LIBRARY ${OPENSSL_INSTALL_DIR}/lib/libcrypto.a
        CACHE FILEPATH "OpenSSL crypto library" FORCE)
    set(OPENSSL_SSL_LIBRARY ${OPENSSL_INSTALL_DIR}/lib/libssl.a
        CACHE FILEPATH "OpenSSL ssl library" FORCE)

    # Create IMPORTED targets
    add_library(openssl_crypto STATIC IMPORTED GLOBAL)
    set_target_properties(openssl_crypto PROPERTIES
        IMPORTED_LOCATION ${OPENSSL_INSTALL_DIR}/lib/libcrypto.a
    )
    add_dependencies(openssl_crypto openssl_external)

    add_library(openssl_ssl STATIC IMPORTED GLOBAL)
    set_target_properties(openssl_ssl PROPERTIES
        IMPORTED_LOCATION ${OPENSSL_INSTALL_DIR}/lib/libssl.a
    )
    add_dependencies(openssl_ssl openssl_external)

    message(STATUS "OpenSSL will be built from source into: ${OPENSSL_INSTALL_DIR}")
else()
    message(STATUS "OpenSSL provider: using pre-existing OpenSSL")
endif()

message(STATUS "OpenSSL include dir: ${OPENSSL_INCLUDE_DIR}")
message(STATUS "OpenSSL crypto lib:  ${OPENSSL_CRYPTO_LIBRARY}")
