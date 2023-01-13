//
//  Router.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import Foundation

/// 路由处理句柄，仅支持openURL时可返回nil
public typealias RouterHandler = (RouterContext) -> Any?

/// 路由完成句柄，openURL时可设置完成回调
public typealias RouterCompletion = (Any?) -> Void

/// 路由用户信息Key定义
public struct RouterUserInfoKey: RawRepresentable, Equatable, Hashable {
    
    public typealias RawValue = String
    
    /// 路由信息来源Key，默认未处理
    public static let routerSource: RouterUserInfoKey = .init("routerSource")
    /// 路由信息选项Key，默认支持NavigationOptions
    public static let routerOptions: RouterUserInfoKey = .init("routerOptions")
    /** 路由信息句柄Key，默认参数context、viewController，无返回值，仅open生效 */
    public static let routerHandler: RouterUserInfoKey = .init("routerHandler")
    
    public var rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
    
}

/// URL路由上下文
public class RouterContext: NSObject {
    
    /// 路由URL
    public private(set) var url: String
    
    /// 路由用户信息
    public private(set) var userInfo: [AnyHashable: Any]?
    
    /// 路由完成回调
    public private(set) var completion: RouterCompletion?
    
    /// 路由URL解析参数字典
    public fileprivate(set) lazy var urlParameters: [AnyHashable: Any] = {
        var urlParameters: [String: String] = [:]
        if let queryUrl = URL.fw_url(string: url),
           let queryItems = URLComponents(url: queryUrl, resolvingAgainstBaseURL: false)?.queryItems {
            // queryItems.value会自动进行URL参数解码
            for item in queryItems {
                urlParameters[item.name] = item.value
            }
        }
        return urlParameters
    }()
    
    /// 路由userInfo和URLParameters合并参数，URL参数优先级高
    public fileprivate(set) lazy var parameters: [AnyHashable: Any] = {
        var parameters: [AnyHashable: Any] = [:]
        if let userInfo = userInfo {
            parameters.merge(userInfo) { key1, key2 in key2 }
        }
        parameters.merge(urlParameters) { key1, key2 in key2 }
        return parameters
    }()
    
    /// 路由是否以openURL方式打开，区别于objectForURL
    public fileprivate(set) var isOpening: Bool = false
    
    /// 创建路由参数对象
    public init(url: String, userInfo: [AnyHashable: Any]? = nil, completion: RouterCompletion? = nil) {
        self.url = url
        self.userInfo = userInfo
        self.completion = completion
    }
    
}

/// URL路由器
///
/// 由于Function也是闭包，FWRouterHandler参数支持静态方法，示例：AppRouter.routePlugin(_:)
/// [MGJRouter](https://github.com/meili/MGJRouter)
/// [FFRouter](https://github.com/imlifengfeng/FFRouter)
public class Router: NSObject {
    
    private static let routeWildcardCharacter = "*"
    private static let routeSpecialCharacters = "/?&."
    private static let routeCoreKey = "FWRouterCore"
    private static let routeBlockKey = "FWRouterBlock"
    
    /// 路由规则，结构类似 ["beauty": [":id": [routerCoreKey: block]]]
    private static var routeRules = NSMutableDictionary()
    
    /// 路由类加载器，访问未注册路由时会尝试调用并注册，block返回值为register方法class参数
    public static let sharedLoader = Loader<String, Any>()
    
    /// 注册路由类或对象，批量注册路由规则
    /// - Parameters:
    ///   - clazz: 路由类或对象，不遍历父类
    ///   - mapper: 自定义映射，默认nil时查找规则：xxxUrl => xxxRouter: > xxxDefaultRouter:
    /// - Returns: 是否注册成功
    @discardableResult
    public class func registerClass(_ clazz: Any, mapper: (([String]) -> [String: String])? = nil) -> Bool {
        return registerClass(clazz, isPreset: false, mapper: mapper)
    }
    
    /// 预置路由类或对象，批量注册路由规则，仅当路由未被注册时生效
    /// - Parameters:
    ///   - clazz: 路由类或对象，不遍历父类
    ///   - mapper: 自定义映射，默认nil时查找规则：xxxUrl => xxxRouter: > xxxDefaultRouter:
    /// - Returns: 是否注册成功
    @discardableResult
    public class func presetClass(_ clazz: Any, mapper: (([String]) -> [String: String])? = nil) -> Bool {
        return registerClass(clazz, isPreset: true, mapper: mapper)
    }
    
    private class func registerClass(_ clazz: Any, isPreset: Bool, mapper: (([String]) -> [String: String])?) -> Bool {
        var result = true
        let routes = routeClass(clazz, mapper: mapper)
        if let objectClass = clazz as? NSObject.Type {
            for (key, obj) in routes {
                guard let pattern = objectClass.perform(NSSelectorFromString(key))?.takeUnretainedValue() else { continue }
                result = registerURL(pattern, handler: { context in
                    return objectClass.perform(NSSelectorFromString(obj), with: context)?.takeUnretainedValue()
                }, isPreset: isPreset) && result
            }
        } else if let object = clazz as? NSObject {
            for (key, obj) in routes {
                guard let pattern = object.perform(NSSelectorFromString(key))?.takeUnretainedValue() else { continue }
                result = registerURL(pattern, handler: { context in
                    return object.perform(NSSelectorFromString(obj), with: context)?.takeUnretainedValue()
                }, isPreset: isPreset) && result
            }
        }
        return result
    }
    
    /// 取消注册某个路由类或对象
    /// - Parameters:
    ///   - clazz: 路由类或对象，不遍历父类
    ///   - mapper: 自定义映射，默认nil时查找规则：xxxUrl => xxxRouter: > xxxDefaultRouter:
    public class func unregisterClass(_ clazz: Any, mapper: (([String]) -> [String: String])? = nil) {
        let routes = routeClass(clazz, mapper: mapper)
        if let objectClass = clazz as? NSObject.Type {
            for (key, _) in routes {
                guard let pattern = objectClass.perform(NSSelectorFromString(key))?.takeUnretainedValue() else { continue }
                unregisterURL(pattern)
            }
        } else if let object = clazz as? NSObject {
            for (key, _) in routes {
                guard let pattern = object.perform(NSSelectorFromString(key))?.takeUnretainedValue() else { continue }
                unregisterURL(pattern)
            }
        }
    }
    
    private class func routeClass(_ clazz: Any, mapper: (([String]) -> [String: String])?) -> [String: String] {
        var targetClass: AnyClass?
        if let clazz = clazz as? AnyClass {
            if let className = (NSStringFromClass(clazz) as NSString).utf8String {
                targetClass = objc_getMetaClass(className) as? AnyClass
            }
        } else {
            targetClass = object_getClass(clazz)
        }
        guard let targetClass = targetClass else { return [:] }
        
        let methods = NSObject.fw_classMethods(targetClass, superclass: false)
        if let mapper = mapper {
            return mapper(methods)
        }
        
        var routes: [String: String] = [:]
        for method in methods {
            if !method.hasSuffix("Url") || method.contains(":") { continue }
            
            var handler = method.replacingOccurrences(of: "Url", with: "Router:")
            if !methods.contains(handler) {
                handler = method.replacingOccurrences(of: "Url", with: "DefaultRouter:")
                if !methods.contains(handler) { continue }
            }
            routes[method] = handler
        }
        return routes
    }
    
    /// 注册 pattern 对应的 Handler，可返回一个 object 给调用方，也可直接触发事件返回nil
    /// - Parameters:
    ///   - pattern: 字符串或字符串数组，带上 scheme，如 app://beauty/:id
    ///   - handler: 路由处理句柄，参数为路由上下文对象
    /// - Returns: 是否注册成功
    @discardableResult
    public class func registerURL(_ pattern: Any, handler: @escaping RouterHandler) -> Bool {
        return registerURL(pattern, handler: handler, isPreset: false)
    }
    
    /// 预置 pattern 对应的 Handler，可返回一个 object 给调用方，也可直接触发事件返回nil，仅当路由未被注册时生效
    /// - Parameters:
    ///   - pattern: 字符串或字符串数组，带上 scheme，如 app://beauty/:id
    ///   - handler: 路由处理句柄，参数为路由上下文对象
    /// - Returns: 是否注册成功
    public class func presetURL(_ pattern: Any, handler: @escaping RouterHandler) -> Bool {
        return registerURL(pattern, handler: handler, isPreset: true)
    }
    
    private class func registerURL(_ pattern: Any, handler: @escaping RouterHandler, isPreset: Bool) -> Bool {
        if let patterns = pattern as? [Any] {
            var result = true
            for subPattern in patterns {
                result = registerURL(subPattern, handler: handler, isPreset: isPreset) && result
            }
            return result
        }
        
        guard let pattern = pattern as? String, !pattern.isEmpty else { return false }
        
        let subRoutes = registerRoute(pattern)
        if isPreset && subRoutes[routeCoreKey] != nil { return false }
        
        subRoutes[routeCoreKey] = handler
        return true
    }
    
    /// 取消注册某个 pattern
    /// - Parameter pattern: 字符串或字符串数组
    public class func unregisterURL(_ pattern: Any) {
        if let patterns = pattern as? [Any] {
            for subPattern in patterns {
                unregisterURL(subPattern)
            }
            return
        }
        
        guard let pattern = pattern as? String, !pattern.isEmpty else { return }
        
        var pathComponents = pathComponents(from: pattern)
        // 只删除该 pattern 的最后一级
        if pathComponents.count < 1 { return }
        
        // 假如 URLPattern 为 a/b/c, components 就是 @"a.b.c" 正好可以作为 KVC 的 key
        let components = pathComponents.joined(separator: ".")
        var routeRule = routeRules.value(forKeyPath: components) as? NSMutableDictionary ?? NSMutableDictionary()
        guard routeRule.count >= 1 else { return }
        
        let lastComponent = pathComponents.last ?? ""
        pathComponents.removeLast()
        
        // 有可能是根 key，这样就是 self.routes 了
        routeRule = routeRules
        if pathComponents.count > 0 {
            let componentsWithoutLast = pathComponents.joined(separator: ".")
            routeRule = routeRules.value(forKeyPath: componentsWithoutLast) as? NSMutableDictionary ?? NSMutableDictionary()
        }
        routeRule.removeObject(forKey: lastComponent)
    }
    
    /// 取消注册所有 pattern
    public class func unregisterAllURLs() {
        routeRules.removeAllObjects()
    }
    
    /// 设置全局路由过滤器，URL 被访问时优先触发。如果返回YES，继续解析pattern，否则停止解析
    public static var routeFilter: ((RouterContext) -> Bool)?
    
    /// 设置全局路由处理器，URL 被访问且有返回值时触发，可用于打开VC、附加设置等
    public static var routeHandler: ((RouterContext, Any) -> Any?)?
    
    /// 设置全局错误句柄，URL 未注册时触发，可用于错误提示、更新提示等
    public static var errorHandler: ((RouterContext) -> Void)?
    
    /// 预置全局路由处理器，仅当未设置routeHandler时生效，值为nil时默认打开VC
    /// - Parameter handler: 路由处理器
    public class func presetRouteHandler(_ handler: ((RouterContext, Any) -> Any?)? = nil) {
        if routeHandler != nil { return }
        
        routeHandler = handler ?? { context, object in
            if !context.isOpening { return object }
            guard let viewController = object as? UIViewController else { return object }
            
            if let routerHandler = context.userInfo?[RouterUserInfoKey.routerHandler] as? (RouterContext, UIViewController) -> Void {
                routerHandler(context, viewController)
            } else {
                var routerOptions: NavigatorOptions = []
                if let navigatorOptions = context.userInfo?[RouterUserInfoKey.routerOptions] as? NavigatorOptions {
                    routerOptions = navigatorOptions
                } else if let optionsNumber = context.userInfo?[RouterUserInfoKey.routerOptions] as? NSNumber {
                    routerOptions = .init(rawValue: optionsNumber.intValue)
                }
                UIWindow.fw_mainWindow?.fw_open(viewController, animated: true, options: routerOptions, completion: nil)
            }
            return nil
        }
    }
    
    /// 是否可以打开URL，不含object
    /// - Parameter url: URL 带 Scheme，如 app://beauty/3
    /// - Returns: 是否可以打开
    public class func canOpenURL(_ url: Any) -> Bool {
        let rewriteURL = rewriteURL(url)
        guard !rewriteURL.isEmpty else { return false }
        
        let URLParameters = routeParameters(from: rewriteURL)
        return URLParameters[routeBlockKey] != nil
    }
    
    /// 打开此 URL，带上附加信息，同时当操作完成时，执行额外的代码
    /// - Parameters:
    ///   - url: 带 Scheme 的 URL，如 app://beauty/4
    ///   - userInfo: 附加参数
    ///   - completion: URL 处理完成后的 callback，完成的判定跟具体的业务相关
    public class func openURL(_ url: Any, userInfo: [AnyHashable: Any]? = nil, completion: RouterCompletion? = nil) {
        let rewriteURL = rewriteURL(url)
        guard !rewriteURL.isEmpty else { return }
        
        let urlParameters = routeParameters(from: rewriteURL)
        let handler = urlParameters[routeBlockKey] as? RouterHandler
        urlParameters.removeObject(forKey: routeBlockKey)
        
        let context = RouterContext(url: rewriteURL, userInfo: userInfo, completion: completion)
        context.urlParameters = urlParameters as! [AnyHashable : Any]
        context.isOpening = true
        
        if let routeFilter = routeFilter {
            if !routeFilter(context) { return }
        }
        if let handler = handler {
            let object = handler(context)
            if let object = object, let routeHandler = routeHandler {
                _ = routeHandler(context, object)
            }
            return
        }
        errorHandler?(context)
    }
    
    /// 快速调用RouterHandler参数中的回调句柄，指定回调结果
    /// - Parameters:
    ///   - context: RouterHandler中的模型参数
    ///   - result: URL处理完成后的回调结果
    public class func completeURL(_ context: RouterContext, result: Any?) {
        context.completion?(result)
    }
    
    /// 查找谁对某个 URL 感兴趣，如果有的话，返回一个 object；如果没有，返回nil
    /// - Parameters:
    ///   - url: URL 带 Scheme，如 app://beauty/3
    ///   - userInfo: 附加参数
    /// - Returns: URL返回的对象
    public class func object(forURL url: Any, userInfo: [AnyHashable: Any]? = nil) -> Any? {
        let rewriteURL = rewriteURL(url)
        guard !rewriteURL.isEmpty else { return nil }
        
        let urlParameters = routeParameters(from: rewriteURL)
        let handler = urlParameters[routeBlockKey] as? RouterHandler
        urlParameters.removeObject(forKey: routeBlockKey)
        
        let context = RouterContext(url: rewriteURL, userInfo: userInfo, completion: nil)
        context.urlParameters = urlParameters as! [AnyHashable : Any]
        context.isOpening = false
        
        if let routeFilter = routeFilter {
            if !routeFilter(context) { return nil }
        }
        if let handler = handler {
            let object = handler(context)
            if let object = object, let routeHandler = routeHandler {
                return routeHandler(context, object)
            }
            return object
        }
        errorHandler?(context)
        return nil
    }
    
    /// 调用此方法来拼接 pattern 和 parameters
    ///
    /// Router.generateURL("beauty/:id", parameters: 13)
    /// Router.generateURL("beauty/:id", parameters: ["id": 13])
    /// - Parameters:
    ///   - pattern: url pattern 比如 @"beauty/:id"
    ///   - parameters: 一个数组(数量和变量一致)或一个字典(key为变量名称)或单个值(替换所有参数)
    /// - Returns: 返回生成的URL String
    public class func generateURL(_ pattern: String, parameters: Any?) -> String {
        var startIndex: Int = 0
        var placeholders: [String] = []
        let patternString = pattern as NSString
        
        for i in 0 ..< patternString.length {
            let character = String(format: "%c", patternString.character(at: i))
            if character == ":" {
                startIndex = i
            }
            if routeSpecialCharacters.range(of: character) != nil &&
                i > (startIndex + 1) && startIndex != 0 {
                let range = NSMakeRange(startIndex, i - startIndex)
                let placeholder = patternString.substring(with: range)
                let specialCharactersSet = CharacterSet(charactersIn: routeSpecialCharacters)
                if placeholder.rangeOfCharacter(from: specialCharactersSet) == nil {
                    placeholders.append(placeholder)
                    startIndex = 0
                }
            }
            if i == patternString.length - 1 && startIndex != 0 {
                let range = NSMakeRange(startIndex, i - startIndex + 1)
                let placeholder = patternString.substring(with: range)
                let specialCharactersSet = CharacterSet(charactersIn: routeSpecialCharacters)
                if placeholder.rangeOfCharacter(from: specialCharactersSet) == nil {
                    placeholders.append(placeholder)
                }
            }
        }
        
        var parsedResult = pattern
        if let paramArray = parameters as? [Any] {
            for idx in 0 ..< placeholders.count {
                if idx < paramArray.count {
                    let value = paramArray[paramArray.count - 1]
                    parsedResult = parsedResult.replacingOccurrences(of: placeholders[idx], with: String.fw_safeString(value))
                }
            }
        } else if let paramDict = parameters as? [AnyHashable: Any] {
            for idx in 0 ..< placeholders.count {
                let value = paramDict[placeholders[idx].replacingOccurrences(of: ":", with: "")]
                if let value = value {
                    parsedResult = parsedResult.replacingOccurrences(of: placeholders[idx], with: String.fw_safeString(value))
                }
            }
        } else if let parameters = parameters {
            for placeholder in placeholders {
                parsedResult = parsedResult.replacingOccurrences(of: placeholder, with: String.fw_safeString(parameters))
            }
        }
        return parsedResult
    }
    
    private class func registerRoute(_ pattern: String) -> NSMutableDictionary {
        let pathComponents = pathComponents(from: pattern)
        
        var subRoutes = routeRules
        for pathComponent in pathComponents {
            if subRoutes[pathComponent] == nil {
                subRoutes[pathComponent] = NSMutableDictionary()
            }
            subRoutes = subRoutes[pathComponent] as? NSMutableDictionary ?? NSMutableDictionary()
        }
        return subRoutes
    }
    
    private class func pathComponents(from url: String) -> [String] {
        var formatUrl = url
        var pathComponents: [String] = []
        // 解析scheme://path格式
        var urlRange = (url as NSString).range(of: "://")
        let fullUrl = URL.fw_url(string: url)
        if urlRange.location == NSNotFound {
            // 解析scheme:path格式
            let urlScheme = (fullUrl?.scheme?.appending(":") ?? "") as NSString
            if urlScheme.length > 1 && url.hasPrefix(urlScheme as String) {
                urlRange = NSMakeRange(urlScheme.length - 1, 1)
            }
        }
        
        if urlRange.location != NSNotFound {
            // 如果 URL 包含协议，那么把协议作为第一个元素放进去
            let urlString = url as NSString
            let pathScheme = urlString.substring(to: urlRange.location)
            if !pathScheme.isEmpty {
                pathComponents.append(pathScheme)
            }
            
            // 如果只有协议，那么放一个占位符
            formatUrl = urlString.substring(from: urlRange.location + urlRange.length)
            if formatUrl.isEmpty {
                pathComponents.append(routeWildcardCharacter)
            }
        }
        
        let pathUrl = URL.fw_url(string: formatUrl)
        var components = pathUrl?.pathComponents ?? []
        if components.count < 1 && urlRange.location != NSNotFound && !formatUrl.isEmpty, let fullUrl = fullUrl {
            let urlComponents = NSURLComponents(url: fullUrl, resolvingAgainstBaseURL: false)
            if let urlComponents = urlComponents, urlComponents.rangeOfPath.location != NSNotFound {
                let pathDomain = (formatUrl as NSString).substring(to: urlComponents.rangeOfPath.location - (urlRange.location + urlRange.length))
                if !pathDomain.isEmpty {
                    pathComponents.append(pathDomain)
                }
            }
            components = fullUrl.pathComponents
        }
        for pathComponent in components {
            if pathComponent.isEmpty || pathComponent == "/" { continue }
            if (pathComponent as NSString).substring(to: 1) == "?" { break }
            pathComponents.append(pathComponent)
        }
        return pathComponents
    }
    
    private class func routeParameters(from url: String) -> NSMutableDictionary {
        var parameters = extractParameters(from: url)
        if parameters[routeBlockKey] != nil { return parameters }
        
        if let object = sharedLoader.load(url) {
            registerClass(object, mapper: nil)
            parameters = extractParameters(from: url)
        }
        return parameters
    }
    
    private class func extractParameters(from url: String) -> NSMutableDictionary {
        let parameters = NSMutableDictionary()
        var subRoutes = routeRules
        let pathComponents = pathComponents(from: url)
        
        var wildcardMatched = false
        for pathComponent in pathComponents {
            // 对 key 进行排序，这样可以把 * 放到最后
            let subRoutesKeys = subRoutes.allKeys.compactMap { key in
                return key as? String
            }.sorted { key1, key2 in
                return key2.caseInsensitiveCompare(key1) == .orderedAscending
            }
            
            for key in subRoutesKeys {
                if key == pathComponent || key == routeWildcardCharacter {
                    wildcardMatched = true
                    subRoutes = subRoutes[key] as? NSMutableDictionary ?? NSMutableDictionary()
                    break
                } else if key.hasPrefix(":") {
                    wildcardMatched = true
                    subRoutes = subRoutes[key] as? NSMutableDictionary ?? NSMutableDictionary()
                    var newKey = (key as NSString).substring(from: 1)
                    var newPathComponent = pathComponent
                    // 再做一下特殊处理，比如 :id.html -> :id
                    let specialCharactersSet = CharacterSet(charactersIn: routeSpecialCharacters)
                    let range = (key as NSString).rangeOfCharacter(from: specialCharactersSet)
                    if range.location != NSNotFound {
                        // 把 pathComponent 后面的部分也去掉
                        newKey = (newKey as NSString).substring(to: range.location - 1)
                        let suffixToStrip = (key as NSString).substring(from: range.location)
                        newPathComponent = newPathComponent.replacingOccurrences(of: suffixToStrip, with: "")
                    }
                    parameters[newKey] = newPathComponent.removingPercentEncoding
                    break
                } else {
                    wildcardMatched = false
                }
            }
            
            // 如果没有找到该 pathComponent 对应的 handler，则以上一层的 handler 作为 fallback
            if !wildcardMatched && subRoutes[routeCoreKey] == nil {
                break
            }
        }
        
        if let nsurl = URL.fw_url(string: url),
           let queryItems = URLComponents(url: nsurl, resolvingAgainstBaseURL: false)?.queryItems {
            // queryItems.value会自动进行URL参数解码
            for item in queryItems {
                parameters[item.name] = item.value
            }
        }
        
        if subRoutes[routeCoreKey] != nil {
            parameters[routeBlockKey] = subRoutes[routeCoreKey]
        } else {
            parameters.removeObject(forKey: routeBlockKey)
        }
        return parameters
    }
    
}

extension Router {
    
    private static var rewriteRules = [String: String]()
    
    /// 全局重写过滤器
    public static var rewriteFilter: ((String) -> String?)?
    
    /// 根据重写规则，重写URL
    /// - Parameter url: 需要重写的url
    /// - Returns: 重写之后的url
    public class func rewriteURL(_ url: Any) -> String {
        var rewriteURL = url as? String
        if let nsurl = url as? URL {
            rewriteURL = nsurl.absoluteString
        }
        guard var rewriteURL = rewriteURL else { return "" }
        
        if let rewriteFilter = rewriteFilter {
            guard let filterURL = rewriteFilter(rewriteURL) else { return "" }
            rewriteURL = filterURL
        }
        
        if rewriteRules.count < 1 { return rewriteURL }
        let rewriteCaptureGroups = rewriteCaptureGroups(originalURL: rewriteURL)
        rewriteURL = rewriteComponents(originalURL: rewriteURL, targetRule: rewriteCaptureGroups)
        return rewriteURL
    }
    
    /// 添加重写规则
    /// - Parameters:
    ///   - matchRule: 匹配规则
    ///   - targetRule: 目标规则
    public class func addRewriteRule(_ matchRule: String, targetRule: String) {
        guard !matchRule.isEmpty else { return }
        rewriteRules[matchRule] = targetRule
    }
    
    /// 批量添加重写规则
    /// - Parameter rules: 规则字典
    public class func addRewriteRules(_ rules: [String: String]) {
        for (matchRule, targetRule) in rules {
            addRewriteRule(matchRule, targetRule: targetRule)
        }
    }
    
    /// 移除重写规则
    /// - Parameter matchRule: 匹配规则
    public class func removeRewriteRule(_ matchRule: String) {
        rewriteRules.removeValue(forKey: matchRule)
    }
    
    /// 移除所有的重写规则
    public class func removeAllRewriteRules() {
        rewriteRules.removeAll()
    }
    
    private class func rewriteCaptureGroups(originalURL: String) -> String {
        let rules = rewriteRules
        if rules.count > 0 {
            let targetURL = originalURL
            let replaceRx = try? NSRegularExpression(pattern: "[$]([$|#]?)(\\d+)", options: [])
            
            for (matchRule, targetRule) in rules {
                let searchRange = NSMakeRange(0, (targetURL as NSString).length)
                let rx = try? NSRegularExpression(pattern: matchRule, options: [])
                let range = rx?.rangeOfFirstMatch(in: targetURL, options: [], range: searchRange)
                if let range = range, range.length != 0 {
                    var groupValues: [String] = []
                    let result = rx?.firstMatch(in: targetURL, options: [], range: searchRange)
                    for idx in 0 ..< (rx?.numberOfCaptureGroups ?? 0) + 1 {
                        if let groupRange = result?.range(at: idx), groupRange.length != 0 {
                            groupValues.append((targetURL as NSString).substring(with: groupRange))
                        }
                    }
                    
                    let newTargetURL = NSMutableString(string: targetRule)
                    replaceRx?.enumerateMatches(in: targetRule, options: [], range: NSMakeRange(0, (targetRule as NSString).length), using: { result, _, _ in
                        guard let result = result else { return }
                        let matchRange = result.range
                        let secondGroupRange = result.range(at: 2)
                        let replacedValue = (targetRule as NSString).substring(with: matchRange)
                        let index = ((targetRule as NSString).substring(with: secondGroupRange) as NSString).integerValue
                        if index >= 0 && index < groupValues.count {
                            let newValue = convertCaptureGroups(checkingResult: result, targetRule: targetRule, originalValue: groupValues[index])
                            newTargetURL.replaceOccurrences(of: replacedValue, with: newValue, options: [], range: NSMakeRange(0, newTargetURL.length))
                        }
                    })
                    return newTargetURL as String
                }
            }
        }
        return originalURL
    }
    
    private class func rewriteComponents(originalURL: String, targetRule: String) -> String {
        let encodeURL = originalURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let urlComponents = URLComponents(string: encodeURL ?? "")
        var componentDict: [String: String] = [:]
        componentDict["url"] = originalURL
        componentDict["scheme"] = urlComponents?.scheme
        componentDict["host"] = urlComponents?.host
        if let componentPort = urlComponents?.port {
            componentDict["port"] = "\(componentPort)"
        }
        componentDict["path"] = urlComponents?.path
        componentDict["query"] = urlComponents?.query
        componentDict["fragment"] = urlComponents?.fragment
        
        let targetURL = NSMutableString(string: targetRule)
        let replaceRx = try? NSRegularExpression(pattern: "[$]([$|#]?)(\\w+)", options: [])
        replaceRx?.enumerateMatches(in: targetRule, options: [], range: NSMakeRange(0, (targetRule as NSString).length), using: { result, _, _ in
            guard let result = result else { return }
            let matchRange = result.range
            let secondGroupRange = result.range(at: 2)
            let replacedValue = (targetRule as NSString).substring(with: matchRange)
            let componentKey = (targetRule as NSString).substring(with: secondGroupRange)
            let componentValue = componentDict[componentKey] ?? ""
            
            let newValue = convertCaptureGroups(checkingResult: result, targetRule: targetRule, originalValue: componentValue)
            targetURL.replaceOccurrences(of: replacedValue, with: newValue, options: [], range: NSMakeRange(0, targetURL.length))
        })
        return targetURL as String
    }
    
    private class func convertCaptureGroups(checkingResult: NSTextCheckingResult, targetRule: String, originalValue: String) -> String {
        var convertValue = originalValue
        let convertKeyRange = checkingResult.range(at: 1)
        let convertKey = (targetRule as NSString).substring(with: convertKeyRange)
        if convertKey == "$" {
            convertValue = originalValue.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        } else if convertKey == "#" {
            convertValue = originalValue.removingPercentEncoding ?? ""
        }
        return convertValue
    }
    
}
