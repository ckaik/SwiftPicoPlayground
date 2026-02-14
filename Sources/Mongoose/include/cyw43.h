// Shim for "cyw43.h"
// Provides CYW43 types, constants, and function declarations needed by
// Mongoose's built-in Pico W driver. Struct definitions are extracted from
// the Pico SDK's CYW43 driver headers; struct netif and struct dhcp are
// opaque placeholders since Mongoose never accesses their fields directly.
//
// All non-inline functions link against the real Pico SDK .a libraries
// at the finalize step.
#pragma once

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

// ── lwIP opaque types ───────────────────────────────────────────────────────
// cyw43_t embeds lwIP's struct netif / struct dhcp by value. We must NOT
// define 'struct netif' or 'struct dhcp' here because Mongoose's built-in
// TCP/IP stack (net_builtin.c) defines its own 'struct dhcp' with real fields.
// Instead we use plain byte-array placeholders inside cyw43_t.  The exact
// sizes do not matter because Mongoose never allocates a cyw43_t; it only
// uses the extern cyw43_state provided by the SDK, and all fields accessed
// by inline helpers precede these opaque regions.

struct pbuf;  // forward declaration only

// ── CYW43 constants ────────────────────────────────────────────────────────

// Interface identifiers
enum {
    CYW43_ITF_STA,
    CYW43_ITF_AP,
};

// Link status
#define CYW43_LINK_DOWN     (0)
#define CYW43_LINK_JOIN     (1)
#define CYW43_LINK_NOIP     (2)
#define CYW43_LINK_UP       (3)
#define CYW43_LINK_FAIL     (-1)
#define CYW43_LINK_NONET    (-2)
#define CYW43_LINK_BADAUTH  (-3)

// Authentication modes
#define CYW43_AUTH_OPEN              (0)
#define CYW43_AUTH_WPA_TKIP_PSK      (0x00200002)
#define CYW43_AUTH_WPA2_AES_PSK      (0x00400004)
#define CYW43_AUTH_WPA2_MIXED_PSK    (0x00400006)
#define CYW43_AUTH_WPA3_SAE_AES_PSK  (0x01000004)
#define CYW43_AUTH_WPA3_WPA2_AES_PSK (0x01400004)

// Channel
#define CYW43_CHANNEL_NONE  (0xffffffff)

// Low-level driver sizing
#define CYW43_BACKPLANE_READ_PAD_LEN_BYTES 16
#define CYW43_INCLUDE_LEGACY_F1_OVERFLOW_WORKAROUND_VARIABLES 0
#define CYW43_LL_STATE_SIZE_WORDS \
    (526 + 1 + ((CYW43_BACKPLANE_READ_PAD_LEN_BYTES / 4) + 1) + \
     CYW43_INCLUDE_LEGACY_F1_OVERFLOW_WORKAROUND_VARIABLES * 4)

// ── CYW43 types ────────────────────────────────────────────────────────────

typedef struct _cyw43_ev_scan_result_t {
    uint32_t _0[5];
    uint8_t bssid[6];
    uint16_t _1[2];
    uint8_t ssid_len;
    uint8_t ssid[32];
    uint32_t _2[5];
    uint16_t channel;
    uint16_t _3;
    uint8_t auth_mode;
    int16_t rssi;
} cyw43_ev_scan_result_t;

typedef struct _cyw43_wifi_scan_options_t {
    uint32_t version;
    uint16_t action;
    uint16_t _;
    uint32_t ssid_len;
    uint8_t ssid[32];
    uint8_t bssid[6];
    int8_t bss_type;
    int8_t scan_type;
    int32_t nprobes;
    int32_t active_time;
    int32_t passive_time;
    int32_t home_time;
    int32_t channel_num;
    uint16_t channel_list[1];
} cyw43_wifi_scan_options_t;

typedef struct _cyw43_ll_t {
    uint32_t opaque[CYW43_LL_STATE_SIZE_WORDS];
} cyw43_ll_t;

typedef struct _cyw43_t {
    cyw43_ll_t cyw43_ll;
    uint8_t itf_state;
    uint32_t trace_flags;
    volatile uint32_t wifi_scan_state;
    uint32_t wifi_join_state;
    void *wifi_scan_env;
    int (*wifi_scan_cb)(void *, const cyw43_ev_scan_result_t *);
    bool initted;
    bool pend_disassoc;
    bool pend_rejoin;
    bool pend_rejoin_wpa;
    uint32_t ap_auth;
    uint8_t ap_channel;
    uint8_t ap_ssid_len;
    uint8_t ap_key_len;
    uint8_t ap_ssid[32];
    uint8_t ap_key[64];
    char _netif_opaque[2][64];   // placeholder for lwIP struct netif[2]
    char _dhcp_client_opaque[56]; // placeholder for lwIP struct dhcp
    uint8_t mac[6];
} cyw43_t;

// ── Global state ───────────────────────────────────────────────────────────

extern cyw43_t cyw43_state;
extern void (*cyw43_poll)(void);
extern uint32_t cyw43_sleep;

// ── Static inline functions (need full struct) ─────────────────────────────

static inline bool cyw43_wifi_scan_active(cyw43_t *self) {
    return self->wifi_scan_state == 1;
}

static inline void cyw43_wifi_ap_set_channel(cyw43_t *self, uint32_t channel) {
    self->ap_channel = (uint8_t)channel;
}

static inline void cyw43_wifi_ap_set_ssid(cyw43_t *self, size_t len,
                                          const uint8_t *buf) {
    self->ap_ssid_len =
        (uint8_t)(sizeof(self->ap_ssid) > len ? len : sizeof(self->ap_ssid));
    memcpy(self->ap_ssid, buf, self->ap_ssid_len);
}

static inline void cyw43_wifi_ap_set_password(cyw43_t *self, size_t len,
                                              const uint8_t *buf) {
    self->ap_key_len =
        (uint8_t)(sizeof(self->ap_key) > len ? len : sizeof(self->ap_key));
    memcpy(self->ap_key, buf, self->ap_key_len);
}

static inline void cyw43_wifi_ap_set_auth(cyw43_t *self, uint32_t auth) {
    self->ap_auth = auth;
}

static inline bool cyw43_is_initialized(cyw43_t *self) {
    return self->initted;
}

// ── Regular functions (link-time resolved) ─────────────────────────────────

void cyw43_init(cyw43_t *self);
void cyw43_deinit(cyw43_t *self);

int  cyw43_send_ethernet(cyw43_t *self, int itf, size_t len, const void *buf,
                         bool is_pbuf);
int  cyw43_wifi_get_mac(cyw43_t *self, int itf, uint8_t mac[6]);
int  cyw43_wifi_link_status(cyw43_t *self, int itf);
int  cyw43_wifi_update_multicast_filter(cyw43_t *self, uint8_t *addr,
                                        bool add);
int  cyw43_wifi_scan(cyw43_t *self, cyw43_wifi_scan_options_t *opts, void *env,
                     int (*result_cb)(void *, const cyw43_ev_scan_result_t *));

// ── Callback declarations (Mongoose implements these) ──────────────────────

void cyw43_cb_process_ethernet(void *cb_data, int itf, size_t len,
                               const uint8_t *buf);
void cyw43_cb_tcpip_set_link_up(cyw43_t *self, int itf);
void cyw43_cb_tcpip_set_link_down(cyw43_t *self, int itf);
