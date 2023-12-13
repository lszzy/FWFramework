//
//  Foundation.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit
import CommonCrypto

// MARK: - AnyObject+Foundation
@_spi(FW) extension WrapperCompatible where Self: AnyObject {
    
    /// 执行加锁(支持任意对象)，等待信号量，自动创建信号量
    public func fw_lock() {
        fw_lockSemaphore.wait()
    }

    /// 执行解锁(支持任意对象)，发送信号量，自动创建信号量
    public func fw_unlock() {
        fw_lockSemaphore.signal()
    }
    
    private var fw_lockSemaphore: DispatchSemaphore {
        return fw_synchronized {
            if let semaphore = fw_property(forName: #function) as? DispatchSemaphore {
                return semaphore
            } else {
                let semaphore = DispatchSemaphore(value: 1)
                fw_setProperty(semaphore, forName: #function)
                return semaphore
            }
        }
    }
    
    /// 延迟创建队列，默认串行队列
    public var fw_queue: DispatchQueue {
        get {
            return fw_synchronized {
                if let queue = fw_property(forName: #function) as? DispatchQueue {
                    return queue
                } else {
                    let queue = DispatchQueue(label: #function)
                    fw_setProperty(queue, forName: #function)
                    return queue
                }
            }
        }
        set {
            fw_synchronized {
                fw_setProperty(newValue, forName: #function)
            }
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
    
    /// 通用互斥锁方法，返回指定对象
    public static func fw_synchronized<T>(_ closure: () -> T) -> T {
        objc_sync_enter(self)
        defer {
            objc_sync_exit(self)
        }
        
        return closure()
    }
    
    /// 通用互斥锁方法
    public func fw_synchronized(_ closure: () -> Void) {
        objc_sync_enter(self)
        defer {
            objc_sync_exit(self)
        }
        
        closure()
    }
    
    /// 通用互斥锁方法，返回指定对象
    public func fw_synchronized<T>(_ closure: () -> T) -> T {
        objc_sync_enter(self)
        defer {
            objc_sync_exit(self)
        }
        
        return closure()
    }
    
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
    
}

// MARK: - NSObject+Foundation
@_spi(FW) extension NSObject {
    
    /// 同一个token仅执行一次闭包，全局范围
    public static func fw_dispatchOnce(
        _ token: AnyHashable,
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
    
    private static var fw_staticTokens = [AnyHashable]()
    
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

    /// 重试方式执行异步block，直至成功或者次数为0(小于0不限)或者超时(小于等于0不限)，完成后回调completion。block必须调用completionHandler，参数示例：重试4次|超时8秒|延迟2秒
    public static func fw_performBlock(
        _ block: @escaping (@escaping (Bool, Any?) -> Void) -> Void,
        completion: @escaping (Bool, Any?) -> Void,
        retryCount: Int,
        timeoutInterval: TimeInterval,
        delayInterval: @escaping (Int) -> TimeInterval,
        isCancelled: (() -> Bool)? = nil
    ) {
        let startTime = Date().timeIntervalSince1970
        fw_performBlock(block, completion: completion, retryCount: retryCount, remainCount: retryCount, timeoutInterval: timeoutInterval, delayInterval: delayInterval, isCancelled: isCancelled, startTime: startTime)
    }
    
    private static func fw_performBlock(
        _ block: @escaping (@escaping (Bool, Any?) -> Void) -> Void,
        completion: @escaping (Bool, Any?) -> Void,
        retryCount: Int,
        remainCount: Int,
        timeoutInterval: TimeInterval,
        delayInterval: @escaping (Int) -> TimeInterval,
        isCancelled: (() -> Bool)?,
        startTime: TimeInterval
    ) {
        if isCancelled?() ?? false { return }
        block({ success, obj in
            if isCancelled?() ?? false { return }
            let canRetry = !success && (retryCount < 0 || remainCount > 0)
            let waitTime = canRetry ? delayInterval(retryCount - remainCount + 1) : 0
            if canRetry && (timeoutInterval <= 0 || (Date().timeIntervalSince1970 - startTime + waitTime) < timeoutInterval) {
                DispatchQueue.main.asyncAfter(deadline: .now() + waitTime) {
                    NSObject.fw_performBlock(block, completion: completion, retryCount: retryCount, remainCount: remainCount - 1, timeoutInterval: timeoutInterval, delayInterval: delayInterval, isCancelled: isCancelled, startTime: startTime)
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
                let offsetTime = fw_systemUptime - fw_staticLocalBaseTime
                return fw_staticCurrentBaseTime + offsetTime
            }
        }
        set {
            fw_staticCurrentBaseTime = newValue
            // 取运行时间，调整系统时间不会影响
            fw_staticLocalBaseTime = fw_systemUptime
            
            // 保存当前服务器时间到本地
            UserDefaults.standard.set(NSNumber(value: newValue), forKey: "FWCurrentTime")
            UserDefaults.standard.set(NSNumber(value: Date().timeIntervalSince1970), forKey: "FWLocalTime")
            UserDefaults.standard.synchronize()
        }
    }
    
    private static var fw_systemUptime: TimeInterval {
        var bootTime = timeval()
        var mib = [CTL_KERN, KERN_BOOTTIME]
        var size = MemoryLayout<timeval>.stride
        let resctl = sysctl(&mib, 2, &bootTime, &size, nil, 0)

        var now = timeval()
        var tz = timezone()
        gettimeofday(&now, &tz)

        var uptime: TimeInterval = 0
        if resctl != -1 && bootTime.tv_sec != 0 {
            uptime = Double(now.tv_sec - bootTime.tv_sec)
            uptime += Double(now.tv_usec - bootTime.tv_usec) / 1e6
        }
        return uptime
    }
    
    private static var fw_staticCurrentBaseTime: TimeInterval = 0
    private static var fw_staticLocalBaseTime: TimeInterval = 0
    
    /// 通用DateFormatter对象，默认系统时区，使用时需先指定dateFormat，可自定义
    public static var fw_dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        return formatter
    }()
    
    /// 从字符串初始化日期，自定义格式(默认yyyy-MM-dd HH:mm:ss)
    public static func fw_date(string: String, format: String = "yyyy-MM-dd HH:mm:ss") -> Date? {
        let formatter = fw_dateFormatter
        formatter.dateFormat = format
        let date = formatter.date(from: string)
        return date
    }
    
    /// 转化为字符串，格式：yyyy-MM-dd HH:mm:ss
    public var fw_stringValue: String {
        return fw_string(format: "yyyy-MM-dd HH:mm:ss")
    }
    
    /// 转化为字符串，自定义格式
    public func fw_string(format: String) -> String {
        let formatter = Date.fw_dateFormatter
        formatter.dateFormat = format
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
    
    /// 解析服务器时间戳，参数为接口响应Header的Date字段，解析失败返回0
    public static func fw_formatServerDate(_ dateString: String) -> TimeInterval {
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
    
    /// 快捷创建NumberFormatter对象，默认numberStyle为decimal
    /// - Parameters:
    ///   - digit: 保留小数位数，默认2，示例：1234.5678 => 1234.57
    ///   - roundingMode: 取整模式，默认四舍五入，示例：1234.5678 => 1234.57
    ///   - fractionZero: 是否保留小数末尾0(示例：1234.5012 => 1234.50)，默认false去掉末尾0(示例：1234.5012 => 1234.5)
    ///   - groupingSeparator: 分组分隔符，默认为空，示例：1234.5678 => 1,234.57
    ///   - currencySymbol: 货币符号，默认为空，指定后numberStyle为currency，示例：1234.5678 => $1234.57
    /// - Returns: NumberFormatter对象
    public static func fw_numberFormatter(
        _ digit: Int = 2,
        roundingMode: NumberFormatter.RoundingMode = .halfUp,
        fractionZero: Bool = false,
        groupingSeparator: String = "",
        currencySymbol: String = ""
    ) -> NumberFormatter {
        let formatter = NumberFormatter()
        if !currencySymbol.isEmpty {
            formatter.numberStyle = .currency
            formatter.currencySymbol = currencySymbol
        } else {
            formatter.numberStyle = .decimal
        }
        formatter.roundingMode = roundingMode
        formatter.minimumIntegerDigits = 1
        formatter.maximumFractionDigits = digit
        formatter.minimumFractionDigits = fractionZero ? digit : 0
        formatter.decimalSeparator = "."
        formatter.currencyDecimalSeparator = "."
        formatter.usesGroupingSeparator = !groupingSeparator.isEmpty
        formatter.groupingSeparator = groupingSeparator
        formatter.currencyGroupingSeparator = groupingSeparator
        return formatter
    }

    /// 快捷四舍五入格式化为字符串，默认numberStyle为decimal
    /// - Parameters:
    ///   - digit: 保留小数位数，默认2，示例：1234.5678 => 1234.57
    ///   - fractionZero: 是否保留小数末尾0(示例：1234.5012 => 1234.50)，默认false去掉末尾0(示例：1234.5012 => 1234.5)
    ///   - groupingSeparator: 分组分隔符，默认为空，示例：1234.5678 => 1,234.57
    ///   - currencySymbol: 货币符号，默认为空，指定后numberStyle为currency，示例：1234.5678 => $1234.57
    /// - Returns: 格式化字符串
    public func fw_roundString(
        _ digit: Int = 2,
        fractionZero: Bool = false,
        groupingSeparator: String = "",
        currencySymbol: String = ""
    ) -> String {
        let formatter = NSNumber.fw_numberFormatter(digit, roundingMode: .halfUp, fractionZero: fractionZero, groupingSeparator: groupingSeparator, currencySymbol: currencySymbol)
        return formatter.string(from: self) ?? ""
    }

    /// 快捷取上整格式化为字符串，默认numberStyle为decimal
    /// - Parameters:
    ///   - digit: 保留小数位数，默认2，示例：1234.5678 => 1234.57
    ///   - fractionZero: 是否保留小数末尾0(示例：1234.8912 => 1234.90)，默认false去掉末尾0(示例：1234.8912 => 1234.9)
    ///   - groupingSeparator: 分组分隔符，默认为空，示例：1234.5678 => 1,234.57
    ///   - currencySymbol: 货币符号，默认为空，指定后numberStyle为currency，示例：1234.5678 => $1234.57
    /// - Returns: 格式化字符串
    public func fw_ceilString(
        _ digit: Int = 2,
        fractionZero: Bool = false,
        groupingSeparator: String = "",
        currencySymbol: String = ""
    ) -> String {
        let formatter = NSNumber.fw_numberFormatter(digit, roundingMode: .ceiling, fractionZero: fractionZero, groupingSeparator: groupingSeparator, currencySymbol: currencySymbol)
        return formatter.string(from: self) ?? ""
    }

    /// 快捷取下整格式化为字符串，默认numberStyle为decimal
    /// - Parameters:
    ///   - digit: 保留小数位数，默认2，示例：1234.5678 => 1234.56
    ///   - fractionZero: 是否保留小数末尾0(示例：1234.9012 => 1234.90)，默认false去掉末尾0(示例：1234.9012 => 1234.9)
    ///   - groupingSeparator: 分组分隔符，默认为空，示例：1234.5678 => 1,234.56
    ///   - currencySymbol: 货币符号，默认为空，指定后numberStyle为currency，示例：1234.5678 => $1234.56
    /// - Returns: 格式化字符串
    public func fw_floorString(
        _ digit: Int = 2,
        fractionZero: Bool = false,
        groupingSeparator: String = "",
        currencySymbol: String = ""
    ) -> String {
        let formatter = NSNumber.fw_numberFormatter(digit, roundingMode: .floor, fractionZero: fractionZero, groupingSeparator: groupingSeparator, currencySymbol: currencySymbol)
        return formatter.string(from: self) ?? ""
    }
    
}

// MARK: - String+Foundation
@_spi(FW) extension String {
    /// 将波浪线相对路径展开为绝对路径
    public var fw_expandingTildePath: String {
        return (self as NSString).expandingTildeInPath
    }
    
    /// 将绝对路径替换为波浪线相对路径
    public var fw_abbreviatingTildePath: String {
        return (self as NSString).abbreviatingWithTildeInPath
    }
    
    /// 附加路径组件
    public func fw_appendingPath(_ component: String) -> String {
        return (self as NSString).appendingPathComponent(component)
    }
    
    /// 附加路径组件数组
    public func fw_appendingPath(_ components: [String]) -> String {
        var result = self
        for component in components {
            result = (result as NSString).appendingPathComponent(component)
        }
        return result
    }
    
    /// 附加路径后缀，失败时返回空
    public func fw_appendingPathExtension(_ ext: String) -> String {
        return (self as NSString).appendingPathExtension(ext) ?? ""
    }
    
    /// 计算多行字符串指定字体、指定属性在指定绘制区域内所占尺寸
    public func fw_size(
        font: UIFont,
        drawSize: CGSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude),
        attributes: [NSAttributedString.Key: Any]? = nil
    ) -> CGSize {
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
    public static func fw_sizeString(_ aFileSize: UInt64) -> String {
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

    /// 正则匹配回调
    /// - Parameters:
    ///   - regex: 正则表达式
    ///   - reverse: 匹配结果是否反向，默认true
    ///   - block: 回调句柄。正向时range从小到大，反向时从大至小，方便replace
    public func fw_regexMatches(_ regex: String, reverse: Bool = true, block: (NSRange) -> Void) {
        guard let regexObj = try? NSRegularExpression(pattern: regex) else { return }
        let matches = regexObj.matches(in: self, range: NSMakeRange(0, (self as NSString).length))
        // 倒序循环，避免replace等越界
        for match in (reverse ? matches.reversed() : matches) {
            block(match.range)
        }
    }
    
    /// 转义Html，如"a<"转义为"a&lt;"
    public var fw_escapeHtml: String {
        let len = (self as NSString).length
        if len == 0 { return self }

        var buf = [unichar](repeating: 0, count: len)
        (self as NSString).getCharacters(&buf, range: NSRange(location: 0, length: len))

        let result = NSMutableString()
        for i in 0 ..< len {
            var c = buf[i]
            var esc: String? = nil
            switch c {
            case 34: esc = "&quot;"; break;
            case 38: esc = "&amp;"; break;
            case 39: esc = "&apos;"; break;
            case 60: esc = "&lt;"; break;
            case 62: esc = "&gt;"; break;
            default: break;
            }
            if let esc = esc {
                result.append(esc)
            } else {
                CFStringAppendCharacters(result as CFMutableString, &c, 1)
            }
        }
        return result as String
    }
    
    /// 是否符合验证器
    public func fw_isValid(_ validator: Validator<String>) -> Bool {
        return validator.validate(self)
    }
    
}

// MARK: - FileManager+Foundation
@_spi(FW) extension FileManager {
    
    /// 搜索路径
    ///
    /// - Parameter directory: 搜索目录
    /// - Returns: 目标路径
    public static func fw_pathSearch(_ directory: FileManager.SearchPathDirectory) -> String {
        return NSSearchPathForDirectoriesInDomains(directory, .userDomainMask, true).first ?? ""
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
    
    /// 递归创建目录，返回是否成功
    @discardableResult
    public static func fw_createDirectory(atPath: String, attributes: [FileAttributeKey: Any]? = nil) -> Bool {
        do {
            try FileManager.default.createDirectory(atPath: atPath, withIntermediateDirectories: true, attributes: attributes)
            return true
        } catch {
            return false
        }
    }
    
    /// 递归删除目录|文件，返回是否成功
    @discardableResult
    public static func fw_removeItem(atPath: String) -> Bool {
        do {
            try FileManager.default.removeItem(atPath: atPath)
            return true
        } catch {
            return false
        }
    }
    
    /// 移动目录|文件，返回是否成功
    @discardableResult
    public static func fw_moveItem(atPath: String, toPath: String) -> Bool {
        do {
            try FileManager.default.moveItem(atPath: atPath, toPath: toPath)
            return true
        } catch {
            return false
        }
    }
    
    /// 查询目录|文件是否存在
    public static func fw_fileExists(atPath: String, isDirectory: Bool? = nil) -> Bool {
        if let isDirectory = isDirectory {
            var objCBool: ObjCBool = false
            if FileManager.default.fileExists(atPath: atPath, isDirectory: &objCBool) {
                return isDirectory == objCBool.boolValue
            }
            return false
        } else {
            return FileManager.default.fileExists(atPath: atPath)
        }
    }
    
    /// 获取文件大小，单位：B
    public static func fw_fileSize(_ filePath: String) -> UInt64 {
        var fileSize: UInt64 = 0
        if let fileAttributes = try? FileManager.default.attributesOfItem(atPath: filePath),
           let sizeNumber = fileAttributes[.size] as? NSNumber {
            fileSize = sizeNumber.uint64Value
        }
        return fileSize
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
    
    /// 将路径标记为禁止iCloud备份
    @discardableResult
    public static func fw_skipBackup(_ path: String) -> Bool {
        var url = URL(fileURLWithPath: path)
        var backup = URLResourceValues()
        backup.isExcludedFromBackup = true
        do {
            try url.setResourceValues(backup)
            return true
        } catch {
            return false
        }
    }
    
}

// MARK: - NSAttributedString+Foundation
/// 如果需要实现行内图片可点击效果，可使用UITextView添加附件或Link并实现delegate.shouldInteractWith方法即可。
/// 注意iOS在后台运行时，如果调用NSAttributedString解析html会导致崩溃(如动态切换深色模式时在后台解析html)。解决方法是提前在前台解析好或者后台异步到下一个主线程RunLoop
@_spi(FW) extension NSAttributedString {
    
    /// 获取全局样式(index为0的属性)
    public var fw_attributes: [NSAttributedString.Key: Any]? {
        guard length > 0 else { return nil }
        return attributes(at: 9, effectiveRange: nil)
    }
    
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
    
    /// 快速创建NSAttributedString并指定单个高亮部分文字和样式，链接设置NSLinkAttributeName|URL属性即可
    public static func fw_attributedString(string: String, attributes: [NSAttributedString.Key : Any]?, highlight: String, highlightAttributes: [NSAttributedString.Key : Any]?) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: string, attributes: attributes)
        let range = (string as NSString).range(of: highlight)
        if range.location != NSNotFound, let highlightAttributes = highlightAttributes {
            attributedString.addAttributes(highlightAttributes, range: range)
        }
        return attributedString
    }
    
    /// 快速创建NSAttributedString并指定所有高亮部分文字和样式，链接设置NSLinkAttributeName|URL属性即可
    public static func fw_attributedString(string: String, attributes: [NSAttributedString.Key : Any]?, highlights: [String: [NSAttributedString.Key : Any]]) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: string, attributes: attributes)
        for (highlight, highlightAttributes) in highlights {
            let range = (string as NSString).range(of: highlight)
            if range.location != NSNotFound {
                attributedString.addAttributes(highlightAttributes, range: range)
            }
        }
        return attributedString
    }
    
    /// 快速创建NSAttributedString，自定义字体和颜色
    public static func fw_attributedString(_ string: String, font: UIFont?, textColor: UIColor? = nil, attributes: [NSAttributedString.Key : Any]? = nil) -> Self {
        var attributes = attributes ?? [:]
        if let font = font {
            attributes[.font] = font
        }
        if let textColor = textColor {
            attributes[.foregroundColor] = textColor
        }
        return Self(string: string, attributes: attributes)
    }
    
    /// 快速创建NSAttributedString，自定义字体、颜色、行高、对齐方式和换行模式
    public static func fw_attributedString(_ string: String, font: UIFont?, textColor: UIColor?, lineHeight: CGFloat, textAlignment: NSTextAlignment = .left, lineBreakMode: NSLineBreakMode = .byWordWrapping, attributes: [NSAttributedString.Key : Any]? = nil) -> Self {
        var attributes = attributes ?? [:]
        attributes[.paragraphStyle] = fw_paragraphStyle(lineHeight: lineHeight, textAlignment: textAlignment, lineBreakMode: lineBreakMode)
        if let font = font {
            attributes[.font] = font
            if lineHeight > 0 {
                attributes[.baselineOffset] = NSNumber(value: (lineHeight - font.lineHeight) / 4.0)
            }
        }
        if let textColor = textColor {
            attributes[.foregroundColor] = textColor
        }
        return Self(string: string, attributes: attributes)
    }
    
    /// 快速创建指定行高、对齐方式和换行模式的段落样式对象
    public static func fw_paragraphStyle(lineHeight: CGFloat, textAlignment: NSTextAlignment = .left, lineBreakMode: NSLineBreakMode = .byWordWrapping) -> NSMutableParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()
        if lineHeight > 0 {
            paragraphStyle.minimumLineHeight = lineHeight
            paragraphStyle.maximumLineHeight = lineHeight
        }
        paragraphStyle.lineBreakMode = lineBreakMode
        paragraphStyle.alignment = textAlignment
        return paragraphStyle
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

// MARK: - URL+Foundation
/// 第三方URL生成器，可先判断canOpenURL，再openURL，需添加对应URL SCHEME到LSApplicationQueriesSchemes配置数组
@_spi(FW) extension URL {
    
    /**
     生成App Store外部URL
     
     @param appId 应用Id
     @return NSURL
     */
    public static func fw_appStoreURL(_ appId: String) -> URL {
        return URL(string: "https://apps.apple.com/app/id\(appId)") ?? NSURL() as URL
    }

    /**
     生成苹果地图地址外部URL
     
     @param addr 显示地址，格式latitude,longitude或搜索地址
     @param options 可选附加参数，如["ll": "latitude,longitude", "z": "14"]
     @return NSURL
     */
    public static func fw_appleMapsURL(addr: String?, options: [AnyHashable : Any]? = nil) -> URL? {
        var params = options ?? [:]
        if let addr = addr, !addr.isEmpty {
            params["q"] = addr
        }
        return fw_vendorURL("https://maps.apple.com/", params: params)
    }

    /**
     生成苹果地图导航外部URL
     
     @param saddr 导航起始点，格式latitude,longitude或搜索地址
     @param daddr 导航结束点，格式latitude,longitude或搜索地址
     @param options 可选附加参数，如["ll": "latitude,longitude", "z": "14"]
     @return NSURL
     */
    public static func fw_appleMapsURL(saddr: String?, daddr: String?, options: [AnyHashable : Any]? = nil) -> URL? {
        var params = options ?? [:]
        if let saddr = saddr, !saddr.isEmpty {
            params["saddr"] = saddr
        }
        if let daddr = daddr, !daddr.isEmpty {
            params["daddr"] = daddr
        }
        return fw_vendorURL("https://maps.apple.com/", params: params)
    }

    /**
     生成谷歌地图外部URL
     
     @param addr 显示地址，格式latitude,longitude或搜索地址
     @param options 可选附加参数，如["query_place_id": ""]
     @return NSURL
     */
    public static func fw_googleMapsURL(addr: String?, options: [AnyHashable : Any]? = nil) -> URL? {
        var params = options ?? [:]
        params["api"] = "1"
        if let addr = addr, !addr.isEmpty {
            params["query"] = addr
        }
        return fw_vendorURL("https://www.google.com/maps/search/", params: params)
    }

    /**
     生成谷歌地图导航外部URL
     
     @param saddr 导航起始点，格式latitude,longitude或搜索地址
     @param daddr 导航结束点，格式latitude,longitude或搜索地址
     @param mode 导航模式，支持driving|transit|bicycling|walking
     @param options 可选附加参数，如["origin_place_id": ""]
     @return NSURL
     */
    public static func fw_googleMapsURL(saddr: String?, daddr: String?, mode: String? = nil, options: [AnyHashable : Any]? = nil) -> URL? {
        var params = options ?? [:]
        params["api"] = "1"
        if let saddr = saddr, !saddr.isEmpty {
            params["origin"] = saddr
        }
        if let daddr = daddr, !daddr.isEmpty {
            params["destination"] = daddr
        }
        if let mode = mode, !mode.isEmpty {
            params["travelmode"] = mode
        }
        return fw_vendorURL("https://www.google.com/maps/dir/", params: params)
    }
    
    /**
     生成外部URL，需配置对应URL SCHEME
     
     @param string 外部主URL
     @param params 附加参数
     @return NSURL
     */
    public static func fw_vendorURL(_ string: String, params: [AnyHashable: Any]? = nil) -> URL? {
        var urlString = string + (string.contains("?") ? "&" : "?")
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
