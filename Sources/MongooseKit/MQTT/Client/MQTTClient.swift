import CMongoose

public final class MQTTClient {
  let options: MQTTClientOptions
  var timer: UnsafeMutablePointer<mg_timer>?
  var onConnectCallback: (() -> Void)?
  var onErrorCallback: ((String) -> Void)?
  var onDisconnectCallback: ((String?) -> Void)?
  var lastErrorMessage: String?

  var isConnected = false
  var isConnecting = false
  var currentConnection: UnsafeMutablePointer<mg_connection>?

  var topics: Set<String> = .init()
  var handlers: [String: (MQTTMessage) -> Void] = [:]

  public init(options: MQTTClientOptions) {
    self.options = options
  }

  deinit {
    if let timer {
      MGManager.shared.withManagerPointer { manager in
        mg_timer_free(&manager.pointee.timers, timer)
      }
    }
  }

  public func onConnect(_ callback: @escaping () -> Void) {
    onConnectCallback = callback
  }

  public func onError(_ callback: @escaping (String) -> Void) {
    onErrorCallback = callback
  }

  public func onDisconnect(_ callback: @escaping (String?) -> Void) {
    onDisconnectCallback = callback
  }

  public func publish(_ payload: String, on topic: String) {
    guard let conn = currentConnection else {
      // TODO: should we buffer messages and send them when the connection is back?
      return
    }

    topic.withCString { topic in
      payload.withCString { payload in
        var opts = mg_mqtt_opts()
        opts.topic = mg_str_s(topic)
        opts.message = mg_str_s(payload)
        opts.retain = true
        mg_mqtt_pub(conn, &opts)
      }
    }
  }

  func handle(_ message: MQTTMessage) {
    handlers[message.topic]?(message)
  }

  func onConnect(_ conn: UnsafeMutablePointer<mg_connection>) {
    guard conn == currentConnection else { return }
    isConnecting = false
    isConnected = true
    lastErrorMessage = nil
    onConnectCallback?()
    subscribe()
  }

  func onDisconnect(_ conn: UnsafeMutablePointer<mg_connection>) {
    guard conn == currentConnection else { return }
    let reason = lastErrorMessage
    isConnecting = false
    isConnected = false
    currentConnection = nil
    lastErrorMessage = nil
    onDisconnectCallback?(reason)
  }

  func handleError(_ conn: UnsafeMutablePointer<mg_connection>, _ message: String) {
    guard conn == currentConnection else { return }
    lastErrorMessage = message
    onErrorCallback?(message)
  }
}
