import Common

public final class FadeEffect: PWMEffect {
  public let durationSeconds: Float
  private let startLevel: Float
  private let endLevel: Float

  public init(
    durationSeconds: Float,
    @Clamped startLevel: Float = 0,
    @Clamped endLevel: Float = 1
  ) {
    self.durationSeconds = PWMConstants.clampDuration(durationSeconds)
    self.startLevel = startLevel
    self.endLevel = endLevel
  }

  public func level(context: PWMEffectContext) -> UInt16 {
    let t = context.progress(durationSeconds: durationSeconds)
    let wrap = Float(context.config.wrap)
    let scaledStart = startLevel * wrap
    let scaledEnd = endLevel * wrap
    let delta = scaledEnd - scaledStart
    let value = scaledStart + (delta * t)
    return UInt16(max(0, min(wrap, value)))
  }
}

extension PWMEffect where Self == FadeEffect {
  public static func fade(
    durationSeconds: Float,
    startLevel: Float = 0,
    endLevel: Float = 1
  ) -> Self {
    FadeEffect(durationSeconds: durationSeconds, startLevel: startLevel, endLevel: endLevel)
  }
}
