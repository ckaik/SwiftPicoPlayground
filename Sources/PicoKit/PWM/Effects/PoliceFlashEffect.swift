import Common

extension PWMEffect {
  public func offset(_ offsetMs: Float) -> Self {
    let offsetSeconds = max(0, offsetMs / 1000)

    return Self { context in
      guard offsetSeconds > 0 else {
        return level(context)
      }

      let adjustedSeconds = context.elapsedSeconds + offsetSeconds
      let adjustedContext = context.withElapsedSeconds(adjustedSeconds)

      return level(adjustedContext)
    }
  }

  public static func policeFlash(
    onMs: Float = 60,
    gapMs: Float = 40,
    pauseMs: Float = 200,
    offsetMs: Float = 0
  ) -> Self {
    let onSeconds = PWMConstants.clampDuration(onMs / 1000)
    let gapSeconds = PWMConstants.clampDuration(gapMs / 1000)
    let pauseSeconds = PWMConstants.clampDuration(pauseMs / 1000)

    return .phase(
      Self.on.duration(onSeconds),
      Self.off.duration(gapSeconds),
      Self.on.duration(onSeconds),
      Self.off.duration(pauseSeconds),
      repeats: true
    )
    .offset(offsetMs)
  }
}
