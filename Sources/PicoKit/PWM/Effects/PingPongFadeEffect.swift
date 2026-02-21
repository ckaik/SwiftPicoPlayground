import Common

extension PWMEffect {
  /// Creates a repeating two-way fade between two levels.
  ///
  /// - Parameters:
  ///   - cycleSeconds: Full out-and-back cycle duration.
  ///   - startLevel: Start normalized brightness in `0 ... 1`.
  ///   - endLevel: End normalized brightness in `0 ... 1`.
  ///   - curve: Easing curve applied to each half cycle.
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
