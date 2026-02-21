/// PWM channel identifier within a hardware slice.
///
/// A Pico PWM slice has two channels (`A`/`B`) addressed by integer index.
public struct ChannelID: Hashable {
  /// Raw Pico SDK channel value.
  public let value: UInt32

  /// Creates a channel identifier from a raw channel value.
  ///
  /// - Parameter value: Pico SDK channel index.
  public init(_ value: UInt32) {
    self.value = value
  }
}

extension ChannelID: ExpressibleByIntegerLiteral {
  /// Creates a channel identifier from an integer literal.
  ///
  /// - Parameter value: Pico SDK channel index.
  public init(integerLiteral value: UInt32) {
    self.init(value)
  }
}
