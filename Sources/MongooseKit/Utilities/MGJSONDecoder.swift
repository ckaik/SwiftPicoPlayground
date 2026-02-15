import CMongoose

public protocol MGJSONDecodable {
  init(reader: MGJSONParser) throws(MGJSONDecodingError)
}

public enum MGJSONDecodingError: Error {
  case invalidEncoding
  case missingOrInvalidField(path: String)
}

public struct MGJSONDecoder {
  public init() {}

  public func decode<T: MGJSONDecodable>(_ type: T.Type, from payload: [UInt8])
    throws(MGJSONDecodingError) -> T
  {
    let parser = MGJSONParser(payload: payload)
    return try T(reader: parser)
  }
}

extension Bool {
  init?(_ string: String) {
    switch string.lowercased() {
    case "true", "on", "yes", "1", "y":
      self = true
    case "false", "off", "no", "0", "n":
      self = false
    default:
      return nil
    }
  }
}

public struct MGJSONParser {
  private let payload: [UInt8]

  public init(payload: [UInt8]) {
    self.payload = payload
  }

  public func bool(_ path: String) throws(MGJSONDecodingError) -> Bool {
    let stringValue = try string(path)

    guard let value = Bool(stringValue) else {
      throw MGJSONDecodingError.missingOrInvalidField(path: path)
    }

    return value
  }

  public func string(_ path: String) throws(MGJSONDecodingError) -> String {
    let rawPointer = try cString(at: path)
    defer { mg_free(rawPointer) }

    guard let value = String(validatingUTF8: rawPointer) else {
      throw MGJSONDecodingError.invalidEncoding
    }

    return value
  }

  public func number<T: BinaryFloatingPoint>(_ path: String) throws(MGJSONDecodingError) -> T {
    var value = 0.0
    let found = withJSON { json in
      path.withCString { pointer in
        mg_json_get_num(json, pointer, &value)
      }
    }

    guard found else {
      throw MGJSONDecodingError.missingOrInvalidField(path: path)
    }

    return T(value)
  }

  public func number<T: BinaryInteger>(_ path: String) throws(MGJSONDecodingError) -> T {
    let value: Double = try number(path)
    return T(value)
  }

  private func cString(at path: String) throws(MGJSONDecodingError) -> UnsafeMutablePointer<CChar> {
    guard
      let raw = withJSON({ json in
        path.withCString { pointer in
          mg_json_get_str(json, pointer)
        }
      })
    else {
      throw MGJSONDecodingError.missingOrInvalidField(path: path)
    }

    return raw
  }

  private func withJSON<Result>(_ body: (mg_str) -> Result) -> Result {
    payload.withMGStr(body)
  }
}
