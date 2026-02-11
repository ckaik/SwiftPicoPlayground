public final class PoliceFlashEffect: PWMEffect {
  public let durationSeconds: Float

  private let phase: PhaseEffect
  private let offsetSeconds: Float

  public init(
    onMs: Float = 60,
    gapMs: Float = 40,
    pauseMs: Float = 200,
    offsetMs: Float = 0
  ) {
    let onSeconds = max(0.001, onMs / 1000)
    let gapSeconds = max(0.001, gapMs / 1000)
    let pauseSeconds = max(0.001, pauseMs / 1000)

    phase = PhaseEffect(
      .on.withDuration(onSeconds),
      .off.withDuration(gapSeconds),
      .on.withDuration(onSeconds),
      .off.withDuration(pauseSeconds),
      repeats: true
    )

    durationSeconds = phase.durationSeconds
    offsetSeconds = max(0, offsetMs / 1000)
  }

  public func level(context: PWMEffectContext) -> UInt16 {
    guard offsetSeconds > 0 else {
      return phase.level(context: context)
    }

    let safeHz = max(1, context.config.frequencyHz)
    let adjustedSeconds = context.elapsedSeconds + offsetSeconds
    let adjustedWrapCount = UInt32(max(0, Int(adjustedSeconds * safeHz)))
    let adjustedContext = PWMEffectContext(
      pinId: context.pinId,
      config: context.config,
      wrapCount: adjustedWrapCount
    )

    return phase.level(context: adjustedContext)
  }
}

extension PWMEffect where Self == PoliceFlashEffect {
  public static func policeFlash(
    onMs: Float = 60,
    gapMs: Float = 40,
    pauseMs: Float = 200,
    offsetMs: Float = 0
  ) -> Self {
    PoliceFlashEffect(onMs: onMs, gapMs: gapMs, pauseMs: pauseMs, offsetMs: offsetMs)
  }
}
