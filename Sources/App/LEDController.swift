import Common
import HomeAssistantKit
import PicoKit

final class LEDController {
  static let pwmConfig = PWMConfig(frequencyHz: 1000, wrap: 4095)

  public enum State {
    case on(brightness: UInt8)
    case off
    case effect(String)
  }

  private let pin: Pin
  private(set) var state: State

  init(pin: Pin) {
    self.pin = pin
    state = .off
    pin.pwm(.off, config: Self.pwmConfig)
  }

  func off() {
    pin.pwm(.off, config: Self.pwmConfig)
    state = .off
  }

  func on(at brightness: Float = 1) {
    let brightness = brightness.clamped()
    pin.pwm(.dim(brightness: brightness), config: Self.pwmConfig)
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
      pin.pwm(.off, config: Self.pwmConfig)
      self.state = .off

      return .init(state: false)
    }

    if let brightness = state.brightness {
      pin.pwm(.dim(brightness: Float(brightness) / 255), config: Self.pwmConfig)
      self.state = .on(brightness: brightness)

      return .init(state: true, brightness: brightness)
    }

    if let effect = state.effect {
      switch effect.lowercased() {
      case "police flash":
        pin.pwm(.policeFlash(), config: Self.pwmConfig)
      case "flicker":
        pin.pwm(.flicker(), config: Self.pwmConfig)
      case "breathe":
        pin.pwm(.breathe(), config: Self.pwmConfig)
      case "strobe":
        pin.pwm(.strobe(), config: Self.pwmConfig)
      case "heartbeat":
        pin.pwm(.heartbeat(), config: Self.pwmConfig)
      case "ping pong fade":
        pin.pwm(.pingPongFade(), config: Self.pwmConfig)
      case "candle":
        pin.pwm(.candle(), config: Self.pwmConfig)
      case "pulse hold":
        pin.pwm(.pulseHold(), config: Self.pwmConfig)
      default:
        self.state = .off
        pin.pwm(.off, config: Self.pwmConfig)
        return .init(state: false)
      }

      self.state = .effect(effect)
      return .init(state: true, brightness: 255, effect: effect)
    }

    pin.pwm(.on, config: Self.pwmConfig)
    self.state = .on(brightness: 255)
    return .init(state: true, brightness: 255)
  }
}
