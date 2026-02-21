@attached(peer)
public macro JSON(_ key: String) =
  #externalMacro(
    module: "MongooseKitMacros",
    type: "JSONKeyMacro"
  )
