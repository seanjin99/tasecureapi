# Patch script to fix mbedTLS build warnings
# Adds __attribute__((unused)) to bignum.c variable
# Wraps string concatenations in parentheses (md5.c, ripemd160.c, sha512.c)
# Eliminates all 4 build warnings

# This file is called during ExternalProject_Add PATCH_COMMAND

# Fix bignum.c - unused variable warning
file(READ "${MBEDTLS_SOURCE_DIR}/library/bignum.c" BIGNUM_CONTENT)
string(REPLACE
    "void mpi_mul_hlp( size_t i, mbedtls_mpi_uint *s, mbedtls_mpi_uint *d, mbedtls_mpi_uint b )
{
    mbedtls_mpi_uint c = 0, t = 0;"
    "void mpi_mul_hlp( size_t i, mbedtls_mpi_uint *s, mbedtls_mpi_uint *d, mbedtls_mpi_uint b )
{
#if defined(__GNUC__) || defined(__clang__)
    mbedtls_mpi_uint c = 0, t __attribute__((unused)) = 0;
#else
    mbedtls_mpi_uint c = 0, t = 0;
#endif"
    BIGNUM_CONTENT "${BIGNUM_CONTENT}")
file(WRITE "${MBEDTLS_SOURCE_DIR}/library/bignum.c" "${BIGNUM_CONTENT}")

# Fix md5.c - string concatenation warning
file(READ "${MBEDTLS_SOURCE_DIR}/library/md5.c" MD5_CONTENT)
string(REPLACE
    "    { \"12345678901234567890123456789012345678901234567890123456789012\"\n      \"345678901234567890\" }"
    "    { (\"12345678901234567890123456789012345678901234567890123456789012\"\n      \"345678901234567890\") }"
    MD5_CONTENT "${MD5_CONTENT}")
file(WRITE "${MBEDTLS_SOURCE_DIR}/library/md5.c" "${MD5_CONTENT}")

# Fix ripemd160.c - string concatenation warning
file(READ "${MBEDTLS_SOURCE_DIR}/library/ripemd160.c" RIPEMD_CONTENT)
string(REPLACE
    "    { \"12345678901234567890123456789012345678901234567890123456789012\"\n      \"345678901234567890\" }"
    "    { (\"12345678901234567890123456789012345678901234567890123456789012\"\n      \"345678901234567890\") }"
    RIPEMD_CONTENT "${RIPEMD_CONTENT}")
file(WRITE "${MBEDTLS_SOURCE_DIR}/library/ripemd160.c" "${RIPEMD_CONTENT}")

# Fix sha512.c - string concatenation warning
file(READ "${MBEDTLS_SOURCE_DIR}/library/sha512.c" SHA512_CONTENT)
string(REPLACE
    "    { \"abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmn\"\n      \"hijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu\" }"
    "    { (\"abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmn\"\n      \"hijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu\") }"
    SHA512_CONTENT "${SHA512_CONTENT}")
file(WRITE "${MBEDTLS_SOURCE_DIR}/library/sha512.c" "${SHA512_CONTENT}")

message(STATUS "Applied mbedTLS build warning fixes")
