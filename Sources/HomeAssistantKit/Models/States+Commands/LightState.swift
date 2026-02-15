import MongooseKit

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

  public enum Mode: String {
    case onOff = "onoff"
    case brightness = "brightness"
  }

  public init(reader: MGJSONParser) throws(MGJSONDecodingError) {
    self.mode = (try? reader.string("$.mode")).flatMap { Mode(rawValue: $0) }
    self.state = try? reader.bool("$.state")
    self.brightness = try? reader.number("$.brightness")
    self.effect = try? reader.string("$.effect")
    self.transition = try? reader.number("$.transition")
  }

  public var json: String {
    """
    {
      "mode": \(mode.map { "\"\($0.rawValue)\"" } ?? "null"),
      "state": \(state.map { $0 ? "\"ON\"" : "\"OFF\"" } ?? "null"),
      "brightness": \(brightness.map { "\($0)" } ?? "null"),
      "effect": \(effect.map { "\"\($0)\"" } ?? "null"),
      "transition": \(transition.map { "\($0)" } ?? "null")
    }
    """
  }
}
