import Common

extension PWMEffect {
  public static func breathe(
    cycleSeconds: Float = 2.4,
    minLevel: Float = 0.05,
    maxLevel: Float = 1,
    curve: TimingCurve = .easeInOut
  ) -> Self {
    let safeCycle = PWMConstants.clampDuration(cycleSeconds)
    let halfCycle = PWMConstants.clampDuration(safeCycle / 2)

    let clampedMin = minLevel.clamped()
    let clampedMax = maxLevel.clamped()
    let startLevel = min(clampedMin, clampedMax)
    let endLevel = max(clampedMin, clampedMax)

    return .phase(
      .fade(durationSeconds: halfCycle, startLevel: startLevel, endLevel: endLevel).curve(curve),
      .fade(durationSeconds: halfCycle, startLevel: endLevel, endLevel: startLevel).curve(curve),
      repeats: true
    )
  }
}
