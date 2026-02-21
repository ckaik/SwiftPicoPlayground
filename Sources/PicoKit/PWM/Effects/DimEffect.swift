import Common

extension PWMEffect {
  /// Creates a constant-brightness effect with simple gamma shaping.
  ///
  /// The normalized `brightness` value is squared before scaling to hardware
  /// range to better match perceived light intensity.
  ///
  /// - Parameter brightness: Normalized brightness in `0 ... 1`.
  public static func dim(@Clamped brightness: Float) -> Self {
    return Self { context in
      let gamma = brightness * brightness
      let scaled = Float(context.config.wrap) * gamma
      return UInt16(min(Float(context.config.wrap), max(0, scaled)))
    }
  }

  /// Fully-on constant output effect.
  public static var on: Self {
    dim(brightness: 1)
  }

  /// Fully-off constant output effect.
  public static var off: Self {
    dim(brightness: 0)
  }
}
