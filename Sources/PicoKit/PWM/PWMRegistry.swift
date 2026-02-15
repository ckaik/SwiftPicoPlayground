import CPicoSDK
import Common

public typealias PWMLevelComputation = (PinID, PWMConfig, UInt32) -> UInt16

final class PWMInterruptRegistry {
  static var onConfigOverride: ((SliceID, PWMConfig, PWMConfig) -> Void)?

  private var handlers: [SliceID: SliceHandlers] = [:]
  private var sliceConfigs: [SliceID: PWMConfig] = [:]
  private var wrapCounts: [SliceID: UInt32] = [:]
  private var isConfigured = false

  private init() {}

  static let shared = PWMInterruptRegistry()

  func isRegistered(pin: PinID) -> Bool {
    let slice = pwm_gpio_to_slice_num(pin.rawValue)
    let sliceID = SliceID(rawValue: slice)
    return handlers[sliceID]?[pin] != nil
  }

  func register(
    pin: PinID,
    config: PWMConfig,
    computeLevel: @escaping PWMLevelComputation
  ) {
    let slice = pwm_gpio_to_slice_num(pin.rawValue)
    let sliceID = SliceID(rawValue: slice)
    let previous = sliceConfigs[sliceID]

    if let previous, previous != config {
      Self.onConfigOverride?(sliceID, previous, config)
    }

    sliceConfigs[sliceID] = config

    var pinHandlers = handlers[sliceID] ?? [:]
    pinHandlers[pin] = computeLevel
    handlers[sliceID] = pinHandlers

    configureIRQIfNeeded()
    pwm_clear_irq(slice)
    pwm_set_irq_enabled(slice, true)
  }

  func unregister(pin: PinID) -> Bool {
    let slice = pwm_gpio_to_slice_num(pin.rawValue)
    let sliceID = SliceID(rawValue: slice)
    guard var pinHandlers = handlers[sliceID], pinHandlers.removeValue(forKey: pin) != nil else {
      return false
    }

    handlers[sliceID] = pinHandlers.isEmpty ? nil : pinHandlers
    pwm_set_gpio_level(pin.rawValue, 0)

    if pinHandlers.isEmpty {
      sliceConfigs[sliceID] = nil
      wrapCounts[sliceID] = nil
      pwm_set_irq_enabled(slice, false)
      pwm_set_enabled(slice, false)
    }

    return true
  }

  private func configureIRQIfNeeded() {
    guard !isConfigured else { return }
    isConfigured = true

    let irqNumber = unsafeBitCast(PWM_IRQ_WRAP_0, to: UInt32.self)
    irq_set_exclusive_handler(irqNumber, _pwmIRQHandler)
    irq_set_enabled(irqNumber, true)
  }

  fileprivate func servicePendingSlices() {
    var pending = pwm_get_irq_status_mask()

    while pending != 0 {
      let sliceIndex = UInt32(pending.trailingZeroBitCount)
      let sliceID = SliceID(rawValue: sliceIndex)
      let wrapCount = (wrapCounts[sliceID] ?? 0) &+ 1

      wrapCounts[sliceID] = wrapCount

      if let config = sliceConfigs[sliceID] {
        pwm_clear_irq(sliceIndex)
        handlers[sliceID]?.drive(config: config, wrapCount: wrapCount)
      }

      pending &= ~(UInt32(1) << sliceIndex)
    }
  }
}

private typealias SliceHandlers = [PinID: PWMLevelComputation]

extension SliceHandlers {
  func drive(config: PWMConfig, wrapCount: UInt32) {
    for (pin, computeLevel) in self {
      pwm_set_gpio_level(pin.rawValue, computeLevel(pin, config, wrapCount))
    }
  }
}

private func _pwmIRQHandler() {
  PWMInterruptRegistry.shared.servicePendingSlices()
}
