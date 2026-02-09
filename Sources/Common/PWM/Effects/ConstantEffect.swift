import CMath
import CPicoSDK

public struct ConstantEffect: PWMEffect {
  let level: UInt16

  init(@Clamped brightness: Float) {
    level = UInt16(pow(brightness, 2) * Float(UInt16.max))
  }

  public mutating func level(for pin: PinID, wrap: UInt16, onWrap wrapCount: UInt32) -> UInt16 {
    min(level, wrap)
  }
}

extension PWMEffect where Self == ConstantEffect {
  public static func on(at brightness: Float = 1.0) -> Self {
    ConstantEffect(brightness: brightness)
  }
}
