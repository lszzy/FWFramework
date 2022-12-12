//
//  Coder+Wrapper.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import Foundation

extension Wrapper where Base == Data {
    
    public static func encoded<T>(_ value: T, using encoder: AnyEncoder = JSONEncoder()) throws -> Data where T : Encodable {
        return try Base.fw_encoded(value, using: encoder)
    }
    
    public func decoded<T: Decodable>(as type: T.Type = T.self,
                                      using decoder: AnyDecoder = JSONDecoder()) throws -> T {
        return try base.fw_decoded(as: type, using: decoder)
    }
    
}
