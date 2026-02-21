import Common

extension PWMEffect {
  /// Creates a fast random-like flicker around a baseline brightness.
  ///
  /// - Parameters:
  ///   - baseLevel: Baseline normalized brightness in `0 ... 1`.
  ///   - intensity: Maximum signed deviation from the base level.
  ///   - intervalSeconds: Noise sampling interval in seconds.
  public static func flicker(
    @Clamped baseLevel: Float = 0.5,
    intensity: Float = 0.4,
    intervalSeconds: Float = 0.08
  ) -> Self {
    func noise(for bucket: UInt32) -> Float {
      var value = bucket
      value = value &* 1_664_525 &+ 1_013_904_223
      value ^= value >> 15
      value = value &* 1_103_515_245 &+ 12345
      value ^= value << 7
      let normalized = Float(value) / Float(UInt32.max)
      return (normalized * 2) - 1
    }

    return Self(for: intervalSeconds) { context in
      let bucket = UInt32(context.elapsedSeconds / intervalSeconds)
      let noise = noise(for: bucket)
      let wrap = Float(context.config.wrap)
      @Clamped var level = baseLevel + (noise * intensity)
      let scaled = level * wrap
      return UInt16(max(0, min(wrap, scaled)))
    }
  }
}
