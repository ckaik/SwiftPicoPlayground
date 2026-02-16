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

    let client = HomeAssistantClient(
      mqttConfig: MQTTConfig(
        host: "10.0.0.101",
        username: Secrets.mqttUser,
        password: Secrets.mqttPassword
      ),
      discovery: DiscoveryConfig(objectId: "Pico"),
      discoveryPayload: DiscoveryPayload(
        qos: 0,
        device: Device(
          ids: "pico2w",
          name: "Pico",
          manufacturer: "CKAIK",
          serialNumber: "1337",
          hardwareVersion: "0.1.0",
          softwareVersion: "0.1.0",
          configurationUrl: "https://github.com/ckaik/SwiftPicoPlayground"
        ),
        components: [
          "red": Component(
            id: "led.red",
            kind: .light,
            name: "Rote LED",
            stateTopic: "pico2w/leds/red/state",
            commandTopic: "pico2w/leds/red/set",
            data: ledConfig
          ),
          "green": Component(
            id: "led.green",
            kind: .light,
            name: "Grüne LED",
            stateTopic: "pico2w/leds/green/state",
            commandTopic: "pico2w/leds/green/set",
            data: ledConfig
          ),
          "blue": Component(
            id: "led.blue",
            kind: .light,
            name: "Blaue LED",
            stateTopic: "pico2w/leds/blue/state",
            commandTopic: "pico2w/leds/blue/set",
            data: ledConfig
          ),
        ]
      ),
      state: { _, cmp in
        switch cmp.id {
        case "led.red":
          return red.currentLightState().json
        case "led.green":
          return green.currentLightState().json
        case "led.blue":
          return blue.currentLightState().json
        default:
          print("unknown component id: \(cmp.id)")
          return nil
        }
      },
      handler: { event in
        switch event {
        case .didReceiveMessage(let topic, let payload):
          print("received message on topic \(topic): \(payload)")

          if topic == "pico2w/leds/red/set" {
            _ = red.process(payload: payload)
          } else if topic == "pico2w/leds/green/set" {
            _ = green.process(payload: payload)
          } else if topic == "pico2w/leds/blue/set" {
            _ = blue.process(payload: payload)
          } else {
            print("unknown topic: \(topic)")
          }
        default:
          print("received unknown event: \(event)")
        }

        return .none
      }
    )
    print("starting Home Assistant client")

    do {
      try client.start()
    } catch {
      print("failed")
      sleep_ms(5000)
      return
    }

    print("polling...")

    MGManager.shared.loop()
  }
}
