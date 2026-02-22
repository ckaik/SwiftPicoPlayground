import CMongoose

extension MGManager {
  public struct WiFiSecurity: OptionSet {
    public let rawValue: UInt8

    public static let `open` = WiFiSecurity([])
    public static let wep = WiFiSecurity(rawValue: 1 << 0)
    public static let wpa = WiFiSecurity(rawValue: 1 << 1)
    public static let wpa2 = WiFiSecurity(rawValue: 1 << 2)
    public static let wpa3 = WiFiSecurity(rawValue: 1 << 3)

    public init(rawValue: UInt8) {
      self.rawValue = rawValue
    }
  }

  public func connectToWiFi(ssid: String, password: String, security: WiFiSecurity) throws(MGError)
  {
    var wifi = mg_wifi_data()
    let ssidCString = try ManagedCString(ssid, or: MGError.wifiConnectFailed)
    let passwordCString = try ManagedCString(password, or: MGError.wifiConnectFailed)

    wifi.ssid = ssidCString.pointer
    wifi.pass = passwordCString.pointer
    wifi.security = security.rawValue
    wifi.apmode = false

    let didConnect = mg_wifi_connect(&wifi)

    ssidCString.cleanup()
    passwordCString.cleanup()

    if !didConnect {
      throw MGError.wifiConnectFailed
    }
  }
}
