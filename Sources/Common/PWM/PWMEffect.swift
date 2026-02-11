public protocol PWMEffect: AnyObject {
  func level(context: PWMEffectContext) -> UInt16

  var durationSeconds: Float { get }
}

extension PWMEffect {
  public var durationSeconds: Float { 1 }
}

public struct PWMEffectContext {
  public let pinId: PinID
  public let config: PWMConfig
  public let wrapCount: UInt32

  public init(pinId: PinID, config: PWMConfig, wrapCount: UInt32) {
    self.pinId = pinId
    self.config = config
    self.wrapCount = wrapCount
  }

  public var elapsedSeconds: Float {
    let safeHz = max(1, config.frequencyHz)
    return Float(wrapCount) / safeHz
  }

  public func totalWraps(durationSeconds: Float) -> UInt32 {
    let safeHz = max(1, config.frequencyHz)
    let safeDuration = max(0.001, durationSeconds)
    let wraps = safeHz * safeDuration
    return UInt32(max(1, Int(wraps)))
  }

  public func progress(durationSeconds: Float) -> Float {
    let safeDuration = max(0.001, durationSeconds)
    @Clamped var t = elapsedSeconds / safeDuration
    return t
  }

  public func repeatingProgress(durationSeconds: Float) -> Float {
    let safeDuration = max(0.001, durationSeconds)
    @Clamped var t = elapsedSeconds.truncatingRemainder(dividingBy: safeDuration) / safeDuration
    return t
  }
}
