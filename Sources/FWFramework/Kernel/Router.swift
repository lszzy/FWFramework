//
//  Router.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit

// MARK: - WrapperGlobal
extension WrapperGlobal {
    /// 路由快速访问
    nonisolated(unsafe) public static var router = Router.self
}

// MARK: - Router
/// URL路由器
///
/// 由于Function也是闭包，Handler参数支持静态方法，示例：AppRouter.routePlugin(_:)
/// [MGJRouter](https://github.com/meili/MGJRouter)
/// [FFRouter](https://github.com/imlifengfeng/FFRouter)
@objc(ObjCRouter)
public class Router: NSObject {
    
    // MARK: - Typealias
    /// URL路由上下文
    public class Context: NSObject, @unchecked Sendable {
        
        /// 路由URL
        public private(set) var url: String
        
        /// 路由用户信息
        public private(set) var userInfo: [AnyHashable: Any]
        
        /// 路由完成回调
        public private(set) var completion: Completion?
        
        /// 路由URL解析参数字典
        public fileprivate(set) lazy var urlParameters: [AnyHashable: Any] = {
            var urlParameters: [String: String] = [:]
            if let queryUrl = URL.fw.url(string: url),
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
            parameters.merge(userInfo) { _, last in last }
            parameters.merge(urlParameters) { _, last in last }
            return parameters
        }()
        
        /// 路由是否以openURL方式打开，区别于objectForURL
        public fileprivate(set) var isOpening: Bool = false
        
        /// 创建路由参数对象
        public init(url: String, userInfo: [AnyHashable: Any]? = nil, completion: Completion? = nil) {
            self.url = url
            self.userInfo = userInfo ?? [:]
            self.completion = completion
        }
        
    }
    
    /// 路由处理句柄，仅支持openURL时可返回nil
    public typealias Handler = (Context) -> Any?
    /// 路由完成回调句柄
    public typealias Completion = (Any?) -> Void
    
    /// 路由参数类，可直接使用，也可完全自定义
    open class Parameter: ObjectParameter, @unchecked Sendable {
        
        /// 路由信息来源Key，兼容字典传参，默认未使用
        public static let routerSourceKey = "routerSource"
        /// 路由信息选项Key，兼容字典传参，支持NavigationOptions
        public static let routerOptionsKey = "routerOptions"
        /// 路由动画选项Key，兼容字典传参，仅open生效
        public static let routerAnimatedKey = "routerAnimated"
        /// 路由信息句柄Key，兼容字典传参，仅open生效
        public static let routerHandlerKey = "routerHandler"
        
        /// 路由信息来源，默认未使用
        open var routerSource: String?
        /// 路由信息选项，支持NavigationOptions
        open var routerOptions: NavigatorOptions?
        /// 路由动画选项，仅open生效
        open var routerAnimated: Bool?
        /// 路由信息句柄，仅open生效
        open var routerHandler: (@convention(block) (Context, UIViewController) -> Void)?
        
        public required init() {}
        
        public required init(dictionaryValue: [AnyHashable : Any]) {
            routerSource = dictionaryValue[Self.routerSourceKey].string
            if let options = dictionaryValue[Self.routerOptionsKey] {
                routerOptions = options as? NavigatorOptions ?? NavigatorOptions(rawValue: NSNumber.fw.safeNumber(options).intValue)
            }
            routerAnimated = dictionaryValue[Self.routerAnimatedKey].bool
            routerHandler = dictionaryValue[Self.routerHandlerKey] as? @convention(block) (Context, UIViewController) -> Void
        }
        
        public var dictionaryValue: [AnyHashable: Any] {
            var dictionary: [AnyHashable: Any] = [:]
            dictionary[Self.routerSourceKey] = routerSource
            dictionary[Self.routerOptionsKey] = routerOptions
            dictionary[Self.routerAnimatedKey] = routerAnimated
            dictionary[Self.routerHandlerKey] = routerHandler
            return dictionary
        }
    }
    
    // MARK: - Accessor
    /// 路由类加载器，访问未注册路由时会尝试调用并注册，block返回值为register方法class参数
    nonisolated(unsafe) public static let sharedLoader = Loader<String, Any>()
    
    /// 是否开启严格模式，开启后不会以上一层为fallback，默认false
    nonisolated(unsafe) public static var strictMode = false
    
    /// 路由规则，结构类似 ["beauty": [":id": [routerCoreKey: block]]]
    nonisolated(unsafe) private static var routeRules = NSMutableDictionary()
    
    private static let routeWildcardCharacter = "*"
    private static let routeParameterCharacter = ":"
    private static let routeSpecialCharacters = "/?&."
    private static let routeCoreKey = "FWRouterCore"
    private static let routeBlockKey = "FWRouterBlock"
    
    // MARK: - Public
    /// 注册路由类或对象，批量注册路由规则
    /// - Parameters:
    ///   - clazz: 路由类或对象，不遍历父类
    ///   - mapper: 自定义映射，默认nil时查找规则：xxxUrl => xxxRouter: > xxxDefaultRouter:
    /// - Returns: 是否注册成功
    @discardableResult
    public class func registerClass(_ clazz: Any, mapper: (([String]) -> [String: String])? = nil) -> Bool {
        return registerClass(with: clazz, isPreset: false, mapper: mapper)
    }
    
    /// 预置路由类或对象，批量注册路由规则，仅当路由未被注册时生效
    /// - Parameters:
    ///   - clazz: 路由类或对象，不遍历父类
    ///   - mapper: 自定义映射，默认nil时查找规则：xxxUrl => xxxRouter: > xxxDefaultRouter:
    /// - Returns: 是否注册成功
    @discardableResult
    public class func presetClass(_ clazz: Any, mapper: (([String]) -> [String: String])? = nil) -> Bool {
        return registerClass(with: clazz, isPreset: true, mapper: mapper)
    }
    
    /// 取消注册某个路由类或对象
    /// - Parameters:
    ///   - clazz: 路由类或对象，不遍历父类
    ///   - mapper: 自定义映射，默认nil时查找规则：xxxUrl => xxxRouter: > xxxDefaultRouter:
    public class func unregisterClass(_ clazz: Any, mapper: (([String]) -> [String: String])? = nil) {
        let routes = routeClass(with: clazz, mapper: mapper)
        if let targetClass = clazz as? NSObject.Type {
            for (key, _) in routes {
                guard let pattern = targetClass.perform(NSSelectorFromString(key))?.takeUnretainedValue() else { continue }
                unregisterURL(with: pattern)
            }
        } else if let targetObject = clazz as? NSObject {
            for (key, _) in routes {
                guard let pattern = targetObject.perform(NSSelectorFromString(key))?.takeUnretainedValue() else { continue }
                unregisterURL(with: pattern)
            }
        }
    }
    
    /// 注册 pattern 对应的 Handler，可返回一个 object 给调用方，也可直接触发事件返回nil
    /// - Parameters:
    ///   - pattern: 字符串，带上 scheme，如 app://beauty/:id
    ///   - handler: 路由处理句柄，参数为路由上下文对象
    /// - Returns: 是否注册成功
    @discardableResult
    public class func registerURL(_ pattern: StringParameter, handler: @escaping Handler) -> Bool {
        return registerURL(with: pattern.stringValue, handler: handler, isPreset: false)
    }
    
    /// 注册 patterns 对应的 Handler，可返回一个 object 给调用方，也可直接触发事件返回nil
    /// - Parameters:
    ///   - patterns: 字符串数组，带上 scheme，如 app://beauty/:id
    ///   - handler: 路由处理句柄，参数为路由上下文对象
    /// - Returns: 是否注册成功
    @discardableResult
    public class func registerURL(_ patterns: [StringParameter], handler: @escaping Handler) -> Bool {
        let urls = patterns.map({ $0.stringValue })
        return registerURL(with: urls, handler: handler, isPreset: false)
    }
    
    /// 预置 pattern 对应的 Handler，可返回一个 object 给调用方，也可直接触发事件返回nil，仅当路由未被注册时生效
    /// - Parameters:
    ///   - pattern: 字符串，带上 scheme，如 app://beauty/:id
    ///   - handler: 路由处理句柄，参数为路由上下文对象
    /// - Returns: 是否注册成功
    public class func presetURL(_ pattern: StringParameter, handler: @escaping Handler) -> Bool {
        return registerURL(with: pattern.stringValue, handler: handler, isPreset: true)
    }
    
    /// 预置 patterns 对应的 Handler，可返回一个 object 给调用方，也可直接触发事件返回nil，仅当路由未被注册时生效
    /// - Parameters:
    ///   - patterns: 字符串数组，带上 scheme，如 app://beauty/:id
    ///   - handler: 路由处理句柄，参数为路由上下文对象
    /// - Returns: 是否注册成功
    public class func presetURL(_ patterns: [StringParameter], handler: @escaping Handler) -> Bool {
        let urls = patterns.map({ $0.stringValue })
        return registerURL(with: urls, handler: handler, isPreset: true)
    }
    
    /// 取消注册某个 pattern
    /// - Parameter pattern: 字符串或字符串数组
    public class func unregisterURL(_ pattern: StringParameter) {
        unregisterURL(with: pattern.stringValue)
    }
    
    /// 批量取消注册 patterns
    /// - Parameter patterns: 字符串数组
    public class func unregisterURL(_ patterns: [StringParameter]) {
        let urls = patterns.map({ $0.stringValue })
        unregisterURL(with: urls)
    }
    
    /// 取消注册所有 pattern
    public class func unregisterAllURLs() {
        routeRules.removeAllObjects()
    }
    
    /// 设置全局路由过滤器，URL 被访问时优先触发。如果返回true，继续解析pattern，否则停止解析
    nonisolated(unsafe) public static var routeFilter: ((Context) -> Bool)?
    
    /// 设置全局路由处理器，URL 被访问且有返回值时触发，可用于打开VC、附加设置等
    nonisolated(unsafe) public static var routeHandler: ((Context, Any) -> Any?)?
    
    /// 设置全局错误句柄，URL 未注册时触发，可用于错误提示、更新提示等
    nonisolated(unsafe) public static var errorHandler: ((Context) -> Void)?
    
    /// 预置全局默认路由处理器，仅当未设置routeHandler时生效，值为nil时默认打开VC
    /// - Parameter handler: 路由处理器
    public class func presetRouteHandler(_ handler: ((Context, Any) -> Any?)? = nil) {
        if routeHandler != nil { return }
        
        routeHandler = handler ?? { context, object in
            guard context.isOpening else { return object }
            guard let viewController = object as? UIViewController else { return object }
            
            // 解析默认路由参数userInfo
            let userInfo = Parameter(dictionaryValue: context.userInfo)
            if let routerHandler = userInfo.routerHandler {
                routerHandler(context, viewController)
            } else {
                DispatchQueue.fw.mainAsync {
                    UIWindow.fw.main?.fw.open(viewController, animated: userInfo.routerAnimated ?? true, options: userInfo.routerOptions ?? [], completion: nil)
                }
            }
            return nil
        }
    }
    
    /// 是否可以打开URL，不含object
    /// - Parameter url: URL 带 Scheme，如 app://beauty/3
    /// - Returns: 是否可以打开
    public class func canOpenURL(_ url: StringParameter?) -> Bool {
        let rewriteURL = rewriteURL(url)
        guard !rewriteURL.isEmpty else { return false }
        
        let URLParameters = routeParameters(from: rewriteURL)
        return URLParameters[routeBlockKey] != nil
    }
    
    /// 打开此 URL，带上附加信息，同时当操作完成时，执行额外的代码
    /// - Parameters:
    ///   - url: 带 Scheme 的 URL，如 app://beauty/4
    ///   - userInfo: 附加信息
    ///   - completion: URL 处理完成后的 callback，完成的判定跟具体的业务相关
    public class func openURL(_ url: StringParameter?, userInfo: [AnyHashable: Any]? = nil, completion: Completion? = nil) {
        let rewriteURL = rewriteURL(url)
        guard !rewriteURL.isEmpty else { return }
        
        let urlParameters = routeParameters(from: rewriteURL)
        let handler = urlParameters[routeBlockKey] as? Handler
        urlParameters.removeObject(forKey: routeBlockKey)
        
        let context = Context(url: rewriteURL, userInfo: userInfo, completion: completion)
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
    
    /// 快速调用Handler参数中的回调句柄，指定回调结果
    /// - Parameters:
    ///   - context: Handler中的模型参数
    ///   - result: URL处理完成后的回调结果
    public class func completeURL(_ context: Context, result: Any?) {
        context.completion?(result)
    }
    
    /// 查找谁对某个 URL 感兴趣，如果有的话，返回一个 object；如果没有，返回nil
    /// - Parameters:
    ///   - url: URL 带 Scheme，如 app://beauty/3
    ///   - userInfo: 附加信息
    /// - Returns: URL返回的对象
    public class func object(forURL url: StringParameter?, userInfo: [AnyHashable: Any]? = nil) -> Any? {
        let rewriteURL = rewriteURL(url)
        guard !rewriteURL.isEmpty else { return nil }
        
        let urlParameters = routeParameters(from: rewriteURL)
        let handler = urlParameters[routeBlockKey] as? Handler
        urlParameters.removeObject(forKey: routeBlockKey)
        
        let context = Context(url: rewriteURL, userInfo: userInfo, completion: nil)
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
            if character == routeParameterCharacter || character == routeWildcardCharacter {
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
                    let value = paramArray[idx]
                    parsedResult = parsedResult.replacingOccurrences(of: placeholders[idx], with: String.fw.safeString(value))
                }
            }
        } else if let paramDict = parameters as? [AnyHashable: Any] {
            for idx in 0 ..< placeholders.count {
                let value = paramDict[placeholders[idx].replacingOccurrences(of: routeParameterCharacter, with: "").replacingOccurrences(of: routeWildcardCharacter, with: "")]
                if let value = value {
                    parsedResult = parsedResult.replacingOccurrences(of: placeholders[idx], with: String.fw.safeString(value))
                }
            }
        } else if let parameters = parameters {
            for placeholder in placeholders {
                parsedResult = parsedResult.replacingOccurrences(of: placeholder, with: String.fw.safeString(parameters))
            }
        }
        return parsedResult
    }
    
    // MARK: - Private
    private class func registerClass(with clazz: Any, isPreset: Bool, mapper: (([String]) -> [String: String])?) -> Bool {
        var result = true
        let routes = routeClass(with: clazz, mapper: mapper)
        if let targetClass = clazz as? NSObject.Type {
            for (key, obj) in routes {
                guard let pattern = targetClass.perform(NSSelectorFromString(key))?.takeUnretainedValue() else { continue }
                result = registerURL(with: pattern, handler: { context in
                    return targetClass.perform(NSSelectorFromString(obj), with: context)?.takeUnretainedValue()
                }, isPreset: isPreset) && result
            }
        } else if let targetObject = clazz as? NSObject {
            for (key, obj) in routes {
                guard let pattern = targetObject.perform(NSSelectorFromString(key))?.takeUnretainedValue() else { continue }
                result = registerURL(with: pattern, handler: { context in
                    return targetObject.perform(NSSelectorFromString(obj), with: context)?.takeUnretainedValue()
                }, isPreset: isPreset) && result
            }
        }
        return result
    }
    
    private class func routeClass(with clazz: Any, mapper: (([String]) -> [String: String])?) -> [String: String] {
        guard let metaClass = NSObject.fw.metaClass(clazz) else {
            return [:]
        }
        
        let methods = NSObject.fw.classMethods(metaClass)
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
    
    private class func registerURL(with pattern: Any, handler: @escaping Handler, isPreset: Bool) -> Bool {
        if let patterns = pattern as? [Any] {
            var result = true
            for subPattern in patterns {
                result = registerURL(with: subPattern, handler: handler, isPreset: isPreset) && result
            }
            return result
        }
        
        guard let pattern = pattern as? String, !pattern.isEmpty else { return false }
        
        let subRoutes = registerRoute(with: pattern)
        if isPreset && subRoutes[routeCoreKey] != nil { return false }
        
        subRoutes[routeCoreKey] = handler
        return true
    }
    
    private class func unregisterURL(with pattern: Any) {
        if let patterns = pattern as? [Any] {
            for subPattern in patterns {
                unregisterURL(with: subPattern)
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
    
    private class func registerRoute(with pattern: String) -> NSMutableDictionary {
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
        let fullUrl = URL.fw.url(string: url)
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
        
        let pathUrl = URL.fw.url(string: formatUrl)
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
        var wildcardRoutes = false
        for (index, pathComponent) in pathComponents.enumerated() {
            // 对 key 进行排序，这样可以把 * 放到最后
            let subRoutesKeys = subRoutes.allKeys.compactMap { key in
                return key as? String
            }.sorted { key1, key2 in
                return key2.caseInsensitiveCompare(key1) == .orderedAscending
            }
            
            for key in subRoutesKeys {
                if key == pathComponent || key.hasPrefix(routeWildcardCharacter) {
                    wildcardMatched = true
                    wildcardRoutes = key.hasPrefix(routeWildcardCharacter)
                    subRoutes = subRoutes[key] as? NSMutableDictionary ?? NSMutableDictionary()
                    
                    if wildcardRoutes && key.count > 1 {
                        var newKey = (key as NSString).substring(from: 1)
                        var newPathComponent = pathComponent
                        if index < pathComponents.count - 1 {
                            newPathComponent = pathComponents.suffix(from: index).joined(separator: "/")
                        }
                        // 再做一下特殊处理，比如 *id.html -> :id
                        let specialCharactersSet = CharacterSet(charactersIn: routeSpecialCharacters)
                        let range = (key as NSString).rangeOfCharacter(from: specialCharactersSet)
                        if range.location != NSNotFound {
                            // 把 pathComponent 后面的部分也去掉
                            newKey = (newKey as NSString).substring(to: range.location - 1)
                            let suffixToStrip = (key as NSString).substring(from: range.location)
                            newPathComponent = newPathComponent.replacingOccurrences(of: suffixToStrip, with: "")
                        }
                        parameters[newKey] = newPathComponent.removingPercentEncoding
                    }
                    break
                } else if key.hasPrefix(routeParameterCharacter) {
                    wildcardMatched = true
                    wildcardRoutes = false
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
            
            // 如果没有找到该 pathComponent 对应的 handler，未开启精准匹配时以上一层的 handler 作为 fallback，否则查找结束
            if !wildcardMatched {
                if strictMode {
                    if !wildcardRoutes { subRoutes = NSMutableDictionary() }
                    break
                } else {
                    if subRoutes[routeCoreKey] == nil { break }
                }
            }
        }
        
        if let nsurl = URL.fw.url(string: url),
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

// MARK: - Router+Extension
extension Router {
    
    nonisolated(unsafe) private static var rewriteRules = [String: String]()
    
    /// 全局重写过滤器
    nonisolated(unsafe) public static var rewriteFilter: ((String) -> String)?
    
    /// 根据重写规则，重写URL
    /// - Parameter url: 需要重写的url
    /// - Returns: 重写之后的url
    public class func rewriteURL(_ url: StringParameter?) -> String {
        var rewriteURL = url?.stringValue ?? ""
        if let rewriteFilter = rewriteFilter {
            rewriteURL = rewriteFilter(rewriteURL)
        }
        guard !rewriteURL.isEmpty, rewriteRules.count > 0 else { return rewriteURL }
        
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
