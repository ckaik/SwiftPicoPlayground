import CMongoose

public final class MQTTClient {
  private let options: MQTTClientOptions
  private var timer: UnsafeMutablePointer<mg_timer>?
  private var onConnectCallback: (() -> Void)?
  private var onErrorCallback: ((String) -> Void)?
  private var onDisconnectCallback: ((String?) -> Void)?
  private var lastErrorMessage: String?

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

  public func onConnect(_ callback: @escaping () -> Void) {
    onConnectCallback = callback
  }

  public func onError(_ callback: @escaping (String) -> Void) {
    onErrorCallback = callback
  }

  public func onDisconnect(_ callback: @escaping (String?) -> Void) {
    onDisconnectCallback = callback
  }

  public func on(_ topic: String, handler: @escaping (MQTTMessage) -> Void) {
    handlers[topic] = handler
    subscribe(to: topic)
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

  private func subscribe() {
    for topic in topics {
      subscribe(to: topic)
    }
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

    mgOptions.keepalive = 60
    mgOptions.clean = true
    mgOptions.qos = 0
    mgOptions.version = 4  // 3.1.1

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
  case MG_EV_MQTT_OPEN: handleMQTTOpen(conn: conn, client: client, evData: evData)
  case MG_EV_MQTT_MSG: handleMQTTMessage(client: client, evData: evData)
  case MG_EV_ERROR: handleMQTTError(conn: conn, client: client, evData: evData)
  case MG_EV_CLOSE: client.onDisconnect(conn)
  default: break
  }
}

private func handleMQTTOpen(
  conn: UnsafeMutablePointer<mg_connection>,
  client: MQTTClient,
  evData: UnsafeMutableRawPointer?
) {
  let ack = evData?.assumingMemoryBound(to: UInt8.self).pointee ?? 0
  if ack == 0 {
    client.onConnect(conn)
  } else {
    client.handleError(conn, "MQTT CONNACK rejected (code \(ack)): \(mqttConnackMessage(ack))")
  }
}

private func handleMQTTMessage(client: MQTTClient, evData: UnsafeMutableRawPointer?) {
  guard let mqttMsg = evData?.assumingMemoryBound(to: mg_mqtt_message.self) else { return }
  client.handle(MQTTMessage(mqttMsg.pointee))
}

private func handleMQTTError(
  conn: UnsafeMutablePointer<mg_connection>,
  client: MQTTClient,
  evData: UnsafeMutableRawPointer?
) {
  guard let errorCString = evData?.assumingMemoryBound(to: CChar.self) else { return }
  let message = String(validatingUTF8: errorCString) ?? "unknown error"
  client.handleError(conn, message)
}

private func mqttConnackMessage(_ code: UInt8) -> String {
  switch code {
  case 1: "unacceptable protocol version"
  case 2: "identifier rejected"
  case 3: "server unavailable"
  case 4: "bad username or password"
  case 5: "not authorized"
  default: "unknown reason"
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
