extension BinaryFloatingPoint {
  /// Creates a floating-point value from a string containing an ASCII representation of a number.
  ///
  /// The string must be in the format accepted by the C `strtod` function, which includes:
  /// - Optional leading `+` or `-` sign.
  /// - Digits with an optional decimal point.
  /// - Optional exponent part starting with `e` or `E`, followed by an optional sign and digits.
  ///
  /// - Parameter string: String containing the ASCII representation of a number.
  public init?(string: String) {
    guard let value = parseDoubleASCII(string) else { return nil }
    self.init(value)
  }
}

@inline(__always)
private func asciiDigit(_ b: UInt8) -> Int? {
  guard b >= 48 && b <= 57 else { return nil }
  return Int(b - 48)
}

private func pow10(_ exp: Int) -> Double {
  if exp == 0 { return 1.0 }
  var e = exp > 0 ? exp : -exp
  var base = 10.0
  var result = 1.0
  while e > 0 {
    if (e & 1) == 1 { result *= base }
    base *= base
    e >>= 1
  }
  return exp > 0 ? result : (1.0 / result)
}

private func parseDoubleASCII(_ text: String) -> Double? {
  let bytes = Array(text.utf8)
  if bytes.isEmpty { return nil }

  var i = 0
  var sign = 1.0
  if bytes[i] == 45 {
    sign = -1.0
    i += 1
  }  // -
  else if bytes[i] == 43 {
    i += 1
  }  // +

  var intPart = 0.0
  var fracPart = 0.0
  var fracScale = 1.0
  var hasDigits = false

  while i < bytes.count, let d = asciiDigit(bytes[i]) {
    hasDigits = true
    intPart = intPart * 10.0 + Double(d)
    i += 1
  }

  if i < bytes.count, bytes[i] == 46 {  // .
    i += 1
    while i < bytes.count, let d = asciiDigit(bytes[i]) {
      hasDigits = true
      fracScale *= 0.1
      fracPart += Double(d) * fracScale
      i += 1
    }
  }

  guard hasDigits else { return nil }

  var value = (intPart + fracPart) * sign

  if i < bytes.count, bytes[i] == 101 || bytes[i] == 69 {  // e/E
    i += 1
    var expSign = 1
    if i < bytes.count, bytes[i] == 45 {
      expSign = -1
      i += 1
    } else if i < bytes.count, bytes[i] == 43 {
      i += 1
    }

    var exp = 0
    var hasExpDigits = false
    while i < bytes.count, let d = asciiDigit(bytes[i]) {
      hasExpDigits = true
      exp = exp * 10 + d
      i += 1
    }
    guard hasExpDigits else { return nil }
    value *= pow10(expSign * exp)
  }

  guard i == bytes.count, value.isFinite else { return nil }
  return value
}
