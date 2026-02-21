public struct SliceID: Hashable {
  public let value: UInt32

  public init(_ value: UInt32) {
    self.value = value
  }
}

extension SliceID: ExpressibleByIntegerLiteral {
  public init(integerLiteral value: UInt32) {
    self.init(value)
  }
}
