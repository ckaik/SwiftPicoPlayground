/// GPIO direction mode.
public enum IODirection: Hashable {
  /// Pin configured as input.
  case input
  /// Pin configured as output.
  case output

  /// Creates a direction from a boolean.
  ///
  /// - Parameter value: `true` for ``output``, `false` for ``input``.
  public init(_ value: Bool) {
    self = value ? .output : .input
  }

  /// Converts the direction to the boolean form used by Pico SDK APIs.
  public var boolean: Bool {
    switch self {
    case .input: false
    case .output: true
    }
  }
}

extension IODirection: ExpressibleByBooleanLiteral {
  /// Creates a direction from a boolean literal.
  ///
  /// - Parameter value: `true` for ``output``, `false` for ``input``.
  public init(booleanLiteral value: Bool) {
    self.init(value)
  }
}
