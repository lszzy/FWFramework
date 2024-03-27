import SwiftSyntax
import SwiftSyntaxBuilder
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
            throw FWMacroPlugin.MacroError("use @MappedValueMacro in `struct` or `class`")
        }
        
        guard let variable = member.as(VariableDeclSyntax.self),
              FWMacroPlugin.isStoredProperty(variable) else {
            return []
        }
        
        guard !variable.description.contains("@MappedValue") else {
            return []
        }
        
        return [AttributeSyntax(stringLiteral: "@MappedValue")]
    }
}
