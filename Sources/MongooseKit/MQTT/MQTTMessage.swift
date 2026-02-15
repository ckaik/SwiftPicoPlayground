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

extension mg_str {
  fileprivate func toByteArray() -> [UInt8] {
    guard let buffer = buf, len > 0 else { return [] }
    let rawPointer = UnsafeRawPointer(buffer).assumingMemoryBound(to: UInt8.self)
    let bytes = UnsafeBufferPointer(start: rawPointer, count: Int(len))
    return Array(bytes)
  }

  fileprivate func toString() -> String? {
    let bytes = toByteArray()
    guard !bytes.isEmpty else { return nil }
    return bytes.withUnsafeBufferPointer { buffer -> String? in
      String(validating: buffer, as: UTF8.self)
    }
  }
}
