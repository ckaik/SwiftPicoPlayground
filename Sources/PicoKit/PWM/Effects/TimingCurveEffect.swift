import CMath
import Common

public enum TimingCurve {
  case linear
  case easeIn
  case easeOut
  case easeInOut
  case custom((Float) -> Float)

  public func apply(_ t: Float) -> Float {
    let clamped = min(1, max(0, t))
    switch self {
    case .linear:
      return clamped
    case .easeIn:
      return clamped * clamped
    case .easeOut:
      return clamped * (2 - clamped)
    case .easeInOut:
      if clamped < 0.5 {
        return 2 * clamped * clamped
      }
      return -1 + (4 - 2 * clamped) * clamped
    case .custom(let fn):
      return min(1, max(0, fn(clamped)))
    }
  }
}

extension PWMEffect {
  public func curve(_ curve: TimingCurve) -> Self {
    Self(for: durationSeconds) { context in
      let elapsed = context.elapsedSeconds
      let normalized = elapsed / durationSeconds
      let cycles = floorf(normalized)
      let fraction = normalized - cycles
      let curved = curve.apply(fraction)
      let adjustedElapsed = (cycles + curved) * durationSeconds
      let adjustedContext = context.withElapsedSeconds(adjustedElapsed)

      return level(adjustedContext)
    }
  }
}
