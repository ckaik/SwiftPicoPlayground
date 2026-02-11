public final class InjectedDurationEffect: PWMEffect {
  public let durationSeconds: Float
  private let fn: (PWMEffectContext) -> UInt16

  public init(durationSeconds: Float, level: @escaping (PWMEffectContext) -> UInt16) {
    fn = level
    self.durationSeconds = durationSeconds
  }

  public func level(context: PWMEffectContext) -> UInt16 {
    fn(context)
  }
}

extension PWMEffect {
  public func withDuration(_ durationSeconds: Float) -> InjectedDurationEffect {
    InjectedDurationEffect(durationSeconds: durationSeconds, level: level)
  }
}
