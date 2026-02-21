import Common

extension PWMEffect {
  /// Creates a repeating strobe pulse effect.
  ///
  /// - Parameters:
  ///   - periodSeconds: Full strobe period duration.
  ///   - dutyCycle: Fraction of each period spent on in `0 ... 1`.
  ///   - brightness: On-state normalized brightness in `0 ... 1`.
  public static func strobe(
    periodSeconds: Float = 0.12,
    @Clamped dutyCycle: Float = 0.35,
    @Clamped brightness: Float = 1
  ) -> Self {
    Self(for: periodSeconds) { context in
      let t = context.repeatingProgress(durationSeconds: periodSeconds)
      guard t < dutyCycle else {
        return 0
      }

      let wrap = Float(context.config.wrap)
      let gamma = brightness * brightness
      let scaled = gamma * wrap
      return UInt16(max(0, min(wrap, scaled)))
    }
  }
}
