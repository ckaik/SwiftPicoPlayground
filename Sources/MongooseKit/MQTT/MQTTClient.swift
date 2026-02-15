import CMongoose

public final class MQTTClient {
  private let options: MQTTClientOptions
  private var timer: UnsafeMutablePointer<mg_timer>?

  fileprivate(set) var isConnected = false
  fileprivate(set) var isConnecting = false
  fileprivate(set) var currentConnection: UnsafeMutablePointer<mg_connection>?

  private var topics: Set<String> = .init()
  private var handlers: [String: (MQTTMessage) -> Void] = [:]

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

  public func connect() throws(MQTTClientError) {
    _ = try doConnect()

    if options.reconnectAutomatically {
      setupReconnectTimer()
    }
  }

  public func on(_ topic: String, handler: @escaping (MQTTMessage) -> Void) {
    handlers[topic] = handler
    subscribe(to: topic)
  }

  func handle(_ message: MQTTMessage) {
    handlers[message.topic]?(message)
  }

  func onConnect(_ conn: UnsafeMutablePointer<mg_connection>) {
    guard conn == currentConnection else { return }
    isConnecting = false
    isConnected = true
    subscribe()
  }

  private func subscribe() {
    for topic in topics {
      subscribe(to: topic)
    }
  }

  func onDisconnect(_ conn: UnsafeMutablePointer<mg_connection>) {
    guard conn == currentConnection else { return }
    isConnecting = false
    isConnected = false
    currentConnection = nil
  }

  func reconnectIfNecessary() -> Bool {
    guard options.reconnectAutomatically else {
      return false
    }

    do {
      _ = try doConnect()
      return true
    } catch {
      return false
    }
  }

  private func doConnect() throws(MQTTClientError) -> UnsafeMutablePointer<mg_connection> {
    let clientID = try makeCString(options.clientID)
    defer { mg_free(clientID) }

    let message = try makeCString("bye")
    defer { mg_free(message) }

    let user: UnsafeMutablePointer<CChar>? = try options.username.map(makeCString)
    defer {
      user.map { mg_free($0) }
    }

    let pass: UnsafeMutablePointer<CChar>? = try options.password.map(makeCString)
    defer {
      pass.map { mg_free($0) }
    }

    var mgOptions = mg_mqtt_opts()
    mgOptions.client_id = mg_str_s(clientID)

    if let user {
      mgOptions.user = mg_str_s(user)
    }

    if let pass {
      mgOptions.pass = mg_str_s(pass)
    }

    mgOptions.message = mg_str_s(message)
    mgOptions.keepalive = 60
    mgOptions.clean = true
    mgOptions.qos = 1
    mgOptions.version = 4

    let fnData = Unmanaged.passUnretained(self).toOpaque()
    let connection: UnsafeMutablePointer<mg_connection>? = MGManager.shared.withManagerPointer {
      manager in
      "mqtt://\(options.host):\(options.port)".withCString { url in
        mg_mqtt_connect(manager, url, &mgOptions, mqttEventHandler, fnData)
      }
    }

    guard let connection else {
      throw MQTTClientError.connectionFailed
    }

    isConnecting = true
    currentConnection = connection
    return connection
  }

  private func subscribe(to topic: String) {
    guard let conn = currentConnection else { return }

    topic.withCString { topic in
      var opts = mg_mqtt_opts()
      opts.topic = mg_str_s(topic)
      mg_mqtt_sub(conn, &opts)
    }
    topics.insert(topic)
  }

  private func setupReconnectTimer() {
    let context = Unmanaged.passUnretained(self).toOpaque()
    MGManager.shared.withManagerPointer { manager in
      timer = mg_timer_add(manager, 1000, UInt32(MG_TIMER_REPEAT), onReconnectTimerTicked, context)
    }
  }

  private func makeCString(_ value: String) throws(MQTTClientError) -> UnsafeMutablePointer<CChar> {
    guard let copy = value.withCString({ strdup($0) }) else {
      throw MQTTClientError.connectionFailed
    }

    return copy
  }
}

private func mqttEventHandler(
  conn: UnsafeMutablePointer<mg_connection>?, ev: Int32, evData: UnsafeMutableRawPointer?
) {
  guard
    let conn,
    let rawClient = conn.pointee.fn_data
  else {
    return
  }

  let client = Unmanaged<MQTTClient>.fromOpaque(rawClient).takeUnretainedValue()

  switch Int(ev) {
  case MG_EV_MQTT_OPEN:
    client.onConnect(conn)
  case MG_EV_MQTT_MSG:
    guard let mqttMsg = evData?.assumingMemoryBound(to: mg_mqtt_message.self) else {
      return
    }

    client.handle(MQTTMessage(mqttMsg.pointee))
  case MG_EV_CLOSE:
    client.onDisconnect(conn)
  default:
    break
  }
}

private func onReconnectTimerTicked(_ value: UnsafeMutableRawPointer?) {
  guard let value else { return }

  let client = Unmanaged<MQTTClient>.fromOpaque(value).takeUnretainedValue()

  if client.isConnected {
    mg_mqtt_ping(client.currentConnection)
    return
  }

  guard !client.isConnecting else {
    return
  }

  _ = client.reconnectIfNecessary()
}
