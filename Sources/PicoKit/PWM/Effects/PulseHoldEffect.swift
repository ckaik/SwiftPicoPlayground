import Common

extension PWMEffect {
  public static func pulseHold(
    rampUpSeconds: Float = 0.25,
    holdHighSeconds: Float = 0.3,
    rampDownSeconds: Float = 0.25,
    holdLowSeconds: Float = 0.4,
    @Clamped minLevel: Float = 0,
    @Clamped maxLevel: Float = 1,
    curve: TimingCurve = .easeInOut
  ) -> Self {
    .phase(
      .fade(for: rampUpSeconds, startLevel: minLevel, endLevel: maxLevel).curve(curve),
      .dim(brightness: maxLevel).duration(holdHighSeconds),
      .fade(for: rampDownSeconds, startLevel: maxLevel, endLevel: minLevel).curve(curve),
      .dim(brightness: minLevel).duration(holdLowSeconds),
      repeats: true
    )
  }
}
