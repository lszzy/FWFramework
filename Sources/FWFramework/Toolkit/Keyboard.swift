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
@_spi(FW) @objc extension UITextField {
    
    // MARK: - Keyboard
    /// 是否启用键盘管理(自动滚动)，默认NO
    public var fw_keyboardManager: Bool {
        get { return self.__fw_keyboardManager }
        set { self.__fw_keyboardManager = newValue }
    }

    /// 设置输入框和键盘的空白间距，默认10.0
    public var fw_keyboardDistance: CGFloat {
        get { return self.__fw_keyboardDistance }
        set { self.__fw_keyboardDistance = newValue }
    }

    /// 设置输入框和键盘的回弹触发最小距离，默认0始终回弹
    public var fw_reboundDistance: CGFloat {
        get { return self.__fw_reboundDistance }
        set { self.__fw_reboundDistance = newValue }
    }

    /// 是否启用键盘后台关闭处理，退后台时收起键盘，回到前台时恢复键盘，解决系统退后台输入框跳动问题，默认NO
    public var fw_keyboardResign: Bool {
        get { return self.__fw_keyboardResign }
        set { self.__fw_keyboardResign = newValue }
    }
    
    /// 是否启用点击背景关闭键盘(会继续触发其它点击事件)，默认NO
    public var fw_touchResign: Bool {
        get { return self.__touchResign }
        set { self.__touchResign = newValue }
    }
    
    /// 指定用于键盘管理滚动的scrollView，默认为nil，通过修改VC.view.frame实现
    public weak var fw_keyboardScrollView: UIScrollView? {
        get { return self.__fw_keyboardScrollView }
        set { self.__fw_keyboardScrollView = newValue }
    }
    
    // MARK: - Return
    /// 点击键盘完成按钮是否关闭键盘，默认NO，二选一
    public var fw_returnResign: Bool {
        get { return self.__fw_returnResign }
        set { self.__fw_returnResign = newValue }
    }

    /// 设置点击键盘完成按钮是否自动切换下一个输入框，二选一
    public var fw_returnNext: Bool {
        get { return self.__fw_returnNext }
        set { self.__fw_returnNext = newValue }
    }

    /// 设置点击键盘完成按钮的事件句柄
    public var fw_returnBlock: ((UITextField) -> Void)? {
        get { return self.__fw_returnBlock }
        set { self.__fw_returnBlock = newValue }
    }
    
    // MARK: - Toolbar
    /// 获取关联的键盘Toolbar对象，可自定义样式
    public var fw_keyboardToolbar: UIToolbar {
        get { return self.__fw_keyboardToolbar }
        set { self.__fw_keyboardToolbar = newValue }
    }

    /// 自定义键盘Toolbar上一个按钮，支持图片|字符串等(详见FWBlock)，默认朝上的箭头
    public var fw_toolbarPreviousButton: Any? {
        get { return self.__fw_toolbarPreviousButton }
        set { self.__fw_toolbarPreviousButton = newValue }
    }

    /// 自定义键盘Toolbar下一个按钮，支持图片|字符串等(详见FWBlock)，默认朝下的箭头
    public var fw_toolbarNextButton: Any? {
        get { return self.__fw_toolbarNextButton }
        set { self.__fw_toolbarNextButton = newValue }
    }

    /// 自定义键盘Toolbar完成按钮，支持图片|字符串等(详见FWBlock)，默认Done
    public var fw_toolbarDoneButton: Any? {
        get { return self.__fw_toolbarDoneButton }
        set { self.__fw_toolbarDoneButton = newValue }
    }

    /// 设置Toolbar点击前一个按钮时聚焦的输入框句柄，默认nil
    public var fw_previousResponder: ((UITextField) -> UIResponder?)? {
        get { return self.__fw_previousResponder }
        set { self.__fw_previousResponder = newValue }
    }

    /// 设置Toolbar点击下一个按钮时聚焦的输入框句柄，默认nil
    public var fw_nextResponder: ((UITextField) -> UIResponder?)? {
        get { return self.__fw_nextResponder }
        set { self.__fw_nextResponder = newValue }
    }
    
    /// 设置Toolbar点击前一个按钮时聚焦的输入框tag，默认0不生效
    public var fw_previousResponderTag: Int {
        get { return self.__fw_previousResponderTag }
        set { self.__fw_previousResponderTag = newValue }
    }

    /// 设置Toolbar点击下一个按钮时聚焦的输入框tag，默认0不生效
    public var fw_nextResponderTag: Int {
        get { return self.__fw_nextResponderTag }
        set { self.__fw_nextResponderTag = newValue }
    }
    
    /// 自动跳转前一个输入框，优先使用previousResponder，其次根据responderTag查找
    public func fw_goPrevious() {
        self.__fw_goPrevious()
    }

    /// 自动跳转后一个输入框，优先使用nextResponder，其次根据responderTag查找
    public func fw_goNext() {
        self.__fw_goNext()
    }
    
    /// 获取键盘弹出时的高度，对应Key为UIKeyboardFrameEndUserInfoKey
    public func fw_keyboardHeight(_ notification: Notification) -> CGFloat {
        return self.__fw_keyboardHeight(notification)
    }

    /// 执行键盘跟随动画，支持AutoLayout，可通过keyboardHeight:获取键盘高度
    public func fw_keyboardAnimate(_ notification: Notification, animations: @escaping () -> Void, completion: ((Bool) -> Void)? = nil) {
        self.__fw_keyboardAnimate(notification, animations: animations, completion: completion)
    }
    
    /// 添加Toolbar，指定标题和完成句柄，使用默认按钮
    /// - Parameters:
    ///   - title: 标题，不能点击
    ///   - doneBlock: 右侧完成按钮句柄，默认收起键盘
    public func fw_addToolbar(title: Any?, doneBlock: ((Any) -> Void)?) {
        self.__fw_addToolbar(withTitle: title, doneBlock: doneBlock)
    }
    
    /// 添加Toolbar，指定居中标题、左侧上一个、下一个按钮和右边按钮
    /// - Parameters:
    ///   - titleItem: 居中标题按钮
    ///   - previousItem: 左侧前一个按钮
    ///   - nextItem: 左侧下一个按钮
    ///   - doneItem: 右侧完成按钮
    public func fw_addToolbar(titleItem: UIBarButtonItem?, previousItem: UIBarButtonItem?, nextItem: UIBarButtonItem?, doneItem: UIBarButtonItem?) {
        self.__fw_addToolbar(withTitleItem: titleItem, previousItem: previousItem, nextItem: nextItem, doneItem: doneItem)
    }
    
}

// MARK: - UITextView+Keyboard
@_spi(FW) @objc extension UITextView {
    
    // MARK: - Keyboard
    /// 是否启用键盘管理(自动滚动)，默认NO
    public var fw_keyboardManager: Bool {
        get { return self.__fw_keyboardManager }
        set { self.__fw_keyboardManager = newValue }
    }

    /// 设置输入框和键盘的空白间距，默认10.0
    public var fw_keyboardDistance: CGFloat {
        get { return self.__fw_keyboardDistance }
        set { self.__fw_keyboardDistance = newValue }
    }

    /// 设置输入框和键盘的回弹触发最小距离，默认0始终回弹
    public var fw_reboundDistance: CGFloat {
        get { return self.__fw_reboundDistance }
        set { self.__fw_reboundDistance = newValue }
    }

    /// 是否启用键盘后台关闭处理，退后台时收起键盘，回到前台时恢复键盘，解决系统退后台输入框跳动问题，默认NO
    public var fw_keyboardResign: Bool {
        get { return self.__fw_keyboardResign }
        set { self.__fw_keyboardResign = newValue }
    }
    
    /// 是否启用点击背景关闭键盘(会继续触发其它点击事件)，默认NO
    public var fw_touchResign: Bool {
        get { return self.__fw_touchResign }
        set { self.__fw_touchResign = newValue }
    }
    
    /// 指定用于键盘管理滚动的scrollView，默认为nil，通过修改VC.view.frame实现
    public weak var fw_keyboardScrollView: UIScrollView? {
        get { return self.__fw_keyboardScrollView }
        set { self.__fw_keyboardScrollView = newValue }
    }
    
    // MARK: - Return
    /// 点击键盘完成按钮是否关闭键盘，默认NO，二选一。此方法会修改delegate，可使用fwDelegate访问原始delegate
    public var fw_returnResign: Bool {
        get { return self.__fw_returnResign }
        set { self.__fw_returnResign = newValue }
    }

    /// 设置点击键盘完成按钮是否自动切换下一个输入框，二选一。此方法会修改delegate，可使用fwDelegate访问原始delegate
    public var fw_returnNext: Bool {
        get { return self.__fw_returnNext }
        set { self.__fw_returnNext = newValue }
    }

    /// 设置点击键盘完成按钮的事件句柄。此方法会修改delegate，可使用fwDelegate访问原始delegate
    public var fw_returnBlock: ((UITextView) -> Void)? {
        get { return self.__fw_returnBlock }
        set { self.__fw_returnBlock = newValue }
    }
    
    /// 调用上面三个方法后会修改delegate，此方法始终访问外部delegate
    public weak var fw_delegate: UITextViewDelegate? {
        get { return self.__fw_delegate }
        set { self.__fw_delegate = newValue }
    }
    
    // MARK: - Toolbar
    /// 获取关联的键盘Toolbar对象，可自定义样式
    public var fw_keyboardToolbar: UIToolbar {
        get { return self.__fw_keyboardToolbar }
        set { self.__fw_keyboardToolbar = newValue }
    }

    /// 自定义键盘Toolbar上一个按钮，支持图片|字符串等(详见FWBlock)，默认朝上的箭头
    public var fw_toolbarPreviousButton: Any? {
        get { return self.__fw_toolbarPreviousButton }
        set { self.__fw_toolbarPreviousButton = newValue }
    }

    /// 自定义键盘Toolbar下一个按钮，支持图片|字符串等(详见FWBlock)，默认朝下的箭头
    public var fw_toolbarNextButton: Any? {
        get { return self.__fw_toolbarNextButton }
        set { self.__fw_toolbarNextButton = newValue }
    }

    /// 自定义键盘Toolbar完成按钮，支持图片|字符串等(详见FWBlock)，默认Done
    public var fw_toolbarDoneButton: Any? {
        get { return self.__fw_toolbarDoneButton }
        set { self.__fw_toolbarDoneButton = newValue }
    }

    /// 设置Toolbar点击前一个按钮时聚焦的输入框句柄，默认nil
    public var fw_previousResponder: ((UITextView) -> UIResponder?)? {
        get { return self.__fw_previousResponder }
        set { self.__fw_previousResponder = newValue }
    }

    /// 设置Toolbar点击下一个按钮时聚焦的输入框句柄，默认nil
    public var fw_nextResponder: ((UITextView) -> UIResponder?)? {
        get { return self.__fw_nextResponder }
        set { self.__fw_nextResponder = newValue }
    }
    
    /// 设置Toolbar点击前一个按钮时聚焦的输入框tag，默认0不生效
    public var fw_previousResponderTag: Int {
        get { return self.__fw_previousResponderTag }
        set { self.__fw_previousResponderTag = newValue }
    }

    /// 设置Toolbar点击下一个按钮时聚焦的输入框tag，默认0不生效
    public var fw_nextResponderTag: Int {
        get { return self.__fw_nextResponderTag }
        set { self.__fw_nextResponderTag = newValue }
    }
    
    /// 自动跳转前一个输入框，优先使用previousResponder，其次根据responderTag查找
    public func fw_goPrevious() {
        self.__fw_goPrevious()
    }

    /// 自动跳转后一个输入框，优先使用nextResponder，其次根据responderTag查找
    public func fw_goNext() {
        self.__fw_goNext()
    }
    
    /// 获取键盘弹出时的高度，对应Key为UIKeyboardFrameEndUserInfoKey
    public func fw_keyboardHeight(_ notification: Notification) -> CGFloat {
        return self.__fw_keyboardHeight(notification)
    }

    /// 执行键盘跟随动画，支持AutoLayout，可通过keyboardHeight:获取键盘高度
    public func fw_keyboardAnimate(_ notification: Notification, animations: @escaping () -> Void, completion: ((Bool) -> Void)? = nil) {
        self.__fw_keyboardAnimate(notification, animations: animations, completion: completion)
    }
    
    /// 添加Toolbar，指定标题和完成句柄，使用默认按钮
    /// - Parameters:
    ///   - title: 标题，不能点击
    ///   - doneBlock: 右侧完成按钮句柄，默认收起键盘
    public func fw_addToolbar(title: Any?, doneBlock: ((Any) -> Void)?) {
        self.__fw_addToolbar(withTitle: title, doneBlock: doneBlock)
    }
    
    /// 添加Toolbar，指定居中标题、左侧上一个、下一个按钮和右边按钮
    /// - Parameters:
    ///   - titleItem: 居中标题按钮
    ///   - previousItem: 左侧前一个按钮
    ///   - nextItem: 左侧下一个按钮
    ///   - doneItem: 右侧完成按钮
    public func fw_addToolbar(titleItem: UIBarButtonItem?, previousItem: UIBarButtonItem?, nextItem: UIBarButtonItem?, doneItem: UIBarButtonItem?) {
        self.__fw_addToolbar(withTitleItem: titleItem, previousItem: previousItem, nextItem: nextItem, doneItem: doneItem)
    }
    
}

// MARK: - UITextView+Placeholder
@_spi(FW) @objc extension UITextView {
    
    /// 占位文本，默认nil
    public var fw_placeholder: String? {
        get { return self.__fw_placeholder }
        set { self.__fw_placeholder = newValue }
    }

    /// 占位颜色，默认系统颜色
    public var fw_placeholderColor: UIColor? {
        get { return self.__fw_placeholderColor }
        set { self.__fw_placeholderColor = newValue }
    }

    /// 带属性占位文本，默认nil
    public var fw_attributedPlaceholder: NSAttributedString? {
        get { return self.__fw_attributedPlaceholder }
        set { self.__fw_attributedPlaceholder = newValue }
    }

    /// 自定义占位文本内间距，默认zero与内容一致
    public var fw_placeholderInset: UIEdgeInsets {
        get { return self.__fw_placeholderInset }
        set { self.__fw_placeholderInset = newValue }
    }

    /// 自定义垂直分布方式，会自动修改contentInset，默认Top与系统一致
    public var fw_verticalAlignment: UIControl.ContentVerticalAlignment {
        get { return self.__fw_verticalAlignment }
        set { self.__fw_verticalAlignment = newValue }
    }

    /// 是否启用自动高度功能，随文字改变高度
    public var fw_autoHeightEnabled: Bool {
        get { return self.__fw_autoHeightEnabled }
        set { self.__fw_autoHeightEnabled = newValue }
    }

    /// 最大高度，默认CGFLOAT_MAX，启用自动高度后生效
    public var fw_maxHeight: CGFloat {
        get { return self.__fw_maxHeight }
        set { self.__fw_maxHeight = newValue }
    }

    /// 最小高度，默认0，启用自动高度后生效
    public var fw_minHeight: CGFloat {
        get { return self.__fw_minHeight }
        set { self.__fw_minHeight = newValue }
    }

    /// 高度改变回调句柄，默认nil，启用自动高度后生效
    public var fw_heightDidChange: ((CGFloat) -> Void)? {
        get { return self.__fw_heightDidChange }
        set { self.__fw_heightDidChange = newValue }
    }

    /// 快捷启用自动高度，并设置最大高度和回调句柄
    public func fw_autoHeight(maxHeight: CGFloat, didChange: ((CGFloat) -> Void)?) {
        self.__fw_autoHeight(withMaxHeight: maxHeight, didChange: didChange)
    }
    
}
