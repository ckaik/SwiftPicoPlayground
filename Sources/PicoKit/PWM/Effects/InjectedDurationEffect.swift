import Common

extension PWMEffect {
  /// Returns a copy of this effect with an overridden nominal duration.
  ///
  /// The underlying level closure is reused unchanged.
  ///
  /// - Parameter durationSeconds: New duration in seconds.
  public func duration(_ durationSeconds: Float) -> Self {
    Self(for: durationSeconds, level: level)
  }
}
