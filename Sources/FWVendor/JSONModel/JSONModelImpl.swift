//
//  JSONModelImpl.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import Foundation
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

// MARK: - JSONModelImpl
/// 可选JSONModel读写内存插件，不推荐使用，建议迁移至KeyMappable协议
@_spi(FW) public class JSONModelImpl: NSObject, JSONModelPlugin {
    
    /// 单例模式
    @objc(sharedInstance)
    public static let shared = JSONModelImpl()
    
    // MARK: - JSONModelPlugin
    public func getPropertyKey(_ property: PropertyInfo) -> String {
        guard property.mode == .default else { return property.key }
        let address = Int(bitPattern: property.address)
        return "\(address)"
    }
    
    public func getPropertyAddress<T>(_ instance: inout T, property: Property.Description) -> (address: UnsafeMutablePointer<Int8>?, key: String) where T : _Measurable {
        guard property.mode == .default else { return (address: nil, key: property.key) }
        let address = instance.headPointer().advanced(by: property.offset)
        let key = "\(Int(bitPattern: address))"
        return (address: address, key: key)
    }
    
    public func getProperties(for type: Any.Type) -> [Property.Description]? {
        if let structDescriptor = Metadata.Struct(anyType: type) {
            return structDescriptor.propertyDescriptions()
        } else if let classDescriptor = Metadata.Class(anyType: type) {
            return classDescriptor.propertyDescriptions()
        } else if let objcClassDescriptor = Metadata.ObjcClassWrapper(anyType: type),
            let targetType = objcClassDescriptor.targetType {
            return getProperties(for: targetType)
        }
        return nil
    }
}

// MARK: - JSONModel
extension _Measurable {
    
    // locate the head of a struct type object in memory
    mutating func headPointerOfStruct() -> UnsafeMutablePointer<Int8> {

        return withUnsafeMutablePointer(to: &self) {
            return UnsafeMutableRawPointer($0).bindMemory(to: Int8.self, capacity: MemoryLayout<Self>.stride)
        }
    }

    // locating the head of a class type object in memory
    mutating func headPointerOfClass() -> UnsafeMutablePointer<Int8> {

        let opaquePointer = Unmanaged.passUnretained(self as AnyObject).toOpaque()
        let mutableTypedPointer = opaquePointer.bindMemory(to: Int8.self, capacity: MemoryLayout<Self>.stride)
        return UnsafeMutablePointer<Int8>(mutableTypedPointer)
    }

    // locating the head of an object
    mutating func headPointer() -> UnsafeMutablePointer<Int8> {
        if Self.self is AnyClass {
            return self.headPointerOfClass()
        } else {
            return self.headPointerOfStruct()
        }
    }
}

extension HelpingMapper {
    
    public func specify<T>(property: inout T, name: String) {
        self.specify(property: &property, name: name, converter: nil)
    }
    
    public func specify<T>(property: inout T, converter: @escaping (String) -> T) {
        self.specify(property: &property, name: nil, converter: converter)
    }
    
    public func specify<T>(property: inout T, name: String?, converter: ((String) -> T)?) {
        let pointer = withUnsafePointer(to: &property, { return $0 })
        let key = "\(Int(bitPattern: pointer))"
        self.specify(property: &property, key: key, name: name, converter: converter)
    }
    
    public func exclude<T>(property: inout T) {
        let pointer = withUnsafePointer(to: &property, { return $0 })
        let key = "\(Int(bitPattern: pointer))"
        self.exclude(key: key)
    }
}

infix operator <-- : LogicalConjunctionPrecedence

public func <-- <T>(property: inout T, name: String) -> CustomMappingKeyValueTuple {
    return property <-- [name]
}

public func <-- <T>(property: inout T, names: [String]) -> CustomMappingKeyValueTuple {
    let pointer = withUnsafePointer(to: &property, { return $0 })
    let key = "\(Int(bitPattern: pointer))"
    return (key, MappingPropertyHandler(rawPaths: names, assignmentClosure: nil, takeValueClosure: nil))
}

// MARK: non-optional properties
public func <-- <Transform: TransformType>(property: inout Transform.Object, transformer: Transform) -> CustomMappingKeyValueTuple {
    return property <-- (nil, transformer)
}

public func <-- <Transform: TransformType>(property: inout Transform.Object, transformer: (String?, Transform?)) -> CustomMappingKeyValueTuple {
    let names = (transformer.0 == nil ? [] : [transformer.0!])
    return property <-- (names, transformer.1)
}

public func <-- <Transform: TransformType>(property: inout Transform.Object, transformer: ([String], Transform?)) -> CustomMappingKeyValueTuple {
    let pointer = withUnsafePointer(to: &property, { return $0 })
    let key = "\(Int(bitPattern: pointer))"
    let assignmentClosure = { (jsonValue: Any?) -> Transform.Object? in
        return transformer.1?.transformFromJSON(jsonValue)
    }
    let takeValueClosure = { (objectValue: Any?) -> Any? in
        if let _value = objectValue as? Transform.Object {
            return transformer.1?.transformToJSON(_value) as Any
        }
        return nil
    }
    return (key, MappingPropertyHandler(rawPaths: transformer.0, assignmentClosure: assignmentClosure, takeValueClosure: takeValueClosure))
}

// MARK: optional properties
public func <-- <Transform: TransformType>(property: inout Transform.Object?, transformer: Transform) -> CustomMappingKeyValueTuple {
    return property <-- (nil, transformer)
}

public func <-- <Transform: TransformType>(property: inout Transform.Object?, transformer: (String?, Transform?)) -> CustomMappingKeyValueTuple {
    let names = (transformer.0 == nil ? [] : [transformer.0!])
    return property <-- (names, transformer.1)
}

public func <-- <Transform: TransformType>(property: inout Transform.Object?, transformer: ([String], Transform?)) -> CustomMappingKeyValueTuple {
    let pointer = withUnsafePointer(to: &property, { return $0 })
    let key = "\(Int(bitPattern: pointer))"
    let assignmentClosure = { (jsonValue: Any?) -> Any? in
        return transformer.1?.transformFromJSON(jsonValue)
    }
    let takeValueClosure = { (objectValue: Any?) -> Any? in
        if let _value = objectValue as? Transform.Object {
            return transformer.1?.transformToJSON(_value) as Any
        }
        return nil
    }
    return (key, MappingPropertyHandler(rawPaths: transformer.0, assignmentClosure: assignmentClosure, takeValueClosure: takeValueClosure))
}

infix operator <<< : AssignmentPrecedence

public func <<< (mapper: HelpingMapper, mapping: CustomMappingKeyValueTuple) {
    mapper.addCustomMapping(key: mapping.0, mappingInfo: mapping.1)
}

public func <<< (mapper: HelpingMapper, mappings: [CustomMappingKeyValueTuple]) {
    mappings.forEach { (mapping) in
        mapper.addCustomMapping(key: mapping.0, mappingInfo: mapping.1)
    }
}

infix operator >>> : AssignmentPrecedence

public func >>> <T> (mapper: HelpingMapper, property: inout T) {
    mapper.exclude(property: &property)
}

// MARK: - FieldDescriptor
enum FieldDescriptorKind : UInt16 {
    // Swift nominal types.
    case Struct = 0
    case Class
    case Enum

    // Fixed-size multi-payload enums have a special descriptor format that
    // encodes spare bits.
    //
    // FIXME: Actually implement this. For now, a descriptor with this kind
    // just means we also have a builtin descriptor from which we get the
    // size and alignment.
    case MultiPayloadEnum

    // A Swift opaque protocol. There are no fields, just a record for the
    // type itself.
    case `Protocol`

    // A Swift class-bound protocol.
    case ClassProtocol

    // An Objective-C protocol, which may be imported or defined in Swift.
    case ObjCProtocol

    // An Objective-C class, which may be imported or defined in Swift.
    // In the former case, field type metadata is not emitted, and
    // must be obtained from the Objective-C runtime.
    case ObjCClass
}

struct FieldDescriptor: PointerType {

    var pointer: UnsafePointer<_FieldDescriptor>

    var fieldRecordSize: Int {
        return Int(pointer.pointee.fieldRecordSize)
    }

    var numFields: Int {
        return Int(pointer.pointee.numFields)
    }

    var fieldRecords: [FieldRecord] {
        return (0..<numFields).map({ (i) -> FieldRecord in
            return FieldRecord(pointer: UnsafePointer<_FieldRecord>(pointer + 1) + i)
        })
    }
}

struct _FieldDescriptor {
    var mangledTypeNameOffset: Int32
    var superClassOffset: Int32
    var fieldDescriptorKind: FieldDescriptorKind
    var fieldRecordSize: Int16
    var numFields: Int32
}

struct FieldRecord: PointerType {

    var pointer: UnsafePointer<_FieldRecord>

    var fieldRecordFlags: Int {
        return Int(pointer.pointee.fieldRecordFlags)
    }

    var mangledTypeName: UnsafePointer<UInt8>? {
        let address = Int(bitPattern: pointer) + 1 * 4
        let offset = Int(pointer.pointee.mangledTypeNameOffset)
        let cString = UnsafePointer<UInt8>(bitPattern: address + offset)
        return cString
    }

    var fieldName: String {
        let address = Int(bitPattern: pointer) + 2 * 4
        let offset = Int(pointer.pointee.fieldNameOffset)
        if let cString = UnsafePointer<UInt8>(bitPattern: address + offset) {
            return String(cString: cString)
        }
        return ""
    }
}

struct _FieldRecord {
    var fieldRecordFlags: Int32
    var mangledTypeNameOffset: Int32
    var fieldNameOffset: Int32
}

// MARK: - OtherExtension
protocol UTF8Initializable {
    init?(validatingUTF8: UnsafePointer<CChar>)
}

extension String : UTF8Initializable {}

extension Array where Element : UTF8Initializable {

    init(utf8Strings: UnsafePointer<CChar>) {
        var strings = [Element]()
        var pointer = utf8Strings
        while let string = Element(validatingUTF8: pointer) {
            strings.append(string)
            while pointer.pointee != 0 {
                pointer.advance()
            }
            pointer.advance()
            guard pointer.pointee != 0 else {
                break
            }
        }
        self = strings
    }
}

extension Strideable {
    mutating func advance() {
        self = advanced(by: 1)
    }
}

extension UnsafePointer {

    init<T>(_ pointer: UnsafePointer<T>) {
        self = UnsafeRawPointer(pointer).assumingMemoryBound(to: Pointee.self)
    }
}

func relativePointer<T, U, V>(base: UnsafePointer<T>, offset: U) -> UnsafePointer<V> where U : FixedWidthInteger {
    return UnsafeRawPointer(base).advanced(by: Int(integer: offset)).assumingMemoryBound(to: V.self)
}

extension Int {
    fileprivate init<T : FixedWidthInteger>(integer: T) {
        switch integer {
        case let value as Int: self = value
        case let value as Int32: self = Int(value)
        case let value as Int16: self = Int(value)
        case let value as Int8: self = Int(value)
        default: self = 0
        }
    }
}

// MARK: - Metadata
struct _class_rw_t {
    var flags: Int32
    var version: Int32
    var ro: UInt
    // other fields we don't care

    // reference: include/swift/Remote/MetadataReader.h/readObjcRODataPtr
    func class_ro_t() -> UnsafePointer<_class_ro_t>? {
        var addr: UInt = self.ro
        if (self.ro & UInt(1)) != 0 {
            if let ptr = UnsafePointer<UInt>(bitPattern: self.ro ^ 1) {
                addr = ptr.pointee
            }
        }
        return UnsafePointer<_class_ro_t>(bitPattern: addr)
    }
}

struct _class_ro_t {
    var flags: Int32
    var instanceStart: Int32
    var instanceSize: Int32
    // other fields we don't care
}

// MARK: MetadataType
protocol MetadataType : PointerType {
    static var kind: Metadata.Kind? { get }
}

extension MetadataType {

    var kind: Metadata.Kind {
        return Metadata.Kind(flag: UnsafePointer<Int>(pointer).pointee)
    }

    init?(anyType: Any.Type) {
        self.init(pointer: unsafeBitCast(anyType, to: UnsafePointer<Int>.self))
        if let kind = type(of: self).kind, kind != self.kind {
            return nil
        }
    }
}

// MARK: Metadata
struct Metadata : MetadataType {
    var pointer: UnsafePointer<Int>

    init(type: Any.Type) {
        self.init(pointer: unsafeBitCast(type, to: UnsafePointer<Int>.self))
    }
}

struct _Metadata {}

var is64BitPlatform: Bool {
    return MemoryLayout<Int>.size == MemoryLayout<Int64>.size
}

// MARK: Metadata + Kind
// include/swift/ABI/MetadataKind.def
let MetadataKindIsNonHeap = 0x200
let MetadataKindIsRuntimePrivate = 0x100
let MetadataKindIsNonType = 0x400
extension Metadata {
    static let kind: Kind? = nil

    enum Kind {
        case `struct`
        case `enum`
        case optional
        case opaque
        case foreignClass
        case tuple
        case function
        case existential
        case metatype
        case objCClassWrapper
        case existentialMetatype
        case heapLocalVariable
        case heapGenericLocalVariable
        case errorObject
        case `class` // The kind only valid for non-class metadata
        init(flag: Int) {
            switch flag {
            case (0 | MetadataKindIsNonHeap): self = .struct
            case (1 | MetadataKindIsNonHeap): self = .enum
            case (2 | MetadataKindIsNonHeap): self = .optional
            case (3 | MetadataKindIsNonHeap): self = .foreignClass
            case (0 | MetadataKindIsRuntimePrivate | MetadataKindIsNonHeap): self = .opaque
            case (1 | MetadataKindIsRuntimePrivate | MetadataKindIsNonHeap): self = .tuple
            case (2 | MetadataKindIsRuntimePrivate | MetadataKindIsNonHeap): self = .function
            case (3 | MetadataKindIsRuntimePrivate | MetadataKindIsNonHeap): self = .existential
            case (4 | MetadataKindIsRuntimePrivate | MetadataKindIsNonHeap): self = .metatype
            case (5 | MetadataKindIsRuntimePrivate | MetadataKindIsNonHeap): self = .objCClassWrapper
            case (6 | MetadataKindIsRuntimePrivate | MetadataKindIsNonHeap): self = .existentialMetatype
            case (0 | MetadataKindIsNonType): self = .heapLocalVariable
            case (0 | MetadataKindIsNonType | MetadataKindIsRuntimePrivate): self = .heapGenericLocalVariable
            case (1 | MetadataKindIsNonType | MetadataKindIsRuntimePrivate): self = .errorObject
            default: self = .class
            }
        }
    }
}

// MARK: Metadata + Class
extension Metadata {
    struct Class : ContextDescriptorType {

        static let kind: Kind? = .class
        var pointer: UnsafePointer<_Metadata._Class>

        var isSwiftClass: Bool {
            get {
                // see include/swift/Runtime/Config.h macro SWIFT_CLASS_IS_SWIFT_MASK
                // it can be 1 or 2 depending on environment
                let lowbit = self.pointer.pointee.rodataPointer & 3
                return lowbit != 0
            }
        }

        var contextDescriptorOffsetLocation: Int {
            return is64BitPlatform ? 8 : 11
        }

        var superclass: Class? {
            guard let superclass = pointer.pointee.superclass else {
                return nil
            }
            
            // ignore objc-runtime layer
            guard let metaclass = Metadata.Class(anyType: superclass) else {
                return nil
            }

            // If the superclass doesn't conform to JSONModel/JSONModelenum protocol,
            // we should ignore the properties inside
            // Use metaclass.isSwiftClass to test if it is a swift class, if it is not return nil directly, or `superclass is JSONModel.Type` wil crash.
            if !metaclass.isSwiftClass
                || (!(superclass is any JSONModel.Type) && !(superclass is JSONModelEnum.Type)) {
                return nil
            }

            return metaclass
        }

        var vTableSize: Int {
            // memory size after ivar destroyer
            return Int(pointer.pointee.classObjectSize - pointer.pointee.classObjectAddressPoint) - (contextDescriptorOffsetLocation + 2) * MemoryLayout<Int>.size
        }

        // reference: https://github.com/apple/swift/blob/master/docs/ABI/TypeMetadata.rst#generic-argument-vector
        var genericArgumentVector: UnsafeRawPointer? {
            let pointer = UnsafePointer<Int>(self.pointer)
            var superVTableSize = 0
            if let _superclass = self.superclass {
                superVTableSize = _superclass.vTableSize / MemoryLayout<Int>.size
            }
            let base = pointer.advanced(by: contextDescriptorOffsetLocation + 2 + superVTableSize)
            if base.pointee == 0 {
                return nil
            }
            return UnsafeRawPointer(base)
        }

        func _propertyDescriptionsAndStartPoint() -> ([Property.Description], Int32?)? {
            let instanceStart = pointer.pointee.class_rw_t()?.pointee.class_ro_t()?.pointee.instanceStart
            var result: [Property.Description] = []
            if let fieldOffsets = self.fieldOffsets, let fieldRecords = self.reflectionFieldDescriptor?.fieldRecords {
                class NameAndType {
                    var name: String?
                    var type: Any.Type?
                }
                
                for i in 0..<self.numberOfFields {
                    let name = fieldRecords[i].fieldName
                    if let cMangledTypeName = fieldRecords[i].mangledTypeName,
                        let fieldType = _getTypeByMangledNameInContext(cMangledTypeName, getMangledTypeNameSize(cMangledTypeName), genericContext: self.contextDescriptorPointer, genericArguments: self.genericArgumentVector) {

                        result.append(Property.Description(mode: .default, key: name, type: fieldType, offset: fieldOffsets[i]))
                    }
                }
            }

            if let superclass = superclass,
                String(describing: unsafeBitCast(superclass.pointer, to: Any.Type.self)) != "SwiftObject",  // ignore the root swift object
                let superclassProperties = superclass._propertyDescriptionsAndStartPoint(),
                superclassProperties.0.count > 0 {

                return (superclassProperties.0 + result, superclassProperties.1)
            }
            return (result, instanceStart)
        }

        func propertyDescriptions() -> [Property.Description]? {
            let propsAndStp = _propertyDescriptionsAndStartPoint()
            if let firstInstanceStart = propsAndStp?.1,
                let firstProperty = propsAndStp?.0.first?.offset {
                    return propsAndStp?.0.map({ (propertyDesc) -> Property.Description in
                        let offset = propertyDesc.offset - firstProperty + Int(firstInstanceStart)
                        return Property.Description(mode: .default, key: propertyDesc.key, type: propertyDesc.type, offset: offset)
                    })
            } else {
                return propsAndStp?.0
            }
        }
    }
}

extension _Metadata {
    struct _Class {
        var kind: Int
        var superclass: Any.Type?
        var reserveword1: Int
        var reserveword2: Int
        var rodataPointer: UInt
        var classFlags: UInt32
        var instanceAddressPoint: UInt32
        var instanceSize: UInt32
        var instanceAlignmentMask: UInt16
        var runtimeReservedField: UInt16
        var classObjectSize: UInt32
        var classObjectAddressPoint: UInt32
        var nominalTypeDescriptor: Int
        var ivarDestroyer: Int
        // other fields we don't care

        func class_rw_t() -> UnsafePointer<_class_rw_t>? {
            if MemoryLayout<Int>.size == MemoryLayout<Int64>.size {
                let fast_data_mask: UInt64 = 0x00007ffffffffff8
                let databits_t: UInt64 = UInt64(self.rodataPointer)
                return UnsafePointer<_class_rw_t>(bitPattern: UInt(databits_t & fast_data_mask))
            } else {
                return UnsafePointer<_class_rw_t>(bitPattern: self.rodataPointer & 0xfffffffc)
            }
        }
    }
}

// MARK: Metadata + Struct
extension Metadata {
    struct Struct : ContextDescriptorType {
        static let kind: Kind? = .struct
        var pointer: UnsafePointer<_Metadata._Struct>
        var contextDescriptorOffsetLocation: Int {
            return 1
        }

        var genericArgumentOffsetLocation: Int {
            return 2
        }

        var genericArgumentVector: UnsafeRawPointer? {
            let pointer = UnsafePointer<Int>(self.pointer)
            let base = pointer.advanced(by: genericArgumentOffsetLocation)
            if base.pointee == 0 {
                return nil
            }
            return UnsafeRawPointer(base)
        }

        func propertyDescriptions() -> [Property.Description]? {
            guard let fieldOffsets = self.fieldOffsets, let fieldRecords = self.reflectionFieldDescriptor?.fieldRecords else {
                return []
            }
            var result: [Property.Description] = []
            class NameAndType {
                var name: String?
                var type: Any.Type?
            }
            for i in 0..<self.numberOfFields where fieldRecords[i].mangledTypeName != nil {
                let name = fieldRecords[i].fieldName
                let cMangledTypeName = fieldRecords[i].mangledTypeName!
                
                let functionMap: [String: () -> Any.Type?] = [
                    "function": { _getTypeByMangledNameInContext(cMangledTypeName, UInt(getMangledTypeNameSize(cMangledTypeName)), genericContext: self.contextDescriptorPointer, genericArguments: self.genericArgumentVector) }
                ]
                if let function = functionMap["function"],let fieldType  = function() {
                    result.append(Property.Description(mode:.default, key: name, type: fieldType, offset: fieldOffsets[i]))
                }
            }
            return result
        }
    }
}

extension _Metadata {
    struct _Struct {
        var kind: Int
        var contextDescriptorOffset: Int
        var parent: Metadata?
    }
}

// MARK: Metadata + ObjcClassWrapper
extension Metadata {
    struct ObjcClassWrapper: ContextDescriptorType {
        static let kind: Kind? = .objCClassWrapper
        var pointer: UnsafePointer<_Metadata._ObjcClassWrapper>
        var contextDescriptorOffsetLocation: Int {
            return is64BitPlatform ? 8 : 11
        }

        var targetType: Any.Type? {
            get {
                return pointer.pointee.targetType
            }
        }
    }
}

extension _Metadata {
    struct _ObjcClassWrapper {
        var kind: Int
        var targetType: Any.Type?
    }
}

// MARK: - ContextDescriptorType
protocol ContextDescriptorType : MetadataType {
    var contextDescriptorOffsetLocation: Int { get }
}

extension ContextDescriptorType {

    var contextDescriptor: ContextDescriptorProtocol? {
        let pointer = UnsafePointer<Int>(self.pointer)
        let base = pointer.advanced(by: contextDescriptorOffsetLocation)
        if base.pointee == 0 {
            // swift class created dynamically in objc-runtime didn't have valid contextDescriptor
            return nil
        }
        if self.kind == .class {
            return ContextDescriptor<_ClassContextDescriptor>(pointer: relativePointer(base: base, offset: base.pointee - Int(bitPattern: base)))
        } else {
            return ContextDescriptor<_StructContextDescriptor>(pointer: relativePointer(base: base, offset: base.pointee - Int(bitPattern: base)))
        }
    }

    var contextDescriptorPointer: UnsafeRawPointer? {
        let pointer = UnsafePointer<Int>(self.pointer)
        let base = pointer.advanced(by: contextDescriptorOffsetLocation)
        if base.pointee == 0 {
            return nil
        }
        return UnsafeRawPointer(bitPattern: base.pointee)
    }

    var mangledName: String {
        let pointer = UnsafePointer<Int>(self.pointer)
        let base = pointer.advanced(by: contextDescriptorOffsetLocation)
        let mangledNameAddress = base.pointee + 2 * 4 // 2 properties in front
        if let offset = contextDescriptor?.mangledName,
            let cString = UnsafePointer<UInt8>(bitPattern: mangledNameAddress + offset) {
            return String(cString: cString)
        }
        return ""
    }

    var numberOfFields: Int {
        return contextDescriptor?.numberOfFields ?? 0
    }

    var fieldOffsets: [Int]? {
        guard let contextDescriptor = self.contextDescriptor else {
            return nil
        }
        let vectorOffset = contextDescriptor.fieldOffsetVector
        guard vectorOffset != 0 else {
            return nil
        }
        if self.kind == .class {
            return (0..<contextDescriptor.numberOfFields).map {
                return UnsafePointer<Int>(pointer)[vectorOffset + $0]
            }
        } else {
            return (0..<contextDescriptor.numberOfFields).map {
                return Int(UnsafePointer<Int32>(pointer)[vectorOffset * (is64BitPlatform ? 2 : 1) + $0])
            }
        }
    }

    var reflectionFieldDescriptor: FieldDescriptor? {
        guard let contextDescriptor = self.contextDescriptor else {
            return nil
        }
        let pointer = UnsafePointer<Int>(self.pointer)
        let base = pointer.advanced(by: contextDescriptorOffsetLocation)
        let offset = contextDescriptor.reflectionFieldDescriptor
        let address = base.pointee + 4 * 4 // (4 properties in front) * (sizeof Int32)
        guard let fieldDescriptorPtr = UnsafePointer<_FieldDescriptor>(bitPattern: address + offset) else {
            return nil
        }
        return FieldDescriptor(pointer: fieldDescriptorPtr)
    }
}

protocol ContextDescriptorProtocol {
    var mangledName: Int { get }
    var numberOfFields: Int { get }
    var fieldOffsetVector: Int { get }
    var reflectionFieldDescriptor: Int { get }
}

struct ContextDescriptor<T: _ContextDescriptorProtocol>: ContextDescriptorProtocol, PointerType {

    var pointer: UnsafePointer<T>

    var mangledName: Int {
        return Int(pointer.pointee.mangledNameOffset)
    }

    var numberOfFields: Int {
        return Int(pointer.pointee.numberOfFields)
    }

    var fieldOffsetVector: Int {
        return Int(pointer.pointee.fieldOffsetVector)
    }

    var fieldTypesAccessor: Int {
        return Int(pointer.pointee.fieldTypesAccessor)
    }

    var reflectionFieldDescriptor: Int {
        return Int(pointer.pointee.reflectionFieldDescriptor)
    }
}

protocol _ContextDescriptorProtocol {
    var mangledNameOffset: Int32 { get }
    var numberOfFields: Int32 { get }
    var fieldOffsetVector: Int32 { get }
    var fieldTypesAccessor: Int32 { get }
    var reflectionFieldDescriptor: Int32 { get }
}

struct _StructContextDescriptor: _ContextDescriptorProtocol {
    var flags: Int32
    var parent: Int32
    var mangledNameOffset: Int32
    var fieldTypesAccessor: Int32
    var reflectionFieldDescriptor: Int32
    var numberOfFields: Int32
    var fieldOffsetVector: Int32
}

struct _ClassContextDescriptor: _ContextDescriptorProtocol {
    var flags: Int32
    var parent: Int32
    var mangledNameOffset: Int32
    var fieldTypesAccessor: Int32
    var reflectionFieldDescriptor: Int32
    var superClsRef: Int32
    var metadataNegativeSizeInWords: Int32
    var metadataPositiveSizeInWords: Int32
    var numImmediateMembers: Int32
    var numberOfFields: Int32
    var fieldOffsetVector: Int32
}

// MARK: - PointerType
protocol PointerType : Equatable {
    associatedtype Pointee
    var pointer: UnsafePointer<Pointee> { get set }
}

extension PointerType {
    init<T>(pointer: UnsafePointer<T>) {
        func cast<T1, U>(_ value: T1) -> U {
            return unsafeBitCast(value, to: U.self)
        }
        self = cast(UnsafePointer<Pointee>(pointer))
    }
}

// MARK: - CBridge
@_silgen_name("swift_getTypeByMangledNameInContext")
public func _getTypeByMangledNameInContext(
    _ name: UnsafePointer<UInt8>,
    _ nameLength: Int,
    genericContext: UnsafeRawPointer?,
    genericArguments: UnsafeRawPointer?)
    -> Any.Type?

// MARK: - MangledName
// mangled name might contain 0 but it is not the end, do not just use strlen
func getMangledTypeNameSize(_ mangledName: UnsafePointer<UInt8>) -> Int {
   // TODO: should find the actually size
   return 256
}

// MARK: - Autoloader+JSONModelImpl
@objc extension Autoloader {
    
    static func loadVendor_JSONModel() {
        PluginManager.presetPlugin(JSONModelPlugin.self, object: JSONModelImpl.self)
    }
    
}
