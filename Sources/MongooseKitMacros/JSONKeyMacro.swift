import SwiftSyntax
import SwiftSyntaxMacros

public struct JSONKeyMacro: PeerMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    try JSONMacroSupport.validateJSONAttributeUsage(
      attribute: node,
      declaration: declaration,
      context: context
    )

    return []
  }
}
