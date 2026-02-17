/// Property wrapper that enforces PWM-safe duration values.
///
/// Any assigned value is clamped to ``PWMConstants/minDurationSeconds``
/// or greater. This provides a consistent timing floor for APIs that
/// convert seconds into wrap counts or normalized progress.
@propertyWrapper
public struct PWMDuration {
  var value: Float

  /// Creates a wrapped duration.
  ///
  /// - Parameter wrappedValue: Duration in seconds.
  public init(wrappedValue: Float) {
    self.value = PWMConstants.clampDuration(wrappedValue)
  }

  /// Duration value in seconds, clamped on write.
  public var wrappedValue: Float {
    get { value }
    set { value = PWMConstants.clampDuration(newValue) }
  }
}
