import CMongoose

/// RAII-style C string ownership for APIs that require allocated C buffers.
struct ManagedCString {
  let pointer: UnsafeMutablePointer<CChar>

  init<E: Error>(_ value: String, or error: @autoclosure () -> E) throws(E) {
    guard let copy = value.withCString({ strdup($0) }) else {
      throw error()
    }

    self.pointer = copy
  }

  func cleanup() {
    mg_free(pointer)
  }
}
