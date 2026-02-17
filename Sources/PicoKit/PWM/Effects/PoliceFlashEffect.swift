import Common

extension PWMEffect {
  public func offset(_ offsetSeconds: Float) -> Self {
    let offsetSeconds = max(0, offsetSeconds)

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
    onSeconds: Float = 0.06,
    gapSeconds: Float = 0.04,
    pauseSeconds: Float = 0.2,
    offsetSeconds: Float = 0
  ) -> Self {
    return .phase(
      .on.duration(onSeconds),
      .off.duration(gapSeconds),
      .on.duration(onSeconds),
      .off.duration(pauseSeconds),
      repeats: true
    )
    .offset(offsetSeconds)
  }
}
