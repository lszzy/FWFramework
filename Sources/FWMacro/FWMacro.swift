import Foundation

@attached(memberAttribute)
public macro MappedValueMacro() = #externalMacro(module: "FWMacroMacros", type: "MappedValueMacro")

@attached(member, names: arbitrary)
public macro KeyMappingMacro() = #externalMacro(module: "FWMacroMacros", type: "KeyMappingMacro")
