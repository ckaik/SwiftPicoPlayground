import CMath
import CPicoSDK

public struct PhaseEffect<Phase: Equatable>: PWMEffect {
  let phases: any Sequence<Phase>
  let animations: [Animation]

  public init(
    _ phases: some Sequence<Phase>,
    animation: @escaping (Phase) -> Animation
  ) {
    self.phases = phases
    animations = phases.map(animation)
  }

  public mutating func level(for pin: PinID, wrap: UInt16, onWrap wrapCount: UInt32) -> UInt16 {
    0
  }
}

public struct Animation {
  public enum Curve {
    case linear
    case easeIn
    case easeOut
    case easeInOut

    public func apply(_ t: Float) -> Float {
      switch self {
      case .linear: t
      case .easeIn: t * t
      case .easeOut: t * (2 - t)
      case .easeInOut: t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t
      }
    }
  }

  public init(durationMs: UInt32, curve: Curve = .linear) {
    self.durationMs = durationMs
    self.curve = curve
  }

  let durationMs: UInt32
  let curve: Curve

  public func level(at timeMs: UInt32) -> UInt16 {
    let t = Float(timeMs) / Float(durationMs)
    return UInt16(curve.apply(t) * Float(UInt16.max))
  }
}
