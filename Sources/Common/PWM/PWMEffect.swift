import CMath

public protocol PWMEffect {
  func level(for pin: PinID) -> UInt16
}
