import CMongoose

public protocol JSONDecodable {
  init(decoder: JSONDecoder) throws(JSONDecodingError)
}

public enum JSONDecodingError: Error {
  case invalidJSON
  case missingKey(path: String)
  case typeMismatch(path: String, expected: String)
  case invalidEncoding(path: String)
  case invalidNumber(path: String)
  case nestedContainerNotFound(path: String)
}

public enum BoolDecodingStrategy {
  case literal
  case literalOrString(
    trueValues: [String],
    falseValues: [String],
    caseInsensitive: Bool
  )

  public static let `default`: BoolDecodingStrategy = .literalOrString(
    trueValues: ["true", "on", "yes", "1", "y"],
    falseValues: ["false", "off", "no", "0", "n"],
    caseInsensitive: true
  )
}

public struct JSONDecoder {
  public let boolDecodingStrategy: BoolDecodingStrategy

  private let payload: [UInt8]
  private let scopePath: String

  public init(boolDecodingStrategy: BoolDecodingStrategy = .default) {
    self.payload = []
    self.scopePath = "$"
    self.boolDecodingStrategy = boolDecodingStrategy
  }

  private init(payload: [UInt8], scopePath: String, boolDecodingStrategy: BoolDecodingStrategy) {
    self.payload = payload
    self.scopePath = scopePath
    self.boolDecodingStrategy = boolDecodingStrategy
  }

  public func decode<T: JSONDecodable>(_ type: T.Type, from payload: [UInt8])
    throws(JSONDecodingError) -> T
  {
    guard isValidRoot(payload) else {
      throw .invalidJSON
    }

    let scoped = JSONDecoder(
      payload: payload, scopePath: "$", boolDecodingStrategy: boolDecodingStrategy)
    return try T(decoder: scoped)
  }

  public func nested(at path: String) throws(JSONDecodingError) -> JSONDecoder {
    let absolutePath = resolvedPath(for: path)
    guard let token = tokenInfo(at: absolutePath) else {
      throw .nestedContainerNotFound(path: absolutePath)
    }

    guard token.firstCharacter == UInt8(ascii: "{") else {
      throw .typeMismatch(path: absolutePath, expected: "object")
    }

    return JSONDecoder(
      payload: payload,
      scopePath: absolutePath,
      boolDecodingStrategy: boolDecodingStrategy
    )
  }

  public func decode(at path: String) throws(JSONDecodingError) -> Bool {
    let absolutePath = resolvedPath(for: path)

    switch boolDecodingStrategy {
    case .literal:
      var value = false
      let found = withJSON { json in
        absolutePath.withCString { pointer in
          mg_json_get_bool(json, pointer, &value)
        }
      }

      if found {
        return value
      }

      throw requiredFieldError(path: absolutePath, expected: "bool")

    case .literalOrString(let trueValues, let falseValues, let caseInsensitive):
      var value = false
      let found = withJSON { json in
        absolutePath.withCString { pointer in
          mg_json_get_bool(json, pointer, &value)
        }
      }

      if found {
        return value
      }

      guard
        let rawPointer = withJSON({ json in
          absolutePath.withCString { pointer in
            mg_json_get_str(json, pointer)
          }
        })
      else {
        throw requiredFieldError(path: absolutePath, expected: "bool")
      }

      defer { mg_free(rawPointer) }

      guard let text = String(validatingUTF8: rawPointer) else {
        throw .invalidEncoding(path: absolutePath)
      }

      if matches(text, values: trueValues, caseInsensitive: caseInsensitive) {
        return true
      }

      if matches(text, values: falseValues, caseInsensitive: caseInsensitive) {
        return false
      }

      throw .typeMismatch(path: absolutePath, expected: "bool")
    }
  }

  public func decodeIfPresent(at path: String) -> Bool? {
    try? decode(at: path)
  }

  public func decode(at path: String) throws(JSONDecodingError) -> String {
    let absolutePath = resolvedPath(for: path)
    guard
      let rawPointer = withJSON({ json in
        absolutePath.withCString { pointer in
          mg_json_get_str(json, pointer)
        }
      })
    else {
      throw requiredFieldError(path: absolutePath, expected: "string")
    }

    defer { mg_free(rawPointer) }

    guard let stringValue = String(validatingUTF8: rawPointer) else {
      throw .invalidEncoding(path: absolutePath)
    }

    return stringValue
  }

  public func decodeIfPresent(at path: String) -> String? {
    try? decode(at: path)
  }

  public func decode<T: BinaryFloatingPoint>(_ type: T.Type = T.self, at path: String)
    throws(JSONDecodingError) -> T
  {
    let absolutePath = resolvedPath(for: path)
    let number = try decodeNumber(at: absolutePath)

    guard number.isFinite else {
      throw .invalidNumber(path: absolutePath)
    }

    return T(number)
  }

  public func decodeIfPresent<T: BinaryFloatingPoint>(_ type: T.Type = T.self, at path: String)
    -> T?
  {
    try? decode(type, at: path)
  }

  public func decode<T: BinaryInteger>(_ type: T.Type = T.self, at path: String)
    throws(JSONDecodingError) -> T
  {
    let absolutePath = resolvedPath(for: path)
    let number = try decodeNumber(at: absolutePath)

    guard number.isFinite else {
      throw .invalidNumber(path: absolutePath)
    }

    guard number.rounded(.towardZero) == number else {
      throw .invalidNumber(path: absolutePath)
    }

    guard let value = T(exactly: number) else {
      throw .invalidNumber(path: absolutePath)
    }

    return value
  }

  public func decodeIfPresent<T: BinaryInteger>(_ type: T.Type = T.self, at path: String)
    -> T?
  {
    try? decode(type, at: path)
  }

  public func decode<T: JSONDecodable>(_ type: T.Type = T.self, at path: String)
    throws(JSONDecodingError) -> T
  {
    let absolutePath = resolvedPath(for: path)
    guard tokenInfo(at: absolutePath) != nil else {
      throw .missingKey(path: absolutePath)
    }

    let scopedDecoder = JSONDecoder(
      payload: payload,
      scopePath: absolutePath,
      boolDecodingStrategy: boolDecodingStrategy
    )

    return try T(decoder: scopedDecoder)
  }

  public func decodeIfPresent<T: JSONDecodable>(_ type: T.Type = T.self, at path: String) -> T? {
    try? decode(type, at: path)
  }

  private func decodeNumber(at path: String) throws(JSONDecodingError) -> Double {
    let absolutePath = resolvedPath(for: path)
    var value = 0.0
    let found = withJSON { json in
      absolutePath.withCString { pointer in
        mg_json_get_num(json, pointer, &value)
      }
    }

    guard found else {
      throw requiredFieldError(path: absolutePath, expected: "number")
    }

    return value
  }

  private func requiredFieldError(path: String, expected: String) -> JSONDecodingError {
    if tokenInfo(at: path) == nil {
      return .missingKey(path: path)
    }

    return .typeMismatch(path: path, expected: expected)
  }

  private func tokenInfo(at path: String) -> JSONTokenInfo? {
    withJSON { json in
      path.withCString { pointer in
        var tokenLength: Int32 = 0
        let offset = mg_json_get(json, pointer, &tokenLength)

        guard offset >= 0, tokenLength > 0 else {
          return nil
        }

        let start = Int(offset)
        let end = start + Int(tokenLength)

        guard start >= 0, end <= payload.count else {
          return nil
        }

        return JSONTokenInfo(
          firstCharacter: payload[start]
        )
      }
    }
  }

  private func resolvedPath(for path: String) -> String {
    if path == "$" {
      return "$"
    }

    if path.hasPrefix("$") {
      return path
    }

    if path.hasPrefix("[") {
      return "\(scopePath)\(path)"
    }

    if scopePath == "$" {
      return "$.\(path)"
    }

    return "\(scopePath).\(path)"
  }

  private func isValidRoot(_ payload: [UInt8]) -> Bool {
    payload.withMGStr { json in
      var tokenLength: Int32 = 0
      let result = mg_json_get(json, "$", &tokenLength)
      return result >= 0 && tokenLength > 0
    }
  }

  private func withJSON<Result>(_ body: (mg_str) -> Result) -> Result {
    payload.withMGStr(body)
  }
}

private struct JSONTokenInfo {
  let firstCharacter: UInt8
}

private func matches(_ input: String, values: [String], caseInsensitive: Bool) -> Bool {
  if caseInsensitive {
    return values.contains(where: { $0.lowercased() == input.lowercased() })
  }

  return values.contains(input)
}
