import CPicoSDK

// This whole file is a workaround for the fact that Swift doesn't allow capturing any context when
// passing a Swift closure as a C function pointer.

typealias PWMLevelComputation = (PinID, UInt16, UInt32) -> UInt16

private typealias SliceHandlers = [PinID: PWMLevelComputation]

extension SliceHandlers {
  func drive(wrap: UInt16, wrapCount: UInt32) {
    for (pin, computeLevel) in self {
      pwm_set_gpio_level(pin.rawValue, computeLevel(pin, wrap, wrapCount))
    }
  }
}

class PWMInterruptRegistry {
  private var handlers: [SliceID: SliceHandlers] = [:]
  private var sliceWraps: [SliceID: UInt16] = [:]
  private var wrapCounts: [SliceID: UInt32] = [:]
  private var isConfigured = false

  private init() {}

  static let shared = PWMInterruptRegistry()

  func register(
    pin: PinID,
    wrap: UInt16,
    computeLevel: @escaping PWMLevelComputation
  ) -> Bool {
    let slice = pwm_gpio_to_slice_num(pin.rawValue)
    let sliceID = SliceID(rawValue: slice)
    if let existingWrap = sliceWraps[sliceID], existingWrap != wrap {
      return false
    }
    sliceWraps[sliceID] = wrap
    var pinHandlers = handlers[sliceID] ?? [:]
    pinHandlers[pin] = computeLevel
    handlers[sliceID] = pinHandlers

    configureIRQIfNeeded()
    pwm_clear_irq(slice)
    pwm_set_irq_enabled(slice, true)
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
      let wrap = sliceWraps[sliceID] ?? UInt16.max
      pwm_clear_irq(sliceIndex)
      handlers[sliceID]?.drive(wrap: wrap, wrapCount: wrapCount)
      pending &= ~(UInt32(1) << sliceIndex)
    }
  }
}

// Top-level, non-capturing — safe to use as a C function pointer
private func _pwmIRQHandler() {
  PWMInterruptRegistry.shared.servicePendingSlices()
}
