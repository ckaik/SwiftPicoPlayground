public final class RGBLed {
  let redPin: Pin
  let greenPin: Pin
  let bluePin: Pin

  public init(redPin: Pin, greenPin: Pin, bluePin: Pin) {
    self.redPin = redPin
    self.greenPin = greenPin
    self.bluePin = bluePin
  }

  public func set(_ color: Color) {
    redPin.pwm(.on(at: color.red), config: PWMConfig(frequencyHz: 1000, wrap: UInt16.max))
    greenPin.pwm(.on(at: color.green), config: PWMConfig(frequencyHz: 1000, wrap: UInt16.max))
    bluePin.pwm(.on(at: color.blue), config: PWMConfig(frequencyHz: 1000, wrap: UInt16.max))
  }
}
