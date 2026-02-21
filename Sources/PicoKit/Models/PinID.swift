/// GPIO identifier used by Pico SDK calls.
///
/// This is a lightweight wrapper around the raw `UInt32` pin number to keep
/// APIs strongly typed.
public struct PinID: Hashable {
  /// Raw Pico SDK GPIO pin value.
  public let value: UInt32

  /// Creates a pin identifier from a raw GPIO number.
  ///
  /// - Parameter value: Pico SDK GPIO number.
  public init(_ value: UInt32) {
    self.value = value
  }
}

extension PinID: ExpressibleByIntegerLiteral {
  /// Creates a pin identifier from an integer literal.
  ///
  /// - Parameter value: Pico SDK GPIO number.
  public init(integerLiteral value: UInt32) {
    self.init(value)
  }
}
