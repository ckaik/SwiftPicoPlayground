import MongooseKit

@JSONCodable
public struct LightState: Command, State {
  public var mode: Mode?
  public var state: Bool?
  public var brightness: UInt8?
  public var effect: String?
  public var transition: Float?

  public init(
    mode: Mode? = nil,
    state: Bool? = nil,
    brightness: UInt8? = nil,
    effect: String? = nil,
    transition: Float? = nil
  ) {
    self.mode = mode
    self.state = state
    self.brightness = brightness
    self.effect = effect
    self.transition = transition
  }

  @JSONCodable
  public enum Mode: String {
    case onOff = "onoff"
    case brightness = "brightness"
  }
}
