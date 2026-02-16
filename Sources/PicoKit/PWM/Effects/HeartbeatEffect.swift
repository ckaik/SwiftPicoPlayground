import Common

extension PWMEffect {
  public static func heartbeat(
    pulseSeconds: Float = 0.18,
    gapSeconds: Float = 0.08,
    pauseSeconds: Float = 0.5,
    minLevel: Float = 0,
    primaryLevel: Float = 1,
    secondaryLevel: Float = 0.65
  ) -> Self {
    let safePulse = PWMConstants.clampDuration(pulseSeconds)
    let rise = PWMConstants.clampDuration(safePulse * 0.45)
    let fall = PWMConstants.clampDuration(safePulse - rise)
    let safeGap = PWMConstants.clampDuration(gapSeconds)
    let safePause = PWMConstants.clampDuration(pauseSeconds)

    let low = minLevel.clamped()
    let high = primaryLevel.clamped()
    let mid = secondaryLevel.clamped()

    return .phase(
      .fade(durationSeconds: rise, startLevel: low, endLevel: high).curve(.easeOut),
      .fade(durationSeconds: fall, startLevel: high, endLevel: low).curve(.easeIn),
      .off.duration(safeGap),
      .fade(durationSeconds: rise, startLevel: low, endLevel: mid).curve(.easeOut),
      .fade(durationSeconds: fall, startLevel: mid, endLevel: low).curve(.easeIn),
      .off.duration(safePause),
      repeats: true
    )
  }
}
