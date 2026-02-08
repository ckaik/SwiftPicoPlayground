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

    let pin = Pin(number: 17)
    pin.turn(on: true)

    let rgb = RGBLed(
      redPin: Pin(number: 13),
      greenPin: Pin(number: 14),
      bluePin: Pin(number: 15)
    )

    rgb.set(Color(red: 1.0, green: 1, blue: 1))

    var value = false

    while true {
      Cyw43Manager.shared[.led] = value
      value.toggle()
      sleep_ms(1000)
    }
  }
}
