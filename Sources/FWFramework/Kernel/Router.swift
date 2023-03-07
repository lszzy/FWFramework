//
//  Router.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/18.
//

import Foundation
#if FWMacroSPM
import FWObjC
#endif

// MARK: - RouterParameter
/// 默认路由参数类，可继承使用，也可完全自定义
open class RouterParameter: ParameterModel {
    
    /// 路由信息来源，默认未使用
    open var routerSource: String?
    /// 路由信息选项，支持NavigationOptions
    open var routerOptions: NavigatorOptions = []
    /// 路由信息句柄，仅open生效
    open var routerHandler: ((RouterContext, UIViewController) -> Void)?
    
    public required init() {}
    
}

// MARK: - Router+RouterParameter
extension Router {
    
    /// 打开此 URL，带上附加信息对象，同时当操作完成时，执行额外的代码
    /// - Parameters:
    ///   - url: 带 Scheme 的 URL，如 app://beauty/4
    ///   - userInfo: 附加信息对象，可自定义
    ///   - completion: URL 处理完成后的 callback，完成的判定跟具体的业务相关
    public class func openURL(_ url: Any, userInfo: ParameterCodable?, completion: RouterCompletion? = nil) {
        openURL(url, userInfo: userInfo?.toDictionary(), completion: completion)
    }
    
    /// 查找谁对某个 URL 感兴趣，如果有的话，返回一个 object；如果没有，返回nil
    /// - Parameters:
    ///   - url: URL 带 Scheme，如 app://beauty/3
    ///   - userInfo: 附加信息对象
    /// - Returns: URL返回的对象
    public class func object(forURL url: Any, userInfo: ParameterCodable?) -> Any? {
        return object(forURL: url, userInfo: userInfo?.toDictionary())
    }
    
}
