public enum DigitalSignal: Hashable {
  case low
  case high

  public init(_ value: Bool) {
    self = value ? .high : .low
  }

  public var boolean: Bool {
    switch self {
    case .low: false
    case .high: true
    }
  }
}

extension DigitalSignal: ExpressibleByBooleanLiteral {
  public init(booleanLiteral value: Bool) {
    self.init(value)
  }
}
