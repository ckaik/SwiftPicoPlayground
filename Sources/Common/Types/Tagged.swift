// A copy of the `Tagged` type from `swift-tagged` by pointfreeco, 
// with some modifications to make it work on embedded platforms,
// once/if the package is updated to support embedded platforms, 
// the package can be used directly

@dynamicMemberLookup
public struct Tagged<Tag, RawValue> {
  public var rawValue: RawValue

  public init(rawValue: RawValue) {
    self.rawValue = rawValue
  }

  public init(_ rawValue: RawValue) {
    self.rawValue = rawValue
  }

  public subscript<Subject>(dynamicMember keyPath: KeyPath<RawValue, Subject>) -> Subject {
    rawValue[keyPath: keyPath]
  }
}

extension Tagged: RawRepresentable {}

// MARK: - Conditional Conformances

extension Tagged: Collection where RawValue: Collection {
  public func index(after i: RawValue.Index) -> RawValue.Index {
    rawValue.index(after: i)
  }

  public subscript(position: RawValue.Index) -> RawValue.Element {
    rawValue[position]
  }

  public var startIndex: RawValue.Index {
    rawValue.startIndex
  }

  public var endIndex: RawValue.Index {
    rawValue.endIndex
  }

  public consuming func makeIterator() -> RawValue.Iterator {
    rawValue.makeIterator()
  }
}

extension Tagged: Comparable where RawValue: Comparable {
  public static func < (lhs: Self, rhs: Self) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
}

extension Tagged: Equatable where RawValue: Equatable {}

extension Tagged: Error where RawValue: Error {}

extension Tagged: Sendable where RawValue: Sendable {}

#if swift(>=6.0)
  extension Tagged: BitwiseCopyable where RawValue: BitwiseCopyable {}
#endif

extension Tagged: ExpressibleByBooleanLiteral where RawValue: ExpressibleByBooleanLiteral {
  public init(booleanLiteral value: RawValue.BooleanLiteralType) {
    self.init(rawValue: RawValue(booleanLiteral: value))
  }
}

extension Tagged: ExpressibleByExtendedGraphemeClusterLiteral
where RawValue: ExpressibleByExtendedGraphemeClusterLiteral {
  public init(extendedGraphemeClusterLiteral: RawValue.ExtendedGraphemeClusterLiteralType) {
    self.init(rawValue: RawValue(extendedGraphemeClusterLiteral: extendedGraphemeClusterLiteral))
  }
}

extension Tagged: ExpressibleByFloatLiteral where RawValue: ExpressibleByFloatLiteral {
  public init(floatLiteral: RawValue.FloatLiteralType) {
    self.init(rawValue: RawValue(floatLiteral: floatLiteral))
  }
}

extension Tagged: ExpressibleByIntegerLiteral where RawValue: ExpressibleByIntegerLiteral {
  public init(integerLiteral: RawValue.IntegerLiteralType) {
    self.init(rawValue: RawValue(integerLiteral: integerLiteral))
  }
}

extension Tagged: ExpressibleByStringLiteral where RawValue: ExpressibleByStringLiteral {
  public init(stringLiteral: RawValue.StringLiteralType) {
    self.init(rawValue: RawValue(stringLiteral: stringLiteral))
  }
}

extension Tagged: ExpressibleByStringInterpolation
where RawValue: ExpressibleByStringInterpolation {
  public init(stringInterpolation: RawValue.StringInterpolation) {
    self.init(rawValue: RawValue(stringInterpolation: stringInterpolation))
  }
}

extension Tagged: ExpressibleByUnicodeScalarLiteral
where RawValue: ExpressibleByUnicodeScalarLiteral {
  public init(unicodeScalarLiteral: RawValue.UnicodeScalarLiteralType) {
    self.init(rawValue: RawValue(unicodeScalarLiteral: unicodeScalarLiteral))
  }
}

extension Tagged: Identifiable where RawValue: Identifiable {
  public var id: RawValue.ID {
    rawValue.id
  }
}

extension Tagged: AdditiveArithmetic where RawValue: AdditiveArithmetic {
  public static var zero: Self {
    Self(rawValue: .zero)
  }

  public static func + (lhs: Self, rhs: Self) -> Self {
    Self(rawValue: lhs.rawValue + rhs.rawValue)
  }

  public static func += (lhs: inout Self, rhs: Self) {
    lhs.rawValue += rhs.rawValue
  }

  public static func - (lhs: Self, rhs: Self) -> Self {
    Self(rawValue: lhs.rawValue - rhs.rawValue)
  }

  public static func -= (lhs: inout Self, rhs: Self) {
    lhs.rawValue -= rhs.rawValue
  }
}

extension Tagged: Numeric where RawValue: Numeric {
  public init?(exactly source: some BinaryInteger) {
    guard let rawValue = RawValue(exactly: source) else { return nil }
    self.init(rawValue: rawValue)
  }

  public var magnitude: RawValue.Magnitude {
    rawValue.magnitude
  }

  public static func * (lhs: Self, rhs: Self) -> Self {
    Self(rawValue: lhs.rawValue * rhs.rawValue)
  }

  public static func *= (lhs: inout Self, rhs: Self) {
    lhs.rawValue *= rhs.rawValue
  }
}

extension Tagged: Hashable where RawValue: Hashable {}

extension Tagged: SignedNumeric where RawValue: SignedNumeric {}

extension Tagged: Sequence where RawValue: Sequence {
  public consuming func makeIterator() -> RawValue.Iterator {
    rawValue.makeIterator()
  }
}

extension Tagged: Strideable where RawValue: Strideable {
  public func distance(to other: Self) -> RawValue.Stride {
    rawValue.distance(to: other.rawValue)
  }

  public func advanced(by n: RawValue.Stride) -> Self {
    Tagged(rawValue: rawValue.advanced(by: n))
  }
}

extension Tagged: ExpressibleByArrayLiteral where RawValue: ExpressibleByArrayLiteral {
  public init(arrayLiteral elements: RawValue.ArrayLiteralElement...) {
    let f = unsafeBitCast(
      RawValue.init(arrayLiteral:) as (RawValue.ArrayLiteralElement...) -> RawValue,
      to: (([RawValue.ArrayLiteralElement]) -> RawValue).self
    )

    self.init(rawValue: f(elements))
  }
}

extension Tagged: ExpressibleByDictionaryLiteral where RawValue: ExpressibleByDictionaryLiteral {
  public init(dictionaryLiteral elements: (RawValue.Key, RawValue.Value)...) {
    let f = unsafeBitCast(
      RawValue.init(dictionaryLiteral:) as ((RawValue.Key, RawValue.Value)...) -> RawValue,
      to: (([(Key, Value)]) -> RawValue).self
    )

    self.init(rawValue: f(elements))
  }
}
