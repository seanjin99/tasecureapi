cmake_minimum_required(VERSION 3.10)

# ed448-goldilocks (libdecaf) provider for Ed448/X448 operations
# Note: We only use decaf for curve448 (Ed448/X448), not curve25519
# Curve25519 (Ed25519/X25519) is handled by ed25519-donna and curve25519-donna
project(decaf_provider C)

include(FetchContent)

# Include centralized dependency versions
include(${CMAKE_SOURCE_DIR}/cmake/deps.cmake)

message(STATUS "Configuring libdecaf (ed448-goldilocks) provider...")
message(STATUS "  Using: ${DEPS_LIBDECAF_GIT_REPO} @ ${DEPS_LIBDECAF_GIT_TAG}")

# Use Git mirror since SourceForge SVN can be unreliable
FetchContent_Declare(
    libdecaf
    GIT_REPOSITORY ${DEPS_LIBDECAF_GIT_REPO}
    GIT_TAG        ${DEPS_LIBDECAF_GIT_TAG}
    GIT_SHALLOW    TRUE
)

# Disable building tests and other unnecessary components before FetchContent
set(ENABLE_TESTS OFF CACHE BOOL "Disable libdecaf tests" FORCE)
set(ENABLE_STRICT OFF CACHE BOOL "Disable strict warnings for external library" FORCE)

# Suppress warnings as errors for external library code BEFORE FetchContent
# libdecaf has false positive uninitialized variable warnings in constant_time.h
set(CMAKE_C_FLAGS_BACKUP "${CMAKE_C_FLAGS}")
# Remove any -Werror flags
string(REPLACE "-Werror" "" CMAKE_C_FLAGS "${CMAKE_C_FLAGS}")
# Add warning suppressions - these must come AFTER any -W flags to override them
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-error -Wno-uninitialized -Wno-maybe-uninitialized")
# Also set for the decaf subdirectory specifically
set(DECAF_C_FLAGS "-Wno-error -Wno-uninitialized -Wno-maybe-uninitialized")

# FetchContent_MakeAvailable automatically:
# - Populates the content (downloads and extracts)
# - Calls add_subdirectory() which runs libdecaf's CMakeLists.txt
# libdecaf's build system then:
# - Detects CPU architecture automatically (x86_64, ARM64, ARM32, etc.)
# - Generates required source files using Python scripts
# - Selects optimal field arithmetic implementation per architecture
# - Builds both curve25519 and curve448 (we only use curve448)
FetchContent_MakeAvailable(libdecaf)

# Restore original flags for our own code
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS_BACKUP}")

# libdecaf builds a library called "decaf" - create an alias for our naming convention
if(TARGET decaf)
    # Suppress warnings on external library target
    target_compile_options(decaf PRIVATE -Wno-error -Wno-uninitialized -Wno-maybe-uninitialized)
    add_library(decaf_provider ALIAS decaf)
    message(STATUS "libdecaf provider configured successfully (using library: decaf)")
else()
    message(FATAL_ERROR "libdecaf did not create expected 'decaf' target")
endif()
