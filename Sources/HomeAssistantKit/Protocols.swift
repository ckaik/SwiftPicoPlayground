import Common
import MongooseKit

public protocol Command: JSONDecodable {}

extension Command {
  public static func from(json: String) throws(JSONDecodingError) -> Self {
    let decoder = JSONDecoder(boolDecodingStrategy: .default)
    return try Self(decoder: decoder)
  }
}

public protocol State: JSONEncodable {}
