//
//  Bridge.swift
//  FWFramework
//
//  Created by wuyong on 2024/4/15.
//

import Foundation

// MARK: - ObjCBridge
@objc protocol ObjCObjectBridge {
    @objc(instanceMethodSignatureForSelector:)
    static func objcInstanceMethodSignature(for selector: Selector) -> NSObject & ObjCMethodSignatureBridge
}

@objc protocol ObjCInvocationBridge {
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

    @objc(invocationWithMethodSignature:)
    static func objcInvocation(withMethodSignature signature: AnyObject) -> ObjCInvocationBridge
}

@objc protocol ObjCMethodSignatureBridge {
    @objc(numberOfArguments)
    var objcNumberOfArguments: UInt { get }

    @objc(methodReturnType)
    var objcMethodReturnType: UnsafePointer<CChar> { get }

    @objc(getArgumentTypeAtIndex:)
    func objcGetArgumentType(at index: UInt) -> UnsafePointer<CChar>

    @objc(signatureWithObjCTypes:)
    static func objcSignature(withObjCTypes typeEncoding: UnsafePointer<Int8>) -> AnyObject
}

enum ObjCClassBridge {
    static let invocationClass: AnyClass? = NSClassFromString("NSInvocation")
    static let methodSignatureClass: AnyClass? = NSClassFromString("NSMethodSignature")

    static let forwardInvocationSelector = NSSelectorFromString("forwardInvocation:")
    static let methodSignatureSelector = NSSelectorFromString("methodSignatureForSelector:")
}

enum ObjCTypeEncodingBridge: Int8 {
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
