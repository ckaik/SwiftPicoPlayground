import Common

extension PWMEffect {
  public static func pingPongFade(
    @PWMDuration cycleSeconds: Float = 2,
    @Clamped startLevel: Float = 0,
    @Clamped endLevel: Float = 1,
    curve: TimingCurve = .linear
  ) -> Self {
    let halfCycle = PWMConstants.clampDuration(cycleSeconds / 2)

    return .phase(
      .fade(for: halfCycle, startLevel: startLevel, endLevel: endLevel).curve(curve),
      .fade(for: halfCycle, startLevel: endLevel, endLevel: startLevel).curve(curve),
      repeats: true
    )
  }
}
