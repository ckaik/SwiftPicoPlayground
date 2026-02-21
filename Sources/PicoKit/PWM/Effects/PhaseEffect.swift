import Common

extension PWMEffect {
  /// Creates a composite effect from a variadic list of phases.
  ///
  /// - Parameters:
  ///   - phases: Ordered phase effects to play in sequence.
  ///   - repeats: `true` to loop continuously, `false` for a one-shot cycle.
  public static func phase(_ phases: PWMEffect..., repeats: Bool = true) -> Self {
    .phase(phases, repeats: repeats)
  }

  /// Creates a composite effect from ordered phases.
  ///
  /// - Parameters:
  ///   - phases: Ordered phase effects to play in sequence.
  ///   - repeats: `true` to loop continuously, `false` to hold the final cycle.
  /// - Precondition: `phases` must not be empty.
  public static func phase(_ phases: [PWMEffect], repeats: Bool = true) -> Self {
    var cumulativeDuration: Float = 0
    var offsets: [Float] = []
    offsets.reserveCapacity(phases.count)

    for phase in phases {
      offsets.append(cumulativeDuration)
      cumulativeDuration += PWMConstants.clampDuration(phase.durationSeconds)
    }

    precondition(
      !phases.isEmpty && cumulativeDuration > 0,
      "Phase effect requires at least one phase and must have a total duration greater than 0"
    )

    return Self(for: cumulativeDuration) { context in
      let elapsed = context.elapsedSeconds
      let cycleTime =
        repeats
        ? elapsed.truncatingRemainder(dividingBy: cumulativeDuration)
        : min(elapsed, cumulativeDuration)

      for index in stride(from: phases.count - 1, through: 0, by: -1)
      where cycleTime >= offsets[index] {
        let localSeconds = cycleTime - offsets[index]
        let localContext = context.withElapsedSeconds(localSeconds)
        return phases[index].level(localContext)
      }

      return phases[0].level(context.withElapsedSeconds(0))
    }
  }
}
