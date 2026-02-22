/// Returns whether two strings are equal using ASCII case-insensitive comparison.
///
/// This helper is intentionally ASCII-only for predictable embedded behavior.
func asciiCaseInsensitiveEquals(_ lhs: String, _ rhs: String) -> Bool {
  let lhsBytes = lhs.utf8
  let rhsBytes = rhs.utf8

  guard lhsBytes.count == rhsBytes.count else { return false }

  for (lhsByte, rhsByte) in zip(lhsBytes, rhsBytes)
  where asciiLowercased(lhsByte) != asciiLowercased(rhsByte) {
    return false
  }

  return true
}

/// Lowercases an ASCII byte if it is an uppercase A-Z character.
func asciiLowercased(_ byte: UInt8) -> UInt8 {
  if byte >= 65 && byte <= 90 {
    return byte + 32
  }

  return byte
}

/// Uppercases ASCII letters in `value`, leaving all other bytes unchanged.
func asciiUppercased(_ value: String) -> String {
  let transformed = value.utf8.map { byte in
    if byte >= 97 && byte <= 122 {
      return byte - 32
    }

    return byte
  }

  return String(decoding: transformed, as: UTF8.self)
}
