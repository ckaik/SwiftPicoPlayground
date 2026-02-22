/// Represents an incoming HTTP request passed to route handlers.
///
/// - Note: Path matching is case-sensitive and trailing-slash-sensitive.
/// - Warning: `queryValue(for:)` returns raw query values and does not perform
///   percent-decoding.
public struct HTTPRequest {
  public let method: HTTPMethod
  public let path: String
  public let query: String
  public let headers: [HTTPHeader]
  public let body: [UInt8]
  public let pathParameters: [String: String]

  public init(
    method: HTTPMethod,
    path: String,
    query: String,
    headers: [HTTPHeader],
    body: [UInt8],
    pathParameters: [String: String] = [:]
  ) {
    self.method = method
    self.path = path
    self.query = query
    self.headers = headers
    self.body = body
    self.pathParameters = pathParameters
  }

  /// Returns the first header value matching `name`.
  ///
  /// Header-name matching is ASCII case-insensitive.
  public func header(named name: String) -> String? {
    guard !name.isEmpty else { return nil }

    for header in headers where asciiCaseInsensitiveEquals(header.field, name) {
      return header.value
    }

    return nil
  }

  /// Returns the first value for `name` from the raw query string.
  ///
  /// - Note: Query parsing is lightweight and does not percent-decode keys or values.
  /// - Note: A key without `=` returns an empty string value.
  public func queryValue(for name: String) -> String? {
    guard !name.isEmpty, !query.isEmpty else { return nil }

    for entry in query.split(separator: "&", omittingEmptySubsequences: false) {
      if entry.isEmpty {
        continue
      }

      let parts = entry.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
      let key = String(parts[0])
      if key != name {
        continue
      }

      if parts.count == 2 {
        return String(parts[1])
      }

      return ""
    }

    return nil
  }

  /// Decodes the request body as UTF-8 text, returning `nil` if decoding fails.
  public func bodyString() -> String? {
    String(validating: body, as: UTF8.self)
  }

  /// Decodes the request body as JSON into `type` using the embedded JSON decoder.
  ///
  /// - Parameters:
  ///   - type: The `JSONDecodable` type to decode.
  ///   - decoder: The decoder configuration to apply while decoding.
  /// - Returns: A decoded value of `type`.
  /// - Throws: `JSONDecodingError` when decoding fails.
  /// - Note: This API is designed for Embedded Swift and uses `JSONDecodable`.
  /// - Warning: This method does not validate the `Content-Type` header.
  public func decodeJSON<T: JSONDecodable>(
    _ type: T.Type = T.self,
    using decoder: JSONDecoder = .init()
  ) throws(JSONDecodingError) -> T {
    try decoder.decode(type, from: body)
  }
}

extension HTTPRequest {
  func setting(
    method: HTTPMethod? = nil, pathParameters: [String: String]? = nil
  ) -> HTTPRequest {
    HTTPRequest(
      method: method ?? self.method,
      path: path,
      query: query,
      headers: headers,
      body: body,
      pathParameters: pathParameters ?? self.pathParameters
    )
  }
}
