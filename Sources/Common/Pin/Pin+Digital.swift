import CPicoSDK

extension Pin {
  public func turn(on: Bool) {
    initializeIfNeeded()
    gpio_put(pinNumber, on)
  }

  public func on() {
    turn(on: true)
  }

  public func off() {
    turn(on: false)
  }

  private func initializeIfNeeded() {
    guard !isInitialized else { return }
    isInitialized = true

    gpio_init(pinNumber)
    gpio_set_dir(pinNumber, true)
  }
}
