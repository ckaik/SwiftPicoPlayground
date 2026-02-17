import Common

extension PWMEffect {
  public func duration(_ durationSeconds: Float) -> Self {
    Self(for: durationSeconds, level: level)
  }
}
