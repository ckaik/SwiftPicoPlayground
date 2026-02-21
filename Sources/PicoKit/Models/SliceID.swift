/// Hardware PWM slice identifier.
///
/// On RP2040-class devices each PWM slice controls timing for two channels.
public struct SliceID: Hashable {
  /// Raw Pico SDK slice index.
  public let value: UInt32

  /// Creates a slice identifier from a raw slice index.
  ///
  /// - Parameter value: Pico SDK PWM slice index.
  public init(_ value: UInt32) {
    self.value = value
  }
}

extension SliceID: ExpressibleByIntegerLiteral {
  /// Creates a slice identifier from an integer literal.
  ///
  /// - Parameter value: Pico SDK PWM slice index.
  public init(integerLiteral value: UInt32) {
    self.init(value)
  }
}
