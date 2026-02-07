import CPicoSDK

extension Cyw43Manager {
  public enum GPIOPin: UInt32 {
    case led = 0  // Onboard LED pin
    case wlanTx = 4  // WLAN TX pin
    case wlanRx = 5  // WLAN RX pin
  }
}

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

  public subscript(pin: GPIOPin) -> Bool {
    get { get(pin) }
    set { set(pin, to: newValue) }
  }

  public func set(_ pin: GPIOPin, to value: Bool) {
    cyw43_arch_gpio_put(pin.rawValue, value)
  }

  public func get(_ pin: GPIOPin) -> Bool {
    cyw43_arch_gpio_get(pin.rawValue)
  }
}
