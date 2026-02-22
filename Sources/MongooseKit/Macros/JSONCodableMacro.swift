@attached(extension, conformances: JSONDecodable, JSONEncodable)
@attached(member, names: named(init), named(encode))
public macro JSONCodable() =
  #externalMacro(
    module: "MongooseKitMacros",
    type: "JSONCodableMacro"
  )
