import Common

extension PWMEffect {
  /// Returns a version of this effect with elapsed time shifted forward.
  ///
  /// - Note: Useful for running two channels with the same effect in a fixed
  ///   phase offset.
  ///
  /// - Parameter offsetSeconds: Positive phase offset in seconds.
  public func offset(_ offsetSeconds: Float) -> Self {
    let offsetSeconds = max(0, offsetSeconds)

    return Self { context in
      guard offsetSeconds > 0 else {
        return level(context)
      }

      let adjustedSeconds = context.elapsedSeconds + offsetSeconds
      let adjustedContext = context.withElapsedSeconds(adjustedSeconds)

      return level(adjustedContext)
    }
  }

  /// Creates a repeating two-blink emergency flash pattern.
  ///
  /// - Parameters:
  ///   - onSeconds: Duration of each flash pulse.
  ///   - gapSeconds: Gap between the first and second pulse.
  ///   - pauseSeconds: Pause between pulse pairs.
  ///   - offsetSeconds: Optional phase offset applied to the full pattern.
  public static func policeFlash(
    onSeconds: Float = 0.06,
    gapSeconds: Float = 0.04,
    pauseSeconds: Float = 0.2,
    offsetSeconds: Float = 0
  ) -> Self {
    return .phase(
      .on.duration(onSeconds),
      .off.duration(gapSeconds),
      .on.duration(onSeconds),
      .off.duration(pauseSeconds),
      repeats: true
    )
    .offset(offsetSeconds)
  }
}
