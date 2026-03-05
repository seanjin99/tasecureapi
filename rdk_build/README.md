# RDK Build — tasecureapi with mbedTLS

## Overview

This directory contains the BitBake recipe (`tasecureapi-mbedtls_1.0.bb`) for
cross-compiling tasecureapi on an RDK (Yocto) build server targeting ARM32.

`ENABLE_SVP` is **ON by default** in the recipe.

## Build Instructions

### Prerequisites

- RDK Yocto build environment (oe-init-build-env sourced)
- Recipe placed under your Yocto layer, e.g.:
  `meta-rdk-vendor-test-utils/recipes-extend/mbedtls2.6.1/`
- Source tree placed under `files/tasecureapi/` alongside the recipe

### Build

```bash
# Source the build environment
source ~/sharp-mtk/rdke/common/poky/oe-init-build-env ~/sharp-mtk/scripts/build-sharp-m120-32

# Full build
bitbake lib32-tasecureapi-mbedtls

# Clean rebuild (after source changes)
bitbake lib32-tasecureapi-mbedtls -c cleansstate && bitbake lib32-tasecureapi-mbedtls
```

### Build with SVP OFF

To disable SVP, edit the recipe and change `-DENABLE_SVP=ON` to `-DENABLE_SVP=OFF`
in the `EXTRA_OECMAKE` block, then do a clean rebuild.

Alternatively, override via `local.conf` without modifying the recipe:

```bash
# In conf/local.conf — override SVP to OFF
EXTRA_OECMAKE:remove:pn-lib32-tasecureapi-mbedtls = "-DENABLE_SVP=ON"
EXTRA_OECMAKE:append:pn-lib32-tasecureapi-mbedtls = " -DENABLE_SVP=OFF"
```

## Expected Test Results (ARM32)

### saclienttest

| Configuration | Total Tests | Passed | Failed | Skipped | Notes |
|---|---|---|---|---|---|
| SVP=ON  | 6670 | 6454 | **216** | — | 216 CENC timing failures |
| SVP=ON + DISABLE_CENC_TIMING | 6670 | **6670** | **0** | — | All pass (757393 ms) |
| SVP=OFF | 6635 | ~5352 | **72**  | ~1211 | 72 CENC timing failures  |

### taimpltest

| Configuration | Total Tests | Passed | Failed | Skipped | Notes |
|---|---|---|---|---|---|
| SVP=ON  | 707 | **635** | **72** | 0 | 72 CENC timing failures (`TaProcessCommonEncryptionTests_1000000`) |
| SVP=ON + DISABLE_CENC_TIMING | 707 | **707** | **0** | 0 | All pass (18666 ms) |
| SVP=OFF | 143 | **43** | 0 | 100 | — |

### util_mbedtls_test

| Configuration | Total Tests | Passed | Failed |
|---|---|---|---|
| SVP=ON  | 13 | **13** | 0 |
| SVP=OFF | 13 | **13** | 0 |

### util_openssl_test

| Configuration | Total Tests | Passed | Failed |
|---|---|---|---|
| SVP=ON  | 2 | **2** | 0 |
| SVP=OFF | 2 | **2** | 0 |

All util tests require `root_keystore.p12` in the working directory.
Deploy it alongside the test binaries:

```bash
scp root_keystore.p12 root@<target>:/opt/mbedtls261/
```

### Known Failures — CENC Timing

All CENC timing failures are in the `*ProcessCommonEncryptionTests_1000000` test suites
(both `SaProcessCommonEncryptionTests_1000000` in saclienttest and
`TaProcessCommonEncryptionTests_1000000` in taimpltest).
These tests decrypt **1 MB of CENC data** and assert that decryption completes
within a timing threshold (`ASSERT_LE(duration.count(), sample_time)`).

On ARM32 hardware the decryption is functionally correct but exceeds the
timing threshold, causing assertion failures:

**saclienttest:**
- SVP=OFF: 72 failures (72 parameter combinations)
- SVP=ON: 216 failures (72 combinations × 3 SVP offset variants: `(0,0)`, `(1,0)`, `(1,1)`)

**taimpltest:**
- SVP=ON: 72 failures (72 parameter combinations, single SVP offset variant)

These are **not correctness bugs** — the decryption output is verified via
SHA-256 digest check (`ta_sa_svp_buffer_check`) and is correct. The timing
threshold (10 ms for 1 MB) was calibrated for faster hardware.

To eliminate all CENC timing failures, add `-DDISABLE_CENC_TIMING=ON` to
`EXTRA_OECMAKE` in the recipe and do a clean rebuild. This skips the timing
assertions entirely — all 216 (SVP=ON) or 72 (SVP=OFF) failures will be gone,
bringing the failure count to **0**.

## Dependency Management

The recipe's `do_fetch_deps` task parses `cmake/deps.cmake` (single source of
truth) and clones all 5 dependencies on the build server:

- mbedtls, yajl, libdecaf, ed25519-donna, curve25519-donna
