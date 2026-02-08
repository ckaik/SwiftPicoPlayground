public struct ConstantEffect: PWMEffect {
  let level: UInt16

  init(brightness: Float, gamma: Float = 2.0) {
    let floatLevel: Float = brightness.clamped(to: 0 ... 1) * 255
    level = UInt16(pow(floatLevel, gamma))
  }

  public func level(for pin: PinID) -> UInt16 {
    level
  }
}

extension PWMEffect where Self == ConstantEffect {
  public static func on(at brightness: Float = 1.0, withGamma gamma: Float = 2.0) -> Self {
    ConstantEffect(brightness: brightness, gamma: gamma)
  }
}
