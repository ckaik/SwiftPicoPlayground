import CMongoose

public enum MGError: Error {
  case wifiConnectFailed
}

public final class MGManager {
  public static let shared = MGManager()

  private var manager = mg_mgr()
  private(set) public var isLooping = false

  private init() {
    mg_log_level = Int32(MG_LL_NONE)
    mg_mgr_init(&manager)
  }

  deinit {
    mg_mgr_free(&manager)
  }

  public enum LogLevel {
    case none
    case debug
    case info
    case error

    var mgLevel: Int {
      switch self {
      case .none: MG_LL_NONE
      case .debug: MG_LL_DEBUG
      case .info: MG_LL_INFO
      case .error: MG_LL_ERROR
      }
    }
  }

  public func setLogLevel(_ level: LogLevel) {
    mg_log_level = Int32(level.mgLevel)
  }

  @discardableResult
  public func waitForReady(timeoutMilliseconds: UInt64 = 3_600_000) -> Bool {
    withManagerPointer { manager in
      let deadline = timeoutMilliseconds == 0 ? nil : mg_millis() + timeoutMilliseconds

      while !isInterfaceReady(manager) {
        mg_mgr_poll(manager, 100)

        if let deadline, mg_millis() >= deadline {
          return false
        }
      }

      return true
    }
  }

  public func loop(pollIntervalMS: Int32 = 10) {
    guard !isLooping else { return }
    isLooping = true
    defer { isLooping = false }

    let manager = managerPointer
    while true {
      mg_mgr_poll(manager, pollIntervalMS)
    }
  }
}

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
    let ssidCString = try ManagedCString(ssid)
    let passwordCString = try ManagedCString(password)

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

extension MGManager {
  private var managerPointer: UnsafeMutablePointer<mg_mgr> {
    withUnsafeMutablePointer(to: &manager) { $0 }
  }

  func withManagerPointer<T>(_ body: (UnsafeMutablePointer<mg_mgr>) -> T) -> T {
    withUnsafeMutablePointer(to: &manager, body)
  }

  private func isInterfaceReady(_ manager: UnsafeMutablePointer<mg_mgr>) -> Bool {
    guard let interface = manager.pointee.ifp else { return false }
    return interface.pointee.state == UInt8(MG_TCPIP_STATE_READY)
  }
}

private struct ManagedCString {
  let pointer: UnsafeMutablePointer<CChar>?

  init(_ value: String) throws(MGError) {
    guard let copy = value.withCString({ strdup($0) }) else {
      throw MGError.wifiConnectFailed
    }

    self.pointer = copy
  }

  func cleanup() {
    if let pointer {
      mg_free(pointer)
    }
  }
}
