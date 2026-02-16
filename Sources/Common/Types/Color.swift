public struct Color {
  @Clamped var red: Float
  @Clamped var green: Float
  @Clamped var blue: Float

  public init(red: Float, green: Float, blue: Float) {
    _red = .init(wrappedValue: red)
    _green = .init(wrappedValue: green)
    _blue = .init(wrappedValue: blue)
  }

  public init(
    hue: Float,
    saturation: Float,
    luminosity: Float
  ) {
    let (r, g, b) = hslToRgb(
      hue: hue.clamped(to: 0.0 ... 360.0),
      saturation: saturation.clamped(to: 0 ... 1),
      luminosity: luminosity.clamped(to: 0 ... 1)
    )

    self.init(red: r, green: g, blue: b)
  }
}

extension Color {
  struct RGB {
    var red: Float
    var green: Float
    var blue: Float
  }

  var rgb: RGB {
    RGB(
      red: red,
      green: green,
      blue: blue
    )
  }
}

extension Color {
  struct HSL {
    let hue: Float
    let saturation: Float
    let luminosity: Float
  }

  var hsl: HSL {
    let (h, s, l) = rgbToHsl(red: red, green: green, blue: blue)
    return HSL(hue: h, saturation: s, luminosity: l)
  }
}

private func rgbToHsl(
  @Clamped red: Float,
  @Clamped green: Float,
  @Clamped blue: Float
) -> (hue: Float, saturation: Float, luminosity: Float) {
  let maxVal = max(red, green, blue)
  let minVal = min(red, green, blue)
  let delta = maxVal - minVal

  var hue: Float = 0
  if delta != 0 {
    if maxVal == red {
      hue = 60 * (((green - blue) / delta).truncatingRemainder(dividingBy: 6))
    } else if maxVal == green {
      hue = 60 * (((blue - red) / delta) + 2)
    } else {
      hue = 60 * (((red - green) / delta) + 4)
    }
  }

  hue = hue.truncatingRemainder(dividingBy: 360)
  if hue < 0 { hue += 360 }

  let luminosity = (maxVal + minVal) / 2
  let saturation = delta == 0 ? 0 : delta / (1 - abs(2 * luminosity - 1))

  return (hue: hue, saturation: saturation, luminosity: luminosity)
}

private func hslToRgb(
  hue: Float,
  @Clamped saturation: Float,
  @Clamped luminosity: Float
) -> (red: Float, green: Float, blue: Float) {
  var wrappedHue = hue.clamped(to: 0 ... 360).truncatingRemainder(dividingBy: 360)
  if wrappedHue < 0 { wrappedHue += 360 }

  let chroma = (1 - abs(2 * luminosity - 1)) * saturation
  let huePrime = wrappedHue / 60
  let x = chroma * (1 - abs(huePrime.truncatingRemainder(dividingBy: 2) - 1))

  var r1: Float = 0
  var g1: Float = 0
  var b1: Float = 0

  switch huePrime {
  case 0 ..< 1:
    r1 = chroma
    g1 = x
    b1 = 0
  case 1 ..< 2:
    r1 = x
    g1 = chroma
    b1 = 0
  case 2 ..< 3:
    r1 = 0
    g1 = chroma
    b1 = x
  case 3 ..< 4:
    r1 = 0
    g1 = x
    b1 = chroma
  case 4 ..< 5:
    r1 = x
    g1 = 0
    b1 = chroma
  case 5 ..< 6:
    r1 = chroma
    g1 = 0
    b1 = x
  default:
    break
  }

  let m = luminosity - chroma / 2
  return (red: r1 + m, green: g1 + m, blue: b1 + m)
}
