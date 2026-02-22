import CMongoose

/// A lightweight embedded HTTP server with method-aware routing.
///
/// ```swift
/// let server = HTTPServer(port: 80)
///
/// server.get("/health") { _ in
///   HTTPResponse(status: .ok, body: "ok")
/// }
///
/// server.put("/lights/:id") { request in
///   let id = request.pathParameters["id"] ?? "unknown"
///   return HTTPResponse(status: .ok, body: "updated \(id)")
/// }
///
/// server.start()
/// ```
///
/// - Note: Route matching is case-sensitive and trailing-slash-sensitive.
/// - Note: Route registration is permissive and never throws.
/// - Note: Missing leading slashes are normalized (`"health"` becomes `"/health"`).
/// - Note: If multiple routes match, the most recently registered route wins
///   within its specificity group, and exact routes are preferred over
///   parameterized routes.
public final class HTTPServer {
  var listener: UnsafeMutablePointer<mg_connection>?
  let port: UInt16
  var routesByMethod: [HTTPMethod: [Route]] = [:]

  /// Enables HTTP server diagnostic logging.
  public var isDebugLoggingEnabled = false

  /// Creates an HTTP server instance that listens on `port`.
  public init(port: UInt16) {
    self.port = port
  }

  /// Registers a route handler for a specific method and path pattern.
  ///
  /// Path patterns support exact segments and `:param` segments.
  ///
  /// Registration behavior:
  /// - Missing leading `/` is added automatically.
  /// - Empty paths are normalized to `/`.
  /// - A `:segment` is treated as a path parameter only if the parameter name
  ///   is valid (`[A-Za-z0-9_-]+`) and unique within the same route pattern.
  /// - Invalid parameter segments are matched as exact literals.
  ///
  /// - Parameters:
  ///   - method: The HTTP method to match.
  ///   - path: The route pattern, e.g. `/lights/:id`.
  ///   - handler: The closure invoked for matching requests.
  @discardableResult
  public func on(
    _ method: HTTPMethod,
    _ path: String,
    handler: @escaping HTTPRouteHandler
  ) -> Self {
    let compiledPath = Self.compilePath(path)
    var routes = routesByMethod[method, default: []]

    routes.append(Route(path: compiledPath, handler: handler))
    routesByMethod[method] = routes

    log(
      "registered route method=\(method.rawValue) input=\(path) normalized=\(compiledPath.normalized) parameterized=\(compiledPath.isParameterized) totalForMethod=\(routes.count)"
    )
    return self
  }

  /// Starts listening for incoming HTTP requests.
  ///
  /// - Parameter address: The bind address. Defaults to `0.0.0.0`.
  public func start(address: String = "0.0.0.0") {
    guard listener == nil else {
      log("start skipped: listener already active")
      return
    }

    let url = "http://\(address):\(port)"
    log("starting HTTP listener at \(url)")
    let context = Unmanaged.passUnretained(self).toOpaque()
    listener = MGManager.shared.withManagerPointer { manager in
      url.withCString { urlCString in
        mg_http_listen(manager, urlCString, httpEventHandler, context)
      }
    }

    if listener != nil {
      log("listener ready on \(url)")
    } else {
      log("listener failed to bind on \(url)")
    }
  }

  /// Stops listening and closes the active listener connection.
  public func stop() {
    guard let listener else {
      log("stop skipped: no active listener")
      return
    }

    log("stopping listener")
    listener.pointee.is_closing = 1
    self.listener = nil
  }

  deinit {
    stop()
  }

  func handle(
    _ message: mg_http_message,
    connection: UnsafeMutablePointer<mg_connection>
  ) {
    let response = dispatch(message)
    swift_mg_http_reply(
      connection,
      response.status.rawValue,
      response.headerString(),
      response.body
    )
  }

  func handleClose(_ connection: UnsafeMutablePointer<mg_connection>) {
    if connection == listener {
      listener = nil
    }
  }

  func log(_ message: String) {
    guard isDebugLoggingEnabled else { return }
    print("[HTTPServer:\(port)] \(message)")
  }
}

/// Route handler closure invoked for matching requests.
public typealias HTTPRouteHandler = (HTTPRequest) -> HTTPResponse
