public struct TimedFadeEffect: PWMEffect {
  public typealias EasingFunction = (UInt16) -> UInt16

  public enum Easing {
    case linear
    case easeInQuad
    case easeOutQuad
    case easeInOutQuad
    case easeInCubic
    case easeOutCubic
    case easeInOutCubic
    case easeInQuart
    case easeOutQuart
    case easeInOutQuart
    case easeInQuint
    case easeOutQuint
    case easeInOutQuint
    case smoothstep
    case smootherstep
    case custom(EasingFunction)
  }

  private var ctx: PWMTickContext
  private let start: UInt16
  private let end: UInt16
  private let easing: Easing
  private let durationSeconds: Float
  private let stepsPerDuration: UInt32

  public init(
    wrapHz: UInt32,
    durationSeconds: Float,
    divider: UInt32 = 1,
    start: UInt16 = 0,
    end: UInt16 = UInt16.max,
    easing: Easing = .linear
  ) {
    self.ctx = makeContext(wrapHz: wrapHz, durationSeconds: durationSeconds, divider: divider)
    self.start = start
    self.end = end
    self.easing = easing
    self.durationSeconds = durationSeconds
    self.stepsPerDuration = PWMTickContext.ticks(
      for: durationSeconds,
      wrapHz: wrapHz,
      divider: divider
    )
  }

  public init(
    config: PWMConfig,
    durationSeconds: Float,
    stepsPerDuration: UInt32 = 100,
    start: UInt16 = 0,
    end: UInt16 = UInt16.max,
    easing: Easing = .linear
  ) {
    let divider = config.tickDivider(
      durationSeconds: durationSeconds,
      stepsPerDuration: stepsPerDuration
    )
    self.ctx = makeContext(
      wrapHz: UInt32(config.frequencyHz),
      durationSeconds: durationSeconds,
      divider: divider
    )
    self.start = start
    self.end = end
    self.easing = easing
    self.durationSeconds = durationSeconds
    self.stepsPerDuration = stepsPerDuration
  }

  public mutating func level(for pin: PinID, wrap: UInt16, onWrap wrapCount: UInt32) -> UInt16 {
    _ = pin
    _ = ctx.advanceIfNeeded(onWrap: wrapCount)
    let tFixed = ctx.tFixed
    let eased = UInt32(applyEasing(tFixed, easing: easing))
    return _level(start: start, end: end, wrap: wrap, tFixed: eased)
  }
}

extension TimedFadeEffect: PWMEffectTiming {
  public var durationSeconds: Float { durationSeconds }
  public var stepsPerDuration: UInt32 { stepsPerDuration }
}

private func makeContext(
  wrapHz: UInt32,
  durationSeconds: Float,
  divider: UInt32
) -> PWMTickContext {
  let ticks = PWMTickContext.ticks(for: durationSeconds, wrapHz: wrapHz, divider: divider)
  return PWMTickContext(totalTicks: ticks, divider: divider)
}

private func _level(start: UInt16, end: UInt16, wrap: UInt16, tFixed: UInt32) -> UInt16 {
  let clampedStart = min(start, wrap)
  let clampedEnd = min(end, wrap)
  let delta = Int32(clampedEnd) - Int32(clampedStart)
  let value = Int32(clampedStart) + (delta * Int32(tFixed)) / 65535
  return UInt16(clamping: value)
}

@inline(__always)
private func q16Mul(_ a: UInt16, _ b: UInt16) -> UInt16 {
  UInt16((UInt64(a) * UInt64(b)) / 65535)
}

@inline(__always)
private func q16Pow2(_ t: UInt16) -> UInt16 {
  q16Mul(t, t)
}

@inline(__always)
private func q16Pow3(_ t: UInt16) -> UInt16 {
  q16Mul(q16Mul(t, t), t)
}

@inline(__always)
private func q16Pow4(_ t: UInt16) -> UInt16 {
  let t2 = q16Mul(t, t)
  return q16Mul(t2, t2)
}

@inline(__always)
private func q16Pow5(_ t: UInt16) -> UInt16 {
  let t2 = q16Mul(t, t)
  let t4 = q16Mul(t2, t2)
  return q16Mul(t4, t)
}

@inline(__always)
private func applyEasing(_ t: UInt16, easing: TimedFadeEffect.Easing) -> UInt16 {
  switch easing {
  case .linear:
    return t
  case .easeInQuad:
    return q16Pow2(t)
  case .easeOutQuad:
    let u = UInt16(65535 - UInt32(t))
    let u2 = q16Pow2(u)
    return UInt16(65535 - UInt32(u2))
  case .easeInOutQuad:
    if t < 32768 {
      let v = UInt32(q16Pow2(t)) * 2
      return UInt16(min(65535, v))
    }
    let u = UInt16(65535 - UInt32(t))
    let v = UInt32(q16Pow2(u)) * 2
    return UInt16(65535 - min(65535, v))
  case .easeInCubic:
    return q16Pow3(t)
  case .easeOutCubic:
    let u = UInt16(65535 - UInt32(t))
    let u3 = q16Pow3(u)
    return UInt16(65535 - UInt32(u3))
  case .easeInOutCubic:
    if t < 32768 {
      let v = UInt32(q16Pow3(t)) * 4
      return UInt16(min(65535, v))
    }
    let u = UInt16(65535 - UInt32(t))
    let v = UInt32(q16Pow3(u)) * 4
    return UInt16(65535 - min(65535, v))
  case .easeInQuart:
    return q16Pow4(t)
  case .easeOutQuart:
    let u = UInt16(65535 - UInt32(t))
    let u4 = q16Pow4(u)
    return UInt16(65535 - UInt32(u4))
  case .easeInOutQuart:
    if t < 32768 {
      let v = UInt32(q16Pow4(t)) * 8
      return UInt16(min(65535, v))
    }
    let u = UInt16(65535 - UInt32(t))
    let v = UInt32(q16Pow4(u)) * 8
    return UInt16(65535 - min(65535, v))
  case .easeInQuint:
    return q16Pow5(t)
  case .easeOutQuint:
    let u = UInt16(65535 - UInt32(t))
    let u5 = q16Pow5(u)
    return UInt16(65535 - UInt32(u5))
  case .easeInOutQuint:
    if t < 32768 {
      let v = UInt32(q16Pow5(t)) * 16
      return UInt16(min(65535, v))
    }
    let u = UInt16(65535 - UInt32(t))
    let v = UInt32(q16Pow5(u)) * 16
    return UInt16(65535 - min(65535, v))
  case .smoothstep:
    let t2 = UInt32(q16Pow2(t))
    let t3 = UInt32(q16Pow3(t))
    let v = 3 * t2 - 2 * t3
    return UInt16(min(65535, v))
  case .smootherstep:
    let t3 = UInt32(q16Pow3(t))
    let t4 = UInt32(q16Pow4(t))
    let t5 = UInt32(q16Pow5(t))
    let v = 6 * t5 - 15 * t4 + 10 * t3
    return UInt16(min(65535, v))
  case .custom(let fn):
    return fn(t)
  }
}
