import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum MacroError: Error, CustomStringConvertible {
    case message(String)

    public var description: String {
        switch self {
        case let .message(text):
            return text
        }
    }
}

struct PropertyInfo {
    let name: String
    let type: String
    let isWrapped: Bool
    let isStored: Bool

    var codingKeyName: String {
        name
    }

    var accessName: String {
        isWrapped ? "_\(name)" : name
    }
}

public struct SmartSubclassMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
            throw MacroError.message("@SmartSubclassMacro can only be applied to class declarations")
        }

        guard let inheritedNames = classDecl.inheritanceClause?.inheritedTypes,
              !inheritedNames.isEmpty else {
            throw MacroError.message("@SmartSubclassMacro requires the class to inherit from a parent class")
        }

        let properties = extractProperties(from: classDecl)
        if properties.isEmpty {
            return []
        }

        var members: [DeclSyntax] = []
        members.append(generateCodingKeysEnum(for: properties))
        members.append(generateInitFromDecoder(for: properties))
        members.append(generateEncodeToEncoder(for: properties))

        if hasRequiredInitializer(classDecl) {
            return members
        } else {
            members.append(generateRequiredInit())
            return members
        }
    }

    private static func extractProperties(from classDecl: ClassDeclSyntax) -> [PropertyInfo] {
        var properties: [PropertyInfo] = []

        for member in classDecl.memberBlock.members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                  varDecl.bindingSpecifier.text == "var" else {
                continue
            }

            for binding in varDecl.bindings {
                guard let identifier = binding.pattern.as(IdentifierPatternSyntax.self),
                      let typeAnnotation = binding.typeAnnotation else {
                    continue
                }

                let name = identifier.identifier.text
                let baseType = typeAnnotation.type.description.trimmingCharacters(in: .whitespacesAndNewlines)

                let isStored = binding.accessorBlock == nil ||
                    (binding.accessorBlock?.accessors.as(AccessorDeclListSyntax.self) == nil &&
                        binding.accessorBlock?.accessors.as(CodeBlockItemListSyntax.self) == nil)

                if isStored {
                    var effectiveType = baseType
                    var isWrapped = false
                    let attrs = varDecl.attributes
                    if !attrs.isEmpty {
                        for attr in attrs {
                            if let attrSyntax = attr.as(AttributeSyntax.self),
                               let wrapperName = attrSyntax.attributeName.as(IdentifierTypeSyntax.self) {
                                effectiveType = "\(wrapperName.name.text)<\(baseType)>"
                                isWrapped = true
                                break
                            }
                        }
                    }

                    properties.append(PropertyInfo(name: name, type: effectiveType, isWrapped: isWrapped, isStored: true))
                }
            }
        }

        return properties
    }

    private static func generateCodingKeysEnum(for properties: [PropertyInfo]) -> DeclSyntax {
        let caseDeclarations = properties.map { property in
            "case \(property.codingKeyName)"
        }.joined(separator: "\n")

        return """
        enum CodingKeys: CodingKey {
            \(raw: caseDeclarations)
        }
        """
    }

    private static func generateInitFromDecoder(for properties: [PropertyInfo]) -> DeclSyntax {
        let decodingStatements = properties.map { property in
            let propertyName = property.accessName
            let propertyType = property.type

            if propertyType.hasSuffix("?") {
                let baseType = propertyType.dropLast()
                return "self.\(propertyName) = try container.decodeIfPresent(\(baseType).self, forKey: .\(property.codingKeyName)) ?? self.\(propertyName)"
            } else {
                return "self.\(propertyName) = try container.decodeIfPresent(\(propertyType).self, forKey: .\(property.codingKeyName)) ?? self.\(propertyName)"
            }
        }.joined(separator: "\n")

        return """
        required init(from decoder: Decoder) throws {
            try super.init(from: decoder)

            let container = try decoder.container(keyedBy: CodingKeys.self)
            \(raw: decodingStatements)
        }
        """
    }

    private static func generateEncodeToEncoder(for properties: [PropertyInfo]) -> DeclSyntax {
        let encodingStatements = properties.map { property in
            "try container.encode(\(property.accessName), forKey: .\(property.codingKeyName))"
        }.joined(separator: "\n")

        return """
        override func encode(to encoder: Encoder) throws {
            try super.encode(to: encoder)

            var container = encoder.container(keyedBy: CodingKeys.self)
            \(raw: encodingStatements)
        }
        """
    }

    private static func hasRequiredInitializer(_ classDecl: ClassDeclSyntax) -> Bool {
        for member in classDecl.memberBlock.members {
            if let initializer = member.decl.as(InitializerDeclSyntax.self),
               initializer.signature.parameterClause.parameters.isEmpty,
               initializer.modifiers.contains(where: { $0.name.text == "required" }) == true {
                return true
            }
        }
        return false
    }

    private static func generateRequiredInit() -> DeclSyntax {
        """
        required init() {
            super.init()
        }
        """
    }
}
