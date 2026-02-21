import CPicoSDK

public final class DigitalOutput {
  public let pin: PinID

  private var isPrepared = false

  public init(pin: PinID, initialSignal: DigitalSignal? = nil) {
    self.pin = pin

    gpio_init(pin.value)

    if let initialSignal {
      set(initialSignal)
    }
  }

  public var isOutput: Bool {
    gpio_is_dir_out(pin.value)
  }

  public func set(_ signal: DigitalSignal) {
    prepareIfNeeded()
    gpio_put(pin.value, signal.boolean)
  }

  public func prepareIfNeeded() {
    if !isOutput {
      gpio_set_dir(pin.value, IODirection.output.boolean)
    }
  }

  public func toggle() {
    prepareIfNeeded()
    gpio_xor_mask(1 << pin.value)
  }
}

// MARK: - Convenience Methods

extension DigitalOutput {
  public func on() {
    set(.high)
  }

  public func off() {
    set(.low)
  }
}
