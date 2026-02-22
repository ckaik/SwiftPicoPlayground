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

  public func loop(pollIntervalMS: Int32 = 100) {
    guard !isLooping else { return }
    isLooping = true
    defer { isLooping = false }

    withManagerPointer { manager in
      while true {
        mg_mgr_poll(manager, pollIntervalMS)
      }
    }
  }
}

extension MGManager {
  func withManagerPointer<T>(_ body: (UnsafeMutablePointer<mg_mgr>) -> T) -> T {
    withUnsafeMutablePointer(to: &manager, body)
  }

  private func isInterfaceReady(_ manager: UnsafeMutablePointer<mg_mgr>) -> Bool {
    guard let interface = manager.pointee.ifp else { return false }
    return interface.pointee.state == UInt8(MG_TCPIP_STATE_READY)
  }
}
