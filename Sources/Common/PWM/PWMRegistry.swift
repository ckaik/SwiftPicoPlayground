import CPicoSDK

// This whole file is a workaround for the fact that Swift doesn't allow capturing any context when
// passing a Swift closure as a C function pointer.

typealias PWMLevelComputation = (PinID) -> UInt16

private typealias SliceHandlers = [PinID: PWMLevelComputation]

extension SliceHandlers {
  func drive() {
    for (pin, computeLevel) in self {
      pwm_set_gpio_level(pin.rawValue, computeLevel(pin))
    }
  }
}

class PWMInterruptRegistry {
  private var handlers: [SliceID: SliceHandlers] = [:]
  private var isConfigured = false

  private init() {}

  static let shared = PWMInterruptRegistry()

  func register(pin: PinID, computeLevel: @escaping PWMLevelComputation) {
    let slice = pwm_gpio_to_slice_num(pin.rawValue)
    let sliceID = SliceID(rawValue: slice)
    var pinHandlers = handlers[sliceID] ?? [:]
    pinHandlers[pin] = computeLevel
    handlers[sliceID] = pinHandlers

    configureIRQIfNeeded()
    pwm_clear_irq(slice)
    pwm_set_irq_enabled(slice, true)
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
      pwm_clear_irq(sliceIndex)
      handlers[SliceID(rawValue: sliceIndex)]?.drive()
      pending &= ~(UInt32(1) << sliceIndex)
    }
  }
}

// Top-level, non-capturing — safe to use as a C function pointer
private func _pwmIRQHandler() {
  PWMInterruptRegistry.shared.servicePendingSlices()
}
