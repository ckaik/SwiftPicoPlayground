import Common

@main
struct App {
  enum AppError: Error {
    case cyw43InitializationFailed(PicoError)
  }

  static func main() throws(AppError) {
    stdio_init_all()

    let redPin = Pin(number: 15)
    let bluePin = Pin(number: 16)
    let config = PWMConfig(frequencyHz: 1000, wrap: 4095)
    let tickMs: Float = 10
    let cycleMs: Float = 2 * 60 + 40 + 200

    let redEffect = PoliceFlashEffect(
      tickMs: tickMs,
      offsetMs: 0
    )
    let blueEffect = PoliceFlashEffect(
      tickMs: tickMs,
      offsetMs: cycleMs / 2
    )

    redPin.pwm(redEffect, config: config, tickMs: tickMs)
    bluePin.pwm(blueEffect, config: config, tickMs: tickMs)

    while true {
      tight_loop_contents()
    }
  }
}
