// Shim for <pico/rand.h>
// Provides get_rand_32() used by Mongoose's mg_random() for MG_ARCH_PICOSDK.
#pragma once

#include <stdint.h>

uint32_t get_rand_32(void);
