import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxMacros

public struct MappedValueMacro: MemberAttributeMacro {
    
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingAttributesFor member: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AttributeSyntax] {
        guard (declaration.is(StructDeclSyntax.self) ||
               declaration.is(ClassDeclSyntax.self)) else {
            throw MacroError("use @MappedValueMacro in `struct` or `class`")
        }
        
        guard let variable = member.as(VariableDeclSyntax.self),
              isStoredProperty(variable),
              !isIgnoredProperty(variable),
              !variable.description.contains("@MappedValue") else {
            return []
        }
        
        return [AttributeSyntax(stringLiteral: "@MappedValue")]
    }
}

private extension MappedValueMacro {
    
    struct MacroError: CustomStringConvertible, Error {
        let text: String
        
        init(_ text: String) {
            self.text = text
        }
        
        var description: String {
            text
        }
    }
    
    static func isStoredProperty(_ syntax: VariableDeclSyntax) -> Bool {
        if syntax.modifiers.compactMap({ $0.as(DeclModifierSyntax.self) }).contains(where: { $0.name.text == "static" }) {
            return false
        }
        
        if syntax.bindings.count < 1 {
            return false
        }
        
        let binding = syntax.bindings.last!
        switch binding.accessorBlock?.accessors {
        case .none:
            return true
        case let .accessors(o):
            for accessor in o {
                switch accessor.accessorSpecifier.tokenKind {
                case .keyword(.willSet), .keyword(.didSet):
                    break
                default:
                    return false
                }
            }
            return true
        case .getter:
            return false
        }
    }
    
    static func isIgnoredProperty(_ syntax: VariableDeclSyntax) -> Bool {
        let patterns = syntax.bindings.map(\.pattern)
        let names = patterns.compactMap { $0.as(IdentifierPatternSyntax.self)?.identifier.text }
        let ignored = names.firstIndex(where: { $0.hasPrefix("_") || $0.hasSuffix("_") }) != nil
        return ignored
    }
}

@main
struct FWMacroPlugin: CompilerPlugin {
    
    let providingMacros: [Macro.Type] = [
        MappedValueMacro.self,
    ]
}
