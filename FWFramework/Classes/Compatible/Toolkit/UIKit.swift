//
//  UIKit.swift
//  FWFramework
//
//  Created by wuyong on 2022/5/13.
//

import UIKit
#if FWMacroSPM
import FWFramework
#endif
#if FWMacroTracking
import AdSupport
#endif

// MARK: - UIDevice+UIKit
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

    /// 获取设备IDFA(外部使用)，重置广告或系统后会改变，需先检测广告追踪权限，启用Tracking子模块后生效
    public static var deviceIDFA: String? {
        #if FWMacroTracking
        return ASIdentifierManager.shared().advertisingIdentifier.uuidString
        #else
        return nil
        #endif
    }
    
}

// MARK: - UIView+UIKit
extension Wrapper where Base: UIView {
    
    /// 视图是否可见，视图hidden为NO、alpha>0.01、window存在且size不为0才认为可见
    public var isViewVisible: Bool {
        return base.__fw.isViewVisible
    }

    /// 获取响应的视图控制器
    public var viewController: UIViewController? {
        return base.__fw.viewController
    }

    /// 设置额外热区(点击区域)
    public var touchInsets: UIEdgeInsets {
        get { return base.__fw.touchInsets }
        set { base.__fw.touchInsets = newValue }
    }

    /// 设置自动计算适合高度的frame，需实现sizeThatFits:方法
    public var fitFrame: CGRect {
        get { return base.__fw.fitFrame }
        set { base.__fw.fitFrame = newValue }
    }

    /// 计算当前视图适合大小，需实现sizeThatFits:方法
    public var fitSize: CGSize {
        return base.__fw.fitSize
    }

    /// 计算指定边界，当前视图适合大小，需实现sizeThatFits:方法
    public func fitSize(drawSize: CGSize) -> CGSize {
        return base.__fw.fitSize(withDraw: drawSize)
    }

    /// 设置阴影颜色、偏移和半径
    public func setShadowColor(_ color: UIColor?, offset: CGSize, radius: CGFloat) {
        base.__fw.setShadowColor(color, offset: offset, radius: radius)
    }

    /// 绘制四边边框
    public func setBorderColor(_ color: UIColor?, width: CGFloat) {
        base.__fw.setBorderColor(color, width: width)
    }

    /// 绘制四边边框和四角圆角
    public func setBorderColor(_ color: UIColor?, width: CGFloat, cornerRadius: CGFloat) {
        base.__fw.setBorderColor(color, width: width, cornerRadius: cornerRadius)
    }

    /// 绘制四角圆角
    public func setCornerRadius(_ radius: CGFloat) {
        base.__fw.setCornerRadius(radius)
    }

    /// 绘制单边或多边边框Layer。frame必须存在(添加视图后可调用layoutIfNeeded更新frame)
    public func setBorderLayer(_ edge: UIRectEdge, color: UIColor?, width: CGFloat) {
        base.__fw.setBorderLayer(edge, color: color, width: width)
    }

    /// 绘制单边或多边边框Layer。frame必须存在(添加视图后可调用layoutIfNeeded更新frame)
    public func setBorderLayer(_ edge: UIRectEdge, color: UIColor?, width: CGFloat, leftInset: CGFloat, rightInset: CGFloat) {
        base.__fw.setBorderLayer(edge, color: color, width: width, leftInset: leftInset, rightInset: rightInset)
    }

    /// 绘制单个或多个边框圆角，frame必须存在(添加视图后可调用layoutIfNeeded更新frame)
    public func setCornerLayer(_ corner: UIRectCorner, radius: CGFloat) {
        base.__fw.setCornerLayer(corner, radius: radius)
    }

    /// 绘制单个或多个边框圆角和四边边框，frame必须存在(添加视图后可调用layoutIfNeeded更新frame)
    public func setCornerLayer(_ corner: UIRectCorner, radius: CGFloat, borderColor: UIColor?, width: CGFloat) {
        base.__fw.setCornerLayer(corner, radius: radius, borderColor: borderColor, width: width)
    }
    
    /// 绘制单边或多边边框视图。使用AutoLayout
    public func setBorderView(_ edge: UIRectEdge, color: UIColor?, width: CGFloat) {
        base.__fw.setBorderView(edge, color: color, width: width)
    }

    /// 绘制单边或多边边框。使用AutoLayout
    public func setBorderView(_ edge: UIRectEdge, color: UIColor?, width: CGFloat, leftInset: CGFloat, rightInset: CGFloat) {
        base.__fw.setBorderView(edge, color: color, width: width, leftInset: leftInset, rightInset: rightInset)
    }
    
    /// 开始倒计时，从window移除时自动取消，回调参数为剩余时间
    @discardableResult
    public func startCountDown(_ seconds: Int, block: @escaping (Int) -> Void) -> DispatchSource {
        return base.__fw.startCountDown(seconds, block: block)
    }
    
}

// MARK: - UILabel+UIKit
extension Wrapper where Base: UILabel {
    
    /// 快速设置attributedText样式，设置后调用setText:会自动转发到setAttributedText:方法
    public var textAttributes: [NSAttributedString.Key: Any]? {
        get { return base.__fw.textAttributes }
        set { base.__fw.textAttributes = newValue }
    }

    /// 快速设置文字的行高，优先级低于fwTextAttributes，设置后调用setText:会自动转发到setAttributedText:方法。小于0时恢复默认行高
    public var lineHeight: CGFloat {
        get { return base.__fw.lineHeight }
        set { base.__fw.lineHeight = newValue }
    }

    /// 自定义内容边距，未设置时为系统默认。当内容为空时不参与intrinsicContentSize和sizeThatFits:计算，方便自动布局
    public var contentInset: UIEdgeInsets {
        get { return base.__fw.contentInset }
        set { base.__fw.contentInset = newValue }
    }

    /// 纵向分布方式，默认居中
    public var verticalAlignment: UIControl.ContentVerticalAlignment {
        get { return base.__fw.verticalAlignment }
        set { base.__fw.verticalAlignment = newValue }
    }
    
    /// 添加点击手势并自动识别NSLinkAttributeName属性点击时触发回调block
    public func addLinkGesture(block: @escaping (Any) -> Void) {
        base.__fw.addLinkGesture(block)
    }
    
    /// 获取手势触发位置的文本属性，可实现行内点击效果等，allowsSpacing默认为NO空白处不可点击。为了识别更准确，attributedText需指定font
    public func attributes(gesture: UIGestureRecognizer, allowsSpacing: Bool) -> [NSAttributedString.Key: Any] {
        return base.__fw.attributes(withGesture: gesture, allowsSpacing: allowsSpacing)
    }

    /// 快速设置标签并指定文本
    public func setFont(_ font: UIFont?, textColor: UIColor?, text: String? = nil) {
        base.__fw.setFont(font, textColor: textColor, text: text)
    }
    
    /// 快速创建标签并指定文本
    public static func label(font: UIFont?, textColor: UIColor?, text: String? = nil) -> Base {
        return Base.__fw.label(with: font, textColor: textColor, text: text) as! Base
    }
    
}

// MARK: - UIButton+UIKit
extension Wrapper where Base: UIButton {
    
    /// 自定义按钮禁用时的alpha，如0.5，默认0不生效
    public var disabledAlpha: CGFloat {
        get { return base.__fw.disabledAlpha }
        set { base.__fw.disabledAlpha = newValue }
    }

    /// 自定义按钮高亮时的alpha，如0.5，默认0不生效
    public var highlightedAlpha: CGFloat {
        get { return base.__fw.highlightedAlpha }
        set { base.__fw.highlightedAlpha = newValue }
    }

    /// 快速设置文本按钮
    public func setTitle(_ title: String?, font: UIFont?, textColor: UIColor?) {
        base.__fw.setTitle(title, font: font, titleColor: textColor)
    }

    /// 快速设置文本
    public func setTitle(_ title: String?) {
        base.__fw.setTitle(title)
    }

    /// 快速设置图片
    public func setImage(_ image: UIImage?) {
        base.__fw.setImage(image)
    }

    /// 设置图片的居中边位置，需要在setImage和setTitle之后调用才生效，且button大小大于图片+文字+间距
    ///
    /// imageEdgeInsets: 仅有image时相对于button，都有时上左下相对于button，右相对于title
    /// titleEdgeInsets: 仅有title时相对于button，都有时上右下相对于button，左相对于image
    public func setImageEdge(_ edge: UIRectEdge, spacing: CGFloat) {
        base.__fw.setImageEdge(edge, spacing: spacing)
    }
    
    /// 快速创建文本按钮
    public static func button(title: String?, font: UIFont?, titleColor: UIColor?) -> Base {
        return Base.__fw.button(withTitle: title, font: font, titleColor: titleColor) as! Base
    }

    /// 快速创建图片按钮
    public static func button(image: UIImage?) -> Base {
        return Base.__fw.button(with: image) as! Base
    }
    
}

// MARK: - UIScrollView+UIKit
extension Wrapper where Base: UIScrollView {
    
    /// 判断当前scrollView内容是否足够滚动
    public var canScroll: Bool {
        return base.__fw.canScroll
    }

    /// 判断当前的scrollView内容是否足够水平滚动
    public var canScrollHorizontal: Bool {
        return base.__fw.canScrollHorizontal
    }

    /// 判断当前的scrollView内容是否足够纵向滚动
    public var canScrollVertical: Bool {
        return base.__fw.canScrollVertical
    }

    /// 当前scrollView滚动到指定边
    public func scroll(to edge: UIRectEdge, animated: Bool = true) {
        base.__fw.scroll(to: edge, animated: animated)
    }

    /// 是否已滚动到指定边
    public func isScroll(to edge: UIRectEdge) -> Bool {
        return base.__fw.isScroll(to: edge)
    }

    /// 获取当前的scrollView滚动到指定边时的contentOffset(包含contentInset)
    public func contentOffset(of edge: UIRectEdge) -> CGPoint {
        return base.__fw.contentOffset(of: edge)
    }

    /// 总页数，自动识别翻页方向
    public var totalPage: Int {
        return base.__fw.totalPage
    }

    /// 当前页数，不支持动画，自动识别翻页方向
    public var currentPage: Int {
        get { return base.__fw.currentPage }
        set { base.__fw.currentPage = newValue }
    }

    /// 设置当前页数，支持动画，自动识别翻页方向
    public func setCurrentPage(_ page: Int, animated: Bool = true) {
        base.__fw.setCurrentPage(page, animated: animated)
    }

    /// 是否是最后一页，自动识别翻页方向
    public var isLastPage: Bool {
        return base.__fw.isLastPage
    }
    
}

// MARK: - UIPageControl+UIKit
extension Wrapper where Base: UIPageControl {
    
    /// 自定义圆点大小，默认{10, 10}
    public var preferredSize: CGSize {
        get { return base.__fw.preferredSize }
        set { base.__fw.preferredSize = newValue }
    }
    
}

// MARK: - UISlider+UIKit
extension Wrapper where Base: UISlider {
    
    /// 中间圆球的大小，默认zero
    public var thumbSize: CGSize {
        get { return base.__fw.thumbSize }
        set { base.__fw.thumbSize = newValue }
    }

    /// 中间圆球的颜色，默认nil
    public var thumbColor: UIColor? {
        get { return base.__fw.thumbColor }
        set { base.__fw.thumbColor = newValue }
    }
    
}

// MARK: - UISwitch+UIKit
extension Wrapper where Base: UISwitch {
    
    /// 自定义尺寸大小，默认{51,31}
    public var preferredSize: CGSize {
        get { return base.__fw.preferredSize }
        set { base.__fw.preferredSize = newValue }
    }
    
}

// MARK: - UITextField+UIKit
extension Wrapper where Base: UITextField {
    
    /// 最大字数限制，0为无限制，二选一
    public var maxLength: Int {
        get { return base.__fw.maxLength }
        set { base.__fw.maxLength = newValue }
    }

    /// 最大Unicode字数限制(中文为1，英文为0.5)，0为无限制，二选一
    public var maxUnicodeLength: Int {
        get { return base.__fw.maxUnicodeLength }
        set { base.__fw.maxUnicodeLength = newValue }
    }
    
    /// 自定义文字改变处理句柄，自动trimString，默认nil
    public var textChangedBlock: ((String) -> Void)? {
        get { return base.__fw.textChangedBlock }
        set { base.__fw.textChangedBlock = newValue }
    }

    /// 文本长度发生改变，自动检测字数限制，用于代码设置text等场景
    public func textLengthChanged() {
        base.__fw.textLengthChanged()
    }

    /// 获取满足最大字数限制的过滤后的文本，无需再调用textLengthChanged
    public func filterText(_ text: String) -> String {
        return base.__fw.filterText(text)
    }

    /// 设置自动完成时间间隔，默认1秒，和autoCompleteBlock配套使用
    public var autoCompleteInterval: TimeInterval {
        get { return base.__fw.autoCompleteInterval }
        set { base.__fw.autoCompleteInterval = newValue }
    }

    /// 设置自动完成处理句柄，自动trimString，默认nil，注意输入框内容为空时会立即触发
    public var autoCompleteBlock: ((String) -> Void)? {
        get { return base.__fw.autoCompleteBlock }
        set { base.__fw.autoCompleteBlock = newValue }
    }
    
}

// MARK: - UITextView+UIKit
extension Wrapper where Base: UITextView {
    
    /// 最大字数限制，0为无限制，二选一
    public var maxLength: Int {
        get { return base.__fw.maxLength }
        set { base.__fw.maxLength = newValue }
    }

    /// 最大Unicode字数限制(中文为1，英文为0.5)，0为无限制，二选一
    public var maxUnicodeLength: Int {
        get { return base.__fw.maxUnicodeLength }
        set { base.__fw.maxUnicodeLength = newValue }
    }
    
    /// 自定义文字改变处理句柄，自动trimString，默认nil
    public var textChangedBlock: ((String) -> Void)? {
        get { return base.__fw.textChangedBlock }
        set { base.__fw.textChangedBlock = newValue }
    }

    /// 文本长度发生改变，自动检测字数限制，用于代码设置text等场景
    public func textLengthChanged() {
        base.__fw.textLengthChanged()
    }

    /// 获取满足最大字数限制的过滤后的文本，无需再调用textLengthChanged
    public func filterText(_ text: String) -> String {
        return base.__fw.filterText(text)
    }

    /// 设置自动完成时间间隔，默认1秒，和autoCompleteBlock配套使用
    public var autoCompleteInterval: TimeInterval {
        get { return base.__fw.autoCompleteInterval }
        set { base.__fw.autoCompleteInterval = newValue }
    }

    /// 设置自动完成处理句柄，默认nil，注意输入框内容为空时会立即触发
    public var autoCompleteBlock: ((String) -> Void)? {
        get { return base.__fw.autoCompleteBlock }
        set { base.__fw.autoCompleteBlock = newValue }
    }
    
}

// MARK: - UIViewController+UIKit
extension Wrapper where Base: UIViewController {
    
    /// 判断当前控制器是否是根控制器。如果是导航栏的第一个控制器或者不含有导航栏，则返回YES
    public var isRoot: Bool {
        return base.__fw.isRoot
    }

    /// 判断当前控制器是否是子控制器。如果父控制器存在，且不是导航栏或标签栏控制器，则返回YES
    public var isChild: Bool {
        return base.__fw.isChild
    }

    /// 判断当前控制器是否是present弹出。如果是导航栏的第一个控制器且导航栏是present弹出，也返回YES
    public var isPresented: Bool {
        return base.__fw.isPresented
    }

    /// 判断当前控制器是否是iOS13+默认pageSheet弹出样式。该样式下导航栏高度等与默认样式不同
    public var isPageSheet: Bool {
        return base.__fw.isPageSheet
    }

    /// 视图是否可见，viewWillAppear后为YES，viewDidDisappear后为NO
    public var isViewVisible: Bool {
        return base.__fw.isViewVisible
    }

    /// 是否已经加载完，默认NO，加载完成后可标记为YES，可用于第一次加载时显示loading等判断
    public var isLoaded: Bool {
        get { return base.__fw.isLoaded }
        set { base.__fw.isLoaded = newValue }
    }
    
}
