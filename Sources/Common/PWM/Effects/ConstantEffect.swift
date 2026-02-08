import CMath
import CPicoSDK

public struct ConstantEffect: PWMEffect {
  let level: UInt16

  init(@Clamped brightness: Float) {
    level = UInt16(pow(brightness, 2) * 255)
  }

  public func level(for pin: PinID) -> UInt16 {
    level
  }
}

extension PWMEffect where Self == ConstantEffect {
  public static func on(at brightness: Float = 1.0) -> Self {
    ConstantEffect(brightness: brightness)
  }
}
