import CMath

public protocol PWMEffect {
  mutating func level(for pin: PinID, wrap: UInt16, onWrap wrapCount: UInt32) -> UInt16
}

public protocol PWMEffectTiming {
  var durationSeconds: Float { get }
  var stepsPerDuration: UInt32 { get }
}

extension PWMEffectTiming {
  public var stepsPerDuration: UInt32 { 100 }
}
