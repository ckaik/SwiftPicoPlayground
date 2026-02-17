import CPicoSDK

extension Pin {
  /// Sets the pin's digital output state.
  ///
  /// If PWM is currently active on this pin, PWM registration is removed
  /// first so digital writes become the sole source of output control.
  ///
  /// - Parameter on: `true` for logic high, `false` for logic low.
  public func turn(on: Bool) {
    initializeIfNeeded()
    unregisterPWMIfNeeded()
    gpio_put(pinNumber, on)
  }

  /// Convenience wrapper for `turn(on: true)`.
  public func on() {
    turn(on: true)
  }

  /// Convenience wrapper for `turn(on: false)`.
  public func off() {
    turn(on: false)
  }

  /// Performs one-time GPIO init and sets output direction.
  private func initializeIfNeeded() {
    guard !isInitialized else { return }
    isInitialized = true

    gpio_init(pinNumber)
    gpio_set_dir(pinNumber, true)
  }

  /// Unregisters PWM control for this pin if currently active.
  ///
  /// Hardware side effect from unregister path: channel output is forced
  /// to level `0` before digital writes proceed.
  private func unregisterPWMIfNeeded() {
    guard PWMInterruptRegistry.shared.isRegistered(pin: id) else { return }
    _ = PWMInterruptRegistry.shared.unregister(pin: id)
  }
}
