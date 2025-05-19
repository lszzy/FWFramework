import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct SmartSubclassMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
            throw MacroError("@SmartSubclassMacro can only be applied to class declarations")
        }

        guard let inheritedNames = classDecl.inheritanceClause?.inheritedTypes,
              !inheritedNames.isEmpty else {
            throw MacroError("@SmartSubclassMacro requires the class to inherit from a parent class")
        }

        // 获取类的属性
        let properties = try extractProperties(from: classDecl)

        var members: [DeclSyntax] = []

        // 生成CodingKeys枚举
        members.append(generateCodingKeysEnum(for: properties))

        // 生成init(from:)方法
        members.append(generateInitFromDecoder(for: properties))

        // 生成encode(to:)方法
        members.append(generateEncodeToEncoder(for: properties))

        if hasRequiredInitializer(classDecl) {
            return members
        } else {
            // 生成required init()方法
            members.append(generateRequiredInit())
            return members
        }
    }

    // 辅助方法：提取类的属性
    private static func extractProperties(from classDecl: ClassDeclSyntax) throws -> [ModelMemberProperty] {
        var properties: [ModelMemberProperty] = []

        for member in classDecl.memberBlock.members {
            // 只处理变量声明
            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                  varDecl.bindingSpecifier.text == "var" else {
                continue
            }

            // 遍历所有绑定
            for binding in varDecl.bindings {
                // 确保有标识符和类型注解
                let identifier = try binding.getIdentifierPattern()
                let baseType = try binding.getVariableType()

                let name = identifier.identifier.text

                // 检查是否是存储属性（有初始值或没有getter/setter）
                let isStored = binding.accessorBlock == nil ||
                    (binding.accessorBlock?.accessors.as(AccessorDeclListSyntax.self) == nil &&
                        binding.accessorBlock?.accessors.as(CodeBlockItemListSyntax.self) == nil)

                // 只添加存储属性
                if isStored {
                    // 判断是否使用了属性包装器
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

                    properties.append(ModelMemberProperty(name: name, type: effectiveType, isWrapped: isWrapped, isStored: true))
                }
            }
        }

        return properties
    }

    // 辅助方法：生成CodingKeys枚举
    private static func generateCodingKeysEnum(for properties: [ModelMemberProperty]) -> DeclSyntax {
        let caseDeclarations = properties.map { property in
            "case \(property.codingKeyName)"
        }.joined(separator: "\n")

        return """
        enum CodingKeys: CodingKey {
            \(raw: caseDeclarations)
        }
        """
    }

    // 辅助方法：生成init(from:)方法
    private static func generateInitFromDecoder(for properties: [ModelMemberProperty]) -> DeclSyntax {
        let decodingStatements = properties.map { property in
            let propertyName = property.accessName
            let propertyType = property.type

            // 处理可选类型
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

    // 辅助方法：生成encode(to:)方法
    private static func generateEncodeToEncoder(for properties: [ModelMemberProperty]) -> DeclSyntax {
        let encodingStatements = properties.map { property in
            if property.type.hasSuffix("?") {
                return "try container.encodeIfPresent(\(property.accessName), forKey: .\(property.codingKeyName))"
            } else {
                return "try container.encode(\(property.accessName), forKey: .\(property.codingKeyName))"
            }
        }.joined(separator: "\n")

        return """
        override func encode(to encoder: Encoder) throws {
            try super.encode(to: encoder)

            var container = encoder.container(keyedBy: CodingKeys.self)
            \(raw: encodingStatements)
        }
        """
    }

    // 检查是否已存在required init()
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

    // 辅助方法：生成required init()方法
    private static func generateRequiredInit() -> DeclSyntax {
        """
        required init() {
            super.init()
        }
        """
    }
}

struct MacroError: CustomStringConvertible, Error {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var description: String {
        text
    }
}

extension MacroError {
    static func requiresExplicitType(for name: String, inferredFrom reason: String) -> MacroError {
        .init("Property '\(name)' requires an explicit type annotation; type cannot be inferred from \(reason) ")
    }
}

struct ModelMemberProperty {
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

extension PatternBindingSyntax {
    /// 获取变量名称
    func getIdentifierPattern() throws -> IdentifierPatternSyntax {
        guard let identifier = pattern.as(IdentifierPatternSyntax.self) else {
            throw MacroError("Property '\(pattern.description)' must be an identifier (e.g., 'var name = ...').")
        }
        return identifier
    }

    /// 获取变量类型，var age：Int，即：Int
    func getVariableType() throws -> String {
        if let explicitType = typeAnnotation?.type.trimmedDescription {
            return explicitType
        }

        return try inferType()
    }

    // 推理类型
    private func inferType() throws -> String {
        guard let expr = initializer?.value else {
            throw MacroError.requiresExplicitType(for: pattern.trimmedDescription, inferredFrom: "missing initializer")
        }

        if expr.is(IntegerLiteralExprSyntax.self) {
            return "Int"
        } else if expr.is(FloatLiteralExprSyntax.self) {
            return "Double"
        } else if expr.is(BooleanLiteralExprSyntax.self) {
            return "Bool"
        } else if expr.is(StringLiteralExprSyntax.self) {
            return "String"
        } else if expr.is(ArrayExprSyntax.self) {
            throw MacroError.requiresExplicitType(for: pattern.trimmedDescription, inferredFrom: "array literal")
        } else if expr.is(DictionaryExprSyntax.self) {
            throw MacroError.requiresExplicitType(for: pattern.trimmedDescription, inferredFrom: "dictionary literal")

        } else if let callExpr = expr.as(FunctionCallExprSyntax.self) {
            let called = callExpr.calledExpression.trimmed.description
            switch called {
            case "Date": return "Date"
            case "UUID": return "UUID"
            case "Data": return "Data"
            default: break
            }
        }

        throw MacroError.requiresExplicitType(for: pattern.trimmedDescription, inferredFrom: "unrecognized expression")
    }
}
