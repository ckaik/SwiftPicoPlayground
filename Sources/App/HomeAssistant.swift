import CPicoSDK
import HomeAssistantKit
import MongooseKit

func startHomeAssistant(red: LEDController, green: LEDController, blue: LEDController)
  -> HomeAssistantRouter
{
  let ledConfig = [
    "schema": JSONEncodedValue.string("json"),
    "brightness": JSONEncodedValue.bool(true),
    "brightness_scale": JSONEncodedValue.number("255"),
    "enabled_by_default": JSONEncodedValue.bool(true),
    "effect": JSONEncodedValue.bool(true),
    "effect_list": JSONEncodedValue.array([
      .string("Breathe"),
      .string("Strobe"),
      .string("Heartbeat"),
      .string("Ping Pong Fade"),
      .string("Candle"),
      .string("Pulse Hold"),
      .string("Police Flash"),
      .string("Flicker"),
    ]),
    "flash": JSONEncodedValue.bool(false),
    "transition": JSONEncodedValue.bool(false),
  ]
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

  do {
    try router.start()
  } catch {
    print("failed")
    sleep_ms(5000)
    fatalError()
  }

  return router
}
