import Common

public struct PWMEffect {
  public let durationSeconds: Float
  public let level: (PWMEffectContext) -> UInt16

  public init(durationSeconds: Float = 1, level: @escaping (PWMEffectContext) -> UInt16) {
    self.durationSeconds = durationSeconds
    self.level = level
  }
}

/// Immutable snapshot of timing and hardware state passed to a ``PWMEffect``
/// on every wrap interrupt.
///
/// The context is the single source of truth for "how much time has passed"
/// and "what hardware are we targeting." Effects should derive all timing
/// from the properties and helpers on this type rather than maintaining
/// their own clocks.
///
/// ## Key Concepts
///
/// - **Wrap count**: The number of times the PWM counter has wrapped since
///   the effect was registered. This is the fundamental timing primitive on
///   the RP2040.
/// - **Elapsed seconds**: Derived from wrap count and the configured
///   frequency (`wrapCount / frequencyHz`).
/// - **Progress helpers**: Convenience methods that map elapsed seconds
///   into a normalised `0 ... 1` range for a given duration, either
///   clamping (``progress(durationSeconds:)``) or looping
///   (``repeatingProgress(durationSeconds:)``).
public struct PWMEffectContext {
  /// The identifier of the pin this effect is driving.
  public let pinId: PinID

  /// The PWM hardware configuration (frequency and wrap value) currently
  /// active on the slice that owns ``pinId``.
  public let config: PWMConfig

  /// The number of PWM wrap interrupts that have fired since the effect
  /// was registered. Monotonically increasing.
  public let wrapCount: UInt32

  /// Creates a new context snapshot.
  ///
  /// Normally constructed by the ``PWMInterruptRegistry`` — you should
  /// only need to call this directly in tests or when building a
  /// derived context via ``withElapsedSeconds(_:)``.
  ///
  /// - Parameters:
  ///   - pinId: The pin identifier.
  ///   - config: Active PWM configuration for the slice.
  ///   - wrapCount: Number of wrap interrupts elapsed.
  public init(pinId: PinID, config: PWMConfig, wrapCount: UInt32) {
    self.pinId = pinId
    self.config = config
    self.wrapCount = wrapCount
  }

  /// Wall-clock time elapsed since the effect was registered, derived
  /// from ``wrapCount`` and ``config``'s frequency.
  ///
  /// The frequency is floored to `1 Hz` to avoid division by zero for
  /// misconfigured slices.
  public var elapsedSeconds: Float {
    let safeHz = max(1, config.frequencyHz)
    return Float(wrapCount) / safeHz
  }

  /// Converts a duration in seconds to an equivalent wrap count.
  ///
  /// Useful when an effect needs to know how many interrupts correspond
  /// to a particular interval at the current frequency.
  ///
  /// - Parameter durationSeconds: The time span to convert. Clamped to
  ///   ``PWMConstants/minDurationSeconds`` at minimum.
  /// - Returns: The number of wraps, guaranteed to be at least `1`.
  public func totalWraps(durationSeconds: Float) -> UInt32 {
    let safeHz = max(1, config.frequencyHz)
    let safeDuration = PWMConstants.clampDuration(durationSeconds)
    let wraps = safeHz * safeDuration
    return UInt32(max(1, Int(wraps)))
  }

  /// Normalised progress through a duration, clamped to `0 ... 1`.
  ///
  /// Once ``elapsedSeconds`` exceeds `durationSeconds` the returned
  /// value stays at `1.0`, making this suitable for one-shot effects
  /// that should hold their final state.
  ///
  /// - Parameter durationSeconds: The full duration of the effect cycle.
  ///   Clamped to ``PWMConstants/minDurationSeconds`` at minimum.
  /// - Returns: A value in `0 ... 1` representing how far through the
  ///   duration the effect has progressed.
  public func progress(durationSeconds: Float) -> Float {
    let safeDuration = PWMConstants.clampDuration(durationSeconds)
    @Clamped var t = elapsedSeconds / safeDuration
    return t
  }

  /// Normalised progress through a duration that wraps around each cycle.
  ///
  /// Unlike ``progress(durationSeconds:)`` the value resets to `0` at the
  /// beginning of every cycle, producing a sawtooth ramp from `0` to `1`
  /// that repeats indefinitely.
  ///
  /// - Parameter durationSeconds: The length of one cycle. Clamped to
  ///   ``PWMConstants/minDurationSeconds`` at minimum.
  /// - Returns: A value in `0 ... 1` representing the position within
  ///   the current cycle.
  public func repeatingProgress(durationSeconds: Float) -> Float {
    let safeDuration = PWMConstants.clampDuration(durationSeconds)
    @Clamped var t = elapsedSeconds.truncatingRemainder(dividingBy: safeDuration) / safeDuration
    return t
  }

  /// Returns a new context whose elapsed time is set to the given value.
  ///
  /// The ``pinId`` and ``config`` are copied unchanged. A new
  /// ``wrapCount`` is back-calculated from `seconds` and the current
  /// frequency so that ``elapsedSeconds`` on the returned context
  /// equals `seconds` (to floating-point precision).
  ///
  /// Composite effects such as ``PhaseEffect`` and
  /// ``TimingCurveEffect`` use this to present a phase-local or
  /// time-warped context to their inner effects.
  ///
  /// - Parameter seconds: Desired elapsed time. Negative values are
  ///   clamped to `0`.
  /// - Returns: A new ``PWMEffectContext`` with the adjusted wrap count.
  public func withElapsedSeconds(_ seconds: Float) -> PWMEffectContext {
    let safeHz = max(1, config.frequencyHz)
    let clampedSeconds = max(0, seconds)
    let wrapCount = UInt32(max(0, Int(clampedSeconds * safeHz)))
    return PWMEffectContext(pinId: pinId, config: config, wrapCount: wrapCount)
  }
}
