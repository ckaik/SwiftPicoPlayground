import Mongoose

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

public struct MGJSONParser {
  private let payload: [UInt8]

  public init(payload: [UInt8]) {
    self.payload = payload
  }

  public func bool(_ path: String) throws(MGJSONDecodingError) -> Bool {
    let comparison = try cString(at: path)
    defer { mg_free(comparison) }

    return "ON".withCString { strcasecmp($0, comparison) == 0 }
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
    payload.withUnsafeBytes { buffer in
      var json = mg_str()
      json.buf = UnsafeMutablePointer(
        mutating: buffer.baseAddress?.assumingMemoryBound(to: CChar.self))
      json.len = buffer.count
      return body(json)
    }
  }
}
