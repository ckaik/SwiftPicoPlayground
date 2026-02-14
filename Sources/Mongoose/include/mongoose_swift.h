#ifndef MONGOOSE_SWIFT_H
#define MONGOOSE_SWIFT_H

#include "mongoose.h"

void swift_mg_http_reply(struct mg_connection *conn, int status_code, const char *headers, const char *body) {
  mg_http_reply(conn, status_code, headers, body);
}

#endif  // MONGOOSE_SWIFT_H
