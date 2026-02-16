import Common
import MongooseKit

public protocol Command: MGJSONDecodable {}

extension Command {
  public static func from(json: String) throws(MGJSONDecodingError) -> Self {
    let parser = MGJSONParser(payload: Array(json.utf8))
    return try Self(reader: parser)
  }
}

public protocol State {
  var json: String { get }
}
