import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct KeyMappingMacro: MemberMacro {
    
    public static func expansion<Declaration: DeclGroupSyntax, Context: MacroExpansionContext>(
        of node: AttributeSyntax,
        providingMembersOf declaration: Declaration,
        in context: Context
    ) throws -> [DeclSyntax] {
        guard (declaration.is(StructDeclSyntax.self) ||
               declaration.is(ClassDeclSyntax.self)) else {
            throw FWMacroPlugin.MacroError("use @KeyMappingMacro in `struct` or `class`")
        }
        
        var names: [String] = []
        for member in declaration.memberBlock.members {
            guard let variable = member.decl.as(VariableDeclSyntax.self),
                  FWMacroPlugin.isStoredProperty(variable) else {
                continue
            }
            
            guard !variable.description.contains("@MappedValue") else {
                continue
            }
            
            let patterns = variable.bindings.map(\.pattern)
            let texts = patterns.compactMap { $0.as(IdentifierPatternSyntax.self)?.identifier.text }
            if !texts.isEmpty {
                names.append(contentsOf: texts)
            }
        }
        
        var declString = "static var keyMapping: [KeyMap<Self>] = [\n"
        names.forEach { name in
            declString.append("KeyMap(\\.\(name), to: \"\(name)\"),\n")
        }
        declString += "]"
        return [DeclSyntax(stringLiteral: declString)]
    }
}
