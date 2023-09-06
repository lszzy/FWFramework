//
//  Keyboard.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit
#if FWMacroSPM
import FWObjC
#endif

// MARK: - UITextField+Keyboard
extension Wrapper where Base: UITextField {
    
    // MARK: - Keyboard
    /// 是否启用键盘管理(自动滚动)，默认NO
    public var keyboardManager: Bool {
        get { return base.__fw_keyboardManager }
        set { base.__fw_keyboardManager = newValue }
    }

    /// 设置输入框和键盘的空白间距，默认10.0
    public var keyboardDistance: CGFloat {
        get { return base.__fw_keyboardDistance }
        set { base.__fw_keyboardDistance = newValue }
    }
    
    /// 设置输入框和键盘的空白间距句柄，参数为键盘高度、输入框高度，优先级高，默认nil
    public var keyboardDistanceBlock: ((_ keyboardHeight: CGFloat, _ height: CGFloat) -> CGFloat)? {
        get { return base.__fw_keyboardDistanceBlock }
        set { base.__fw_keyboardDistanceBlock = newValue }
    }

    /// 设置输入框和键盘的回弹触发最小距离，默认0始终回弹
    public var reboundDistance: CGFloat {
        get { return base.__fw_reboundDistance }
        set { base.__fw_reboundDistance = newValue }
    }

    /// 是否启用键盘后台关闭处理，退后台时收起键盘，回到前台时恢复键盘，解决系统退后台输入框跳动问题，默认NO
    public var keyboardResign: Bool {
        get { return base.__fw_keyboardResign }
        set { base.__fw_keyboardResign = newValue }
    }
    
    /// 是否启用点击背景关闭键盘(会继续触发其它点击事件)，默认NO
    public var touchResign: Bool {
        get { return base.__fw_touchResign }
        set { base.__fw_touchResign = newValue }
    }
    
    /// 指定用于键盘管理滚动的scrollView，默认为nil，通过修改VC.view.frame实现
    public weak var keyboardScrollView: UIScrollView? {
        get { return base.__fw_keyboardScrollView }
        set { base.__fw_keyboardScrollView = newValue }
    }
    
    // MARK: - Return
    /// 点击键盘完成按钮是否关闭键盘，默认NO，二选一
    public var returnResign: Bool {
        get { return base.__fw_returnResign }
        set { base.__fw_returnResign = newValue }
    }

    /// 设置点击键盘完成按钮是否自动切换下一个输入框，二选一
    public var returnNext: Bool {
        get { return base.__fw_returnNext }
        set { base.__fw_returnNext = newValue }
    }

    /// 设置点击键盘完成按钮的事件句柄
    public var returnBlock: ((UITextField) -> Void)? {
        get { return base.__fw_returnBlock }
        set { base.__fw_returnBlock = newValue }
    }
    
    // MARK: - Toolbar
    /// 获取关联的键盘Toolbar对象，可自定义样式
    public var keyboardToolbar: UIToolbar {
        get { return base.__fw_keyboardToolbar }
        set { base.__fw_keyboardToolbar = newValue }
    }

    /// 自定义键盘Toolbar上一个按钮，支持图片|字符串等(详见FWBlock)，默认朝上的箭头
    public var toolbarPreviousButton: Any? {
        get { return base.__fw_toolbarPreviousButton }
        set { base.__fw_toolbarPreviousButton = newValue }
    }

    /// 自定义键盘Toolbar下一个按钮，支持图片|字符串等(详见FWBlock)，默认朝下的箭头
    public var toolbarNextButton: Any? {
        get { return base.__fw_toolbarNextButton }
        set { base.__fw_toolbarNextButton = newValue }
    }

    /// 自定义键盘Toolbar完成按钮，支持图片|字符串等(详见FWBlock)，默认Done
    public var toolbarDoneButton: Any? {
        get { return base.__fw_toolbarDoneButton }
        set { base.__fw_toolbarDoneButton = newValue }
    }

    /// 设置Toolbar点击前一个按钮时聚焦的输入框句柄，默认nil
    public var previousResponder: ((UITextField) -> UIResponder?)? {
        get { return base.__fw_previousResponder }
        set { base.__fw_previousResponder = newValue }
    }

    /// 设置Toolbar点击下一个按钮时聚焦的输入框句柄，默认nil
    public var nextResponder: ((UITextField) -> UIResponder?)? {
        get { return base.__fw_nextResponder }
        set { base.__fw_nextResponder = newValue }
    }
    
    /// 设置Toolbar点击前一个按钮时聚焦的输入框tag，默认0不生效
    public var previousResponderTag: Int {
        get { return base.__fw_previousResponderTag }
        set { base.__fw_previousResponderTag = newValue }
    }

    /// 设置Toolbar点击下一个按钮时聚焦的输入框tag，默认0不生效
    public var nextResponderTag: Int {
        get { return base.__fw_nextResponderTag }
        set { base.__fw_nextResponderTag = newValue }
    }
    
    /// 自动跳转前一个输入框，优先使用previousResponder，其次根据responderTag查找
    public func goPrevious() {
        base.__fw_goPrevious()
    }

    /// 自动跳转后一个输入框，优先使用nextResponder，其次根据responderTag查找
    public func goNext() {
        base.__fw_goNext()
    }
    
    /// 获取键盘弹出时的高度，对应Key为UIKeyboardFrameEndUserInfoKey
    public func keyboardHeight(_ notification: Notification) -> CGFloat {
        return base.__fw_keyboardHeight(notification)
    }

    /// 执行键盘跟随动画，支持AutoLayout，可通过keyboardHeight:获取键盘高度
    public func keyboardAnimate(_ notification: Notification, animations: @escaping () -> Void, completion: ((Bool) -> Void)? = nil) {
        base.__fw_keyboardAnimate(notification, animations: animations, completion: completion)
    }
    
    /// 添加Toolbar，指定标题和完成句柄，使用默认按钮
    /// - Parameters:
    ///   - title: 标题，不能点击
    ///   - doneBlock: 右侧完成按钮句柄，默认收起键盘
    public func addToolbar(title: Any?, doneBlock: ((Any) -> Void)?) {
        base.__fw_addToolbar(withTitle: title, doneBlock: doneBlock)
    }
    
    /// 添加Toolbar，指定居中标题、左侧上一个、下一个按钮和右边按钮
    /// - Parameters:
    ///   - titleItem: 居中标题按钮
    ///   - previousItem: 左侧前一个按钮
    ///   - nextItem: 左侧下一个按钮
    ///   - doneItem: 右侧完成按钮
    public func addToolbar(titleItem: UIBarButtonItem?, previousItem: UIBarButtonItem?, nextItem: UIBarButtonItem?, doneItem: UIBarButtonItem?) {
        base.__fw_addToolbar(withTitleItem: titleItem, previousItem: previousItem, nextItem: nextItem, doneItem: doneItem)
    }
    
}

// MARK: - UITextView+Keyboard
extension Wrapper where Base: UITextView {
    
    // MARK: - Keyboard
    /// 是否启用键盘管理(自动滚动)，默认NO
    public var keyboardManager: Bool {
        get { return base.__fw_keyboardManager }
        set { base.__fw_keyboardManager = newValue }
    }

    /// 设置输入框和键盘的空白间距，默认10.0
    public var keyboardDistance: CGFloat {
        get { return base.__fw_keyboardDistance }
        set { base.__fw_keyboardDistance = newValue }
    }
    
    /// 设置输入框和键盘的空白间距句柄，参数为键盘高度、输入框高度，优先级高，默认nil
    public var keyboardDistanceBlock: ((_ keyboardHeight: CGFloat, _ height: CGFloat) -> CGFloat)? {
        get { return base.__fw_keyboardDistanceBlock }
        set { base.__fw_keyboardDistanceBlock = newValue }
    }

    /// 设置输入框和键盘的回弹触发最小距离，默认0始终回弹
    public var reboundDistance: CGFloat {
        get { return base.__fw_reboundDistance }
        set { base.__fw_reboundDistance = newValue }
    }

    /// 是否启用键盘后台关闭处理，退后台时收起键盘，回到前台时恢复键盘，解决系统退后台输入框跳动问题，默认NO
    public var keyboardResign: Bool {
        get { return base.__fw_keyboardResign }
        set { base.__fw_keyboardResign = newValue }
    }
    
    /// 是否启用点击背景关闭键盘(会继续触发其它点击事件)，默认NO
    public var touchResign: Bool {
        get { return base.__fw_touchResign }
        set { base.__fw_touchResign = newValue }
    }
    
    /// 指定用于键盘管理滚动的scrollView，默认为nil，通过修改VC.view.frame实现
    public weak var keyboardScrollView: UIScrollView? {
        get { return base.__fw_keyboardScrollView }
        set { base.__fw_keyboardScrollView = newValue }
    }
    
    // MARK: - Return
    /// 点击键盘完成按钮是否关闭键盘，默认NO，二选一。此方法会修改delegate，可使用fwDelegate访问原始delegate
    public var returnResign: Bool {
        get { return base.__fw_returnResign }
        set { base.__fw_returnResign = newValue }
    }

    /// 设置点击键盘完成按钮是否自动切换下一个输入框，二选一。此方法会修改delegate，可使用fwDelegate访问原始delegate
    public var returnNext: Bool {
        get { return base.__fw_returnNext }
        set { base.__fw_returnNext = newValue }
    }

    /// 设置点击键盘完成按钮的事件句柄。此方法会修改delegate，可使用fwDelegate访问原始delegate
    public var returnBlock: ((UITextView) -> Void)? {
        get { return base.__fw_returnBlock }
        set { base.__fw_returnBlock = newValue }
    }
    
    /// 调用上面三个方法后会修改delegate，此方法始终访问外部delegate
    public weak var delegate: UITextViewDelegate? {
        get { return base.__fw_delegate }
        set { base.__fw_delegate = newValue }
    }
    
    // MARK: - Toolbar
    /// 获取关联的键盘Toolbar对象，可自定义样式
    public var keyboardToolbar: UIToolbar {
        get { return base.__fw_keyboardToolbar }
        set { base.__fw_keyboardToolbar = newValue }
    }

    /// 自定义键盘Toolbar上一个按钮，支持图片|字符串等(详见FWBlock)，默认朝上的箭头
    public var toolbarPreviousButton: Any? {
        get { return base.__fw_toolbarPreviousButton }
        set { base.__fw_toolbarPreviousButton = newValue }
    }

    /// 自定义键盘Toolbar下一个按钮，支持图片|字符串等(详见FWBlock)，默认朝下的箭头
    public var toolbarNextButton: Any? {
        get { return base.__fw_toolbarNextButton }
        set { base.__fw_toolbarNextButton = newValue }
    }

    /// 自定义键盘Toolbar完成按钮，支持图片|字符串等(详见FWBlock)，默认Done
    public var toolbarDoneButton: Any? {
        get { return base.__fw_toolbarDoneButton }
        set { base.__fw_toolbarDoneButton = newValue }
    }

    /// 设置Toolbar点击前一个按钮时聚焦的输入框句柄，默认nil
    public var previousResponder: ((UITextView) -> UIResponder?)? {
        get { return base.__fw_previousResponder }
        set { base.__fw_previousResponder = newValue }
    }

    /// 设置Toolbar点击下一个按钮时聚焦的输入框句柄，默认nil
    public var nextResponder: ((UITextView) -> UIResponder?)? {
        get { return base.__fw_nextResponder }
        set { base.__fw_nextResponder = newValue }
    }
    
    /// 设置Toolbar点击前一个按钮时聚焦的输入框tag，默认0不生效
    public var previousResponderTag: Int {
        get { return base.__fw_previousResponderTag }
        set { base.__fw_previousResponderTag = newValue }
    }

    /// 设置Toolbar点击下一个按钮时聚焦的输入框tag，默认0不生效
    public var nextResponderTag: Int {
        get { return base.__fw_nextResponderTag }
        set { base.__fw_nextResponderTag = newValue }
    }
    
    /// 自动跳转前一个输入框，优先使用previousResponder，其次根据responderTag查找
    public func goPrevious() {
        base.__fw_goPrevious()
    }

    /// 自动跳转后一个输入框，优先使用nextResponder，其次根据responderTag查找
    public func goNext() {
        base.__fw_goNext()
    }
    
    /// 获取键盘弹出时的高度，对应Key为UIKeyboardFrameEndUserInfoKey
    public func keyboardHeight(_ notification: Notification) -> CGFloat {
        return base.__fw_keyboardHeight(notification)
    }

    /// 执行键盘跟随动画，支持AutoLayout，可通过keyboardHeight:获取键盘高度
    public func keyboardAnimate(_ notification: Notification, animations: @escaping () -> Void, completion: ((Bool) -> Void)? = nil) {
        base.__fw_keyboardAnimate(notification, animations: animations, completion: completion)
    }
    
    /// 添加Toolbar，指定标题和完成句柄，使用默认按钮
    /// - Parameters:
    ///   - title: 标题，不能点击
    ///   - doneBlock: 右侧完成按钮句柄，默认收起键盘
    public func addToolbar(title: Any?, doneBlock: ((Any) -> Void)?) {
        base.__fw_addToolbar(withTitle: title, doneBlock: doneBlock)
    }
    
    /// 添加Toolbar，指定居中标题、左侧上一个、下一个按钮和右边按钮
    /// - Parameters:
    ///   - titleItem: 居中标题按钮
    ///   - previousItem: 左侧前一个按钮
    ///   - nextItem: 左侧下一个按钮
    ///   - doneItem: 右侧完成按钮
    public func addToolbar(titleItem: UIBarButtonItem?, previousItem: UIBarButtonItem?, nextItem: UIBarButtonItem?, doneItem: UIBarButtonItem?) {
        base.__fw_addToolbar(withTitleItem: titleItem, previousItem: previousItem, nextItem: nextItem, doneItem: doneItem)
    }
    
}

// MARK: - UITextView+Placeholder
extension Wrapper where Base: UITextView {
    
    /// 占位文本，默认nil
    public var placeholder: String? {
        get { return base.__fw_placeholder }
        set { base.__fw_placeholder = newValue }
    }

    /// 占位颜色，默认系统颜色
    public var placeholderColor: UIColor? {
        get { return base.__fw_placeholderColor }
        set { base.__fw_placeholderColor = newValue }
    }

    /// 带属性占位文本，默认nil
    public var attributedPlaceholder: NSAttributedString? {
        get { return base.__fw_attributedPlaceholder }
        set { base.__fw_attributedPlaceholder = newValue }
    }

    /// 自定义占位文本内间距，默认zero与内容一致
    public var placeholderInset: UIEdgeInsets {
        get { return base.__fw_placeholderInset }
        set { base.__fw_placeholderInset = newValue }
    }

    /// 自定义垂直分布方式，会自动修改contentInset，默认Top与系统一致
    public var verticalAlignment: UIControl.ContentVerticalAlignment {
        get { return base.__fw_verticalAlignment }
        set { base.__fw_verticalAlignment = newValue }
    }
    
    /// 快捷设置行高，兼容placeholder和typingAttributes
    public var lineHeight: CGFloat {
        get { return base.__fw_lineHeight }
        set { base.__fw_lineHeight = newValue }
    }

    /// 是否启用自动高度功能，随文字改变高度
    public var autoHeightEnabled: Bool {
        get { return base.__fw_autoHeightEnabled }
        set { base.__fw_autoHeightEnabled = newValue }
    }

    /// 最大高度，默认CGFLOAT_MAX，启用自动高度后生效
    public var maxHeight: CGFloat {
        get { return base.__fw_maxHeight }
        set { base.__fw_maxHeight = newValue }
    }

    /// 最小高度，默认0，启用自动高度后生效
    public var minHeight: CGFloat {
        get { return base.__fw_minHeight }
        set { base.__fw_minHeight = newValue }
    }

    /// 高度改变回调句柄，默认nil，启用自动高度后生效
    public var heightDidChange: ((CGFloat) -> Void)? {
        get { return base.__fw_heightDidChange }
        set { base.__fw_heightDidChange = newValue }
    }

    /// 快捷启用自动高度，并设置最大高度和回调句柄
    public func autoHeight(maxHeight: CGFloat, didChange: ((CGFloat) -> Void)?) {
        base.__fw_autoHeight(withMaxHeight: maxHeight, didChange: didChange)
    }
    
}
