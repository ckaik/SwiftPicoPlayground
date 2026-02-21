@attached(extension, conformances: JSONEncodable)
@attached(member, names: named(encode))
public macro JSONEncodable() =
  #externalMacro(
    module: "MongooseKitMacros",
    type: "JSONEncodableMacro"
  )
