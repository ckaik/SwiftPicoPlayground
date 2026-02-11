public final class PhaseEffect: PWMEffect {
  public let durationSeconds: Float

  private let phases: [PWMEffect]
  private let repeats: Bool

  public init(_ phases: [PWMEffect], repeats: Bool = true) {
    let durationSeconds = phases.reduce(0) { $0 + $1.durationSeconds }
    precondition(
      !phases.isEmpty && durationSeconds > 0,
      "PhaseEffect requires at least one phase and must have a total duration greater than 0"
    )

    self.phases = phases
    self.durationSeconds = durationSeconds
    self.repeats = repeats
  }

  public convenience init(_ phases: PWMEffect..., repeats: Bool = true) {
    self.init(phases, repeats: repeats)
  }

  public func level(context: PWMEffectContext) -> UInt16 {
    let elapsed = context.elapsedSeconds
    let cycleTime =
      repeats
      ? elapsed.truncatingRemainder(dividingBy: durationSeconds)
      : min(elapsed, durationSeconds)

    var cursor: Float = 0
    for phase in phases {
      let next = cursor + phase.durationSeconds
      if cycleTime <= next {
        let localSeconds = max(0, cycleTime - cursor)
        let localContext = context.withElapsedSeconds(localSeconds)

        return phase.level(context: localContext)
      }
      cursor = next
    }

    return phases.last?.level(context: context) ?? 0
  }
}

extension PWMEffect where Self == PhaseEffect {
  public static func phase(_ steps: PWMEffect..., repeats: Bool = true) -> some PWMEffect {
    .phase(steps, repeats: repeats)
  }

  public static func phase(_ steps: [PWMEffect], repeats: Bool = true) -> some PWMEffect {
    PhaseEffect(steps, repeats: repeats)
  }
}
