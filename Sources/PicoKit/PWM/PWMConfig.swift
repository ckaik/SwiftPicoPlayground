/// Hardware PWM configuration shared by all GPIOs on a PWM slice.
///
/// The effective PWM output period is controlled by two values:
///
/// - `frequencyHz`: target wrap rate in Hz (how often the counter reaches TOP).
/// - `wrap`: TOP value loaded into the PWM counter.
///
/// In the Pico SDK model used here, duty resolution is `wrap + 1` steps,
/// while output frequency is set via the slice clock divider:
///
/// `divider = clk_sys / (frequencyHz * (wrap + 1))`
///
/// Higher `wrap` improves duty granularity but typically requires a larger
/// divider (or lower frequency). Lower `wrap` reduces granularity but makes
/// higher output frequencies easier to achieve.
///
/// Platform note:
/// - RP2040: this maps directly to PWM slice TOP/divider behavior.
/// - RP2350 (Pico 2): same conceptual model applies, but exact achievable
///   frequencies depend on that platform's clocking and SDK behavior.
public struct PWMConfig: Equatable {
  /// Target PWM wrap frequency in Hz.
  ///
  /// Values at or below `0` are not rejected at construction time. Runtime
  /// call sites defensively clamp denominators/frequencies when converting
  /// this value into timing calculations.
  public let frequencyHz: Float

  /// PWM TOP value (inclusive upper bound of the counter).
  ///
  /// Duty-cycle outputs are expected to be in the range `0 ... wrap`.
  /// The number of representable duty steps is therefore `wrap + 1`.
  public let wrap: UInt16

  /// Creates a PWM configuration.
  ///
  /// - Parameters:
  ///   - frequencyHz: Target wrap frequency in Hz.
  ///   - wrap: Counter TOP value (`0 ... 65535`).
  public init(frequencyHz: Float, wrap: UInt16) {
    self.frequencyHz = frequencyHz
    self.wrap = wrap
  }
}

extension PWMConfig {
  /// Default PWM configuration used by convenience APIs.
  ///
  /// Uses `1000 Hz` wrap frequency with `12-bit`-like resolution
  /// (`wrap = 4095`).
  public static let `default` = PWMConfig(frequencyHz: 1000, wrap: 4095)
}
