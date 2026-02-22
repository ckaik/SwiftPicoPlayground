public struct HTTPResponse {
  public let status: HTTPStatus
  public let headers: [HTTPHeader]
  public let body: String

  public init(status: HTTPStatus, headers: [HTTPHeader] = [], body: String) {
    self.status = status
    self.headers = headers
    self.body = body
  }

  /// Creates a JSON response from an embedded `JSONEncodable` value.
  ///
  /// - Parameters:
  ///   - status: The response status code. Defaults to `.ok`.
  ///   - headers: Additional headers to include.
  ///   - body: The value to encode as JSON.
  ///   - encoder: The encoder configuration to use for JSON serialization.
  /// - Returns: A response with a JSON body.
  /// - Throws: `JSONEncodingError` when JSON encoding fails.
  /// - Note: If `headers` does not include `Content-Type` (ASCII
  ///   case-insensitive), `application/json` is appended automatically.
  /// - Note: Encoding errors are intentionally surfaced to let callers decide
  ///   their own fallback response mapping.
  public static func json<T: JSONEncodable>(
    status: HTTPStatus = .ok,
    headers: [HTTPHeader] = [],
    body: T,
    encoder: JSONEncoder = .init()
  ) throws(JSONEncodingError) -> HTTPResponse {
    let encodedBody = try encoder.encodeString(body)
    var responseHeaders = headers

    if !responseHeaders.contains(where: { header in
      asciiCaseInsensitiveEquals(header.field, "Content-Type")
    }) {
      responseHeaders.append(HTTPHeader("Content-Type", value: "application/json"))
    }

    return HTTPResponse(status: status, headers: responseHeaders, body: encodedBody)
  }
}

extension HTTPResponse {
  func headerString() -> String {
    var headersString = ""
    for header in headers {
      headersString += "\(header.field): \(header.value)\r\n"
    }
    return headersString
  }
}
