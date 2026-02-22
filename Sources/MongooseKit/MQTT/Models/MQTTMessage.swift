import CMongoose

public struct MQTTMessage {
  public let topic: String
  public let payload: [UInt8]

  init(_ message: mg_mqtt_message) {
    self.topic = message.topic.toString() ?? ""
    self.payload = message.data.toByteArray()
  }

  public var payloadString: String? {
    guard !payload.isEmpty else { return nil }
    return payload.withUnsafeBufferPointer { buffer -> String? in
      String(validating: buffer, as: UTF8.self)
    }
  }
}
