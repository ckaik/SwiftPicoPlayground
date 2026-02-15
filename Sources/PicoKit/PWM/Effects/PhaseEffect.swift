import Common

public final class PhaseEffect: PWMEffect {
  public let durationSeconds: Float

  private let phases: [PWMEffect]
  private let cumulativeOffsets: [Float]
  private let repeats: Bool

  public init(_ phases: [PWMEffect], repeats: Bool = true) {
    var offsets: [Float] = []
    offsets.reserveCapacity(phases.count)
    var cumulative: Float = 0
    for phase in phases {
      offsets.append(cumulative)
      cumulative += PWMConstants.clampDuration(phase.durationSeconds)
    }

    precondition(
      !phases.isEmpty && cumulative > 0,
      "PhaseEffect requires at least one phase and must have a total duration greater than 0"
    )

    self.phases = phases
    self.cumulativeOffsets = offsets
    self.durationSeconds = cumulative
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

    for index in stride(from: phases.count - 1, through: 0, by: -1)
    where cycleTime >= cumulativeOffsets[index] {
      let localSeconds = cycleTime - cumulativeOffsets[index]
      let localContext = context.withElapsedSeconds(localSeconds)
      return phases[index].level(context: localContext)
    }

    return phases[0].level(context: context.withElapsedSeconds(0))
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
