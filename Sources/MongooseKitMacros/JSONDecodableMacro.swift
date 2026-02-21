import SwiftSyntax
import SwiftSyntaxMacros

public struct JSONDecodableMacro: MemberMacro, ExtensionMacro {
  public static func expansion(
    of node: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingExtensionsOf type: some TypeSyntaxProtocol,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [ExtensionDeclSyntax] {
    [try ExtensionDeclSyntax("extension \(type.trimmed): JSONDecodable {}")]
  }

  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    if let enumDecl = declaration.as(EnumDeclSyntax.self) {
      return [try makeEnumInitializer(for: enumDecl)]
    }

    if let structDecl = declaration.as(StructDeclSyntax.self) {
      return [
        try makeStoredPropertyInitializer(
          members: structDecl.memberBlock.members,
          accessPrefix: accessPrefix(from: structDecl.modifiers),
          declarationKind: "struct"
        )
      ]
    }

    if let classDecl = declaration.as(ClassDeclSyntax.self) {
      return [
        try makeStoredPropertyInitializer(
          members: classDecl.memberBlock.members,
          accessPrefix: classAccessPrefix(from: classDecl.modifiers),
          declarationKind: "class"
        )
      ]
    }

    if let actorDecl = declaration.as(ActorDeclSyntax.self) {
      return [
        try makeStoredPropertyInitializer(
          members: actorDecl.memberBlock.members,
          accessPrefix: accessPrefix(from: actorDecl.modifiers),
          declarationKind: "actor"
        )
      ]
    }

    throw MacroExpansionErrorMessage(
      "@JSONDecodable can only be applied to struct, class, actor, or raw-value enum declarations"
    )
  }

  private static func makeEnumInitializer(for enumDecl: EnumDeclSyntax) throws -> DeclSyntax {
    guard let inheritanceClause = enumDecl.inheritanceClause,
      let rawTypeSyntax = inheritanceClause.inheritedTypes.first?.type
    else {
      throw MacroExpansionErrorMessage(
        "@JSONDecodable on enum requires a raw-value enum, for example: enum Mode: String"
      )
    }

    let rawTypeName = rawTypeSyntax.trimmedDescription
    let rawDecodeExpression = decodeExpression(typeName: rawTypeName, path: "$", isOptional: false)
    let prefix = accessPrefix(from: enumDecl.modifiers)

    return """
      \(raw: prefix)init(decoder: JSONDecoder) throws(JSONDecodingError) {
        let rawValue: \(raw: rawTypeName) = \(raw: rawDecodeExpression)
        guard let decoded = Self(rawValue: rawValue) else {
          throw JSONDecodingError.typeMismatch(path: "\(raw: "$")", expected: "\(raw: "\(Self.self)")")
        }
        self = decoded
      }
      """
  }

  private static func makeStoredPropertyInitializer(
    members: MemberBlockItemListSyntax,
    accessPrefix: String,
    declarationKind: String
  ) throws -> DeclSyntax {
    var assignments: [String] = []

    for member in members {
      guard let variable = member.decl.as(VariableDeclSyntax.self) else {
        continue
      }

      if isStatic(variable) {
        continue
      }

      for binding in variable.bindings {
        guard let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
        else {
          throw MacroExpansionErrorMessage(
            "@JSONDecodable only supports stored properties with identifier patterns"
          )
        }

        guard let typeAnnotation = binding.typeAnnotation else {
          throw MacroExpansionErrorMessage(
            "@JSONDecodable requires explicit type annotations for property '\(identifier)'"
          )
        }

        if binding.accessorBlock != nil {
          continue
        }

        let type = typeAnnotation.type
        let (typeName, isOptional) = unwrapOptional(type: type)
        let keyPath = identifier
        let decode = decodeExpression(typeName: typeName, path: keyPath, isOptional: isOptional)

        if let defaultValue = binding.initializer?.value.trimmedDescription {
          assignments.append("self.\(identifier) = (\(decode)) ?? \(defaultValue)")
        } else {
          assignments.append("self.\(identifier) = \(decode)")
        }
      }
    }

    let body =
      assignments.isEmpty
      ? ""
      : assignments.joined(separator: "\n  ")

    return """
      \(raw: accessPrefix)init(decoder: JSONDecoder) throws(JSONDecodingError) {
        \(raw: body)
      }
      """
  }

  private static func decodeExpression(typeName: String, path: String, isOptional: Bool) -> String {
    switch typeName {
    case "Bool", "Swift.Bool":
      return isOptional
        ? "decoder.decodeIfPresent(at: \"\(path)\")"
        : "try decoder.decode(at: \"\(path)\")"
    case "String", "Swift.String":
      return isOptional
        ? "decoder.decodeIfPresent(at: \"\(path)\")"
        : "try decoder.decode(at: \"\(path)\")"
    default:
      return isOptional
        ? "decoder.decodeIfPresent(\(typeName).self, at: \"\(path)\")"
        : "try decoder.decode(\(typeName).self, at: \"\(path)\")"
    }
  }

  private static func unwrapOptional(type: TypeSyntax) -> (typeName: String, isOptional: Bool) {
    if let optional = type.as(OptionalTypeSyntax.self) {
      return (optional.wrappedType.trimmedDescription, true)
    }

    if let implicitlyUnwrapped = type.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
      return (implicitlyUnwrapped.wrappedType.trimmedDescription, true)
    }

    return (type.trimmedDescription, false)
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

  private static func classAccessPrefix(from modifiers: DeclModifierListSyntax?) -> String {
    let baseAccess = accessPrefix(from: modifiers)
    let isFinal = modifiers?.contains(where: { $0.name.text == "final" }) == true

    if isFinal {
      return baseAccess
    }

    return "\(baseAccess)required "
  }

  private static func isStatic(_ variable: VariableDeclSyntax) -> Bool {
    variable.modifiers.contains(where: {
      $0.name.text == "static" || $0.name.text == "class"
    })
  }
}
