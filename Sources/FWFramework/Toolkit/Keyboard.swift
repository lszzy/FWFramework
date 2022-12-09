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
    
    private class PlaceholderTarget: NSObject {
        
        private(set) weak var textView: UITextView?
        
        var lastHeight: CGFloat = 0
        
        private static var defaultPlaceholderColor: UIColor?
        
        fileprivate static func placeholderColor() -> UIColor? {
            if defaultPlaceholderColor != nil { return defaultPlaceholderColor }
            
            let textField = UITextField()
            textField.placeholder = " "
            let placeholderLabel = textField.fw_invokeGetter("_placeholderLabel") as? UILabel
            defaultPlaceholderColor = placeholderLabel?.textColor
            return defaultPlaceholderColor
        }
        
        init(textView: UITextView?) {
            super.init()
            self.textView = textView
        }
        
        @objc func setNeedsUpdatePlaceholder() {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(updatePlaceholder), object: nil)
            self.perform(#selector(updatePlaceholder), with: nil, afterDelay: 0)
        }
        
        @objc func setNeedsUpdateText() {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(updateText), object: nil)
            self.perform(#selector(updateText), with: nil, afterDelay: 0)
        }
        
        @objc func updatePlaceholder() {
            guard let textView = self.textView else { return }
            // 调整contentInset实现垂直分布，不使用contentOffset是因为光标移动会不正常
            var contentInset = textView.contentInset
            contentInset.top = 0
            if textView.contentSize.height < textView.bounds.size.height {
                let height = ceil(textView.sizeThatFits(CGSize(width: textView.bounds.size.width, height: .greatestFiniteMagnitude)).height)
                switch textView.fw_verticalAlignment {
                case .center:
                    contentInset.top = (textView.bounds.size.height - height) / 2.0
                case .bottom:
                    contentInset.top = textView.bounds.size.height - height
                default:
                    break
                }
            }
            textView.contentInset = contentInset
            
            let text: String? = textView.text
            if (text?.count ?? 0) > 0 {
                textView.fw_placeholderLabel.isHidden = true
            } else {
                var targetFrame: CGRect = .zero
                let inset = textView.fw_placeholderInset
                if inset != .zero {
                    targetFrame = CGRect(x: inset.left, y: inset.top, width: CGRectGetWidth(textView.bounds) - inset.left - inset.right, height: CGRectGetHeight(textView.bounds) - inset.top - inset.bottom)
                } else {
                    let x = textView.textContainer.lineFragmentPadding + textView.textContainerInset.left
                    let width = CGRectGetWidth(textView.bounds) - x - textView.textContainer.lineFragmentPadding - textView.textContainerInset.right
                    var height = ceil(textView.fw_placeholderLabel.sizeThatFits(CGSize(width: width, height: 0)).height)
                    height = min(height, textView.bounds.size.height - textView.textContainerInset.top - textView.textContainerInset.bottom)
                    
                    var y = textView.textContainerInset.top
                    switch textView.fw_verticalAlignment {
                    case .center:
                        y = (textView.bounds.size.height - height) / 2.0 - textView.contentInset.top
                    case .bottom:
                        y = textView.bounds.size.height - height - textView.textContainerInset.bottom - textView.contentInset.top
                    default:
                        break
                    }
                    targetFrame = CGRect(x: x, y: y, width: width, height: height)
                }
                
                textView.fw_placeholderLabel.isHidden = false
                textView.fw_placeholderLabel.textAlignment = textView.textAlignment
                textView.fw_placeholderLabel.frame = targetFrame
            }
        }
        
        @objc func updateText() {
            updatePlaceholder()
            guard let textView = self.textView,
                  textView.fw_autoHeightEnabled else { return }
            
            var height = ceil(textView.sizeThatFits(CGSize(width: textView.bounds.size.width, height: .greatestFiniteMagnitude)).height)
            height = max(textView.fw_minHeight, min(height, textView.fw_maxHeight))
            if height == self.lastHeight { return }
            
            var targetFrame = textView.frame
            targetFrame.size.height = height
            textView.frame = targetFrame
            textView.fw_heightDidChange?(height)
            self.lastHeight = height
        }
        
    }
    
    /// 占位文本，默认nil
    public var fw_placeholder: String? {
        get {
            return self.fw_placeholderLabel.text
        }
        set {
            self.fw_placeholderLabel.text = newValue
            self.fw_innerPlaceholderTarget.setNeedsUpdatePlaceholder()
        }
    }

    /// 占位颜色，默认系统颜色
    public var fw_placeholderColor: UIColor? {
        get { return self.fw_placeholderLabel.textColor }
        set { self.fw_placeholderLabel.textColor = newValue }
    }

    /// 带属性占位文本，默认nil
    public var fw_attributedPlaceholder: NSAttributedString? {
        get {
            return self.fw_placeholderLabel.attributedText
        }
        set {
            self.fw_placeholderLabel.attributedText = newValue
            self.fw_innerPlaceholderTarget.setNeedsUpdatePlaceholder()
        }
    }

    /// 自定义占位文本内间距，默认zero与内容一致
    public var fw_placeholderInset: UIEdgeInsets {
        get {
            let value = fw_property(forName: "fw_placeholderInset") as? NSValue
            return value?.uiEdgeInsetsValue ?? .zero
        }
        set {
            fw_setProperty(NSValue(uiEdgeInsets: newValue), forName: "fw_placeholderInset")
            self.fw_innerPlaceholderTarget.setNeedsUpdatePlaceholder()
        }
    }

    /// 自定义垂直分布方式，会自动修改contentInset，默认Top与系统一致
    public var fw_verticalAlignment: UIControl.ContentVerticalAlignment {
        get {
            if let value = fw_property(forName: "fw_verticalAlignment") as? NSNumber {
                return .init(rawValue: value.intValue) ?? .top
            }
            return .top
        }
        set {
            fw_setProperty(NSNumber(value: newValue.rawValue), forName: "fw_verticalAlignment")
            self.fw_innerPlaceholderTarget.setNeedsUpdatePlaceholder()
        }
    }
    
    private var fw_placeholderLabel: UILabel {
        if let label = fw_property(forName: "fw_placeholderLabel") as? UILabel { return label }
        
        let originalText = self.attributedText
        self.text = " "
        self.attributedText = originalText
        
        let label = UILabel()
        label.textColor = PlaceholderTarget.placeholderColor()
        label.numberOfLines = 0
        label.isUserInteractionEnabled = false
        label.font = self.font
        fw_setProperty(label, forName: "fw_placeholderLabel")
        self.fw_innerPlaceholderTarget.setNeedsUpdatePlaceholder()
        self.insertSubview(label, at: 0)
        
        self.fw_observeNotification(UITextView.textDidChangeNotification, object: self, target: self.fw_innerPlaceholderTarget, action: #selector(PlaceholderTarget.setNeedsUpdateText))
        self.fw_observeProperty("attributedText", target: self.fw_innerPlaceholderTarget, action: #selector(PlaceholderTarget.setNeedsUpdateText))
        self.fw_observeProperty("text", target: self.fw_innerPlaceholderTarget, action: #selector(PlaceholderTarget.setNeedsUpdateText))
        self.fw_observeProperty("bounds", target: self.fw_innerPlaceholderTarget, action: #selector(PlaceholderTarget.setNeedsUpdatePlaceholder))
        self.fw_observeProperty("frame", target: self.fw_innerPlaceholderTarget, action: #selector(PlaceholderTarget.setNeedsUpdatePlaceholder))
        self.fw_observeProperty("textAlignment", target: self.fw_innerPlaceholderTarget, action: #selector(PlaceholderTarget.setNeedsUpdatePlaceholder))
        self.fw_observeProperty("textContainerInset", target: self.fw_innerPlaceholderTarget, action: #selector(PlaceholderTarget.setNeedsUpdatePlaceholder))
        self.fw_observeProperty("font") { textView, change in
            guard let textView = textView as? UITextView else { return }
            if change[.newKey] != nil {
                textView.fw_placeholderLabel.font = textView.font
                textView.fw_innerPlaceholderTarget.setNeedsUpdatePlaceholder()
            }
        }
        return label
    }
    
    private var fw_innerPlaceholderTarget: PlaceholderTarget {
        if let target = fw_property(forName: "fw_innerPlaceholderTarget") as? PlaceholderTarget {
            return target
        } else {
            let target = PlaceholderTarget(textView: self)
            fw_setProperty(target, forName: "fw_innerPlaceholderTarget")
            return target
        }
    }

    /// 是否启用自动高度功能，随文字改变高度
    public var fw_autoHeightEnabled: Bool {
        get {
            return fw_propertyBool(forName: "fw_autoHeightEnabled")
        }
        set {
            fw_setPropertyBool(newValue, forName: "fw_autoHeightEnabled")
            self.fw_innerPlaceholderTarget.setNeedsUpdateText()
        }
    }

    /// 最大高度，默认CGFLOAT_MAX，启用自动高度后生效
    public var fw_maxHeight: CGFloat {
        get {
            if let value = fw_property(forName: "fw_maxHeight") as? NSNumber {
                return value.doubleValue
            }
            return .greatestFiniteMagnitude
        }
        set {
            fw_setProperty(NSNumber(value: newValue), forName: "fw_maxHeight")
            self.fw_innerPlaceholderTarget.setNeedsUpdateText()
        }
    }

    /// 最小高度，默认0，启用自动高度后生效
    public var fw_minHeight: CGFloat {
        get {
            return fw_propertyDouble(forName: "fw_minHeight")
        }
        set {
            fw_setPropertyDouble(newValue, forName: "fw_minHeight")
            self.fw_innerPlaceholderTarget.setNeedsUpdateText()
        }
    }

    /// 高度改变回调句柄，默认nil，启用自动高度后生效
    public var fw_heightDidChange: ((CGFloat) -> Void)? {
        get { return fw_property(forName: "fw_heightDidChange") as? (CGFloat) -> Void }
        set { fw_setPropertyCopy(newValue, forName: "fw_heightDidChange") }
    }

    /// 快捷启用自动高度，并设置最大高度和回调句柄
    public func fw_autoHeight(maxHeight: CGFloat, didChange: ((CGFloat) -> Void)? = nil) {
        self.fw_maxHeight = maxHeight
        if didChange != nil { self.fw_heightDidChange = didChange }
        self.fw_autoHeightEnabled = true
    }
    
}
