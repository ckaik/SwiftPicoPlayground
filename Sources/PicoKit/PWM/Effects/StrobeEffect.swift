import Common

extension PWMEffect {
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
