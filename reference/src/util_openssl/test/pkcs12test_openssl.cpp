/*
 * Copyright 2020-2023 Comcast Cable Communications Management, LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include "pkcs12.h" // NOLINT
#include "common.h"
#include "root_keystore.h"
#include "gtest/gtest.h"
#include <cstdlib>

namespace {
    TEST(Pkcs12TestOpenSSL, parsePkcs12) {
        uint8_t key[SYM_256_KEY_SIZE];
        size_t key_length = SYM_256_KEY_SIZE;
        char name[MAX_NAME_SIZE];
        size_t name_length = MAX_NAME_SIZE;
        name[0] = '\0';

        printf("Using OpenSSL PKCS#12 API with embedded keystore\n");
        ASSERT_EQ(load_pkcs12_secret_key(key, &key_length, name, &name_length), true);
        ASSERT_EQ(key_length, SYM_128_KEY_SIZE);
        ASSERT_EQ(name_length, 16);
        ASSERT_EQ(memcmp(name, "fffffffffffffffe", 16), 0);
    }

    TEST(Pkcs12TestOpenSSL, parsePkcs12Common) {
        uint8_t key[SYM_256_KEY_SIZE];
        size_t key_length = SYM_256_KEY_SIZE;
        char name[MAX_NAME_SIZE];
        size_t name_length = MAX_NAME_SIZE;
        strcpy(name, COMMON_ROOT_NAME);

        printf("Using OpenSSL PKCS#12 API with embedded keystore (commonroot)\n");
        ASSERT_EQ(load_pkcs12_secret_key(key, &key_length, name, &name_length), true);
        ASSERT_EQ(key_length, SYM_128_KEY_SIZE);
        ASSERT_EQ(name_length, 10);
        ASSERT_EQ(memcmp(name, "commonroot", 10), 0);
    }
} // namespace
