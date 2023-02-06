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

// MARK: - FW+Foundation
extension FW {

    /// 通用互斥锁方法
    public static func synchronized(_ object: Any, closure: () -> Void) {
        objc_sync_enter(object)
        defer {
            objc_sync_exit(object)
        }
        
        closure()
    }
    
    /// 同一个token仅执行一次block，全局范围
    public static func dispatchOnce(
        _ token: String,
        closure: @escaping () -> Void
    ) {
        NSObject.fw_dispatchOnce(token, closure: closure)
    }
    
}

// MARK: - Data+Foundation
@_spi(FW) extension Data {
    /// 使用NSKeyedArchiver压缩对象
    public static func fw_archiveObject(_ object: Any) -> Data? {
        let data = try? NSKeyedArchiver.archivedData(withRootObject: object, requiringSecureCoding: true)
        return data
    }
    
    /// 使用NSKeyedUnarchiver解压数据
    public func fw_unarchiveObject<T>(_ clazz: T.Type) -> T? where T : NSObject, T : NSCoding {
        let object = try? NSKeyedUnarchiver.unarchivedObject(ofClass: clazz, from: self)
        return object
    }
    
    /// 保存对象归档
    public static func fw_archiveObject(_ object: Any, file: String) -> Bool {
        guard let data = fw_archiveObject(object) else { return false }
        do {
            try data.write(to: URL(fileURLWithPath: file))
            return true
        } catch {
            return false
        }
    }
    
    /// 读取对象归档
    public static func fw_unarchiveObject<T>(_ clazz: T.Type, file: String) -> T? where T : NSObject, T : NSCoding {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: file)) else { return nil }
        return data.fw_unarchiveObject(clazz)
    }
    
    // MARK: - Encrypt
    /// 利用AES加密数据
    public func fw_aesEncrypt(key: String, iv: Data) -> Data? {
        return (self as NSData).__fw_AESEncrypt(withKey: key, andIV: iv)
    }

    /// 利用AES解密数据
    public func fw_aesDecrypt(key: String, iv: Data) -> Data? {
        return (self as NSData).__fw_AESDecrypt(withKey: key, andIV: iv)
    }

    /// 利用3DES加密数据
    public func fw_des3Encrypt(key: String, iv: Data) -> Data? {
        return (self as NSData).__fw_DES3Encrypt(withKey: key, andIV: iv)
    }

    /// 利用3DES解密数据
    public func fw_des3Decrypt(key: String, iv: Data) -> Data? {
        return (self as NSData).__fw_DES3Decrypt(withKey: key, andIV: iv)
    }

    // MARK: - RSA
    /// RSA公钥加密，数据传输安全，使用默认标签，执行base64编码
    public func fw_rsaEncrypt(publicKey: String) -> Data? {
        return (self as NSData).__fw_RSAEncrypt(withPublicKey: publicKey)
    }

    /// RSA公钥加密，数据传输安全，可自定义标签，指定base64编码
    public func fw_rsaEncrypt(publicKey: String, tag: String, base64Encode: Bool) -> Data? {
        return (self as NSData).__fw_RSAEncrypt(withPublicKey: publicKey, andTag: tag, base64Encode: base64Encode)
    }

    /// RSA私钥解密，数据传输安全，使用默认标签，执行base64解密
    public func fw_rsaDecrypt(privateKey: String) -> Data? {
        return (self as NSData).__fw_RSADecrypt(withPrivateKey: privateKey)
    }

    /// RSA私钥解密，数据传输安全，可自定义标签，指定base64解码
    public func fw_rsaDecrypt(privateKey: String, tag: String, base64Decode: Bool) -> Data? {
        return (self as NSData).__fw_RSADecrypt(withPrivateKey: privateKey, andTag: tag, base64Decode: base64Decode)
    }

    /// RSA私钥加签，防篡改防否认，使用默认标签，执行base64编码
    public func fw_rsaSign(privateKey: String) -> Data? {
        return (self as NSData).__fw_RSASign(withPrivateKey: privateKey)
    }

    /// RSA私钥加签，防篡改防否认，可自定义标签，指定base64编码
    public func fw_rsaSign(privateKey: String, tag: String, base64Encode: Bool) -> Data? {
        return (self as NSData).__fw_RSASign(withPrivateKey: privateKey, andTag: tag, base64Encode: base64Encode)
    }

    /// RSA公钥验签，防篡改防否认，使用默认标签，执行base64解密
    public func fw_rsaVerify(publicKey: String) -> Data? {
        return (self as NSData).__fw_RSAVerify(withPublicKey: publicKey)
    }

    /// RSA公钥验签，防篡改防否认，可自定义标签，指定base64解码
    public func fw_rsaVerify(publicKey: String, tag: String, base64Decode: Bool) -> Data? {
        return (self as NSData).__fw_RSAVerify(withPublicKey: publicKey, andTag: tag, base64Decode: base64Decode)
    }
}

// MARK: - Date+Foundation
@_spi(FW) extension Date {
    /// 当前时间戳，没有设置过返回本地时间戳，可同步设置服务器时间戳，同步后调整手机时间不影响
    public static var fw_currentTime: TimeInterval {
        get {
            // 没有同步过返回本地时间
            if fw_staticCurrentBaseTime == 0 {
                // 是否本地有服务器时间
                let preCurrentTime = UserDefaults.standard.object(forKey: "FWCurrentTime") as? NSNumber
                let preLocalTime = UserDefaults.standard.object(forKey: "FWLocalTime") as? NSNumber
                if let preCurrentTime = preCurrentTime,
                   let preLocalTime = preLocalTime {
                    // 计算当前服务器时间
                    let offsetTime = Date().timeIntervalSince1970 - preLocalTime.doubleValue
                    return preCurrentTime.doubleValue + offsetTime
                } else {
                    return Date().timeIntervalSince1970
                }
            // 同步过计算当前服务器时间
            } else {
                let offsetTime = __FWBridge.systemUptime() - fw_staticLocalBaseTime
                return fw_staticCurrentBaseTime + offsetTime
            }
        }
        set {
            fw_staticCurrentBaseTime = newValue
            // 取运行时间，调整系统时间不会影响
            fw_staticLocalBaseTime = __FWBridge.systemUptime()
            
            // 保存当前服务器时间到本地
            UserDefaults.standard.set(NSNumber(value: newValue), forKey: "FWCurrentTime")
            UserDefaults.standard.set(NSNumber(value: Date().timeIntervalSince1970), forKey: "FWLocalTime")
            UserDefaults.standard.synchronize()
        }
    }
    
    private static var fw_staticCurrentBaseTime: TimeInterval = 0
    private static var fw_staticLocalBaseTime: TimeInterval = 0
    
    /// 从字符串初始化日期，自定义格式(默认yyyy-MM-dd HH:mm:ss)和时区(默认当前时区)
    public static func fw_date(string: String, format: String = "yyyy-MM-dd HH:mm:ss", timeZone: TimeZone? = nil) -> Date? {
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
    public var fw_stringValue: String {
        return fw_string(format: "yyyy-MM-dd HH:mm:ss")
    }
    
    /// 转化为字符串，自定义格式和时区
    public func fw_string(format: String, timeZone: TimeZone? = nil) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = format
        if let timeZone = timeZone {
            formatter.timeZone = timeZone
        }
        let string = formatter.string(from: self)
        return string
    }
    
    /// 格式化时长，格式"00:00"或"00:00:00"
    public static func fw_formatDuration(_ duration: TimeInterval, hasHour: Bool) -> String {
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
    public static func fw_formatTimestamp(_ timestamp: TimeInterval) -> TimeInterval {
        let string = String(format: "%ld", Int64(timestamp))
        if string.count == 16 {
            return timestamp / 1000.0 / 1000.0
        } else if string.count == 13 {
            return timestamp / 1000.0
        } else {
            return timestamp
        }
    }
    
    /// 是否是闰年
    public var fw_isLeapYear: Bool {
        let year = Calendar.current.component(.year, from: self)
        if year % 400 == 0 {
            return true
        } else if year % 100 == 0 {
            return false
        } else if year % 4 == 0 {
            return true
        }
        return false
    }

    /// 是否是同一天
    public func fw_isSameDay(_ date: Date) -> Bool {
        var components = Calendar.current.dateComponents([.era, .year, .month, .day], from: date)
        let dateOne = Calendar.current.date(from: components)
        
        components = Calendar.current.dateComponents([.era, .year, .month, .day], from: self)
        let dateTwo = Calendar.current.date(from: components)
        return dateOne == dateTwo
    }

    /// 添加指定日期，如year:1|month:-1|day:1等
    public func fw_date(byAdding: DateComponents) -> Date? {
        return Calendar.current.date(byAdding: byAdding, to: self)
    }

    /// 与指定日期相隔天数
    public func fw_days(from date: Date) -> Int {
        let earliest = (self as NSDate).earlierDate(date)
        let latest = earliest == self ? date : self
        let multipier: Int = earliest == self ? -1 : 1
        let components = Calendar.current.dateComponents([.day], from: earliest, to: latest)
        return multipier * (components.day ?? 0)
    }
}

// MARK: - NSNumber+Foundation
@_spi(FW) extension NSNumber {

    /// 四舍五入，去掉末尾0，最多digit位，小数分隔符为.，分组分隔符为空，示例：12345.6789 => 12345.68
    public func fw_roundString(_ digit: Int) -> String {
        return fw_formatString(digit, roundingMode: .halfUp)
    }

    /// 取上整，去掉末尾0，最多digit位，小数分隔符为.，分组分隔符为空，示例：12345.6789 => 12345.68
    public func fw_ceilString(_ digit: Int) -> String {
        return fw_formatString(digit, roundingMode: .ceiling)
    }

    /// 取下整，去掉末尾0，最多digit位，小数分隔符为.，分组分隔符为空，示例：12345.6789 => 12345.67
    public func fw_floorString(_ digit: Int) -> String {
        return fw_formatString(digit, roundingMode: .floor)
    }
    
    private func fw_formatString(_ digit: Int, roundingMode: NumberFormatter.RoundingMode) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.roundingMode = roundingMode
        formatter.minimumIntegerDigits = 1
        formatter.maximumFractionDigits = digit
        formatter.decimalSeparator = "."
        formatter.groupingSeparator = ""
        formatter.usesGroupingSeparator = false
        formatter.currencyDecimalSeparator = "."
        formatter.currencyGroupingSeparator = ""
        return formatter.string(from: self) ?? ""
    }

    /// 四舍五入，去掉末尾0，最多digit位，示例：12345.6789 => 12345.68
    public func fw_roundNumber(_ digit: Int) -> NSNumber {
        return fw_formatNumber(digit, roundingMode: .halfUp)
    }

    /// 取上整，去掉末尾0，最多digit位，示例：12345.6789 => 12345.68
    public func fw_ceilNumber(_ digit: Int) -> NSNumber {
        return fw_formatNumber(digit, roundingMode: .ceiling)
    }

    /// 取下整，去掉末尾0，最多digit位，示例：12345.6789 => 12345.67
    public func fw_floorNumber(_ digit: Int) -> NSNumber {
        return fw_formatNumber(digit, roundingMode: .floor)
    }
    
    private func fw_formatNumber(_ digit: Int, roundingMode: NumberFormatter.RoundingMode) -> NSNumber {
        let string = fw_formatString(digit, roundingMode: roundingMode) as NSString
        return NSNumber(value: string.doubleValue)
    }
    
}

// MARK: - String+Foundation
@_spi(FW) extension String {
    /// 计算多行字符串指定字体、指定属性在指定绘制区域内所占尺寸
    public func fw_size(font: UIFont, drawSize: CGSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude), attributes: [NSAttributedString.Key: Any]? = nil) -> CGSize {
        var attr: [NSAttributedString.Key: Any] = [:]
        attr[.font] = font
        if let attributes = attributes {
            attr.merge(attributes) { _, last in last }
        }
        
        let str = self as NSString
        let size = str.boundingRect(with: drawSize, options: [.usesFontLeading, .usesLineFragmentOrigin], attributes: attr, context: nil).size
        return CGSize(width: min(drawSize.width, ceil(size.width)), height: min(drawSize.height, ceil(size.height)))
    }
    
    /// 格式化文件大小为".0K/.1M/.1G"
    public static func fw_sizeString(_ aFileSize: UInt) -> String {
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
    public func fw_matchesRegex(_ regex: String) -> Bool {
        let regexPredicate = NSPredicate(format: "SELF MATCHES %@", regex)
        return regexPredicate.evaluate(with: self)
    }
    
    /**
     *  安全截取字符串。解决末尾半个Emoji问题(半个Emoji调UTF8String为NULL，导致MD5签名等失败)
     *
     *  @param index 目标索引
     */
    public func fw_emojiSubstring(_ index: Int) -> String {
        var result = self as NSString
        if result.length > index {
            // 获取index处的整个字符range，并截取掉整个字符，防止半个Emoji
            let rangeIndex = result.rangeOfComposedCharacterSequence(at: index)
            result = result.substring(to: rangeIndex.location) as NSString
        }
        return result as String
    }

    /**
     *  正则搜索子串
     *
     *  @param regex 正则表达式
     */
    public func fw_regexSubstring(_ regex: String) -> String? {
        let range = (self as NSString).range(of: regex, options: .regularExpression)
        if range.location != NSNotFound {
            return (self as NSString).substring(with: range)
        } else {
            return nil
        }
    }

    /**
     *  正则替换字符串
     *
     *  @param regex  正则表达式
     *  @param string 替换模板，如"头部$1中部$2尾部"
     *
     *  @return 替换后的字符串
     */
    public func fw_regexReplace(_ regex: String, string: String) -> String {
        guard let regexObj = try? NSRegularExpression(pattern: regex) else {
            return self
        }
        return regexObj.stringByReplacingMatches(in: self, range: NSMakeRange(0, (self as NSString).length), withTemplate: string)
    }

    /**
     *  正则匹配回调
     *
     *  @param regex 正则表达式
     *  @param block 回调句柄。range从大至小，方便replace
     */
    public func fw_regexMatches(_ regex: String, block: @escaping (NSRange) -> Void) {
        guard let regexObj = try? NSRegularExpression(pattern: regex) else { return }
        let matches = regexObj.matches(in: self, range: NSMakeRange(0, (self as NSString).length))
        // 倒序循环，避免replace等越界
        for match in matches.reversed() {
            block(match.range)
        }
    }
    
    /// 转义Html，如"a<"转义为"a&lt;"
    public var fw_escapeHtml: String {
        return __FWBridge.escapeHtml(self)
    }
    
    /**
     *  是否符合正则表达式
     *  示例：用户名：^[a-zA-Z][a-zA-Z0-9_]{4,13}$
     *       密码：^[a-zA-Z0-9_]{6,20}$
     *       昵称：^[a-zA-Z0-9_\u4e00-\u9fa5]{4,14}$
     *
     *  @param regex 正则表达式
     */
    public func fw_isFormatRegex(_ regex: String) -> Bool {
        let regexPredicate = NSPredicate(format: "SELF MATCHES %@", regex)
        return regexPredicate.evaluate(with: self)
    }

    /// 是否是手机号
    public var fw_isFormatMobile: Bool {
        return fw_isFormatRegex("^1\\d{10}$")
    }

    /// 是否是座机号
    public var fw_isFormatTelephone: Bool {
        return fw_isFormatRegex("^(\\d{3}\\-)?\\d{8}|(\\d{4}\\-)?\\d{7}$")
    }
    
    /// 是否是整数
    public var fw_isFormatInteger: Bool {
        return fw_isFormatRegex("^\\-?\\d+$")
    }
    
    /// 是否是数字
    public var fw_isFormatNumber: Bool {
        return fw_isFormatRegex("^\\-?\\d+\\.?\\d*$")
    }
    
    /// 是否是合法金额，两位小数点
    public var fw_isFormatMoney: Bool {
        return fw_isFormatRegex("^\\d+\\.?\\d{0,2}$")
    }
    
    /// 是否是身份证号
    public var fw_isFormatIdcard: Bool {
        return __FWBridge.isIdcard(self)
    }
    
    /// 是否是银行卡号
    public var fw_isFormatBankcard: Bool {
        return __FWBridge.isBankcard(self)
    }
    
    /// 是否是车牌号
    public var fw_isFormatCarno: Bool {
        // 车牌号:湘K-DE829 香港车牌号码:粤Z-J499港。\u4e00-\u9fa5表示unicode编码中汉字已编码部分，\u9fa5-\u9fff是保留部分
        return fw_isFormatRegex("^[\\u4e00-\\u9fff]{1}[a-zA-Z]{1}[-][a-zA-Z_0-9]{4}[a-zA-Z_0-9_\\u4e00-\\u9fff]$")
    }
    
    /// 是否是邮政编码
    public var fw_isFormatPostcode: Bool {
        return fw_isFormatRegex("^[0-8]\\d{5}(?!\\d)$")
    }
    
    /// 是否是邮箱
    public var fw_isFormatEmail: Bool {
        return fw_isFormatRegex("^[A-Z0-9a-z._\\%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$")
    }
    
    /// 是否是URL
    public var fw_isFormatUrl: Bool {
        return lowercased().hasPrefix("http://") || lowercased().hasPrefix("https://")
    }
    
    /// 是否是HTML
    public var fw_isFormatHtml: Bool {
        return range(of: "<[^>]+>", options: .regularExpression) != nil
    }
    
    /// 是否是IP
    public var fw_isFormatIp: Bool {
        // 简单版本
        // return fw_isFormatRegex("^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}$")
        
        // 复杂版本
        let components = self.components(separatedBy: ".")
        let invalidCharacters = CharacterSet(charactersIn: "1234567890").inverted
        
        if components.count == 4 {
            let part1 = components[0]
            let part2 = components[1]
            let part3 = components[2]
            let part4 = components[3]
            
            if part1.rangeOfCharacter(from: invalidCharacters) == nil &&
                part2.rangeOfCharacter(from: invalidCharacters) == nil &&
                part3.rangeOfCharacter(from: invalidCharacters) == nil &&
                part4.rangeOfCharacter(from: invalidCharacters) == nil {
                if (part1 as NSString).intValue < 255 &&
                    (part2 as NSString).intValue < 255 &&
                    (part3 as NSString).intValue < 255 &&
                    (part4 as NSString).intValue < 255 {
                    return true
                }
            }
        }
        return false
    }
    
    /// 是否全是中文
    public var fw_isFormatChinese: Bool {
        return fw_isFormatRegex("^[\\x{4e00}-\\x{9fa5}]+$")
    }
    
    /// 是否是合法时间，格式：yyyy-MM-dd HH:mm:ss
    public var fw_isFormatDatetime: Bool {
        return fw_isFormatRegex("^\\d{4}\\-\\d{2}\\-\\d{2}\\s\\d{2}\\:\\d{2}\\:\\d{2}$")
    }
    
    /// 是否是合法时间戳，格式：1301234567
    public var fw_isFormatTimestamp: Bool {
        return fw_isFormatRegex("^\\d{10}$")
    }
    
    /// 是否是坐标点字符串，格式：latitude,longitude
    public var fw_isFormatCoordinate: Bool {
        return fw_isFormatRegex("^\\-?\\d+\\.?\\d*,\\-?\\d+\\.?\\d*$")
    }
    
}

// MARK: - FileManager+Foundation
@_spi(FW) extension FileManager {
    
    /// 搜索路径
    ///
    /// - Parameter directory: 搜索目录
    /// - Returns: 目标路径
    public static func fw_pathSearch(_ directory: FileManager.SearchPathDirectory) -> String {
        return NSSearchPathForDirectoriesInDomains(directory, .userDomainMask, true)[0]
    }

    /// 沙盒路径，常量
    public static var fw_pathHome: String {
        return NSHomeDirectory()
    }

    /// 文档路径，iTunes会同步备份
    public static var fw_pathDocument: String {
        return fw_pathSearch(.documentDirectory)
    }

    /// 缓存路径，系统不会删除，iTunes会删除
    public static var fw_pathCaches: String {
        return fw_pathSearch(.cachesDirectory)
    }

    /// Library路径
    public static var fw_pathLibrary: String {
        return fw_pathSearch(.libraryDirectory)
    }

    /// 配置路径，配置文件保存位置
    public static var fw_pathPreference: String {
        return (fw_pathLibrary as NSString).appendingPathComponent("Preference")
    }

    /// 临时路径，App退出后可能会删除
    public static var fw_pathTmp: String {
        return NSTemporaryDirectory()
    }

    /// bundle路径，不可写
    public static var fw_pathBundle: String {
        return Bundle.main.bundlePath
    }

    /// 资源路径，不可写
    public static var fw_pathResource: String {
        return Bundle.main.resourcePath ?? ""
    }

    /// 获取目录大小，单位：B
    public static func fw_folderSize(_ folderPath: String) -> UInt64 {
        guard let contents = try? FileManager.default.contentsOfDirectory(atPath: folderPath) else {
            return 0
        }
        var folderSize: UInt64 = 0
        for file in contents {
            if let fileAttributes = try? FileManager.default.attributesOfItem(atPath: (folderPath as NSString).appendingPathComponent(file)),
               let sizeNumber = fileAttributes[.size] as? NSNumber {
                folderSize += sizeNumber.uint64Value
            }
        }
        return folderSize
    }
    
}

// MARK: - NSAttributedString+Foundation
/// 如果需要实现行内图片可点击效果，可使用UITextView添加附件或Link并实现delegate.shouldInteractWith方法即可。
/// 注意iOS在后台运行时，如果调用NSAttributedString解析html会导致崩溃(如动态切换深色模式时在后台解析html)。解决方法是提前在前台解析好或者后台异步到下一个主线程RunLoop
@_spi(FW) extension NSAttributedString {
    
    /// NSAttributedString对象转换为html字符串
    public func fw_htmlString() -> String? {
        let htmlData = try? self.data(
            from: NSMakeRange(0, self.length),
            documentAttributes: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ]
        )
        guard let htmlData = htmlData, !htmlData.isEmpty else { return nil }
        return String(data: htmlData, encoding: .utf8)
    }

    /// 计算所占尺寸，需设置Font等
    public var fw_textSize: CGSize {
        return fw_textSize(drawSize: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
    }

    /// 计算在指定绘制区域内所占尺寸，需设置Font等
    public func fw_textSize(drawSize: CGSize) -> CGSize {
        let size = self.boundingRect(with: drawSize, options: [.usesFontLeading, .usesLineFragmentOrigin], context: nil).size
        return CGSize(width: min(drawSize.width, ceil(size.width)), height: min(drawSize.height, ceil(size.height)))
    }
    
    /// html字符串转换为NSAttributedString对象。如需设置默认字体和颜色，请使用addAttributes方法或附加CSS样式
    public static func fw_attributedString(htmlString: String) -> Self? {
        let htmlData = htmlString.data(using: .utf8)
        guard let htmlData = htmlData, !htmlData.isEmpty else { return nil }
        
        return try? Self(
            data: htmlData,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
        )
    }

    /// 图片转换为NSAttributedString对象，可实现行内图片样式。其中bounds.x会设置为间距，y常用算法：(font.capHeight - image.size.height) / 2.0
    public static func fw_attributedString(image: UIImage?, bounds: CGRect) -> NSAttributedString {
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = image
        imageAttachment.bounds = CGRect(x: 0, y: bounds.origin.y, width: bounds.size.width, height: bounds.size.height)
        let imageString = NSAttributedString(attachment: imageAttachment)
        if bounds.origin.x <= 0 { return imageString }
        
        let attributedString = NSMutableAttributedString()
        let spacingAttachment = NSTextAttachment()
        spacingAttachment.image = nil
        spacingAttachment.bounds = CGRect(x: 0, y: bounds.origin.y, width: bounds.origin.x, height: bounds.size.height)
        attributedString.append(NSAttributedString(attachment: spacingAttachment))
        attributedString.append(imageString)
        return attributedString
    }
    
    /// 快速创建NSAttributedString并指定高亮部分文字和样式，链接设置NSLinkAttributeName|URL属性即可
    public static func fw_attributedString(string: String, attributes: [NSAttributedString.Key : Any]?, highlight: String, highlightAttributes: [NSAttributedString.Key : Any]?) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: string, attributes: attributes)
        let range = (string as NSString).range(of: highlight)
        if range.location != NSNotFound, let highlightAttributes = highlightAttributes {
            attributedString.addAttributes(highlightAttributes, range: range)
        }
        return attributedString
    }
    
    /// 快速创建NSAttributedString，自定义字体和颜色
    public static func fw_attributedString(_ string: String, font: UIFont?, textColor: UIColor? = nil) -> Self {
        var attributes: [NSAttributedString.Key: Any] = [:]
        if let font = font {
            attributes[.font] = font
        }
        if let textColor = textColor {
            attributes[.foregroundColor] = textColor
        }
        return Self(string: string, attributes: attributes)
    }
    
    /// html字符串转换为NSAttributedString对象，可设置默认系统字体和颜色(附加CSS方式)
    public static func fw_attributedString(htmlString string: String, defaultAttributes: [NSAttributedString.Key: Any]?) -> Self? {
        guard !string.isEmpty else { return nil }
        var htmlString = string
        if let attributes = defaultAttributes {
            var cssString = ""
            if let textColor = attributes[.foregroundColor] as? UIColor {
                cssString = cssString.appendingFormat("color:%@;", fw_cssString(color: textColor))
            }
            if let font = attributes[.font] as? UIFont {
                cssString = cssString.appending(fw_cssString(font: font))
            }
            if !cssString.isEmpty {
                htmlString = String(format: "<style type='text/css'>html{%@}</style>%@", cssString, htmlString)
            }
        }
        return fw_attributedString(htmlString: htmlString)
    }

    /// html字符串转换为NSAttributedString主题对象，可设置默认系统字体和动态颜色，详见ThemeObject
    public static func fw_themeObject(htmlString: String, defaultAttributes: [NSAttributedString.Key: Any]?) -> ThemeObject<NSAttributedString> {
        var lightAttributes: [NSAttributedString.Key: Any] = [:]
        var darkAttributes: [NSAttributedString.Key: Any] = [:]
        if let textColor = defaultAttributes?[.foregroundColor] as? UIColor {
            lightAttributes[.foregroundColor] = textColor.fw_color(forStyle: .light)
            darkAttributes[.foregroundColor] = textColor.fw_color(forStyle: .dark)
        }
        if let font = defaultAttributes?[.font] as? UIFont {
            lightAttributes[.font] = font
            darkAttributes[.font] = font
        }
        
        let lightObject = fw_attributedString(htmlString: htmlString, defaultAttributes: lightAttributes)
        let darkObject = fw_attributedString(htmlString: htmlString, defaultAttributes: darkAttributes)
        return ThemeObject(light: lightObject, dark: darkObject)
    }

    /// 获取颜色对应CSS字符串(rgb|rgba格式)
    public static func fw_cssString(color: UIColor) -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        if !color.getRed(&r, green: &g, blue: &b, alpha: &a) {
            if color.getWhite(&r, alpha: &a) {
                g = r
                b = r
            }
        }
        
        if a >= 1.0 {
            return String(format: "rgb(%u, %u, %u)", UInt(round(r * 255.0)), UInt(round(g * 255.0)), UInt(round(b * 255.0)))
        } else {
            return String(format: "rgba(%u, %u, %u, %g)", UInt(round(r * 255.0)), UInt(round(g * 255.0)), UInt(round(b * 255.0)), a)
        }
    }

    /// 获取系统字体对应CSS字符串(family|style|weight|size)
    public static func fw_cssString(font: UIFont) -> String {
        let fontWeights: [String: String] = [
            "ultralight": "100",
            "thin": "200",
            "light": "300",
            "medium": "500",
            "semibold": "600",
            "demibold": "600",
            "extrabold": "800",
            "ultrabold": "800",
            "bold": "700",
            "heavy": "900",
            "black": "900",
        ]
        
        let fontName = font.fontName.lowercased()
        var fontStyle = "normal"
        if fontName.range(of: "italic") != nil {
            fontStyle = "italic"
        } else if fontName.range(of: "oblique") != nil {
            fontStyle = "oblique"
        }
        
        var fontWeight = "400"
        for (key, value) in fontWeights {
            if fontName.range(of: key) != nil {
                fontWeight = value
                break
            }
        }
        
        return String(format: "font-family:-apple-system;font-weight:%@;font-style:%@;font-size:%.0fpx;", fontWeight, fontStyle, font.pointSize)
    }
    
}

// MARK: - NSObject+Foundation
@_spi(FW) extension NSObject {
    
    /// 执行加锁(支持任意对象)，等待信号量，自动创建信号量
    public func fw_lock() {
        fw_lockSemaphore.wait()
    }

    /// 执行解锁(支持任意对象)，发送信号量，自动创建信号量
    public func fw_unlock() {
        fw_lockSemaphore.signal()
    }
    
    private var fw_lockSemaphore: DispatchSemaphore {
        if let semaphore = fw_property(forName: "fw_lockSemaphore") as? DispatchSemaphore {
            return semaphore
        } else {
            var semaphore: DispatchSemaphore?
            fw_synchronized {
                semaphore = fw_property(forName: "fw_lockSemaphore") as? DispatchSemaphore
                if semaphore == nil {
                    semaphore = DispatchSemaphore(value: 1)
                    fw_setProperty(semaphore, forName: "fw_lockSemaphore")
                }
            }
            return semaphore!
        }
    }
    
    /// 通用互斥锁方法
    public static func fw_synchronized(_ closure: () -> Void) {
        objc_sync_enter(self)
        defer {
            objc_sync_exit(self)
        }
        
        closure()
    }
    
    /// 通用互斥锁方法
    public func fw_synchronized(_ closure: () -> Void) {
        objc_sync_enter(self)
        defer {
            objc_sync_exit(self)
        }
        
        closure()
    }
    
    /// 同一个token仅执行一次闭包，全局范围
    public static func fw_dispatchOnce(
        _ token: String,
        closure: @escaping () -> Void
    ) {
        objc_sync_enter(NSObject.self)
        defer {
            objc_sync_exit(NSObject.self)
        }
        
        guard !fw_staticTokens.contains(token) else { return }
        fw_staticTokens.append(token)
        closure()
    }
    
    private static var fw_staticTokens = [String]()
    
    /// 同一个token仅执行一次block，对象范围
    public func fw_dispatchOnce(
        _ token: String,
        closure: @escaping () -> Void
    ) {
        fw_synchronized {
            var tokens: NSMutableSet
            if let mutableSet = fw_property(forName: "fw_dispatchOnce") as? NSMutableSet {
                tokens = mutableSet
            } else {
                tokens = NSMutableSet()
                fw_setProperty(tokens, forName: "fw_dispatchOnce")
            }
            
            guard !tokens.contains(token) else { return }
            tokens.add(token)
            closure()
        }
    }
    
    /// 延迟delay秒后主线程执行，返回可取消的block，对象范围
    @discardableResult
    public func fw_performBlock(
        _ block: @escaping (Any) -> Void,
        afterDelay delay: TimeInterval
    ) -> Any {
        return fw_performBlock(block, on: .main, afterDelay: delay)
    }

    /// 延迟delay秒后后台线程执行，返回可取消的block，对象范围
    @discardableResult
    public func fw_performBlock(
        inBackground block: @escaping (Any) -> Void,
        afterDelay delay: TimeInterval
    ) -> Any {
        return fw_performBlock(block, on: .global(qos: .background), afterDelay: delay)
    }

    /// 延迟delay秒后指定线程执行，返回可取消的block，对象范围
    @discardableResult
    public func fw_performBlock(
        _ block: @escaping (Any) -> Void,
        on queue: DispatchQueue,
        afterDelay delay: TimeInterval
    ) -> Any {
        var cancelled = false
        let wrapper: (Bool) -> Void = { cancel in
            if cancel {
                cancelled = true
                return
            }
            if !cancelled {
                block(self)
            }
        }
        
        queue.asyncAfter(deadline: .now() + delay) {
            wrapper(false)
        }
        return wrapper
    }
    
    /// 延迟delay秒后主线程执行，返回可取消的block，全局范围
    @discardableResult
    public static func fw_performBlock(
        _ block: @escaping () -> Void,
        afterDelay delay: TimeInterval
    ) -> Any {
        return fw_performBlock(block, on: .main, afterDelay: delay)
    }

    /// 延迟delay秒后后台线程执行，返回可取消的block，全局范围
    @discardableResult
    public static func fw_performBlock(
        inBackground block: @escaping () -> Void,
        afterDelay delay: TimeInterval
    ) -> Any {
        return fw_performBlock(block, on: .global(qos: .background), afterDelay: delay)
    }

    /// 延迟delay秒后指定线程执行，返回可取消的block，全局范围
    @discardableResult
    public static func fw_performBlock(
        _ block: @escaping () -> Void,
        on queue: DispatchQueue,
        afterDelay delay: TimeInterval
    ) -> Any {
        var cancelled = false
        let wrapper: (Bool) -> Void = { cancel in
            if cancel {
                cancelled = true
                return
            }
            if !cancelled {
                block()
            }
        }
        
        queue.asyncAfter(deadline: .now() + delay) {
            wrapper(false)
        }
        return wrapper
    }

    /// 取消指定延迟block，全局范围
    public static func fw_cancelBlock(_ block: Any) {
        let wrapper = block as? (Bool) -> Void
        wrapper?(true)
    }

    /// 同步方式执行异步block，阻塞当前线程(信号量)，异步block必须调用completionHandler，全局范围
    public static func fw_syncPerform(
        asyncBlock: @escaping (@escaping () -> Void) -> Void
    ) {
        // 使用信号量阻塞当前线程，等待block执行结果
        let semaphore = DispatchSemaphore(value: 0)
        let completionHandler: () -> Void = {
            semaphore.signal()
        }
        asyncBlock(completionHandler)
        semaphore.wait()
    }

    /// 重试方式执行异步block，直至成功或者次数为0或者超时，完成后回调completion。block必须调用completionHandler，参数示例：重试4次|超时8秒|延迟2秒
    public static func fw_performBlock(
        _ block: @escaping (@escaping (Bool, Any?) -> Void) -> Void,
        completion: @escaping (Bool, Any?) -> Void,
        retryCount: Int,
        timeoutInterval: TimeInterval,
        delayInterval: TimeInterval
    ) {
        let startTime = Date().timeIntervalSince1970
        fw_performBlock(block, completion: completion, retryCount: retryCount, timeoutInterval: timeoutInterval, delayInterval: delayInterval, startTime: startTime)
    }
    
    private static func fw_performBlock(
        _ block: @escaping (@escaping (Bool, Any?) -> Void) -> Void,
        completion: @escaping (Bool, Any?) -> Void,
        retryCount: Int,
        timeoutInterval: TimeInterval,
        delayInterval: TimeInterval,
        startTime: TimeInterval
    ) {
        block({ success, obj in
            if !success && retryCount > 0 && (timeoutInterval <= 0 || (Date().timeIntervalSince1970 - startTime) < timeoutInterval) {
                DispatchQueue.main.asyncAfter(deadline: .now() + delayInterval) {
                    NSObject.fw_performBlock(block, completion: completion, retryCount: retryCount - 1, timeoutInterval: timeoutInterval, delayInterval: delayInterval, startTime: startTime)
                }
            } else {
                completion(success, obj)
            }
        })
    }

    /// 执行轮询block任务，返回任务Id可取消
    @discardableResult
    public static func fw_performTask(_ task: @escaping () -> Void, start: TimeInterval, interval: TimeInterval, repeats: Bool, async: Bool) -> String {
        let queue: DispatchQueue = async ? .global() : .main
        let timer = DispatchSource.makeTimerSource(flags: [], queue: queue)
        timer.schedule(deadline: .now() + start, repeating: interval, leeway: .seconds(0))
        
        fw_staticSemaphore.wait()
        let taskId = "\(fw_staticTasks.count)"
        fw_staticTasks[taskId] = timer
        fw_staticSemaphore.signal()
        
        timer.setEventHandler {
            task()
            if !repeats {
                NSObject.fw_cancelTask(taskId)
            }
        }
        timer.resume()
        return taskId
    }

    /// 指定任务Id取消轮询任务
    public static func fw_cancelTask(_ taskId: String) {
        guard !taskId.isEmpty else { return }
        fw_staticSemaphore.wait()
        if let timer = fw_staticTasks[taskId] as? DispatchSourceTimer {
            timer.cancel()
            fw_staticTasks.removeObject(forKey: taskId)
        }
        fw_staticSemaphore.signal()
    }
    
    private static var fw_staticTasks = NSMutableDictionary()
    private static var fw_staticSemaphore = DispatchSemaphore(value: 1)
    
}

// MARK: - URL+Foundation
/// 第三方URL生成器，可先判断canOpenURL，再openURL，需添加对应URL SCHEME到LSApplicationQueriesSchemes配置数组
@_spi(FW) extension URL {

    /**
     生成苹果地图地址外部URL
     
     @param addr 显示地址，格式latitude,longitude或搜索地址
     @param options 可选附加参数，如@{@"ll": @"latitude,longitude", @"z": @"14"}
     @return NSURL
     */
    public static func fw_appleMapsURL(withAddr addr: String?, options: [AnyHashable : Any]? = nil) -> URL? {
        var params = options ?? [:]
        if let addr = addr, !addr.isEmpty {
            params["q"] = addr
        }
        return fw_vendorURL("http://maps.apple.com/", params: params)
    }

    /**
     生成苹果地图导航外部URL
     
     @param saddr 导航起始点，格式latitude,longitude或搜索地址
     @param daddr 导航结束点，格式latitude,longitude或搜索地址
     @param options 可选附加参数，如@{@"ll": @"latitude,longitude", @"z": @"14"}
     @return NSURL
     */
    public static func fw_appleMapsURL(withSaddr saddr: String?, daddr: String?, options: [AnyHashable : Any]? = nil) -> URL? {
        var params = options ?? [:]
        if let saddr = saddr, !saddr.isEmpty {
            params["saddr"] = saddr
        }
        if let daddr = daddr, !daddr.isEmpty {
            params["daddr"] = daddr
        }
        return fw_vendorURL("http://maps.apple.com/", params: params)
    }

    /**
     生成谷歌地图外部URL，URL SCHEME为：comgooglemaps
     
     @param addr 显示地址，格式latitude,longitude或搜索地址
     @param options 可选附加参数，如@{@"center": @"latitude,longitude", @"zoom": @"14"}
     @return NSURL
     */
    public static func fw_googleMapsURL(withAddr addr: String?, options: [AnyHashable : Any]? = nil) -> URL? {
        var params = options ?? [:]
        if let addr = addr, !addr.isEmpty {
            params["q"] = addr
        }
        return fw_vendorURL("comgooglemaps://", params: params)
    }

    /**
     生成谷歌地图导航外部URL，URL SCHEME为：comgooglemaps
     
     @param saddr 导航起始点，格式latitude,longitude或搜索地址
     @param daddr 导航结束点，格式latitude,longitude或搜索地址
     @param mode 导航模式，支持driving|transit|bicycling|walking，默认driving
     @param options 可选附加参数，如@{@"center": @"latitude,longitude", @"zoom": @"14", @"dirflg": @"t,h"}
     @return NSURL
     */
    public static func fw_googleMapsURL(withSaddr saddr: String?, daddr: String?, mode: String? = nil, options: [AnyHashable : Any]? = nil) -> URL? {
        var params = options ?? [:]
        if let saddr = saddr, !saddr.isEmpty {
            params["saddr"] = saddr
        }
        if let daddr = daddr, !daddr.isEmpty {
            params["daddr"] = daddr
        }
        var directionsmode = "driving"
        if let mode = mode, !mode.isEmpty {
            directionsmode = mode
        }
        params["directionsmode"] = directionsmode
        return fw_vendorURL("comgooglemaps://", params: params)
    }

    /**
     生成百度地图外部URL，URL SCHEME为：baidumap
     
     @param addr 显示地址，格式latitude,longitude或搜索地址
     @param options 可选附加参数，如@{@"src": @"app", @"zoom": @"14", @"coord_type": @"默认gcj02|wgs84|bd09ll"}
     @return NSURL
     */
    public static func fw_baiduMapsURL(withAddr addr: String?, options: [AnyHashable : Any]? = nil) -> URL? {
        var params = options ?? [:]
        if let addr = addr, !addr.isEmpty {
            if addr.fw_isFormatCoordinate {
                params["location"] = addr
            } else {
                params["address"] = addr
            }
        }
        if params["coord_type"] == nil {
            params["coord_type"] = "gcj02"
        }
        if params["src"] == nil {
            params["src"] = Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier")
        }
        return fw_vendorURL("baidumap://map/geocoder", params: params)
    }

    /**
     生成百度地图导航外部URL，URL SCHEME为：baidumap
     
     @param saddr 导航起始点，格式latitude,longitude或搜索地址
     @param daddr 导航结束点，格式latitude,longitude或搜索地址
     @param mode 导航模式，支持driving|transit|navigation|riding|walking，默认driving
     @param options 可选附加参数，如@{@"src": @"app", @"zoom": @"14", @"coord_type": @"默认gcj02|wgs84|bd09ll"}
     @return NSURL
     */
    public static func fw_baiduMapsURL(withSaddr saddr: String?, daddr: String?, mode: String? = nil, options: [AnyHashable : Any]? = nil) -> URL? {
        var params = options ?? [:]
        if let saddr = saddr, !saddr.isEmpty {
            params["origin"] = saddr
        }
        if let daddr = daddr, !daddr.isEmpty {
            params["destination"] = daddr
        }
        var directionsmode = "driving"
        if let mode = mode, !mode.isEmpty {
            directionsmode = mode
        }
        params["mode"] = directionsmode
        if params["coord_type"] == nil {
            params["coord_type"] = "gcj02"
        }
        if params["src"] == nil {
            params["src"] = Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier")
        }
        return fw_vendorURL("baidumap://map/direction", params: params)
    }
    
    /**
     生成外部URL，需配置对应URL SCHEME
     
     @param string 外部主URL
     @param params 附加参数
     @return NSURL
     */
    public static func fw_vendorURL(_ string: String, params: [AnyHashable: Any]? = nil) -> URL? {
        var urlString = string + "?"
        let urlParams = params ?? [:]
        for (key, value) in urlParams {
            let valueStr = String.fw_safeString(value)
                .replacingOccurrences(of: " ", with: "+")
                .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            urlString += "\(String.fw_safeString(key))=\(valueStr ?? "")&"
        }
        return URL(string: urlString.fw_substring(to: urlString.count - 1))
    }
    
}

// MARK: - UserDefaults+Foundation
@_spi(FW) extension URLSession {
    
    /// 是否禁止网络代理抓包，不影响App请求，默认false
    public static var fw_httpProxyDisabled = false {
        didSet {
            if fw_httpProxyDisabled {
                fw_swizzleHttpProxy()
            }
        }
    }
    
    /// 获取手机网络代理，可能为空
    public static var fw_httpProxyString: String? {
        let proxy = CFNetworkCopySystemProxySettings()?.takeUnretainedValue() as? [AnyHashable: Any]
        return proxy?[kCFNetworkProxiesHTTPProxy as String] as? String
    }
    
    /// 获取host在本地DNS的IP地址，可实现防DNS劫持，建议后台调用
    ///
    /// 方案说明：
    /// 1. NSURLProtocol注册全局请求拦截器类
    /// 2. canonicalRequest方法中检查请求URL是否是合法IP格式
    /// 3. 如果不满足，获取本地DNS的IP地址添加到请求Header的host以便区分
    /// [ZXRequestBlock](https://github.com/SmileZXLee/ZXRequestBlock)
    public static func fw_ipAddress(host: String) -> String? {
        return __FWBridge.ipAddress(host)
    }
    
    private static var fw_staticHttpProxySwizzled = false
    
    private static func fw_swizzleHttpProxy() {
        guard !fw_staticHttpProxySwizzled else { return }
        fw_staticHttpProxySwizzled = true
        
        NSObject.fw_swizzleClassMethod(
            URLSession.self,
            selector: #selector(URLSession.init(configuration:)),
            methodSignature: (@convention(c) (URLSession, Selector, URLSessionConfiguration) -> URLSession).self,
            swizzleSignature: (@convention(block) (URLSession, URLSessionConfiguration) -> URLSession).self
        ) { store in { selfObject, configuration in
            if fw_httpProxyDisabled {
                configuration.connectionProxyDictionary = [:]
            }
            return store.original(selfObject, store.selector, configuration)
        }}
        
        NSObject.fw_swizzleClassMethod(
            URLSession.self,
            selector: #selector(URLSession.init(configuration:delegate:delegateQueue:)),
            methodSignature: (@convention(c) (URLSession, Selector, URLSessionConfiguration, URLSessionDelegate?, OperationQueue?) -> URLSession).self,
            swizzleSignature: (@convention(block) (URLSession, URLSessionConfiguration, URLSessionDelegate?, OperationQueue?) -> URLSession).self
        ) { store in { selfObject, configuration, delegate, delegateQueue in
            if fw_httpProxyDisabled {
                configuration.connectionProxyDictionary = [:]
            }
            return store.original(selfObject, store.selector, configuration, delegate, delegateQueue)
        }}
    }
    
}

// MARK: - UserDefaults+Foundation
@_spi(FW) extension UserDefaults {
    
    /// 从standard读取对象，支持unarchive对象
    public static func fw_object(forKey: String) -> Any? {
        return UserDefaults.standard.object(forKey: forKey)
    }

    /// 保存对象到standard，支持archive对象
    public static func fw_setObject(_ object: Any?, forKey: String) {
        if let object = object {
            UserDefaults.standard.set(object, forKey: forKey)
        } else {
            UserDefaults.standard.removeObject(forKey: forKey)
        }
        UserDefaults.standard.synchronize()
    }
    
    /// 读取对象，支持unarchive对象
    public func fw_object(forKey: String) -> Any? {
        return self.object(forKey: forKey)
    }

    /// 保存对象，支持archive对象
    public func fw_setObject(_ object: Any?, forKey: String) {
        if let object = object {
            self.set(object, forKey: forKey)
        } else {
            self.removeObject(forKey: forKey)
        }
        self.synchronize()
    }
    
}
