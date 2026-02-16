import MongooseKit

public final class HomeAssistantRouter {
  public struct DeviceOptions {
    public var manufacturer: String?
    public var serialNumber: String?
    public var hardwareVersion: String?
    public var softwareVersion: String?
    public var configurationUrl: String?

    public init(
      manufacturer: String? = nil,
      serialNumber: String? = nil,
      hardwareVersion: String? = nil,
      softwareVersion: String? = nil,
      configurationUrl: String? = nil
    ) {
      self.manufacturer = manufacturer
      self.serialNumber = serialNumber
      self.hardwareVersion = hardwareVersion
      self.softwareVersion = softwareVersion
      self.configurationUrl = configurationUrl
    }
  }

  public struct Light {
    public var key: String
    public var componentID: String
    public var name: String
    public var stateTopic: String?
    public var commandTopic: String?
    public var discoveryData: [String: JSONValue]?
    public var initialState: LightState?
    public var onCommand: (LightState) -> LightState?

    public init(
      key: String,
      componentID: String? = nil,
      name: String,
      stateTopic: String? = nil,
      commandTopic: String? = nil,
      discoveryData: [String: JSONValue]? = nil,
      initialState: LightState? = nil,
      onCommand: @escaping (LightState) -> LightState?
    ) {
      self.key = key
      self.componentID = componentID ?? key
      self.name = name
      self.stateTopic = stateTopic
      self.commandTopic = commandTopic
      self.discoveryData = discoveryData
      self.initialState = initialState
      self.onCommand = onCommand
    }
  }

  private struct ResolvedLight {
    let key: String
    let componentID: String
    let stateTopic: String
    let commandTopic: String
    let onCommand: (LightState) -> LightState?
  }

  private let mqttConfig: MQTTConfig
  private let discovery: DiscoveryConfig
  private let discoveryPayload: DiscoveryPayload
  private var lightsByCommandTopic: [String: ResolvedLight] = [:]
  private var lightsByComponentID: [String: ResolvedLight] = [:]
  private var statesByComponentID: [String: LightState] = [:]

  private var client: HomeAssistantClient?

  public init(
    mqttConfig: MQTTConfig,
    deviceId: String,
    deviceName: String,
    objectId: String,
    lights: [Light],
    discoveryPrefix: String = "homeassistant",
    discoveryNodeID: String? = nil,
    device: DeviceOptions = .init()
  ) {
    self.mqttConfig = mqttConfig
    self.discovery = DiscoveryConfig(
      prefix: discoveryPrefix,
      nodeId: discoveryNodeID,
      objectId: objectId
    )

    var components: [String: Component] = [:]
    var lightsByCommandTopic: [String: ResolvedLight] = [:]
    var lightsByComponentID: [String: ResolvedLight] = [:]
    var statesByComponentID: [String: LightState] = [:]

    for light in lights {
      let componentID = light.componentID
      let stateTopic = light.stateTopic ?? "\(deviceId)/lights/\(light.key)/state"
      let commandTopic = light.commandTopic ?? "\(deviceId)/lights/\(light.key)/set"

      let component = Component(
        id: componentID,
        kind: .light,
        name: light.name,
        stateTopic: stateTopic,
        commandTopic: commandTopic,
        data: light.discoveryData
      )
      components[light.key] = component

      let resolved = ResolvedLight(
        key: light.key,
        componentID: componentID,
        stateTopic: stateTopic,
        commandTopic: commandTopic,
        onCommand: light.onCommand
      )
      lightsByCommandTopic[commandTopic] = resolved
      lightsByComponentID[componentID] = resolved

      if let initialState = light.initialState {
        statesByComponentID[componentID] = initialState
      }
    }

    self.lightsByCommandTopic = lightsByCommandTopic
    self.lightsByComponentID = lightsByComponentID
    self.statesByComponentID = statesByComponentID

    self.discoveryPayload = DiscoveryPayload(
      device: Device(
        ids: deviceId,
        name: deviceName,
        manufacturer: device.manufacturer,
        serialNumber: device.serialNumber,
        hardwareVersion: device.hardwareVersion,
        softwareVersion: device.softwareVersion,
        configurationUrl: device.configurationUrl
      ),
      components: components
    )
  }

  public func setup() {
    guard client == nil else { return }

    client = HomeAssistantClient(
      mqttConfig: mqttConfig,
      discovery: discovery,
      discoveryPayload: discoveryPayload,
      state: { componentID, _ in
        statesByComponentID[componentID]?.json
      },
      handler: handle(event:)
    )
  }

  public func start() throws(HomeAssistantError) {
    if client == nil {
      setup()
    }

    guard let client else { return }
    try client.start()
  }

  private func handle(event: Event) -> Effect {
    switch event {
    case .onConnect:
      return .none

    case .didReceiveMessage(let topic, let payload):
      guard let light = lightsByCommandTopic[topic] else {
        return .none
      }

      guard let command = try? LightState.from(json: payload) else {
        return .none
      }

      guard let newState = light.onCommand(command) else {
        return .none
      }

      statesByComponentID[light.componentID] = newState
      return .publish(topic: light.stateTopic, content: newState.json)
    }
  }
}
