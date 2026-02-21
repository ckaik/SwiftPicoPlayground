import Common

extension PWMEffect {
  /// Creates a repeating inhale/exhale brightness effect.
  ///
  /// - Parameters:
  ///   - cycleSeconds: Full up-and-down cycle duration.
  ///   - minLevel: Minimum normalized brightness in `0 ... 1`.
  ///   - maxLevel: Maximum normalized brightness in `0 ... 1`.
  ///   - curve: Easing curve applied to both rise and fall phases.
  public static func breathe(
    @PWMDuration cycleSeconds: Float = 2.4,
    @Clamped minLevel: Float = 0.05,
    @Clamped maxLevel: Float = 1,
    curve: TimingCurve = .easeInOut
  ) -> Self {
    let halfCycle = PWMConstants.clampDuration(cycleSeconds / 2)
    let startLevel = min(minLevel, maxLevel)
    let endLevel = max(minLevel, maxLevel)

    return .phase(
      .fade(for: halfCycle, startLevel: startLevel, endLevel: endLevel).curve(curve),
      .fade(for: halfCycle, startLevel: endLevel, endLevel: startLevel).curve(curve),
      repeats: true
    )
  }
}
