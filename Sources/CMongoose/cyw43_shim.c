#include "include/cyw43.h"

int __attribute__((weak)) cyw43_tcpip_link_status(cyw43_t *self, int itf) {
  return cyw43_wifi_link_status(self, itf);
}
