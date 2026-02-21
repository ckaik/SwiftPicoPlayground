public enum IODirection: Hashable {
  case input
  case output

  public init(_ value: Bool) {
    self = value ? .output : .input
  }

  public var boolean: Bool {
    switch self {
    case .input: false
    case .output: true
    }
  }
}

extension IODirection: ExpressibleByBooleanLiteral {
  public init(booleanLiteral value: Bool) {
    self.init(value)
  }
}
