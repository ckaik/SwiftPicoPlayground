import Common

public enum JSONValue {
  case string(String)
  case floatingPoint(Double)
  case number(Int)
  case bool(Bool)
  case object([String: JSONValue])
  case array([JSONValue])
  case null

  public var json: String {
    switch self {
    case .string(let str):
      return "\"\(str)\""
    case .floatingPoint(let num):
      return "\(num)"
    case .number(let num):
      return "\(num)"
    case .bool(let bool):
      return bool ? "true" : "false"
    case .object(let obj):
      let objJson = obj.map { "\"\($0)\": \($1.json)" }.joined(separator: ",")
      return "{ \(objJson) }"
    case .array(let arr):
      let arrJson = arr.map { $0.json }.joined(separator: ",")
      return "[ \(arrJson) ]"
    case .null:
      return "null"
    }
  }
}

public struct DiscoveryPayload: State {
  public var qos: Int
  public var device: Device
  public var origin: Origin
  public var components: [String: Component]

  public init(
    qos: Int = 0,
    device: Device,
    components: [String: Component]
  ) {
    self.qos = qos
    self.device = device
    self.origin = Origin()
    self.components = components
  }

  public var json: String {
    let componentsJson = components.map { "\"\($0.key)\": \($0.value.json)" }.joined(
      separator: ",")
    return """
      {
        "qos": \(qos),
        "dev": \(device.json),
        "o": \(origin.json),
        "cmps": { \(componentsJson) }
      }
      """
  }
}

public struct Device: State {
  public var ids: String
  public var name: String
  public var manufacturer: String?
  public var serialNumber: String?
  public var hardwareVersion: String?
  public var softwareVersion: String?
  public var configurationUrl: String?

  public init(
    ids: String,
    name: String,
    manufacturer: String? = nil,
    serialNumber: String? = nil,
    hardwareVersion: String? = nil,
    softwareVersion: String? = nil,
    configurationUrl: String? = nil
  ) {
    self.ids = ids
    self.name = name
    self.manufacturer = manufacturer
    self.serialNumber = serialNumber
    self.hardwareVersion = hardwareVersion
    self.softwareVersion = softwareVersion
    self.configurationUrl = configurationUrl
  }

  public var json: String {
    """
    {
      "ids": ["\(ids)"],
      "name": "\(name)",
      "mf": \(manufacturer.map { "\"\($0)\"" } ?? "null"),
      "sn": \(serialNumber.map { "\"\($0)\"" } ?? "null"),
      "hw": \(hardwareVersion.map { "\"\($0)\"" } ?? "null"),
      "sw": \(softwareVersion.map { "\"\($0)\"" } ?? "null"),
      "cu": \(configurationUrl.map { "\"\($0)\"" } ?? "null")
    }
    """
  }
}

public struct Origin: State {
  public let name = "HomeAssistantKit"
  public let softwareVersion = "1.0.0"
  public let supportUrl = "https://github.com/ckaik/SwiftPicoPlayground"

  public init() {}

  public var json: String {
    """
    {
      "name": "\(name)",
      "sw": "\(softwareVersion)",
      "url": "\(supportUrl)"
    }
    """
  }
}

public struct Component: State {
  public enum Kind: String {
    case light
  }

  public var id: String
  public var kind: Kind
  public var name: String
  public var stateTopic: String
  public var commandTopic: String
  public var data: [String: JSONValue]?

  public init(
    id: String,
    kind: Kind,
    name: String,
    stateTopic: String,
    commandTopic: String,
    data: [String: JSONValue]? = nil
  ) {
    self.id = id
    self.kind = kind
    self.name = name
    self.stateTopic = stateTopic
    self.commandTopic = commandTopic
    self.data = data
  }

  public var json: String {
    let dataJson = data?.map { "\"\($0)\": \($1.json)" }.joined(separator: ",") ?? ""

    return """
      {
        \(dataJson.isEmpty ? "" : "\(dataJson),")
        "unique_id": "\(id)",
        "p": "\(kind.rawValue)",
        "name": "\(name)",
        "stat_t": "\(stateTopic)",
        "cmd_t": "\(commandTopic)"
      }
      """
  }
}
