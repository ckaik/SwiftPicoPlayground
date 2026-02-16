import Common

extension PWMEffect {
  public static func dim(brightness: Float) -> Self {
    let brightness = brightness.clamped()
    return Self { context in
      let gamma = brightness * brightness
      let scaled = Float(context.config.wrap) * gamma
      return UInt16(min(Float(context.config.wrap), max(0, scaled)))
    }
  }

  public static var on: Self {
    dim(brightness: 1)
  }

  public static var off: Self {
    dim(brightness: 0)
  }
}
