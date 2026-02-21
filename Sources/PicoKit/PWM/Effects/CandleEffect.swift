import Common

extension PWMEffect {
  /// Creates a warm candle-like flicker effect using deterministic noise.
  ///
  /// - Parameters:
  ///   - baseLevel: Baseline normalized brightness in `0 ... 1`.
  ///   - intensity: Maximum signed deviation from the base level.
  ///   - intervalSeconds: Noise sampling interval in seconds.
  public static func candle(
    @Clamped baseLevel: Float = 0.4,
    intensity: Float = 0.2,
    intervalSeconds: Float = 0.2
  ) -> Self {
    func noise(for bucket: UInt32) -> Float {
      var value = bucket
      value = value &* 1_664_525 &+ 1_013_904_223
      value ^= value >> 15
      value = value &* 1_103_515_245 &+ 12_345
      value ^= value << 7
      let normalized = Float(value) / Float(UInt32.max)
      return (normalized * 2) - 1
    }

    return Self(for: intervalSeconds) { context in
      let elapsed = context.elapsedSeconds / intervalSeconds
      let bucket = UInt32(max(0, Int(elapsed)))
      let fraction = elapsed - Float(bucket)

      let n0 = noise(for: bucket)
      let n1 = noise(for: bucket &+ 1)
      let smoothNoise = n0 + ((n1 - n0) * fraction)

      @Clamped var level = baseLevel + (smoothNoise * intensity)
      let wrap = Float(context.config.wrap)
      let scaled = level * wrap
      return UInt16(max(0, min(wrap, scaled)))
    }
  }
}
