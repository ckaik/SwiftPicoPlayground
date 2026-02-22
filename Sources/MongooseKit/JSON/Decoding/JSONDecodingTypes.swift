public protocol JSONDecodable {
  init(decoder: JSONDecoder) throws(JSONDecodingError)
}

public enum JSONDecodingError: Error {
  case invalidJSON
  case missingKey(path: String)
  case typeMismatch(path: String, expected: String)
  case invalidEncoding(path: String)
  case invalidNumber(path: String)
  case nestedContainerNotFound(path: String)
}

public enum BoolDecodingStrategy {
  case literal
  case literalOrString(
    trueValues: [String],
    falseValues: [String],
    caseInsensitive: Bool
  )

  public static let `default`: BoolDecodingStrategy = .literalOrString(
    trueValues: ["true", "on", "yes", "1", "y"],
    falseValues: ["false", "off", "no", "0", "n"],
    caseInsensitive: true
  )
}
