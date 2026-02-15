// Shim for <pico/stdlib.h>
// Provides the minimal declarations Mongoose needs from the Pico SDK.
// Real implementations are in the Pico SDK .a libraries linked by
// the FinalizeBinaryPlugin.
#pragma once

#include <stdint.h>
#include <sys/types.h>  // mode_t (used by mongoose.h's mkdir declaration)

uint64_t time_us_64(void);
void sleep_ms(uint32_t ms);
