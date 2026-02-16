import Common

extension PWMEffect {
  public static func fade(
    durationSeconds: Float = 1,
    startLevel: Float = 0,
    endLevel: Float = 1
  ) -> Self {
    Self(durationSeconds: durationSeconds) { context in
      let t = context.progress(durationSeconds: durationSeconds)
      let wrap = Float(context.config.wrap)
      let scaledStart = startLevel * wrap
      let scaledEnd = endLevel * wrap
      let delta = scaledEnd - scaledStart
      let value = scaledStart + (delta * t)
      return UInt16(max(0, min(wrap, value)))
    }
  }
}
