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

    let baseFade = FadeEffect(durationSeconds: 5, startLevel: 0, endLevel: 1)
    let redEffect = baseFade.withTimingCurve(.easeInOut)
    let blueEffect = baseFade.withTimingCurve(.easeOut)

    _ = redPin.pwm(.flicker(), config: config)
    _ = bluePin.pwm(
      .phase(
        .policeFlash().withDuration(2),
        .off.withDuration(10)
      ), config: config)

    while true {
      tight_loop_contents()
    }
  }
}
