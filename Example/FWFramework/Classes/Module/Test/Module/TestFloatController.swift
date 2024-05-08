//
//  TestFloatController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/21.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestFloatController: UIViewController, ViewControllerProtocol {
    
    private lazy var floatView: FloatView = {
        let result = FloatView()
        result.padding = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        result.itemMargins = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        result.minimumItemSize = CGSize(width: 69, height: 29)
        result.layer.borderWidth = 0.5
        result.layer.borderColor = AppTheme.textColor.cgColor
        return result
    }()
    
    func setupSubviews() {
        view.addSubview(floatView)
        floatView.app.layoutChain
            .left(24)
            .right(24)
            .top(toSafeArea: 36)
        
        let suggestions = ["东野圭吾\n多行文本", "三体", "爱", "红楼梦", "", "理智与情感\n多行文本", "读书热榜", "免费榜"]
        for i in 0 ..< suggestions.count {
            if i < 3 {
                let label = UILabel()
                label.textColor = AppTheme.textColor
                label.numberOfLines = 0
                label.text = suggestions[i]
                label.font = APP.font(14)
                label.app.setBorderColor(AppTheme.textColor, width: 0.5, cornerRadius: 10)
                label.app.contentInset = UIEdgeInsets(top: 6, left: 20, bottom: 6, right: 20)
                floatView.addSubview(label)
            } else {
                let button = UIButton()
                button.setTitleColor(AppTheme.textColor, for: .normal)
                button.app.setBorderColor(AppTheme.textColor, width: 0.5, cornerRadius: 10)
                button.setTitle(suggestions[i], for: .normal)
                button.titleLabel?.font = APP.font(14)
                button.titleLabel?.numberOfLines = 0
                button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 20, bottom: 6, right: 20)
                button.isHidden = suggestions[i].isEmpty
                floatView.addSubview(button)
            }
        }
        
        floatView.setNeedsLayout()
        floatView.layoutIfNeeded()
        floatView.invalidateIntrinsicContentSize()
    }
    
}
