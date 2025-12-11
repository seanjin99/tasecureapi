/**
 * \file ctr.h
 *
 * \brief    This file contains common functionality for counter algorithms.
 *
 *  Copyright The Mbed TLS Contributors
 *  SPDX-License-Identifier: Apache-2.0 OR GPL-2.0-or-later
 *
 *  BACKPORT NOTE: This file is backported from mbedTLS 3.6.2 (commit 591ff05)
 *  for CTR counter performance optimization only.
 */

#ifndef MBEDTLS_CTR_H
#define MBEDTLS_CTR_H

#include <stdint.h>

/* Compatibility layer for mbedTLS 2.16.10 */
#ifndef MBEDTLS_GET_UINT32_BE
/* Manual big-endian 32-bit read */
#define MBEDTLS_GET_UINT32_BE(data, offset)                        \
    (  ((uint32_t) (data)[(offset)    ] << 24)                     \
     | ((uint32_t) (data)[(offset) + 1] << 16)                     \
     | ((uint32_t) (data)[(offset) + 2] <<  8)                     \
     | ((uint32_t) (data)[(offset) + 3]      ) )
#endif

#ifndef MBEDTLS_PUT_UINT32_BE
/* Manual big-endian 32-bit write */
#define MBEDTLS_PUT_UINT32_BE(n, data, offset)                     \
    do {                                                            \
        (data)[(offset)    ] = (unsigned char) ( (n) >> 24 );      \
        (data)[(offset) + 1] = (unsigned char) ( (n) >> 16 );      \
        (data)[(offset) + 2] = (unsigned char) ( (n) >>  8 );      \
        (data)[(offset) + 3] = (unsigned char) ( (n)       );      \
    } while( 0 )
#endif

/**
 * \brief               Increment a big-endian 16-byte value.
 *                      Performance optimization for AES-CTR and CTR-DRBG.
 *
 * \param n             A 16-byte value to be incremented.
 */
static inline void mbedtls_ctr_increment_counter(uint8_t n[16])
{
    // The 32-bit version seems to perform about the same as a 64-bit version
    // on 64-bit architectures, so no need to define a 64-bit version.
    // Loop from most significant to least significant 32-bit word.
    for (int i = 3;; i--) {
        uint32_t x = MBEDTLS_GET_UINT32_BE(n, i << 2);
        x += 1;
        MBEDTLS_PUT_UINT32_BE(x, n, i << 2);
        // Break if no carry (x wrapped to 0) OR if we processed the last word
        if (x != 0 || i == 0) {
            break;
        }
    }
}

#endif /* MBEDTLS_CTR_H */
