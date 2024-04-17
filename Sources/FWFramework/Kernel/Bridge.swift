//
//  Bridge.swift
//  FWFramework
//
//  Created by wuyong on 2024/4/15.
//

import Foundation

@objc internal protocol ObjCObjectBridge {
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
