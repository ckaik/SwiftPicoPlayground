public protocol Cancellable {
  @discardableResult
  func cancel() -> Bool
}
