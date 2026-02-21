import CPicoSDK

/// High-level GPIO output helper for a single pin.
///
/// The pin is initialized in the constructor and switched to output mode on
/// first write.
public final class DigitalOutput {
  /// GPIO identifier controlled by this instance.
  public let pin: PinID

  private var isPrepared = false

  /// Creates a digital output controller.
  ///
  /// - Parameters:
  ///   - pin: Target GPIO pin.
  ///   - initialSignal: Optional initial level to write after initialization.
  public init(pin: PinID, initialSignal: DigitalSignal? = nil) {
    self.pin = pin

    gpio_init(pin.value)

    if let initialSignal {
      set(initialSignal)
    }
  }

  /// Returns `true` when the pin is currently configured as output.
  public var isOutput: Bool {
    gpio_is_dir_out(pin.value)
  }

  /// Writes a digital signal to the pin.
  ///
  /// The pin direction is switched to output automatically if needed.
  ///
  /// - Parameter signal: Output level to apply.
  public func set(_ signal: DigitalSignal) {
    prepareIfNeeded()
    gpio_put(pin.value, signal.boolean)
  }

  /// Ensures the pin direction is configured for output.
  public func prepareIfNeeded() {
    if !isOutput {
      gpio_set_dir(pin.value, IODirection.output.boolean)
    }
  }

  /// Toggles the current output level.
  ///
  /// The pin direction is switched to output automatically if needed.
  public func toggle() {
    prepareIfNeeded()
    gpio_xor_mask(1 << pin.value)
  }
}

// MARK: - Convenience Methods

extension DigitalOutput {
  /// Convenience helper equivalent to `set(.high)`.
  public func on() {
    set(.high)
  }

  /// Convenience helper equivalent to `set(.low)`.
  public func off() {
    set(.low)
  }
}
