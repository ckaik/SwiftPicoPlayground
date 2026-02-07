import CPicoSDK
import Common

@main
struct App {
  enum AppError: Error {
    case cyw43InitializationFailed(PicoError)
  }

  static func main() throws(AppError) {
    stdio_init_all()

    do {
      try Cyw43Manager.shared.initialize()
    } catch {
      throw .cyw43InitializationFailed(error)
    }

    let red = Pin(number: 13)
    red.pwm(Effects.fade())

    let green = Pin(number: 14)
    green.turn(on: true)

    let blue = Pin(number: 15)
    blue.pwm(Effects.fade(goingUp: false))

    var value = false

    while true {
      Cyw43Manager.shared[.led] = value
      value.toggle()
      sleep_ms(1000)
    }
  }
}
