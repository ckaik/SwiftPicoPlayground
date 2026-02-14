public struct MQTTClientOptions {
  public var host: String
  public var port: UInt16
  public var clientID: String
  public var username: String?
  public var password: String?
  public var topic: String
  public var reconnectAutomatically: Bool

  public init(
    host: String,
    port: UInt16 = 1883,
    clientID: String,
    username: String? = nil,
    password: String? = nil,
    topic: String,
    reconnectAutomatically: Bool = true
  ) {
    self.host = host
    self.port = port
    self.clientID = clientID
    self.username = username
    self.password = password
    self.topic = topic
    self.reconnectAutomatically = reconnectAutomatically
  }
}

public enum MQTTClientError: Error {
  case connectionFailed
}
