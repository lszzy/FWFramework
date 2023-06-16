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
        result.numberOfLines = 2
        result.lineBreakMode = .byTruncatingTail
        result.lineTruncatingSpacing = self.buttonWidth
        result.backgroundColor = AppTheme.backgroundColor
        result.font = FW.font(16)
        result.textColor = AppTheme.textColor
        result.textAlignment = .left
        return result
    }()
    
    func setupSubviews() {
        let subview = UIView()
        subview.backgroundColor = AppTheme.textColor
        view.addSubview(subview)
        subview.fw.addTapGesture { _ in
            subview.fw.isCollapsed = !subview.fw.isCollapsed
        }
        subview.fw.layoutChain.remake()
            .top(toSafeArea: 20)
            .left(20).collapse()
            .size(CGSize(width: 100, height: 100))
            .width(50).collapse()
            .height(50)
        
        let label = UILabel()
        label.text = "text"
        label.textAlignment = .center
        label.textColor = AppTheme.textColor
        label.backgroundColor = AppTheme.backgroundColor
        label.fw.contentInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        label.fw.setCornerRadius(5)
        label.isUserInteractionEnabled = true
        label.fw.addTapGesture { _ in
            subview.fw.isCollapsed = !subview.fw.isCollapsed
        }
        view.addSubview(label)
        label.fw.layoutMaker { make in
            make.width(50)
                .centerY(toView: subview)
                .left(toViewRight: subview, offset: 20)
        }
        
        let button = UIButton(type: .custom)
        button.setTitleColor(AppTheme.textColor, for: .normal)
        button.setTitle("btn", for: .normal)
        view.addSubview(button)
        button.fw.layoutChain
            .width(50)
            .height(toView: subview)
            .left(toViewRight: label, offset: 20)
            .top(toView: subview, offset: 0)
        
        let image = UIImageView()
        image.image = UIImage.fw.appIconImage()
        image.isUserInteractionEnabled = true
        image.fw.addTapGesture { _ in
            image.fw.isInactive = !image.fw.isInactive
        }
        view.addSubview(image)
        image.fw.layoutChain
            .width(50)
            .height(toWidth: 1.0)
            .centerY(toView: subview)
            .right(20).toggle(false)
            .attribute(.left, toAttribute: .right, ofView: button, offset: 20, relation: .equal, priority: .defaultHigh).toggle()
        
        let lineHeight = ceil(FW.font(16).lineHeight)
        let moreText = "点击展开"
        buttonWidth = moreText.fw.size(font: FW.font(16)).width + 20
        view.addSubview(attributedLabel)
        attributedLabel.fw.layoutChain
            .left(20)
            .right(20)
            .top(toViewBottom: subview, offset: 20)
        
        attributedLabel.text = "我是非常长的文本，要多长有多长，我会自动截断，再附加视图，不信你看嘛，我是显示不下了的文本，我是更多文本，我是更多更多的文本，我是更多更多的文本，我是更多更多的文本，我又要换行了"
        let collapseLabel = UILabel.fw.label(font: FW.font(16), textColor: UIColor.blue, text: "点击收起")
        collapseLabel.textAlignment = .center
        collapseLabel.frame = CGRect(x: 0, y: 0, width: buttonWidth, height: ceil(FW.font(16).lineHeight))
        collapseLabel.isUserInteractionEnabled = true
        collapseLabel.fw.addTapGesture { [weak self] _ in
            self?.attributedLabel.lineTruncatingSpacing = self?.buttonWidth ?? 0
            self?.attributedLabel.numberOfLines = 2
            self?.attributedLabel.lineBreakMode = .byTruncatingTail
        }
        attributedLabel.append(collapseLabel, margin: .zero)
        
        let expandLabel = UILabel.fw.label(font: FW.font(16), textColor: UIColor.blue, text: moreText)
        expandLabel.textAlignment = .center
        expandLabel.frame = CGRect(x: 0, y: 0, width: buttonWidth, height: lineHeight)
        expandLabel.isUserInteractionEnabled = true
        expandLabel.fw.addTapGesture { [weak self] _ in
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
        emptyLabel.fw.layoutMaker { make in
            make.top(toViewBottom: attributedLabel, offset: 20)
            make.left(20)
        }
        
        let emptyLabel2 = UILabel()
        emptyLabel2.textAlignment = .center
        emptyLabel2.textColor = AppTheme.textColor
        emptyLabel2.backgroundColor = AppTheme.backgroundColor
        emptyLabel2.fw.contentInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        view.addSubview(emptyLabel2)
        emptyLabel2.fw.layoutMaker { make in
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
        resultLabel.fw.layoutMaker { make in
            make.centerX().centerY(toView: emptyLabel2)
        }
        
        let numberLabel = UILabel()
        numberLabel.textAlignment = .center
        numberLabel.numberOfLines = 0
        numberLabel.textColor = AppTheme.textColor
        numberLabel.text = numberString()
        view.addSubview(numberLabel)
        numberLabel.fw.layoutMaker { make in
            make.left(20)
                .width((FW.screenWidth - 60) / 2.0)
                .top(toViewBottom: attributedLabel, offset: 50)
        }
        
        let number2Label = UILabel()
        number2Label.textAlignment = .center
        number2Label.numberOfLines = 0
        number2Label.textColor = AppTheme.textColor
        number2Label.text = number2String()
        view.addSubview(number2Label)
        number2Label.fw.layoutMaker { make in
            make.right(20)
                .width((FW.screenWidth - 60) / 2.0)
                .top(toViewBottom: attributedLabel, offset: 50)
        }
    }
    
    func numberString() -> String {
        let number = NSNumber(value: 45.6789)
        let string = NSMutableString()
        string.appendFormat("number: %@\n\n", number)
        string.appendFormat("round: %@\n", number.fw.roundString(2))
        string.appendFormat("ceil: %@\n", number.fw.ceilString(2))
        string.appendFormat("floor: %@\n", number.fw.floorString(2))
        string.appendFormat("round: %@\n", number.fw.roundNumber(2))
        string.appendFormat("ceil: %@\n", number.fw.ceilNumber(2))
        string.appendFormat("floor: %@\n", number.fw.floorNumber(2))
        return string as String
    }
    
    func number2String() -> String {
        let number = NSNumber(value: 0.6049)
        let string = NSMutableString()
        string.appendFormat("number: %@\n\n", number)
        string.appendFormat("round: %@\n", number.fw.roundString(2))
        string.appendFormat("ceil: %@\n", number.fw.ceilString(2))
        string.appendFormat("floor: %@\n", number.fw.floorString(2))
        string.appendFormat("round: %@\n", number.fw.roundNumber(2))
        string.appendFormat("ceil: %@\n", number.fw.ceilNumber(2))
        string.appendFormat("floor: %@\n", number.fw.floorNumber(2))
        return string as String
    }
    
}
