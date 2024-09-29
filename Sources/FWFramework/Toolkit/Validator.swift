//
//  Validator.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import Foundation

// MARK: - AnyValidator
/// 任意值验证器
///
/// 默认开启类型验证，当Validator<Value>类型转为AnyValidator时，如果value数据类型不匹配，会验证失败
public typealias AnyValidator = Validator<Any>

extension AnyValidator {
    /// 重写为AnyValidator自身
    public var anyValidator: AnyValidator { self }

    /// 重写为AnyValidator自身
    public var unsafeAnyValidator: AnyValidator { self }

    /// 初始化包装验证器并转发调用，默认开启类型验证(可关闭)
    public init<WrappedValue>(
        _ validator: Validator<WrappedValue>,
        validateType: Bool = true
    ) {
        if validateType {
            predicate = { @Sendable value in
                if value == nil {
                    return validator.validate(nil)
                } else if let value = value as? WrappedValue {
                    return validator.validate(value)
                }
                return false
            }
        } else {
            predicate = { @Sendable value in
                validator.validate(value as? WrappedValue)
            }
        }
    }
}

// MARK: - Validator
/// 规则验证器，可扩展
public struct Validator<Value>: Sendable {
    /// 创建可选句柄验证器，值为nil时自行处理
    public static func predicate(
        _ predicate: @escaping @Sendable (Value?) -> Bool
    ) -> Self {
        var validator = Self()
        validator.predicate = predicate
        return validator
    }

    /// 转换为AnyValidator，开启类型验证
    public var anyValidator: AnyValidator {
        AnyValidator(self, validateType: true)
    }

    /// 转换为不安全的AnyValidator，关闭类型验证
    public var unsafeAnyValidator: AnyValidator {
        AnyValidator(self, validateType: false)
    }

    private var predicate: @Sendable (Value?) -> Bool

    /// 默认验证器，值为nil时返回false
    public init() {
        self.predicate = { @Sendable value in
            value != nil
        }
    }

    /// 初始化包装验证器，转发调用
    public init<WrappedValue>(
        _ validator: Validator<WrappedValue>
    ) where WrappedValue? == Value {
        self.predicate = { @Sendable value in
            validator.validate(value as? WrappedValue)
        }
    }

    /// 初始化句柄验证器，值为nil时返回false
    public init(
        _ predicate: @escaping @Sendable (Value) -> Bool
    ) {
        self.predicate = { @Sendable value in
            if let value {
                return predicate(value)
            }
            return false
        }
    }

    /// 执行验证并返回结果
    public func validate(_ value: Value?) -> Bool {
        predicate(value)
    }
}

extension Validator {
    /// Nil有效验证器，仅nil时返回true，兼容嵌套Optional
    public static var isNil: Self {
        .predicate { value in
            Optional<Any>.isNil(value)
        }
    }

    /// 非Nil有效验证器，非nil时返回true，兼容嵌套Optional
    public static var isNotNil: Self {
        .predicate { value in
            !Optional<Any>.isNil(value)
        }
    }

    /// 固定有效验证器，始终返回true
    public static var isValid: Self {
        .predicate { _ in
            true
        }
    }

    /// 固定无效验证器，始终返回false
    public static var isInvalid: Self {
        .predicate { _ in
            false
        }
    }

    /// KeyPath包装验证器
    public static func keyPath<T>(
        _ keyPath: @autoclosure @escaping @Sendable () -> KeyPath<Value, T>,
        _ validator: @autoclosure @escaping @Sendable () -> Validator<T>
    ) -> Self {
        .init { value in
            validator().validate(value[keyPath: keyPath()])
        }
    }

    /// KeyPath验证器
    public static func keyPath(
        _ keyPath: @autoclosure @escaping @Sendable () -> KeyPath<Value, Bool>
    ) -> Self {
        .init { value in
            value[keyPath: keyPath()]
        }
    }

    /// 等于验证器
    public static func ==(
        lhs: Self,
        rhs: Self
    ) -> Self {
        .init { value in
            lhs.validate(value) == rhs.validate(value)
        }
    }

    /// 不等于验证器
    public static func !=(
        lhs: Self,
        rhs: Self
    ) -> Self {
        .init { value in
            lhs.validate(value) != rhs.validate(value)
        }
    }

    /// 非验证器
    public static prefix func !(
        validator: Self
    ) -> Self {
        .init { value in
            !validator.validate(value)
        }
    }

    /// 与验证器
    public static func &&(
        lhs: Self,
        rhs: @autoclosure @escaping @Sendable () -> Self
    ) -> Self {
        .init { value in
            lhs.validate(value) && rhs().validate(value)
        }
    }

    /// 或验证器
    public static func ||(
        lhs: Self,
        rhs: @autoclosure @escaping @Sendable () -> Self
    ) -> Self {
        .init { value in
            lhs.validate(value) || rhs().validate(value)
        }
    }
}

// MARK: - Validator+Extension
extension Validator where Value: BasicType {
    /// 空验证器
    public static var isEmpty: Self {
        .predicate { value in
            if let value {
                return !value.isNotEmpty
            }
            return true
        }
    }

    /// 非空验证器
    public static var isNotEmpty: Self {
        .predicate { value in
            if let value {
                return value.isNotEmpty
            }
            return false
        }
    }
}

extension Validator where Value: Equatable {
    /// 相等验证器
    public static func isEqual(
        _ equatableValue: @autoclosure @escaping @Sendable () -> Value
    ) -> Self {
        .init { value in
            value == equatableValue()
        }
    }
}

extension Validator where Value: Comparable {
    /// 小于验证器
    public static func less(
        _ comparableValue: @autoclosure @escaping @Sendable () -> Value
    ) -> Self {
        .init { value in
            value < comparableValue()
        }
    }

    /// 小于等于验证器
    public static func lessOrEqual(
        _ comparableValue: @autoclosure @escaping @Sendable () -> Value
    ) -> Self {
        .init { value in
            value <= comparableValue()
        }
    }

    /// 大于验证器
    public static func greater(
        _ comparableValue: @autoclosure @escaping @Sendable () -> Value
    ) -> Self {
        .init { value in
            value > comparableValue()
        }
    }

    /// 大于等于验证器
    public static func greaterOrEqual(
        _ comparableValue: @autoclosure @escaping @Sendable () -> Value
    ) -> Self {
        .init { value in
            value >= comparableValue()
        }
    }

    /// 值区间验证器
    public static func between(
        min: @autoclosure @escaping @Sendable () -> Value,
        max: @autoclosure @escaping @Sendable () -> Value
    ) -> Self {
        .init { value in
            value >= min() && value <= max()
        }
    }
}

extension Validator where Value: StringProtocol {
    /// 包含验证器
    public static func contains<S: StringProtocol>(
        _ string: @autoclosure @escaping @Sendable () -> S,
        options: @autoclosure @escaping @Sendable () -> String.CompareOptions = []
    ) -> Self {
        .init { value in
            value.range(of: string(), options: options()) != nil
        }
    }

    /// 包含前缀验证器
    public static func hasPrefix<S: StringProtocol>(
        _ prefix: @autoclosure @escaping @Sendable () -> S
    ) -> Self {
        .init { value in
            value.hasPrefix(prefix())
        }
    }

    /// 包含后缀验证器
    public static func hasSuffix<S: StringProtocol>(
        _ suffix: @autoclosure @escaping @Sendable () -> S
    ) -> Self {
        .init { value in
            value.hasSuffix(suffix())
        }
    }

    /// 指定长度验证器
    public static func length(
        _ count: @autoclosure @escaping @Sendable () -> Int
    ) -> Self {
        .init { value in
            value.count == count()
        }
    }

    /// 长度区间验证器
    public static func length(
        min: @autoclosure @escaping @Sendable () -> Int = 0,
        max: @autoclosure @escaping @Sendable () -> Int
    ) -> Self {
        .init { value in
            value.count >= min() && value.count <= max()
        }
    }
}

extension Validator where Value == String {
    /// 正则验证器
    public static func regex(
        _ rule: String
    ) -> Self {
        .init { value in
            let predicate = NSPredicate(format: "SELF MATCHES %@", rule)
            return predicate.evaluate(with: value)
        }
    }

    /// 英文字母验证器
    public static var isLetter: Self { .regex("^[A-Za-z]+$") }

    /// 字母和数字验证器，不含下划线
    public static var isWord: Self { .regex("^[A-Za-z0-9]+$") }

    /// 整数验证器
    public static var isInteger: Self { .regex("^\\-?([1-9]\\d*|0)$") }

    /// 数字验证器
    public static var isNumber: Self { .regex("^\\-?([1-9]\\d*|0)(\\.\\d+)?$") }

    /// 合法金额验证器，两位小数点
    public static var isMoney: Self { .regex("^([1-9]\\d*|0)(\\.\\d{1,2})?$") }

    /// 中文验证器
    public static var isChinese: Self { .regex("^[\\x{4e00}-\\x{9fa5}]+$") }

    /// 手机号验证器
    public static var isMobile: Self { .regex("^1\\d{10}$") }

    /// 座机号验证器
    public static var isTelephone: Self { .regex("^(\\d{3}\\-)?\\d{8}|(\\d{4}\\-)?\\d{7}$") }

    /// 邮政编码验证器
    public static var isPostcode: Self { .regex("^[0-8]\\d{5}(?!\\d)$") }

    /// 身份证验证器
    public static var isIdcard: Self { .regex("^[1-9]\\d{5}[1-9]\\d{3}((0\\d)|(1[0-2]))(([0|1|2]\\d)|3[0-1])\\d{3}(\\d|x|X)$") }

    /// 邮箱验证器
    public static var isEmail: Self { .regex("^[A-Z0-9a-z._\\%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$") }

    /// 合法时间验证器，格式：yyyy-MM-dd HH:mm:ss
    public static var isDatetime: Self { .regex("^\\d{4}\\-\\d{2}\\-\\d{2}\\s\\d{2}\\:\\d{2}\\:\\d{2}$") }

    /// 合法时间戳验证器，格式：1301234567
    public static var isTimestamp: Self { .regex("^\\d{10}$") }

    /// 坐标点字符串验证器，格式：latitude,longitude
    public static var isCoordinate: Self { .regex("^\\-?\\d+\\.?\\d*,\\-?\\d+\\.?\\d*$") }

    /// URL验证器
    public static var isUrl: Self {
        .init { value in
            value.lowercased().hasPrefix("http://") || value.lowercased().hasPrefix("https://")
        }
    }

    /// HTML验证器
    public static var isHtml: Self {
        .init { value in
            value.range(of: "<[^>]+>", options: .regularExpression) != nil
        }
    }

    /// IPv4验证器
    ///
    /// 正则示例：.regex("^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}$")
    public static var isIPv4: Self {
        .init { value in
            let components = value.components(separatedBy: ".")
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
    }

    /// IPv6验证器
    public static var isIPv6: Self {
        .init { value in
            var sockAddr = sockaddr_in6()
            return value.withCString { cstring in inet_pton(AF_INET6, cstring, &sockAddr.sin6_addr) } == 1
        }
    }
}
