public struct MQTTTopicKey: Hashable, ExpressibleByStringLiteral {
  public let bytes: [UInt8]

  public init(_ topic: String) {
    bytes = topic.utf8Bytes
  }

  public init(stringLiteral value: String) {
    self.init(value)
  }
}

extension String {
  fileprivate var utf8Bytes: [UInt8] {
    var bytes: [UInt8] = []
    bytes.reserveCapacity(utf8.count)
    for byte in utf8 {
      bytes.append(byte)
    }
    return bytes
  }
}
