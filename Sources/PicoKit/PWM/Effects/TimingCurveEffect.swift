import CMath
import Common

/// Easing curve used to remap normalized effect progress.
public enum TimingCurve {
  /// Linear interpolation with no easing.
  case linear
  /// Quadratic ease-in.
  case easeIn
  /// Quadratic ease-out.
  case easeOut
  /// Symmetric ease-in/ease-out.
  case easeInOut
  /// Custom progress remapping function.
  ///
  /// The closure receives a clamped input in `0 ... 1`.
  case custom((Float) -> Float)

  /// Applies the curve to a normalized input value.
  ///
  /// - Parameter t: Input progress value.
  /// - Returns: Curved progress value clamped to `0 ... 1`.
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
  /// Applies a timing curve to this effect while preserving its duration.
  ///
  /// This remaps progress inside each effect cycle and forwards the adjusted
  /// elapsed time to the original level closure.
  ///
  /// - Parameter curve: Curve used to transform normalized progress.
  /// - Returns: A wrapped effect with curved timing.
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
