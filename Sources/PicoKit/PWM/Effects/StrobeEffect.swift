import Common

extension PWMEffect {
  public static func strobe(
    periodSeconds: Float = 0.12,
    dutyCycle: Float = 0.35,
    brightness: Float = 1
  ) -> Self {
    let safePeriod = PWMConstants.clampDuration(periodSeconds)
    let onFraction = dutyCycle.clamped()
    let clampedBrightness = brightness.clamped()

    return Self(durationSeconds: safePeriod) { context in
      let t = context.repeatingProgress(durationSeconds: safePeriod)
      guard t < onFraction else {
        return 0
      }

      let wrap = Float(context.config.wrap)
      let gamma = clampedBrightness * clampedBrightness
      let scaled = gamma * wrap
      return UInt16(max(0, min(wrap, scaled)))
    }
  }
}
