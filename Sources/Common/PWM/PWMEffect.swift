public protocol PWMEffect: AnyObject {
  func level(context: PWMEffectContext) -> UInt16
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
}
