//
//  Loader.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import Foundation

/// 通用加载器，添加处理句柄后指定输入即可加载输出结果，如需比较请使用"==="或ObjectIdentifier即可
public class Loader<Input, Output> {
    
    private class Target {
        let identifier = UUID().uuidString
        var block: ((Input) -> Output?)?
        weak var target: AnyObject?
        var action: Selector?
        
        func invoke(_ input: Input) -> Output? {
            if block != nil {
                return block?(input)
            }
            
            if let target = target, let action = action, target.responds(to: action) {
                return target.perform(action, with: input)?.takeUnretainedValue() as? Output
            }
            
            return nil
        }
    }
    
    private var allLoaders: [Target] = []
    
    /// 添加block加载器，返回标志id
    @discardableResult
    public func append(block: @escaping (Input) -> Output?) -> String {
        let loader = Target()
        loader.block = block
        allLoaders.append(loader)
        return loader.identifier
    }
    
    /// 添加target和action加载器，返回标志id
    @discardableResult
    public func append(target: AnyObject?, action: Selector) -> String {
        let loader = Target()
        loader.target = target
        loader.action = action
        allLoaders.append(loader)
        return loader.identifier
    }
    
    /// 指定标志id移除加载器
    public func remove(_ identifier: String) {
        allLoaders.removeAll { $0.identifier == identifier }
    }
    
    /// 移除所有的加载器
    public func removeAll() {
        allLoaders.removeAll()
    }
    
    /// 依次执行加载器，直到加载成功
    public func load(_ input: Input) -> Output? {
        var output: Output?
        for loader in allLoaders {
            output = loader.invoke(input)
            if output != nil { break }
        }
        return output
    }
    
}
