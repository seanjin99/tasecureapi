#
# Copyright 2020-2025 Comcast Cable Communications Management, LLC
#
# SINGLE SOURCE OF TRUTH for third-party dependency versions
# - CMake includes this file to know dependency locations
# - BitBake parses this file to generate SRC_URI for Yocto builds
#
# Format: Each dependency has:
#   DEPS_<NAME>_GIT_REPO   - Git repository URL
#   DEPS_<NAME>_GIT_TAG    - Git tag/branch/commit
#
# SPDX-License-Identifier: Apache-2.0

# =============================================================================
# mbedTLS - Cryptographic library (TLS, ciphers, hashes, etc.)
# =============================================================================
set(DEPS_MBEDTLS_GIT_REPO "https://github.com/Mbed-TLS/mbedtls.git")
set(DEPS_MBEDTLS_GIT_TAG "mbedtls-2.16.10")

# =============================================================================
# YAJL - Yet Another JSON Library (JSON parsing)
# =============================================================================
set(DEPS_YAJL_GIT_REPO "https://github.com/lloyd/yajl.git")
set(DEPS_YAJL_GIT_TAG "2.1.0")

# =============================================================================
# libdecaf (ed448-goldilocks) - Ed448/X448 curve operations
# =============================================================================
set(DEPS_LIBDECAF_GIT_REPO "https://git.code.sf.net/p/ed448goldilocks/code")
set(DEPS_LIBDECAF_GIT_TAG "master")

# =============================================================================
# ed25519-donna - Ed25519 EdDSA operations
# =============================================================================
set(DEPS_ED25519_DONNA_GIT_REPO "https://github.com/floodyberry/ed25519-donna.git")
set(DEPS_ED25519_DONNA_GIT_TAG "master")

# =============================================================================
# curve25519-donna - X25519 ECDH operations
# =============================================================================
set(DEPS_CURVE25519_DONNA_GIT_REPO "https://github.com/agl/curve25519-donna.git")
set(DEPS_CURVE25519_DONNA_GIT_TAG "master")
