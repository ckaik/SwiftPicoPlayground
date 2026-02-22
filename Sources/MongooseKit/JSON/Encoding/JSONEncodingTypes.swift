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

public enum ObjectKeyOrderingStrategy {
  case insertion
  case sorted

  public static let `default`: ObjectKeyOrderingStrategy = .insertion
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
