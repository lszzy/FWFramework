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
        return try PropertyWrapperMacro.expansion(propertyWrapper: "@MappedValue", of: node, attachedTo: declaration, providingAttributesFor: member, in: context)
    }
}
