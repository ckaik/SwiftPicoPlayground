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

    _ = redPin.pwm(config: config) { _, cfg, wrapCount in
      let phase = wrapCount % 200
      return phase < 100 ? cfg.wrap : 0
    }

    _ = bluePin.pwm(config: config) { _, cfg, wrapCount in
      let phase = (wrapCount + 100) % 200
      return phase < 100 ? cfg.wrap : 0
    }

    while true {
      tight_loop_contents()
    }
  }
}
