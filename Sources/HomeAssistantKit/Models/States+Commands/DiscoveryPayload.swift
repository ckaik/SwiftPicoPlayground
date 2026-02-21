import Common
import MongooseKit

@JSONEncodable
public struct DiscoveryPayload: State {
  public var qos: Int

  @JSON("dev")
  public var device: Device

  @JSON("o")
  public var origin: Origin

  @JSON("cmps")
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
}

@JSONEncodable
public struct Device: State {
  public var ids: String
  public var name: String

  @JSON("mf")
  public var manufacturer: String?

  @JSON("sn")
  public var serialNumber: String?

  @JSON("hw")
  public var hardwareVersion: String?

  @JSON("sw")
  public var softwareVersion: String?

  @JSON("cu")
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
}

@JSONEncodable
public struct Origin: State {
  public let name: String = "HomeAssistantKit"

  @JSON("sw")
  public let softwareVersion: String = "1.0.0"

  @JSON("url")
  public let supportUrl: String = "https://github.com/ckaik/SwiftPicoPlayground"

  public init() {}
}

public struct Component: State {
  @JSONEncodable
  public enum Kind: String {
    case light
  }

  public var id: String
  public var kind: Kind
  public var name: String
  public var stateTopic: String
  public var commandTopic: String
  public var data: [String: JSONEncodedValue]?

  public init(
    id: String,
    kind: Kind,
    name: String,
    stateTopic: String,
    commandTopic: String,
    data: [String: JSONEncodedValue]? = nil
  ) {
    self.id = id
    self.kind = kind
    self.name = name
    self.stateTopic = stateTopic
    self.commandTopic = commandTopic
    self.data = data
  }

  public func encode(encoder: JSONEncoder) throws(JSONEncodingError) -> JSONEncodedValue {
    var object: [String: JSONEncodedValue] = [
      "unique_id": try encoder.box(id),
      "p": try encoder.box(kind.rawValue),
      "name": try encoder.box(name),
      "stat_t": try encoder.box(stateTopic),
      "cmd_t": try encoder.box(commandTopic),
    ]

    if let data {
      for (key, value) in data {
        object[key] = value
      }
    }

    return .object(object)
  }
}
