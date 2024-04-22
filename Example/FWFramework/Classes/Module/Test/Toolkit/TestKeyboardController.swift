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
            mobileField.app.keyboardScrollView = useScrollView ? scrollView : nil
            passwordField.app.keyboardScrollView = useScrollView ? scrollView : nil
            textView.app.keyboardScrollView = useScrollView ? scrollView : nil
            descView.app.keyboardScrollView = useScrollView ? scrollView : nil
        }
    }
    
    private var appendString = ""
    private var popupMenu: PopupMenu?
    
    private lazy var mobileField: UITextField = {
        let result = createTextField()
        result.tag = 1
        result.app.maxUnicodeLength = 10
        result.app.menuDisabled = true
        result.placeholder = "禁止粘贴，最多10个中文"
        result.keyboardType = .default
        result.returnKeyType = .next
        result.textContentType = .telephoneNumber
        return result
    }()
    
    private lazy var passwordField: UITextField = {
        let result = createTextField()
        result.tag = 2
        result.delegate = self
        result.app.maxLength = 20
        result.placeholder = "仅数字和字母转大写，最多20个英文"
        result.keyboardType = .default
        result.returnKeyType = .next
        result.textContentType = .password
        return result
    }()
    
    private lazy var textView: UITextView = {
        let result = createTextView()
        result.tag = 3
        result.backgroundColor = AppTheme.backgroundColor
        result.app.maxLength = 200
        result.app.placeholder = "问题\n最多200个字符"
        result.app.lineHeight = 25
        result.app.textChangedBlock = { [weak self] text in
            self?.countLabel.text = "\(self?.textView.app.actualNumberOfLines ?? 0)行 \(text.count)/\(self?.textView.app.maxLength ?? 0)字"
        }
        // result.returnKeyType = .next
        return result
    }()
    
    private lazy var countLabel: UILabel = {
        let result = UILabel()
        result.font = UIFont.app.font(ofSize: 13)
        result.textColor = AppTheme.textColor
        result.textAlignment = .right
        result.text = "0行 0/\(textView.app.maxLength)字"
        return result
    }()
    
    private lazy var descView: UITextView = {
        let result = createTextView()
        result.tag = 4
        result.backgroundColor = AppTheme.backgroundColor
        result.app.maxLength = 20
        result.app.menuDisabled = true
        result.app.placeholder = "仅数字和字母转大写，最多20个英文"
        result.returnKeyType = .done
        result.app.returnResign = true
        result.app.keyboardDistance = 80
        result.app.delegate = self
        return result
    }()
    
    private lazy var submitButton: UIButton = {
        let result = AppTheme.largeButton()
        result.setTitle("提交", for: .normal)
        result.app.addTouch(target: self, action: #selector(onSubmit))
        return result
    }()
    
    func setupSubviews() {
        scrollView.backgroundColor = AppTheme.tableColor
        
        let textFieldAppearance = UITextField.appearance(whenContainedInInstancesOf: [TestKeyboardController.self])
        let textViewAppearance = UITextView.appearance(whenContainedInInstancesOf: [TestKeyboardController.self])
        textFieldAppearance.app.keyboardManager = true
        textFieldAppearance.app.touchResign = true
        textFieldAppearance.app.keyboardResign = true
        textFieldAppearance.app.reboundDistance = 200
        textViewAppearance.app.keyboardManager = true
        textViewAppearance.app.touchResign = true
        textViewAppearance.app.keyboardResign = true
        textViewAppearance.app.reboundDistance = 200
        
        contentView.addSubview(mobileField)
        mobileField.app.layoutChain
            .left(15)
            .right(15)
            .centerX()
        mobileField.app.returnNext = true
        mobileField.app.nextResponder = { [weak self] textField in
            return self?.passwordField
        }
        mobileField.app.addToolbar(title: NSAttributedString.app.attributedString(mobileField.placeholder ?? "", font: UIFont.systemFont(ofSize: 13)), doneBlock: nil)
        
        contentView.addSubview(passwordField)
        passwordField.app.layoutChain
            .centerX()
            .top(toViewBottom: mobileField)
        passwordField.app.returnNext = true
        passwordField.app.previousResponderTag = 1
        passwordField.app.nextResponderTag = 3
        passwordField.app.addToolbar(title: NSAttributedString.app.attributedString(passwordField.placeholder ?? "", font: UIFont.systemFont(ofSize: 13)), doneBlock: nil)
        
        contentView.addSubview(textView)
        textView.app.layoutChain
            .centerX()
            .top(toViewBottom: passwordField, offset: 15)
        // textView.app.returnNext = true
        textView.app.previousResponderTag = 2
        textView.app.nextResponderTag = 4
        textView.app.addToolbar(title: NSAttributedString.app.attributedString(textView.app.placeholder ?? "", font: UIFont.systemFont(ofSize: 13)), doneBlock: nil)
        
        contentView.addSubview(countLabel)
        countLabel.app.layoutChain
            .top(toViewBottom: textView, offset: 15)
            .right(15)
        
        contentView.addSubview(descView)
        descView.app.previousResponderTag = 3
        descView.app.addToolbar(title: NSAttributedString.app.attributedString(descView.app.placeholder ?? "", font: UIFont.systemFont(ofSize: 13)), doneBlock: nil)
        descView.app.layoutChain
            .centerX()
            .top(toViewBottom: countLabel, offset: 15)
        
        contentView.addSubview(submitButton)
        submitButton.app.layoutChain
            .centerX()
            .bottom(15)
            .top(toViewBottom: descView, offset: 15)
    }
    
    func setupLayout() {
        mobileField.app.autoCompleteBlock = { [weak self] text in
            guard let self = self else { return }
            if text.isEmpty {
                self.popupMenu?.dismiss()
            } else {
                self.popupMenu?.dismiss()
                self.popupMenu = PopupMenu.show(relyOn: self.mobileField, titles: [text], icons: nil, menuWidth: self.mobileField.app.width, customize: { popupMenu in
                    popupMenu.maskViewColor = .clear
                })
            }
        }
        
        descView.app.autoCompleteBlock = { [weak self] text in
            guard let self = self else { return }
            if text.isEmpty {
                self.popupMenu?.dismiss()
            } else {
                self.popupMenu?.dismiss()
                self.popupMenu = PopupMenu.show(relyOn: self.descView, titles: [text], icons: nil, menuWidth: self.descView.app.width, customize: { popupMenu in
                    popupMenu.maskViewColor = .clear
                })
            }
        }
        
        app.setRightBarItem("切换") { [weak self] _ in
            self?.app.showSheet(title: nil, message: nil, cancel: "取消", actions: ["切换滚动", "切换滚动时收起键盘", "切换滚动视图", "自动添加-"], currentIndex: -1, actionBlock: { index in
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
        let marginTop = APP.screenHeight - (390 + 15 + APP.topBarHeight + UIScreen.app.safeAreaInsets.bottom)
        let topInset = canScroll ? APP.screenHeight : marginTop
        mobileField.app.pinEdge(toSuperview: .top, inset: topInset)
    }
    
    private func createTextField() -> UITextField {
        let result = UITextField()
        result.font = UIFont.app.font(ofSize: 15)
        result.textColor = AppTheme.textColor
        result.tintColor = AppTheme.textColor
        result.app.cursorRect = CGRect(x: 0, y: 0, width: 2, height: 0)
        result.clearButtonMode = .whileEditing
        result.app.setBorderView(.bottom, color: AppTheme.borderColor, width: 0.5)
        result.app.setDimension(.width, size: APP.screenWidth - 30)
        result.app.setDimension(.height, size: 50)
        return result
    }
    
    private func createTextView() -> UITextView {
        let result = UITextView()
        result.font = UIFont.app.font(ofSize: 15)
        result.textColor = AppTheme.textColor
        result.tintColor = AppTheme.textColor
        result.app.cursorRect = CGRect(x: 0, y: 0, width: 2, height: 0)
        result.app.setBorderColor(AppTheme.borderColor, width: 0.5, cornerRadius: 5)
        result.app.setDimension(.width, size: APP.screenWidth - 30)
        result.app.setDimension(.height, size: 100)
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
            textField.text = textField.app.filterText(filterText)
            
            var offset = range.location + replaceString.count
            if offset > textField.app.maxLength {
                offset = textField.app.maxLength
            }
            textField.app.moveCursor(offset)
            return false
        }
        
        return true
    }
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        print("textViewShouldBeginEditing")
        return true
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText string: String) -> Bool {
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
            let curText = (textView.text ?? "") as NSString
            let filterText = curText.replacingCharacters(in: range, with: replaceString)
            textView.text = textView.app.filterText(filterText)
            
            var offset = range.location + replaceString.count
            if offset > textView.app.maxLength {
                offset = textView.app.maxLength
            }
            textView.app.moveCursor(offset)
            return false
        }
        
        return true
    }
    
    @objc func onSubmit() {
        view.endEditing(true)
        app.showMessage(text: "点击了提交")
    }
    
}
