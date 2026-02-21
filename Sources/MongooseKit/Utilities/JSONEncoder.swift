public protocol JSONEncodable {
  func encode(encoder: JSONEncoder) throws(JSONEncodingError) -> JSONEncodedValue
}

public enum JSONEncodingError: Error {
  case invalidNumber(path: String)
}

public enum NilEncodingStrategy {
  case omitKey
  case encodeNull

  public static let `default`: NilEncodingStrategy = .omitKey
}

public enum BoolEncodingStrategy {
  case literal
  case string(trueValue: String, falseValue: String)

  public static let `default`: BoolEncodingStrategy = .literal
  public static let onOff: BoolEncodingStrategy = .string(trueValue: "ON", falseValue: "OFF")
}

public enum JSONEncodedValue {
  case string(String)
  case number(String)
  case bool(Bool)
  case object([String: JSONEncodedValue])
  case array([JSONEncodedValue])
  case null
}

extension JSONEncodedValue: JSONEncodable {
  public func encode(encoder: JSONEncoder) throws(JSONEncodingError) -> JSONEncodedValue {
    self
  }
}

public struct JSONEncoder {
  public let nilEncodingStrategy: NilEncodingStrategy
  public let boolEncodingStrategy: BoolEncodingStrategy

  public init(
    nilEncodingStrategy: NilEncodingStrategy = .default,
    boolEncodingStrategy: BoolEncodingStrategy = .default
  ) {
    self.nilEncodingStrategy = nilEncodingStrategy
    self.boolEncodingStrategy = boolEncodingStrategy
  }

  public func encode<T: JSONEncodable>(_ value: T) throws(JSONEncodingError) -> [UInt8] {
    let json = try encodeString(value)
    return Array(json.utf8)
  }

  public func encodeString<T: JSONEncodable>(_ value: T) throws(JSONEncodingError) -> String {
    let encoded = try value.encode(encoder: self)
    return try render(encoded, path: "$")
  }

  public func box(_ value: Bool) throws(JSONEncodingError) -> JSONEncodedValue {
    .bool(value)
  }

  public func box(_ value: String) throws(JSONEncodingError) -> JSONEncodedValue {
    .string(value)
  }

  public func box<T: BinaryInteger>(_ value: T) throws(JSONEncodingError) -> JSONEncodedValue {
    .number(String(value))
  }

  public func box<T: BinaryFloatingPoint>(_ value: T, path: String = "$")
    throws(JSONEncodingError) -> JSONEncodedValue
  {
    let number = Double(value)

    guard number.isFinite else {
      throw .invalidNumber(path: path)
    }

    return .number(String(number))
  }

  @_disfavoredOverload
  public func box<T: JSONEncodable>(_ value: T) throws(JSONEncodingError) -> JSONEncodedValue {
    try value.encode(encoder: self)
  }

  public func box<T: JSONEncodable>(_ value: [T]) throws(JSONEncodingError) -> JSONEncodedValue {
    var encoded: [JSONEncodedValue] = []
    encoded.reserveCapacity(value.count)

    for element in value {
      encoded.append(try box(element))
    }

    return .array(encoded)
  }

  public func box<T: JSONEncodable>(_ value: [String: T]) throws(JSONEncodingError)
    -> JSONEncodedValue
  {
    var encoded: [String: JSONEncodedValue] = [:]
    encoded.reserveCapacity(value.count)

    for (key, element) in value {
      encoded[key] = try box(element)
    }

    return .object(encoded)
  }

  private func render(_ value: JSONEncodedValue, path: String) throws(JSONEncodingError) -> String {
    switch value {
    case .string(let text):
      return "\"\(escape(text))\""
    case .number(let text):
      return text
    case .bool(let boolValue):
      switch boolEncodingStrategy {
      case .literal:
        return boolValue ? "true" : "false"
      case .string(let trueValue, let falseValue):
        let text = boolValue ? trueValue : falseValue
        return "\"\(escape(text))\""
      }
    case .null:
      return "null"
    case .array(let array):
      var rendered: [String] = []
      rendered.reserveCapacity(array.count)

      for (index, element) in array.enumerated() {
        rendered.append(try render(element, path: "\(path)[\(index)]"))
      }

      return "[\(rendered.joined(separator: ","))]"
    case .object(let object):
      let keys = object.keys.sorted()
      var rendered: [String] = []
      rendered.reserveCapacity(keys.count)

      for key in keys {
        guard let element = object[key] else {
          continue
        }

        let encodedKey = "\"\(escape(key))\""
        let encodedValue = try render(element, path: "\(path).\(key)")
        rendered.append("\(encodedKey):\(encodedValue)")
      }

      return "{\(rendered.joined(separator: ","))}"
    }
  }

  private func escape(_ value: String) -> String {
    var output = ""
    output.reserveCapacity(value.count)

    for scalar in value.unicodeScalars {
      switch scalar.value {
      case 0x22:
        output.append("\\\"")
      case 0x5C:
        output.append("\\\\")
      case 0x08:
        output.append("\\b")
      case 0x0C:
        output.append("\\f")
      case 0x0A:
        output.append("\\n")
      case 0x0D:
        output.append("\\r")
      case 0x09:
        output.append("\\t")
      case 0x00 ... 0x1F:
        output.append("\\u00")
        output.append(hexDigit((scalar.value >> 4) & 0xF))
        output.append(hexDigit(scalar.value & 0xF))
      default:
        output.append(String(scalar))
      }
    }

    return output
  }

  private func hexDigit(_ value: UInt32) -> Character {
    // swift-format-ignore: NeverForceUnwrap
    switch value {
    case 0 ... 9:
      return Character(UnicodeScalar(48 + value)!)
    default:
      return Character(UnicodeScalar(87 + value)!)
    }
  }
}

extension Bool: JSONEncodable {
  public func encode(encoder: JSONEncoder) throws(JSONEncodingError) -> JSONEncodedValue {
    try encoder.box(self)
  }
}

extension String: JSONEncodable {
  public func encode(encoder: JSONEncoder) throws(JSONEncodingError) -> JSONEncodedValue {
    try encoder.box(self)
  }
}

extension Int: JSONEncodable {
  public func encode(encoder: JSONEncoder) throws(JSONEncodingError) -> JSONEncodedValue {
    try encoder.box(self)
  }
}

extension Int8: JSONEncodable {
  public func encode(encoder: JSONEncoder) throws(JSONEncodingError) -> JSONEncodedValue {
    try encoder.box(self)
  }
}

extension Int16: JSONEncodable {
  public func encode(encoder: JSONEncoder) throws(JSONEncodingError) -> JSONEncodedValue {
    try encoder.box(self)
  }
}

extension Int32: JSONEncodable {
  public func encode(encoder: JSONEncoder) throws(JSONEncodingError) -> JSONEncodedValue {
    try encoder.box(self)
  }
}

extension Int64: JSONEncodable {
  public func encode(encoder: JSONEncoder) throws(JSONEncodingError) -> JSONEncodedValue {
    try encoder.box(self)
  }
}

extension UInt: JSONEncodable {
  public func encode(encoder: JSONEncoder) throws(JSONEncodingError) -> JSONEncodedValue {
    try encoder.box(self)
  }
}

extension UInt8: JSONEncodable {
  public func encode(encoder: JSONEncoder) throws(JSONEncodingError) -> JSONEncodedValue {
    try encoder.box(self)
  }
}

extension UInt16: JSONEncodable {
  public func encode(encoder: JSONEncoder) throws(JSONEncodingError) -> JSONEncodedValue {
    try encoder.box(self)
  }
}

extension UInt32: JSONEncodable {
  public func encode(encoder: JSONEncoder) throws(JSONEncodingError) -> JSONEncodedValue {
    try encoder.box(self)
  }
}

extension UInt64: JSONEncodable {
  public func encode(encoder: JSONEncoder) throws(JSONEncodingError) -> JSONEncodedValue {
    try encoder.box(self)
  }
}

extension Float: JSONEncodable {
  public func encode(encoder: JSONEncoder) throws(JSONEncodingError) -> JSONEncodedValue {
    try encoder.box(self)
  }
}

extension Double: JSONEncodable {
  public func encode(encoder: JSONEncoder) throws(JSONEncodingError) -> JSONEncodedValue {
    try encoder.box(self)
  }
}

extension Array: JSONEncodable where Element: JSONEncodable {
  public func encode(encoder: JSONEncoder) throws(JSONEncodingError) -> JSONEncodedValue {
    try encoder.box(self)
  }
}

extension Dictionary: JSONEncodable where Key == String, Value: JSONEncodable {
  public func encode(encoder: JSONEncoder) throws(JSONEncodingError) -> JSONEncodedValue {
    try encoder.box(self)
  }
}
