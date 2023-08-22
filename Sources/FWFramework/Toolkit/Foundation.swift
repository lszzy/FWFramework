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
        let data = try? NSKeyedArchiver.archivedData(withRootObject: object, requiringSecureCoding: true)
        return data
    }
    
    /// 使用NSKeyedUnarchiver解压数据
    public func unarchiveObject<T>(_ clazz: T.Type) -> T? where T : NSObject, T : NSCoding {
        let object = try? NSKeyedUnarchiver.unarchivedObject(ofClass: clazz, from: self.base)
        return object
    }
    
    /// 保存对象归档
    public static func archiveObject(_ object: Any, file: String) -> Bool {
        guard let data = archiveObject(object) else { return false }
        do {
            try data.write(to: URL(fileURLWithPath: file))
            return true
        } catch {
            return false
        }
    }
    
    /// 读取对象归档
    public static func unarchiveObject<T>(_ clazz: T.Type, file: String) -> T? where T : NSObject, T : NSCoding {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: file)) else { return nil }
        return data.fw.unarchiveObject(clazz)
    }
    
    // MARK: - Encrypt
    /// 利用AES加密数据
    public func aesEncrypt(key: String, iv: Data) -> Data? {
        return (base as NSData).__fw_AESEncrypt(withKey: key, andIV: iv)
    }

    /// 利用AES解密数据
    public func aesDecrypt(key: String, iv: Data) -> Data? {
        return (base as NSData).__fw_AESDecrypt(withKey: key, andIV: iv)
    }

    /// 利用3DES加密数据
    public func des3Encrypt(key: String, iv: Data) -> Data? {
        return (base as NSData).__fw_DES3Encrypt(withKey: key, andIV: iv)
    }

    /// 利用3DES解密数据
    public func des3Decrypt(key: String, iv: Data) -> Data? {
        return (base as NSData).__fw_DES3Decrypt(withKey: key, andIV: iv)
    }

    // MARK: - RSA
    /// RSA公钥加密，数据传输安全，使用默认标签，执行base64编码
    public func rsaEncrypt(publicKey: String) -> Data? {
        return (base as NSData).__fw_RSAEncrypt(withPublicKey: publicKey)
    }

    /// RSA公钥加密，数据传输安全，可自定义标签，指定base64编码
    public func rsaEncrypt(publicKey: String, tag: String, base64Encode: Bool) -> Data? {
        return (base as NSData).__fw_RSAEncrypt(withPublicKey: publicKey, andTag: tag, base64Encode: base64Encode)
    }

    /// RSA私钥解密，数据传输安全，使用默认标签，执行base64解密
    public func rsaDecrypt(privateKey: String) -> Data? {
        return (base as NSData).__fw_RSADecrypt(withPrivateKey: privateKey)
    }

    /// RSA私钥解密，数据传输安全，可自定义标签，指定base64解码
    public func rsaDecrypt(privateKey: String, tag: String, base64Decode: Bool) -> Data? {
        return (base as NSData).__fw_RSADecrypt(withPrivateKey: privateKey, andTag: tag, base64Decode: base64Decode)
    }

    /// RSA私钥加签，防篡改防否认，使用默认标签，执行base64编码
    public func rsaSign(privateKey: String) -> Data? {
        return (base as NSData).__fw_RSASign(withPrivateKey: privateKey)
    }

    /// RSA私钥加签，防篡改防否认，可自定义标签，指定base64编码
    public func rsaSign(privateKey: String, tag: String, base64Encode: Bool) -> Data? {
        return (base as NSData).__fw_RSASign(withPrivateKey: privateKey, andTag: tag, base64Encode: base64Encode)
    }

    /// RSA公钥验签，防篡改防否认，使用默认标签，执行base64解密
    public func rsaVerify(publicKey: String) -> Data? {
        return (base as NSData).__fw_RSAVerify(withPublicKey: publicKey)
    }

    /// RSA公钥验签，防篡改防否认，可自定义标签，指定base64解码
    public func rsaVerify(publicKey: String, tag: String, base64Decode: Bool) -> Data? {
        return (base as NSData).__fw_RSAVerify(withPublicKey: publicKey, andTag: tag, base64Decode: base64Decode)
    }
}

// MARK: - Date+Foundation
extension Wrapper where Base == Date {
    /// 当前时间戳，没有设置过返回本地时间戳，可同步设置服务器时间戳，同步后调整手机时间不影响
    public static var currentTime: TimeInterval {
        get { return NSDate.__fw_currentTime }
        set { NSDate.__fw_currentTime = newValue }
    }
    
    /// 从字符串初始化日期，自定义格式(默认yyyy-MM-dd HH:mm:ss)和时区(默认当前时区)
    public static func date(string: String, format: String = "yyyy-MM-dd HH:mm:ss", timeZone: TimeZone? = nil) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = format
        if let timeZone = timeZone {
            formatter.timeZone = timeZone
        }
        let date = formatter.date(from: string)
        return date
    }
    
    /// 转化为字符串，默认当前时区，格式：yyyy-MM-dd HH:mm:ss
    public var stringValue: String {
        return string(format: "yyyy-MM-dd HH:mm:ss")
    }
    
    /// 转化为字符串，自定义格式和时区
    public func string(format: String, timeZone: TimeZone? = nil) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = format
        if let timeZone = timeZone {
            formatter.timeZone = timeZone
        }
        let string = formatter.string(from: self.base)
        return string
    }
    
    /// 格式化时长，格式"00:00"或"00:00:00"
    public static func formatDuration(_ duration: TimeInterval, hasHour: Bool) -> String {
        var seconds = Int64(duration)
        if hasHour {
            var minute = seconds / 60
            let hour = minute / 60
            seconds -= minute * 60
            minute -= hour * 60
            return String(format: "%02d:%02d:%02d", hour, minute, seconds)
        } else {
            let minute = seconds / 60
            let second = seconds % 60
            return String(format: "%02ld:%02ld", minute, second)
        }
    }
    
    /// 格式化16位、13位时间戳为10位(秒)
    public static func formatTimestamp(_ timestamp: TimeInterval) -> TimeInterval {
        return NSDate.__fw_formatTimestamp(timestamp)
    }
    
    /// 解析服务器时间戳，参数为接口响应Header的Date字段，解析失败返回0
    public static func formatServerDate(_ dateString: String) -> TimeInterval {
        return Base.fw_formatServerDate(dateString)
    }
    
    /// 是否是闰年
    public var isLeapYear: Bool {
        return (base as NSDate).__fw_isLeapYear
    }

    /// 是否是同一天
    public func isSameDay(_ date: Date) -> Bool {
        return (base as NSDate).__fw_isSameDay(date)
    }

    /// 添加指定日期，如year:1|month:-1|day:1等
    public func date(byAdding: DateComponents) -> Date? {
        return (base as NSDate).__fw_date(byAdding: byAdding)
    }

    /// 与指定日期相隔天数
    public func days(from date: Date) -> Int {
        return (base as NSDate).__fw_days(from: date)
    }
}

extension Date {
    
    fileprivate static func fw_formatServerDate(_ dateString: String) -> TimeInterval {
        let dateFormatter = fw_serverDateFormatter
        let date = dateFormatter.date(from: dateString)
        return date?.timeIntervalSince1970 ?? 0
    }
    
    private static var fw_serverDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "GMT")
        formatter.dateFormat = "EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'"
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()
    
}

// MARK: - NSNumber+Foundation
extension Wrapper where Base: NSNumber {
    
    /// 转换为CGFloat
    public var CGFloatValue: CGFloat {
        return base.__fw_CGFloatValue
    }

    /// 快捷创建NumberFormatter对象，默认numberStyle为decimal
    /// - Parameters:
    ///   - digit: 保留小数位数，默认2，示例：1234.5678 => 1234.57
    ///   - roundingMode: 取整模式，默认四舍五入，示例：1234.5678 => 1234.57
    ///   - fractionZero: 是否保留小数末尾0(示例：1234.5012 => 1234.50)，默认false去掉末尾0(示例：1234.5012 => 1234.5)
    ///   - groupingSeparator: 分组分隔符，默认为空，示例：1234.5678 => 1,234.57
    ///   - currencySymbol: 货币符号，默认为空，指定后numberStyle为currency，示例：1234.5678 => $1234.57
    /// - Returns: NumberFormatter对象
    public static func numberFormatter(
        _ digit: Int = 2,
        roundingMode: NumberFormatter.RoundingMode = .halfUp,
        fractionZero: Bool = false,
        groupingSeparator: String = "",
        currencySymbol: String = ""
    ) -> NumberFormatter {
        return NSNumber.__fw_numberFormatter(digit, roundingMode: roundingMode, fractionZero: fractionZero, groupingSeparator: groupingSeparator, currencySymbol: currencySymbol)
    }

    /// 快捷四舍五入格式化为字符串，默认numberStyle为decimal
    /// - Parameters:
    ///   - digit: 保留小数位数，默认2，示例：1234.5678 => 1234.57
    ///   - fractionZero: 是否保留小数末尾0(示例：1234.5012 => 1234.50)，默认false去掉末尾0(示例：1234.5012 => 1234.5)
    ///   - groupingSeparator: 分组分隔符，默认为空，示例：1234.5678 => 1,234.57
    ///   - currencySymbol: 货币符号，默认为空，指定后numberStyle为currency，示例：1234.5678 => $1234.57
    /// - Returns: 格式化字符串
    public func roundString(
        _ digit: Int = 2,
        fractionZero: Bool = false,
        groupingSeparator: String = "",
        currencySymbol: String = ""
    ) -> String {
        return base.__fw_roundString(digit, fractionZero: fractionZero, groupingSeparator: groupingSeparator, currencySymbol: currencySymbol)
    }

    /// 快捷取上整格式化为字符串，默认numberStyle为decimal
    /// - Parameters:
    ///   - digit: 保留小数位数，默认2，示例：1234.5678 => 1234.57
    ///   - fractionZero: 是否保留小数末尾0(示例：1234.8912 => 1234.90)，默认false去掉末尾0(示例：1234.8912 => 1234.9)
    ///   - groupingSeparator: 分组分隔符，默认为空，示例：1234.5678 => 1,234.57
    ///   - currencySymbol: 货币符号，默认为空，指定后numberStyle为currency，示例：1234.5678 => $1234.57
    /// - Returns: 格式化字符串
    public func ceilString(
        _ digit: Int = 2,
        fractionZero: Bool = false,
        groupingSeparator: String = "",
        currencySymbol: String = ""
    ) -> String {
        return base.__fw_ceilString(digit, fractionZero: fractionZero, groupingSeparator: groupingSeparator, currencySymbol: currencySymbol)
    }

    /// 快捷取下整格式化为字符串，默认numberStyle为decimal
    /// - Parameters:
    ///   - digit: 保留小数位数，默认2，示例：1234.5678 => 1234.56
    ///   - fractionZero: 是否保留小数末尾0(示例：1234.9012 => 1234.90)，默认false去掉末尾0(示例：1234.9012 => 1234.9)
    ///   - groupingSeparator: 分组分隔符，默认为空，示例：1234.5678 => 1,234.56
    ///   - currencySymbol: 货币符号，默认为空，指定后numberStyle为currency，示例：1234.5678 => $1234.56
    /// - Returns: 格式化字符串
    public func floorString(
        _ digit: Int = 2,
        fractionZero: Bool = false,
        groupingSeparator: String = "",
        currencySymbol: String = ""
    ) -> String {
        return base.__fw_floorString(digit, fractionZero: fractionZero, groupingSeparator: groupingSeparator, currencySymbol: currencySymbol)
    }
    
}

// MARK: - String+Foundation
extension Wrapper where Base == String {
    /// 计算多行字符串指定字体、指定属性在指定绘制区域内所占尺寸
    public func size(font: UIFont, drawSize: CGSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude), attributes: [NSAttributedString.Key: Any]? = nil) -> CGSize {
        var attr: [NSAttributedString.Key: Any] = [:]
        attr[.font] = font
        if let attributes = attributes {
            attr.merge(attributes) { _, last in last }
        }
        
        let str = self.base as NSString
        let size = str.boundingRect(with: drawSize, options: [.usesFontLeading, .usesLineFragmentOrigin], attributes: attr, context: nil).size
        return CGSize(width: min(drawSize.width, ceil(size.width)), height: min(drawSize.height, ceil(size.height)))
    }
    
    /// 格式化文件大小为".0K/.1M/.1G"
    public static func sizeString(_ aFileSize: UInt) -> String {
        guard aFileSize > 0 else { return "0K" }
        var fileSize = Double(aFileSize) / 1024
        if fileSize >= 1024 {
            fileSize = fileSize / 1024
            if fileSize >= 1024 {
                fileSize = fileSize / 1024
                return String(format: "%0.1fG", fileSize)
            } else {
                return String(format: "%0.1fM", fileSize)
            }
        } else {
            return String(format: "%dK", Int(ceil(fileSize)))
        }
    }
    
    /// 是否匹配正则表达式，示例：^[a-zA-Z0-9_\u4e00-\u9fa5]{4,14}$
    public func matchesRegex(_ regex: String) -> Bool {
        let regexPredicate = NSPredicate(format: "SELF MATCHES %@", regex)
        return regexPredicate.evaluate(with: self.base)
    }
    
    /**
     *  安全截取字符串。解决末尾半个Emoji问题(半个Emoji调UTF8String为NULL，导致MD5签名等失败)
     *
     *  @param index 目标索引
     */
    public func emojiSubstring(_ index: UInt) -> String {
        return (base as NSString).__fw_emojiSubstring(index)
    }

    /**
     *  正则搜索子串
     *
     *  @param regex 正则表达式
     */
    public func regexSubstring(_ regex: String) -> String? {
        return (base as NSString).__fw_regexSubstring(regex)
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
        return (base as NSString).__fw_regexReplace(regex, with: string)
    }

    /**
     *  正则匹配回调
     *
     *  @param regex 正则表达式
     *  @param block 回调句柄。range从大至小，方便replace
     */
    public func regexMatches(_ regex: String, block: @escaping (NSRange) -> Void) {
        return (base as NSString).__fw_regexMatches(regex, with: block)
    }
    
    /// 转义Html，如"a<"转义为"a&lt;"
    public var escapeHtml: String {
        return (base as NSString).__fw_escapeHtml
    }
    
    /// 是否符合验证器
    public func isValid(_ validator: Validator<String>) -> Bool {
        return validator.validate(base)
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
        return (base as NSString).__fw_isFormatRegex(regex)
    }

    /// 是否是手机号
    public func isFormatMobile() -> Bool {
        return (base as NSString).__fw_isFormatMobile()
    }

    /// 是否是座机号
    public func isFormatTelephone() -> Bool {
        return (base as NSString).__fw_isFormatTelephone()
    }
    
    /// 是否是整数
    public func isFormatInteger() -> Bool {
        return (base as NSString).__fw_isFormatInteger()
    }
    
    /// 是否是数字
    public func isFormatNumber() -> Bool {
        return (base as NSString).__fw_isFormatNumber()
    }
    
    /// 是否是合法金额，两位小数点
    public func isFormatMoney() -> Bool {
        return (base as NSString).__fw_isFormatMoney()
    }
    
    /// 是否是身份证号
    public func isFormatIdcard() -> Bool {
        return (base as NSString).__fw_isFormatIdcard()
    }
    
    /// 是否是银行卡号
    public func isFormatBankcard() -> Bool {
        return (base as NSString).__fw_isFormatBankcard()
    }
    
    /// 是否是车牌号
    public func isFormatCarno() -> Bool {
        return (base as NSString).__fw_isFormatCarno()
    }
    
    /// 是否是邮政编码
    public func isFormatPostcode() -> Bool {
        return (base as NSString).__fw_isFormatPostcode()
    }
    
    /// 是否是邮箱
    public func isFormatEmail() -> Bool {
        return (base as NSString).__fw_isFormatEmail()
    }
    
    /// 是否是URL
    public func isFormatUrl() -> Bool {
        return (base as NSString).__fw_isFormatUrl()
    }
    
    /// 是否是HTML
    public func isFormatHtml() -> Bool {
        return (base as NSString).__fw_isFormatHtml()
    }
    
    /// 是否是IP
    public func isFormatIp() -> Bool {
        return (base as NSString).__fw_isFormatIp()
    }
    
    /// 是否全是中文
    public func isFormatChinese() -> Bool {
        return (base as NSString).__fw_isFormatChinese()
    }
    
    /// 是否是合法时间，格式：yyyy-MM-dd HH:mm:ss
    public func isFormatDatetime() -> Bool {
        return (base as NSString).__fw_isFormatDatetime()
    }
    
    /// 是否是合法时间戳，格式：1301234567
    public func isFormatTimestamp() -> Bool {
        return (base as NSString).__fw_isFormatTimestamp()
    }
    
    /// 是否是坐标点字符串，格式：latitude,longitude
    public func isFormatCoordinate() -> Bool {
        return (base as NSString).__fw_isFormatCoordinate()
    }
    
}

// MARK: - FileManager+Foundation
extension Wrapper where Base: FileManager {
    
    /// 搜索路径
    ///
    /// - Parameter directory: 搜索目录
    /// - Returns: 目标路径
    public static func pathSearch(_ directory: FileManager.SearchPathDirectory) -> String {
        return NSSearchPathForDirectoriesInDomains(directory, .userDomainMask, true)[0]
    }

    /// 沙盒路径，常量
    public static var pathHome: String {
        return NSHomeDirectory()
    }

    /// 文档路径，iTunes会同步备份
    public static var pathDocument: String {
        return pathSearch(.documentDirectory)
    }

    /// 缓存路径，系统不会删除，iTunes会删除
    public static var pathCaches: String {
        return pathSearch(.cachesDirectory)
    }

    /// Library路径
    public static var pathLibrary: String {
        return pathSearch(.libraryDirectory)
    }

    /// 配置路径，配置文件保存位置
    public static var pathPreference: String {
        return (pathLibrary as NSString).appendingPathComponent("Preference")
    }

    /// 临时路径，App退出后可能会删除
    public static var pathTmp: String {
        return NSTemporaryDirectory()
    }

    /// bundle路径，不可写
    public static var pathBundle: String {
        return Bundle.main.bundlePath
    }

    /// 资源路径，不可写
    public static var pathResource: String {
        return Bundle.main.resourcePath ?? ""
    }

    /// 获取目录大小，单位：B
    public static func folderSize(_ folderPath: String) -> UInt64 {
        return Base.__fw_folderSize(folderPath)
    }
    
}

// MARK: - NSAttributedString+Foundation
/// 如果需要实现行内图片可点击效果，可使用UITextView添加附件或Link并实现delegate.shouldInteractWith方法即可。
/// 注意iOS在后台运行时，如果调用NSAttributedString解析html会导致崩溃(如动态切换深色模式时在后台解析html)。解决方法是提前在前台解析好或者后台异步到下一个主线程RunLoop
extension Wrapper where Base: NSAttributedString {
    
    /// NSAttributedString对象转换为html字符串
    public func htmlString() -> String? {
        return base.__fw_htmlString()
    }

    /// 计算所占尺寸，需设置Font等
    public var textSize: CGSize {
        return base.__fw_textSize
    }

    /// 计算在指定绘制区域内所占尺寸，需设置Font等
    public func textSize(drawSize: CGSize) -> CGSize {
        return base.__fw_textSize(withDraw: drawSize)
    }
    
    /// html字符串转换为NSAttributedString对象。如需设置默认字体和颜色，请使用addAttributes方法或附加CSS样式
    public static func attributedString(htmlString: String) -> Base? {
        return Base.__fw_attributedString(withHtmlString: htmlString)
    }

    /// 图片转换为NSAttributedString对象，可实现行内图片样式。其中bounds.x会设置为间距，y常用算法：(font.capHeight - image.size.height) / 2.0
    public static func attributedString(image: UIImage?, bounds: CGRect) -> NSAttributedString {
        return Base.__fw_attributedString(with: image, bounds: bounds)
    }
    
    /// 快速创建NSAttributedString并指定单个高亮部分文字和样式，链接设置NSLinkAttributeName|URL属性即可
    public static func attributedString(string: String, attributes: [NSAttributedString.Key : Any]?, highlight: String, highlightAttributes: [NSAttributedString.Key : Any]?) -> NSAttributedString {
        return Base.__fw_attributedString(with: string, attributes: attributes, highlight: highlight, highlightAttributes: highlightAttributes)
    }
    
    /// 快速创建NSAttributedString并指定所有高亮部分文字和样式，链接设置NSLinkAttributeName|URL属性即可
    public static func attributedString(string: String, attributes: [NSAttributedString.Key : Any]?, highlights: [String: [NSAttributedString.Key : Any]]) -> NSAttributedString {
        return Base.__fw_attributedString(with: string, attributes: attributes, highlights: highlights)
    }
    
    /// 快速创建NSAttributedString，自定义字体和颜色
    public static func attributedString(_ string: String, font: UIFont?, textColor: UIColor? = nil) -> Base {
        return Base.__fw_attributedString(string, with: font, textColor: textColor)
    }
    
    /// 快速创建NSAttributedString，自定义字体、颜色、行高、对齐方式和换行模式
    public static func attributedString(_ string: String, font: UIFont?, textColor: UIColor?, lineHeight: CGFloat, textAlignment: NSTextAlignment = .left, lineBreakMode: NSLineBreakMode = .byWordWrapping) -> Base {
        return Base.__fw_attributedString(string, with: font, textColor: textColor, lineHeight: lineHeight, textAlignment: textAlignment, lineBreakMode: lineBreakMode)
    }
    
    /// html字符串转换为NSAttributedString对象，可设置默认系统字体和颜色(附加CSS方式)
    public static func attributedString(htmlString: String, defaultAttributes: [NSAttributedString.Key: Any]?) -> Base? {
        return Base.__fw_attributedString(withHtmlString: htmlString, defaultAttributes: defaultAttributes)
    }

    /// html字符串转换为NSAttributedString主题对象，可设置默认系统字体和动态颜色，详见FWThemeObject
    public static func themeObject(htmlString: String, defaultAttributes: [NSAttributedString.Key: Any]?) -> ThemeObject<NSAttributedString> {
        return Base.__fw_themeObject(withHtmlString: htmlString, defaultAttributes: defaultAttributes)
    }

    /// 获取颜色对应CSS字符串(rgb|rgba格式)
    public static func cssString(color: UIColor) -> String {
        return Base.__fw_CSSString(with: color)
    }

    /// 获取系统字体对应CSS字符串(family|style|weight|size)
    public static func cssString(font: UIFont) -> String {
        return Base.__fw_CSSString(with: font)
    }
    
}

// MARK: - NSObject+Foundation
extension Wrapper where Base: NSObject {
    
    /// 执行加锁(支持任意对象)，等待信号量，自动创建信号量
    public func lock() {
        base.__fw_lock()
    }

    /// 执行解锁(支持任意对象)，发送信号量，自动创建信号量
    public func unlock() {
        base.__fw_unlock()
    }
    
    /// 延迟delay秒后主线程执行，返回可取消的block，对象范围
    @discardableResult
    public func performBlock(
        _ block: @escaping (Any) -> Void,
        afterDelay delay: TimeInterval
    ) -> Any {
        return base.__fw_perform(block, afterDelay: delay)
    }

    /// 延迟delay秒后后台线程执行，返回可取消的block，对象范围
    @discardableResult
    public func performBlock(
        inBackground block: @escaping (Any) -> Void,
        afterDelay delay: TimeInterval
    ) -> Any {
        return base.__fw_performBlock(inBackground: block, afterDelay: delay)
    }

    /// 延迟delay秒后指定线程执行，返回可取消的block，对象范围
    @discardableResult
    public func performBlock(
        _ block: @escaping (Any) -> Void,
        on: DispatchQueue,
        afterDelay delay: TimeInterval
    ) -> Any {
        return base.__fw_perform(block, on: on, afterDelay: delay)
    }
    
    /// 同一个identifier仅执行一次block，对象范围
    public func performOnce(
        _ identifier: String,
        with block: @escaping () -> Void
    ) {
        base.__fw_performOnce(identifier, with: block)
    }
    
    /// 延迟delay秒后主线程执行，返回可取消的block，全局范围
    @discardableResult
    public static func performBlock(
        _ block: @escaping () -> Void,
        afterDelay delay: TimeInterval
    ) -> Any {
        return Base.__fw_perform(with: block, afterDelay: delay)
    }

    /// 延迟delay秒后后台线程执行，返回可取消的block，全局范围
    @discardableResult
    public static func performBlock(
        inBackground block: @escaping () -> Void,
        afterDelay delay: TimeInterval
    ) -> Any {
        return Base.__fw_perform(inBackground: block, afterDelay: delay)
    }

    /// 延迟delay秒后指定线程执行，返回可取消的block，全局范围
    @discardableResult
    public static func performBlock(
        _ block: @escaping () -> Void,
        on: DispatchQueue,
        afterDelay delay: TimeInterval
    ) -> Any {
        return Base.__fw_perform(with: block, on: on, afterDelay: delay)
    }

    /// 取消指定延迟block，全局范围
    public static func cancelBlock(_ block: Any) {
        Base.__fw_cancelBlock(block)
    }

    /// 同步方式执行异步block，阻塞当前线程(信号量)，异步block必须调用completionHandler，全局范围
    public static func syncPerform(
        asyncBlock: @escaping (@escaping () -> Void) -> Void
    ) {
        Base.__fw_syncPerformAsyncBlock(asyncBlock)
    }

    /// 同一个identifier仅执行一次block，全局范围
    public static func performOnce(
        _ identifier: String,
        with block: @escaping () -> Void
    ) {
        Base.__fw_performOnce(identifier, with: block)
    }

    /// 重试方式执行异步block，直至成功或者次数为0(小于0不限)或者超时(小于等于0不限)，完成后回调completion。block必须调用completionHandler，参数示例：重试4次|超时8秒|延迟2秒
    public static func performBlock(
        _ block: @escaping (@escaping (Bool, Any?) -> Void) -> Void,
        completion: @escaping (Bool, Any?) -> Void,
        retryCount: Int,
        timeoutInterval: TimeInterval,
        delayInterval: @escaping (Int) -> TimeInterval,
        isCancelled: (() -> Bool)? = nil
    ) {
        Base.__fw_perform(block, completion: completion, retryCount: retryCount, timeoutInterval: timeoutInterval, delayInterval: delayInterval, isCancelled: isCancelled)
    }

    /// 执行轮询block任务，返回任务Id可取消
    @discardableResult
    public static func performTask(_ task: @escaping () -> Void, start: TimeInterval, interval: TimeInterval, repeats: Bool, async: Bool) -> String {
        return Base.__fw_performTask(task, start: start, interval: interval, repeats: repeats, async: async)
    }

    /// 指定任务Id取消轮询任务
    public static func cancelTask(_ taskId: String) {
        Base.__fw_cancelTask(taskId)
    }
    
}

// MARK: - URL+Foundation
/// 第三方URL生成器，可先判断canOpenURL，再openURL，需添加对应URL SCHEME到LSApplicationQueriesSchemes配置数组
extension Wrapper where Base == URL {
    
    /**
     生成App Store外部URL
     
     @param appId 应用Id
     @return NSURL
     */
    public static func appStoreURL(_ appId: String) -> URL {
        return NSURL.__fw_appStore(appId)
    }

    /**
     生成苹果地图地址外部URL
     
     @param addr 显示地址，格式latitude,longitude或搜索地址
     @param options 可选附加参数，如@{@"ll": @"latitude,longitude", @"z": @"14"}
     @return NSURL
     */
    public static func appleMapsURL(withAddr addr: String?, options: [AnyHashable : Any]? = nil) -> URL? {
        return NSURL.__fw_appleMapsURL(withAddr: addr, options: options)
    }

    /**
     生成苹果地图导航外部URL
     
     @param saddr 导航起始点，格式latitude,longitude或搜索地址
     @param daddr 导航结束点，格式latitude,longitude或搜索地址
     @param options 可选附加参数，如@{@"ll": @"latitude,longitude", @"z": @"14"}
     @return NSURL
     */
    public static func appleMapsURL(withSaddr saddr: String?, daddr: String?, options: [AnyHashable : Any]? = nil) -> URL? {
        return NSURL.__fw_appleMapsURL(withSaddr: saddr, daddr: daddr, options: options)
    }

    /**
     生成谷歌地图外部URL，URL SCHEME为：comgooglemaps
     
     @param addr 显示地址，格式latitude,longitude或搜索地址
     @param options 可选附加参数，如@{@"center": @"latitude,longitude", @"zoom": @"14"}
     @return NSURL
     */
    public static func googleMapsURL(withAddr addr: String?, options: [AnyHashable : Any]? = nil) -> URL? {
        return NSURL.__fw_googleMapsURL(withAddr: addr, options: options)
    }

    /**
     生成谷歌地图导航外部URL，URL SCHEME为：comgooglemaps
     
     @param saddr 导航起始点，格式latitude,longitude或搜索地址
     @param daddr 导航结束点，格式latitude,longitude或搜索地址
     @param mode 导航模式，支持driving|transit|bicycling|walking，默认driving
     @param options 可选附加参数，如@{@"center": @"latitude,longitude", @"zoom": @"14", @"dirflg": @"t,h"}
     @return NSURL
     */
    public static func googleMapsURL(withSaddr saddr: String?, daddr: String?, mode: String?, options: [AnyHashable : Any]? = nil) -> URL? {
        return NSURL.__fw_googleMapsURL(withSaddr: saddr, daddr: daddr, mode: mode, options: options)
    }

    /**
     生成百度地图外部URL，URL SCHEME为：baidumap
     
     @param addr 显示地址，格式latitude,longitude或搜索地址
     @param options 可选附加参数，如@{@"src": @"app", @"zoom": @"14", @"coord_type": @"默认gcj02|wgs84|bd09ll"}
     @return NSURL
     */
    public static func baiduMapsURL(withAddr addr: String?, options: [AnyHashable : Any]? = nil) -> URL? {
        return NSURL.__fw_baiduMapsURL(withAddr: addr, options: options)
    }

    /**
     生成百度地图导航外部URL，URL SCHEME为：baidumap
     
     @param saddr 导航起始点，格式latitude,longitude或搜索地址
     @param daddr 导航结束点，格式latitude,longitude或搜索地址
     @param mode 导航模式，支持driving|transit|navigation|riding|walking，默认driving
     @param options 可选附加参数，如@{@"src": @"app", @"zoom": @"14", @"coord_type": @"默认gcj02|wgs84|bd09ll"}
     @return NSURL
     */
    public static func baiduMapsURL(withSaddr saddr: String?, daddr: String?, mode: String?, options: [AnyHashable : Any]? = nil) -> URL? {
        return NSURL.__fw_baiduMapsURL(withSaddr: saddr, daddr: daddr, mode: mode, options: options)
    }
    
}

// MARK: - UserDefaults+Foundation
extension Wrapper where Base: UserDefaults {
    
    /// 从standard读取对象，支持unarchive对象
    public static func object(forKey: String) -> Any? {
        return Base.__fw_object(forKey: forKey)
    }

    /// 保存对象到standard，支持archive对象
    public static func setObject(_ object: Any?, forKey: String) {
        Base.__fw_setObject(object, forKey: forKey)
    }
    
    /// 读取对象，支持unarchive对象
    public func object(forKey: String) -> Any? {
        return base.__fw_object(forKey: forKey)
    }

    /// 保存对象，支持archive对象
    public func setObject(_ object: Any?, forKey: String) {
        base.__fw_setObject(object, forKey: forKey)
    }
    
}
