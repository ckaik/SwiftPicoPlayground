import CMongoose

extension MQTTClient {
  public func connect() throws(MQTTClientError) {
    _ = try doConnect()

    if options.reconnectAutomatically {
      setupReconnectTimer()
    }
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
    let clientID = try ManagedCString(options.clientID, or: MQTTClientError.connectionFailed)
    defer { clientID.cleanup() }

    let user: ManagedCString?
    if let username = options.username {
      user = try ManagedCString(username, or: MQTTClientError.connectionFailed)
    } else {
      user = nil
    }
    defer {
      user?.cleanup()
    }

    let pass: ManagedCString?
    if let password = options.password {
      pass = try ManagedCString(password, or: MQTTClientError.connectionFailed)
    } else {
      pass = nil
    }
    defer {
      pass?.cleanup()
    }

    var mgOptions = mg_mqtt_opts()
    mgOptions.client_id = mg_str_s(clientID.pointer)

    if let user {
      mgOptions.user = mg_str_s(user.pointer)
    }

    if let pass {
      mgOptions.pass = mg_str_s(pass.pointer)
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

  private func setupReconnectTimer() {
    let context = Unmanaged.passUnretained(self).toOpaque()
    MGManager.shared.withManagerPointer { manager in
      timer = mg_timer_add(manager, 1000, UInt32(MG_TIMER_REPEAT), onReconnectTimerTicked, context)
    }
  }
}
