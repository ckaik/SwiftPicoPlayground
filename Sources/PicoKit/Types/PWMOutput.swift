import CPicoSDK

public final class PWMOutput {
  public let pin: PinID

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

  public func stop() {
    if PWMInterruptRegistry.shared.isRegistered(pin: pin) {
      _ = PWMInterruptRegistry.shared.unregister(pin: pin)
    }
  }
}

extension PWMOutput {
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

  public func set(level: UInt16) {
    pwm_set_gpio_level(pin.value, level)
  }
}
