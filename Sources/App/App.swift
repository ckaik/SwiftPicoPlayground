import CPicoSDK
import Common
import HomeAssistantKit
import MongooseKit
import PicoKit

let ledConfig = [
  "schema": JSONValue.string("json"),
  "brightness": JSONValue.bool(true),
  "brightness_scale": JSONValue.number(255),
  "enabled_by_default": JSONValue.bool(true),
  "effect": JSONValue.bool(true),
  "effect_list": JSONValue.array([
    .string("Breathe"),
    .string("Strobe"),
    .string("Heartbeat"),
    .string("Ping Pong Fade"),
    .string("Candle"),
    .string("Pulse Hold"),
    .string("Police Flash"),
    .string("Flicker"),
  ]),
  "flash": JSONValue.bool(false),
  "transition": JSONValue.bool(false),
]

@main
struct App {
  enum AppError: Error {
    case cyw43InitializationFailed(PicoError)
  }

  static func main() throws(AppError) {
    stdio_init_all()

    let red = LEDController(pin: Pin(number: 15))
    let green = LEDController(pin: Pin(number: 14))
    let blue = LEDController(pin: Pin(number: 17))

    red.off()
    green.off()
    blue.off()

    print("connect to wifi")

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

    print("waiting for network")

    MGManager.shared.waitForReady()

    let router = HomeAssistantRouter(
      mqttConfig: MQTTConfig(
        host: "10.0.0.101",
        username: Secrets.mqttUser,
        password: Secrets.mqttPassword
      ),
      deviceId: "pico2w",
      deviceName: "Pico",
      objectId: "Pico",
      lights: [
        .init(
          key: "red",
          componentID: "led.red",
          name: "Rote LED",
          discoveryData: ledConfig,
          initialState: red.currentLightState(),
          onCommand: red.process
        ),
        .init(
          key: "green",
          componentID: "led.green",
          name: "Grüne LED",
          discoveryData: ledConfig,
          initialState: green.currentLightState(),
          onCommand: green.process
        ),
        .init(
          key: "blue",
          componentID: "led.blue",
          name: "Blaue LED",
          discoveryData: ledConfig,
          initialState: blue.currentLightState(),
          onCommand: blue.process
        ),
      ],
      device: .init(
        manufacturer: "CKAIK",
        serialNumber: "1337",
        hardwareVersion: "0.1.0",
        softwareVersion: "0.1.0",
        configurationUrl: "https://github.com/ckaik/SwiftPicoPlayground"
      )
    )

    print("starting Home Assistant client")

    do {
      try router.start()
    } catch {
      print("failed")
      sleep_ms(5000)
      return
    }

    print("polling...")

    MGManager.shared.loop()
  }
}
