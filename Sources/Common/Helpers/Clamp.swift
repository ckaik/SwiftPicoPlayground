extension Comparable {
  public func clamped(to range: ClosedRange<Self>) -> Self {
    min(max(self, range.lowerBound), range.upperBound)
  }

  public func clamped(to range: ClosedRange<Self> = 0 ... 1) -> Self
  where Self: BinaryFloatingPoint {
    min(max(self, range.lowerBound), range.upperBound)
  }
}

@propertyWrapper
public struct Clamped<Value: Comparable> {
  var value: Value
  let range: ClosedRange<Value>

  public init(wrappedValue: Value, in range: ClosedRange<Value>) {
    self.value = wrappedValue
    self.range = range
  }

  public var wrappedValue: Value {
    get { value }
    set { value = newValue.clamped(to: range) }
  }
}

extension Clamped where Value: BinaryFloatingPoint {
  @_disfavoredOverload
  public init(wrappedValue: Value, in range: ClosedRange<Value> = 0 ... 1) {
    self.init(wrappedValue: wrappedValue, in: range)
  }
}
