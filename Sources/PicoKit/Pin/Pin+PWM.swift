import CPicoSDK
import Common

extension Pin {
  @discardableResult
  public func pwm(
    config: PWMConfig,
    computeLevel: @escaping PWMLevelComputation
  ) -> PinCancellable? {
    let pinId = id

    PWMInterruptRegistry.shared.register(
      pin: pinId,
      config: config,
      computeLevel: computeLevel
    )

    gpio_set_function(pinNumber, GPIO_FUNC_PWM)

    let slice = pwm_gpio_to_slice_num(pinNumber)
    let clockHz = Float(clock_get_hz(clk_sys))
    let denominator = max(1, config.frequencyHz * Float(config.wrap + 1))
    let clockDivider = clockHz / denominator

    pwm_set_clkdiv(slice, clockDivider)
    pwm_set_wrap(slice, config.wrap)
    pwm_set_gpio_level(pinNumber, computeLevel(pinId, config, 0))
    pwm_set_enabled(slice, true)

    return PinCancellable(pinId: pinId)
  }

  @discardableResult
  public func pwm(
    _ effect: PWMEffect,
    config: PWMConfig
  ) -> PinCancellable? {
    pwm(config: config) { pinId, config, wrapCount in
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

public struct PinCancellable: Cancellable {
  let pinId: PinID

  public func cancel() -> Bool {
    PWMInterruptRegistry.shared.unregister(pin: pinId)
  }
}
