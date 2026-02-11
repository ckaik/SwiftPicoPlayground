import Common

@main
struct App {
  enum AppError: Error {
    case cyw43InitializationFailed(PicoError)
  }

  static func main() throws(AppError) {
    stdio_init_all()

    let redPin = Pin(number: 15)
    let bluePin = Pin(number: 17)
    let config = PWMConfig(frequencyHz: 1000, wrap: 4095)

    let redEffect = PoliceFlashEffect(offsetMs: 0)
    let blueEffect = PoliceFlashEffect(offsetMs: 150)

    _ = redPin.pwm(redEffect, config: config)
    _ = bluePin.pwm(blueEffect, config: config)

    while true {
      tight_loop_contents()
    }
  }
}
