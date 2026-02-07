public enum Effects {
  public static func fade(offset: UInt16 = 0, goingUp: Bool = true) -> (PinID) -> UInt16 {
    var goingUp = goingUp
    var fade =
      if goingUp {
        offset >= 255 ? 254 : offset
      } else {
        offset <= 0 ? 1 : offset
      }

    return { _ in
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
}
