public struct PinID: Hashable {
  public let value: UInt32

  public init(_ value: UInt32) {
    self.value = value
  }
}

extension PinID: ExpressibleByIntegerLiteral {
  public init(integerLiteral value: UInt32) {
    self.init(value)
  }
}
