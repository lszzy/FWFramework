//
//  PasscodeView.swift
//  FWFramework
//
//  Created by wuyong on 2023/7/17.
//

import UIKit

// MARK: - PasscodeView
public enum PasscodeEditStatus: Int {
    case idle = 0
    case beginEdit
    case endEdit
}

public enum PasscodeInputType: Int {
    /// 数字
    case number = 0
    /// 普通（不作任何处理）
    case normal
    /// 自定义正则（此时需要设置customInputRegex）
    case regex
}

fileprivate enum PasscodeTextChangeType: Int {
    case none = 0
    case insert
    case delete
}

/// PasscodeView
///
/// [CRBoxInputView](https://github.com/CRAnimation/CRBoxInputView)
open class PasscodeView: UIView, UICollectionViewDataSource, UICollectionViewDelegate, UITextFieldDelegate {
    
    // MARK: - Accessor
    /// 是否需要光标，默认: YES
    open var showCursor: Bool = true

    /// 验证码长度，默认: 4
    open private(set) var codeLength: Int = 4 {
        didSet {
            flowLayout.itemNum = codeLength
        }
    }

    /// 是否开启密文模式，默认: NO，描述：你可以在任何时候修改该属性，并且已经存在的文字会自动刷新
    open var needSecurity: Bool = false {
        didSet {
            if needSecurity {
                allSecurityOpen()
            } else {
                allSecurityClose()
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.reloadAllCells()
            }
        }
    }

    /// 显示密文的延时时间，默认0防止录屏时录下明文
    open var securityDelay: TimeInterval = 0

    /// 键盘类型，默认: UIKeyboardTypeNumberPad
    open var keyboardType: UIKeyboardType = .numberPad {
        didSet {
            textField.keyboardType = keyboardType
        }
    }

    /// 输入样式，默认: PasscodeInputTypeNumber
    open var inputType: PasscodeInputType = .number

    /// 自定义正则匹配输入内容，默认: ""，当inputType == PasscodeInputTypeRegex时才会生效
    open var customInputRegex: String? = ""

    /// textContentType，描述: 你可以设置为 'nil' 或者 'UITextContentTypeOneTimeCode' 来自动获取短信验证码，默认: nil
    open var textContentType: UITextContentType? {
        didSet {
            textField.textContentType = textContentType
        }
    }

    /// 占位字符填充值，在对应的输入框没有内容时，会显示该值。默认：nil
    open var placeholderText: String?

    /// 弹出键盘时，是否清空所有输入，只有在输入的字数等于codeLength时，生效。默认: NO
    open var clearAllWhenEditingBegin: Bool = false

    /// 输入完成时，是否自动结束编辑模式，收起键盘。默认: YES
    open var endEditWhenEditingFinished: Bool = true

    open var textDidChangeBlock: ((_ text: String, _ isFinished: Bool) -> Void)?
    
    open var editStatusChangeBlock: ((PasscodeEditStatus) -> Void)?
    
    open var customCellBlock: ((PasscodeView, IndexPath) -> UICollectionViewCell)?
    
    open lazy var collectionView: UICollectionView = {
        let result = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        result.showsHorizontalScrollIndicator = false
        result.backgroundColor = .clear
        result.dataSource = self
        result.delegate = self
        result.layer.masksToBounds = true
        result.register(PasscodeCell.self, forCellWithReuseIdentifier: "FWPasscodeCellID")
        return result
    }()
    
    open lazy var flowLayout: PasscodeFlowLayout = {
        let result = PasscodeFlowLayout()
        result.itemNum = codeLength
        result.itemSize = CGSize(width: 42, height: 47)
        return result
    }()
    
    open var cellProperty: PasscodeCellProperty = .init()
    
    open var textValue: String {
        return textField.text ?? ""
    }
    
    open var textAccessoryView: UIView? {
        get { textField.inputAccessoryView }
        set { textField.inputAccessoryView = newValue }
    }
    
    private lazy var textField: UITextField = {
        let result = UITextField()
        result.fw_menuDisabled = true
        result.keyboardType = keyboardType
        result.delegate = self
        result.addTarget(self, action: #selector(textDidChange(_:)), for: .editingChanged)
        return result
    }()
    
    private lazy var tapGesture: UITapGestureRecognizer = {
        let result = UITapGestureRecognizer(target: self, action: #selector(textFieldBeginEdit))
        return result
    }()
    
    private var oldLength: Int = 0
    private var needBeginEdit: Bool = false
    private var valueArray: [String] = []
    private var cellPropertyArray: [PasscodeCellProperty] = []
    
    // MARK: - Lifecycle
    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        
        addNotificationObserver()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        
        addNotificationObserver()
    }
    
    public init(codeLength: Int) {
        super.init(frame: .zero)
        self.codeLength = codeLength
        backgroundColor = .clear
        
        addNotificationObserver()
    }
    
    deinit {
        removeNotificationObserver()
    }

    // MARK: - Public
    /// 装载数据和准备界面，beginEdit: 自动开启编辑模式。默认: YES
    open func prepareView(beginEdit: Bool = true) {
        guard codeLength > 0 else { return }
        
        generateCellPropertyArray()
        
        if collectionView.superview == nil {
            addSubview(collectionView)
            collectionView.fw_pinEdges()
        }
        
        if textField.superview == nil {
            addSubview(textField)
            textField.fw_setDimensions(.zero)
            textField.fw_pinEdge(toSuperview: .left)
            textField.fw_pinEdge(toSuperview: .top)
        }
        
        if tapGesture.view != self {
            addGestureRecognizer(tapGesture)
        }
        
        if textField.text != cellProperty.originValue {
            textField.text = cellProperty.originValue
            textDidChange(textField)
        }
        
        reloadAllCells()
        
        if beginEdit {
            self.beginEdit()
        }
    }

    /// 重载输入的数据（用来设置预设数据）
    open func reloadInputString(_ value: String?) {
        if textField.text != value {
            textField.text = value
            textDidChange(textField, manualInvoke: true)
        }
    }

    /// 开始编辑模式
    open func beginEdit() {
        if !textField.isFirstResponder {
            textField.becomeFirstResponder()
        }
    }
    
    /// 结束编辑模式
    open func endEdit() {
        if textField.isFirstResponder {
            textField.resignFirstResponder()
        }
    }

    /// 清空输入，beginEdit: 自动开启编辑模式。默认: YES
    open func clearAll(beginEdit: Bool = true) {
        oldLength = 0
        valueArray.removeAll()
        textField.text = ""
        allSecurityClose()
        reloadAllCells()
        textDidChangeBlock?(textValue, valueArray.count == codeLength)
        
        if beginEdit {
            self.beginEdit()
        }
    }

    /// 快速设置
    open func setSecuritySymbol(_ securitySymbol: String) {
        cellProperty.securitySymbol = securitySymbol.count != 1 ? "✱" : securitySymbol
    }
    
    /// 调整codeLength
    open func resetCodeLength(_ codeLength: Int, beginEdit: Bool = true) {
        guard codeLength > 0 else { return }
        
        self.codeLength = codeLength
        generateCellPropertyArray()
        clearAll(beginEdit: beginEdit)
    }
    
    // MARK: - UICollectionView
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return codeLength
    }
    
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell: UICollectionViewCell
        if let customCellBlock = customCellBlock {
            cell = customCellBlock(self, indexPath)
        } else {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FWPasscodeCellID", for: indexPath)
        }
        guard let cell = cell as? PasscodeCell,
              indexPath.row < cellPropertyArray.count else {
            return cell
        }
        
        cell.showCursor = showCursor
        let cellProperty = cellPropertyArray[indexPath.row]
        cellProperty.index = indexPath.row
        
        var currentPlaceholder: String?
        if (placeholderText?.count ?? 0) > indexPath.row {
            currentPlaceholder = placeholderText?.fw_substring(with: NSMakeRange(indexPath.row, 1))
            cellProperty.cellPlaceholderText = currentPlaceholder
        }
        
        let focusIndex = valueArray.count
        if valueArray.count > 0, indexPath.row <= focusIndex - 1 {
            cellProperty.originValue = valueArray[indexPath.row]
        } else {
            cellProperty.originValue = ""
        }
        
        cell.cellProperty = cellProperty
        if needBeginEdit {
            cell.isSelected = indexPath.row == focusIndex ? true : false
        } else {
            cell.isSelected = false
        }
        return cell
    }
    
    // MARK: - UITextFieldDelegate
    open func textFieldDidBeginEditing(_ textField: UITextField) {
        needBeginEdit = true
        
        if clearAllWhenEditingBegin, textValue.count == codeLength {
            clearAll()
        }
        
        editStatusChangeBlock?(.beginEdit)
        reloadAllCells()
    }
    
    open func textFieldDidEndEditing(_ textField: UITextField) {
        needBeginEdit = false
        
        editStatusChangeBlock?(.endEdit)
        reloadAllCells()
    }
    
    // MARK: - Private
    private func addNotificationObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive(_:)), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    private func removeNotificationObserver() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func applicationWillResignActive(_ notification: Notification) {
        // 触发home按下，光标动画移除
    }
    
    @objc private func applicationDidBecomeActive(_ notification: Notification) {
        // 重新进来后响应，光标动画重新开始
        reloadAllCells()
    }
    
    @objc private func textFieldBeginEdit() {
        beginEdit()
    }
    
    @objc private func textDidChange(_ textField: UITextField) {
        textDidChange(textField, manualInvoke: false)
    }
    
    private func textDidChange(_ textField: UITextField, manualInvoke: Bool) {
        var valueText = textField.text ?? ""
        valueText = valueText.replacingOccurrences(of: " ", with: "")
        valueText = filterInputContent(valueText)
        
        if valueText.count >= codeLength {
            valueText = valueText.fw_substring(to: codeLength)
            if endEditWhenEditingFinished {
                endEdit()
            }
        }
        textField.text = valueText
        
        var textChangeType: PasscodeTextChangeType = .none
        if valueText.count > oldLength {
            textChangeType = .insert
        } else if valueText.count < oldLength {
            textChangeType = .delete
        }
        
        if textChangeType == .delete {
            setSecurityShow(false, index: valueArray.count - 1)
            valueArray.removeLast()
        } else if textChangeType == .insert, valueText.count > 0 {
            if valueArray.count > 0 {
                replaceSecurityValue(index: valueArray.count - 1, equalCount: false)
            }
            valueArray.removeAll()
            
            valueText.enumerateSubstrings(in: valueText.startIndex ..< valueText.endIndex, options: .byComposedCharacterSequences) { [weak self] substring, _, _, _ in
                if let substring = substring {
                    self?.valueArray.append(substring)
                }
            }
            
            if needSecurity {
                if manualInvoke {
                    delaySecurityProcessAll()
                } else {
                    delaySecurityProcessLastOne()
                }
            }
        }
        
        reloadAllCells()
        oldLength = valueText.count
        if textChangeType != .none {
            textDidChangeBlock?(textValue, valueArray.count == codeLength)
        }
    }
    
    private func filterInputContent(_ input: String) -> String {
        let mutableString = NSMutableString(string: input)
        if inputType == .number {
            let regex = try? NSRegularExpression(pattern: "[^0-9]")
            regex?.replaceMatches(in: mutableString, range: NSMakeRange(0, mutableString.length), withTemplate: "")
        } else if inputType == .regex {
            if let customInputRegex = customInputRegex, !customInputRegex.isEmpty {
                let regex = try? NSRegularExpression(pattern: customInputRegex)
                regex?.replaceMatches(in: mutableString, range: NSMakeRange(0, mutableString.length), withTemplate: "")
            }
        }
        return mutableString as String
    }
    
    private func generateCellPropertyArray() {
        cellPropertyArray.removeAll()
        for _ in 0 ..< codeLength {
            cellPropertyArray.append(cellProperty.copy() as! PasscodeCellProperty)
        }
    }
    
    private func reloadAllCells() {
        collectionView.reloadData()
        
        let focusIndex = valueArray.count
        if focusIndex == codeLength {
            collectionView.scrollToItem(at: IndexPath(row: focusIndex - 1, section: 0), at: .right, animated: true)
        } else {
            collectionView.scrollToItem(at: IndexPath(row: focusIndex, section: 0), at: .centeredHorizontally, animated: true)
        }
    }
    
    private func replaceSecurityValue(index: Int, equalCount: Bool) {
        guard needSecurity else { return }
        
        if equalCount && index != valueArray.count - 1 { return }
        setSecurityShow(true, index: index)
    }
    
    private func setSecurityShow(_ isShow: Bool, index: Int) {
        guard index >= 0, index < cellPropertyArray.count else { return }
        
        let cellProperty = cellPropertyArray[index]
        cellProperty.showSecurity = isShow
    }
    
    private func allSecurityOpen() {
        for cellProperty in cellPropertyArray {
            if !cellProperty.showSecurity {
                cellProperty.showSecurity = true
            }
        }
    }
    
    private func allSecurityClose() {
        for cellProperty in cellPropertyArray {
            if cellProperty.showSecurity {
                cellProperty.showSecurity = false
            }
        }
    }
    
    private func delaySecurityProcessLastOne() {
        DispatchQueue.main.asyncAfter(deadline: .now() + securityDelay) { [weak self] in
            guard let this = self else { return }
            
            if this.valueArray.count > 0 {
                this.replaceSecurityValue(index: this.valueArray.count - 1, equalCount: true)
                DispatchQueue.main.async {
                    self?.reloadAllCells()
                }
            }
        }
    }
    
    private func delaySecurityProcessAll() {
        for index in 0 ..< valueArray.count {
            replaceSecurityValue(index: index, equalCount: false)
        }
        
        reloadAllCells()
    }
    
}

// MARK: - PasscodeCellProperty
public enum PasscodeSecurityType: Int {
    case symbol = 0
    case view
}

open class PasscodeCellProperty: NSObject, NSCopying {
    
    /// cell边框宽度，默认：0.5
    open var borderWidth: CGFloat = 0.5

    /// cell边框颜色，未选中状态时。默认：[UIColor colorWithRed:228/255.0 green:228/255.0 blue:228/255.0 alpha:1]
    open var cellBorderColorNormal: UIColor? = .init(red: 228.0 / 255.0, green: 228.0 / 255.0, blue: 228.0 / 255.0, alpha: 1)

    /// cell边框颜色，选中状态时。默认：[UIColor colorWithRed:255/255.0 green:70/255.0 blue:62/255.0 alpha:1]
    open var cellBorderColorSelected: UIColor? = .init(red: 255.0 / 255.0, green: 70.0 / 255.0, blue: 62.0 / 255.0, alpha: 1)

    /// cell边框颜色，无填充文字，未选中状态时。默认：与cellBorderColorFilled相同
    open var cellBorderColorFilled: UIColor?

    /// cell背景颜色，无填充文字，未选中状态时。默认：[UIColor whiteColor]
    open var cellBgColorNormal: UIColor? = .white

    /// cell背景颜色，选中状态时。默认：[UIColor whiteColor]
    open var cellBgColorSelected: UIColor? = .white

    /// cell背景颜色，填充文字后，未选中状态时。默认：与cellBgColorFilled相同
    open var cellBgColorFilled: UIColor?

    /// 光标颜色。默认： [UIColor colorWithRed:255/255.0 green:70/255.0 blue:62/255.0 alpha:1]
    open var cellCursorColor: UIColor? = .init(red: 255.0 / 255.0, green: 70.0 / 255.0, blue: 62.0 / 255.0, alpha: 1)

    /// 光标宽度。默认： 2
    open var cellCursorWidth: CGFloat = 2

    /// 光标高度。默认： 32
    open var cellCursorHeight: CGFloat = 32

    /// 圆角。默认： 4
    open var cornerRadius: CGFloat = 4

    /// 显示下划线。默认： NO
    open var showLine: Bool = false

    /// 字体/字号。默认：[UIFont systemFontOfSize:20]
    open var cellFont: UIFont? = .systemFont(ofSize: 20)

    /// 字体颜色。默认：[UIColor blackColor]
    open var cellTextColor: UIColor? = .black

    /// 是否密文显示。默认：NO
    open var showSecurity: Bool = false

    /// 密文符号。默认：✱，说明：只有showSecurity=YES时，有效
    open var securitySymbol: String = "✱"

    /// 保存当前显示的字符，若想一次性修改所有输入值，请使用reloadInputString方法。禁止修改该值！！！（除非你知道该怎么使用它。）
    open var originValue: String = ""

    /// 密文类型，默认：PasscodeSecurityTypeSymbol
    /// 类型说明：
    /// PasscodeSecurityTypeSymbol 符号类型，根据securitySymbol，originValue的内容来显示
    /// PasscodeSecurityTypeView 自定义View类型，可以自定义密文状态下的图片，View
    open var securityType: PasscodeSecurityType = .symbol

    /// 占位符默认填充值，禁止修改该值！！！（除非你知道该怎么使用它。）
    open var cellPlaceholderText: String?

    /// 占位符字体颜色，默认：[UIColor colorWithRed:114/255.0 green:126/255.0 blue:124/255.0 alpha:0.3]
    open var cellPlaceholderTextColor: UIColor? = .init(red: 114.0 / 255.0, green: 116.0 / 255.0, blue: 124.0 / 255.0, alpha: 0.3)

    /// 占位符字体/字号，默认：[UIFont systemFontOfSize:20]
    open var cellPlaceholderFont: UIFont? = .systemFont(ofSize: 20)
    
    /// 自定义密文View回调，默认创建视图
    open var customSecurityViewBlock: (() -> UIView)?
    
    /// 自定义下划线回调，默认PasscodeLineView
    open var customLineViewBlock: (() -> PasscodeLineView)?
    
    /// 自定义阴影回调，默认nil
    open var configCellShadowBlock: ((CALayer) -> Void)?

    open var index: Int = 0
    
    public required override init() {
        super.init()
        
        customSecurityViewBlock = {
            let securityView = UIView()
            securityView.backgroundColor = .clear
            
            let circleView = UIView()
            circleView.backgroundColor = .black
            circleView.layer.cornerRadius = 4
            securityView.addSubview(circleView)
            circleView.fw_setDimensions(CGSize(width: 20, height: 20))
            circleView.fw_alignCenter()
            return securityView
        }
        
        customLineViewBlock = {
            let lineView = PasscodeLineView()
            return lineView
        }
    }
    
    open func copy(with zone: NSZone? = nil) -> Any {
        let property = Self.init()
        property.borderWidth = borderWidth
        property.cellBorderColorNormal = cellBorderColorNormal
        property.cellBorderColorSelected = cellBorderColorSelected
        property.cellBorderColorFilled = cellBorderColorFilled
        property.cellBgColorNormal = cellBgColorNormal
        property.cellBgColorSelected = cellBgColorSelected
        property.cellBgColorFilled = cellBgColorFilled
        property.cellCursorColor = cellCursorColor
        property.cellCursorWidth = cellCursorWidth
        property.cellCursorHeight = cellCursorHeight
        property.cornerRadius = cornerRadius
        
        property.showLine = showLine
        property.cellFont = cellFont
        property.cellTextColor = cellTextColor
        property.showSecurity = showSecurity
        property.securitySymbol = securitySymbol
        property.originValue = originValue
        property.securityType = securityType
        property.cellPlaceholderText = cellPlaceholderText
        property.cellPlaceholderTextColor = cellPlaceholderTextColor
        property.cellPlaceholderFont = cellPlaceholderFont
        property.customSecurityViewBlock = customSecurityViewBlock
        property.customLineViewBlock = customLineViewBlock
        property.configCellShadowBlock = configCellShadowBlock
        property.index = index
        return property
    }
    
}

// MARK: - PasscodeCell
open class PasscodeCell: UICollectionViewCell {
    
    /// 指定cell属性
    open var cellProperty: PasscodeCellProperty = .init() {
        didSet {
            applyCellProperty()
        }
    }
    
    /// 是否显示光标，默认true
    open var showCursor: Bool = true
    
    open lazy var cursorView: UIView = {
        let result = UIView()
        return result
    }()
    
    private lazy var valueLabel: UILabel = {
        let result = UILabel()
        result.font = .systemFont(ofSize: 38)
        return result
    }()
    
    private var customSecurityView: UIView?
    
    private var lineView: PasscodeLineView?
    
    private lazy var opacityAnimation: CABasicAnimation = {
        let result = CABasicAnimation(keyPath: "opacity")
        result.fromValue = NSNumber(value: 1.0)
        result.toValue = NSNumber(value: 0.0)
        result.duration = 0.9
        result.repeatCount = .infinity
        result.isRemovedOnCompletion = true
        result.fillMode = .forwards
        result.timingFunction = .init(name: .easeIn)
        return result
    }()
    
    open override var isSelected: Bool {
        get {
            return super.isSelected
        }
        set {
            let isSelected = newValue
            if isSelected {
                layer.borderColor = cellProperty.cellBorderColorSelected?.cgColor
                backgroundColor = cellProperty.cellBgColorSelected
            } else {
                let hasFill = (valueLabel.text?.count ?? 0) > 0
                var cellBorderColor = cellProperty.cellBorderColorNormal
                var cellBackgroundColor = cellProperty.cellBgColorNormal
                if hasFill {
                    if cellProperty.cellBorderColorFilled != nil {
                        cellBorderColor = cellProperty.cellBorderColorFilled
                    }
                    if cellProperty.cellBgColorFilled != nil {
                        cellBackgroundColor = cellProperty.cellBgColorFilled
                    }
                }
                layer.borderColor = cellBorderColor?.cgColor
                backgroundColor = cellBackgroundColor
            }
            
            if let lineView = lineView {
                if !isSelected {
                    if cellProperty.originValue.count > 0, lineView.underlineColorFilled != nil {
                        lineView.lineView.backgroundColor = lineView.underlineColorFilled
                    } else if lineView.underlineColorNormal != nil {
                        lineView.lineView.backgroundColor = lineView.underlineColorNormal
                    } else {
                        lineView.lineView.backgroundColor = UIColor(red: 49.0 / 255.0, green: 51.0 / 255.0, blue: 64.0 / 255.0, alpha: 1)
                    }
                } else if isSelected, lineView.underlineColorSelected != nil {
                    lineView.lineView.backgroundColor = lineView.underlineColorSelected
                } else {
                    lineView.lineView.backgroundColor = UIColor(red: 49.0 / 255.0, green: 51.0 / 255.0, blue: 64.0 / 255.0, alpha: 1)
                }
                lineView.selected = isSelected
            }
            
            if showCursor {
                if isSelected {
                    cursorView.isHidden = false
                    cursorView.layer.add(opacityAnimation, forKey: "FWPasscodeCursorAnimationKey")
                } else {
                    cursorView.isHidden = true
                    cursorView.layer.removeAnimation(forKey: "FWPasscodeCursorAnimationKey")
                }
            } else {
                cursorView.isHidden = true
            }
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupSubviews()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setupSubviews()
    }
    
    private func setupSubviews() {
        isUserInteractionEnabled = false
        
        contentView.addSubview(valueLabel)
        valueLabel.fw_alignCenter()
        
        contentView.addSubview(cursorView)
        cursorView.fw_alignCenter()
        
        applyCellProperty()
    }
    
    open override func layoutSubviews() {
        if cellProperty.showLine, lineView == nil {
            lineView = cellProperty.customLineViewBlock?()
            if let lineView = lineView {
                contentView.addSubview(lineView)
                lineView.fw_pinEdges()
            }
        }
        
        if cellProperty.configCellShadowBlock != nil {
            cellProperty.configCellShadowBlock?(layer)
        }
        
        super.layoutSubviews()
    }
    
    private func applyCellProperty() {
        cursorView.backgroundColor = cellProperty.cellCursorColor
        cursorView.fw_setDimension(.width, size: cellProperty.cellCursorWidth)
        cursorView.fw_setDimension(.height, size: cellProperty.cellCursorHeight)
        layer.cornerRadius = cellProperty.cornerRadius
        layer.borderWidth = cellProperty.borderWidth
        
        valueLabel.isHidden = false
        hideCustomSecurityView()
        
        let hasOriginValue = !cellProperty.originValue.isEmpty
        if hasOriginValue {
            if cellProperty.showSecurity {
                if cellProperty.securityType == .symbol {
                    valueLabel.text = cellProperty.securitySymbol
                } else if cellProperty.securityType == .view {
                    valueLabel.isHidden = true
                    showCustomSecurityView()
                }
            } else {
                valueLabel.text = cellProperty.originValue
            }
            if cellProperty.cellFont != nil {
                valueLabel.font = cellProperty.cellFont
            }
            if cellProperty.cellTextColor != nil {
                valueLabel.textColor = cellProperty.cellTextColor
            }
        } else {
            let hasPlaceholderText = (cellProperty.cellPlaceholderText?.count ?? 0) > 0
            if hasPlaceholderText {
                valueLabel.text = cellProperty.cellPlaceholderText
                if cellProperty.cellPlaceholderFont != nil {
                    valueLabel.font = cellProperty.cellPlaceholderFont
                }
                if cellProperty.cellPlaceholderTextColor != nil {
                    valueLabel.textColor = cellProperty.cellPlaceholderTextColor
                }
            } else {
                valueLabel.text = ""
                if cellProperty.cellFont != nil {
                    valueLabel.font = cellProperty.cellFont
                }
                if cellProperty.cellTextColor != nil {
                    valueLabel.textColor = cellProperty.cellTextColor
                }
            }
        }
    }
    
    private func showCustomSecurityView() {
        if customSecurityView == nil {
            customSecurityView = cellProperty.customSecurityViewBlock?()
        }
        
        if let customSecurityView = customSecurityView,
           customSecurityView.superview == nil {
            contentView.addSubview(customSecurityView)
            customSecurityView.fw_pinEdges()
        }
        
        customSecurityView?.alpha = 1
    }
    
    private func hideCustomSecurityView() {
        customSecurityView?.alpha = 0
    }
    
}

// MARK: - PasscodeLineView
open class PasscodeLineView: UIView {
    
    /// 下划线颜色，未选中状态，且没有填充文字时。默认：[UIColor colorWithRed:49/255.0 green:51/255.0 blue:64/255.0 alpha:1]
    open var underlineColorNormal: UIColor? = .init(red: 49.0 / 255.0, green: 51.0 / 255.0, blue: 64.0 / 255.0, alpha: 1.0)

    /// 下划线颜色，选中状态时。默认：[UIColor colorWithRed:49/255.0 green:51/255.0 blue:64/255.0 alpha:1]
    open var underlineColorSelected: UIColor? = .init(red: 49.0 / 255.0, green: 51.0 / 255.0, blue: 64.0 / 255.0, alpha: 1.0)

    /// 下划线颜色，未选中状态，且有填充文字时。默认：[UIColor colorWithRed:49/255.0 green:51/255.0 blue:64/255.0 alpha:1]
    open var underlineColorFilled: UIColor? = .init(red: 49.0 / 255.0, green: 51.0 / 255.0, blue: 64.0 / 255.0, alpha: 1.0)

    /// 选择状态改变时回调
    open var selectChangeBlock: ((PasscodeLineView, Bool) -> Void)?
    
    open lazy var lineView: UIView = {
        let result = UIView()
        result.backgroundColor = underlineColorNormal
        result.layer.cornerRadius = 2
        result.layer.shadowColor = UIColor.black.withAlphaComponent(0.2).cgColor
        result.layer.shadowOpacity = 1
        result.layer.shadowOffset = CGSize(width: 0, height: 2)
        result.layer.shadowRadius = 4
        return result
    }()
    
    open var selected: Bool = false {
        didSet {
            selectChangeBlock?(self, selected)
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupSubviews()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setupSubviews()
    }
    
    private func setupSubviews() {
        addSubview(lineView)
        lineView.fw_pinEdges(excludingEdge: .top)
        lineView.fw_setDimension(.height, size: 4)
    }
    
}

// MARK: - PasscodeSecrectImageView
open class PasscodeSecrectImageView: UIView {
    
    open var image: UIImage? {
        didSet {
            lockImageView.image = image
        }
    }
    
    open var imageWidth: CGFloat = 0 {
        didSet {
            lockImageView.fw_setDimension(.width, size: imageWidth)
        }
    }
    
    open var imageHeight: CGFloat = 0 {
        didSet {
            lockImageView.fw_setDimension(.height, size: imageHeight)
        }
    }
    
    private lazy var lockImageView: UIImageView = {
        let result = UIImageView()
        return result
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupSubviews()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setupSubviews()
    }
    
    private func setupSubviews() {
        addSubview(lockImageView)
        lockImageView.fw_alignCenter()
    }
    
}

// MARK: - PasscodeFlowLayout
open class PasscodeFlowLayout: UICollectionViewFlowLayout {
    
    open var equalGap: Bool = true
    
    open var itemNum: Int = 1
    
    open var minLineSpacing: CGFloat = 10
    
    public override init() {
        super.init()
        
        didInitialize()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        didInitialize()
    }
    
    private func didInitialize() {
        scrollDirection = .horizontal
        minimumLineSpacing = 0
        minimumInteritemSpacing = 0
        sectionInset = .zero
    }
    
    open override func prepare() {
        if equalGap {
            updateLineSpacing()
        }
        
        super.prepare()
    }
    
    open func updateLineSpacing() {
        if itemNum > 1 {
            let width = CGRectGetWidth(collectionView?.frame ?? .zero)
            minimumLineSpacing = floor(1.0 * (width - CGFloat(itemNum) * itemSize.width - (collectionView?.contentInset.left ?? 0) - (collectionView?.contentInset.right ?? 0)) / (CGFloat(itemNum) - 1.0))
            
            if minimumLineSpacing < minLineSpacing {
                minimumLineSpacing = minLineSpacing
            }
        } else {
            minimumLineSpacing = 0
        }
    }
    
}
