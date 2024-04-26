import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct FWMacroPlugin: CompilerPlugin {
    
    let providingMacros: [Macro.Type] = [
        MappedValueMacro.self,
        PropertyWrapperMacro.self,
    ]
}
