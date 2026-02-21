/// Logical voltage level for GPIO output/input operations.
public enum DigitalSignal: Hashable {
  /// Low level (`false` in Pico SDK boolean APIs).
  case low
  /// High level (`true` in Pico SDK boolean APIs).
  case high

  /// Creates a signal from a boolean.
  ///
  /// - Parameter value: `true` for ``high``, `false` for ``low``.
  public init(_ value: Bool) {
    self = value ? .high : .low
  }

  /// Converts the signal to a boolean used by Pico SDK GPIO functions.
  public var boolean: Bool {
    switch self {
    case .low: false
    case .high: true
    }
  }
}

extension DigitalSignal: ExpressibleByBooleanLiteral {
  /// Creates a signal from a boolean literal.
  ///
  /// - Parameter value: `true` for ``high``, `false` for ``low``.
  public init(booleanLiteral value: Bool) {
    self.init(value)
  }
}
