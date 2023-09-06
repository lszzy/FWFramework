//
//  TestKeyboardController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/28.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestKeyboardController: UIViewController, ScrollViewControllerProtocol, UITextFieldDelegate, UITextViewDelegate {
    
    private var canScroll = false {
        didSet {
            view.endEditing(true)
            renderData()
        }
    }
    
    private var dismissOnDrag = false {
        didSet {
            view.endEditing(true)
            scrollView.keyboardDismissMode = dismissOnDrag ? .onDrag : .none
        }
    }
    
    private var useScrollView = false {
        didSet {
            view.endEditing(true)
            navigationItem.title = useScrollView ? "UIScrollView+FWKeyboard" : "UITextField+FWKeyboard"
            mobileField.fw.keyboardScrollView = useScrollView ? scrollView : nil
            passwordField.fw.keyboardScrollView = useScrollView ? scrollView : nil
            textView.fw.keyboardScrollView = useScrollView ? scrollView : nil
            descView.fw.keyboardScrollView = useScrollView ? scrollView : nil
        }
    }
    
    private var appendString = ""
    private var popupMenu: PopupMenu?
    
    private lazy var mobileField: UITextField = {
        let result = createTextField()
        result.tag = 1
        result.fw.maxUnicodeLength = 10
        result.fw.menuDisabled = true
        result.placeholder = "禁止粘贴，最多10个中文"
        result.keyboardType = .default
        result.returnKeyType = .next
        return result
    }()
    
    private lazy var passwordField: UITextField = {
        let result = createTextField()
        result.tag = 2
        result.delegate = self
        result.fw.maxLength = 20
        result.placeholder = "仅数字和字母转大写，最多20个英文"
        result.keyboardType = .default
        result.returnKeyType = .next
        return result
    }()
    
    private lazy var textView: UITextView = {
        let result = createTextView()
        result.tag = 3
        result.delegate = self
        result.backgroundColor = AppTheme.backgroundColor
        result.fw.maxUnicodeLength = 50
        result.fw.placeholder = "问题\n最多50个中文"
        result.app.lineHeight = 25
        // result.returnKeyType = .next
        return result
    }()
    
    private lazy var descView: UITextView = {
        let result = createTextView()
        result.tag = 4
        result.backgroundColor = AppTheme.backgroundColor
        result.fw.maxLength = 20
        result.fw.menuDisabled = true
        result.fw.placeholder = "建议，最多20个英文"
        result.returnKeyType = .done
        result.fw.returnResign = true
        result.fw.keyboardDistance = 80
        result.fw.delegate = self
        return result
    }()
    
    private lazy var submitButton: UIButton = {
        let result = AppTheme.largeButton()
        result.setTitle("提交", for: .normal)
        result.fw.addTouch(target: self, action: #selector(onSubmit))
        return result
    }()
    
    func setupSubviews() {
        scrollView.backgroundColor = AppTheme.tableColor
        
        let textFieldAppearance = UITextField.appearance(whenContainedInInstancesOf: [TestKeyboardController.self])
        let textViewAppearance = UITextView.appearance(whenContainedInInstancesOf: [TestKeyboardController.self])
        textFieldAppearance.fw.keyboardManager = true
        textFieldAppearance.fw.touchResign = true
        textFieldAppearance.fw.keyboardResign = true
        textFieldAppearance.fw.reboundDistance = 200
        textViewAppearance.fw.keyboardManager = true
        textViewAppearance.fw.touchResign = true
        textViewAppearance.fw.keyboardResign = true
        textViewAppearance.fw.reboundDistance = 200
        
        contentView.addSubview(mobileField)
        mobileField.fw.layoutChain
            .left(15)
            .right(15)
            .centerX()
        mobileField.fw.returnNext = true
        mobileField.fw.nextResponder = { [weak self] textField in
            return self?.passwordField
        }
        mobileField.fw.addToolbar(title: NSAttributedString.fw.attributedString(mobileField.placeholder ?? "", font: UIFont.systemFont(ofSize: 13)), doneBlock: nil)
        
        contentView.addSubview(passwordField)
        passwordField.fw.layoutChain
            .centerX()
            .top(toViewBottom: mobileField)
        passwordField.fw.returnNext = true
        passwordField.fw.previousResponderTag = 1
        passwordField.fw.nextResponderTag = 3
        passwordField.fw.addToolbar(title: NSAttributedString.fw.attributedString(passwordField.placeholder ?? "", font: UIFont.systemFont(ofSize: 13)), doneBlock: nil)
        
        contentView.addSubview(textView)
        textView.fw.layoutChain
            .centerX()
            .top(toViewBottom: passwordField, offset: 15)
        // textView.fw.returnNext = true
        textView.fw.previousResponderTag = 2
        textView.fw.nextResponderTag = 4
        textView.fw.addToolbar(title: NSAttributedString.fw.attributedString(textView.fw.placeholder ?? "", font: UIFont.systemFont(ofSize: 13)), doneBlock: nil)
        
        contentView.addSubview(descView)
        descView.fw.previousResponderTag = 3
        descView.fw.addToolbar(title: NSAttributedString.fw.attributedString(descView.fw.placeholder ?? "", font: UIFont.systemFont(ofSize: 13)), doneBlock: nil)
        descView.fw.layoutChain
            .centerX()
            .top(toViewBottom: textView, offset: 15)
        
        contentView.addSubview(submitButton)
        submitButton.fw.layoutChain
            .centerX()
            .bottom(15)
            .top(toViewBottom: descView, offset: 15)
    }
    
    func setupLayout() {
        mobileField.fw.autoCompleteBlock = { [weak self] text in
            guard let self = self else { return }
            if text.isEmpty {
                self.popupMenu?.dismiss()
            } else {
                self.popupMenu?.dismiss()
                self.popupMenu = PopupMenu.showRely(on: self.mobileField, titles: [text], icons: nil, menuWidth: self.mobileField.fw.width, otherSettings: { popupMenu in
                    popupMenu.showMaskView = false
                })
            }
        }
        
        descView.fw.autoCompleteBlock = { [weak self] text in
            guard let self = self else { return }
            if text.isEmpty {
                self.popupMenu?.dismiss()
            } else {
                self.popupMenu?.dismiss()
                self.popupMenu = PopupMenu.showRely(on: self.descView, titles: [text], icons: nil, menuWidth: self.descView.fw.width, otherSettings: { popupMenu in
                    popupMenu.showMaskView = false
                })
            }
        }
        
        fw.setRightBarItem("切换") { [weak self] _ in
            self?.fw.showSheet(title: nil, message: nil, cancel: "取消", actions: ["切换滚动", "切换滚动时收起键盘", "切换滚动视图", "自动添加-"], currentIndex: -1, actionBlock: { index in
                guard let self = self else { return }
                if index == 0 {
                    self.canScroll = !self.canScroll
                } else if index == 1 {
                    self.dismissOnDrag = !self.dismissOnDrag
                } else if index == 2 {
                    self.useScrollView = !self.useScrollView
                } else {
                    self.appendString = !self.appendString.isEmpty ? "" : "-"
                }
            })
        }
        
        renderData()
    }
    
    private func renderData() {
        let marginTop = FW.screenHeight - (390 + 15 + FW.topBarHeight + UIScreen.fw.safeAreaInsets.bottom)
        let topInset = canScroll ? FW.screenHeight : marginTop
        mobileField.fw.pinEdge(toSuperview: .top, inset: topInset)
    }
    
    private func createTextField() -> UITextField {
        let result = UITextField()
        result.font = UIFont.fw.font(ofSize: 15)
        result.textColor = AppTheme.textColor
        result.tintColor = AppTheme.textColor
        result.fw.cursorRect = CGRect(x: 0, y: 0, width: 2, height: 0)
        result.clearButtonMode = .whileEditing
        result.fw.setBorderView(.bottom, color: AppTheme.borderColor, width: 0.5)
        result.fw.setDimension(.width, size: FW.screenWidth - 30)
        result.fw.setDimension(.height, size: 50)
        return result
    }
    
    private func createTextView() -> UITextView {
        let result = UITextView()
        result.font = UIFont.fw.font(ofSize: 15)
        result.textColor = AppTheme.textColor
        result.tintColor = AppTheme.textColor
        result.fw.cursorRect = CGRect(x: 0, y: 0, width: 2, height: 0)
        result.fw.setBorderColor(AppTheme.borderColor, width: 0.5, cornerRadius: 5)
        result.fw.setDimension(.width, size: FW.screenWidth - 30)
        result.fw.setDimension(.height, size: 100)
        return result
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string == "\n" {
            return true
        }
        
        let allowedChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        let characterSet = CharacterSet(charactersIn: allowedChars).inverted
        let filterString = string.components(separatedBy: characterSet).joined(separator: "")
        if string != filterString {
            return false
        }
        
        if !string.isEmpty {
            var replaceString = string.uppercased()
            if !appendString.isEmpty {
                replaceString = replaceString.appending(appendString)
            }
            let curText = (textField.text ?? "") as NSString
            let filterText = curText.replacingCharacters(in: range, with: replaceString)
            textField.text = textField.fw.filterText(filterText)
            
            var offset = range.location + replaceString.count
            if offset > textField.fw.maxLength {
                offset = textField.fw.maxLength
            }
            textField.fw.moveCursor(offset)
            return false
        }
        
        return true
    }
    
    @objc func onSubmit() {
        view.endEditing(true)
        fw.showMessage(text: "点击了提交")
    }
    
}
