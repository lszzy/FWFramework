//
//  UIKit.swift
//  FWFramework
//
//  Created by wuyong on 2022/5/13.
//

import UIKit
#if FWMacroTracking
import AdSupport
#endif

extension Wrapper where Base: UIDevice {
    
    /// 设置设备token原始Data，格式化并保存
    public static func setDeviceTokenData(_ tokenData: Data?) {
        Base.__fw.setDeviceTokenData(tokenData)
    }

    /// 获取设备Token格式化后的字符串
    public static var deviceToken: String? {
        return Base.__fw.deviceToken
    }

    /// 获取设备模型，格式："iPhone6,1"
    public static var deviceModel: String? {
        return Base.__fw.deviceModel
    }

    /// 获取设备IDFV(内部使用)，同账号应用全删除后会改变，可通过keychain持久化
    public static var deviceIDFV: String? {
        return Base.__fw.deviceIDFV
    }

#if FWMacroTracking
    /// 获取设备IDFA(外部使用)，重置广告或系统后会改变，需先检测广告追踪权限，启用Tracking子模块后生效
    public static var deviceIDFA: String {
        return ASIdentifierManager.shared().advertisingIdentifier.uuidString
    }
#endif
    
}

extension Wrapper where Base: UIView {
    
    /// 绘制单边或多边边框视图。使用AutoLayout
    public func setBorderView(_ edge: UIRectEdge, color: UIColor?, width: CGFloat) {
        base.__fw.setBorderView(edge, color: color, width: width)
    }

    /// 绘制单边或多边边框。使用AutoLayout
    public func setBorderView(_ edge: UIRectEdge, color: UIColor?, width: CGFloat, leftInset: CGFloat, rightInset: CGFloat) {
        base.__fw.setBorderView(edge, color: color, width: width, leftInset: leftInset, rightInset: rightInset)
    }
    
}

extension Wrapper where Base: UILabel {
    
    /// 添加点击手势并自动识别NSLinkAttributeName属性点击时触发回调block
    public func addLinkGesture(_ block: @escaping (Any) -> Void) {
        base.__fw.addLinkGesture(block)
    }
    
}
