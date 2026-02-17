import CPicoSDK
import Common

extension Pin {
  /// Configures this GPIO for hardware PWM and registers a level callback.
  ///
  /// Hardware sequence:
  /// 1. Registers `computeLevel` in the shared PWM interrupt registry.
  /// 2. Switches the GPIO mux to `GPIO_FUNC_PWM`.
  /// 3. Computes and applies the slice clock divider.
  /// 4. Sets slice TOP (`wrap`) and initial channel compare level.
  /// 5. Enables the slice.
  ///
  /// Divider math:
  ///
  /// `divider = clk_sys / (frequencyHz * (wrap + 1))`
  ///
  /// where `wrap + 1` is the number of counter ticks per PWM period.
  ///
  /// Expected level contract:
  /// - `computeLevel` should return values in `0 ... config.wrap`.
  /// - Values outside that range are not clamped here.
  ///
  /// Platform note:
  /// - RP2040: maps directly onto per-slice divider + TOP + channel level.
  /// - RP2350 (Pico 2): same high-level model, with platform-specific
  ///   clock constraints determining exact achievable rates.
  ///
  /// - Parameters:
  ///   - config: PWM slice timing configuration.
  ///   - computeLevel: Callback invoked initially and on each wrap IRQ.
  /// - Returns: A cancellable that unregisters this pin from PWM updates.
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

  /// Drives this pin with a prebuilt PWM effect.
  ///
  /// This is a convenience wrapper around ``pwm(config:computeLevel:)``
  /// that builds a ``PWMEffectContext`` for each wrap update.
  ///
  /// - Parameters:
  ///   - effect: Effect that computes per-wrap output levels.
  ///   - config: PWM slice timing configuration.
  /// - Returns: A cancellable that stops PWM updates for this pin.
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

/// Cancellation handle for a PWM registration on a specific pin.
public struct PinCancellable: Cancellable {
  let pinId: PinID

  /// Unregisters the pin from PWM IRQ-driven updates.
  ///
  /// Returns `true` when an active registration was removed.
  public func cancel() -> Bool {
    PWMInterruptRegistry.shared.unregister(pin: pinId)
  }
}
