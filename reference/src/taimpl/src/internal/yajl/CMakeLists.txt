cmake_minimum_required(VERSION 3.10)

# YAJL (Yet Another JSON Library) - JSON parsing library
project(yajl_provider C)

include(FetchContent)

# Set policy to allow FetchContent_Populate (we need this to avoid YAJL's old CMakeLists.txt)
if(POLICY CMP0169)
    cmake_policy(SET CMP0169 OLD)
endif()

message(STATUS "Configuring YAJL provider...")

FetchContent_Declare(
    yajl
    GIT_REPOSITORY https://github.com/lloyd/yajl.git
    GIT_TAG        2.1.0
    GIT_SHALLOW    TRUE
)

# YAJL has an old CMakeLists.txt, so we download it but build manually
set(FETCHCONTENT_QUIET OFF)
FetchContent_GetProperties(yajl)
if(NOT yajl_POPULATED)
    FetchContent_Populate(yajl)
endif()

# Build YAJL manually to avoid compatibility issues with YAJL's old CMake files
set(YAJL_MAJOR 2)
set(YAJL_MINOR 1)
set(YAJL_MICRO 0)

# Create yajl/ subdirectory in build tree for headers
file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/yajl)

# Generate yajl_version.h in yajl/ subdirectory
configure_file(
    ${yajl_SOURCE_DIR}/src/api/yajl_version.h.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/yajl/yajl_version.h
)

# Copy all API headers to yajl/ subdirectory so includes like <yajl/yajl_parse.h> work
file(GLOB YAJL_API_HEADERS ${yajl_SOURCE_DIR}/src/api/*.h)
foreach(header ${YAJL_API_HEADERS})
    get_filename_component(header_name ${header} NAME)
    configure_file(${header} ${CMAKE_CURRENT_BINARY_DIR}/yajl/${header_name} COPYONLY)
endforeach()

# YAJL source files
set(YAJL_SOURCES
    ${yajl_SOURCE_DIR}/src/yajl.c
    ${yajl_SOURCE_DIR}/src/yajl_alloc.c
    ${yajl_SOURCE_DIR}/src/yajl_buf.c
    ${yajl_SOURCE_DIR}/src/yajl_encode.c
    ${yajl_SOURCE_DIR}/src/yajl_gen.c
    ${yajl_SOURCE_DIR}/src/yajl_lex.c
    ${yajl_SOURCE_DIR}/src/yajl_parser.c
    ${yajl_SOURCE_DIR}/src/yajl_tree.c
)

# Create static library
add_library(yajl_provider STATIC ${YAJL_SOURCES})

# Include directories
target_include_directories(yajl_provider
    PUBLIC 
        ${CMAKE_CURRENT_BINARY_DIR}  # For <yajl/yajl_*.h> includes
    PRIVATE
        ${yajl_SOURCE_DIR}/src       # For internal headers
)

# Compiler options
target_compile_options(yajl_provider PRIVATE
    -Wall
    -Wextra
    -Wno-unused-parameter
    -Wno-missing-field-initializers
    -Wno-implicit-fallthrough
)

# Suppress clang static analyzer warnings for external YAJL library
if(CMAKE_C_COMPILER_ID MATCHES "Clang")
    target_compile_options(yajl_provider PRIVATE
        -Wno-analyzer-security-insecure-api-strcpy
        -Wno-analyzer-deadcode.DeadStores
        -Wno-analyzer-unix.Malloc
    )
endif()

# Platform-specific settings
if(WIN32)
    target_compile_definitions(yajl_provider PRIVATE WIN32)
endif()

set_property(TARGET yajl_provider PROPERTY C_STANDARD 99)

message(STATUS "YAJL provider configured successfully")
