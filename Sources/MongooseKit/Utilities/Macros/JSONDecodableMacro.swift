@attached(extension, conformances: JSONDecodable)
@attached(member, names: named(init))
public macro JSONDecodable() =
  #externalMacro(
    module: "MongooseKitMacros",
    type: "JSONDecodableMacro"
  )
