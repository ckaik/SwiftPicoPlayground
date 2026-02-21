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
  fileprivate var listener: UnsafeMutablePointer<mg_connection>?
  private let port: UInt16
  private var routesByMethod: [HTTPMethod: [Route]] = [:]

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

  /// Registers a `PUT` route.
  @discardableResult
  public func put(_ path: String, handler: @escaping HTTPRouteHandler) -> Self {
    on(.put, path, handler: handler)
  }

  /// Registers a `PATCH` route.
  @discardableResult
  public func patch(_ path: String, handler: @escaping HTTPRouteHandler) -> Self {
    on(.patch, path, handler: handler)
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

  fileprivate func handle(
    _ message: mg_http_message, connection: UnsafeMutablePointer<mg_connection>
  ) {
    let response = dispatch(message)
    swift_mg_http_reply(
      connection,
      response.status.rawValue,
      response.headerString(),
      response.body
    )
  }
}

/// Route handler closure invoked for matching requests.
public typealias HTTPRouteHandler = (HTTPRequest) -> HTTPResponse

extension HTTPServer {
  private struct Route {
    let path: CompiledPath
    let handler: HTTPRouteHandler
  }

  private struct CompiledPath {
    let input: String
    let normalized: String
    let segments: [CompiledSegment]
    let isParameterized: Bool
  }

  private enum CompiledSegment {
    case literal(String)
    case parameter(String)
  }

  private struct RouteMatch {
    let route: Route
    let pathParameters: [String: String]
  }

  private struct RequestContext {
    let request: HTTPRequest
    let pathSegments: [String]
  }

  private static let allowHeaderOrder: [HTTPMethod] = [
    .get,
    .head,
    .post,
    .put,
    .patch,
    .delete,
    .options,
  ]

  private func dispatch(_ message: mg_http_message) -> HTTPResponse {
    guard let context = Self.makeRequestContext(from: message) else {
      let rawMethod = Self.decodeString(message.method, allowEmpty: true) ?? "<invalid>"
      let rawPath = Self.decodeString(message.uri, allowEmpty: true) ?? "<invalid>"
      log("request parse failure: method=\(rawMethod) path=\(rawPath)")
      return Self.plainTextResponse(status: .badRequest, body: "Bad Request")
    }

    if let match = matchRoute(method: context.request.method, pathSegments: context.pathSegments) {
      log(
        "route matched method=\(context.request.method.rawValue) path=\(context.request.path) normalizedRoute=\(match.route.path.normalized) parameters=\(match.pathParameters)"
      )
      let request = context.request.setting(pathParameters: match.pathParameters)
      return match.route.handler(request)
    }

    if context.request.method == .head,
      let getMatch = matchRoute(method: .get, pathSegments: context.pathSegments)
    {
      log(
        "HEAD fallback to GET for path=\(context.request.path), normalizedRoute=\(getMatch.route.path.normalized)"
      )
      let getRequest = context.request.setting(
        method: .get,
        pathParameters: getMatch.pathParameters
      )
      let getResponse = getMatch.route.handler(getRequest)
      return HTTPResponse(
        status: getResponse.status,
        headers: getResponse.headers,
        body: ""
      )
    }

    let allowedMethods = allowedMethods(for: context.pathSegments)
    if !allowedMethods.isEmpty {
      let allowHeader = Self.allowHeader(for: allowedMethods)
      log(
        "method mismatch method=\(context.request.method.rawValue) path=\(context.request.path) allow=\(allowHeader.value)"
      )

      if context.request.method == .options {
        log("auto OPTIONS response for path=\(context.request.path)")
        return HTTPResponse(
          status: .noContent,
          headers: [allowHeader],
          body: ""
        )
      }

      return HTTPResponse(
        status: .methodNotAllowed,
        headers: [allowHeader, .init("Content-Type", value: "text/plain")],
        body: "Method Not Allowed"
      )
    }

    log("no route found method=\(context.request.method.rawValue) path=\(context.request.path)")
    return Self.plainTextResponse(status: .notFound, body: "Not Found")
  }

  private func matchRoute(method: HTTPMethod, pathSegments: [String]) -> RouteMatch? {
    guard let routes = routesByMethod[method] else { return nil }

    for route in routes.reversed() where !route.path.isParameterized {
      if let parameters = Self.match(route.path, pathSegments: pathSegments) {
        return RouteMatch(route: route, pathParameters: parameters)
      }
    }

    for route in routes.reversed() where route.path.isParameterized {
      if let parameters = Self.match(route.path, pathSegments: pathSegments) {
        return RouteMatch(route: route, pathParameters: parameters)
      }
    }

    return nil
  }

  private func allowedMethods(for pathSegments: [String]) -> Set<HTTPMethod> {
    var methods: Set<HTTPMethod> = []

    for method in HTTPMethod.allCases
    where matchRoute(method: method, pathSegments: pathSegments) != nil {
      methods.insert(method)
    }

    if methods.contains(.get) {
      methods.insert(.head)
    }

    if !methods.isEmpty {
      methods.insert(.options)
    }

    return methods
  }

  private static func compilePath(_ rawPath: String) -> CompiledPath {
    let path = normalizedPath(rawPath)
    if path == "/" {
      return CompiledPath(
        input: rawPath,
        normalized: path,
        segments: [],
        isParameterized: false
      )
    }

    let rawSegments = path.dropFirst().split(separator: "/", omittingEmptySubsequences: false)
    var segments: [CompiledSegment] = []
    var parameterNames: Set<String> = []
    var isParameterized = false

    for rawSegment in rawSegments {
      let segment = String(rawSegment)

      if let parameterName = parameterName(
        for: segment,
        existingNames: parameterNames
      ) {
        segments.append(.parameter(parameterName))
        parameterNames.insert(parameterName)
        isParameterized = true
      } else {
        segments.append(.literal(segment))
      }
    }

    return CompiledPath(
      input: rawPath,
      normalized: path,
      segments: segments,
      isParameterized: isParameterized
    )
  }

  private static func normalizedPath(_ path: String) -> String {
    guard !path.isEmpty else { return "/" }
    guard !path.hasPrefix("/") else { return path }
    return "/\(path)"
  }

  private static func parameterName(for segment: String, existingNames: Set<String>) -> String? {
    guard segment.hasPrefix(":") else { return nil }

    let candidate = String(segment.dropFirst())
    guard
      isValidParameterName(candidate),
      !existingNames.contains(candidate)
    else {
      return nil
    }

    return candidate
  }

  private static func isValidParameterName(_ value: String) -> Bool {
    guard !value.isEmpty else { return false }

    for byte in value.utf8 {
      switch byte {
      case 45, 48 ... 57, 65 ... 90, 95, 97 ... 122:
        continue
      default:
        return false
      }
    }

    return true
  }

  private static func match(_ path: CompiledPath, pathSegments: [String]) -> [String: String]? {
    guard path.segments.count == pathSegments.count else {
      return nil
    }

    var parameters: [String: String] = [:]

    for (index, segment) in path.segments.enumerated() {
      let value = pathSegments[index]
      switch segment {
      case .literal(let literal):
        guard literal == value else {
          return nil
        }
      case .parameter(let name):
        guard !value.isEmpty else {
          return nil
        }

        parameters[name] = value
      }
    }

    return parameters
  }

  private static func makeRequestContext(from message: mg_http_message) -> RequestContext? {
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

  private static func decodeString(_ value: mg_str, allowEmpty: Bool) -> String? {
    if value.len == 0 {
      return allowEmpty ? "" : nil
    }

    return value.toString()
  }

  private static func decodeHeaders(from message: mg_http_message) -> [HTTPHeader]? {
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

  private static func parsePathSegments(_ path: String) -> [String]? {
    guard path.hasPrefix("/") else {
      return nil
    }

    if path == "/" {
      return []
    }

    return path.dropFirst().split(separator: "/", omittingEmptySubsequences: false).map(String.init)
  }

  private static func allowHeader(for methods: Set<HTTPMethod>) -> HTTPHeader {
    let value = allowHeaderOrder.compactMap { method in
      methods.contains(method) ? method.rawValue : nil
    }.joined(separator: ", ")

    return HTTPHeader("Allow", value: value)
  }

  private static func plainTextResponse(status: HTTPStatus, body: String) -> HTTPResponse {
    HTTPResponse(
      status: status,
      headers: [.init("Content-Type", value: "text/plain")],
      body: body
    )
  }

  fileprivate func log(_ message: String) {
    guard isDebugLoggingEnabled else { return }
    print("[HTTPServer:\(port)] \(message)")
  }
}

private func asciiUppercased(_ value: String) -> String {
  let transformed = value.utf8.map { byte in
    if byte >= 97 && byte <= 122 {
      return byte - 32
    }

    return byte
  }

  return String(decoding: transformed, as: UTF8.self)
}

private func httpEventHandler(
  conn: UnsafeMutablePointer<mg_connection>?, ev: Int32, evData: UnsafeMutableRawPointer?
) {
  guard let conn, let rawServer = conn.pointee.fn_data else { return }

  let server = Unmanaged<HTTPServer>.fromOpaque(rawServer).takeUnretainedValue()

  switch Int(ev) {
  case MG_EV_HTTP_MSG:
    guard let messagePointer = evData?.assumingMemoryBound(to: mg_http_message.self) else { return }

    server.handle(messagePointer.pointee, connection: conn)
  case MG_EV_CLOSE:
    if conn == server.listener {
      server.listener = nil
    }
  default: break
  }
}
