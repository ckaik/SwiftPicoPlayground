public class FadeEffect: PWMEffect {
  private var goingUp: Bool
  private var fade: UInt16

  init(offset: UInt16 = 0, goingUp: Bool = true) {
    self.goingUp = goingUp
    self.fade =
      if goingUp {
        offset >= 255 ? 254 : offset
      } else {
        offset <= 0 ? 1 : offset
      }
  }

  public func level(for pin: PinID) -> UInt16 {
    if goingUp {
      fade += 1
      if fade >= 255 {
        fade = 255
        goingUp = false
      }
    } else {
      fade -= 1
      if fade <= 0 {
        fade = 0
        goingUp = true
      }
    }
    return fade * fade
  }
}

extension PWMEffect where Self == FadeEffect {
  public static func fade(offset: UInt16 = 0, direction: VerticalDirection = .up) -> Self {
    FadeEffect(offset: offset, goingUp: direction == .up)
  }
}
