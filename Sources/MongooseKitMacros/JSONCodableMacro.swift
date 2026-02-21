import SwiftSyntax
import SwiftSyntaxMacros

public struct JSONCodableMacro: MemberMacro, ExtensionMacro {
  public static func expansion(
    of node: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingExtensionsOf type: some TypeSyntaxProtocol,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [ExtensionDeclSyntax] {
    let decodableExtensions = try JSONDecodableMacro.expansion(
      of: node,
      attachedTo: declaration,
      providingExtensionsOf: type,
      conformingTo: protocols,
      in: context
    )

    let encodableExtensions = try JSONEncodableMacro.expansion(
      of: node,
      attachedTo: declaration,
      providingExtensionsOf: type,
      conformingTo: protocols,
      in: context
    )

    return decodableExtensions + encodableExtensions
  }

  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    let decodableMembers = try JSONDecodableMacro.expansion(
      of: node,
      providingMembersOf: declaration,
      conformingTo: protocols,
      in: context
    )

    let encodableMembers = try JSONEncodableMacro.expansion(
      of: node,
      providingMembersOf: declaration,
      conformingTo: protocols,
      in: context
    )

    return decodableMembers + encodableMembers
  }
}
