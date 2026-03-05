# Security API

## Table of Contents

1. [Introduction](#introduction)
2. [Terms and Definitions](#terms-and-definitions)
3. [SecAPI Overview](#secapi-overview)
4. [Build](#build)
5. [Source Structure](#source-structure)
6. [Sample Use Cases](#sample-use-cases)
7. [Robustness Rules](#robustness-rules)
8. [References](#references)

## Introduction

The Security API (SecAPI) provides a cryptographic interface for video devices to support a common
set of robustness requirements for video content protection.

The Security API (SecAPI) provides a thread-safe C-type interface to cryptographic and key
management operations. The API enables applications to use keys and secret data without exposing
sensitive data and keys.

The processing environment for applications includes two environments: a Rich Execution Environment
(REE) and a Trusted Execution Environment (TEE). The API is implemented as a Trusted Application
(TA) in the TEE. The TEE ensures that device, application, and protocol secrets are not compromised.

The API may be invoked from client applications running in the REE or from other TAs that are
running in the TEE. The API is expected to support in-field provisioning of device credentials and
keys, including credentials and keys required for:

* Device activation and authentication (on X1 as well as for OTT partners, e.g. Netflix).
* Secure communication (e.g. TLS).
* DRM individualization (e.g. Widevine).

## Terms and Definitions

The following terms are used:

* `Client Application` An application running outside the TEE making use of the TEE API to access
  facilities and functions provided by Trusted Applications inside the TEE.
* `Client Key` A key that may be used by client applications using the SecAPI. Client keys are
  derived from a root key using a four-stage key ladder, or are derived from another client key, or
  are unwrapped by a SecAPI key or another client key. Intermediate stages of the key ladder are not
  observable or modifiable outside the SecAPI TA. Clear key client keys may also be loaded.
* `Execution Environment` A set of hardware and software components providing facilities necessary
  to support running of applications.
* `Host Processor` The general-purpose processor in the SoC to run client application software. The
  host processor is a component of the REE.
* `Key Container` A data structure that contains a key, metadata, and a signature to authenticate
  the key. The metadata typically includes a description of the key and associated key usage rights.
  The key is typically encrypted such that the plain-text value is accessible only in a TEE. The key
  container may be created by a key provisioning service to provision keys to the device in the
  field, and may be created by the device to export a key from the SecAPI TA for storage outside the
  TEE.
* `Key Derivation Function` A function that, with a key and other data as inputs, generates a
  symmetric key.
* `Key Ladder` A chain of cryptographic operations such that each operation gets its key from the
  output of the previous operation. The result of the final operation is a key that can be used for
  general cryptographic operations (e.g. to decrypt content). Intermediate stages of the key ladder
  are not observable or modifiable outside the SecAPI TA.
* `Key Rights` Uses that are authorized for a key (e.g. data decryption, key unwrapping). Key rights
  in this API also include restrictions on when a decryption key may be used, specifically
  restrictions based on available video output ports (e.g. a decryption key may only be used if HDCP
  2.2 is enforced on the video output).
* `Key Wrapping` A method of encrypting a key, along with key usage information and integrity
  information, that provides confidentiality and integrity protection.
* `Load Key` Decrypt or import a key for use by the SecAPI TA.
* `OTP` One time programmable.
* `Rich Execution Environment` An environment that is provided and governed by a typical OS (e.g.
  Linux, Android, iOS) outside the TEE. This environment and any applications running on it are
  considered untrusted.
* `Root Key` A device unique secret key stored in OTP. A root key is not observable by access
  outside the TEE. A root key is used as the first stage in the device key ladder.
* `SecAPI Key` A key that is derived from a root key using a three-stage key ladder. Intermediate
  stages of the key ladder are not observable or modifiable outside the SecAPI TA. A SecAPI key
  cannot be used by client applications or other TAs. That is, only the SecAPI can use a SecAPI key.
* `Secure Video Path` An end-to-end video path (decrypted compressed content to rendering/output)
  that is hardware isolated such that the decrypted content is protected from unauthorized software
  and hardware. Content cannot be read or accessed by unauthorized software or hardware.
* `Trusted Application` An application that runs in a TEE.
* `Trusted Execution Environment` An environment that enforces that only authorized code can execute
  within the TEE, and data used by that code cannot be read or tampered with by code outside the
  TEE. The TEE uses an isolation mechanism to ensure that one TA cannot read, modify or delete the
  data and code of another TA.
* `Unwrap a Key` Decrypt a key with a second key.
* `Wrap a Key` Encrypt a key with a second key.

## SecAPI Overview

The SecAPI is implemented as a TA. The SecAPI TA exposes an interface to client applications in the
REE and an interface to other TAs in the TEE.

The SecAPI is a blocking API. That is, the API blocks while waiting for underlying tasks to complete
before returning execution control to the calling client application or TA.

The API exposes an interface to provide:

* [Key Management](#key-management)
* [Cryptographic Operations](#cryptographic-operations)
* [SVP Operations](#svp-operations)

### Key Management

The API provides the following key management capabilities:

* Key generation.
* Key agreement.
* Key derivation.
* Key unwrapping.
* Key export and import.
* Key provisioning.
* Enforcement of key usage rights and restrictions.

The API supports symmetric keys, RSA keys, ECC, and Diffie-Hellman (DH) keys.

Persistent storage of keys is out of scope for the API.

Key container formats are out of scope for the API. However, each key container definition must
support a capability to specify a list of TAs that are entitled to use the key contained in the
container. Each entitled TAs is identified by a TA UUID compliant with
[RFC 4122](https://tools.ietf.org/html/rfc4122).

Key containers used to provision keys for the SecAPI must use a SecAPI key to encrypt the keys that
are getting provisioned. Each such key container must be authenticated by a SecAPI key. When a key
provisioning service is used to provision SecAPI key containers in fielded devices, the service
depends on a priori knowledge of a key derived from the device's root key. This allows the key
provisioning service to subsequently derive the SecAPI keys used to encrypt the key carried in the
container as well as authenticate the container.

![Key Container Generation](./docs/diagrams/GenerateKeyContainer.png)

1. A keying center generates SoC root keys.
2. The keying center delivers the SoC root keys to the SoC manufacturer. The SoC manufacturer writes
   the root keys to SoC OTP memory.
3. The keying center performs the first stage derivation of a container encryption key and delivers
   the result to the key provisioning service.
4. The key provisioning service, starting with the first stage derived key, performs second and
   third stage derivation to generate the SecAPI key used to protect the confidentiality of a
   field-provisioned key delivered in a SecAPI key container.

### Cryptographic Operations

The API provides the following cryptographic capabilities:

| Category | Operations |
|---|---|
| Symmetric | AES-CBC, AES-ECB, AES-CTR, AES-GCM (128/256-bit) |
| Asymmetric | RSA (sign/verify, encrypt/decrypt, PKCS/OAEP padding, 1024–4096 bit), ECDSA (P-256, P-384, P-521), ECDH |
| Hashing | SHA-1, SHA-256, SHA-384, SHA-512 |
| MAC | HMAC (SHA-1, SHA-256, SHA-384, SHA-512), CMAC |
| KDF | HKDF, Concat KDF, multi-round KDF |
| Key Exchange | DH, ECDH (NIST curves), X25519, X448 |
| Signature | RSA-PSS, RSA-PKCS1v15, ECDSA, Ed25519, Ed448 |
| RNG | Random number generation |

Public key operations are out of scope for the API. Digest operations are also out of scope for the
API since digest operations do not require access to keys.

### SVP Operations

The API provides the following SVP capabilities:

* Protected buffer operations, including buffer allocation, deallocation, writes, and copies.
* AES cipher operations on data in protected buffers using CBC and CTR mode.

The SVP implementation must provide a mechanism to the SecAPI TA to determine whether SVP is
enforced. The SVP implementation must provide a mechanism to the SecAPI TA to determine whether an
SVP buffer is wholly contained within the restricted SVP memory region.

The control of HDCP and other outputs is out of scope for the API. This is the responsibility of an
HDCP TA, for example. The device must provide a mechanism to the SecAPI TA to determine what video
outputs are currently enabled.

## SecAPI Performance

It is the responsibility of the SoC vendor to optimize their implementation to reduce latency to
ensure sufficient decryption performance in order to prevent poor video playback quality issues.
This reference implementation is implemented with simple examples of how to perform cryptographic
operations using OpenSSL. It has not been optimized to provide the fastest possible cryptographic
operations.

## Build

### Prerequisites

- macOS (ARM64 or Intel) or Linux
- CMake 3.16+

All dependencies are automatically resolved during the build:
- **OpenSSL** — TLS Engine/Provider integration, test harness crypto verification; found on system if available, otherwise fetched from GitHub and built from source
- **mbedTLS** — primary cryptographic backend for the TA implementation (AES, RSA, ECC, hashing, HMAC, CMAC)
- **yajl** — JSON parsing for key containers and provisioning data
- **libdecaf** — Ed448/X448 elliptic curve operations (EdDSA signatures, ECDH key exchange)
- **ed25519-donna** — Ed25519 EdDSA signature operations
- **curve25519-donna** — X25519 ECDH key exchange operations

All library versions are defined in `reference/cmake/deps.cmake`.

### Native Build (macOS / Linux)

```bash
mkdir build && cd build
cmake .. -DENABLE_SVP=OFF -DCMAKE_BUILD_TYPE=Debug
make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu)
```

> **Note:** If OpenSSL is not installed on the system, CMake will fetch and build
> it from source. In this case you **must** use `make -j1` for the first build —
> parallel builds will fail because the OpenSSL build must complete before
> dependent targets can compile. Subsequent rebuilds can use `-j` normally.

### Build Flow (macOS / Linux)

```mermaid
flowchart TD
    subgraph "Native Build (macOS / Linux)"
        A[cmake ..] --> B{System OpenSSL found?}
        B -->|Yes| C[Use system OpenSSL]
        B -->|No| D[Fetch OpenSSL 3.x from GitHub & build]
        C --> E[Fetch deps via deps.cmake]
        D --> E
        E --> F["mbedTLS, yajl, libdecaf, ed25519-donna, curve25519-donna"]
        F --> G[make -j]
        G --> H[saclienttest / taimpltest / util_*_test]
    end
```

## Source Structure

All source code lives under `reference/src/`. The directory is organized into layered modules:

| Directory | Description |
|---|---|
| `client/` | Public API headers (`sa.h`, `sa_crypto.h`, `sa_key.h`, `sa_svp.h`, `sa_cenc.h`, etc.) and the client library. This is what applications include to use SecAPI. |
| `clientimpl/` | Client implementation that bridges the public API to the Trusted Application layer. Marshals/unmarshals data between REE client code and the TA. |
| `taimpl/` | Core Trusted Application implementation containing all cryptographic logic, key management, cipher/MAC/digest stores, and protocol-specific encryption (Netflix, CENC). Pluggable crypto backends live under `taimpl/src/internal/providers/` — mbedTLS, OpenSSL, libdecaf, ed25519-donna, and curve25519-donna. |
| `util/` | Shared utility library with **no crypto dependency**. Provides logging, digest helpers, and key-rights management used by all other modules. |
| `util_mbedtls/` | mbedTLS-specific utilities: PKCS8/PKCS12 key format parsing, digest wrappers, hardware RNG abstraction, and mbedTLS test helpers. Built when the mbedTLS backend is selected. |
| `util_openssl/` | OpenSSL-specific utilities: PKCS8/PKCS12 key format parsing, digest mechanism abstraction, and OpenSSL test helpers. Built when the OpenSSL backend is selected. |

```
reference/src/
├── client/          # Public API (sa.h, sa_crypto.h, sa_key.h, …)
├── clientimpl/      # REE ↔ TA bridge
├── taimpl/          # TA core + crypto providers
│   ├── include/     #   TA interface headers
│   ├── src/
│   │   ├── internal/        # Crypto logic (symmetric, rsa, ec, kdf, cenc, …)
│   │   │   └── providers/   # mbedtls/, openssl/, decaf/, ed25519-donna/, curve25519-donna/
│   │   └── porting/         # Platform-specific (init, rand, svp, transport)
│   └── test/        #   taimpltest
├── util/            # Logging, digest helpers (no crypto dep)
├── util_mbedtls/    # mbedTLS utilities + util_mbedtls_test
└── util_openssl/    # OpenSSL utilities + util_openssl_test
```

## Sample Use Cases

### In-Field Key Provisioning

The diagram below presents an overview of the role of the SecAPI TA in key provisioning.

![Key Provisioning](./docs/diagrams/KeyProvisioning.png)

1. A provisioning client application obtains a key container from the key provisioning service.
2. The provisioning application writes the key container to REE memory.
3. The SecAPI TA copies the key container into the TEE.
4. The SecAPI TA uses the root key ladder to derive the SecAPI key that is used to encrypt the key in
   the key container. The SecAPI TA decrypts the key and verifies the container authentication
   data.
5. The SecAPI generates an export key container and returns the export key container to the calling
   client application. The client application places the container in the file system for
   persistent storage.

### DRM License Acquisition

The diagram below presents an overview of the role of the SecAPI TA in DRM license acquisition.

![DRM License Acquisition](./docs/diagrams/LicenseAcquisition.png)

1. The player determines the media type and invokes the DRM TA to obtain a license request.
2. The DRM TA creates the license request and invokes the SecAPI to sign the request.
3. The SecAPI TA imports the DRM key, signs the license request, and returns the signed request to
   the DRM TA. The DRM TA provides the license request to the player.
4. The player obtains a license from the DRM license server.
5. The player provides the license to the DRM TA to process the license.
6. The DRM TA invokes the SecAPI TA to unwrap the content key.
7. The SecAPI unwraps the content key. The content key may be exported in an export key container
   if the use case requires persistent storage for the content key (i.e. if the content key is
   cacheable).

### SVP Content Decryption

The diagram below presents an overview of the role of the SecAPI TA in SVP content decryption. Prior
to content decryption a DRM TA acquires a license, unwraps the key and invokes the SecAPI TA to
export the content key for storage in the REE.

![SVP Content Decryption](./docs/diagrams/SvpDecryptionUseCase.png)

1. An SVP TA initializes the SVP.
2. The content key is imported by the SecAPI TA.
3. The encrypted compressed content is decrypted into an SVP buffer.
4. The SVP is configured to allow the decoder to access protected TEE memory. The decoder
   decompresses the video into an SVP buffer.
5. An HDCP TA outputs HDCP-protected video.

## Robustness Rules

Implementations of this API must conform to the following:

* SecAPI keys must be derived from a secret OTP root key. SecAPI keys must be derived by the SoC's
  hardware key ladder, or derived in the SecAPI TA.
* Derived, generated and unwrapped keys must not be observable or modifiable by access outside the
  SecAPI TA.
* Exported keys must be decrypted only in the SecAPI TA. Client applications must not be able to
  decrypt exported keys.
* Exported keys must be encrypted with a SecAPI key.
* Exported keys must be stored with an integrity mechanism. The SecAPI TA must not use a key if the
  integrity is compromised.
* Exported keys must not be observable or modifiable by access outside the SecAPI TA.
* Exported keys must maintain key usage rights. The usage rights must be cryptographically bound to
  the key.
* The SecAPI TA must not load or use a key if the usage rights compliance cannot be enforced or
  confirmed. For example, if specified output protections are not enabled, or cannot be confirmed,
  then the SecAPI TA must not load the key. Usage rights include entitled TA restrictions.
* The SecAPI TA must not embed clear keys in source code.
* Intermediate stages of key derivations, in either the key ladder or in a KDF, must not be
  observable or modifiable by access outside the SecAPI TA.
* TEE memory used to store plain-text keys must be isolated from other data memory. The SecAPI must
  protect plain-text keys in the TEE such that memory management functions cannot be used to expose
  keys to other TAs in the TEE.
* Cipher operations must be implemented in the TEE such that the key is not observable or modifiable
  during the operation by access external to the SecAPI TA.
* Client applications and TAs other than the SecAPI TA must be restricted to using a client key.
  Client applications and other TAs must not be able to use a SecAPI key. Client applications must
  not be able to re-derive a SecAPI key for its own use. That is, a client must not be able to use a
  three-stage key ladder to derive a key from a SecAPI root key.
* Key containers used to provision keys for the SecAPI must use a SecAPI key to encrypt the key. The
  key container must be authenticated by a SecAPI key.
* The SecAPI TA must have access to a device service that enables the SecAPI TA to determine whether
  SVP is configured and enabled.
* The SecAPI TA must have access to a device service that enables the SecAPI TA to determine what
  video outputs are currently enabled.

## References

[List Format Requirements for Markdown documentation](https://www.doxygen.nl/manual/lists.html)
