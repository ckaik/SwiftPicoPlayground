import CMongoose

extension mg_str {
  /// Convert the `mg_str` buffer to a Swift byte array.
  func toByteArray() -> [UInt8] {
    guard let buffer = buf, len > 0 else { return [] }
    let raw = UnsafeRawBufferPointer(start: UnsafeRawPointer(buffer), count: Int(len))
    return Array(raw)
  }

  /// Decode the `mg_str` buffer as a UTF-8 string, returning `nil` on failure.
  func toString() -> String? {
    let bytes = toByteArray()
    guard !bytes.isEmpty else { return nil }
    return String(validating: bytes, as: UTF8.self)
  }
}

extension Array where Element == UInt8 {
  /// Borrow the array contents as an `mg_str` for the duration of `body`.
  func withMGStr<Result>(_ body: (mg_str) -> Result) -> Result {
    withUnsafeBytes { buffer in
      var str = mg_str()
      str.buf = UnsafeMutableRawPointer(mutating: buffer.baseAddress)?
        .assumingMemoryBound(to: CChar.self)
      str.len = buffer.count
      return body(str)
    }
  }
}
