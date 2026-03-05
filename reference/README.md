# Security API Reference Implementation

> For project overview, cryptographic capabilities, source structure, and basic build instructions
> see the [root README](../README.md).

## Summary

This library is the reference implementation of the Comcast Security API v3+. SoC vendors are
responsible for implementing this layer, including both the REE client interface and TA client
interface, as well as the backing implementation in TEE.

The TA cryptographic backend uses mbedTLS, libdecaf, ed25519-donna, and curve25519-donna.
OpenSSL is used only by the test harnesses (saclienttest, taimpltest, util_openssl_test).

## Vendor Porting Rules

See the [Source Structure](../README.md#source-structure) section in the root README for a
description of each directory. The rules below specify what SoC vendors **may** and **must**
modify.

### client/

Copy as-is — do **not** modify. Comcast will update reference headers and unit tests over time;
vendors *MUST* keep this folder in sync. Some unit tests (e.g. `sa_key_import_soc.cpp`) may be
modified if the vendor library does not support a particular feature. The vendor *MUST* declare to
Comcast which unit tests have been modified.

### clientimpl/

Only the files in the `internal` directory need to be modified. All other code in `src/` is
platform independent and should *NOT* be modified.

Some TEEs require communication through shared memory; to enable it define the compile-time flag
`USE_SHARED_MEMORY`. Vendors *MUST* implement the client-side functions defined in the porting
directory: `ta_open_session`, `ta_close_session`, `ta_invoke_command`,
`ta_alloc_shared_memory`, and `ta_free_shared_memory` (declared in `ta_client.h`, example
implementations in `ta_client.c`).

Vendors *MUST* implement code identified by `TODO SoC Vendor` in files in the `src/porting`
directory.

### taimpl/

Only the files in `include/internal`, `include/porting`, `src/internal`, and `src/porting` need
to be modified. All other code is platform independent and should *NOT* be modified.

Vendors *MUST* implement code to call the TA-side functions: `ta_open_session_handler`,
`ta_close_session_handler`, and `ta_invoke_command_handler` (declared in `ta.h`, implemented in
`ta.c`).

Vendors *MUST* implement code identified by `TODO SoC Vendor` in files in `include/porting` and
`src/porting`.

`include/internal` and `src/internal` contain the mbedTLS-based cryptographic implementation.
Vendors may modify these directories to replace the crypto backend with a SoC-specific
implementation.

### util/

Contains code to read a secret symmetric root key from an embedded PKCS 12 key store. The
reference implementation provides a default test root key embedded in `include/root_keystore.h`
and `src/root_keystore.c` as a compiled-in byte array, encrypted with a default password
(`DEFAULT_ROOT_KEYSTORE_PASSWORD`). The key is loaded directly from the embedded array at
runtime — no external file or environment variable is needed.

To use a different key store, replace the array in `src/root_keystore.c` and update the
password in `include/root_keystore.h`, then rebuild.

NOTE — this implementation reads PKCS 12 Secret Bags in the proprietary format created by Java's
`keytool` application.

### util_mbedtls/ and util_openssl/

Do **not** modify. Keep in sync with the reference implementation. These provide backend-specific
test utilities (PKCS8/PKCS12 parsing, digest wrappers) and are selected automatically based on the
build configuration.

## Build Options

See the [Build](../README.md#build) section in the root README for prerequisites and basic build
instructions. The options below are additional cmake flags for vendor and test configurations.

| Flag | Default | Description |
|---|---|---|
| `CMAKE_INSTALL_PREFIX` | system default | Install to a non-standard directory |
| `ENABLE_SOC_KEY_TESTS` | OFF | Enable SoC and root key tests. `TEST_KEY` in `sa_key_common.cpp` must match the root key on the test device. |
| `DISABLE_CENC_1000000_TESTS` | OFF | Disable 1 KB sample common encryption tests |

### SVP (Secure Video Pipeline) Support

SVP support is controlled by the `ENABLE_SVP` cmake option. By default, SVP is **OFF**.

To build with SVP enabled:

```
cmake -S . -B cmake-build -DENABLE_SVP=ON
```

When `ENABLE_SVP=ON`:
- SVP buffer management APIs (`sa_svp_buffer_*`) are fully functional.
- SVP key check (`sa_svp_key_check`) validates keys against SVP buffers.
- Cipher process and common encryption operations support SVP buffer types.
- SVP-related test cases are enabled in both `saclienttest` and `taimpltest`.

When `ENABLE_SVP=OFF` (default):
- SVP APIs return `SA_STATUS_OPERATION_NOT_SUPPORTED`.
- SVP-specific code is excluded from the build via `#ifdef ENABLE_SVP` guards.

**Note on OpenSSL dependency:** `BUILD_UTIL_OPENSSL` is **ON** by default. If you build with
`-DBUILD_UTIL_OPENSSL=OFF -DENABLE_SVP=ON`, `taimpltest` will still build — you just won't get
the `ta_sa_svp_crypto` tests. The other SVP tests in `taimpltest` (buffer check/copy/write, key
check) don't need OpenSSL.

```
cmake -S . -B cmake-build
```

Build reference implementation and unit tests

```
cmake --build cmake-build
```

Run unit test suite

```
cmake --build cmake-build --target test
```
or
```
cd cmake-build
ctest -V
```

To test for memory leaks

```
cd cmake-build
ctest -T memcheck
```

### Install

To install SecApi 3 (libsaclient), run a cmake install with an optional --prefix argument to
install in a non-standard directory.

```
cmake --install cmake-build [--prefix <directory>]
```

This copies the include files, the library, libsaclient.(so/dll/dylib) containing the SecAPI code (the
extension .so/.dll/.dylib created depends on which platform you are building on), and the test application,
saclienttest and taimpltest, to their appropriate locations on the system.

To run Key Provision file-based tests, refer to
[SecApiKeyProvisionTaTests.md](./test/SecApiKeyProvisionTaTests.md).

## Versioning

SecAPI version is specified using 4 numbers. The first 3 contain the major, minor, and point release
of the SecAPI specification document that this release has implemented. This version triplet is
specified in the src/client/include/sa.h file under the SA_SPECIFICATION_VERSION macro. Comcast is
responsible for updating the version number in this file.  Please see https://semver.org/
for reference.

An additional number is added for specifying an implementation revision for a particular spec
version. SoC vendors are responsible for updating this number with every revision of their
implementation. The full 4 number version can be retrieved using the sa_get_version() call.

## Porting guidance

### Suggested procedure for porting the SecAPI

1. Copy the reference implementation repo.
2. Replace the name of the project in ./CMakeLists.txt.
3. Modify files in src/clientimpl/src/internal, src/taimpl/include/internal,
   src/taimpl/include/porting, src/taimpl/src/internal, and src/taimpl/src/porting folders with
   platform specific implementation for a given platform.
4. Keep all folder except the ones mentioned in 3) up to date with reference implementation
   regularly.

### Secure Heap

SoC vendors are expected to provide memory allocation and de-allocation functions for secure heap if
available on the target platform (memory_secure_alloc, memory_secure_realloc, memory_secure_free).
The secure heap shall be used for storing unencrypted key material while in use.

## Coding Standards

clang-format is used to format all code according to the settings in the associated
.clang-format file. All attempts were used to use descriptive variable names and predefined
constants instead of magic numbers. When calling OpenSSL APIs (in test utilities), standard OpenSSL
convention is followed by testing return values against the value 1 which represents success.

clang-tidy is a linting tool used to diagnose and fixing typical programming errors.
