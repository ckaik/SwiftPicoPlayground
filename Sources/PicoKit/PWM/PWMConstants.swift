/// Shared constants and guardrails for PWM timing helpers.
public enum PWMConstants {
  /// Minimum duration accepted by PWM timing utilities, in seconds.
  ///
  /// Using a positive floor avoids divide-by-zero and degenerate
  /// wrap-conversion paths in progress/timing computations.
  public static let minDurationSeconds: Float = 0.001

  /// Clamps a duration to ``minDurationSeconds`` or above.
  ///
  /// - Parameter durationSeconds: Input duration in seconds.
  /// - Returns: `max(minDurationSeconds, durationSeconds)`.
  public static func clampDuration(_ durationSeconds: Float) -> Float {
    max(minDurationSeconds, durationSeconds)
  }
}
