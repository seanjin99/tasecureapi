# Patch script for mbedTLS CMakeLists.txt and config.h
# This script modifies the mbedTLS CMakeLists.txt to require CMake 3.10...3.28
# and enables CMAC and platform memory support in config.h
# Applies RSA PSS and GCM patches

# Get the source directory from command line argument
set(MBEDTLS_SOURCE_DIR ${CMAKE_ARGV3})

if(NOT EXISTS "${MBEDTLS_SOURCE_DIR}/CMakeLists.txt")
    message(FATAL_ERROR "mbedTLS CMakeLists.txt not found at ${MBEDTLS_SOURCE_DIR}/CMakeLists.txt")
endif()

message(STATUS "Patching ${MBEDTLS_SOURCE_DIR}/CMakeLists.txt")

# Read the original CMakeLists.txt
file(READ "${MBEDTLS_SOURCE_DIR}/CMakeLists.txt" MBEDTLS_CMAKELISTS)

# Replace cmake_minimum_required version from 2.6 to 3.10...3.28 range
string(REPLACE
    "cmake_minimum_required(VERSION 2.6)"
    "cmake_minimum_required(VERSION 3.10...3.28)"
    MBEDTLS_CMAKELISTS
    "${MBEDTLS_CMAKELISTS}"
)

# Also replace 2.8.12 if it exists (for other mbedTLS versions)
string(REPLACE
    "cmake_minimum_required(VERSION 2.8.12)"
    "cmake_minimum_required(VERSION 3.10...3.28)"
    MBEDTLS_CMAKELISTS
    "${MBEDTLS_CMAKELISTS}"
)

# Suppress deprecated PythonInterp warning by commenting out the find_package call
string(REPLACE
    "find_package(PythonInterp)"
    "# find_package(PythonInterp) # Commented out to suppress deprecation warning"
    MBEDTLS_CMAKELISTS
    "${MBEDTLS_CMAKELISTS}"
)

# Write the patched CMakeLists.txt
file(WRITE "${MBEDTLS_SOURCE_DIR}/CMakeLists.txt" "${MBEDTLS_CMAKELISTS}")

message(STATUS "Successfully patched mbedTLS CMakeLists.txt to require CMake 3.10...3.28 and suppress PythonInterp warning")

# Now patch config.h to enable CMAC and PLATFORM_MEMORY
if(EXISTS "${MBEDTLS_SOURCE_DIR}/include/mbedtls/config.h")
    message(STATUS "Patching ${MBEDTLS_SOURCE_DIR}/include/mbedtls/config.h")

    file(READ "${MBEDTLS_SOURCE_DIR}/include/mbedtls/config.h" MBEDTLS_CONFIG)

    # Enable CMAC_C
    string(REPLACE
        "//#define MBEDTLS_CMAC_C"
        "#define MBEDTLS_CMAC_C"
        MBEDTLS_CONFIG
        "${MBEDTLS_CONFIG}"
    )

    # Enable PLATFORM_MEMORY
    string(REPLACE
        "//#define MBEDTLS_PLATFORM_MEMORY"
        "#define MBEDTLS_PLATFORM_MEMORY"
        MBEDTLS_CONFIG
        "${MBEDTLS_CONFIG}"
    )

    file(WRITE "${MBEDTLS_SOURCE_DIR}/include/mbedtls/config.h" "${MBEDTLS_CONFIG}")

    message(STATUS "Successfully enabled CMAC and PLATFORM_MEMORY in mbedTLS config.h")
endif()

# Apply RSA PSS hang fix patch
set(RSA_PATCH_FILE "${CMAKE_CURRENT_LIST_DIR}/patches_mbedtls/mbedtls_rsa_pss_hang_fix.patch")
if(EXISTS "${RSA_PATCH_FILE}" AND EXISTS "${MBEDTLS_SOURCE_DIR}/library/rsa.c")
    message(STATUS "Applying mbedTLS RSA PSS hang fix patch...")
    execute_process(
        COMMAND patch -N -p1 -i ${RSA_PATCH_FILE}
        WORKING_DIRECTORY ${MBEDTLS_SOURCE_DIR}
        RESULT_VARIABLE PATCH_RESULT
        OUTPUT_VARIABLE PATCH_OUTPUT
        ERROR_VARIABLE PATCH_ERROR
    )
    if(PATCH_RESULT EQUAL 0)
        message(STATUS "Successfully applied mbedTLS RSA PSS hang fix")
    else()
        message(WARNING "Failed to apply RSA patch (may already be applied): ${PATCH_ERROR}")
    endif()
endif()

# Apply GCM multi-part fix patch (backported from mbedTLS 3.x)
set(GCM_PATCH_FILE "${CMAKE_CURRENT_LIST_DIR}/patches_mbedtls/gcm_multipart_mbedtls3x_backport.patch")
if(EXISTS "${GCM_PATCH_FILE}" AND EXISTS "${MBEDTLS_SOURCE_DIR}/library/gcm.c")
    message(STATUS "Applying mbedTLS GCM multi-part fix patch...")
    execute_process(
        COMMAND patch -N -p1 -i ${GCM_PATCH_FILE}
        WORKING_DIRECTORY ${MBEDTLS_SOURCE_DIR}
        RESULT_VARIABLE PATCH_RESULT
        OUTPUT_VARIABLE PATCH_OUTPUT
        ERROR_VARIABLE PATCH_ERROR
    )
    if(PATCH_RESULT EQUAL 0)
        message(STATUS "Successfully applied mbedTLS GCM multi-part fix (backported from mbedTLS 3.x)")
    else()
        message(WARNING "Failed to apply GCM patch (may already be applied): ${PATCH_ERROR}")
    endif()
endif()

# (Reverted) ECP fixed-point optimization patch application removed due to no measurable improvement

# Apply CTR counter increment performance optimization (backported from mbedTLS 3.6.2 commit 591ff05)
# NOTE: This is a PERFORMANCE optimization only - processes counter in 32-bit chunks for speed.
set(CTR_PATCH_FILE "${CMAKE_CURRENT_LIST_DIR}/patches_mbedtls/mbedtls-ctr-counter-fix.patch")
if(EXISTS "${CTR_PATCH_FILE}")
    message(STATUS "Applying mbedTLS CTR counter performance optimization...")

    # Copy the ctr.h header file from patches directory
    set(CTR_H_SOURCE "${CMAKE_CURRENT_LIST_DIR}/patches_mbedtls/ctr.h")
    set(CTR_H_PATH "${MBEDTLS_SOURCE_DIR}/library/ctr.h")
    if(NOT EXISTS "${CTR_H_PATH}" AND EXISTS "${CTR_H_SOURCE}")
        file(COPY "${CTR_H_SOURCE}" DESTINATION "${MBEDTLS_SOURCE_DIR}/library/")
        message(STATUS "Copied library/ctr.h header file from patches directory")
    endif()

    # Now patch aes.c to use the new counter increment function
    if(EXISTS "${MBEDTLS_SOURCE_DIR}/library/aes.c")
        file(READ "${MBEDTLS_SOURCE_DIR}/library/aes.c" AES_CONTENT)

        # Add include directive if not already present
        if(NOT AES_CONTENT MATCHES "#include \"ctr.h\"")
            string(REGEX REPLACE
                "(#include \"mbedtls/aesni.h\")"
                "\\1\\n#include \"ctr.h\""
                AES_CONTENT "${AES_CONTENT}")
            message(STATUS "Added #include \"ctr.h\" to aes.c")
        endif()

        # Replace the counter increment loop with the optimized function
        string(REGEX REPLACE
            "for\\( i = 16; i > 0; i-- \\)\n[ \t]*if\\( \\+\\+nonce_counter\\[i - 1\\] != 0 \\)\n[ \t]*break;"
            "mbedtls_ctr_increment_counter(nonce_counter);"
            AES_CONTENT "${AES_CONTENT}")

        # Remove unused variable 'i' from the declaration to fix warning
        string(REGEX REPLACE
            "int c, i;"
            "int c;"
            AES_CONTENT "${AES_CONTENT}")

        file(WRITE "${MBEDTLS_SOURCE_DIR}/library/aes.c" "${AES_CONTENT}")
        message(STATUS "Successfully applied CTR counter performance optimization to aes.c")
    endif()
endif()

# Apply ARM64 (aarch64) bignum optimization directly
# This backports aarch64 assembly from newer mbedTLS versions to 2.16.10
set(BN_MUL_H "${MBEDTLS_SOURCE_DIR}/include/mbedtls/bn_mul.h")

#if(EXISTS "${BN_MUL_H}")
if(FALSE)
    file(READ "${BN_MUL_H}" BN_MUL_CONTENT)

    # Check if aarch64 optimization is already present
    if(NOT BN_MUL_CONTENT MATCHES "defined\\(__aarch64__\\)")
        message(STATUS "Applying ARM64 (aarch64) bignum hardware acceleration optimization...")

        # Find the line after "#endif /* AMD64 */" and inject aarch64 code
        # Match AMD64 pattern: INIT opens asm, CORE adds instructions, STOP closes asm
        string(REGEX REPLACE
            "(#endif /\\* AMD64 \\*/)"
            "\\1\n\n#if defined(__aarch64__)\n\n#define MULADDC_INIT                                        \\\\\n    asm(\n\n#define MULADDC_CORE                                            \\\\\n        \"ldr x4, [%1]               \\\\n\\\\t\"                       \\\\\n        \"mul x5, x4, %3             \\\\n\\\\t\"                       \\\\\n        \"umulh x6, x4, %3           \\\\n\\\\t\"                       \\\\\n        \"ldr x7, [%2]               \\\\n\\\\t\"                       \\\\\n        \"adds x7, x7, x5            \\\\n\\\\t\"                       \\\\\n        \"adc x6, x6, xzr            \\\\n\\\\t\"                       \\\\\n        \"adds x7, x7, %0            \\\\n\\\\t\"                       \\\\\n        \"adc %0, x6, xzr            \\\\n\\\\t\"                       \\\\\n        \"str x7, [%2]               \\\\n\\\\t\"                       \\\\\n        \"add %1, %1, #8             \\\\n\\\\t\"                       \\\\\n        \"add %2, %2, #8             \\\\n\\\\t\"\n\n#define MULADDC_STOP                                            \\\\\n         : \"+r\" (c), \"+r\" (s), \"+r\" (d)                          \\\\\n         : \"r\" (b)                                              \\\\\n         : \"x4\", \"x5\", \"x6\", \"x7\", \"cc\", \"memory\"               \\\\\n    );\n\n#endif /* Aarch64 */"
            BN_MUL_CONTENT "${BN_MUL_CONTENT}")

        file(WRITE "${BN_MUL_H}" "${BN_MUL_CONTENT}")
        message(STATUS "✓ Successfully applied ARM64 aarch64 bignum hardware acceleration")
    else()
        message(STATUS "ARM64 aarch64 optimization already present in bn_mul.h")
    endif()
endif()
