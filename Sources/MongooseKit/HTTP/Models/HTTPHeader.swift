public struct HTTPHeader {
  public let field: String
  public let value: String

  public init(_ field: String, value: String) {
    self.field = field
    self.value = value
  }
}
