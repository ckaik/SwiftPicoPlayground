import Common

@main
struct App {
  enum AppError: Error {
    case cyw43InitializationFailed(PicoError)
  }

  static func main() throws(AppError) {
    stdio_init_all()

    let red = Pin(number: 15)
    let blue = Pin(number: 17)

    do {
      try Cyw43Manager.shared.initialize()
      try Cyw43Manager.shared.connectToWiFi(
        Secrets.ssid, password: Secrets.password, auth: Secrets.mode)
      blue.on()
    } catch {
      red.on()
      sleep_ms(5000)
      return
    }

    Cyw43Manager.shared.loop()
  }
}
