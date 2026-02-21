import Common
import MongooseKit

public protocol Command: JSONDecodable {}

extension Command {
  public static func from(json: String) throws(JSONDecodingError) -> Self {
    let decoder = JSONDecoder(boolDecodingStrategy: .default)
    return try decoder.decode(Self.self, from: Array(json.utf8))
  }
}

public protocol State: JSONEncodable {}
