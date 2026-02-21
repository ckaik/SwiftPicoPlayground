#ifndef MONGOOSE_SWIFT_H
#define MONGOOSE_SWIFT_H

#include "mongoose.h"

void swift_mg_http_reply(
    struct mg_connection *conn, int status_code, const char *headers,
    const char *body);

bool swift_mg_format_double(double value, char *buffer, size_t buffer_len);

#endif  // MONGOOSE_SWIFT_H
