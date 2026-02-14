#ifndef MONGOOSE_SWIFT_H
#define MONGOOSE_SWIFT_H

#include "mongoose.h"

// Swift cannot import macros defined inside structs. Re-export as enum constants.
#ifdef MG_WIFI_SECURITY_OPEN
#undef MG_WIFI_SECURITY_OPEN
#endif
#ifdef MG_WIFI_SECURITY_WEP
#undef MG_WIFI_SECURITY_WEP
#endif
#ifdef MG_WIFI_SECURITY_WPA
#undef MG_WIFI_SECURITY_WPA
#endif
#ifdef MG_WIFI_SECURITY_WPA2
#undef MG_WIFI_SECURITY_WPA2
#endif
#ifdef MG_WIFI_SECURITY_WPA3
#undef MG_WIFI_SECURITY_WPA3
#endif

enum {
  MG_WIFI_SECURITY_OPEN = 0,
  MG_WIFI_SECURITY_WEP = 1 << 0,
  MG_WIFI_SECURITY_WPA = 1 << 1,
  MG_WIFI_SECURITY_WPA2 = 1 << 2,
  MG_WIFI_SECURITY_WPA3 = 1 << 3
};

#endif  // MONGOOSE_SWIFT_H
