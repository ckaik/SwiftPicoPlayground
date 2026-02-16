import Common

extension PWMEffect {
  public static func pulseHold(
    rampUpSeconds: Float = 0.25,
    holdHighSeconds: Float = 0.3,
    rampDownSeconds: Float = 0.25,
    holdLowSeconds: Float = 0.4,
    minLevel: Float = 0,
    maxLevel: Float = 1,
    curve: TimingCurve = .easeInOut
  ) -> Self {
    let up = PWMConstants.clampDuration(rampUpSeconds)
    let highHold = PWMConstants.clampDuration(holdHighSeconds)
    let down = PWMConstants.clampDuration(rampDownSeconds)
    let lowHold = PWMConstants.clampDuration(holdLowSeconds)

    let low = minLevel.clamped()
    let high = maxLevel.clamped()

    return .phase(
      .fade(durationSeconds: up, startLevel: low, endLevel: high).curve(curve),
      .dim(brightness: high).duration(highHold),
      .fade(durationSeconds: down, startLevel: high, endLevel: low).curve(curve),
      .dim(brightness: low).duration(lowHold),
      repeats: true
    )
  }
}
