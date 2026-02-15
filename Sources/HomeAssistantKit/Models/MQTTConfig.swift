public struct MQTTConfig {
  let host: String
  let port: UInt16
  let clientId: String
  let username: String?
  let password: String?

  public init(
    host: String,
    port: UInt16 = 1883,
    clientId: String = "HomeAssistantKit",
    username: String? = nil,
    password: String? = nil
  ) {
    self.host = host
    self.port = port
    self.clientId = clientId
    self.username = username
    self.password = password
  }
}
