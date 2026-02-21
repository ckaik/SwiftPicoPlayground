import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct MongooseKitMacroPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    JSONDecodableMacro.self
  ]
}
