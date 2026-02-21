import CPicoSDK
import Common

/// Computes a PWM level for a given pin at a specific wrap count.
///
/// - Parameters:
///   - pin: GPIO identifier being driven.
///   - config: Active shared slice configuration.
///   - wrapCount: Number of wrap interrupts since registration.
/// - Returns: Channel level, typically in `0 ... config.wrap`.
public typealias PWMLevelComputation = (_ pin: PinID, _ config: PWMConfig, _ wrapCount: UInt32) ->
  UInt16

/// Central PWM IRQ dispatcher keyed by hardware slice.
///
/// Each slice owns a single timing configuration (divider/TOP), so all pins
/// mapped to that slice share frequency and wrap. Per-pin behavior is
/// represented by individual `PWMLevelComputation` callbacks.
final class PWMInterruptRegistry {
  /// Optional hook fired when a registration changes an existing slice config.
  ///
  /// This signals that two pins sharing one slice requested different
  /// timing settings, and the newer config replaced the prior one.
  static var onConfigOverride: ((SliceID, PWMConfig, PWMConfig) -> Void)?

  private var handlers: [SliceID: SliceHandlers] = [:]
  private var sliceConfigs: [SliceID: PWMConfig] = [:]
  private var wrapCounts: [SliceID: UInt32] = [:]
  private var isConfigured = false

  private init() {}

  static let shared = PWMInterruptRegistry()

  /// Indicates whether a pin currently has a registered PWM callback.
  func isRegistered(pin: PinID) -> Bool {
    let slice = pwm_gpio_to_slice_num(pin.value)
    let sliceID = SliceID(integerLiteral: slice)
    return handlers[sliceID]?[pin] != nil
  }

  /// Registers a pin callback on its owning PWM slice.
  ///
  /// If the slice already has a different ``PWMConfig``, that existing config
  /// is overwritten and ``onConfigOverride`` is invoked.
  ///
  /// - Parameters:
  ///   - pin: GPIO identifier.
  ///   - config: Slice-level PWM timing configuration.
  ///   - computeLevel: Per-wrap level callback for this pin.
  func register(
    pin: PinID,
    config: PWMConfig,
    computeLevel: @escaping PWMLevelComputation
  ) {
    let slice = pwm_gpio_to_slice_num(pin.value)
    let sliceID = SliceID(integerLiteral: slice)
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

  /// Unregisters a pin from PWM updates.
  ///
  /// Hardware effects:
  /// - Immediately writes output level `0` for the pin.
  /// - If this was the last pin on a slice, disables that slice IRQ and
  ///   disables the slice itself.
  ///
  /// - Parameter pin: GPIO identifier.
  /// - Returns: `true` if an active registration existed and was removed.
  func unregister(pin: PinID) -> Bool {
    let slice = pwm_gpio_to_slice_num(pin.value)
    let sliceID = SliceID(integerLiteral: slice)
    guard var pinHandlers = handlers[sliceID], pinHandlers.removeValue(forKey: pin) != nil else {
      return false
    }

    handlers[sliceID] = pinHandlers.isEmpty ? nil : pinHandlers
    pwm_set_gpio_level(pin.value, 0)

    if pinHandlers.isEmpty {
      sliceConfigs[sliceID] = nil
      wrapCounts[sliceID] = nil
      pwm_set_irq_enabled(slice, false)
      pwm_set_enabled(slice, false)
    }

    return true
  }

  /// Installs the global PWM wrap IRQ handler once.
  private func configureIRQIfNeeded() {
    guard !isConfigured else { return }
    isConfigured = true

    let irqNumber = unsafeBitCast(PWM_IRQ_WRAP_0, to: UInt32.self)
    irq_set_exclusive_handler(irqNumber, _pwmIRQHandler)
    irq_set_enabled(irqNumber, true)
  }

  /// Services all slices that have a pending wrap IRQ.
  ///
  /// For each pending slice bit:
  /// - increment wrap counter,
  /// - clear that slice IRQ,
  /// - drive all registered pins with the new wrap count.
  fileprivate func servicePendingSlices() {
    var pending = pwm_get_irq_status_mask()

    while pending != 0 {
      let sliceIndex = UInt32(pending.trailingZeroBitCount)
      let sliceID = SliceID(integerLiteral: sliceIndex)
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

/// Per-slice map of pin callbacks.
private typealias SliceHandlers = [PinID: PWMLevelComputation]

extension SliceHandlers {
  /// Applies one wrap-tick update to all pins in this slice.
  func drive(config: PWMConfig, wrapCount: UInt32) {
    for (pin, computeLevel) in self {
      pwm_set_gpio_level(pin.value, computeLevel(pin, config, wrapCount))
    }
  }
}

/// C-compatible IRQ entrypoint forwarding to the shared registry.
private func _pwmIRQHandler() {
  PWMInterruptRegistry.shared.servicePendingSlices()
}
