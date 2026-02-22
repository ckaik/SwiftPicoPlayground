extension HTTPServer {
  /// Registers a `GET` route.
  @discardableResult
  public func get(_ path: String, handler: @escaping HTTPRouteHandler) -> Self {
    on(.get, path, handler: handler)
  }

  /// Registers a `POST` route.
  @discardableResult
  public func post(_ path: String, handler: @escaping HTTPRouteHandler) -> Self {
    on(.post, path, handler: handler)
  }

  /// Registers a `POST` route that decodes the request body as JSON.
  ///
  /// - Parameters:
  ///   - path: The route pattern.
  ///   - decoder: The JSON decoder configuration to apply to the request body.
  ///   - handler: Invoked only when JSON decoding succeeds.
  /// - Returns: `self` to support call chaining.
  /// - Note: On decoding failure this returns a `400 Bad Request` plain-text
  ///   response and does not invoke `handler`.
  @discardableResult
  public func post<T: JSONDecodable>(
    _ path: String,
    decoder: JSONDecoder = .init(),
    handler: @escaping (HTTPRequest, T) -> HTTPResponse
  ) -> Self {
    on(.post, path, decoder: decoder, handler: handler)
  }

  /// Registers a `POST` route with JSON request decoding and typed JSON response encoding.
  ///
  /// - Parameters:
  ///   - path: The route pattern.
  ///   - decoder: The JSON decoder configuration to apply to the request body.
  ///   - encoder: The JSON encoder configuration to apply to the response body.
  ///   - handler: Invoked only when request JSON decoding succeeds.
  /// - Returns: `self` to support call chaining.
  /// - Note: On decode failure this returns `400 Bad Request` and skips `handler`.
  /// - Note: Successful responses ensure `Content-Type: application/json` unless
  ///   already present.
  /// - Warning: On response-encoding failure this logs the error and returns
  ///   `500 Internal Server Error`.
  @discardableResult
  public func post<RequestBody: JSONDecodable, ResponseBody: JSONEncodable>(
    _ path: String,
    decoder: JSONDecoder = .init(),
    encoder: JSONEncoder = .init(),
    handler: @escaping (HTTPRequest, RequestBody) -> HTTPJSONResponse<ResponseBody>
  ) -> Self {
    on(.post, path, decoder: decoder, encoder: encoder, handler: handler)
  }

  /// Registers a `PUT` route.
  @discardableResult
  public func put(_ path: String, handler: @escaping HTTPRouteHandler) -> Self {
    on(.put, path, handler: handler)
  }

  /// Registers a `PUT` route that decodes the request body as JSON.
  ///
  /// - Parameters:
  ///   - path: The route pattern.
  ///   - decoder: The JSON decoder configuration to apply to the request body.
  ///   - handler: Invoked only when JSON decoding succeeds.
  /// - Returns: `self` to support call chaining.
  /// - Note: On decoding failure this returns a `400 Bad Request` plain-text
  ///   response and does not invoke `handler`.
  @discardableResult
  public func put<T: JSONDecodable>(
    _ path: String,
    decoder: JSONDecoder = .init(),
    handler: @escaping (HTTPRequest, T) -> HTTPResponse
  ) -> Self {
    on(.put, path, decoder: decoder, handler: handler)
  }

  /// Registers a `PUT` route with JSON request decoding and typed JSON response encoding.
  ///
  /// - Parameters:
  ///   - path: The route pattern.
  ///   - decoder: The JSON decoder configuration to apply to the request body.
  ///   - encoder: The JSON encoder configuration to apply to the response body.
  ///   - handler: Invoked only when request JSON decoding succeeds.
  /// - Returns: `self` to support call chaining.
  /// - Note: On decode failure this returns `400 Bad Request` and skips `handler`.
  /// - Note: Successful responses ensure `Content-Type: application/json` unless
  ///   already present.
  /// - Warning: On response-encoding failure this logs the error and returns
  ///   `500 Internal Server Error`.
  @discardableResult
  public func put<RequestBody: JSONDecodable, ResponseBody: JSONEncodable>(
    _ path: String,
    decoder: JSONDecoder = .init(),
    encoder: JSONEncoder = .init(),
    handler: @escaping (HTTPRequest, RequestBody) -> HTTPJSONResponse<ResponseBody>
  ) -> Self {
    on(.put, path, decoder: decoder, encoder: encoder, handler: handler)
  }

  /// Registers a `PATCH` route.
  @discardableResult
  public func patch(_ path: String, handler: @escaping HTTPRouteHandler) -> Self {
    on(.patch, path, handler: handler)
  }

  /// Registers a `PATCH` route that decodes the request body as JSON.
  ///
  /// - Parameters:
  ///   - path: The route pattern.
  ///   - decoder: The JSON decoder configuration to apply to the request body.
  ///   - handler: Invoked only when JSON decoding succeeds.
  /// - Returns: `self` to support call chaining.
  /// - Note: On decoding failure this returns a `400 Bad Request` plain-text
  ///   response and does not invoke `handler`.
  @discardableResult
  public func patch<T: JSONDecodable>(
    _ path: String,
    decoder: JSONDecoder = .init(),
    handler: @escaping (HTTPRequest, T) -> HTTPResponse
  ) -> Self {
    on(.patch, path, decoder: decoder, handler: handler)
  }

  /// Registers a `PATCH` route with JSON request decoding and typed JSON response encoding.
  ///
  /// - Parameters:
  ///   - path: The route pattern.
  ///   - decoder: The JSON decoder configuration to apply to the request body.
  ///   - encoder: The JSON encoder configuration to apply to the response body.
  ///   - handler: Invoked only when request JSON decoding succeeds.
  /// - Returns: `self` to support call chaining.
  /// - Note: On decode failure this returns `400 Bad Request` and skips `handler`.
  /// - Note: Successful responses ensure `Content-Type: application/json` unless
  ///   already present.
  /// - Warning: On response-encoding failure this logs the error and returns
  ///   `500 Internal Server Error`.
  @discardableResult
  public func patch<RequestBody: JSONDecodable, ResponseBody: JSONEncodable>(
    _ path: String,
    decoder: JSONDecoder = .init(),
    encoder: JSONEncoder = .init(),
    handler: @escaping (HTTPRequest, RequestBody) -> HTTPJSONResponse<ResponseBody>
  ) -> Self {
    on(.patch, path, decoder: decoder, encoder: encoder, handler: handler)
  }

  /// Registers a `DELETE` route.
  @discardableResult
  public func delete(_ path: String, handler: @escaping HTTPRouteHandler) -> Self {
    on(.delete, path, handler: handler)
  }

  /// Registers a `HEAD` route.
  @discardableResult
  public func head(_ path: String, handler: @escaping HTTPRouteHandler) -> Self {
    on(.head, path, handler: handler)
  }

  /// Registers an `OPTIONS` route.
  @discardableResult
  public func options(_ path: String, handler: @escaping HTTPRouteHandler) -> Self {
    on(.options, path, handler: handler)
  }
}
