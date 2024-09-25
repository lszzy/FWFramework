//
//  Keyboard.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit

// MARK: - Wrapper+UITextField
@MainActor extension Wrapper where Base: UITextField {
    // MARK: - Keyboard
    /// 是否启用键盘管理(自动滚动)，默认NO
    public var keyboardManager: Bool {
        get { base.innerKeyboardManager }
        set { base.innerKeyboardManager = newValue }
    }

    /// 设置输入框和键盘的空白间距，默认10.0
    public var keyboardDistance: CGFloat {
        get { base.innerKeyboardDistance }
        set { base.innerKeyboardDistance = newValue }
    }

    /// 设置输入框和键盘的空白间距句柄，参数为键盘高度、输入框高度，优先级高，默认nil
    public var keyboardDistanceBlock: (@MainActor @Sendable (_ keyboardHeight: CGFloat, _ height: CGFloat) -> CGFloat)? {
        get { base.innerKeyboardDistanceBlock }
        set { base.innerKeyboardDistanceBlock = newValue }
    }

    /// 设置输入框和键盘的回弹触发最小距离，默认0始终回弹
    public var reboundDistance: CGFloat {
        get { base.innerReboundDistance }
        set { base.innerReboundDistance = newValue }
    }

    /// 是否启用键盘后台关闭处理，退后台时收起键盘，回到前台时恢复键盘，解决系统退后台输入框跳动问题，默认NO
    public var keyboardResign: Bool {
        get { base.innerKeyboardResign }
        set { base.innerKeyboardResign = newValue }
    }

    /// 是否启用点击背景关闭键盘(会继续触发其它点击事件)，默认NO
    public var touchResign: Bool {
        get { base.innerTouchResign }
        set { base.innerTouchResign = newValue }
    }

    /// 指定用于键盘管理滚动的scrollView，默认为nil，通过修改VC.view.frame实现
    public weak var keyboardScrollView: UIScrollView? {
        get { keyboardTarget.scrollView }
        set { keyboardTarget.scrollView = newValue }
    }

    // MARK: - Return
    /// 点击键盘完成按钮是否关闭键盘，默认NO，二选一
    public var returnResign: Bool {
        get { base.innerReturnResign }
        set { base.innerReturnResign = newValue }
    }

    /// 设置点击键盘完成按钮是否自动切换下一个输入框，二选一
    public var returnNext: Bool {
        get {
            keyboardTarget.returnNext
        }
        set {
            keyboardTarget.returnNext = newValue
            addReturnEvent()
        }
    }

    /// 设置点击键盘完成按钮的事件句柄
    public var returnBlock: (@MainActor @Sendable (UITextField) -> Void)? {
        get {
            keyboardTarget.returnBlock
        }
        set {
            keyboardTarget.returnBlock = newValue
            addReturnEvent()
        }
    }

    fileprivate func addReturnEvent() {
        let value = propertyNumber(forName: "addReturnEvent")
        if value == nil {
            base.addTarget(keyboardTarget, action: #selector(KeyboardTarget<UITextField>.invokeReturnAction), for: .editingDidEndOnExit)
            setPropertyNumber(NSNumber(value: true), forName: "addReturnEvent")
        }
    }

    // MARK: - Toolbar
    /// 获取关联的键盘Toolbar对象，可自定义样式
    public var keyboardToolbar: UIToolbar {
        get { keyboardTarget.keyboardToolbar }
        set { keyboardTarget.keyboardToolbar = newValue }
    }

    /// 自定义键盘Toolbar上一个按钮，支持图片|字符串等(详见FWBlock)，默认朝上的箭头
    public var toolbarPreviousButton: Any? {
        get { keyboardTarget.toolbarPreviousButton }
        set { keyboardTarget.toolbarPreviousButton = newValue }
    }

    /// 自定义键盘Toolbar下一个按钮，支持图片|字符串等(详见FWBlock)，默认朝下的箭头
    public var toolbarNextButton: Any? {
        get { keyboardTarget.toolbarNextButton }
        set { keyboardTarget.toolbarNextButton = newValue }
    }

    /// 自定义键盘Toolbar完成按钮，支持图片|字符串等(详见FWBlock)，默认Done
    public var toolbarDoneButton: Any? {
        get { keyboardTarget.toolbarDoneButton }
        set { keyboardTarget.toolbarDoneButton = newValue }
    }

    /// 设置Toolbar点击前一个按钮时聚焦的输入框句柄，默认nil
    public var previousResponder: (@MainActor @Sendable (UITextField) -> UIResponder?)? {
        get { keyboardTarget.previousResponder }
        set { keyboardTarget.previousResponder = newValue }
    }

    /// 设置Toolbar点击下一个按钮时聚焦的输入框句柄，默认nil
    public var nextResponder: (@MainActor @Sendable (UITextField) -> UIResponder?)? {
        get { keyboardTarget.nextResponder }
        set { keyboardTarget.nextResponder = newValue }
    }

    /// 设置Toolbar点击前一个按钮时聚焦的输入框tag，默认0不生效
    public var previousResponderTag: Int {
        get { keyboardTarget.previousResponderTag }
        set { keyboardTarget.previousResponderTag = newValue }
    }

    /// 设置Toolbar点击下一个按钮时聚焦的输入框tag，默认0不生效
    public var nextResponderTag: Int {
        get { keyboardTarget.nextResponderTag }
        set { keyboardTarget.nextResponderTag = newValue }
    }

    /// 自动跳转前一个输入框，优先使用previousResponder，其次根据responderTag查找
    public func goPrevious() {
        keyboardTarget.goPrevious()
    }

    /// 自动跳转后一个输入框，优先使用nextResponder，其次根据responderTag查找
    public func goNext() {
        keyboardTarget.goNext()
    }

    /// 获取键盘弹出时的高度，对应Key为UIKeyboardFrameEndUserInfoKey
    public func keyboardHeight(_ notification: Notification) -> CGFloat {
        keyboardTarget.keyboardHeight(notification)
    }

    /// 执行键盘跟随动画，支持AutoLayout，可通过keyboardHeight:获取键盘高度
    public func keyboardAnimate(_ notification: Notification, animations: @escaping () -> Void, completion: ((Bool) -> Void)? = nil) {
        keyboardTarget.keyboardAnimate(notification, animations: animations, completion: completion)
    }

    /// 添加Toolbar，指定标题和完成句柄，使用默认按钮
    /// - Parameters:
    ///   - title: 标题，不能点击
    ///   - doneBlock: 右侧完成按钮句柄，默认收起键盘
    public func addToolbar(title: Any? = nil, doneBlock: (@MainActor @Sendable (UIBarButtonItem) -> Void)? = nil) {
        keyboardTarget.addToolbar(title: title, doneBlock: doneBlock)
    }

    /// 添加Toolbar，指定居中标题、左侧上一个、下一个按钮和右边按钮
    /// - Parameters:
    ///   - titleItem: 居中标题按钮
    ///   - previousItem: 左侧前一个按钮
    ///   - nextItem: 左侧下一个按钮
    ///   - doneItem: 右侧完成按钮
    public func addToolbar(titleItem: UIBarButtonItem?, previousItem: UIBarButtonItem?, nextItem: UIBarButtonItem?, doneItem: UIBarButtonItem?) {
        keyboardTarget.addToolbar(titleItem: titleItem, previousItem: previousItem, nextItem: nextItem, doneItem: doneItem)
    }

    fileprivate var keyboardTarget: KeyboardTarget<UITextField> {
        if let target = property(forName: "keyboardTarget") as? KeyboardTarget<UITextField> {
            return target
        } else {
            let target = KeyboardTarget<UITextField>(textInput: base)
            setProperty(target, forName: "keyboardTarget")
            return target
        }
    }
}

// MARK: - Wrapper+UITextView
@MainActor extension Wrapper where Base: UITextView {
    // MARK: - Keyboard
    /// 是否启用键盘管理(自动滚动)，默认NO
    public var keyboardManager: Bool {
        get { base.innerKeyboardManager }
        set { base.innerKeyboardManager = newValue }
    }

    /// 设置输入框和键盘的空白间距，默认10.0
    public var keyboardDistance: CGFloat {
        get { base.innerKeyboardDistance }
        set { base.innerKeyboardDistance = newValue }
    }

    /// 设置输入框和键盘的空白间距句柄，参数为键盘高度、输入框高度，优先级高，默认nil
    public var keyboardDistanceBlock: (@MainActor @Sendable (_ keyboardHeight: CGFloat, _ height: CGFloat) -> CGFloat)? {
        get { base.innerKeyboardDistanceBlock }
        set { base.innerKeyboardDistanceBlock = newValue }
    }

    /// 设置输入框和键盘的回弹触发最小距离，默认0始终回弹
    public var reboundDistance: CGFloat {
        get { base.innerReboundDistance }
        set { base.innerReboundDistance = newValue }
    }

    /// 是否启用键盘后台关闭处理，退后台时收起键盘，回到前台时恢复键盘，解决系统退后台输入框跳动问题，默认NO
    public var keyboardResign: Bool {
        get { base.innerKeyboardResign }
        set { base.innerKeyboardResign = newValue }
    }

    /// 是否启用点击背景关闭键盘(会继续触发其它点击事件)，默认NO
    public var touchResign: Bool {
        get { base.innerTouchResign }
        set { base.innerTouchResign = newValue }
    }

    /// 指定用于键盘管理滚动的scrollView，默认为nil，通过修改VC.view.frame实现
    public weak var keyboardScrollView: UIScrollView? {
        get { keyboardTarget.scrollView }
        set { keyboardTarget.scrollView = newValue }
    }

    // MARK: - Return
    /// 点击键盘完成按钮是否关闭键盘，默认NO，二选一。此方法会修改delegate，可使用fwDelegate访问原始delegate
    public var returnResign: Bool {
        get { base.innerReturnResign }
        set { base.innerReturnResign = newValue }
    }

    /// 设置点击键盘完成按钮是否自动切换下一个输入框，二选一。此方法会修改delegate，可使用fwDelegate访问原始delegate
    public var returnNext: Bool {
        get {
            keyboardTarget.returnNext
        }
        set {
            keyboardTarget.returnNext = newValue
            delegateProxyEnabled = true
        }
    }

    /// 设置点击键盘完成按钮的事件句柄。此方法会修改delegate，可使用fwDelegate访问原始delegate
    public var returnBlock: (@MainActor @Sendable (UITextView) -> Void)? {
        get {
            keyboardTarget.returnBlock
        }
        set {
            keyboardTarget.returnBlock = newValue
            delegateProxyEnabled = true
        }
    }

    /// 调用上面三个方法后会修改delegate，此方法始终访问外部delegate
    public weak var delegate: UITextViewDelegate? {
        get {
            if !delegateProxyEnabled {
                return base.delegate
            } else {
                return delegateProxy.delegate
            }
        }
        set {
            if !delegateProxyEnabled {
                base.delegate = newValue
            } else {
                delegateProxy.delegate = newValue
                base.delegate = delegateProxy
            }
        }
    }

    fileprivate var delegateProxyEnabled: Bool {
        get {
            base.delegate === delegateProxy
        }
        set {
            if newValue != delegateProxyEnabled {
                if newValue {
                    delegateProxy.delegate = base.delegate
                    base.delegate = delegateProxy
                } else {
                    base.delegate = delegateProxy.delegate
                    delegateProxy.delegate = nil
                }
            }
        }
    }

    private var delegateProxy: TextViewDelegateProxy {
        if let proxy = property(forName: "delegateProxy") as? TextViewDelegateProxy {
            return proxy
        } else {
            let proxy = TextViewDelegateProxy()
            setProperty(proxy, forName: "delegateProxy")
            return proxy
        }
    }

    // MARK: - Toolbar
    /// 获取关联的键盘Toolbar对象，可自定义样式
    public var keyboardToolbar: UIToolbar {
        get { keyboardTarget.keyboardToolbar }
        set { keyboardTarget.keyboardToolbar = newValue }
    }

    /// 自定义键盘Toolbar上一个按钮，支持图片|字符串等(详见FWBlock)，默认朝上的箭头
    public var toolbarPreviousButton: Any? {
        get { keyboardTarget.toolbarPreviousButton }
        set { keyboardTarget.toolbarPreviousButton = newValue }
    }

    /// 自定义键盘Toolbar下一个按钮，支持图片|字符串等(详见FWBlock)，默认朝下的箭头
    public var toolbarNextButton: Any? {
        get { keyboardTarget.toolbarNextButton }
        set { keyboardTarget.toolbarNextButton = newValue }
    }

    /// 自定义键盘Toolbar完成按钮，支持图片|字符串等(详见FWBlock)，默认Done
    public var toolbarDoneButton: Any? {
        get { keyboardTarget.toolbarDoneButton }
        set { keyboardTarget.toolbarDoneButton = newValue }
    }

    /// 设置Toolbar点击前一个按钮时聚焦的输入框句柄，默认nil
    public var previousResponder: (@MainActor @Sendable (UITextView) -> UIResponder?)? {
        get { keyboardTarget.previousResponder }
        set { keyboardTarget.previousResponder = newValue }
    }

    /// 设置Toolbar点击下一个按钮时聚焦的输入框句柄，默认nil
    public var nextResponder: (@MainActor @Sendable (UITextView) -> UIResponder?)? {
        get { keyboardTarget.nextResponder }
        set { keyboardTarget.nextResponder = newValue }
    }

    /// 设置Toolbar点击前一个按钮时聚焦的输入框tag，默认0不生效
    public var previousResponderTag: Int {
        get { keyboardTarget.previousResponderTag }
        set { keyboardTarget.previousResponderTag = newValue }
    }

    /// 设置Toolbar点击下一个按钮时聚焦的输入框tag，默认0不生效
    public var nextResponderTag: Int {
        get { keyboardTarget.nextResponderTag }
        set { keyboardTarget.nextResponderTag = newValue }
    }

    /// 自动跳转前一个输入框，优先使用previousResponder，其次根据responderTag查找
    public func goPrevious() {
        keyboardTarget.goPrevious()
    }

    /// 自动跳转后一个输入框，优先使用nextResponder，其次根据responderTag查找
    public func goNext() {
        keyboardTarget.goNext()
    }

    /// 获取键盘弹出时的高度，对应Key为UIKeyboardFrameEndUserInfoKey
    public func keyboardHeight(_ notification: Notification) -> CGFloat {
        keyboardTarget.keyboardHeight(notification)
    }

    /// 执行键盘跟随动画，支持AutoLayout，可通过keyboardHeight:获取键盘高度
    public func keyboardAnimate(_ notification: Notification, animations: @escaping () -> Void, completion: ((Bool) -> Void)? = nil) {
        keyboardTarget.keyboardAnimate(notification, animations: animations, completion: completion)
    }

    /// 添加Toolbar，指定标题和完成句柄，使用默认按钮
    /// - Parameters:
    ///   - title: 标题，不能点击
    ///   - doneBlock: 右侧完成按钮句柄，默认收起键盘
    public func addToolbar(title: Any? = nil, doneBlock: (@MainActor @Sendable (UIBarButtonItem) -> Void)? = nil) {
        keyboardTarget.addToolbar(title: title, doneBlock: doneBlock)
    }

    /// 添加Toolbar，指定居中标题、左侧上一个、下一个按钮和右边按钮
    /// - Parameters:
    ///   - titleItem: 居中标题按钮
    ///   - previousItem: 左侧前一个按钮
    ///   - nextItem: 左侧下一个按钮
    ///   - doneItem: 右侧完成按钮
    public func addToolbar(titleItem: UIBarButtonItem?, previousItem: UIBarButtonItem?, nextItem: UIBarButtonItem?, doneItem: UIBarButtonItem?) {
        keyboardTarget.addToolbar(titleItem: titleItem, previousItem: previousItem, nextItem: nextItem, doneItem: doneItem)
    }

    fileprivate var keyboardTarget: KeyboardTarget<UITextView> {
        if let target = property(forName: "keyboardTarget") as? KeyboardTarget<UITextView> {
            return target
        } else {
            let target = KeyboardTarget<UITextView>(textInput: base)
            setProperty(target, forName: "keyboardTarget")
            return target
        }
    }
}

// MARK: - Wrapper+UITextView
@MainActor extension Wrapper where Base: UITextView {
    /// 占位文本，默认nil
    public var placeholder: String? {
        get {
            placeholderLabel.text
        }
        set {
            placeholderLabel.text = newValue
            placeholderTarget.setNeedsUpdatePlaceholder()
        }
    }

    /// 占位颜色，默认系统颜色
    public var placeholderColor: UIColor? {
        get { placeholderLabel.textColor }
        set { placeholderLabel.textColor = newValue }
    }

    /// 带属性占位文本，默认nil
    public var attributedPlaceholder: NSAttributedString? {
        get {
            placeholderLabel.attributedText
        }
        set {
            placeholderLabel.attributedText = newValue
            placeholderTarget.setNeedsUpdatePlaceholder()
        }
    }

    /// 自定义占位文本内间距，默认zero与内容一致
    public var placeholderInset: UIEdgeInsets {
        get {
            let value = property(forName: "placeholderInset") as? NSValue
            return value?.uiEdgeInsetsValue ?? .zero
        }
        set {
            setProperty(NSValue(uiEdgeInsets: newValue), forName: "placeholderInset")
            placeholderTarget.setNeedsUpdatePlaceholder()
        }
    }

    /// 自定义垂直分布方式，会自动修改contentInset，默认Top与系统一致
    public var verticalAlignment: UIControl.ContentVerticalAlignment {
        get {
            if let value = propertyNumber(forName: "verticalAlignment") {
                return .init(rawValue: value.intValue) ?? .top
            }
            return .top
        }
        set {
            setPropertyNumber(NSNumber(value: newValue.rawValue), forName: "verticalAlignment")
            placeholderTarget.setNeedsUpdatePlaceholder()
        }
    }

    /// 自定义placeholder行高，内部使用
    var placeholderLineHeight: CGFloat {
        get {
            placeholderLabel.fw.lineHeight
        }
        set {
            placeholderLabel.fw.lineHeight = newValue
            placeholderTarget.setNeedsUpdatePlaceholder()
        }
    }

    fileprivate var placeholderLabel: UILabel {
        if let label = property(forName: "placeholderLabel") as? UILabel { return label }

        let originalText = base.attributedText
        base.text = " "
        base.attributedText = originalText

        let label = UILabel()
        label.textColor = PlaceholderTarget.placeholderColor()
        label.numberOfLines = 0
        label.isUserInteractionEnabled = false
        label.font = base.font
        setProperty(label, forName: "placeholderLabel")
        placeholderTarget.setNeedsUpdatePlaceholder()
        base.insertSubview(label, at: 0)

        observeNotification(UITextView.textDidChangeNotification, object: base, target: placeholderTarget, action: #selector(PlaceholderTarget.setNeedsUpdateText))
        observeProperty(\.attributedText, target: placeholderTarget, action: #selector(PlaceholderTarget.setNeedsUpdateText))
        observeProperty(\.text, target: placeholderTarget, action: #selector(PlaceholderTarget.setNeedsUpdateText))
        observeProperty(\.bounds, target: placeholderTarget, action: #selector(PlaceholderTarget.setNeedsUpdatePlaceholder))
        observeProperty(\.frame, target: placeholderTarget, action: #selector(PlaceholderTarget.setNeedsUpdatePlaceholder))
        observeProperty(\.textAlignment, target: placeholderTarget, action: #selector(PlaceholderTarget.setNeedsUpdatePlaceholder))
        observeProperty(\.textContainerInset, target: placeholderTarget, action: #selector(PlaceholderTarget.setNeedsUpdatePlaceholder))
        safeObserveProperty(\.font) { textView, _ in
            if textView.font != nil {
                textView.fw.placeholderLabel.font = textView.font
                textView.fw.placeholderTarget.setNeedsUpdatePlaceholder()
            }
        }
        return label
    }

    private var placeholderTarget: PlaceholderTarget {
        if let target = property(forName: "placeholderTarget") as? PlaceholderTarget {
            return target
        } else {
            let target = PlaceholderTarget(textView: base)
            setProperty(target, forName: "placeholderTarget")
            return target
        }
    }

    /// 是否启用自动高度功能，随文字改变高度
    public var autoHeightEnabled: Bool {
        get {
            propertyBool(forName: "autoHeightEnabled")
        }
        set {
            setPropertyBool(newValue, forName: "autoHeightEnabled")
            placeholderTarget.setNeedsUpdateText()
        }
    }

    /// 最大高度，默认CGFLOAT_MAX，启用自动高度后生效
    public var maxHeight: CGFloat {
        get {
            if let value = propertyNumber(forName: "maxHeight") {
                return value.doubleValue
            }
            return .greatestFiniteMagnitude
        }
        set {
            setPropertyNumber(NSNumber(value: newValue), forName: "maxHeight")
            placeholderTarget.setNeedsUpdateText()
        }
    }

    /// 最小高度，默认0，启用自动高度后生效
    public var minHeight: CGFloat {
        get {
            propertyDouble(forName: "minHeight")
        }
        set {
            setPropertyDouble(newValue, forName: "minHeight")
            placeholderTarget.setNeedsUpdateText()
        }
    }

    /// 高度改变回调句柄，默认nil，启用自动高度后生效
    public var heightDidChange: (@MainActor @Sendable (CGFloat) -> Void)? {
        get { return property(forName: "heightDidChange") as? @MainActor @Sendable (CGFloat) -> Void }
        set { setPropertyCopy(newValue, forName: "heightDidChange") }
    }

    /// 快捷启用自动高度，并设置最大高度和回调句柄
    public func autoHeight(maxHeight height: CGFloat, didChange: (@MainActor @Sendable (CGFloat) -> Void)?) {
        maxHeight = height
        if didChange != nil { heightDidChange = didChange }
        autoHeightEnabled = true
    }
}

// MARK: - UITextField+Keyboard
/// 注意：需要支持appearance的属性必须标记为objc，否则不会生效
extension UITextField {
    @objc fileprivate dynamic var innerKeyboardManager: Bool {
        get { fw.keyboardTarget.keyboardManager }
        set { fw.keyboardTarget.keyboardManager = newValue }
    }

    @objc fileprivate dynamic var innerKeyboardDistance: CGFloat {
        get { fw.keyboardTarget.keyboardDistance }
        set { fw.keyboardTarget.keyboardDistance = newValue }
    }

    @objc fileprivate dynamic var innerKeyboardDistanceBlock: (@MainActor @Sendable (_ keyboardHeight: CGFloat, _ height: CGFloat) -> CGFloat)? {
        get { fw.keyboardTarget.keyboardDistanceBlock }
        set { fw.keyboardTarget.keyboardDistanceBlock = newValue }
    }

    @objc fileprivate dynamic var innerReboundDistance: CGFloat {
        get { fw.keyboardTarget.reboundDistance }
        set { fw.keyboardTarget.reboundDistance = newValue }
    }

    @objc fileprivate dynamic var innerKeyboardResign: Bool {
        get { fw.keyboardTarget.keyboardResign }
        set { fw.keyboardTarget.keyboardResign = newValue }
    }

    @objc fileprivate dynamic var innerTouchResign: Bool {
        get { fw.keyboardTarget.touchResign }
        set { fw.keyboardTarget.touchResign = newValue }
    }

    @objc fileprivate dynamic var innerReturnResign: Bool {
        get {
            fw.keyboardTarget.returnResign
        }
        set {
            fw.keyboardTarget.returnResign = newValue
            fw.addReturnEvent()
        }
    }
}

// MARK: - UITextView+Keyboard
/// 注意：需要支持appearance的属性必须标记为objc，否则不会生效
extension UITextView {
    @objc fileprivate dynamic var innerKeyboardManager: Bool {
        get { fw.keyboardTarget.keyboardManager }
        set { fw.keyboardTarget.keyboardManager = newValue }
    }

    @objc fileprivate dynamic var innerKeyboardDistance: CGFloat {
        get { fw.keyboardTarget.keyboardDistance }
        set { fw.keyboardTarget.keyboardDistance = newValue }
    }

    @objc fileprivate dynamic var innerKeyboardDistanceBlock: (@MainActor @Sendable (_ keyboardHeight: CGFloat, _ height: CGFloat) -> CGFloat)? {
        get { fw.keyboardTarget.keyboardDistanceBlock }
        set { fw.keyboardTarget.keyboardDistanceBlock = newValue }
    }

    @objc fileprivate dynamic var innerReboundDistance: CGFloat {
        get { fw.keyboardTarget.reboundDistance }
        set { fw.keyboardTarget.reboundDistance = newValue }
    }

    @objc fileprivate dynamic var innerKeyboardResign: Bool {
        get { fw.keyboardTarget.keyboardResign }
        set { fw.keyboardTarget.keyboardResign = newValue }
    }

    @objc fileprivate dynamic var innerTouchResign: Bool {
        get { fw.keyboardTarget.touchResign }
        set { fw.keyboardTarget.touchResign = newValue }
    }

    @objc public dynamic var innerReturnResign: Bool {
        get {
            fw.keyboardTarget.returnResign
        }
        set {
            fw.keyboardTarget.returnResign = newValue
            fw.delegateProxyEnabled = true
        }
    }
}

// MARK: - KeyboardTarget
@MainActor private class KeyboardTarget<T: UIView & UITextInput>: NSObject {
    var keyboardManager = false {
        didSet {
            if oldValue == keyboardManager { return }
            if keyboardManager {
                NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIApplication.keyboardWillShowNotification, object: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIApplication.keyboardWillHideNotification, object: nil)
            } else {
                NotificationCenter.default.removeObserver(self, name: UIApplication.keyboardWillShowNotification, object: nil)
                NotificationCenter.default.removeObserver(self, name: UIApplication.keyboardWillHideNotification, object: nil)
            }
        }
    }

    var keyboardDistance: CGFloat = 10

    var keyboardDistanceBlock: (@MainActor @Sendable (_ keyboardHeight: CGFloat, _ height: CGFloat) -> CGFloat)?

    var reboundDistance: CGFloat = 0

    var keyboardResign = false {
        didSet {
            if oldValue == keyboardResign { return }
            if keyboardResign {
                NotificationCenter.default.addObserver(self, selector: #selector(appResignActive), name: UIApplication.willResignActiveNotification, object: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(appBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
            } else {
                NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
                NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
            }
        }
    }

    var touchResign = false {
        didSet {
            if oldValue == touchResign { return }
            if touchResign {
                if let textField = textInput as? UITextField {
                    NotificationCenter.default.addObserver(self, selector: #selector(editingDidBegin), name: UITextField.textDidBeginEditingNotification, object: textField)
                    NotificationCenter.default.addObserver(self, selector: #selector(editingDidEnd), name: UITextField.textDidEndEditingNotification, object: textField)
                } else if let textView = textInput as? UITextView {
                    NotificationCenter.default.addObserver(self, selector: #selector(editingDidBegin), name: UITextView.textDidBeginEditingNotification, object: textView)
                    NotificationCenter.default.addObserver(self, selector: #selector(editingDidEnd), name: UITextView.textDidEndEditingNotification, object: textView)
                }
            } else {
                if let textField = textInput as? UITextField {
                    NotificationCenter.default.removeObserver(self, name: UITextField.textDidBeginEditingNotification, object: textField)
                    NotificationCenter.default.removeObserver(self, name: UITextField.textDidEndEditingNotification, object: textField)
                } else if let textView = textInput as? UITextView {
                    NotificationCenter.default.removeObserver(self, name: UITextView.textDidBeginEditingNotification, object: textView)
                    NotificationCenter.default.removeObserver(self, name: UITextView.textDidEndEditingNotification, object: textView)
                }
            }
        }
    }

    var returnResign = false

    var returnNext = false

    var returnBlock: (@MainActor @Sendable (T) -> Void)?

    lazy var keyboardToolbar: UIToolbar = .init()

    lazy var toolbarPreviousButton: Any? = KeyboardConfig.toolbarPreviousImage

    lazy var toolbarNextButton: Any? = KeyboardConfig.toolbarNextImage

    lazy var toolbarDoneButton: Any? = NSNumber(value: UIBarButtonItem.SystemItem.done.rawValue)

    var previousResponder: (@MainActor @Sendable (T) -> UIResponder?)? {
        didSet {
            previousItem?.isEnabled = previousResponder != nil || previousResponderTag > 0
        }
    }

    var nextResponder: (@MainActor @Sendable (T) -> UIResponder?)? {
        didSet {
            nextItem?.isEnabled = nextResponder != nil || nextResponderTag > 0
        }
    }

    var previousResponderTag: Int = 0 {
        didSet {
            previousItem?.isEnabled = previousResponder != nil || previousResponderTag > 0
        }
    }

    var nextResponderTag: Int = 0 {
        didSet {
            nextItem?.isEnabled = nextResponder != nil || nextResponderTag > 0
        }
    }

    weak var scrollView: UIScrollView?

    private var previousItem: UIBarButtonItem?

    private var nextItem: UIBarButtonItem?

    private var keyboardActive = false

    private weak var viewController: UIViewController? {
        if _viewController == nil {
            _viewController = textInput?.fw.viewController
        }
        return _viewController
    }

    private weak var _viewController: UIViewController?

    private weak var textInput: T?

    init(textInput: T?) {
        super.init()
        self.textInput = textInput
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func editingDidBegin() {
        guard touchResign, let viewController else { return }

        if KeyboardConfig.keyboardGesture == nil {
            KeyboardConfig.keyboardGesture = UITapGestureRecognizer.fw.gestureRecognizer(block: { sender in
                if sender.state == .ended {
                    sender.view?.endEditing(true)
                }
            })
        }
        if let keyboardGesture = KeyboardConfig.keyboardGesture {
            viewController.view.addGestureRecognizer(keyboardGesture)
        }
    }

    @objc private func editingDidEnd() {
        guard touchResign, let viewController else { return }

        if let keyboardGesture = KeyboardConfig.keyboardGesture {
            viewController.view.removeGestureRecognizer(keyboardGesture)
        }
    }

    @objc private func appResignActive() {
        guard keyboardResign, textInput?.isFirstResponder ?? false else { return }

        keyboardActive = true
        textInput?.resignFirstResponder()
    }

    @objc private func appBecomeActive() {
        guard keyboardResign, keyboardActive else { return }

        keyboardActive = false
        textInput?.becomeFirstResponder()
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let textInput, textInput.isFirstResponder else { return }
        guard keyboardManager, let viewController else { return }

        let keyboardRect = (notification.userInfo?[UIApplication.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? .zero
        let animationDuration: TimeInterval = (notification.userInfo?[UIApplication.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? .zero
        var animationCurve: UInt = (notification.userInfo?[UIApplication.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue ?? .zero
        animationCurve = animationCurve << 16

        if let scrollView {
            if !KeyboardConfig.keyboardShowing {
                KeyboardConfig.keyboardShowing = true
                KeyboardConfig.keyboardOffset = scrollView.contentOffset.y
            }

            let convertView = textInput.window ?? viewController.view.window
            let convertRect = textInput.convert(textInput.bounds, to: convertView)
            var contentOffset = scrollView.contentOffset
            let textInputOffset = keyboardDistanceBlock?(keyboardRect.height, convertRect.height) ?? keyboardDistance
            var targetOffsetY = max(contentOffset.y + textInputOffset + CGRectGetMaxY(convertRect) - CGRectGetMinY(keyboardRect), KeyboardConfig.keyboardOffset)
            if reboundDistance > 0 && targetOffsetY < contentOffset.y {
                targetOffsetY = (targetOffsetY + reboundDistance >= contentOffset.y) ? contentOffset.y : targetOffsetY + reboundDistance
            }

            contentOffset.y = targetOffsetY
            UIView.animate(withDuration: animationDuration, delay: 0, options: .init(rawValue: animationCurve).union(.beginFromCurrentState), animations: {
                scrollView.contentOffset = contentOffset
            }, completion: nil)
            return
        }

        if !KeyboardConfig.keyboardShowing {
            KeyboardConfig.keyboardShowing = true
            KeyboardConfig.keyboardOrigin = viewController.view.frame.origin.y
        }

        let convertView = textInput.window ?? viewController.view.window
        let convertRect = textInput.convert(textInput.bounds, to: convertView)
        var viewFrame = viewController.view.frame
        let textInputOffset = keyboardDistanceBlock?(keyboardRect.height, convertRect.height) ?? keyboardDistance
        var viewTargetY = min(viewFrame.origin.y - textInputOffset + CGRectGetMinY(keyboardRect) - CGRectGetMaxY(convertRect), KeyboardConfig.keyboardOrigin)
        if reboundDistance > 0 && viewTargetY > viewFrame.origin.y {
            viewTargetY = (viewTargetY - reboundDistance <= viewFrame.origin.y) ? viewFrame.origin.y : viewTargetY - reboundDistance
        }

        viewFrame.origin.y = viewTargetY
        UIView.animate(withDuration: animationDuration, delay: 0, options: .init(rawValue: animationCurve).union(.beginFromCurrentState), animations: {
            // 修复iOS14当vc.hidesBottomBarWhenPushed为YES时view.frame会被导航栏重置引起的滚动失效问题
            if #available(iOS 14.0, *) {
                viewController.view.layer.frame = viewFrame
            } else {
                viewController.view.frame = viewFrame
            }
        }, completion: nil)
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let textInput, textInput.isFirstResponder else { return }
        guard keyboardManager, let viewController,
              KeyboardConfig.keyboardShowing else { return }

        let animationDuration: TimeInterval = (notification.userInfo?[UIApplication.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? .zero
        var animationCurve: UInt = (notification.userInfo?[UIApplication.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue ?? .zero
        animationCurve = animationCurve << 16

        if let scrollView {
            let originOffsetY = KeyboardConfig.keyboardOffset
            KeyboardConfig.keyboardShowing = false
            KeyboardConfig.keyboardOffset = 0

            var contentOffset = scrollView.contentOffset
            contentOffset.y = originOffsetY
            UIView.animate(withDuration: animationDuration, delay: 0, options: .init(rawValue: animationCurve).union(.beginFromCurrentState), animations: {
                scrollView.contentOffset = contentOffset
            }, completion: nil)
            return
        }

        let viewOriginY = KeyboardConfig.keyboardOrigin
        KeyboardConfig.keyboardShowing = false
        KeyboardConfig.keyboardOrigin = 0

        var viewFrame = viewController.view.frame
        viewFrame.origin.y = viewOriginY
        UIView.animate(withDuration: animationDuration, delay: 0, options: .init(rawValue: animationCurve).union(.beginFromCurrentState), animations: {
            // 修复iOS14当vc.hidesBottomBarWhenPushed为YES时view.frame会被导航栏重置引起的滚动失效问题
            if #available(iOS 14.0, *) {
                viewController.view.layer.frame = viewFrame
            } else {
                viewController.view.frame = viewFrame
            }
        }, completion: nil)
    }

    @objc func invokeReturnAction() {
        // 切换到下一个输入框
        if returnNext {
            goNext()
            // 关闭键盘
        } else if returnResign {
            textInput?.resignFirstResponder()
        }
        // 执行回调
        if returnBlock != nil, let textInput {
            returnBlock?(textInput)
        }
    }

    @objc func goPrevious() {
        guard let textInput else { return }
        if previousResponder != nil {
            let previousInput = previousResponder?(textInput)
            previousInput?.becomeFirstResponder()
            return
        }

        if previousResponderTag > 0 {
            let targetView = viewController != nil ? viewController?.view : textInput.window
            let previousView = targetView?.viewWithTag(previousResponderTag)
            previousView?.becomeFirstResponder()
        }
    }

    @objc func goNext() {
        guard let textInput else { return }
        if nextResponder != nil {
            let nextInput = nextResponder?(textInput)
            nextInput?.becomeFirstResponder()
            return
        }

        if nextResponderTag > 0 {
            let targetView = viewController != nil ? viewController?.view : textInput.window
            let nextView = targetView?.viewWithTag(nextResponderTag)
            nextView?.becomeFirstResponder()
        }
    }

    func keyboardHeight(_ notification: Notification) -> CGFloat {
        let keyboardRect = (notification.userInfo?[UIApplication.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? .zero
        return keyboardRect.size.height
    }

    func keyboardAnimate(_ notification: Notification, animations: @escaping () -> Void, completion: ((Bool) -> Void)? = nil) {
        let animationDuration: TimeInterval = (notification.userInfo?[UIApplication.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? .zero
        var animationCurve: UInt = (notification.userInfo?[UIApplication.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue ?? .zero
        animationCurve = animationCurve << 16

        UIView.animate(withDuration: animationDuration, delay: 0, options: .init(rawValue: animationCurve).union(.beginFromCurrentState), animations: animations, completion: completion)
    }

    func addToolbar(title: Any?, doneBlock: (@MainActor @Sendable (UIBarButtonItem) -> Void)?) {
        let titleItem = title != nil ? UIBarButtonItem.fw.item(object: title, block: nil) : nil
        titleItem?.isEnabled = false

        let previousEnabled = previousResponder != nil || previousResponderTag > 0
        let nextEnabled = nextResponder != nil || nextResponderTag > 0
        let previousItem = ((previousEnabled || nextEnabled) && toolbarPreviousButton != nil) ? UIBarButtonItem.fw.item(object: toolbarPreviousButton, target: self, action: #selector(goPrevious)) : nil
        previousItem?.isEnabled = previousEnabled
        self.previousItem = previousItem

        let nextItem = ((previousEnabled || nextEnabled) && toolbarNextButton != nil) ? UIBarButtonItem.fw.item(object: toolbarNextButton, target: self, action: #selector(goNext)) : nil
        nextItem?.isEnabled = nextEnabled
        self.nextItem = nextItem

        let doneItem = toolbarDoneButton != nil ? (doneBlock != nil ? UIBarButtonItem.fw.item(object: toolbarDoneButton, block: doneBlock) : UIBarButtonItem.fw.item(object: toolbarDoneButton, target: textInput, action: #selector(UIView.resignFirstResponder))) : nil
        doneItem?.style = .done

        addToolbar(titleItem: titleItem, previousItem: previousItem, nextItem: nextItem, doneItem: doneItem)
    }

    func addToolbar(titleItem: UIBarButtonItem?, previousItem: UIBarButtonItem?, nextItem: UIBarButtonItem?, doneItem: UIBarButtonItem?) {
        var items: [UIBarButtonItem] = []
        if let previousItem { items.append(previousItem) }
        if previousItem != nil && nextItem != nil {
            let fixedItem = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
            fixedItem.width = 6
            items.append(fixedItem)
        }
        if let nextItem { items.append(nextItem) }
        items.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))
        if let titleItem {
            items.append(titleItem)
            items.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))
        }
        if let doneItem { items.append(doneItem) }

        let toolbar = keyboardToolbar
        toolbar.items = items
        toolbar.sizeToFit()
        if let textField = textInput as? UITextField {
            textField.inputAccessoryView = toolbar
        } else if let textView = textInput as? UITextView {
            textView.inputAccessoryView = toolbar
        }
    }
}

// MARK: - KeyboardConfig
private class KeyboardConfig {
    nonisolated(unsafe) static var keyboardShowing = false
    nonisolated(unsafe) static var keyboardOrigin: CGFloat = 0
    nonisolated(unsafe) static var keyboardOffset: CGFloat = 0
    nonisolated(unsafe) static var keyboardGesture: UITapGestureRecognizer?

    static var toolbarPreviousImage: UIImage? {
        if let image = _toolbarPreviousImage { return image }

        let base64String = "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"
        guard let data = Data(base64Encoded: base64String, options: .ignoreUnknownCharacters) else { return nil }
        _toolbarPreviousImage = UIImage(data: data, scale: 3)?.imageFlippedForRightToLeftLayoutDirection()
        return _toolbarPreviousImage
    }

    nonisolated(unsafe) static var _toolbarPreviousImage: UIImage?

    static var toolbarNextImage: UIImage? {
        if let image = _toolbarNextImage { return image }

        let base64String = "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"
        guard let data = Data(base64Encoded: base64String, options: .ignoreUnknownCharacters) else { return nil }
        _toolbarNextImage = UIImage(data: data, scale: 3)?.imageFlippedForRightToLeftLayoutDirection()
        return _toolbarNextImage
    }

    nonisolated(unsafe) static var _toolbarNextImage: UIImage?
}

// MARK: - PlaceholderTarget
@MainActor private class PlaceholderTarget: NSObject {
    private(set) weak var textView: UITextView?

    var lastHeight: CGFloat = 0

    private static var defaultPlaceholderColor: UIColor?

    fileprivate static func placeholderColor() -> UIColor? {
        if defaultPlaceholderColor != nil { return defaultPlaceholderColor }

        let textField = UITextField()
        textField.placeholder = " "
        let placeholderLabel = textField.fw.invokeGetter(String(format: "%@%@%@", "_p", "lacehol", "derLabel")) as? UILabel
        defaultPlaceholderColor = placeholderLabel?.textColor
        return defaultPlaceholderColor
    }

    init(textView: UITextView?) {
        super.init()
        self.textView = textView
    }

    @objc func setNeedsUpdatePlaceholder() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(updatePlaceholder), object: nil)
        perform(#selector(updatePlaceholder), with: nil, afterDelay: 0)
    }

    @objc func setNeedsUpdateText() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(updateText), object: nil)
        perform(#selector(updateText), with: nil, afterDelay: 0)
    }

    @objc func updatePlaceholder() {
        guard let textView else { return }
        // 调整contentInset实现垂直分布，不使用contentOffset是因为光标移动会不正常
        var contentInset = textView.contentInset
        contentInset.top = 0
        if textView.contentSize.height < textView.bounds.size.height {
            let height = ceil(textView.sizeThatFits(CGSize(width: textView.bounds.size.width, height: .greatestFiniteMagnitude)).height)
            switch textView.fw.verticalAlignment {
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
            textView.fw.placeholderLabel.isHidden = true
        } else {
            var targetFrame: CGRect = .zero
            let inset = textView.fw.placeholderInset
            if inset != .zero {
                targetFrame = CGRect(x: inset.left, y: inset.top, width: CGRectGetWidth(textView.bounds) - inset.left - inset.right, height: CGRectGetHeight(textView.bounds) - inset.top - inset.bottom)
            } else {
                let x = textView.textContainer.lineFragmentPadding + textView.textContainerInset.left
                let width = CGRectGetWidth(textView.bounds) - x - textView.textContainer.lineFragmentPadding - textView.textContainerInset.right
                var height = ceil(textView.fw.placeholderLabel.sizeThatFits(CGSize(width: width, height: 0)).height)
                height = min(height, textView.bounds.size.height - textView.textContainerInset.top - textView.textContainerInset.bottom)

                var y = textView.textContainerInset.top
                switch textView.fw.verticalAlignment {
                case .center:
                    y = (textView.bounds.size.height - height) / 2.0 - textView.contentInset.top
                case .bottom:
                    y = textView.bounds.size.height - height - textView.textContainerInset.bottom - textView.contentInset.top
                default:
                    break
                }
                targetFrame = CGRect(x: x, y: y, width: width, height: height)
            }

            textView.fw.placeholderLabel.isHidden = false
            textView.fw.placeholderLabel.textAlignment = textView.textAlignment
            textView.fw.placeholderLabel.frame = targetFrame
        }
    }

    @objc func updateText() {
        updatePlaceholder()
        guard let textView,
              textView.fw.autoHeightEnabled else { return }

        var height = ceil(textView.sizeThatFits(CGSize(width: textView.bounds.size.width, height: .greatestFiniteMagnitude)).height)
        height = max(textView.fw.minHeight, min(height, textView.fw.maxHeight))
        if height == lastHeight { return }

        var targetFrame = textView.frame
        targetFrame.size.height = height
        textView.frame = targetFrame
        textView.fw.heightDidChange?(height)
        lastHeight = height
    }
}

// MARK: - TextViewDelegateProxy
private class TextViewDelegateProxy: DelegateProxy<UITextViewDelegate>, UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        var shouldChange = true
        // 先执行代理方法
        if let delegateChange = delegate?.textView?(textView, shouldChangeTextIn: range, replacementText: text) {
            shouldChange = delegateChange
        }

        // 再执行内部方法
        if textView.fw.returnResign || textView.fw.returnNext || textView.fw.returnBlock != nil {
            // 判断是否输入回车
            if text == "\n" {
                // 切换到下一个输入框
                if textView.fw.returnNext {
                    textView.fw.goNext()
                    // 关闭键盘
                } else if textView.fw.returnResign {
                    textView.resignFirstResponder()
                }
                // 执行回调
                textView.fw.returnBlock?(textView)
                shouldChange = false
            }
        }
        return shouldChange
    }
}
