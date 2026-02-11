public final class DimEffect: PWMEffect {
  private let brightness: Float

  public init(@Clamped brightness: Float) {
    self.brightness = min(1, max(0, brightness))
  }

  public func level(context: PWMEffectContext) -> UInt16 {
    let gamma = brightness * brightness
    let scaled = Float(context.config.wrap) * gamma
    return UInt16(min(Float(context.config.wrap), max(0, scaled)))
  }
}

extension PWMEffect where Self == DimEffect {
  public static func dim(brightness: Float) -> Self {
    DimEffect(brightness: brightness)
  }

  public static var on: Self {
    DimEffect(brightness: 1)
  }

  public static var off: Self {
    DimEffect(brightness: 0)
  }
}
