import Common
import HomeAssistantKit
import PicoKit

final class LEDController {
  public enum State {
    case on(brightness: UInt8)
    case off
    case effect(String)
  }

  private let output: PWMOutput
  private(set) var state: State

  init(output: PWMOutput) {
    self.output = output
    state = .off
    output.start(effect: .off)
  }

  func off() {
    output.start(effect: .off)
    state = .off
  }

  func on(at brightness: Float = 1) {
    let brightness = brightness.clamped()
    output.start(effect: .dim(brightness: brightness))
    state = .on(brightness: UInt8(brightness * 255))
  }

  func currentLightState() -> LightState {
    switch state {
    case .off: LightState(state: false)
    case .on(let brightness): LightState(state: true, brightness: brightness)
    case .effect(let effect): LightState(state: true, brightness: 255, effect: effect)
    }
  }

  func process(payload: String) -> LightState {
    guard let newState = try? LightState.from(json: payload) else {
      return currentLightState()
    }

    return process(state: newState)
  }

  func process(state: LightState) -> LightState {
    print("State Request: \(state)")

    guard
      let isOn = state.state,
      isOn
    else {
      off()
      return .init(state: false)
    }

    if let brightness = state.brightness {
      output.start(effect: .dim(brightness: Float(brightness) / 255))
      self.state = .on(brightness: brightness)

      return .init(state: true, brightness: brightness)
    }

    if let effect = state.effect {
      switch effect.lowercased() {
      case "police flash":
        output.start(effect: .policeFlash())
      case "flicker":
        output.start(effect: .flicker())
      case "breathe":
        output.start(effect: .breathe())
      case "strobe":
        output.start(effect: .strobe())
      case "heartbeat":
        output.start(effect: .heartbeat())
      case "ping pong fade":
        output.start(effect: .pingPongFade())
      case "candle":
        output.start(effect: .candle())
      case "pulse hold":
        output.start(effect: .pulseHold())
      default:
        self.state = .off
        output.start(effect: .off)
        return .init(state: false)
      }

      self.state = .effect(effect)
      return .init(state: true, brightness: 255, effect: effect)
    }

    on(at: 1)
    return .init(state: true, brightness: 255)
  }
}
