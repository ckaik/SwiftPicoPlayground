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

    let red = Pin(number: 15)
    let green = Pin(number: 14)
    let blue = Pin(number: 17)

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

    var redState = false {
      didSet {
        redState ? red.on() : red.off()
      }
    }
    var greenState = false {
      didSet {
        greenState ? green.on() : green.off()
      }
    }
    var blueState = false {
      didSet {
        blueState ? blue.on() : blue.off()
      }
    }

    let pwm = PWMConfig(frequencyHz: 1000, wrap: 4095)
    let client = HomeAssistantClient(
      mqttConfig: MQTTConfig(
        host: "10.0.0.101",
        username: Secrets.mqttUser,
        password: Secrets.mqttPassword
      ),
      discovery: DiscoveryConfig(objectId: "Pico2W"),
      discoveryPayload: DiscoveryPayload(
        qos: 0,
        device: Device(
          ids: "pico2w",
          name: "Pico2W",
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
            name: "Red LED",
            stateTopic: "pico2w/leds/red/state",
            commandTopic: "pico2w/leds/red/set",
            data: ledConfig
          ),
          "green": Component(
            id: "led.green",
            kind: .light,
            name: "Green LED",
            stateTopic: "pico2w/leds/green/state",
            commandTopic: "pico2w/leds/green/set",
            data: ledConfig
          ),
          "blue": Component(
            id: "led.blue",
            kind: .light,
            name: "Blue LED",
            stateTopic: "pico2w/leds/blue/state",
            commandTopic: "pico2w/leds/blue/set",
            data: ledConfig
          ),
        ]
      ),
      state: { _, cmp in
        switch cmp.id {
        case "led.red":
          return .init(rawValue: LightState(state: redState, brightness: 255).json)
        case "led.green":
          return .init(rawValue: LightState(state: greenState, brightness: 255).json)
        case "led.blue":
          return .init(rawValue: LightState(state: blueState, brightness: 255).json)
        default:
          print("unknown component id: \(cmp.id)")
          return nil
        }
      },
      handler: { event in
        switch event {
        case .didReceiveMessage(let topic, let payload):
          print("received message on topic \(topic.rawValue): \(payload.rawValue)")

          if topic.rawValue == "pico2w/leds/red/set" {
            if let state = try? LightState.from(json: payload) {
              if let isOn = state.state {
                redState = isOn
              } else {
                print("missing 'state' field in payload for red LED: \(payload.rawValue)")
              }
            } else {
              print("failed to decode payload for red LED: \(payload.rawValue)")
            }
          } else if topic.rawValue == "pico2w/leds/green/set" {
            if let state = try? LightState.from(json: payload), let isOn = state.state {
              greenState = isOn
            } else {
              print("failed to decode payload for green LED: \(payload.rawValue)")
            }
          } else if topic.rawValue == "pico2w/leds/blue/set" {
            if let state = try? LightState.from(json: payload), let isOn = state.state {
              blueState = isOn
            } else {
              print("failed to decode payload for blue LED: \(payload.rawValue)")
            }
          } else {
            print("unknown topic: \(topic.rawValue)")
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
      green.pwm(.flicker(), config: pwm)
      red.pwm(.flicker(), config: pwm)
      blue.pwm(.flicker(), config: pwm)

      sleep_ms(5000)
      return
    }

    print("polling...")

    MGManager.shared.loop()
  }
}
