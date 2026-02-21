import SwiftSyntax
import SwiftSyntaxMacros

struct JSONStoredProperty {
  let identifier: String
  let key: String
  let typeName: String
  let isOptional: Bool
  let defaultValue: String?
}

enum JSONMacroSupport {
  static func collectStoredProperties(
    from members: MemberBlockItemListSyntax,
    synthesisMacroName: String
  ) throws -> [JSONStoredProperty] {
    var properties: [JSONStoredProperty] = []
    var seenKeys: [String: String] = [:]

    for member in members {
      guard let variable = member.decl.as(VariableDeclSyntax.self) else {
        continue
      }

      let jsonAttribute = jsonAttribute(from: variable.attributes)
      let hasJSONAttribute = jsonAttribute != nil

      if isStatic(variable) {
        if hasJSONAttribute {
          throw MacroExpansionErrorMessage("@JSON cannot be applied to static/class properties")
        }
        continue
      }

      if hasJSONAttribute && variable.bindings.count != 1 {
        throw MacroExpansionErrorMessage(
          "@JSON can only be applied to a declaration with a single property binding"
        )
      }

      for binding in variable.bindings {
        guard let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
        else {
          throw MacroExpansionErrorMessage(
            "\(synthesisMacroName) only supports stored properties with identifier patterns"
          )
        }

        guard let typeAnnotation = binding.typeAnnotation else {
          throw MacroExpansionErrorMessage(
            "\(synthesisMacroName) requires explicit type annotations for property '\(identifier)'"
          )
        }

        if binding.accessorBlock != nil {
          if hasJSONAttribute {
            throw MacroExpansionErrorMessage(
              "@JSON can only be applied to stored properties"
            )
          }
          continue
        }

        let key: String
        if let jsonAttribute {
          key = try parseJSONKey(from: jsonAttribute)
        } else {
          key = identifier
        }

        if let existingProperty = seenKeys[key] {
          throw MacroExpansionErrorMessage(
            "Duplicate JSON key '\(key)' for properties '\(existingProperty)' and '\(identifier)'"
          )
        }

        seenKeys[key] = identifier

        let (typeName, isOptional) = unwrapOptional(type: typeAnnotation.type)
        properties.append(
          JSONStoredProperty(
            identifier: identifier,
            key: key,
            typeName: typeName,
            isOptional: isOptional,
            defaultValue: binding.initializer?.value.trimmedDescription
          )
        )
      }
    }

    return properties
  }

  static func validateJSONAttributeUsage(
    attribute: AttributeSyntax,
    declaration: some DeclSyntaxProtocol,
    context: some MacroExpansionContext
  ) throws {
    guard let variable = declaration.as(VariableDeclSyntax.self) else {
      throw MacroExpansionErrorMessage("@JSON can only be applied to properties")
    }

    if isStatic(variable) {
      throw MacroExpansionErrorMessage("@JSON cannot be applied to static/class properties")
    }

    guard variable.bindings.count == 1,
      let binding = variable.bindings.first,
      binding.accessorBlock == nil
    else {
      throw MacroExpansionErrorMessage(
        "@JSON can only be applied to a single stored property"
      )
    }

    guard isInsideJSONSynthesisContext(context) else {
      throw MacroExpansionErrorMessage(
        "@JSON is only supported on stored properties inside types annotated with @JSONDecodable, @JSONEncodable, or @JSONCodable"
      )
    }

    _ = try parseJSONKey(from: attribute)
  }

  static func parseJSONKey(from attribute: AttributeSyntax) throws -> String {
    guard let arguments = attribute.arguments,
      let argumentList = arguments.as(LabeledExprListSyntax.self),
      argumentList.count == 1,
      let expression = argumentList.first?.expression.as(StringLiteralExprSyntax.self),
      expression.segments.count == 1,
      let segment = expression.segments.first?.as(StringSegmentSyntax.self)
    else {
      throw MacroExpansionErrorMessage("@JSON requires exactly one string literal argument")
    }

    let key = segment.content.text
    guard !key.isEmpty else {
      throw MacroExpansionErrorMessage("@JSON key cannot be empty")
    }

    return key
  }

  private static func jsonAttribute(from attributes: AttributeListSyntax) -> AttributeSyntax? {
    for attributeElement in attributes {
      guard case .attribute(let attribute) = attributeElement else {
        continue
      }

      if attributeName(for: attribute) == "JSON" {
        return attribute
      }
    }

    return nil
  }

  private static func attributeName(for attribute: AttributeSyntax) -> String {
    let fullName = attribute.attributeName.trimmedDescription
    return fullName.split(separator: ".").last.map(String.init) ?? fullName
  }

  private static func isInsideJSONSynthesisContext(_ context: some MacroExpansionContext) -> Bool {
    let supportedAttributes = Set(["JSONDecodable", "JSONEncodable", "JSONCodable"])

    for syntax in context.lexicalContext.reversed() {
      let attributes: AttributeListSyntax?
      if let structDecl = syntax.as(StructDeclSyntax.self) {
        attributes = structDecl.attributes
      } else if let classDecl = syntax.as(ClassDeclSyntax.self) {
        attributes = classDecl.attributes
      } else if let actorDecl = syntax.as(ActorDeclSyntax.self) {
        attributes = actorDecl.attributes
      } else {
        continue
      }

      guard let attributes else {
        continue
      }

      for attributeElement in attributes {
        guard case .attribute(let attribute) = attributeElement else {
          continue
        }

        let name = attributeName(for: attribute)
        if supportedAttributes.contains(name) {
          return true
        }
      }
    }

    return false
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

  private static func isStatic(_ variable: VariableDeclSyntax) -> Bool {
    variable.modifiers.contains(where: {
      $0.name.text == "static" || $0.name.text == "class"
    })
  }
}
