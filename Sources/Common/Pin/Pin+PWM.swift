import CPicoSDK

extension Pin {
  @discardableResult
  public func pwm(
    _ effect: some PWMEffect,
    config: PWMConfig,
    tickDivider: UInt32 = 1
  ) -> Bool {
    guard !pwmIsRunning else { return false }
    pwmIsRunning = true

    var effect = effect
    let divider = max(1, tickDivider)
    var lastLevel = effect.level(for: id, wrap: config.wrap, onWrap: 0)
    let registered = PWMInterruptRegistry.shared.register(
      pin: id,
      wrap: config.wrap,
      computeLevel: { pin, wrap, wrapCount in
        if wrapCount % divider == 0 {
          lastLevel = effect.level(for: pin, wrap: wrap, onWrap: wrapCount)
        }
        return lastLevel
      }
    )

    guard registered else {
      pwmIsRunning = false
      return false
    }

    gpio_set_function(pinNumber, GPIO_FUNC_PWM)

    let slice = pwm_gpio_to_slice_num(pinNumber)
    let clockDivider = Float(clock_get_hz(clk_sys)) / (config.frequencyHz * Float(config.wrap + 1))

    pwm_set_clkdiv(slice, clockDivider)
    pwm_set_wrap(slice, config.wrap)
    pwm_set_gpio_level(pinNumber, lastLevel)
    pwm_set_enabled(slice, true)
    return true
  }

  @discardableResult
  public func pwm(
    _ effect: some PWMEffect,
    config: PWMConfig,
    tickMs: Float
  ) -> Bool {
    let divider = config.tickDivider(forTickMs: tickMs)
    return pwm(effect, config: config, tickDivider: divider)
  }

  @discardableResult
  public func pwm<E: PWMEffect & PWMEffectTiming>(
    _ effect: E,
    config: PWMConfig
  ) -> Bool {
    let divider = config.tickDivider(for: effect)
    return pwm(effect, config: config, tickDivider: divider)
  }
}

public protocol Cancellable {
  @discardableResult
  func cancel() -> Bool
}

public struct PWMCancellable: Cancellable {
  private let cancelHandler: () -> Bool

  init(_ cancelHandler: @escaping () -> Bool) {
    self.cancelHandler = cancelHandler
  }

  public func cancel() -> Bool {
    cancelHandler()
  }
}

public struct PWMConfig {
  public let frequencyHz: Float
  public let wrap: UInt16

  public init(frequencyHz: Float, wrap: UInt16) {
    self.frequencyHz = frequencyHz
    self.wrap = wrap
  }
}

extension PWMConfig {
  public static var recommended: PWMConfig {
    PWMConfig(frequencyHz: 1000, wrap: 4095)
  }

  public func tickDivider(durationSeconds: Float, stepsPerDuration: UInt32 = 100) -> UInt32 {
    let safeDuration = max(0.001, durationSeconds)
    let safeSteps = max(1, stepsPerDuration)
    let updateHz = Float(safeSteps) / safeDuration
    return tickDivider(forUpdateHz: updateHz)
  }

  public func tickDivider<E: PWMEffectTiming>(for effect: E) -> UInt32 {
    tickDivider(durationSeconds: effect.durationSeconds, stepsPerDuration: effect.stepsPerDuration)
  }

  public func tickDivider(forUpdateHz updateHz: Float) -> UInt32 {
    PWMTickContext.divider(forUpdateHz: updateHz, wrapHz: UInt32(frequencyHz))
  }

  public func tickDivider(forTickMs tickMs: Float) -> UInt32 {
    PWMTickContext.divider(forTickMs: tickMs, wrapHz: UInt32(frequencyHz))
  }
}
