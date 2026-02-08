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
    redPin.pwm(.on(at: color.red))
    greenPin.pwm(.on(at: color.green))
    bluePin.pwm(.on(at: color.blue))
  }
}
