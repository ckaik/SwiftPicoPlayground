import Common

extension PWMEffect {
  public func duration(_ durationSeconds: Float) -> Self {
    Self(durationSeconds: durationSeconds, level: level)
  }
}
