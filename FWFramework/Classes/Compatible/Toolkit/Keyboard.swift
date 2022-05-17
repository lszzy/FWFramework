//
//  Keyboard.swift
//  FWFramework
//
//  Created by wuyong on 2022/5/13.
//

import UIKit

// MARK: - UITextField+Keyboard
extension Wrapper where Base: UITextField {
    
    // MARK: - Keyboard
    /// 是否启用键盘管理(自动滚动)，默认NO
    public var keyboardManager: Bool {
        get { return base.__fw.keyboardManager }
        set { base.__fw.keyboardManager = newValue }
    }

    /// 设置输入框和键盘的空白间距，默认10.0
    public var keyboardDistance: CGFloat {
        get { return base.__fw.keyboardDistance }
        set { base.__fw.keyboardDistance = newValue }
    }

    /// 设置输入框和键盘的回弹触发最小距离，默认0始终回弹
    public var reboundDistance: CGFloat {
        get { return base.__fw.reboundDistance }
        set { base.__fw.reboundDistance = newValue }
    }

    /// 是否启用键盘后台关闭处理，退后台时收起键盘，回到前台时恢复键盘，解决系统退后台输入框跳动问题，默认NO
    public var keyboardResign: Bool {
        get { return base.__fw.keyboardResign }
        set { base.__fw.keyboardResign = newValue }
    }
    
    /// 是否启用点击背景关闭键盘(会继续触发其它点击事件)，默认NO
    public var touchResign: Bool {
        get { return base.__fw.touchResign }
        set { base.__fw.touchResign = newValue }
    }
    
    /// 指定用于键盘管理滚动的scrollView，默认为nil，通过修改VC.view.frame实现
    public weak var keyboardScrollView: UIScrollView? {
        get { return base.__fw.keyboardScrollView }
        set { base.__fw.keyboardScrollView = newValue }
    }
    
    // MARK: - Return
    /// 点击键盘完成按钮是否关闭键盘，默认NO，二选一
    public var returnResign: Bool {
        get { return base.__fw.returnResign }
        set { base.__fw.returnResign = newValue }
    }

    /// 设置点击键盘完成按钮自动切换的下一个输入框，二选一
    public weak var returnResponder: UIResponder? {
        get { return base.__fw.returnResponder }
        set { base.__fw.returnResponder = newValue }
    }

    /// 设置点击键盘完成按钮的事件句柄
    public var returnBlock: ((UITextField) -> Void)? {
        get { return base.__fw.returnBlock }
        set { base.__fw.returnBlock = newValue }
    }
    
    // MARK: - Toolbar
    /// 获取关联的键盘Toolbar对象，可自定义样式
    public var keyboardToolbar: UIToolbar {
        get { return base.__fw.keyboardToolbar }
        set { base.__fw.keyboardToolbar = newValue }
    }

    /// 自定义键盘Toolbar上一个按钮，支持图片|字符串等(详见FWBlock)，默认朝上的箭头
    public var toolbarPreviousButton: Any {
        get { return base.__fw.toolbarPreviousButton }
        set { base.__fw.toolbarPreviousButton = newValue }
    }

    /// 自定义键盘Toolbar下一个按钮，支持图片|字符串等(详见FWBlock)，默认朝下的箭头
    public var toolbarNextButton: Any {
        get { return base.__fw.toolbarNextButton }
        set { base.__fw.toolbarNextButton = newValue }
    }

    /// 自定义键盘Toolbar完成按钮，支持图片|字符串等(详见FWBlock)，默认Done
    public var toolbarDoneButton: Any {
        get { return base.__fw.toolbarDoneButton }
        set { base.__fw.toolbarDoneButton = newValue }
    }

    /// 设置Toolbar点击前一个按钮时聚焦的输入框，默认nil
    public weak var previousResponder: UIResponder? {
        get { return base.__fw.previousResponder }
        set { base.__fw.previousResponder = newValue }
    }

    /// 设置Toolbar点击下一个按钮时聚焦的输入框，默认nil
    public weak var nextResponder: UIResponder? {
        get { return base.__fw.nextResponder }
        set { base.__fw.nextResponder = newValue }
    }
    
    /// 获取键盘弹出时的高度，对应Key为UIKeyboardFrameEndUserInfoKey
    public func keyboardHeight(_ notification: Notification) -> CGFloat {
        return base.__fw.keyboardHeight(notification)
    }

    /// 执行键盘跟随动画，支持AutoLayout，可通过keyboardHeight:获取键盘高度
    public func keyboardAnimate(_ notification: Notification, animations: @escaping () -> Void, completion: ((Bool) -> Void)? = nil) {
        base.__fw.keyboardAnimate(notification, animations: animations, completion: completion)
    }
    
    /// 添加Toolbar，指定标题和完成句柄，使用默认按钮
    /// - Parameters:
    ///   - title: 标题，不能点击
    ///   - doneBlock: 右侧完成按钮句柄，默认收起键盘
    public func addToolbar(title: Any?, doneBlock: ((Any) -> Void)?) {
        base.__fw.addToolbar(withTitle: title, doneBlock: doneBlock)
    }
    
    /// 添加Toolbar，指定居中标题、左侧上一个、下一个按钮和右边按钮
    /// - Parameters:
    ///   - titleItem: 居中标题按钮
    ///   - previousItem: 左侧前一个按钮
    ///   - nextItem: 左侧下一个按钮
    ///   - doneItem: 右侧完成按钮
    public func addToolbar(titleItem: UIBarButtonItem?, previousItem: UIBarButtonItem?, nextItem: UIBarButtonItem?, doneItem: UIBarButtonItem?) {
        base.__fw.addToolbar(withTitleItem: titleItem, previousItem: previousItem, nextItem: nextItem, doneItem: doneItem)
    }
    
}

// MARK: - UITextView+Keyboard
extension Wrapper where Base: UITextView {
    
    // MARK: - Keyboard
    /// 是否启用键盘管理(自动滚动)，默认NO
    public var keyboardManager: Bool {
        get { return base.__fw.keyboardManager }
        set { base.__fw.keyboardManager = newValue }
    }

    /// 设置输入框和键盘的空白间距，默认10.0
    public var keyboardDistance: CGFloat {
        get { return base.__fw.keyboardDistance }
        set { base.__fw.keyboardDistance = newValue }
    }

    /// 设置输入框和键盘的回弹触发最小距离，默认0始终回弹
    public var reboundDistance: CGFloat {
        get { return base.__fw.reboundDistance }
        set { base.__fw.reboundDistance = newValue }
    }

    /// 是否启用键盘后台关闭处理，退后台时收起键盘，回到前台时恢复键盘，解决系统退后台输入框跳动问题，默认NO
    public var keyboardResign: Bool {
        get { return base.__fw.keyboardResign }
        set { base.__fw.keyboardResign = newValue }
    }
    
    /// 是否启用点击背景关闭键盘(会继续触发其它点击事件)，默认NO
    public var touchResign: Bool {
        get { return base.__fw.touchResign }
        set { base.__fw.touchResign = newValue }
    }
    
    /// 指定用于键盘管理滚动的scrollView，默认为nil，通过修改VC.view.frame实现
    public weak var keyboardScrollView: UIScrollView? {
        get { return base.__fw.keyboardScrollView }
        set { base.__fw.keyboardScrollView = newValue }
    }
    
    // MARK: - Return
    /// 点击键盘完成按钮是否关闭键盘，默认NO，二选一。此方法会修改delegate，可使用fwDelegate访问原始delegate
    public var returnResign: Bool {
        get { return base.__fw.returnResign }
        set { base.__fw.returnResign = newValue }
    }

    /// 设置点击键盘完成按钮自动切换的下一个输入框，二选一。此方法会修改delegate，可使用fwDelegate访问原始delegate
    public weak var returnResponder: UIResponder? {
        get { return base.__fw.returnResponder }
        set { base.__fw.returnResponder = newValue }
    }

    /// 设置点击键盘完成按钮的事件句柄。此方法会修改delegate，可使用fwDelegate访问原始delegate
    public var returnBlock: ((UITextView) -> Void)? {
        get { return base.__fw.returnBlock }
        set { base.__fw.returnBlock = newValue }
    }
    
    /// 调用上面三个方法后会修改delegate，此方法始终访问外部delegate
    public weak var delegate: UITextViewDelegate? {
        get { return base.__fw.delegate }
        set { base.__fw.delegate = newValue }
    }
    
    // MARK: - Toolbar
    /// 获取关联的键盘Toolbar对象，可自定义样式
    public var keyboardToolbar: UIToolbar {
        get { return base.__fw.keyboardToolbar }
        set { base.__fw.keyboardToolbar = newValue }
    }

    /// 自定义键盘Toolbar上一个按钮，支持图片|字符串等(详见FWBlock)，默认朝上的箭头
    public var toolbarPreviousButton: Any {
        get { return base.__fw.toolbarPreviousButton }
        set { base.__fw.toolbarPreviousButton = newValue }
    }

    /// 自定义键盘Toolbar下一个按钮，支持图片|字符串等(详见FWBlock)，默认朝下的箭头
    public var toolbarNextButton: Any {
        get { return base.__fw.toolbarNextButton }
        set { base.__fw.toolbarNextButton = newValue }
    }

    /// 自定义键盘Toolbar完成按钮，支持图片|字符串等(详见FWBlock)，默认Done
    public var toolbarDoneButton: Any {
        get { return base.__fw.toolbarDoneButton }
        set { base.__fw.toolbarDoneButton = newValue }
    }

    /// 设置Toolbar点击前一个按钮时聚焦的输入框，默认nil
    public weak var previousResponder: UIResponder? {
        get { return base.__fw.previousResponder }
        set { base.__fw.previousResponder = newValue }
    }

    /// 设置Toolbar点击下一个按钮时聚焦的输入框，默认nil
    public weak var nextResponder: UIResponder? {
        get { return base.__fw.nextResponder }
        set { base.__fw.nextResponder = newValue }
    }
    
    /// 获取键盘弹出时的高度，对应Key为UIKeyboardFrameEndUserInfoKey
    public func keyboardHeight(_ notification: Notification) -> CGFloat {
        return base.__fw.keyboardHeight(notification)
    }

    /// 执行键盘跟随动画，支持AutoLayout，可通过keyboardHeight:获取键盘高度
    public func keyboardAnimate(_ notification: Notification, animations: @escaping () -> Void, completion: ((Bool) -> Void)? = nil) {
        base.__fw.keyboardAnimate(notification, animations: animations, completion: completion)
    }
    
    /// 添加Toolbar，指定标题和完成句柄，使用默认按钮
    /// - Parameters:
    ///   - title: 标题，不能点击
    ///   - doneBlock: 右侧完成按钮句柄，默认收起键盘
    public func addToolbar(title: Any?, doneBlock: ((Any) -> Void)?) {
        base.__fw.addToolbar(withTitle: title, doneBlock: doneBlock)
    }
    
    /// 添加Toolbar，指定居中标题、左侧上一个、下一个按钮和右边按钮
    /// - Parameters:
    ///   - titleItem: 居中标题按钮
    ///   - previousItem: 左侧前一个按钮
    ///   - nextItem: 左侧下一个按钮
    ///   - doneItem: 右侧完成按钮
    public func addToolbar(titleItem: UIBarButtonItem?, previousItem: UIBarButtonItem?, nextItem: UIBarButtonItem?, doneItem: UIBarButtonItem?) {
        base.__fw.addToolbar(withTitleItem: titleItem, previousItem: previousItem, nextItem: nextItem, doneItem: doneItem)
    }
    
}

// MARK: - UITextView+Placeholder
extension Wrapper where Base: UITextView {
    
    /// 占位文本，默认nil
    public var placeholder: String? {
        get { return base.__fw.placeholder }
        set { base.__fw.placeholder = newValue }
    }

    /// 占位颜色，默认系统颜色
    public var placeholderColor: UIColor? {
        get { return base.__fw.placeholderColor }
        set { base.__fw.placeholderColor = newValue }
    }

    /// 带属性占位文本，默认nil
    public var attributedPlaceholder: NSAttributedString? {
        get { return base.__fw.attributedPlaceholder }
        set { base.__fw.attributedPlaceholder = newValue }
    }

    /// 自定义占位文本内间距，默认zero与内容一致
    public var placeholderInset: UIEdgeInsets {
        get { return base.__fw.placeholderInset }
        set { base.__fw.placeholderInset = newValue }
    }

    /// 自定义垂直分布方式，会自动修改contentInset，默认Top与系统一致
    public var verticalAlignment: UIControl.ContentVerticalAlignment {
        get { return base.__fw.verticalAlignment }
        set { base.__fw.verticalAlignment = newValue }
    }

    /// 是否启用自动高度功能，随文字改变高度
    public var autoHeightEnabled: Bool {
        get { return base.__fw.autoHeightEnabled }
        set { base.__fw.autoHeightEnabled = newValue }
    }

    /// 最大高度，默认CGFLOAT_MAX，启用自动高度后生效
    public var maxHeight: CGFloat {
        get { return base.__fw.maxHeight }
        set { base.__fw.maxHeight = newValue }
    }

    /// 最小高度，默认0，启用自动高度后生效
    public var minHeight: CGFloat {
        get { return base.__fw.minHeight }
        set { base.__fw.minHeight = newValue }
    }

    /// 高度改变回调句柄，默认nil，启用自动高度后生效
    public var heightDidChange: ((CGFloat) -> Void)? {
        get { return base.__fw.heightDidChange }
        set { base.__fw.heightDidChange = newValue }
    }

    /// 快捷启用自动高度，并设置最大高度和回调句柄
    public func autoHeight(maxHeight: CGFloat, didChange: ((CGFloat) -> Void)?) {
        base.__fw.autoHeight(withMaxHeight: maxHeight, didChange: didChange)
    }
    
}
