import SwiftSyntax
import SwiftSyntaxMacros

public struct JSONEncodableMacro: MemberMacro, ExtensionMacro {
  public static func expansion(
    of node: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingExtensionsOf type: some TypeSyntaxProtocol,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [ExtensionDeclSyntax] {
    [try ExtensionDeclSyntax("extension \(type.trimmed): JSONEncodable {}")]
  }

  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    if let enumDecl = declaration.as(EnumDeclSyntax.self) {
      return [try makeEnumEncodeMethod(for: enumDecl)]
    }

    if let structDecl = declaration.as(StructDeclSyntax.self) {
      return [
        try makeStoredPropertyEncodeMethod(
          members: structDecl.memberBlock.members,
          accessPrefix: accessPrefix(from: structDecl.modifiers)
        )
      ]
    }

    if let classDecl = declaration.as(ClassDeclSyntax.self) {
      return [
        try makeStoredPropertyEncodeMethod(
          members: classDecl.memberBlock.members,
          accessPrefix: accessPrefix(from: classDecl.modifiers)
        )
      ]
    }

    if let actorDecl = declaration.as(ActorDeclSyntax.self) {
      return [
        try makeStoredPropertyEncodeMethod(
          members: actorDecl.memberBlock.members,
          accessPrefix: accessPrefix(from: actorDecl.modifiers)
        )
      ]
    }

    throw MacroExpansionErrorMessage(
      "@JSONEncodable can only be applied to struct, class, actor, or raw-value enum declarations"
    )
  }

  private static func makeEnumEncodeMethod(for enumDecl: EnumDeclSyntax) throws -> DeclSyntax {
    guard enumDecl.inheritanceClause != nil else {
      throw MacroExpansionErrorMessage(
        "@JSONEncodable on enum requires a raw-value enum, for example: enum Mode: String"
      )
    }

    let prefix = accessPrefix(from: enumDecl.modifiers)

    return """
      \(raw: prefix)func encode(encoder: JSONEncoder) throws(JSONEncodingError) -> JSONEncodedValue {
        try encoder.box(rawValue)
      }
      """
  }

  private static func makeStoredPropertyEncodeMethod(
    members: MemberBlockItemListSyntax,
    accessPrefix: String
  ) throws -> DeclSyntax {
    var assignments: [String] = []

    let properties = try JSONMacroSupport.collectStoredProperties(
      from: members,
      synthesisMacroName: "@JSONEncodable"
    )

    for property in properties {
      if property.isOptional {
        assignments.append(
          "if let value = self.\(property.identifier) { object[\"\(property.key)\"] = try encoder.box(value) } else if encoder.nilEncodingStrategy == .encodeNull { object[\"\(property.key)\"] = .null }"
        )
      } else {
        assignments.append(
          "object[\"\(property.key)\"] = try encoder.box(self.\(property.identifier))"
        )
      }
    }

    let body = assignments.joined(separator: "\n    ")

    return """
      \(raw: accessPrefix)func encode(encoder: JSONEncoder) throws(JSONEncodingError) -> JSONEncodedValue {
        var object: [String: JSONEncodedValue] = [:]
        \(raw: body)
        return .object(object)
      }
      """
  }

  private static func accessPrefix(from modifiers: DeclModifierListSyntax?) -> String {
    guard let modifiers else {
      return ""
    }

    if modifiers.contains(where: { $0.name.text == "open" || $0.name.text == "public" }) {
      return "public "
    }

    if modifiers.contains(where: { $0.name.text == "package" }) {
      return "package "
    }

    return ""
  }
}
