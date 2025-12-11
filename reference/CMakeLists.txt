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

project(tasecureapi)

option(BUILD_TESTS  "Builds and installs the unit tests" ON)
option(BUILD_DOC    "Build documentation" ON)

if(${BUILD_TESTS})
    enable_testing()
    # GoogleTest is configured in src/util/gtest/
    add_subdirectory(src/util/gtest)
endif()

# Setup mbedTLS before adding subdirectories so all sub-projects can use it
# mbedTLS is configured in src/taimpl/src/internal/providers/mbedtls/
add_subdirectory(src/taimpl/src/internal/providers/mbedtls)

add_subdirectory(src)
