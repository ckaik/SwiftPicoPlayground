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

    let phase = PhaseEffect(
      .fade(durationSeconds: 2, startLevel: 0, endLevel: 1),
      .off.withDuration(1),
      .on.withDuration(5),
      .fade(durationSeconds: 2, startLevel: 1, endLevel: 0),
      repeats: true
    )

    _ = redPin.pwm(phase, config: config)
    _ = bluePin.pwm(.on, config: config)

    while true {
      tight_loop_contents()
    }
  }
}
