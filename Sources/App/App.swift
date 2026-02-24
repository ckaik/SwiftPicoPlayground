import CPicoSDK
import Common
import HomeAssistantKit
import MongooseKit
import PicoKit
import _Concurrency

@main
struct App {
  enum AppError: Error {
    case cyw43InitializationFailed(PicoError)
  }

  private static let microsecondsPerMillisecond: UInt64 = 1_000

  static func main() async throws(AppError) {
    stdio_init_all()

    let red: LEDController = LEDController(output: .init(pin: 15))
    let green = LEDController(output: .init(pin: 14))
    let blue = LEDController(output: .init(pin: 17))

    red.off()
    green.off()
    blue.off()

    print("running async startup demo...")
    await runAsyncStartupDemo(red: red, green: green, blue: blue)

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

  private static func runAsyncStartupDemo(
    red: LEDController, green: LEDController, blue: LEDController
  ) async {
    await withTaskGroup {
      $0.addTask {
        await blink(
          controller: red,
          brightness: 1,
          onMilliseconds: 120,
          offMilliseconds: 120,
          times: 10
        )
      }

      $0.addTask {
        await blink(
          controller: green,
          brightness: 1,
          onMilliseconds: 120,
          offMilliseconds: 120,
          times: 15
        )
      }

      $0.addTask {
        await blink(
          controller: blue,
          brightness: 1,
          onMilliseconds: 120,
          offMilliseconds: 120,
          times: 20
        )
      }

      await $0.waitForAll()
    }

    red.off()
    green.off()
    blue.off()
  }

  private static func blink(
    controller: LEDController,
    brightness: Float,
    onMilliseconds: UInt64,
    offMilliseconds: UInt64,
    times: Int
  ) async {
    guard times > 0 else { return }

    var remainingIterations = times
    while remainingIterations > 0 {
      controller.on(at: brightness)
      await sleep(milliseconds: onMilliseconds)
      controller.off()
      await sleep(milliseconds: offMilliseconds)
      remainingIterations -= 1
    }
  }

  private static func sleep(milliseconds: UInt64) async {
    let targetDelayMicros = milliseconds * microsecondsPerMillisecond
    let start = time_us_64()
    while time_us_64() - start < targetDelayMicros {
      await Task.yield()
    }
  }
}
