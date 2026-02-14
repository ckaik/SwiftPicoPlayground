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

void swift_mg_http_reply(struct mg_connection *conn, int status_code, const char *headers, const char *body) {
  mg_http_reply(conn, status_code, headers, body);
}

#endif  // MONGOOSE_SWIFT_H
