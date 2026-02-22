import CMongoose

func mqttEventHandler(
  conn: UnsafeMutablePointer<mg_connection>?,
  ev: Int32,
  evData: UnsafeMutableRawPointer?
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

func onReconnectTimerTicked(_ value: UnsafeMutableRawPointer?) {
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
