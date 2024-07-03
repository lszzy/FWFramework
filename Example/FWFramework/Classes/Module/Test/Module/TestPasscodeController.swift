//
//  TestPasscodeController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/10/18.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

enum TestPasscodeType: Int {
    case normal = 0
    case placeholder
    case custom
    case line
    case secretSymbol
    case secretImage
    case secretView
}

class TestPasscodeController: UIViewController, ViewControllerProtocol {
    
    var dataArray: [String] = [
        "Normal",
        "Placeholder",
        "Custom Box",
        "Line",
        "Secret Symbol",
        "Secret Image",
        "Secret View",
    ]
    
    var type: TestPasscodeType = .normal {
        didSet {
            updatePasscodeView()
        }
    }
    
    var boxInputView: PasscodeView?
    
    lazy var boxContainerView: UIView = {
        let result = UIView()
        return result
    }()
    
    lazy var securityButton: UIButton = {
        let result = AppTheme.largeButton()
        result.setTitle("Security", for: .normal)
        result.addTarget(self, action: #selector(securityButtonClicked), for: .touchUpInside)
        return result
    }()
    
    lazy var clearButton: UIButton = {
        let result = AppTheme.largeButton()
        result.setTitle("Clear", for: .normal)
        result.addTarget(self, action: #selector(clearButtonClicked), for: .touchUpInside)
        return result
    }()
    
    lazy var valueLabel: UILabel = {
        let result = UILabel()
        result.textColor = AppTheme.textColor
        result.font = UIFont.boldSystemFont(ofSize: 24)
        result.text = "Empty"
        return result
    }()
    
    func setupNavbar() {
        app.setRightBarItem(UIBarButtonItem.SystemItem.action) { [weak self] _ in
            self?.app.showSheet(title: nil, message: nil, actions: self?.dataArray, actionBlock: { index in
                self?.type = .init(rawValue: index) ?? .normal
            })
        }
    }
    
    func setupSubviews() {
        view.addSubview(valueLabel)
        view.addSubview(boxContainerView)
        view.addSubview(clearButton)
        view.addSubview(securityButton)
    }
    
    func setupLayout() {
        valueLabel.app.layoutChain
            .centerX()
            .top(toSafeArea: 30)
        
        boxContainerView.app.layoutChain
            .left(35)
            .right(35)
            .height(52)
            .top(toViewBottom: valueLabel, offset: 30)
        
        clearButton.app.layoutChain
            .centerX()
            .top(toViewBottom: boxContainerView, offset: 30)
        
        securityButton.app.layoutChain
            .centerX()
            .top(toViewBottom: clearButton, offset: 30)
        
        type = .normal
    }
    
    private func updatePasscodeView() {
        if let boxInputView = boxInputView {
            boxInputView.removeFromSuperview()
            valueLabel.text = "Empty"
        }
        
        var boxInputView: PasscodeView
        switch type {
        case .placeholder:
            boxInputView = generateBoxInputView_placeholder()
        case .custom:
            boxInputView = generateBoxInputView_custom()
        case .line:
            boxInputView = generateBoxInputView_line()
        case .secretSymbol:
            boxInputView = generateBoxInputView_secretSymbol()
        case .secretImage:
            boxInputView = generateBoxInputView_secretImage()
        case .secretView:
            boxInputView = generateBoxInputView_secretView()
        default:
            boxInputView = generateBoxInputView_normal()
        }
        self.boxInputView = boxInputView
        
        boxInputView.textDidChangeBlock = { [weak self] text, isFinished in
            if !text.isEmpty {
                self?.valueLabel.text = text
            } else {
                self?.valueLabel.text = "Empty"
            }
        }
        boxContainerView.addSubview(boxInputView)
        boxInputView.app.layoutChain.edges()
    }
    
    private func generateBoxInputView_normal() -> PasscodeView {
        let result = PasscodeView(codeLength: 4)
        result.collectionView.contentInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        result.collectionView.contentOffset = CGPoint(x: -40, y: 0)
        result.prepareView()
        result.inputType = .regex
        result.customInputRegex = "[^0-9]"
        result.textContentType = .oneTimeCode
        return result
    }
    
    private func generateBoxInputView_placeholder() -> PasscodeView {
        let cellProperty = PasscodeCellProperty()
        cellProperty.cellPlaceholderTextColor = UIColor(red: 114.0 / 255.0, green: 116.0 / 255.0, blue: 124.0 / 255.0, alpha: 0.3)
        cellProperty.cellPlaceholderFont = UIFont.systemFont(ofSize: 20)
        
        let result = PasscodeView(codeLength: 4)
        result.collectionView.contentInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        result.collectionView.contentOffset = CGPoint(x: -40, y: 0)
        result.showCursor = false
        result.placeholderText = "露可娜娜"
        result.cellProperty = cellProperty
        result.prepareView()
        return result
    }
    
    private func generateBoxInputView_custom() -> PasscodeView {
        let cellProperty = PasscodeCellProperty()
        cellProperty.cellBgColorNormal = AppTheme.cellColor
        cellProperty.cellBgColorSelected = .white
        cellProperty.cellCursorColor = AppTheme.textColor
        cellProperty.cellCursorWidth = 2
        cellProperty.cellCursorHeight = 27
        cellProperty.cornerRadius = 4
        cellProperty.borderWidth = 0
        cellProperty.cellFont = UIFont.boldSystemFont(ofSize: 24)
        cellProperty.cellTextColor = AppTheme.textColor
        cellProperty.configCellShadowBlock = { layer in
            layer.shadowColor = AppTheme.textColor.withAlphaComponent(0.2).cgColor
            layer.shadowOpacity = 1
            layer.shadowOffset = CGSize(width: 0, height: 2)
            layer.shadowRadius = 4
        }
        
        let result = PasscodeView(codeLength: 4)
        result.collectionView.contentInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        result.collectionView.contentOffset = CGPoint(x: -20, y: 0)
        result.flowLayout.itemSize = CGSize(width: 52, height: 52)
        result.cellProperty = cellProperty
        result.prepareView()
        return result
    }
    
    private func generateBoxInputView_line() -> PasscodeView {
        let cellProperty = PasscodeCellProperty()
        cellProperty.cellCursorColor = AppTheme.textColor
        cellProperty.cellCursorWidth = 2
        cellProperty.cellCursorHeight = 27
        cellProperty.cornerRadius = 0
        cellProperty.borderWidth = 0
        cellProperty.cellFont = UIFont.boldSystemFont(ofSize: 24)
        cellProperty.cellTextColor = AppTheme.textColor
        cellProperty.showLine = true
        cellProperty.customLineViewBlock = {
            let lineView = PasscodeLineView()
            lineView.underlineColorNormal = AppTheme.textColor.withAlphaComponent(0.3)
            lineView.underlineColorSelected = AppTheme.textColor.withAlphaComponent(0.7)
            lineView.underlineColorFilled = AppTheme.textColor
            lineView.lineView.app.layoutChain.remake()
                .height(4)
                .edges(excludingEdge: .top)
            lineView.selectChangeBlock = { lineView, selected in
                lineView.lineView.app.layoutChain.height(selected ? 6 : 4)
            }
            return lineView
        }
        
        let result = PasscodeView(codeLength: 4)
        result.collectionView.contentInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        result.collectionView.contentOffset = CGPoint(x: -20, y: 0)
        result.flowLayout.itemSize = CGSize(width: 52, height: 52)
        result.cellProperty = cellProperty
        result.prepareView()
        return result
    }
    
    private func generateBoxInputView_secretSymbol() -> PasscodeView {
        let cellProperty = PasscodeCellProperty()
        cellProperty.cellCursorColor = AppTheme.textColor
        cellProperty.cellCursorWidth = 2
        cellProperty.cellCursorHeight = 27
        cellProperty.cornerRadius = 0
        cellProperty.borderWidth = 0
        cellProperty.cellFont = UIFont.boldSystemFont(ofSize: 24)
        cellProperty.cellTextColor = AppTheme.textColor
        cellProperty.showLine = true
        cellProperty.securitySymbol = "*"
        
        let result = PasscodeView(codeLength: 4)
        result.collectionView.contentInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        result.collectionView.contentOffset = CGPoint(x: -20, y: 0)
        result.needSecurity = true
        result.flowLayout.itemSize = CGSize(width: 52, height: 52)
        result.cellProperty = cellProperty
        result.prepareView()
        
        result.clearAllWhenEditingBegin = true
        result.reloadInputString("5678")
        return result
    }
    
    private func generateBoxInputView_secretImage() -> PasscodeView {
        let cellProperty = PasscodeCellProperty()
        cellProperty.cellCursorColor = AppTheme.textColor
        cellProperty.cellCursorWidth = 2
        cellProperty.cellCursorHeight = 27
        cellProperty.cornerRadius = 0
        cellProperty.borderWidth = 0
        cellProperty.cellFont = UIFont.boldSystemFont(ofSize: 24)
        cellProperty.cellTextColor = AppTheme.textColor
        cellProperty.showLine = true
        cellProperty.securityType = .view
        cellProperty.customSecurityViewBlock = {
            let view = PasscodeSecrectImageView()
            view.image = APP.iconImage("zmdi-var-settings", 24) ?? UIImage()
            view.imageWidth = 23
            view.imageHeight = 23
            return view
        }
        
        let result = PasscodeView(codeLength: 4)
        result.collectionView.contentInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        result.collectionView.contentOffset = CGPoint(x: -20, y: 0)
        result.needSecurity = true
        result.flowLayout.itemSize = CGSize(width: 52, height: 52)
        result.cellProperty = cellProperty
        result.prepareView()
        return result
    }
    
    private func generateBoxInputView_secretView() -> PasscodeView {
        let cellProperty = PasscodeCellProperty()
        cellProperty.cellCursorColor = AppTheme.textColor
        cellProperty.cellCursorWidth = 2
        cellProperty.cellCursorHeight = 27
        cellProperty.cornerRadius = 0
        cellProperty.borderWidth = 0
        cellProperty.cellFont = UIFont.boldSystemFont(ofSize: 24)
        cellProperty.cellTextColor = AppTheme.textColor
        cellProperty.showLine = true
        cellProperty.securityType = .view
        cellProperty.customSecurityViewBlock = {
            let view = UIView()
            view.backgroundColor = .clear
            let circleView = UIView()
            circleView.backgroundColor = AppTheme.textColor
            circleView.layer.cornerRadius = 4
            view.addSubview(circleView)
            circleView.app.layoutChain.center()
                .width(20)
                .height(20)
            return view
        }
        
        let result = PasscodeView(codeLength: 4)
        result.collectionView.contentInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        result.collectionView.contentOffset = CGPoint(x: -20, y: 0)
        result.needSecurity = true
        result.flowLayout.itemSize = CGSize(width: 52, height: 52)
        result.cellProperty = cellProperty
        result.prepareView()
        return result
    }
    
    @objc func clearButtonClicked() {
        boxInputView?.clearAll()
    }
    
    @objc func securityButtonClicked() {
        guard let boxInputView = boxInputView else { return }
        boxInputView.needSecurity = !boxInputView.needSecurity
    }
    
}
