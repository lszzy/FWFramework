//
//  Foundation.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit
import CommonCrypto

// MARK: - WrapperGlobal
extension WrapperGlobal {
    /// 通用互斥锁方法
    public static func synchronized(_ object: Any, closure: () -> Void) {
        objc_sync_enter(object)
        defer { objc_sync_exit(object) }
        
        closure()
    }
    
    /// 通用互斥锁方法，返回指定对象
    public static func synchronized<T>(_ object: Any, closure: () -> T) -> T {
        objc_sync_enter(object)
        defer { objc_sync_exit(object) }
        
        return closure()
    }
    
    /// 同一个token仅执行一次block，全局范围
    public static func dispatchOnce(
        _ token: AnyHashable,
        closure: @escaping () -> Void
    ) {
        NSObject.fw.dispatchOnce(token, closure: closure)
    }
}

// MARK: - Wrapper+AnyObject
extension Wrapper where Base: WrapperObject {
    /// 执行加锁(支持任意对象)，等待信号量，自动创建信号量
    public func lock() {
        lockSemaphore.wait()
    }

    /// 执行解锁(支持任意对象)，发送信号量，自动创建信号量
    public func unlock() {
        lockSemaphore.signal()
    }
    
    private var lockSemaphore: DispatchSemaphore {
        return synchronized {
            if let semaphore = property(forName: #function) as? DispatchSemaphore {
                return semaphore
            } else {
                let semaphore = DispatchSemaphore(value: 1)
                setProperty(semaphore, forName: #function)
                return semaphore
            }
        }
    }
    
    /// 延迟创建队列，默认串行队列
    public var queue: DispatchQueue {
        get {
            return synchronized {
                if let queue = property(forName: #function) as? DispatchQueue {
                    return queue
                } else {
                    let queue = DispatchQueue(label: #function)
                    setProperty(queue, forName: #function)
                    return queue
                }
            }
        }
        set {
            synchronized {
                setProperty(newValue, forName: #function)
            }
        }
    }
    
    /// 通用互斥锁方法
    public static func synchronized(_ closure: () -> Void) {
        objc_sync_enter(Base.self)
        defer { objc_sync_exit(Base.self) }
        
        closure()
    }
    
    /// 通用互斥锁方法，返回指定对象
    public static func synchronized<T>(_ closure: () -> T) -> T {
        objc_sync_enter(Base.self)
        defer { objc_sync_exit(Base.self) }
        
        return closure()
    }
    
    /// 通用互斥锁方法
    public func synchronized(_ closure: () -> Void) {
        objc_sync_enter(base)
        defer { objc_sync_exit(base) }
        
        closure()
    }
    
    /// 通用互斥锁方法，返回指定对象
    public func synchronized<T>(_ closure: () -> T) -> T {
        objc_sync_enter(base)
        defer { objc_sync_exit(base) }
        
        return closure()
    }
    
    /// 同一个token仅执行一次block，对象范围
    public func dispatchOnce(
        _ token: String,
        closure: @escaping () -> Void
    ) {
        synchronized {
            var tokens: NSMutableSet
            if let mutableSet = property(forName: "dispatchOnce") as? NSMutableSet {
                tokens = mutableSet
            } else {
                tokens = NSMutableSet()
                setProperty(tokens, forName: "dispatchOnce")
            }
            
            guard !tokens.contains(token) else { return }
            tokens.add(token)
            closure()
        }
    }
    
    /// 延迟delay秒后主线程执行，返回可取消的block，对象范围
    @discardableResult
    public func performBlock(
        _ block: @escaping (Base) -> Void,
        afterDelay delay: TimeInterval
    ) -> Any {
        return performBlock(block, on: .main, afterDelay: delay)
    }

    /// 延迟delay秒后后台线程执行，返回可取消的block，对象范围
    @discardableResult
    public func performBlock(
        inBackground block: @escaping (Base) -> Void,
        afterDelay delay: TimeInterval
    ) -> Any {
        return performBlock(block, on: .global(qos: .background), afterDelay: delay)
    }

    /// 延迟delay秒后指定线程执行，返回可取消的block，对象范围
    @discardableResult
    public func performBlock(
        _ block: @escaping (Base) -> Void,
        on: DispatchQueue,
        afterDelay delay: TimeInterval
    ) -> Any {
        var cancelled = false
        let strongBase = base
        let wrapper: (Bool) -> Void = { cancel in
            if cancel {
                cancelled = true
                return
            }
            if !cancelled {
                block(strongBase)
            }
        }
        
        queue.asyncAfter(deadline: .now() + delay) {
            wrapper(false)
        }
        return wrapper
    }
}

// MARK: - Wrapper+NSObject
extension Wrapper where Base: NSObject {
    /// 同一个token仅执行一次block，全局范围
    public static func dispatchOnce(
        _ token: AnyHashable,
        closure: @escaping () -> Void
    ) {
        objc_sync_enter(NSObject.self)
        defer { objc_sync_exit(NSObject.self) }
        
        guard !NSObject.innerOnceTokens.contains(token) else { return }
        NSObject.innerOnceTokens.append(token)
        closure()
    }
    
    /// 延迟delay秒后主线程执行，返回可取消的block，全局范围
    @discardableResult
    public static func performBlock(
        _ block: @escaping () -> Void,
        afterDelay delay: TimeInterval
    ) -> Any {
        return performBlock(block, on: .main, afterDelay: delay)
    }

    /// 延迟delay秒后后台线程执行，返回可取消的block，全局范围
    @discardableResult
    public static func performBlock(
        inBackground block: @escaping () -> Void,
        afterDelay delay: TimeInterval
    ) -> Any {
        return performBlock(block, on: .global(qos: .background), afterDelay: delay)
    }

    /// 延迟delay秒后指定线程执行，返回可取消的block，全局范围
    @discardableResult
    public static func performBlock(
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
    public static func cancelBlock(_ block: Any?) {
        let wrapper = block as? (Bool) -> Void
        wrapper?(true)
    }

    /// 同步方式执行异步block，阻塞当前线程(信号量)，异步block必须调用completionHandler，全局范围
    public static func syncPerform(
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
    public static func performBlock(
        _ block: @escaping (@escaping (Bool, Any?) -> Void) -> Void,
        completion: @escaping (Bool, Any?) -> Void,
        retryCount: Int,
        timeoutInterval: TimeInterval,
        delayInterval: @escaping (Int) -> TimeInterval,
        isCancelled: (() -> Bool)? = nil
    ) {
        let startTime = Date().timeIntervalSince1970
        performBlock(block, completion: completion, retryCount: retryCount, remainCount: retryCount, timeoutInterval: timeoutInterval, delayInterval: delayInterval, isCancelled: isCancelled, startTime: startTime)
    }
    
    private static func performBlock(
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
                    NSObject.fw.performBlock(block, completion: completion, retryCount: retryCount, remainCount: remainCount - 1, timeoutInterval: timeoutInterval, delayInterval: delayInterval, isCancelled: isCancelled, startTime: startTime)
                }
            } else {
                completion(success, obj)
            }
        })
    }

    /// 执行轮询block任务，返回任务Id可取消
    @discardableResult
    public static func performTask(_ task: @escaping () -> Void, start: TimeInterval, interval: TimeInterval, repeats: Bool, async: Bool) -> String {
        let queue: DispatchQueue = async ? .global() : .main
        let timer = DispatchSource.makeTimerSource(flags: [], queue: queue)
        timer.schedule(deadline: .now() + start, repeating: interval, leeway: .seconds(0))
        
        NSObject.innerTaskSemaphore.wait()
        let taskId = "\(NSObject.innerTaskPool.count)"
        NSObject.innerTaskPool[taskId] = timer
        NSObject.innerTaskSemaphore.signal()
        
        timer.setEventHandler {
            task()
            if !repeats {
                NSObject.fw.cancelTask(taskId)
            }
        }
        timer.resume()
        return taskId
    }

    /// 指定任务Id取消轮询任务
    public static func cancelTask(_ taskId: String?) {
        guard let taskId, !taskId.isEmpty else { return }
        NSObject.innerTaskSemaphore.wait()
        if let timer = NSObject.innerTaskPool[taskId] as? DispatchSourceTimer {
            timer.cancel()
            NSObject.innerTaskPool.removeObject(forKey: taskId)
        }
        NSObject.innerTaskSemaphore.signal()
    }
}

// MARK: - Wrapper+Date
extension Wrapper where Base == Date {
    /// 当前时间戳，没有设置过返回本地时间戳，可同步设置服务器时间戳，同步后调整手机时间不影响
    public static var currentTime: TimeInterval {
        get {
            // 没有同步过返回本地时间
            if Date.innerCurrentBaseTime == 0 {
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
                let offsetTime = systemUptime - Date.innerLocalBaseTime
                return Date.innerCurrentBaseTime + offsetTime
            }
        }
        set {
            Date.innerCurrentBaseTime = newValue
            // 取运行时间，调整系统时间不会影响
            Date.innerLocalBaseTime = systemUptime
            
            // 保存当前服务器时间到本地
            UserDefaults.standard.set(NSNumber(value: newValue), forKey: "FWCurrentTime")
            UserDefaults.standard.set(NSNumber(value: Date().timeIntervalSince1970), forKey: "FWLocalTime")
            UserDefaults.standard.synchronize()
        }
    }
    
    private static var systemUptime: TimeInterval {
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
    
    /// 通用DateFormatter对象，默认系统时区，使用时需先指定dateFormat，可自定义
    public static var dateFormatter: DateFormatter {
        get { Base.innerDateFormatter }
        set { Base.innerDateFormatter = newValue }
    }
    
    /// 从字符串初始化日期，自定义格式(默认yyyy-MM-dd HH:mm:ss)
    public static func date(string: String, format: String = "yyyy-MM-dd HH:mm:ss") -> Date? {
        let formatter = Date.innerDateFormatter
        formatter.dateFormat = format
        let date = formatter.date(from: string)
        return date
    }
    
    /// 转化为字符串，格式：yyyy-MM-dd HH:mm:ss
    public var stringValue: String {
        return string(format: "yyyy-MM-dd HH:mm:ss")
    }
    
    /// 转化为字符串，自定义格式
    public func string(format: String) -> String {
        let formatter = Date.innerDateFormatter
        formatter.dateFormat = format
        let string = formatter.string(from: base)
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
    public static func formatServerDate(_ dateString: String) -> TimeInterval {
        let dateFormatter = Date.innerServerDateFormatter
        let date = dateFormatter.date(from: dateString)
        return date?.timeIntervalSince1970 ?? 0
    }
    
    /// 是否是闰年
    public var isLeapYear: Bool {
        let year = Calendar.current.component(.year, from: base)
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
    public func isSameDay(_ date: Date) -> Bool {
        var components = Calendar.current.dateComponents([.era, .year, .month, .day], from: date)
        let dateOne = Calendar.current.date(from: components)
        
        components = Calendar.current.dateComponents([.era, .year, .month, .day], from: base)
        let dateTwo = Calendar.current.date(from: components)
        return dateOne == dateTwo
    }

    /// 添加指定日期，如year:1|month:-1|day:1等
    public func date(byAdding: DateComponents) -> Date? {
        return Calendar.current.date(byAdding: byAdding, to: base)
    }

    /// 与指定日期相隔天数
    public func days(from date: Date) -> Int {
        let earliest = (base as NSDate).earlierDate(date)
        let latest = earliest == base ? date : base
        let multipier: Int = earliest == base ? -1 : 1
        let components = Calendar.current.dateComponents([.day], from: earliest, to: latest)
        return multipier * (components.day ?? 0)
    }
}

// MARK: - Wrapper+NSNumber
extension Wrapper where Base: NSNumber {
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
    public func roundString(
        _ digit: Int = 2,
        fractionZero: Bool = false,
        groupingSeparator: String = "",
        currencySymbol: String = ""
    ) -> String {
        let formatter = NSNumber.fw.numberFormatter(digit, roundingMode: .halfUp, fractionZero: fractionZero, groupingSeparator: groupingSeparator, currencySymbol: currencySymbol)
        return formatter.string(from: base) ?? ""
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
        let formatter = NSNumber.fw.numberFormatter(digit, roundingMode: .ceiling, fractionZero: fractionZero, groupingSeparator: groupingSeparator, currencySymbol: currencySymbol)
        return formatter.string(from: base) ?? ""
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
        let formatter = NSNumber.fw.numberFormatter(digit, roundingMode: .floor, fractionZero: fractionZero, groupingSeparator: groupingSeparator, currencySymbol: currencySymbol)
        return formatter.string(from: base) ?? ""
    }
}

// MARK: - Wrapper+String
extension Wrapper where Base == String {
    /// 将波浪线相对路径展开为绝对路径
    public var expandingTildePath: String {
        return (base as NSString).expandingTildeInPath
    }
    
    /// 将绝对路径替换为波浪线相对路径
    public var abbreviatingTildePath: String {
        return (base as NSString).abbreviatingWithTildeInPath
    }
    
    /// 附加路径组件
    public func appendingPath(_ component: String) -> String {
        return (base as NSString).appendingPathComponent(component)
    }
    
    /// 附加路径组件数组
    public func appendingPath(_ components: [String]) -> String {
        var result = base
        for component in components {
            result = (result as NSString).appendingPathComponent(component)
        }
        return result
    }
    
    /// 附加路径后缀，失败时返回空
    public func appendingPathExtension(_ ext: String) -> String {
        return (base as NSString).appendingPathExtension(ext) ?? ""
    }
    
    /// 计算多行字符串指定字体、指定属性在指定绘制区域内所占尺寸
    public func size(
        font: UIFont,
        drawSize: CGSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude),
        attributes: [NSAttributedString.Key: Any]? = nil
    ) -> CGSize {
        var attr: [NSAttributedString.Key: Any] = [:]
        attr[.font] = font
        if let attributes = attributes {
            attr.merge(attributes) { _, last in last }
        }
        
        let str = base as NSString
        let size = str.boundingRect(with: drawSize, options: [.usesFontLeading, .usesLineFragmentOrigin], attributes: attr, context: nil).size
        return CGSize(width: min(drawSize.width, ceil(size.width)), height: min(drawSize.height, ceil(size.height)))
    }
    
    /// 格式化文件大小为".0K/.1M/.1G"
    public static func sizeString(_ aFileSize: UInt64) -> String {
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
        return regexPredicate.evaluate(with: base)
    }
    
    /**
     *  安全截取字符串。解决末尾半个Emoji问题(半个Emoji调UTF8String为NULL，导致MD5签名等失败)
     *
     *  @param index 目标索引
     */
    public func emojiSubstring(_ index: Int) -> String {
        var result = base as NSString
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
    public func regexSubstring(_ regex: String) -> String? {
        let range = (base as NSString).range(of: regex, options: .regularExpression)
        if range.location != NSNotFound {
            return (base as NSString).substring(with: range)
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
    public func regexReplace(_ regex: String, string: String) -> String {
        guard let regexObj = try? NSRegularExpression(pattern: regex) else {
            return base
        }
        return regexObj.stringByReplacingMatches(in: base, range: NSMakeRange(0, (base as NSString).length), withTemplate: string)
    }

    /// 正则匹配回调
    /// - Parameters:
    ///   - regex: 正则表达式
    ///   - reverse: 匹配结果是否反向，默认true
    ///   - block: 回调句柄。正向时range从小到大，反向时从大至小，方便replace
    public func regexMatches(_ regex: String, reverse: Bool = true, block: (NSRange) -> Void) {
        guard let regexObj = try? NSRegularExpression(pattern: regex) else { return }
        let matches = regexObj.matches(in: base, range: NSMakeRange(0, (base as NSString).length))
        // 倒序循环，避免replace等越界
        for match in (reverse ? matches.reversed() : matches) {
            block(match.range)
        }
    }
    
    /// 检测链接并回调，NSAttributedString调用时请使用string防止range越界
    public func detectLinks(types: NSTextCheckingTypes? = nil, block: (NSTextCheckingResult, String, UnsafeMutablePointer<ObjCBool>) -> Void) {
        if let dataDetector = try? NSDataDetector(types: types ?? NSTextCheckingResult.CheckingType.link.rawValue) {
            let string = base as NSString
            dataDetector.enumerateMatches(in: base, range: NSMakeRange(0, string.length)) { result, flags, stop in
                if let result = result {
                    block(result, string.substring(with: result.range), stop)
                }
            }
        }
    }
    
    /// 转义Html，如"a<"转义为"a&lt;"
    public var escapeHtml: String {
        let len = (base as NSString).length
        if len == 0 { return base }

        var buf = [unichar](repeating: 0, count: len)
        (base as NSString).getCharacters(&buf, range: NSRange(location: 0, length: len))

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
    public func isValid(_ validator: Validator<String>) -> Bool {
        return validator.validate(base)
    }
}

// MARK: - Wrapper+FileManager
extension Wrapper where Base: FileManager {
    /// 搜索路径
    ///
    /// - Parameter directory: 搜索目录
    /// - Returns: 目标路径
    public static func pathSearch(_ directory: FileManager.SearchPathDirectory) -> String {
        return NSSearchPathForDirectoriesInDomains(directory, .userDomainMask, true).first ?? ""
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
    
    /// 递归创建目录，返回是否成功
    @discardableResult
    public static func createDirectory(atPath: String, attributes: [FileAttributeKey: Any]? = nil) -> Bool {
        do {
            try FileManager.default.createDirectory(atPath: atPath, withIntermediateDirectories: true, attributes: attributes)
            return true
        } catch {
            return false
        }
    }
    
    /// 递归删除目录|文件，返回是否成功
    @discardableResult
    public static func removeItem(atPath: String) -> Bool {
        do {
            try FileManager.default.removeItem(atPath: atPath)
            return true
        } catch {
            return false
        }
    }
    
    /// 移动目录|文件，返回是否成功
    @discardableResult
    public static func moveItem(atPath: String, toPath: String) -> Bool {
        do {
            try FileManager.default.moveItem(atPath: atPath, toPath: toPath)
            return true
        } catch {
            return false
        }
    }
    
    /// 查询目录|文件是否存在
    public static func fileExists(atPath: String, isDirectory: Bool? = nil) -> Bool {
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
    public static func fileSize(_ filePath: String) -> UInt64 {
        var fileSize: UInt64 = 0
        if let fileAttributes = try? FileManager.default.attributesOfItem(atPath: filePath),
           let sizeNumber = fileAttributes[.size] as? NSNumber {
            fileSize = sizeNumber.uint64Value
        }
        return fileSize
    }

    /// 获取目录大小，单位：B
    public static func folderSize(_ folderPath: String) -> UInt64 {
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
    public static func skipBackup(_ path: String) -> Bool {
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

// MARK: - Wrapper+NSAttributedString
/// 如果需要实现行内图片可点击效果，可使用UITextView添加附件或Link并实现delegate.shouldInteractWith方法即可。
/// 注意iOS在后台运行时，如果调用NSAttributedString解析html会导致崩溃(如动态切换深色模式时在后台解析html)。解决方法是提前在前台解析好或者后台异步到下一个主线程RunLoop
extension Wrapper where Base: NSAttributedString {
    /// 获取全局样式(index为0的属性)
    public var attributes: [NSAttributedString.Key: Any]? {
        guard base.length > 0 else { return nil }
        return base.attributes(at: 0, effectiveRange: nil)
    }
    
    /// NSAttributedString对象转换为html字符串
    public func htmlString() -> String? {
        let htmlData = try? base.data(
            from: NSMakeRange(0, base.length),
            documentAttributes: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ]
        )
        guard let htmlData = htmlData, !htmlData.isEmpty else { return nil }
        return String(data: htmlData, encoding: .utf8)
    }

    /// 计算所占尺寸，需设置Font等
    public var textSize: CGSize {
        return textSize(drawSize: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
    }

    /// 计算在指定绘制区域内所占尺寸，需设置Font等
    public func textSize(drawSize: CGSize) -> CGSize {
        let size = base.boundingRect(with: drawSize, options: [.usesFontLeading, .usesLineFragmentOrigin], context: nil).size
        return CGSize(width: min(drawSize.width, ceil(size.width)), height: min(drawSize.height, ceil(size.height)))
    }
    
    /// html字符串转换为NSAttributedString对象。如需设置默认字体和颜色，请使用addAttributes方法或附加CSS样式
    public static func attributedString(htmlString: String) -> Base? {
        let htmlData = htmlString.data(using: .utf8)
        guard let htmlData = htmlData, !htmlData.isEmpty else { return nil }
        
        return try? Base.init(
            data: htmlData,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
        )
    }

    /// 图片转换为NSAttributedString对象，可实现行内图片样式。其中bounds.x会设置为间距，y常用算法：(font.capHeight - image.size.height) / 2.0
    public static func attributedString(image: UIImage?, bounds: CGRect) -> NSAttributedString {
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
    public static func attributedString(string: String, attributes: [NSAttributedString.Key : Any]?, highlight: String, highlightAttributes: [NSAttributedString.Key : Any]?) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: string, attributes: attributes)
        let range = (string as NSString).range(of: highlight)
        if range.location != NSNotFound, let highlightAttributes = highlightAttributes {
            attributedString.addAttributes(highlightAttributes, range: range)
        }
        return attributedString
    }
    
    /// 快速创建NSAttributedString并指定所有高亮部分文字和样式，链接设置NSLinkAttributeName|URL属性即可
    public static func attributedString(string: String, attributes: [NSAttributedString.Key : Any]?, highlights: [String: [NSAttributedString.Key : Any]]) -> NSAttributedString {
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
    public static func attributedString(_ string: String, font: UIFont?, textColor: UIColor? = nil, attributes: [NSAttributedString.Key : Any]? = nil) -> Base {
        var attributes = attributes ?? [:]
        if let font = font {
            attributes[.font] = font
        }
        if let textColor = textColor {
            attributes[.foregroundColor] = textColor
        }
        return Base.init(string: string, attributes: attributes)
    }
    
    /// 快速创建NSAttributedString，自定义字体、颜色、行高、对齐方式和换行模式
    public static func attributedString(_ string: String, font: UIFont?, textColor: UIColor?, lineHeight: CGFloat, textAlignment: NSTextAlignment = .left, lineBreakMode: NSLineBreakMode = .byWordWrapping, attributes: [NSAttributedString.Key : Any]? = nil) -> Base {
        var attributes = attributes ?? [:]
        attributes[.paragraphStyle] = paragraphStyle(lineHeight: lineHeight, textAlignment: textAlignment, lineBreakMode: lineBreakMode)
        if let font = font {
            attributes[.font] = font
            if lineHeight > 0 {
                attributes[.baselineOffset] = NSNumber(value: (lineHeight - font.lineHeight) / 4.0)
            }
        }
        if let textColor = textColor {
            attributes[.foregroundColor] = textColor
        }
        return Base.init(string: string, attributes: attributes)
    }
    
    /// 快速创建指定行高、对齐方式和换行模式的段落样式对象
    public static func paragraphStyle(lineHeight: CGFloat, textAlignment: NSTextAlignment = .left, lineBreakMode: NSLineBreakMode = .byWordWrapping) -> NSMutableParagraphStyle {
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
    public static func attributedString(htmlString string: String, defaultAttributes: [NSAttributedString.Key: Any]?) -> Base? {
        guard !string.isEmpty else { return nil }
        var htmlString = string
        if let attributes = defaultAttributes {
            var cssText = ""
            if let textColor = attributes[.foregroundColor] as? UIColor {
                cssText = cssText.appendingFormat("color:%@;", cssString(color: textColor))
            }
            if let font = attributes[.font] as? UIFont {
                cssText = cssText.appending(cssString(font: font))
            }
            if !cssText.isEmpty {
                htmlString = String(format: "<style type='text/css'>html{%@}</style>%@", cssText, htmlString)
            }
        }
        return attributedString(htmlString: htmlString)
    }

    /// html字符串转换为NSAttributedString主题对象，可设置默认系统字体和动态颜色，详见ThemeObject
    public static func themeObject(htmlString: String, defaultAttributes: [NSAttributedString.Key: Any]?) -> ThemeObject<NSAttributedString> {
        var lightAttributes: [NSAttributedString.Key: Any] = [:]
        var darkAttributes: [NSAttributedString.Key: Any] = [:]
        if let textColor = defaultAttributes?[.foregroundColor] as? UIColor {
            lightAttributes[.foregroundColor] = textColor.fw.color(forStyle: .light)
            darkAttributes[.foregroundColor] = textColor.fw.color(forStyle: .dark)
        }
        if let font = defaultAttributes?[.font] as? UIFont {
            lightAttributes[.font] = font
            darkAttributes[.font] = font
        }
        
        let lightObject = attributedString(htmlString: htmlString, defaultAttributes: lightAttributes)
        let darkObject = attributedString(htmlString: htmlString, defaultAttributes: darkAttributes)
        return ThemeObject(light: lightObject, dark: darkObject)
    }

    /// 获取颜色对应CSS字符串(rgb|rgba格式)
    public static func cssString(color: UIColor) -> String {
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
    public static func cssString(font: UIFont) -> String {
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

// MARK: - Wrapper+NSMutableAttributedString
extension Wrapper where Base: NSMutableAttributedString {
    
    /// 当指定属性不存在时添加默认值，默认整个range
    public func addDefaultAttribute(_ name: NSAttributedString.Key, value: Any, range: NSRange? = nil) {
        let fullRange = NSMakeRange(0, (base.string as NSString).length)
        let range = range ?? fullRange
        var ranges: [NSRange] = []
        base.enumerateAttribute(name, in: range) { aValue, aRange, stop in
            if aValue != nil {
                ranges.append(aRange)
            }
        }
        
        let complementaryRanges = complementaryRanges(ranges, inRange: range)
        for complementaryRange in complementaryRanges {
            base.addAttribute(name, value: value, range: complementaryRange)
        }
    }
    
    private func complementaryRanges(_ ranges: [NSRange], inRange: NSRange) -> [NSRange] {
        var targets: [NSRange] = []
        if ranges.count < 1 {
            targets.append(inRange)
            return targets
        }
        
        for (i, range) in ranges.enumerated() {
            var begin = inRange.location
            let end = range.location
            
            if i != 0 {
                let previousRange = ranges[i - 1]
                begin = previousRange.location + previousRange.length
            }
            
            if end > begin {
                targets.append(NSMakeRange(begin, end - begin))
            }
        }
        
        if ranges.count > 0 {
            let lastRange = ranges.last!
            let begin = lastRange.location + lastRange.length
            let end = inRange.location + inRange.length
            
            if end > begin {
                targets.append(NSMakeRange(begin, end - begin))
            }
        }
        
        return targets
    }
    
    /// 设置指定段落样式keyPath对应值，默认整个range
    public func setParagraphStyleValue<Value>(_ keyPath: ReferenceWritableKeyPath<NSMutableParagraphStyle, Value>, value: Value, range: NSRange? = nil) {
        let fullRange = NSMakeRange(0, (base.string as NSString).length)
        let range = range ?? fullRange
        var style: NSParagraphStyle?
        if NSEqualRanges(range, fullRange) {
            style = base.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle
        } else {
            style = base.attribute(.paragraphStyle, at: range.location, longestEffectiveRange: nil, in: range) as? NSParagraphStyle
        }
        
        let mutableStyle = style?.mutableCopy() as? NSMutableParagraphStyle ?? .init()
        mutableStyle[keyPath: keyPath] = value
        base.addAttribute(.paragraphStyle, value: mutableStyle, range: range)
    }
    
}

// MARK: - Wrapper+URL
/// 第三方URL生成器，可先判断canOpenURL，再openURL，需添加对应URL SCHEME到LSApplicationQueriesSchemes配置数组
extension Wrapper where Base == URL {
    /**
     生成App Store外部URL
     
     @param appId 应用Id
     @return NSURL
     */
    public static func appStoreURL(_ appId: String) -> URL {
        return URL(string: "https://apps.apple.com/app/id\(appId)") ?? URL()
    }

    /**
     生成苹果地图地址外部URL
     
     @param addr 显示地址，格式latitude,longitude或搜索地址
     @param options 可选附加参数，如["ll": "latitude,longitude", "z": "14"]
     @return NSURL
     */
    public static func appleMapsURL(addr: String?, options: [AnyHashable : Any]? = nil) -> URL? {
        var params = options ?? [:]
        if let addr = addr, !addr.isEmpty {
            params["q"] = addr
        }
        return vendorURL("https://maps.apple.com/", params: params)
    }

    /**
     生成苹果地图导航外部URL
     
     @param saddr 导航起始点，格式latitude,longitude或搜索地址
     @param daddr 导航结束点，格式latitude,longitude或搜索地址
     @param options 可选附加参数，如["ll": "latitude,longitude", "z": "14"]
     @return NSURL
     */
    public static func appleMapsURL(saddr: String?, daddr: String?, options: [AnyHashable : Any]? = nil) -> URL? {
        var params = options ?? [:]
        if let saddr = saddr, !saddr.isEmpty {
            params["saddr"] = saddr
        }
        if let daddr = daddr, !daddr.isEmpty {
            params["daddr"] = daddr
        }
        return vendorURL("https://maps.apple.com/", params: params)
    }

    /**
     生成谷歌地图外部URL
     
     @param addr 显示地址，格式latitude,longitude或搜索地址
     @param options 可选附加参数，如["query_place_id": ""]
     @return NSURL
     */
    public static func googleMapsURL(addr: String?, options: [AnyHashable : Any]? = nil) -> URL? {
        var params = options ?? [:]
        params["api"] = "1"
        if let addr = addr, !addr.isEmpty {
            params["query"] = addr
        }
        return vendorURL("https://www.google.com/maps/search/", params: params)
    }

    /**
     生成谷歌地图导航外部URL
     
     @param saddr 导航起始点，格式latitude,longitude或搜索地址
     @param daddr 导航结束点，格式latitude,longitude或搜索地址
     @param mode 导航模式，支持driving|transit|bicycling|walking
     @param options 可选附加参数，如["origin_place_id": ""]
     @return NSURL
     */
    public static func googleMapsURL(saddr: String?, daddr: String?, mode: String? = nil, options: [AnyHashable : Any]? = nil) -> URL? {
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
        return vendorURL("https://www.google.com/maps/dir/", params: params)
    }
    
    /**
     生成外部URL，需配置对应URL SCHEME
     
     @param string 外部主URL
     @param params 附加参数
     @return NSURL
     */
    public static func vendorURL(_ string: String, params: [AnyHashable: Any]? = nil) -> URL? {
        var urlString = string + (string.contains("?") ? "&" : "?")
        let urlParams = params ?? [:]
        for (key, value) in urlParams {
            let valueStr = String.fw.safeString(value)
                .replacingOccurrences(of: " ", with: "+")
                .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            urlString += "\(String.fw.safeString(key))=\(valueStr ?? "")&"
        }
        return URL(string: urlString.fw.substring(to: urlString.count - 1))
    }
}

// MARK: - Wrapper+URLSession
extension Wrapper where Base: URLSession {
    /// 是否禁止网络代理抓包，不影响App请求，默认false
    public static var httpProxyDisabled: Bool {
        get {
            return Base.innerHttpProxyDisabled
        }
        set {
            Base.innerHttpProxyDisabled = newValue
            if newValue { FrameworkAutoloader.swizzleHttpProxy() }
        }
    }
    
    /// 获取手机网络代理，可能为空
    public static var httpProxyString: String? {
        let proxy = CFNetworkCopySystemProxySettings()?.takeUnretainedValue() as? [AnyHashable: Any]
        return proxy?[kCFNetworkProxiesHTTPProxy as String] as? String
    }
}

// MARK: - Wrapper+UserDefaults
extension Wrapper where Base: UserDefaults {
    /// 从standard读取对象，支持unarchive对象
    public static func object(forKey: String) -> Any? {
        return UserDefaults.standard.object(forKey: forKey)
    }

    /// 保存对象到standard，支持archive对象
    public static func setObject(_ object: Any?, forKey: String) {
        if let object = object {
            UserDefaults.standard.set(object, forKey: forKey)
        } else {
            UserDefaults.standard.removeObject(forKey: forKey)
        }
        UserDefaults.standard.synchronize()
    }
    
    /// 读取对象，支持unarchive对象
    public func object(forKey: String) -> Any? {
        return base.object(forKey: forKey)
    }

    /// 保存对象，支持archive对象
    public func setObject(_ object: Any?, forKey: String) {
        if let object = object {
            base.set(object, forKey: forKey)
        } else {
            base.removeObject(forKey: forKey)
        }
        base.synchronize()
    }
    
    /// 从standard解档对象，兼容NSCoding和AnyArchivable
    public static func archivableObject(forKey: String) -> Any? {
        return UserDefaults.standard.fw.archivableObject(forKey: forKey)
    }

    /// 归档对象到standard，兼容NSCoding和AnyArchivable
    public static func setArchivableObject(_ object: Any?, forKey: String) {
        UserDefaults.standard.fw.setArchivableObject(object, forKey: forKey)
    }
    
    /// 解档对象，兼容NSCoding和AnyArchivable
    public func archivableObject(forKey: String) -> Any? {
        let data = base.object(forKey: forKey) as? Data
        return data?.fw.unarchivedObject()
    }

    /// 归档对象，兼容NSCoding和AnyArchivable
    public func setArchivableObject(_ object: Any?, forKey: String) {
        let data = Data.fw.archivedData(object)
        if let data = data {
            base.set(data, forKey: forKey)
        } else {
            base.removeObject(forKey: forKey)
        }
        base.synchronize()
    }
}

// MARK: - NSObject+Foundation
extension NSObject {
    
    fileprivate static var innerOnceTokens = [AnyHashable]()
    fileprivate static var innerTaskPool = NSMutableDictionary()
    fileprivate static var innerTaskSemaphore = DispatchSemaphore(value: 1)
    
}

// MARK: - Date+Foundation
extension Date {
    
    fileprivate static var innerCurrentBaseTime: TimeInterval = 0
    fileprivate static var innerLocalBaseTime: TimeInterval = 0
    fileprivate static var innerDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        return formatter
    }()
    fileprivate static var innerServerDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "GMT")
        formatter.dateFormat = "EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'"
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()
}

// MARK: - UserDefaults+Foundation
extension URLSession {
    
    fileprivate static var innerHttpProxyDisabled = false
    
}

// MARK: - FrameworkAutoloader+Foundation
extension FrameworkAutoloader {
    
    private static var swizzleHttpProxyFinished = false
    
    fileprivate static func swizzleHttpProxy() {
        guard !swizzleHttpProxyFinished else { return }
        swizzleHttpProxyFinished = true
        
        NSObject.fw.swizzleClassMethod(
            URLSession.self,
            selector: #selector(URLSession.init(configuration:)),
            methodSignature: (@convention(c) (URLSession, Selector, URLSessionConfiguration) -> URLSession).self,
            swizzleSignature: (@convention(block) (URLSession, URLSessionConfiguration) -> URLSession).self
        ) { store in { selfObject, configuration in
            if URLSession.innerHttpProxyDisabled {
                configuration.connectionProxyDictionary = [:]
            }
            return store.original(selfObject, store.selector, configuration)
        }}
        
        NSObject.fw.swizzleClassMethod(
            URLSession.self,
            selector: #selector(URLSession.init(configuration:delegate:delegateQueue:)),
            methodSignature: (@convention(c) (URLSession, Selector, URLSessionConfiguration, URLSessionDelegate?, OperationQueue?) -> URLSession).self,
            swizzleSignature: (@convention(block) (URLSession, URLSessionConfiguration, URLSessionDelegate?, OperationQueue?) -> URLSession).self
        ) { store in { selfObject, configuration, delegate, delegateQueue in
            if URLSession.innerHttpProxyDisabled {
                configuration.connectionProxyDictionary = [:]
            }
            return store.original(selfObject, store.selector, configuration, delegate, delegateQueue)
        }}
    }
    
}
