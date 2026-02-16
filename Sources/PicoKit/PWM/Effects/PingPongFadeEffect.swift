import Common

extension PWMEffect {
  public static func pingPongFade(
    cycleSeconds: Float = 2,
    startLevel: Float = 0,
    endLevel: Float = 1,
    curve: TimingCurve = .linear
  ) -> Self {
    let safeCycle = PWMConstants.clampDuration(cycleSeconds)
    let halfCycle = PWMConstants.clampDuration(safeCycle / 2)

    let from = startLevel.clamped()
    let to = endLevel.clamped()

    return .phase(
      .fade(durationSeconds: halfCycle, startLevel: from, endLevel: to).curve(curve),
      .fade(durationSeconds: halfCycle, startLevel: to, endLevel: from).curve(curve),
      repeats: true
    )
  }
}
