import CPicoSDK

/// High-level PWM driver for a single GPIO pin.
///
/// - Note: PWM timing is slice-wide. Starting another pin on the same slice
///   with a different ``PWMConfig`` overrides the active slice configuration.
public final class PWMOutput {
  /// GPIO identifier controlled by this instance.
  public let pin: PinID

  /// Creates a PWM output controller and switches the pin to PWM function.
  ///
  /// - Parameters:
  ///   - pin: Target GPIO pin.
  ///   - initialLevel: Optional initial PWM level to write immediately.
  public init(pin: PinID, initialLevel: UInt16? = nil) {
    self.pin = pin

    gpio_set_function(pin.value, GPIO_FUNC_PWM)

    if let level = initialLevel {
      set(level: level)
    }
  }

  deinit {
    stop()
  }

  /// Starts PWM updates for this pin.
  ///
  /// The provided closure is invoked on every slice wrap interrupt to compute
  /// the output level.
  ///
  /// - Parameters:
  ///   - config: Slice timing configuration used to set divider and wrap.
  ///   - computeLevel: Per-wrap level computation closure.
  public func start(
    config: PWMConfig = .default,
    computeLevel: @escaping PWMLevelComputation
  ) {
    PWMInterruptRegistry.shared.register(
      pin: pin,
      config: config,
      computeLevel: computeLevel
    )

    let slice = pwm_gpio_to_slice_num(pin.value)
    let clockHz = Float(clock_get_hz(clk_sys))
    let denominator = max(1, config.frequencyHz * Float(config.wrap + 1))
    let clockDivider = clockHz / denominator

    pwm_set_clkdiv(slice, clockDivider)
    pwm_set_wrap(slice, config.wrap)
    pwm_set_gpio_level(pin.value, computeLevel(pin, config, 0))
    pwm_set_enabled(slice, true)
  }

  /// Stops PWM updates for this pin and unregisters its interrupt callback.
  public func stop() {
    if PWMInterruptRegistry.shared.isRegistered(pin: pin) {
      _ = PWMInterruptRegistry.shared.unregister(pin: pin)
    }
  }

  /// Writes a raw PWM level immediately.
  ///
  /// - Parameter level: Hardware level value, typically in `0 ... wrap`.
  public func set(level: UInt16) {
    pwm_set_gpio_level(pin.value, level)
  }
}

// MARK: - Convenience Methods

extension PWMOutput {
  /// Starts PWM updates using a high-level ``PWMEffect``.
  ///
  /// - Parameters:
  ///   - effect: Effect used to compute each wrap-level update.
  ///   - config: Slice timing configuration.
  public func start(
    effect: PWMEffect,
    config: PWMConfig = .default
  ) {
    start(config: config) { pinId, config, wrapCount in
      effect.level(
        PWMEffectContext(
          pinId: pinId,
          config: config,
          wrapCount: wrapCount
        )
      )
    }
  }
}
