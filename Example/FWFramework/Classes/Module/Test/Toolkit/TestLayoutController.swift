//
//  TestLayoutController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/27.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestLayoutController: UIViewController, ViewControllerProtocol {
    
    var buttonWidth: CGFloat = 0
    
    lazy var attributedLabel: AttributedLabel = {
        let result = AttributedLabel()
        result.clipsToBounds = true
        result.numberOfLines = 3
        result.lineBreakMode = .byTruncatingTail
        result.lineTruncatingSpacing = self.buttonWidth
        result.backgroundColor = AppTheme.backgroundColor
        result.font = APP.font(16)
        result.textColor = AppTheme.textColor
        result.textAlignment = .left
        return result
    }()
    
    lazy var debugView: UIView = {
        let result = UIView()
        result.backgroundColor = AppTheme.textColor
        return result
    }()
    
    func setupNavbar() {
        view.app.layoutKey = "view"
        app.setRightBarItem("Debug") { [weak self] _ in
            self?.debugView.app.layoutChain
                .layoutKey("debugView")
                .width(49, relation: .lessThanOrEqual).identifier("debugView.widthLess")
                .left(19, relation: .lessThanOrEqual).identifier("debugView.leftLess")
                .top(toSafeArea: 19, relation: .lessThanOrEqual).identifier("debugView.topLess")
        }
    }
    
    func setupSubviews() {
        let subview = debugView
        view.addSubview(subview)
        subview.app.addTapGesture { _ in
            subview.app.isCollapsed = !subview.app.isCollapsed
        }
        subview.app.layoutChain.remake()
            .top(toSafeArea: 20).identifier("debugView.top")
            .left(20).collapse().identifier("debugView.left")
            .size(CGSize(width: 100, height: 100)).identifier("debugView.size")
            .width(50).collapse().identifier("debugView.width")
            .height(50)
        
        let label = UILabel()
        label.text = "text"
        label.textAlignment = .center
        label.textColor = AppTheme.textColor
        label.backgroundColor = AppTheme.backgroundColor
        label.app.contentInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        label.app.setCornerRadius(5)
        label.isUserInteractionEnabled = true
        label.app.addTapGesture { _ in
            subview.app.isCollapsed = !subview.app.isCollapsed
        }
        view.addSubview(label)
        label.app.layoutMaker { make in
            make.width(50)
                .centerY(toView: subview)
                .left(toViewRight: subview, offset: 20)
        }
        
        let button = UIButton(type: .custom)
        button.setTitleColor(AppTheme.textColor, for: .normal)
        button.setTitle("btn", for: .normal)
        view.addSubview(button)
        button.app.layoutChain
            .width(50)
            .height(toView: subview)
            .left(toViewRight: label, offset: 20)
            .top(toView: subview, offset: 0)
        
        let image = UIImageView()
        image.image = UIImage.app.appIconImage()
        image.isUserInteractionEnabled = true
        image.app.addTapGesture { _ in
            image.app.isCollapsed = !image.app.isCollapsed
        }
        view.addSubview(image)
        image.app.layoutChain
            .width(50)
            .height(toWidth: 1.0)
            .centerY(toView: subview)
            .right(20).collapseActive(false)
            .attribute(.left, toAttribute: .right, ofView: button, offset: 20, relation: .equal, priority: .defaultHigh).collapseActive()
        
        let iconsView = UIView()
        view.addSubview(iconsView)
        iconsView.chain
            .top(toViewBottom: subview, offset: 20)
            .horizontal(20)
            .height(50)
        
        UIView.app.autoScaleLayout = true
        for _ in 0..<4 {
            let iconView = UIImageView()
            iconView.image = UIImage.app.appIconImage()
            iconsView.addSubview(iconView)
        }
        iconsView.chain
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
        
        attributedLabel.text = "我是非常长的文本，我可以截断并附加视图，支持链接高亮https://www.baidu.com， #也可以实现标签# ， @实现对话 。我是更多更多的文本，我是更多更多的文本，我是更多更多的文本，我是更多更多的文本"
        let collapseLabel = UILabel.app.label(font: APP.font(16), textColor: UIColor.blue, text: "点击收起")
        collapseLabel.textAlignment = .center
        collapseLabel.frame = CGRect(x: 0, y: 0, width: buttonWidth, height: ceil(APP.font(16).lineHeight))
        collapseLabel.isUserInteractionEnabled = true
        collapseLabel.app.addTapGesture { [weak self] _ in
            self?.attributedLabel.lineTruncatingSpacing = self?.buttonWidth ?? 0
            self?.attributedLabel.numberOfLines = 3
            self?.attributedLabel.lineBreakMode = .byTruncatingTail
        }
        attributedLabel.append(collapseLabel, margin: .zero)
        
        let expandLabel = UILabel.app.label(font: APP.font(16), textColor: UIColor.blue, text: moreText)
        expandLabel.textAlignment = .center
        expandLabel.frame = CGRect(x: 0, y: 0, width: buttonWidth, height: lineHeight)
        expandLabel.isUserInteractionEnabled = true
        expandLabel.app.addTapGesture { [weak self] _ in
            self?.attributedLabel.lineTruncatingSpacing = 0
            self?.attributedLabel.numberOfLines = 0
            self?.attributedLabel.lineBreakMode = .byWordWrapping
        }
        attributedLabel.lineTruncatingAttachment = AttributedLabelAttachment(expandLabel, margin: .zero, alignment: .center, maxSize: .zero)
        
        let emptyLabel = UILabel()
        emptyLabel.textAlignment = .center
        emptyLabel.textColor = AppTheme.textColor
        emptyLabel.backgroundColor = AppTheme.backgroundColor
        view.addSubview(emptyLabel)
        emptyLabel.app.layoutMaker { make in
            make.top(toViewBottom: attributedLabel, offset: 20)
            make.left(20)
        }
        
        let emptyLabel2 = UILabel()
        emptyLabel2.textAlignment = .center
        emptyLabel2.textColor = AppTheme.textColor
        emptyLabel2.backgroundColor = AppTheme.backgroundColor
        emptyLabel2.app.contentInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        view.addSubview(emptyLabel2)
        emptyLabel2.app.layoutMaker { make in
            make.left(toViewRight: emptyLabel, offset: 20)
            make.centerY(toView: emptyLabel)
        }
        
        let resultLabel = UILabel()
        let emptySize = emptyLabel.sizeThatFits(CGSize(width: 1, height: 1))
        let emptySize2 = emptyLabel2.sizeThatFits(CGSize(width: 1, height: 1))
        resultLabel.text = "\(NSCoder.string(for: emptySize)) <=> \(NSCoder.string(for: emptySize2))"
        resultLabel.textAlignment = .center
        resultLabel.textColor = AppTheme.textColor
        view.addSubview(resultLabel)
        resultLabel.app.layoutMaker { make in
            make.centerX().centerY(toView: emptyLabel2)
        }
        
        let numberLabel = UILabel()
        numberLabel.textAlignment = .center
        numberLabel.numberOfLines = 0
        numberLabel.textColor = AppTheme.textColor
        numberLabel.text = numberString()
        view.addSubview(numberLabel)
        numberLabel.app.layoutMaker { make in
            make.left(20)
                .width((APP.screenWidth - 60) / 2.0)
                .top(toViewBottom: attributedLabel, offset: 50)
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
                .top(toViewBottom: attributedLabel, offset: 50)
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
