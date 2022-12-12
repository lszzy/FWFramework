//
//  Foundation.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit
#if FWMacroSPM
import FWObjC
#endif

// MARK: - Data+Foundation
extension Wrapper where Base == Data {
    /// 使用NSKeyedArchiver压缩对象
    public static func archiveObject(_ object: Any) -> Data? {
        return Base.fw_archiveObject(object)
    }
    
    /// 使用NSKeyedUnarchiver解压数据
    public func unarchiveObject<T>(_ clazz: T.Type) -> T? where T : NSObject, T : NSCoding {
        return base.fw_unarchiveObject(clazz)
    }
    
    /// 保存对象归档
    public static func archiveObject(_ object: Any, file: String) -> Bool {
        return Base.fw_archiveObject(object, file: file)
    }
    
    /// 读取对象归档
    public static func unarchiveObject<T>(_ clazz: T.Type, file: String) -> T? where T : NSObject, T : NSCoding {
        return Base.fw_unarchiveObject(clazz, file: file)
    }
    
    // MARK: - Encrypt
    /// 利用AES加密数据
    public func aesEncrypt(key: String, iv: Data) -> Data? {
        return base.fw_aesEncrypt(key: key, iv: iv)
    }

    /// 利用AES解密数据
    public func aesDecrypt(key: String, iv: Data) -> Data? {
        return base.fw_aesDecrypt(key: key, iv: iv)
    }

    /// 利用3DES加密数据
    public func des3Encrypt(key: String, iv: Data) -> Data? {
        return base.fw_des3Encrypt(key: key, iv: iv)
    }

    /// 利用3DES解密数据
    public func des3Decrypt(key: String, iv: Data) -> Data? {
        return base.fw_des3Decrypt(key: key, iv: iv)
    }

    // MARK: - RSA
    /// RSA公钥加密，数据传输安全，使用默认标签，执行base64编码
    public func rsaEncrypt(publicKey: String) -> Data? {
        return base.fw_rsaEncrypt(publicKey: publicKey)
    }

    /// RSA公钥加密，数据传输安全，可自定义标签，指定base64编码
    public func rsaEncrypt(publicKey: String, tag: String, base64Encode: Bool) -> Data? {
        return base.fw_rsaEncrypt(publicKey: publicKey, tag: tag, base64Encode: base64Encode)
    }

    /// RSA私钥解密，数据传输安全，使用默认标签，执行base64解密
    public func rsaDecrypt(privateKey: String) -> Data? {
        return base.fw_rsaDecrypt(privateKey: privateKey)
    }

    /// RSA私钥解密，数据传输安全，可自定义标签，指定base64解码
    public func rsaDecrypt(privateKey: String, tag: String, base64Decode: Bool) -> Data? {
        return base.fw_rsaDecrypt(privateKey: privateKey, tag: tag, base64Decode: base64Decode)
    }

    /// RSA私钥加签，防篡改防否认，使用默认标签，执行base64编码
    public func rsaSign(privateKey: String) -> Data? {
        return base.fw_rsaSign(privateKey: privateKey)
    }

    /// RSA私钥加签，防篡改防否认，可自定义标签，指定base64编码
    public func rsaSign(privateKey: String, tag: String, base64Encode: Bool) -> Data? {
        return base.fw_rsaSign(privateKey: privateKey, tag: tag, base64Encode: base64Encode)
    }

    /// RSA公钥验签，防篡改防否认，使用默认标签，执行base64解密
    public func rsaVerify(publicKey: String) -> Data? {
        return base.fw_rsaVerify(publicKey: publicKey)
    }

    /// RSA公钥验签，防篡改防否认，可自定义标签，指定base64解码
    public func rsaVerify(publicKey: String, tag: String, base64Decode: Bool) -> Data? {
        return base.fw_rsaVerify(publicKey: publicKey, tag: tag, base64Decode: base64Decode)
    }
}

// MARK: - Date+Foundation
extension Wrapper where Base == Date {
    /// 当前时间戳，没有设置过返回本地时间戳，可同步设置服务器时间戳，同步后调整手机时间不影响
    public static var currentTime: TimeInterval {
        get { Base.fw_currentTime }
        set { Base.fw_currentTime = newValue }
    }
    
    /// 从字符串初始化日期，自定义格式(默认yyyy-MM-dd HH:mm:ss)和时区(默认当前时区)
    public static func date(string: String, format: String = "yyyy-MM-dd HH:mm:ss", timeZone: TimeZone? = nil) -> Date? {
        return Base.fw_date(string: string, format: format, timeZone: timeZone)
    }
    
    /// 转化为字符串，默认当前时区，格式：yyyy-MM-dd HH:mm:ss
    public var stringValue: String {
        return base.fw_stringValue
    }
    
    /// 转化为字符串，自定义格式和时区
    public func string(format: String, timeZone: TimeZone? = nil) -> String {
        return base.fw_string(format: format, timeZone: timeZone)
    }
    
    /// 格式化时长，格式"00:00"或"00:00:00"
    public static func formatDuration(_ duration: TimeInterval, hasHour: Bool) -> String {
        return Base.fw_formatDuration(duration, hasHour: hasHour)
    }
    
    /// 格式化16位、13位时间戳为10位(秒)
    public static func formatTimestamp(_ timestamp: TimeInterval) -> TimeInterval {
        return Base.fw_formatTimestamp(timestamp)
    }
    
    /// 是否是闰年
    public var isLeapYear: Bool {
        return base.fw_isLeapYear
    }

    /// 是否是同一天
    public func isSameDay(_ date: Date) -> Bool {
        return base.fw_isSameDay(date)
    }

    /// 添加指定日期，如year:1|month:-1|day:1等
    public func date(byAdding: DateComponents) -> Date? {
        return base.fw_date(byAdding: byAdding)
    }

    /// 与指定日期相隔天数
    public func days(from date: Date) -> Int {
        return base.fw_days(from: date)
    }
}

// MARK: - NSNumber+Foundation
extension Wrapper where Base: NSNumber {

    /// 四舍五入，去掉末尾0，最多digit位，小数分隔符为.，分组分隔符为空，示例：12345.6789 => 12345.68
    public func roundString(_ digit: Int) -> String {
        return base.fw_roundString(digit)
    }

    /// 取上整，去掉末尾0，最多digit位，小数分隔符为.，分组分隔符为空，示例：12345.6789 => 12345.68
    public func ceilString(_ digit: Int) -> String {
        return base.fw_ceilString(digit)
    }

    /// 取下整，去掉末尾0，最多digit位，小数分隔符为.，分组分隔符为空，示例：12345.6789 => 12345.67
    public func floorString(_ digit: Int) -> String {
        return base.fw_floorString(digit)
    }

    /// 四舍五入，去掉末尾0，最多digit位，示例：12345.6789 => 12345.68
    public func roundNumber(_ digit: Int) -> NSNumber {
        return base.fw_roundNumber(digit)
    }

    /// 取上整，去掉末尾0，最多digit位，示例：12345.6789 => 12345.68
    public func ceilNumber(_ digit: Int) -> NSNumber {
        return base.fw_ceilNumber(digit)
    }

    /// 取下整，去掉末尾0，最多digit位，示例：12345.6789 => 12345.67
    public func floorNumber(_ digit: Int) -> NSNumber {
        return base.fw_floorNumber(digit)
    }
    
}

// MARK: - String+Foundation
extension Wrapper where Base == String {
    /// 计算多行字符串指定字体、指定属性在指定绘制区域内所占尺寸
    public func size(font: UIFont, drawSize: CGSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude), attributes: [NSAttributedString.Key: Any]? = nil) -> CGSize {
        return base.fw_size(font: font, drawSize: drawSize, attributes: attributes)
    }
    
    /// 格式化文件大小为".0K/.1M/.1G"
    public static func sizeString(_ aFileSize: UInt) -> String {
        return Base.fw_sizeString(aFileSize)
    }
    
    /// 是否匹配正则表达式，示例：^[a-zA-Z0-9_\u4e00-\u9fa5]{4,14}$
    public func matchesRegex(_ regex: String) -> Bool {
        return base.fw_matchesRegex(regex)
    }
    
    /**
     *  安全截取字符串。解决末尾半个Emoji问题(半个Emoji调UTF8String为NULL，导致MD5签名等失败)
     *
     *  @param index 目标索引
     */
    public func emojiSubstring(_ index: Int) -> String {
        return base.fw_emojiSubstring(index)
    }

    /**
     *  正则搜索子串
     *
     *  @param regex 正则表达式
     */
    public func regexSubstring(_ regex: String) -> String? {
        return base.fw_regexSubstring(regex)
    }

    /**
     *  正则替换字符串
     *
     *  @param regex  正则表达式
     *  @param string 替换模板，如"头部$1中部$2尾部"
     *
     *  @return 替换后的字符串
     */
    public func regexReplace(_ regex: String, string: String) -> String {
        return base.fw_regexReplace(regex, string: string)
    }

    /**
     *  正则匹配回调
     *
     *  @param regex 正则表达式
     *  @param block 回调句柄。range从大至小，方便replace
     */
    public func regexMatches(_ regex: String, block: @escaping (NSRange) -> Void) {
        return base.fw_regexMatches(regex, block: block)
    }
    
    /// 转义Html，如"a<"转义为"a&lt;"
    public var escapeHtml: String {
        return base.fw_escapeHtml
    }
    
    /**
     *  是否符合正则表达式
     *  示例：用户名：^[a-zA-Z][a-zA-Z0-9_]{4,13}$
     *       密码：^[a-zA-Z0-9_]{6,20}$
     *       昵称：^[a-zA-Z0-9_\u4e00-\u9fa5]{4,14}$
     *
     *  @param regex 正则表达式
     */
    public func isFormatRegex(_ regex: String) -> Bool {
        return base.fw_isFormatRegex(regex)
    }

    /// 是否是手机号
    public var isFormatMobile: Bool {
        return base.fw_isFormatMobile
    }

    /// 是否是座机号
    public var isFormatTelephone: Bool {
        return base.fw_isFormatTelephone
    }
    
    /// 是否是整数
    public var isFormatInteger: Bool {
        return base.fw_isFormatInteger
    }
    
    /// 是否是数字
    public var isFormatNumber: Bool {
        return base.fw_isFormatNumber
    }
    
    /// 是否是合法金额，两位小数点
    public var isFormatMoney: Bool {
        return base.fw_isFormatMoney
    }
    
    /// 是否是身份证号
    public var isFormatIdcard: Bool {
        return base.fw_isFormatIdcard
    }
    
    /// 是否是银行卡号
    public var isFormatBankcard: Bool {
        return base.fw_isFormatBankcard
    }
    
    /// 是否是车牌号
    public var isFormatCarno: Bool {
        return base.fw_isFormatCarno
    }
    
    /// 是否是邮政编码
    public var isFormatPostcode: Bool {
        return base.fw_isFormatPostcode
    }
    
    /// 是否是邮箱
    public var isFormatEmail: Bool {
        return base.fw_isFormatEmail
    }
    
    /// 是否是URL
    public var isFormatUrl: Bool {
        return base.fw_isFormatUrl
    }
    
    /// 是否是HTML
    public var isFormatHtml: Bool {
        return base.fw_isFormatHtml
    }
    
    /// 是否是IP
    public var isFormatIp: Bool {
        return base.fw_isFormatIp
    }
    
    /// 是否全是中文
    public var isFormatChinese: Bool {
        return base.fw_isFormatChinese
    }
    
    /// 是否是合法时间，格式：yyyy-MM-dd HH:mm:ss
    public var isFormatDatetime: Bool {
        return base.fw_isFormatDatetime
    }
    
    /// 是否是合法时间戳，格式：1301234567
    public var isFormatTimestamp: Bool {
        return base.fw_isFormatTimestamp
    }
    
    /// 是否是坐标点字符串，格式：latitude,longitude
    public var isFormatCoordinate: Bool {
        return base.fw_isFormatCoordinate
    }
    
}

// MARK: - FileManager+Foundation
extension Wrapper where Base: FileManager {
    
    /// 搜索路径
    ///
    /// - Parameter directory: 搜索目录
    /// - Returns: 目标路径
    public static func pathSearch(_ directory: FileManager.SearchPathDirectory) -> String {
        return Base.fw_pathSearch(directory)
    }

    /// 沙盒路径，常量
    public static var pathHome: String {
        return Base.fw_pathHome
    }

    /// 文档路径，iTunes会同步备份
    public static var pathDocument: String {
        return Base.fw_pathDocument
    }

    /// 缓存路径，系统不会删除，iTunes会删除
    public static var pathCaches: String {
        return Base.fw_pathCaches
    }

    /// Library路径
    public static var pathLibrary: String {
        return Base.fw_pathLibrary
    }

    /// 配置路径，配置文件保存位置
    public static var pathPreference: String {
        return Base.fw_pathPreference
    }

    /// 临时路径，App退出后可能会删除
    public static var pathTmp: String {
        return Base.fw_pathTmp
    }

    /// bundle路径，不可写
    public static var pathBundle: String {
        return Base.fw_pathBundle
    }

    /// 资源路径，不可写
    public static var pathResource: String {
        return Base.fw_pathResource
    }

    /// 获取目录大小，单位：B
    public static func folderSize(_ folderPath: String) -> UInt64 {
        return Base.fw_folderSize(folderPath)
    }
    
}

// MARK: - NSAttributedString+Foundation
/// 如果需要实现行内图片可点击效果，可使用UITextView添加附件或Link并实现delegate.shouldInteractWith方法即可。
/// 注意iOS在后台运行时，如果调用NSAttributedString解析html会导致崩溃(如动态切换深色模式时在后台解析html)。解决方法是提前在前台解析好或者后台异步到下一个主线程RunLoop
extension Wrapper where Base: NSAttributedString {
    
    /// NSAttributedString对象转换为html字符串
    public func htmlString() -> String? {
        return base.fw_htmlString()
    }

    /// 计算所占尺寸，需设置Font等
    public var textSize: CGSize {
        return base.fw_textSize
    }

    /// 计算在指定绘制区域内所占尺寸，需设置Font等
    public func textSize(drawSize: CGSize) -> CGSize {
        return base.fw_textSize(drawSize: drawSize)
    }
    
    /// html字符串转换为NSAttributedString对象。如需设置默认字体和颜色，请使用addAttributes方法或附加CSS样式
    public static func attributedString(htmlString: String) -> Base? {
        return Base.fw_attributedString(htmlString: htmlString)
    }

    /// 图片转换为NSAttributedString对象，可实现行内图片样式。其中bounds.x会设置为间距，y常用算法：(font.capHeight - image.size.height) / 2.0
    public static func attributedString(image: UIImage?, bounds: CGRect) -> NSAttributedString {
        return Base.fw_attributedString(image: image, bounds: bounds)
    }
    
    /// 快速创建NSAttributedString并指定高亮部分文字和样式，链接设置NSLinkAttributeName|URL属性即可
    public static func attributedString(string: String, attributes: [NSAttributedString.Key : Any]?, highlight: String, highlightAttributes: [NSAttributedString.Key : Any]?) -> NSAttributedString {
        return Base.fw_attributedString(string: string, attributes: attributes, highlight: highlight, highlightAttributes: highlightAttributes)
    }
    
    /// 快速创建NSAttributedString，自定义字体和颜色
    public static func attributedString(_ string: String, font: UIFont?, textColor: UIColor? = nil) -> Base {
        return Base.fw_attributedString(string, font: font, textColor: textColor)
    }
    
    /// html字符串转换为NSAttributedString对象，可设置默认系统字体和颜色(附加CSS方式)
    public static func attributedString(htmlString: String, defaultAttributes: [NSAttributedString.Key: Any]?) -> Base? {
        return Base.fw_attributedString(htmlString: htmlString, defaultAttributes: defaultAttributes)
    }

    /// html字符串转换为NSAttributedString主题对象，可设置默认系统字体和动态颜色，详见FWThemeObject
    public static func themeObject(htmlString: String, defaultAttributes: [NSAttributedString.Key: Any]?) -> ThemeObject<NSAttributedString> {
        return Base.fw_themeObject(htmlString: htmlString, defaultAttributes: defaultAttributes)
    }

    /// 获取颜色对应CSS字符串(rgb|rgba格式)
    public static func cssString(color: UIColor) -> String {
        return Base.fw_cssString(color: color)
    }

    /// 获取系统字体对应CSS字符串(family|style|weight|size)
    public static func cssString(font: UIFont) -> String {
        return Base.fw_cssString(font: font)
    }
    
}

// MARK: - NSObject+Foundation
extension Wrapper where Base: NSObject {
    
    /// 执行加锁(支持任意对象)，等待信号量，自动创建信号量
    public func lock() {
        base.fw_lock()
    }

    /// 执行解锁(支持任意对象)，发送信号量，自动创建信号量
    public func unlock() {
        base.fw_unlock()
    }
    
    /// 通用互斥锁方法
    public static func synchronized(_ closure: () -> Void) {
        Base.fw_synchronized(closure)
    }
    
    /// 通用互斥锁方法
    public func synchronized(_ closure: () -> Void) {
        base.fw_synchronized(closure)
    }
    
    /// 同一个token仅执行一次block，全局范围
    public static func dispatchOnce(
        _ token: String,
        closure: @escaping () -> Void
    ) {
        Base.fw_dispatchOnce(token, closure: closure)
    }
    
    /// 同一个token仅执行一次block，对象范围
    public func dispatchOnce(
        _ token: String,
        closure: @escaping () -> Void
    ) {
        base.fw_dispatchOnce(token, closure: closure)
    }
    
    /// 延迟delay秒后主线程执行，返回可取消的block，对象范围
    @discardableResult
    public func performBlock(
        _ block: @escaping (Any) -> Void,
        afterDelay delay: TimeInterval
    ) -> Any {
        return base.fw_performBlock(block, afterDelay: delay)
    }

    /// 延迟delay秒后后台线程执行，返回可取消的block，对象范围
    @discardableResult
    public func performBlock(
        inBackground block: @escaping (Any) -> Void,
        afterDelay delay: TimeInterval
    ) -> Any {
        return base.fw_performBlock(inBackground: block, afterDelay: delay)
    }

    /// 延迟delay秒后指定线程执行，返回可取消的block，对象范围
    @discardableResult
    public func performBlock(
        _ block: @escaping (Any) -> Void,
        on: DispatchQueue,
        afterDelay delay: TimeInterval
    ) -> Any {
        return base.fw_performBlock(block, on: on, afterDelay: delay)
    }
    
    /// 延迟delay秒后主线程执行，返回可取消的block，全局范围
    @discardableResult
    public static func performBlock(
        _ block: @escaping () -> Void,
        afterDelay delay: TimeInterval
    ) -> Any {
        return Base.fw_performBlock(block, afterDelay: delay)
    }

    /// 延迟delay秒后后台线程执行，返回可取消的block，全局范围
    @discardableResult
    public static func performBlock(
        inBackground block: @escaping () -> Void,
        afterDelay delay: TimeInterval
    ) -> Any {
        return Base.fw_performBlock(inBackground: block, afterDelay: delay)
    }

    /// 延迟delay秒后指定线程执行，返回可取消的block，全局范围
    @discardableResult
    public static func performBlock(
        _ block: @escaping () -> Void,
        on: DispatchQueue,
        afterDelay delay: TimeInterval
    ) -> Any {
        return Base.fw_performBlock(block, on: on, afterDelay: delay)
    }

    /// 取消指定延迟block，全局范围
    public static func cancelBlock(_ block: Any) {
        Base.fw_cancelBlock(block)
    }

    /// 同步方式执行异步block，阻塞当前线程(信号量)，异步block必须调用completionHandler，全局范围
    public static func syncPerform(
        asyncBlock: @escaping (@escaping () -> Void) -> Void
    ) {
        Base.fw_syncPerform(asyncBlock: asyncBlock)
    }

    /// 重试方式执行异步block，直至成功或者次数为0或者超时，完成后回调completion。block必须调用completionHandler，参数示例：重试4次|超时8秒|延迟2秒
    public static func performBlock(
        _ block: @escaping (@escaping (Bool, Any?) -> Void) -> Void,
        completion: @escaping (Bool, Any?) -> Void,
        retryCount: Int,
        timeoutInterval: TimeInterval,
        delayInterval: TimeInterval
    ) {
        Base.fw_performBlock(block, completion: completion, retryCount: retryCount, timeoutInterval: timeoutInterval, delayInterval: delayInterval)
    }

    /// 执行轮询block任务，返回任务Id可取消
    @discardableResult
    public static func performTask(_ task: @escaping () -> Void, start: TimeInterval, interval: TimeInterval, repeats: Bool, async: Bool) -> String {
        return Base.fw_performTask(task, start: start, interval: interval, repeats: repeats, async: async)
    }

    /// 指定任务Id取消轮询任务
    public static func cancelTask(_ taskId: String) {
        Base.fw_cancelTask(taskId)
    }
    
}

// MARK: - URL+Foundation
/// 第三方URL生成器，可先判断canOpenURL，再openURL，需添加对应URL SCHEME到LSApplicationQueriesSchemes配置数组
extension Wrapper where Base == URL {

    /**
     生成苹果地图地址外部URL
     
     @param addr 显示地址，格式latitude,longitude或搜索地址
     @param options 可选附加参数，如@{@"ll": @"latitude,longitude", @"z": @"14"}
     @return NSURL
     */
    public static func appleMapsURL(withAddr addr: String?, options: [AnyHashable : Any]? = nil) -> URL? {
        return Base.fw_appleMapsURL(withAddr: addr, options: options)
    }

    /**
     生成苹果地图导航外部URL
     
     @param saddr 导航起始点，格式latitude,longitude或搜索地址
     @param daddr 导航结束点，格式latitude,longitude或搜索地址
     @param options 可选附加参数，如@{@"ll": @"latitude,longitude", @"z": @"14"}
     @return NSURL
     */
    public static func appleMapsURL(withSaddr saddr: String?, daddr: String?, options: [AnyHashable : Any]? = nil) -> URL? {
        return Base.fw_appleMapsURL(withSaddr: saddr, daddr: daddr, options: options)
    }

    /**
     生成谷歌地图外部URL，URL SCHEME为：comgooglemaps
     
     @param addr 显示地址，格式latitude,longitude或搜索地址
     @param options 可选附加参数，如@{@"center": @"latitude,longitude", @"zoom": @"14"}
     @return NSURL
     */
    public static func googleMapsURL(withAddr addr: String?, options: [AnyHashable : Any]? = nil) -> URL? {
        return Base.fw_googleMapsURL(withAddr: addr, options: options)
    }

    /**
     生成谷歌地图导航外部URL，URL SCHEME为：comgooglemaps
     
     @param saddr 导航起始点，格式latitude,longitude或搜索地址
     @param daddr 导航结束点，格式latitude,longitude或搜索地址
     @param mode 导航模式，支持driving|transit|bicycling|walking，默认driving
     @param options 可选附加参数，如@{@"center": @"latitude,longitude", @"zoom": @"14", @"dirflg": @"t,h"}
     @return NSURL
     */
    public static func googleMapsURL(withSaddr saddr: String?, daddr: String?, mode: String? = nil, options: [AnyHashable : Any]? = nil) -> URL? {
        return Base.fw_googleMapsURL(withSaddr: saddr, daddr: daddr, mode: mode, options: options)
    }

    /**
     生成百度地图外部URL，URL SCHEME为：baidumap
     
     @param addr 显示地址，格式latitude,longitude或搜索地址
     @param options 可选附加参数，如@{@"src": @"app", @"zoom": @"14", @"coord_type": @"默认gcj02|wgs84|bd09ll"}
     @return NSURL
     */
    public static func baiduMapsURL(withAddr addr: String?, options: [AnyHashable : Any]? = nil) -> URL? {
        return Base.fw_baiduMapsURL(withAddr: addr, options: options)
    }

    /**
     生成百度地图导航外部URL，URL SCHEME为：baidumap
     
     @param saddr 导航起始点，格式latitude,longitude或搜索地址
     @param daddr 导航结束点，格式latitude,longitude或搜索地址
     @param mode 导航模式，支持driving|transit|navigation|riding|walking，默认driving
     @param options 可选附加参数，如@{@"src": @"app", @"zoom": @"14", @"coord_type": @"默认gcj02|wgs84|bd09ll"}
     @return NSURL
     */
    public static func baiduMapsURL(withSaddr saddr: String?, daddr: String?, mode: String? = nil, options: [AnyHashable : Any]? = nil) -> URL? {
        return Base.fw_baiduMapsURL(withSaddr: saddr, daddr: daddr, mode: mode, options: options)
    }
    
    /**
     生成外部URL，需配置对应URL SCHEME
     
     @param string 外部主URL
     @param params 附加参数
     @return NSURL
     */
    public static func fw_vendorURL(_ string: String, params: [AnyHashable: Any]? = nil) -> URL? {
        return Base.fw_vendorURL(string, params: params)
    }
    
}

// MARK: - UserDefaults+Foundation
extension Wrapper where Base: UserDefaults {
    
    /// 从standard读取对象，支持unarchive对象
    public static func object(forKey: String) -> Any? {
        return Base.fw_object(forKey: forKey)
    }

    /// 保存对象到standard，支持archive对象
    public static func setObject(_ object: Any?, forKey: String) {
        Base.fw_setObject(object, forKey: forKey)
    }
    
    /// 读取对象，支持unarchive对象
    public func object(forKey: String) -> Any? {
        return base.fw_object(forKey: forKey)
    }

    /// 保存对象，支持archive对象
    public func setObject(_ object: Any?, forKey: String) {
        base.fw_setObject(object, forKey: forKey)
    }
    
}
