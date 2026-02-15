import Common

public final class FlickerEffect: PWMEffect {
  public let durationSeconds: Float

  private let baseLevel: Float
  private let intensity: Float
  private let intervalSeconds: Float

  public init(
    @Clamped baseLevel: Float = 0.5,
    @Clamped intensity: Float = 0.4,
    intervalSeconds: Float = 0.08
  ) {
    let safeInterval = PWMConstants.clampDuration(intervalSeconds)
    self.durationSeconds = safeInterval
    self.baseLevel = baseLevel
    self.intensity = intensity
    self.intervalSeconds = safeInterval
  }

  public func level(context: PWMEffectContext) -> UInt16 {
    let bucket = UInt32(context.elapsedSeconds / intervalSeconds)
    let noise = noiseValue(for: bucket)
    let wrap = Float(context.config.wrap)
    @Clamped var level = baseLevel + (noise * intensity)
    let scaled = level * wrap
    return UInt16(max(0, min(wrap, scaled)))
  }

  // Deterministic xorshift to keep flicker behavior repeatable.
  private func noiseValue(for bucket: UInt32) -> Float {
    var value = bucket
    value = value &* 1_664_525 &+ 1_013_904_223
    value ^= value >> 15
    value = value &* 1_103_515_245 &+ 12345
    value ^= value << 7
    let normalized = Float(value) / Float(UInt32.max)
    return (normalized * 2) - 1
  }
}

extension PWMEffect where Self == FlickerEffect {
  public static func flicker(
    baseLevel: Float = 0.5,
    intensity: Float = 0.4,
    intervalSeconds: Float = 0.08
  ) -> Self {
    FlickerEffect(baseLevel: baseLevel, intensity: intensity, intervalSeconds: intervalSeconds)
  }
}
