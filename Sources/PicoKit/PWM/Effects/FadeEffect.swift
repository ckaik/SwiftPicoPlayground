import Common

extension PWMEffect {
  /// Creates a linear brightness fade between two normalized levels.
  ///
  /// - Parameters:
  ///   - durationSeconds: Fade duration in seconds.
  ///   - startLevel: Start level in `0 ... 1`.
  ///   - endLevel: End level in `0 ... 1`.
  /// - Returns: Effect that interpolates between `startLevel` and `endLevel`.
  public static func fade(
    for durationSeconds: Float = 1,
    @Clamped startLevel: Float = 0,
    @Clamped endLevel: Float = 1
  ) -> Self {
    Self(for: durationSeconds) { context in
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
