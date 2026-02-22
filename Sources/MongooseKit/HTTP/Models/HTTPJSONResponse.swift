/// A typed JSON response wrapper for route handlers that return `JSONEncodable` bodies.
///
/// Use this type with `HTTPServer` JSON convenience routes to express response status,
/// headers, and body separately while deferring JSON serialization to the server.
///
/// - Note: `encode(using:)` delegates to `HTTPResponse.json(...)`, which ensures
///   `Content-Type: application/json` is present unless already provided.
public struct HTTPJSONResponse<Body: JSONEncodable> {
  public let status: HTTPStatus
  public let headers: [HTTPHeader]
  public let body: Body

  /// Creates a typed JSON response wrapper.
  ///
  /// - Parameters:
  ///   - status: The HTTP status code to use. Defaults to `.ok`.
  ///   - headers: Additional response headers.
  ///   - body: The typed JSON body value.
  public init(status: HTTPStatus = .ok, headers: [HTTPHeader] = [], body: Body) {
    self.status = status
    self.headers = headers
    self.body = body
  }

  /// Encodes the typed JSON body into an `HTTPResponse`.
  ///
  /// - Parameter encoder: The JSON encoder configuration to use.
  /// - Returns: A concrete `HTTPResponse` with an encoded JSON body.
  /// - Throws: `JSONEncodingError` when encoding fails.
  /// - Note: If `headers` does not include `Content-Type` (ASCII
  ///   case-insensitive), `application/json` is appended automatically.
  public func encode(using encoder: JSONEncoder = .init()) throws(JSONEncodingError) -> HTTPResponse
  {
    try HTTPResponse.json(
      status: status,
      headers: headers,
      body: body,
      encoder: encoder
    )
  }
}
