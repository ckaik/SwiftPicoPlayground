extension HTTPServer {
  struct Route {
    let path: CompiledPath
    let handler: HTTPRouteHandler
  }

  struct CompiledPath {
    let normalized: String
    let segments: [CompiledSegment]
    let isParameterized: Bool
  }

  enum CompiledSegment {
    case literal(String)
    case parameter(String)
  }

  struct RouteMatch {
    let route: Route
    let pathParameters: [String: String]
  }

  static func compilePath(_ rawPath: String) -> CompiledPath {
    let path = normalizedPath(rawPath)
    if path == "/" {
      return CompiledPath(
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
      normalized: path,
      segments: segments,
      isParameterized: isParameterized
    )
  }

  static func normalizedPath(_ path: String) -> String {
    guard !path.isEmpty else { return "/" }
    guard !path.hasPrefix("/") else { return path }
    return "/\(path)"
  }

  static func parameterName(for segment: String, existingNames: Set<String>) -> String? {
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

  static func isValidParameterName(_ value: String) -> Bool {
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

  static func match(_ path: CompiledPath, pathSegments: [String]) -> [String: String]? {
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
}
