import Common
import MongooseKit

public struct Light: MGJSONDecodable {
  public let brightness: UInt8
  public let isOn: Bool?

  public init(brightness: UInt8, isOn: Bool?) {
    self.brightness = brightness
    self.isOn = isOn
  }

  public init(reader: MGJSONParser) throws(MGJSONDecodingError) {
    self.brightness = (try? reader.number("$.brightness")) ?? 255
    self.isOn = try? reader.bool("$.state")
  }
}

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

    do {
      try MGManager.shared.connectToWiFi(
        ssid: Secrets.ssid,
        password: Secrets.password,
        security: Secrets.mode
      )
      blue.on()
    } catch {
      red.on()
      CPicoSDK.sleep_ms(10000)
      return
    }

    MGManager.shared.waitForReady()

    let client = MQTTClient(
      options: MQTTClientOptions(
        host: "10.0.0.101",
        clientID: "pico",
        username: Secrets.mqttUser,
        password: Secrets.mqttPassword,
        topic: "pico/test",
        reconnectAutomatically: true
      ))

    let pwm = PWMConfig(frequencyHz: 1000, wrap: 4095)

    client.on("pico/test") { message in
      if let light = try? MGJSONDecoder().decode(Light.self, from: message.payload) {
        if let isOn = light.isOn, isOn {
          red.pwm(
            .dim(brightness: Float(light.brightness) / 255),
            config: pwm
          )
        } else {
          red.pwm(.off, config: pwm)
        }
      }
    }

    do {
      try client.connect()
      green.pwm(.dim(brightness: 0.5), config: pwm)
    } catch {
      red.pwm(.flicker(), config: pwm)
    }

    MGManager.shared.loop()
  }
}
