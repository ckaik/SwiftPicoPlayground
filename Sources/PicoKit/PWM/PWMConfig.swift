public struct PWMConfig: Equatable {
  public let frequencyHz: Float
  public let wrap: UInt16

  public init(frequencyHz: Float, wrap: UInt16) {
    self.frequencyHz = frequencyHz
    self.wrap = wrap
  }
}
