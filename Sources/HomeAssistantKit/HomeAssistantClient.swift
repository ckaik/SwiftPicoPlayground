import Common
import MongooseKit

public struct DiscoveryConfig {
  public var prefix: String
  public var nodeId: String?
  public var objectId: String

  public init(
    prefix: String = "homeassistant",
    nodeId: String? = nil,
    objectId: String
  ) {
    self.prefix = prefix
    self.nodeId = nodeId
    self.objectId = objectId
  }

  public var topic: String {
    if let nodeId = nodeId {
      "\(prefix)/device/\(nodeId)/\(objectId)/config"
    } else {
      "\(prefix)/device/\(objectId)/config"
    }
  }
}

public enum Effect {
  case none
  case publish(topic: MQTTTopicName, content: JSONString)
  case publishMultiple([MQTTTopicName: JSONString])
}

public enum Event {
  case onConnect
  case didReceiveMessage(topic: MQTTTopicName, payload: JSONString)
}

public final class HomeAssistantClient {
  public typealias Handler = (_ event: Event) -> Effect
  public typealias StateHandler = (_ componentId: HomeAssistantComponentID, _ component: Component)
    -> JSONString?

  let mqtt: MQTTClient
  let discovery: DiscoveryConfig
  let discoveryPayload: DiscoveryPayload
  let state: StateHandler
  let handler: Handler

  private var isRunning = false

  lazy private var discoveryTopic = { MQTTTopicName(rawValue: discovery.topic) }()
  lazy private var discoveryPayloadString = { discoveryPayload.json }()

  public init(
    mqttConfig: MQTTConfig,
    discovery: DiscoveryConfig,
    discoveryPayload: DiscoveryPayload,
    state: @escaping StateHandler,
    handler: @escaping Handler
  ) {
    self.discovery = discovery
    self.discoveryPayload = discoveryPayload
    self.state = state
    self.handler = handler
    mqtt = MQTTClient(
      options: .init(
        host: mqttConfig.host,
        port: mqttConfig.port,
        clientID: mqttConfig.clientId,
        username: mqttConfig.username,
        password: mqttConfig.password,
        reconnectAutomatically: true
      )
    )

    mqtt.onConnect(onConnect)
  }

  public func start() throws(HomeAssistantError) {
    guard !isRunning else { return }
    isRunning = true

    do {
      try mqtt.connect()
    } catch {
      isRunning = false
      throw HomeAssistantError.mqtt(error)
    }
  }

  private func onConnect() {
    process(effect: handler(.onConnect))

    mqtt.publish(topic: discoveryTopic.rawValue, payload: discoveryPayloadString)

    for (componentId, component) in discoveryPayload.components {
      // Publish initial state
      if let state = state(componentId, component) {
        mqtt.publish(topic: component.stateTopic, payload: state.rawValue)
      }

      mqtt.on(component.commandTopic) { [self] msg in  // yes, a retain cycle :|
        // Process incoming command
        let topic = MQTTTopicName(rawValue: component.commandTopic)
        let payload = JSONString(rawValue: msg.payloadString ?? "")
        let effect = handler(.didReceiveMessage(topic: topic, payload: payload))

        // Process side effects
        process(effect: effect)

        // Publish updated state after processing the command
        if let state = state(componentId, component) {
          mqtt.publish(topic: component.stateTopic, payload: state.rawValue)
        }
      }
    }
  }

  private func process(effect: Effect) {
    switch effect {
    case .none:
      break
    case .publish(let topic, let content):
      mqtt.publish(topic: topic.rawValue, payload: content.rawValue)
      break
    case .publishMultiple(let messages):
      for (topic, content) in messages {
        mqtt.publish(topic: topic.rawValue, payload: content.rawValue)
      }
    }
  }
}

public enum MQTTTopicNameTag {}
public typealias MQTTTopicName = Tagged<MQTTTopicNameTag, String>

public enum JSONStringTag {}
public typealias JSONString = Tagged<JSONStringTag, String>
