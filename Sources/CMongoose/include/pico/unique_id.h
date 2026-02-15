// Shim for "pico/unique_id.h"
// Provides board unique ID types/functions used by the Mongoose Pico W driver.
#pragma once

#include <stdint.h>

#ifndef PICO_UNIQUE_BOARD_ID_SIZE_BYTES
#define PICO_UNIQUE_BOARD_ID_SIZE_BYTES 8
#endif

typedef struct {
    uint8_t id[PICO_UNIQUE_BOARD_ID_SIZE_BYTES];
} pico_unique_board_id_t;

void pico_get_unique_board_id(pico_unique_board_id_t *id_out);
void pico_get_unique_board_id_string(char *id_out, unsigned int len);
