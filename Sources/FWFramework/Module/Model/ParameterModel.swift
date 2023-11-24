//
//  ParameterModel.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import Foundation

/// 通用参数与字典非递归编码协议，用于解决字典传参时Key不清晰问题，可自定义实现
public protocol ParameterCodable {
    
    /// 从字典解码为参数，非递归方式
    static func fromDictionary(_ dict: [AnyHashable: Any]?) -> Self
    
    /// 编码为字典，非递归方式
    func toDictionary() -> [AnyHashable: Any]
    
}

/// 通用参数与字典非递归编码模型，用于解决字典传参时Key不清晰问题，可直接使用
public protocol ParameterModel: ParameterCodable, JSONModel {}

extension ParameterModel {
    
    /// 从字典解码为参数，非递归方式
    public static func fromDictionary(_ dict: [AnyHashable: Any]?) -> Self {
        return safeDeserialize(dict)
    }
    
    /// 编码为字典，非递归方式
    public func toDictionary() -> [AnyHashable: Any] {
        return NSObject.fw_mirrorDictionary(self)
    }
    
}
