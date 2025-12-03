/*
 * Copyright 2020-2025 Comcast Cable Communications Management, LLC
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

#ifndef TA_SA_KEY_PROVISION_H
#define TA_SA_KEY_PROVISION_H

#include "sa_types.h"
#include "internal/client_store.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Provision a Widevine OEM key.
 *
 * @param[in] in WidevineOemProvisioning structure.
 * @param[in] parameters import parameters.
 * @param[in] client Client context.
 * @param[in] caller_uuid Caller UUID.
 * @return Operation status.
 */
sa_status ta_sa_key_provision_widevine(
    const void* in,
    const void* parameters,
    client_t* client,
    const sa_uuid* caller_uuid);

/**
 * Provision a PlayReady model key.
 *
 * @param[in] in PlayReadyProvisioning structure.
 * @param[in] parameters import parameters.
 * @param[in] client Client context.
 * @param[in] caller_uuid Caller UUID.
 * @return Operation status.
 */
sa_status ta_sa_key_provision_playready(
    const void* in,
    const void* parameters,
    client_t* client,
    const sa_uuid* caller_uuid);

/**
 * Provision Netflix keys.
 *
 * @param[in] in NetflixProvisioning structure.
 * @param[in] parameters import parameters.
 * @param[in] client Client context.
 * @param[in] caller_uuid Caller UUID.
 * @return Operation status.
 */
sa_status ta_sa_key_provision_netflix(
    const void* in,
    const void* parameters,
    client_t* client,
    const sa_uuid* caller_uuid);

#ifdef __cplusplus
}
#endif

#endif // TA_SA_KEY_PROVISION_H
