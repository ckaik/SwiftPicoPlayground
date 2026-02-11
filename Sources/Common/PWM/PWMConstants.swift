public enum PWMConstants {
  public static let minDurationSeconds: Float = 0.001

  public static func clampDuration(_ durationSeconds: Float) -> Float {
    max(minDurationSeconds, durationSeconds)
  }
}
