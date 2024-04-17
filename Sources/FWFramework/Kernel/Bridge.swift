//
//  Bridge.swift
//  FWFramework
//
//  Created by wuyong on 2024/4/15.
//

import Foundation

@objc internal protocol ObjCObjectBridge {
    @objc(class)
    var objcClass: AnyClass { get }
    
    @objc(methodSignatureForSelector:)
    func objcMethodSignature(for selector: Selector) -> NSObject & ObjCMethodSignatureBridge
    
    @objc(instanceMethodSignatureForSelector:)
    static func objcInstanceMethodSignature(for selector: Selector) -> NSObject & ObjCMethodSignatureBridge
}

@objc internal protocol ObjCInvocationBridge {
    @objc(selector)
    var objcSelector: Selector { get set }
    
    @objc(target)
    var objcTarget: AnyObject? { get set }
    
    @objc(getReturnValue:)
    func objcGetReturnValue(_ retLoc: UnsafeMutableRawPointer?)
    
    @objc(setArgument:atIndex:)
    func objcSetArgument(_ argumentLocation: UnsafeMutableRawPointer?, at index: Int)
    
    @objc(invoke)
    func objcInvoke()
    
    @objc(invokeWithTarget:)
    func objcInvoke(with target: AnyObject)
    
    @objc(invocationWithMethodSignature:)
    static func objcInvocation(withMethodSignature signature: AnyObject) -> ObjCInvocationBridge
}

@objc internal protocol ObjCMethodSignatureBridge {
    @objc(numberOfArguments)
    var objcNumberOfArguments: UInt { get }
    
    @objc(methodReturnLength)
    var objcMethodReturnLength: UInt { get }
    
    @objc(methodReturnType)
    var objcMethodReturnType: UnsafePointer<CChar> { get }

    @objc(getArgumentTypeAtIndex:)
    func objcArgumentType(at index: UInt) -> UnsafePointer<CChar>

    @objc(signatureWithObjCTypes:)
    static func objcSignature(withObjCTypes typeEncoding: UnsafePointer<Int8>) -> AnyObject
}

internal enum ObjCTypeEncodingBridge: Int8 {
    case char = 99
    case int = 105
    case short = 115
    case long = 108
    case longLong = 113

    case unsignedChar = 67
    case unsignedInt = 73
    case unsignedShort = 83
    case unsignedLong = 76
    case unsignedLongLong = 81

    case float = 102
    case double = 100

    case bool = 66

    case object = 64
    case type = 35
    case selector = 58

    case undefined = -1
}
