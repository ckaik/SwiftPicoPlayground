import CPicoSDK
import Common
import HomeAssistantKit
import MongooseKit
import PicoKit

@main
struct App {
  enum AppError: Error {
    case cyw43InitializationFailed(PicoError)
  }

  static func main() throws(AppError) {
    stdio_init_all()

    let red: LEDController = LEDController(output: .init(pin: 15))
    let green = LEDController(output: .init(pin: 14))
    let blue = LEDController(output: .init(pin: 17))

    red.off()
    green.off()
    blue.off()

    print("connect to wifi...")

    do {
      try MGManager.shared.connectToWiFi(
        ssid: Secrets.ssid,
        password: Secrets.password,
        security: Secrets.mode
      )
    } catch {
      red.on()
      CPicoSDK.sleep_ms(10000)
      return
    }

    print("waiting for network...")

    MGManager.shared.waitForReady()

    let hass = startHomeAssistant(red: red, green: green, blue: blue)
    let http = startHTTPServer(
      ledMap: [
        "15": red,
        "14": green,
        "17": blue,
      ]
    )

    _ = http
    _ = hass

    print("up and running...")

    MGManager.shared.loop()
  }
}
