//
//  Bridge.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/20.
//

import UIKit

@_spi(FW) @objc extension NSData {
    
    /// 使用NSKeyedArchiver压缩对象
    public static func fw_archiveObject(_ object: Any) -> Data? {
        return Data.fw_archiveObject(object)
    }
    
    /// 使用NSKeyedUnarchiver解压数据
    public func fw_unarchiveObject(_ clazz: AnyClass) -> Any? {
        return __unarchiveObject(clazz)
    }
    
    /// 保存对象归档
    public static func fw_archiveObject(_ object: Any, file: String) -> Bool {
        return Data.fw_archiveObject(object, file: file)
    }
    
    /// 读取对象归档
    public static func fw_unarchiveObject(_ clazz: AnyClass, file: String) -> Any? {
        guard let data = NSData(contentsOfFile: file) else { return nil }
        return data.fw_unarchiveObject(clazz)
    }
    
    // MARK: - Encrypt
    /// 利用AES加密数据
    public func fw_aesEncrypt(key: String, iv: Data) -> Data? {
        return (self as Data).fw_aesEncrypt(key: key, iv: iv)
    }

    /// 利用AES解密数据
    public func fw_aesDecrypt(key: String, iv: Data) -> Data? {
        return (self as Data).fw_aesDecrypt(key: key, iv: iv)
    }

    /// 利用3DES加密数据
    public func fw_des3Encrypt(key: String, iv: Data) -> Data? {
        return (self as Data).fw_des3Encrypt(key: key, iv: iv)
    }

    /// 利用3DES解密数据
    public func fw_des3Decrypt(key: String, iv: Data) -> Data? {
        return (self as Data).fw_des3Decrypt(key: key, iv: iv)
    }

    // MARK: - RSA
    /// RSA公钥加密，数据传输安全，使用默认标签，执行base64编码
    public func fw_rsaEncrypt(publicKey: String) -> Data? {
        return (self as Data).fw_rsaEncrypt(publicKey: publicKey)
    }

    /// RSA公钥加密，数据传输安全，可自定义标签，指定base64编码
    public func fw_rsaEncrypt(publicKey: String, tag: String, base64Encode: Bool) -> Data? {
        return (self as Data).fw_rsaEncrypt(publicKey: publicKey, tag: tag, base64Encode: base64Encode)
    }

    /// RSA私钥解密，数据传输安全，使用默认标签，执行base64解密
    public func fw_rsaDecrypt(privateKey: String) -> Data? {
        return (self as Data).fw_rsaDecrypt(privateKey: privateKey)
    }

    /// RSA私钥解密，数据传输安全，可自定义标签，指定base64解码
    public func fw_rsaDecrypt(privateKey: String, tag: String, base64Decode: Bool) -> Data? {
        return (self as Data).fw_rsaDecrypt(privateKey: privateKey, tag: tag, base64Decode: base64Decode)
    }

    /// RSA私钥加签，防篡改防否认，使用默认标签，执行base64编码
    public func fw_rsaSign(privateKey: String) -> Data? {
        return (self as Data).fw_rsaSign(privateKey: privateKey)
    }

    /// RSA私钥加签，防篡改防否认，可自定义标签，指定base64编码
    public func fw_rsaSign(privateKey: String, tag: String, base64Encode: Bool) -> Data? {
        return (self as Data).fw_rsaSign(privateKey: privateKey, tag: tag, base64Encode: base64Encode)
    }

    /// RSA公钥验签，防篡改防否认，使用默认标签，执行base64解密
    public func fw_rsaVerify(publicKey: String) -> Data? {
        return (self as Data).fw_rsaVerify(publicKey: publicKey)
    }

    /// RSA公钥验签，防篡改防否认，可自定义标签，指定base64解码
    public func fw_rsaVerify(publicKey: String, tag: String, base64Decode: Bool) -> Data? {
        return (self as Data).fw_rsaVerify(publicKey: publicKey, tag: tag, base64Decode: base64Decode)
    }
    
}

@_spi(FW) @objc extension NSDate {
    
    /// 当前时间戳，没有设置过返回本地时间戳，可同步设置服务器时间戳，同步后调整手机时间不影响
    public static var fw_currentTime: TimeInterval {
        get { Date.fw_currentTime }
        set { Date.fw_currentTime = newValue }
    }
    
    /// 从字符串初始化日期，自定义格式(默认yyyy-MM-dd HH:mm:ss)和时区(默认当前时区)
    public static func fw_date(string: String, format: String = "yyyy-MM-dd HH:mm:ss", timeZone: TimeZone? = nil) -> Date? {
        return Date.fw_date(string: string, format: format, timeZone: timeZone)
    }
    
    /// 转化为字符串，默认当前时区，格式：yyyy-MM-dd HH:mm:ss
    public var fw_stringValue: String {
        return (self as Date).fw_stringValue
    }
    
    /// 转化为字符串，自定义格式和时区
    public func fw_string(format: String, timeZone: TimeZone? = nil) -> String {
        return (self as Date).fw_string(format: format, timeZone: timeZone)
    }
    
    /// 格式化时长，格式"00:00"或"00:00:00"
    public static func fw_formatDuration(_ duration: TimeInterval, hasHour: Bool) -> String {
        return Date.fw_formatDuration(duration, hasHour: hasHour)
    }
    
    /// 格式化16位、13位时间戳为10位(秒)
    public static func fw_formatTimestamp(_ timestamp: TimeInterval) -> TimeInterval {
        return Date.fw_formatTimestamp(timestamp)
    }
    
    /// 是否是闰年
    public var fw_isLeapYear: Bool {
        return (self as Date).fw_isLeapYear
    }

    /// 是否是同一天
    public func fw_isSameDay(_ date: Date) -> Bool {
        return (self as Date).fw_isSameDay(date)
    }

    /// 添加指定日期，如year:1|month:-1|day:1等
    public func fw_date(byAdding: DateComponents) -> Date? {
        return (self as Date).fw_date(byAdding: byAdding)
    }

    /// 与指定日期相隔天数
    public func fw_days(from date: Date) -> Int {
        return (self as Date).fw_days(from: date)
    }
    
}

@_spi(FW) @objc extension NSString {
    
    /// 计算多行字符串指定字体、指定属性在指定绘制区域内所占尺寸
    public func fw_size(font: UIFont, drawSize: CGSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude), attributes: [NSAttributedString.Key: Any]? = nil) -> CGSize {
        return (self as String).fw_size(font: font, drawSize: drawSize, attributes: attributes)
    }
    
    /// 格式化文件大小为".0K/.1M/.1G"
    public static func fw_sizeString(_ aFileSize: UInt) -> String {
        return String.fw_sizeString(aFileSize)
    }
    
    /// 是否匹配正则表达式，示例：^[a-zA-Z0-9_\u4e00-\u9fa5]{4,14}$
    public func fw_matchesRegex(_ regex: String) -> Bool {
        return (self as String).fw_matchesRegex(regex)
    }
    
    /**
     *  安全截取字符串。解决末尾半个Emoji问题(半个Emoji调UTF8String为NULL，导致MD5签名等失败)
     *
     *  @param index 目标索引
     */
    public func fw_emojiSubstring(_ index: Int) -> String {
        return (self as String).fw_emojiSubstring(index)
    }

    /**
     *  正则搜索子串
     *
     *  @param regex 正则表达式
     */
    public func fw_regexSubstring(_ regex: String) -> String? {
        return (self as String).fw_regexSubstring(regex)
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
        return (self as String).fw_regexReplace(regex, string: string)
    }

    /**
     *  正则匹配回调
     *
     *  @param regex 正则表达式
     *  @param block 回调句柄。range从大至小，方便replace
     */
    public func fw_regexMatches(_ regex: String, block: @escaping (NSRange) -> Void) {
        return (self as String).fw_regexMatches(regex, block: block)
    }
    
    /// 转义Html，如"a<"转义为"a&lt;"
    public var fw_escapeHtml: String {
        return (self as String).fw_escapeHtml
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
        return (self as String).fw_isFormatRegex(regex)
    }

    /// 是否是手机号
    public var fw_isFormatMobile: Bool {
        return (self as String).fw_isFormatMobile
    }

    /// 是否是座机号
    public var fw_isFormatTelephone: Bool {
        return (self as String).fw_isFormatTelephone
    }
    
    /// 是否是整数
    public var fw_isFormatInteger: Bool {
        return (self as String).fw_isFormatInteger
    }
    
    /// 是否是数字
    public var fw_isFormatNumber: Bool {
        return (self as String).fw_isFormatNumber
    }
    
    /// 是否是合法金额，两位小数点
    public var fw_isFormatMoney: Bool {
        return (self as String).fw_isFormatMoney
    }
    
    /// 是否是身份证号
    public var fw_isFormatIdcard: Bool {
        return (self as String).fw_isFormatIdcard
    }
    
    /// 是否是银行卡号
    public var fw_isFormatBankcard: Bool {
        return (self as String).fw_isFormatBankcard
    }
    
    /// 是否是车牌号
    public var fw_isFormatCarno: Bool {
        return (self as String).fw_isFormatCarno
    }
    
    /// 是否是邮政编码
    public var fw_isFormatPostcode: Bool {
        return (self as String).fw_isFormatPostcode
    }
    
    /// 是否是邮箱
    public var fw_isFormatEmail: Bool {
        return (self as String).fw_isFormatEmail
    }
    
    /// 是否是URL
    public var fw_isFormatUrl: Bool {
        return (self as String).fw_isFormatUrl
    }
    
    /// 是否是HTML
    public var fw_isFormatHtml: Bool {
        return (self as String).fw_isFormatHtml
    }
    
    /// 是否是IP
    public var fw_isFormatIp: Bool {
        return (self as String).fw_isFormatIp
    }
    
    /// 是否全是中文
    public var fw_isFormatChinese: Bool {
        return (self as String).fw_isFormatChinese
    }
    
    /// 是否是合法时间，格式：yyyy-MM-dd HH:mm:ss
    public var fw_isFormatDatetime: Bool {
        return (self as String).fw_isFormatDatetime
    }
    
    /// 是否是合法时间戳，格式：1301234567
    public var fw_isFormatTimestamp: Bool {
        return (self as String).fw_isFormatTimestamp
    }
    
    /// 是否是坐标点字符串，格式：latitude,longitude
    public var fw_isFormatCoordinate: Bool {
        return (self as String).fw_isFormatCoordinate
    }
    
}

@_spi(FW) @objc extension NSURL {
    
    /**
     生成苹果地图地址外部URL
     
     @param addr 显示地址，格式latitude,longitude或搜索地址
     @param options 可选附加参数，如@{@"ll": @"latitude,longitude", @"z": @"14"}
     @return NSURL
     */
    public static func fw_appleMapsURL(withAddr addr: String?, options: [AnyHashable : Any]? = nil) -> URL? {
        return URL.fw_appleMapsURL(withAddr: addr, options: options)
    }

    /**
     生成苹果地图导航外部URL
     
     @param saddr 导航起始点，格式latitude,longitude或搜索地址
     @param daddr 导航结束点，格式latitude,longitude或搜索地址
     @param options 可选附加参数，如@{@"ll": @"latitude,longitude", @"z": @"14"}
     @return NSURL
     */
    public static func fw_appleMapsURL(withSaddr saddr: String?, daddr: String?, options: [AnyHashable : Any]? = nil) -> URL? {
        return URL.fw_appleMapsURL(withSaddr: saddr, daddr: daddr, options: options)
    }

    /**
     生成谷歌地图外部URL，URL SCHEME为：comgooglemaps
     
     @param addr 显示地址，格式latitude,longitude或搜索地址
     @param options 可选附加参数，如@{@"center": @"latitude,longitude", @"zoom": @"14"}
     @return NSURL
     */
    public static func fw_googleMapsURL(withAddr addr: String?, options: [AnyHashable : Any]? = nil) -> URL? {
        return URL.fw_googleMapsURL(withAddr: addr, options: options)
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
        return URL.fw_googleMapsURL(withSaddr: saddr, daddr: daddr, mode: mode, options: options)
    }

    /**
     生成百度地图外部URL，URL SCHEME为：baidumap
     
     @param addr 显示地址，格式latitude,longitude或搜索地址
     @param options 可选附加参数，如@{@"src": @"app", @"zoom": @"14", @"coord_type": @"默认gcj02|wgs84|bd09ll"}
     @return NSURL
     */
    public static func fw_baiduMapsURL(withAddr addr: String?, options: [AnyHashable : Any]? = nil) -> URL? {
        return URL.fw_baiduMapsURL(withAddr: addr, options: options)
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
        return URL.fw_baiduMapsURL(withSaddr: saddr, daddr: daddr, mode: mode, options: options)
    }
    
    /**
     生成外部URL，需配置对应URL SCHEME
     
     @param string 外部主URL
     @param params 附加参数
     @return NSURL
     */
    public static func fw_vendorURL(_ string: String, params: [AnyHashable: Any]? = nil) -> URL? {
        return URL.fw_vendorURL(string, params: params)
    }
    
}
