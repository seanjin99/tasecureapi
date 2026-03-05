# Recipe for tasecureapi with mbedTLS backend
# 
# DEPENDENCY VERSION MANAGEMENT:
# All 3rd party dependency URLs and versions are defined in cmake/deps.cmake
# This recipe PARSES that file to fetch dependencies - single source of truth!
#
# Copyright 2020-2026 Comcast Cable Communications Management, LLC
# SPDX-License-Identifier: Apache-2.0

SUMMARY = "Secure API for TA implementation with mbedTLS"
DESCRIPTION = "Reference implementation of SecAPI with mbedTLS as crypto backend"
HOMEPAGE = "https://github.com/rdkcentral/tasecureapi"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://../LICENSE;md5=9b92ba42a610bc2b59cb924b84990497"

# Look for source files in files/ subdirectory
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# =============================================================================
# Source - tasecureapi (deps are fetched by parsing cmake/deps.cmake)
# =============================================================================
SRC_URI = "file://tasecureapi"

S = "${WORKDIR}/tasecureapi/reference"

inherit cmake

# =============================================================================
# Parse cmake/deps.cmake and fetch dependencies during do_fetch_deps
# This keeps cmake/deps.cmake as the SINGLE SOURCE OF TRUTH for versions
# =============================================================================
python do_fetch_deps() {
    """
    Parse cmake/deps.cmake to extract dependency URLs and tags, then git clone them.
    This runs AFTER do_unpack so tasecureapi source is available.
    """
    import subprocess
    import os
    import re
    
    workdir = d.getVar('WORKDIR')
    thisdir = d.getVar('THISDIR')
    
    # deps.cmake is in the source tree (in files/ subdirectory per Yocto convention)
    deps_cmake_path = os.path.join(thisdir, 'files', 'tasecureapi', 'reference', 'cmake', 'deps.cmake')
    
    if not os.path.exists(deps_cmake_path):
        bb.fatal(f"deps.cmake not found at {deps_cmake_path}")
    
    # Parse deps.cmake
    with open(deps_cmake_path, 'r') as f:
        content = f.read()
    
    # Match: set(DEPS_<NAME>_GIT_REPO "url")
    # Match: set(DEPS_<NAME>_GIT_TAG "tag")  
    deps = {}
    for match in re.finditer(r'set\(DEPS_(\w+)_GIT_REPO\s+"([^"]+)"\)', content):
        name = match.group(1)
        deps.setdefault(name, {})['repo'] = match.group(2)
    for match in re.finditer(r'set\(DEPS_(\w+)_GIT_TAG\s+"([^"]+)"\)', content):
        name = match.group(1)
        deps.setdefault(name, {})['tag'] = match.group(2)
    
    bb.note(f"Parsed {len(deps)} dependencies from deps.cmake")
    
    # Create deps directory
    deps_dir = os.path.join(workdir, 'deps')
    os.makedirs(deps_dir, exist_ok=True)
    
    # Clone each dependency
    for name, info in deps.items():
        if 'repo' not in info or 'tag' not in info:
            bb.warn(f"Skipping incomplete dependency {name}")
            continue
            
        repo = info['repo']
        tag = info['tag']
        
        # Convert name to directory (lowercase, underscores to hyphens)
        dir_name = name.lower().replace('_', '-')
        dest = os.path.join(deps_dir, dir_name)
        
        if os.path.exists(dest) and os.path.isdir(os.path.join(dest, '.git')):
            bb.note(f"{name}: already cloned at {dest}")
            continue
            
        bb.note(f"{name}: cloning {repo} @ {tag}")
        
        # Try branch first, fallback to tag
        try:
            subprocess.check_call(
                ['git', 'clone', '--depth', '1', '--branch', tag, repo, dest],
                stderr=subprocess.STDOUT
            )
        except subprocess.CalledProcessError:
            # Branch not found, try without --branch (for tags)
            if os.path.exists(dest):
                subprocess.check_call(['rm', '-rf', dest])
            subprocess.check_call(['git', 'clone', repo, dest])
            subprocess.check_call(['git', 'checkout', tag], cwd=dest)
            
        bb.note(f"{name}: cloned successfully")
}
addtask do_fetch_deps after do_unpack before do_configure
do_fetch_deps[network] = "1"

# Build dependencies - gtest and openssl from Yocto
DEPENDS = " \
    gtest \
    openssl \
"

# CMake configuration
EXTRA_OECMAKE = " \
    -DBUILD_TESTS=ON \
    -DBUILD_DOC=OFF \
    -DBUILD_UTIL_OPENSSL=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_THREAD_SANITIZER=OFF \
    -DENABLE_SVP=ON \
"

# Point CMake FetchContent to pre-fetched deps (WORKDIR/deps/xxx)
EXTRA_OECMAKE += " \
    -DFETCHCONTENT_FULLY_DISCONNECTED=ON \
    -DFETCHCONTENT_SOURCE_DIR_YAJL=${WORKDIR}/deps/yajl \
    -DFETCHCONTENT_SOURCE_DIR_CURVE25519_DONNA=${WORKDIR}/deps/curve25519-donna \
    -DFETCHCONTENT_SOURCE_DIR_ED25519_DONNA=${WORKDIR}/deps/ed25519-donna \
    -DFETCHCONTENT_SOURCE_DIR_LIBDECAF=${WORKDIR}/deps/libdecaf \
"

# mbedTLS uses ExternalProject, not FetchContent
EXTRA_OECMAKE += " \
    -DMBEDTLS_SOURCE_DIR=${WORKDIR}/deps/mbedtls \
"

# For lib32 multilib builds, Yocto sets CMAKE_SYSROOT correctly
# Let CMake's find_package(OpenSSL) search within the sysroot
# Do NOT hardcode OPENSSL_* paths - they differ between 32/64-bit builds

# Fix pthreads for cross-compilation
EXTRA_OECMAKE += " \
    -DTHREADS_PREFER_PTHREAD_FLAG=ON \
    -DCMAKE_THREAD_LIBS_INIT='-lpthread' \
    -DCMAKE_HAVE_THREADS_LIBRARY=1 \
    -DCMAKE_USE_PTHREADS_INIT=1 \
"

# Override optimization flags for cross-compile (remove -march=native)
EXTRA_OECMAKE += " \
    -DCMAKE_C_FLAGS_RELEASE='-O3 -DNDEBUG -Wno-error -Wno-uninitialized -Wno-maybe-uninitialized -Wno-incompatible-pointer-types' \
    -DCMAKE_CXX_FLAGS_RELEASE='-O3 -DNDEBUG -Wno-error' \
"

# Add warning suppressions to CFLAGS for external deps with false positive warnings
# libdecaf has uninitialized warnings in constant_time.h that are false positives
# ARM32: size_t is unsigned int but add_overflow uses unsigned long - both 32-bit
CFLAGS:append = " -Wno-error -Wno-uninitialized -Wno-maybe-uninitialized -Wno-incompatible-pointer-types"
CXXFLAGS:append = " -Wno-error"

# Build targets
# Main libraries: saclient, saclientimpl, taimpl, util_mbedtls
# Test executables: saclienttest, taimpltest, util_mbedtls_test, util_openssl_test

do_install() {
    # Only create directories if we have files to install
    local installed_bins=0
    local installed_libs=0
    
    # Install test executables (paths match CMake output structure)
    if [ -f ${B}/src/client/saclienttest ]; then
        install -d ${D}${bindir}
        install -m 0755 ${B}/src/client/saclienttest ${D}${bindir}/
        installed_bins=1
    fi
    if [ -f ${B}/src/taimpl/taimpltest ]; then
        install -d ${D}${bindir}
        install -m 0755 ${B}/src/taimpl/taimpltest ${D}${bindir}/
        installed_bins=1
    fi
    if [ -f ${B}/src/util_mbedtls/util_mbedtls_test ]; then
        install -d ${D}${bindir}
        install -m 0755 ${B}/src/util_mbedtls/util_mbedtls_test ${D}${bindir}/
        installed_bins=1
    fi
    if [ -f ${B}/src/util_openssl/util_openssl_test ]; then
        install -d ${D}${bindir}
        install -m 0755 ${B}/src/util_openssl/util_openssl_test ${D}${bindir}/
        installed_bins=1
    fi
    
    # Install libraries (paths match CMake output structure)
    if [ -f ${B}/src/client/libsaclient.so.3.4.1 ]; then
        install -d ${D}${libdir}
        install -m 0755 ${B}/src/client/libsaclient.so.3.4.1 ${D}${libdir}/
        # Create symlink for libsaclient.so (dev symlink)
        ln -sf libsaclient.so.3.4.1 ${D}${libdir}/libsaclient.so
        installed_libs=1
    elif [ -f ${B}/src/client/libsaclient.so ]; then
        install -d ${D}${libdir}
        install -m 0755 ${B}/src/client/libsaclient.so ${D}${libdir}/
        installed_libs=1
    fi
    
    # Install libdecaf (built as shared lib by CMake)
    if [ -f ${B}/_deps/libdecaf-build/src/libdecaf.so.0 ]; then
        install -d ${D}${libdir}
        install -m 0755 ${B}/_deps/libdecaf-build/src/libdecaf.so.0 ${D}${libdir}/
        ln -sf libdecaf.so.0 ${D}${libdir}/libdecaf.so
    fi
    
    # Install headers if any exist
    if [ -d ${S}/include/sa ]; then
        install -d ${D}${includedir}/sa
        install -m 0644 ${S}/include/sa/*.h ${D}${includedir}/sa/ 2>/dev/null || true
    fi
}

# Package configuration
PACKAGES = "${PN} ${PN}-dev ${PN}-dbg"

# Versioned shared libraries (.so.X) go in main package
# Unversioned .so symlinks go in -dev package
FILES:${PN} = " \
    ${bindir}/saclienttest \
    ${bindir}/taimpltest \
    ${bindir}/util_mbedtls_test \
    ${bindir}/util_openssl_test \
    ${libdir}/libsaclient.so.* \
    ${libdir}/libdecaf.so.* \
"

FILES:${PN}-dev = " \
    ${includedir} \
    ${libdir}/*.a \
    ${libdir}/libsaclient.so \
    ${libdir}/libdecaf.so \
"

# Allow .so symlinks in -dev even if base package is empty
INSANE_SKIP:${PN}-dev = "dev-so"

# Allow empty packages (some targets may not build)
ALLOW_EMPTY:${PN} = "1"

# Note: mbedTLS is downloaded and built by CMake FetchContent
# yajl and gtest are also fetched by CMake
