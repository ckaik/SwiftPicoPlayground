import Common

extension PWMEffect {
  /// Creates a repeating double-pulse heartbeat pattern.
  ///
  /// - Parameters:
  ///   - pulseSeconds: Total duration for each rise/fall pulse.
  ///   - gapSeconds: Short gap between the first and second pulse.
  ///   - pauseSeconds: Pause after the second pulse.
  ///   - minLevel: Baseline normalized brightness in `0 ... 1`.
  ///   - primaryLevel: Peak level for the first pulse in `0 ... 1`.
  ///   - secondaryLevel: Peak level for the second pulse in `0 ... 1`.
  public static func heartbeat(
    @PWMDuration pulseSeconds: Float = 0.18,
    @PWMDuration gapSeconds: Float = 0.08,
    @PWMDuration pauseSeconds: Float = 0.5,
    @Clamped minLevel: Float = 0,
    @Clamped primaryLevel: Float = 1,
    @Clamped secondaryLevel: Float = 0.65
  ) -> Self {
    let rise = PWMConstants.clampDuration(pulseSeconds * 0.45)
    let fall = PWMConstants.clampDuration(pulseSeconds - rise)

    return .phase(
      .fade(for: rise, startLevel: minLevel, endLevel: primaryLevel).curve(.easeOut),
      .fade(for: fall, startLevel: primaryLevel, endLevel: minLevel).curve(.easeIn),
      .off.duration(gapSeconds),
      .fade(for: rise, startLevel: minLevel, endLevel: secondaryLevel).curve(.easeOut),
      .fade(for: fall, startLevel: secondaryLevel, endLevel: minLevel).curve(.easeIn),
      .off.duration(pauseSeconds),
      repeats: true
    )
  }
}
