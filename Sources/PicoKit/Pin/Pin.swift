import CPicoSDK
import Common

/// GPIO pin abstraction with automatic PWM cleanup semantics.
public final class Pin {
  /// Numeric identifier used by Pico SDK GPIO/PWM functions.
  public let id: PinID

  internal(set) public var isInitialized = false

  /// Creates a pin wrapper for the given GPIO identifier.
  public init(id: PinID) {
    self.id = id
  }

  /// Ensures any active PWM registration is released before deallocation.
  ///
  /// This prevents stale IRQ-driven callbacks from targeting a destroyed
  /// Swift object lifecycle.
  deinit {
    if PWMInterruptRegistry.shared.isRegistered(pin: id) {
      _ = PWMInterruptRegistry.shared.unregister(pin: id)
    }
  }

  /// Convenience initializer using a GPIO number.
  public convenience init(number: UInt32) {
    self.init(id: number)
  }

  lazy private(set) var pinNumber: UInt32 = id
}
