import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct MongooseKitMacroPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    JSONKeyMacro.self,
    JSONDecodableMacro.self,
    JSONEncodableMacro.self,
    JSONCodableMacro.self,
  ]
}
