import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct FWMacroMacros: CompilerPlugin {
    
    let providingMacros: [Macro.Type] = [
        MappedValueMacro.self,
        PropertyWrapperMacro.self,
    ]
}
