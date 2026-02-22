import CMongoose

extension HTTPServer {
  static let allowHeaderOrder: [HTTPMethod] = [
    .get,
    .head,
    .post,
    .put,
    .patch,
    .delete,
    .options,
  ]

  func dispatch(_ message: mg_http_message) -> HTTPResponse {
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

  func matchRoute(method: HTTPMethod, pathSegments: [String]) -> RouteMatch? {
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

  func allowedMethods(for pathSegments: [String]) -> Set<HTTPMethod> {
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

  static func allowHeader(for methods: Set<HTTPMethod>) -> HTTPHeader {
    let value = allowHeaderOrder.compactMap { method in
      methods.contains(method) ? method.rawValue : nil
    }.joined(separator: ", ")

    return HTTPHeader("Allow", value: value)
  }

  static func plainTextResponse(status: HTTPStatus, body: String) -> HTTPResponse {
    HTTPResponse(
      status: status,
      headers: [.init("Content-Type", value: "text/plain")],
      body: body
    )
  }

  static func logJSONEncodingFailure(
    port: UInt16,
    request: HTTPRequest,
    errorDescription: String
  ) {
    print(
      "[HTTPServer:\(port)] response JSON encoding failure method=\(request.method.rawValue) path=\(request.path) error=\(errorDescription)"
    )
  }
}
