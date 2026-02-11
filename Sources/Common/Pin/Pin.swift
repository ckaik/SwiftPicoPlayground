import CPicoSDK

public final class Pin {
  public let id: PinID

  internal(set) public var isInitialized = false

  public init(id: PinID) {
    self.id = id
  }

  public convenience init(number: UInt32) {
    self.init(id: .init(number))
  }

  lazy private(set) var pinNumber: UInt32 = id.rawValue
}
