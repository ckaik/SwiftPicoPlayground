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
