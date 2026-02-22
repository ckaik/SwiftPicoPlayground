import CMongoose

extension HTTPServer {
  struct RequestContext {
    let request: HTTPRequest
    let pathSegments: [String]
  }

  static func makeRequestContext(from message: mg_http_message) -> RequestContext? {
    guard
      let rawMethod = decodeString(message.method, allowEmpty: false),
      let method = HTTPMethod(rawValue: asciiUppercased(rawMethod)),
      let path = decodeString(message.uri, allowEmpty: false),
      let query = decodeString(message.query, allowEmpty: true),
      let headers = decodeHeaders(from: message),
      let pathSegments = parsePathSegments(path)
    else {
      return nil
    }

    let request = HTTPRequest(
      method: method,
      path: path,
      query: query,
      headers: headers,
      body: message.body.toByteArray()
    )

    return RequestContext(request: request, pathSegments: pathSegments)
  }

  static func decodeString(_ value: mg_str, allowEmpty: Bool) -> String? {
    if value.len == 0 {
      return allowEmpty ? "" : nil
    }

    return value.toString()
  }

  static func decodeHeaders(from message: mg_http_message) -> [HTTPHeader]? {
    var headers: [HTTPHeader] = []
    var isInvalid = false

    withUnsafePointer(to: message.headers) { tuplePointer in
      let base = UnsafeRawPointer(tuplePointer).assumingMemoryBound(to: mg_http_header.self)
      let maxHeaders = Int(MG_MAX_HTTP_HEADERS)

      for index in 0 ..< maxHeaders {
        let header = base[index]
        if header.name.len == 0 {
          break
        }

        guard
          let field = decodeString(header.name, allowEmpty: false),
          let value = decodeString(header.value, allowEmpty: true)
        else {
          isInvalid = true
          break
        }

        headers.append(HTTPHeader(field, value: value))
      }
    }

    return isInvalid ? nil : headers
  }

  static func parsePathSegments(_ path: String) -> [String]? {
    guard path.hasPrefix("/") else {
      return nil
    }

    if path == "/" {
      return []
    }

    return path.dropFirst().split(separator: "/", omittingEmptySubsequences: false).map(String.init)
  }
}
