#include "include/mongoose_swift.h"

void swift_mg_http_reply(
    struct mg_connection *conn, int status_code, const char *headers,
    const char *body) {
  mg_http_reply(conn, status_code, headers, body);
}

bool swift_mg_format_double(double value, char *buffer, size_t buffer_len) {
  if (buffer == NULL || buffer_len == 0) return false;

  size_t written = mg_snprintf(buffer, buffer_len, "%.17g", value);
  return written > 0 && written < buffer_len;
}
