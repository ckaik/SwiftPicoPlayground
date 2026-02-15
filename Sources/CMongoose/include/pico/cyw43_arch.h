// Shim for "pico/cyw43_arch.h"
// Declares CYW43 architecture-level functions used by Mongoose's Pico W driver.
// Real implementations are in the Pico SDK .a libraries.
#pragma once

#include <stdint.h>

int  cyw43_arch_init(void);
void cyw43_arch_poll(void);
void cyw43_arch_enable_sta_mode(void);
void cyw43_arch_disable_sta_mode(void);
void cyw43_arch_enable_ap_mode(const char *ssid, const char *password,
                               uint32_t auth);
void cyw43_arch_disable_ap_mode(void);
int  cyw43_arch_wifi_connect_async(const char *ssid, const char *pw,
                                   uint32_t auth);
