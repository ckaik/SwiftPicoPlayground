import CPicoSDK

extension Pin {
  public func pwm(_ level: @escaping (_ pin: PinID) -> UInt16) {
    guard !pwmIsRunning else { return }
    pwmIsRunning = true

    gpio_set_function(pinNumber, GPIO_FUNC_PWM)
    let slice = pwm_gpio_to_slice_num(pinNumber)

    var config = pwm_get_default_config()
    pwm_config_set_clkdiv(&config, 4)
    pwm_init(slice, &config, true)

    PWMInterruptRegistry.shared.register(pin: id, computeLevel: level)
  }
}
