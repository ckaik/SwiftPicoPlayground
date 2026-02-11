import CPicoSDK

public final class Cyw43Manager {
  public static let shared = Cyw43Manager()

  private init() {}

  deinit {
    cyw43_arch_deinit()
  }

  public func initialize() throws(PicoError) {
    let rawResult = cyw43_arch_init()
    let result = unsafeBitCast(rawResult, to: pico_error_codes.self)

    if result != PICO_OK {
      throw .init(rawValue: rawResult) ?? .unknown
    }
  }

  public func connectToWiFi(
    _ ssid: String,
    password: String,
    auth: WiFiAuthenticationMode,
    timeout: Float = 30
  ) throws(PicoError) {
    cyw43_arch_enable_sta_mode()

    let rawResult = cyw43_arch_wifi_connect_timeout_ms(
      ssid,
      password,
      auth.rawValue,
      UInt32(ceilf(timeout * 1000))
    )

    let result = unsafeBitCast(rawResult, to: pico_error_codes.self)

    if result != PICO_OK {
      throw .init(rawValue: rawResult) ?? .unknown
    }
  }

  public func loop() {
    while true {
      cyw43_arch_wait_for_work_until(.max)
    }
  }
}
