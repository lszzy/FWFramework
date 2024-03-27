import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxMacros

@main
struct FWMacroPlugin: CompilerPlugin {
    
    let providingMacros: [Macro.Type] = [
        MappedValueMacro.self,
        KeyMappingMacro.self,
    ]
}

extension FWMacroPlugin {
    
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
}
