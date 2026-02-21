@attached(extension, conformances: JSONDecodable)
@attached(member, names: named(init))
public macro Decodable() =
  #externalMacro(
    module: "MongooseKitMacros",
    type: "JSONDecodableMacro"
  )
