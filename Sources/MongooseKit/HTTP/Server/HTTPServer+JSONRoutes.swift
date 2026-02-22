extension HTTPServer {
  /// Registers a route handler that decodes the request body as JSON.
  ///
  /// ```swift
  /// @JSONDecodable
  /// struct ToggleCommand {
  ///   let on: Bool
  /// }
  ///
  /// server.on(.post, "/lights/:id") { request, command in
  ///   let id = request.pathParameters["id"] ?? "unknown"
  ///   return HTTPResponse(status: .ok, body: "updated \(id): \(command.on)")
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - method: The HTTP method to match.
  ///   - path: The route pattern, e.g. `/lights/:id`.
  ///   - decoder: The JSON decoder configuration to apply to the request body.
  ///   - handler: Invoked only when JSON decoding succeeds.
  /// - Returns: `self` to support call chaining.
  /// - Note: Route registration and path normalization follow `on(_:_:handler:)`.
  /// - Warning: This helper does not validate `Content-Type`; it always attempts
  ///   to decode the body as JSON.
  /// - Note: If decoding fails, a `400 Bad Request` plain-text response is
  ///   returned and `handler` is not invoked.
  @discardableResult
  public func on<T: JSONDecodable>(
    _ method: HTTPMethod,
    _ path: String,
    decoder: JSONDecoder = .init(),
    handler: @escaping (HTTPRequest, T) -> HTTPResponse
  ) -> Self {
    on(method, path) { request in
      guard let decoded = try? request.decodeJSON(T.self, using: decoder) else {
        return Self.plainTextResponse(status: .badRequest, body: "Bad Request")
      }

      return handler(request, decoded)
    }
  }

  /// Registers a route handler that decodes request JSON and encodes a typed JSON response.
  ///
  /// ```swift
  /// @JSONDecodable
  /// struct ToggleCommand {
  ///   let on: Bool
  /// }
  ///
  /// @JSONEncodable
  /// struct ToggleResult {
  ///   let id: String
  ///   let on: Bool
  /// }
  ///
  /// server.on(.post, "/lights/:id") { request, command in
  ///   let id = request.pathParameters["id"] ?? "unknown"
  ///   return HTTPJSONResponse(body: ToggleResult(id: id, on: command.on))
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - method: The HTTP method to match.
  ///   - path: The route pattern, e.g. `/lights/:id`.
  ///   - decoder: The JSON decoder configuration to apply to the request body.
  ///   - encoder: The JSON encoder configuration to apply to the response body.
  ///   - handler: Invoked only when request JSON decoding succeeds.
  /// - Returns: `self` to support call chaining.
  /// - Note: Route registration and path normalization follow `on(_:_:handler:)`.
  /// - Warning: This helper does not validate `Content-Type`; it always attempts
  ///   to decode the body as JSON.
  /// - Note: If request decoding fails, this returns `400 Bad Request` as plain
  ///   text and does not invoke `handler`.
  /// - Note: Successful responses are encoded with `HTTPJSONResponse.encode(using:)`,
  ///   which ensures `Content-Type: application/json` unless already present.
  /// - Warning: If response encoding fails, this logs the encoding error and
  ///   returns `500 Internal Server Error` as plain text.
  @discardableResult
  public func on<RequestBody: JSONDecodable, ResponseBody: JSONEncodable>(
    _ method: HTTPMethod,
    _ path: String,
    decoder: JSONDecoder = .init(),
    encoder: JSONEncoder = .init(),
    handler: @escaping (HTTPRequest, RequestBody) -> HTTPJSONResponse<ResponseBody>
  ) -> Self {
    let port = self.port
    return on(method, path, decoder: decoder) { (request: HTTPRequest, decoded: RequestBody) in
      let jsonResponse = handler(request, decoded)

      do {
        return try jsonResponse.encode(using: encoder)
      } catch let error as JSONEncodingError {
        Self.logJSONEncodingFailure(
          port: port,
          request: request,
          errorDescription: "\(error)"
        )
        return Self.plainTextResponse(
          status: .internalServerError,
          body: "Internal Server Error"
        )
      } catch {
        Self.logJSONEncodingFailure(
          port: port,
          request: request,
          errorDescription: "\(error)"
        )
        return Self.plainTextResponse(
          status: .internalServerError,
          body: "Internal Server Error"
        )
      }
    }
  }
}
