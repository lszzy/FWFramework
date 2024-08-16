//
//  TestLayoutController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/27.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestLayoutController: UIViewController, ViewControllerProtocol {
    
    private var buttonWidth: CGFloat = 0
    
    private lazy var attributedLabel: AttributedLabel = {
        let result = AttributedLabel()
        result.clipsToBounds = true
        result.numberOfLines = 3
        result.lineBreakMode = .byTruncatingTail
        result.lineTruncatingSpacing = self.buttonWidth
        result.backgroundColor = AppTheme.backgroundColor
        result.font = APP.font(16)
        result.lineSpacing = APP.font(16).pointSize / 2.0
        result.textColor = AppTheme.textColor
        result.textAlignment = .left
        result.clickedOnLink = { [weak self] linkData in
            guard let linkData = linkData as? String else { return }
            if linkData.app.isValid(.isUrl) {
                Router.openURL(linkData)
            } else {
                self?.app.showMessage(text: "点击了 \(linkData)")
            }
        }
        
        let linkDetector = AttributedLabelURLDetector()
        if let tagDetector = try? NSRegularExpression(pattern: "#[^#]+#") {
            linkDetector.addRegularExpression(tagDetector, attributes: [.underlineStyle: NSUnderlineStyle().rawValue])
        }
        if let usserDetector = try? NSRegularExpression(pattern: "@[^ ]+ ") {
            linkDetector.addRegularExpression(usserDetector, attributes: [.underlineStyle: NSUnderlineStyle().rawValue, .foregroundColor: UIColor.red])
        }
        result.linkDetector = linkDetector
        return result
    }()
    
    private lazy var debugView: UIView = {
        let result = UIView()
        return result
    }()
    
    private lazy var debugLabel: UILabel = {
        let result = UILabel()
        return result
    }()
    
    private lazy var debugButton: UIButton = {
        let result = UIButton(type: .custom)
        return result
    }()
    
    private lazy var debugImage: UIImageView = {
        let result = UIImageView()
        return result
    }()
    
    func setupNavbar() {
        view.app.layoutKey = "view"
        app.setRightBarItem(UIBarButtonItem.SystemItem.action) { [weak self] _ in
            self?.app.showSheet(title: nil, message: nil, actions: ["自动布局冲突调试"], actionBlock: { _ in
                self?.debugView.app.layoutChain
                    .layoutKey("debugView")
                    .width(49, relation: .lessThanOrEqual).identifier("debugView.widthLess")
                    .left(19, relation: .lessThanOrEqual).identifier("debugView.leftLess")
                    .top(toSafeArea: 19, relation: .lessThanOrEqual).identifier("debugView.topLess")
            })
        }
    }
    
    func setupSubviews() {
        view.arrangeSubviews {
            debugView
                .arrangeSetup({ result in
                    result.backgroundColor = AppTheme.textColor
                    result.app.addTapGesture { _ in
                        result.app.toggleCollapsed()
                    }
                    view.addSubview(result)
                })
                .layoutMaker { make in
                    make.top(toSafeArea: 20).identifier("debugView.top")
                        .left(20).collapse().identifier("debugView.left")
                        .size(CGSize(width: 100, height: 100)).identifier("debugView.size")
                        .width(50).collapse().identifier("debugView.width")
                        .height(50)
                }
            
            debugLabel
                .arrangeSetup { label in
                    label.text = "text"
                    label.textAlignment = .center
                    label.textColor = AppTheme.textColor
                    label.backgroundColor = AppTheme.backgroundColor
                    label.app.contentInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
                    label.app.setCornerRadius(5)
                    label.isUserInteractionEnabled = true
                    label.app.addTapGesture { [weak self] _ in
                        self?.debugView.app.toggleCollapsed()
                    }
                    view.addSubview(label)
                }
                .layoutChain
                    .width(50)
                    .centerY(toView: debugView)
                    .left(toViewRight: debugView, offset: 20)
            
            debugButton
                .arrangeSetup { button in
                    button.setTitleColor(AppTheme.textColor, for: .normal)
                    button.setTitle("btn", for: .normal)
                    view.addSubview(button)
                }
            
            debugImage
                .arrangeSetup { image in
                    image.image = UIImage.app.appIconImage()
                    image.isUserInteractionEnabled = true
                    image.app.addTapGesture { _ in
                        image.app.isCollapsed = !image.app.isCollapsed
                    }
                }
        }
        .arrangeLayout {
            debugButton.layoutMaker { make in
                make.width(50)
                    .height(toView: debugView)
                    .left(toViewRight: debugLabel, offset: 20)
                    .top(toView: debugView, offset: 0)
            }
            
            debugImage.layoutChain
                .width(50)
                .height(toWidth: 1.0)
                .centerY(toView: debugView)
                .right(20).collapseActive(false)
                .attribute(.left, toAttribute: .right, ofView: debugButton, offset: 20, relation: .equal, priority: .defaultHigh).collapseActive()
        }
        
        let iconsView = UIView()
        view.addSubview(iconsView)
        iconsView.layoutChain
            .top(toViewBottom: debugView, offset: 20)
            .horizontal(20)
            .height(50)
        
        UIView.app.autoScaleLayout = true
        for _ in 0..<4 {
            let iconView = UIImageView()
            iconView.image = UIImage.app.appIconImage()
            iconsView.addSubview(iconView)
        }
        iconsView.layoutChain
            .subviews(along: .horizontal, itemLength: APP.fixed(50), leadSpacing: 0, tailSpacing: 0)
            .subviews(along: .horizontal, leftSpacing: 0, rightSpacing: 0)
        UIView.app.autoScaleLayout = false
        
        let lineHeight = ceil(APP.font(16).lineHeight)
        let moreText = "点击展开"
        buttonWidth = moreText.app.size(font: APP.font(16)).width + 20
        view.addSubview(attributedLabel)
        attributedLabel.app.layoutChain
            .left(20)
            .right(20)
            .top(toViewBottom: iconsView, offset: 20)
        
        attributedLabel.text = "我是非常长的文本，我可以附加"
        attributedLabel.appendImage(UIImage.app.appIconImage()!, maxSize: CGSize(width: 16, height: 16))
        attributedLabel.appendAttributedText(NSAttributedString(string: "，支持链接高亮https://www.baidu.com， #也可以实现标签# ， @实现用户对话 。我是更多更多的文本，我是更多更多的文本，我是更多更多的文本，我是更多更多的文本", attributes: [.font: APP.font(16)]))
        let collapseLabel = UILabel.app.label(font: APP.font(16), textColor: UIColor.blue, text: "点击收起")
        collapseLabel.textAlignment = .center
        collapseLabel.frame = CGRect(x: 0, y: 0, width: buttonWidth, height: ceil(APP.font(16).lineHeight))
        collapseLabel.isUserInteractionEnabled = true
        collapseLabel.app.addTapGesture { [weak self] _ in
            self?.attributedLabel.lineTruncatingSpacing = self?.buttonWidth ?? 0
            self?.attributedLabel.numberOfLines = 3
            self?.attributedLabel.lineBreakMode = .byTruncatingTail
        }
        attributedLabel.appendView(collapseLabel, margin: .zero)
        
        let expandLabel = UILabel.app.label(font: APP.font(16), textColor: UIColor.blue, text: moreText)
        expandLabel.textAlignment = .center
        expandLabel.frame = CGRect(x: 0, y: 0, width: buttonWidth, height: lineHeight)
        expandLabel.isUserInteractionEnabled = true
        expandLabel.app.addTapGesture { [weak self] _ in
            self?.attributedLabel.lineTruncatingSpacing = 0
            self?.attributedLabel.numberOfLines = 0
            self?.attributedLabel.lineBreakMode = .byWordWrapping
        }
        attributedLabel.lineTruncatingAttachment = AttributedLabelAttachment(content: expandLabel, margin: .zero, alignment: .center, maxSize: .zero)
        
        let numberLabel = UILabel()
        numberLabel.textAlignment = .center
        numberLabel.numberOfLines = 0
        numberLabel.textColor = AppTheme.textColor
        numberLabel.text = numberString()
        view.addSubview(numberLabel)
        numberLabel.app.layoutMaker { make in
            make.left(20)
                .width((APP.screenWidth - 60) / 2.0)
                .top(toViewBottom: attributedLabel, offset: 20)
        }
        
        let number2Label = UILabel()
        number2Label.textAlignment = .center
        number2Label.numberOfLines = 0
        number2Label.textColor = AppTheme.textColor
        number2Label.text = number2String()
        view.addSubview(number2Label)
        number2Label.app.layoutMaker { make in
            make.right(20)
                .width((APP.screenWidth - 60) / 2.0)
                .top(toViewBottom: attributedLabel, offset: 20)
        }
        
        let emptyLabel = UILabel()
        emptyLabel.textAlignment = .center
        emptyLabel.textColor = AppTheme.textColor
        emptyLabel.backgroundColor = AppTheme.backgroundColor
        emptyLabel.app.contentInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        emptyLabel.app.setBorderColor(UIColor.red, width: UIScreen.app.pixelOne)
        view.addSubview(emptyLabel)
        emptyLabel.app.layoutMaker { make in
            make.top(toViewBottom: numberLabel, offset: 20)
            make.left(20)
        }
        
        let emptyButton = UIButton()
        emptyButton.app.contentCollapse = true
        emptyButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        emptyButton.setTitleColor(AppTheme.textColor, for: .normal)
        emptyButton.app.setBorderColor(UIColor.red, width: UIScreen.app.pixelOne)
        view.addSubview(emptyButton)
        emptyButton.app.layoutMaker { make in
            make.top(toViewBottom: numberLabel, offset: 20)
            make.left(toViewRight: emptyLabel, offset: 20)
        }
        
        let resultLabel = UILabel()
        let emptySize = emptyLabel.intrinsicContentSize.ceilValue
        let emptySize2 = emptyButton.intrinsicContentSize.ceilValue
        resultLabel.text = "\(NSCoder.string(for: emptySize)) <=> \(NSCoder.string(for: emptySize2))"
        resultLabel.textAlignment = .center
        resultLabel.textColor = AppTheme.textColor
        resultLabel.isUserInteractionEnabled = true
        resultLabel.app.addTapGesture { _ in
            emptyLabel.text = ["", "UILabel"].randomElement()
            emptyButton.setTitle([true, false].randomElement() == true ? "UILabel" : nil, for: .normal)
            emptyButton.setImage([true, false].randomElement() == true ? UIImage.app.appIconImage() : nil, for: .normal)
            let emptySize = emptyLabel.intrinsicContentSize.ceilValue
            let emptySize2 = emptyButton.intrinsicContentSize.ceilValue
            resultLabel.text = "\(NSCoder.string(for: emptySize)) <=> \(NSCoder.string(for: emptySize2))"
        }
        view.addSubview(resultLabel)
        resultLabel.app.layoutMaker { make in
            make.right(20).top(toViewBottom: numberLabel, offset: 20)
        }
        
        let bottomLeftImage = UIImageView()
        bottomLeftImage.image = UIImage.app.appIconImage()
        bottomLeftImage.isUserInteractionEnabled = true
        bottomLeftImage.app.addTapGesture { _ in
            bottomLeftImage.app.isCollapsed = !bottomLeftImage.app.isCollapsed
        }
        view.addSubview(bottomLeftImage)
        bottomLeftImage.app.layoutChain
            .size(width: 50, height: 50)
            .left(20).collapse()
            .bottom(20 + APP.safeAreaInsets.bottom).collapse(APP.safeAreaInsets.bottom)
        
        let bottomRightImage = UIImageView()
        bottomRightImage.image = UIImage.app.appIconImage()
        bottomRightImage.isUserInteractionEnabled = true
        bottomRightImage.app.addTapGesture { _ in
            bottomRightImage.app.isCollapsed = !bottomRightImage.app.isCollapsed
        }
        view.addSubview(bottomRightImage)
        bottomRightImage.app.layoutChain
            .size(width: 50, height: 50)
            .right(20).collapse()
            .bottom(20 + APP.safeAreaInsets.bottom).collapse(APP.safeAreaInsets.bottom)
    }
    
    func numberString() -> String {
        let number = NSNumber(value: 2345.6789)
        let string = NSMutableString()
        string.appendFormat("number: %@\n\n", number)
        string.appendFormat("round: %@\n", number.app.roundString())
        string.appendFormat("ceil: %@\n", number.app.ceilString())
        string.appendFormat("floor: %@\n", number.app.floorString())
        string.appendFormat("roundd: %@\n", number.app.roundString(2, groupingSeparator: ","))
        string.appendFormat("ceild: %@\n", number.app.ceilString(2, groupingSeparator: ","))
        string.appendFormat("floord: %@\n", number.app.floorString(2, groupingSeparator: ","))
        return string as String
    }
    
    func number2String() -> String {
        let number = NSNumber(value: -2345.6049)
        let string = NSMutableString()
        string.appendFormat("number: %@\n\n", number)
        string.appendFormat("round: %@\n", number.app.roundString())
        string.appendFormat("ceil: %@\n", number.app.ceilString())
        string.appendFormat("floor: %@\n", number.app.floorString())
        string.appendFormat("roundc: %@\n", number.app.roundString(2, groupingSeparator: ",", currencySymbol: "$"))
        string.appendFormat("ceilc: %@\n", number.app.ceilString(2, groupingSeparator: ",", currencySymbol: "$"))
        string.appendFormat("floorc: %@\n", number.app.floorString(2, groupingSeparator: ",", currencySymbol: "$"))
        return string as String
    }
    
}
