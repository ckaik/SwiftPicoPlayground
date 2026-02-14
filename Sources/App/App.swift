import Common
import Mongoose

@main
struct App {
  enum AppError: Error {
    case wifiConnectFailed
  }

  private static var ssidCString: UnsafeMutablePointer<CChar>?
  private static var passwordCString: UnsafeMutablePointer<CChar>?

  private static func makeCString(_ string: String) -> UnsafeMutablePointer<CChar> {
    let bytes = Array(string.utf8CString)
    let ptr = UnsafeMutablePointer<CChar>.allocate(capacity: bytes.count)
    ptr.initialize(from: bytes, count: bytes.count)
    return ptr
  }

  private static func mongooseSecurity(for mode: WiFiAuthenticationMode) -> UInt8 {
    switch mode {
    case .open:
      return UInt8(MG_WIFI_SECURITY_OPEN)
    case .wpaTkipPsk:
      return UInt8(MG_WIFI_SECURITY_WPA)
    case .wpa2AesPsk, .wpa2MixedPsk:
      return UInt8(MG_WIFI_SECURITY_WPA2)
    case .wpa3SaeAesPsk:
      return UInt8(MG_WIFI_SECURITY_WPA3)
    case .wpa3Wpa2AesPsk:
      return UInt8(MG_WIFI_SECURITY_WPA2 | MG_WIFI_SECURITY_WPA3)
    }
  }

  static func main() throws(AppError) {
    stdio_init_all()

    let red = Pin(number: 15)
    let blue = Pin(number: 17)

    ssidCString = makeCString(Secrets.ssid)
    passwordCString = makeCString(Secrets.password)

    var wifi = mg_wifi_data()
    wifi.ssid = ssidCString
    wifi.pass = passwordCString
    wifi.security = mongooseSecurity(for: Secrets.mode)
    wifi.apmode = false

    var mgr = mg_mgr()
    mg_mgr_init(&mgr)

    guard mg_wifi_connect(&wifi) else {
      red.on()
      CPicoSDK.sleep_ms(5000)
      throw .wifiConnectFailed
    }

    blue.on()

    while true {
      mg_mgr_poll(&mgr, 100)
    }
  }
}
