//
//  TestTextViewViewController.swift
//  Example
//
//  Created by wuyong on 2020/6/5.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

import FWFramework

@objcMembers class TestTextViewViewController: TestViewController {
    private lazy var textView: UITextView = {
        let result = UITextView(frame: CGRect(x: 16, y: 16, width: FWScreenWidth - 32, height: 44))
        result.fwPlaceholder = "我是TextView1"
        result.fwSetBorderColor(Theme.borderColor, width: 0.5, cornerRadius: 8)
        result.fwAutoHeightEnabled = true
        result.fwMaxLength = 100
        result.fwMinHeight = 44
        result.fwTouchResign = true
        result.fwVerticalAlignment = .center
        return result
    }()
    
    private lazy var textView2: UITextView = {
        let result = UITextView()
        result.fwPlaceholder = "我是TextView2\n我有两行"
        result.fwSetBorderColor(Theme.borderColor, width: 0.5, cornerRadius: 8)
        result.fwMinHeight = 44
        result.fwAutoHeight(withMaxHeight: 100) { height in
            result.fwLayoutChain.height(height)
        }
        result.fwTouchResign = true
        result.fwVerticalAlignment = .center
        return result
    }()
    
    private lazy var textView3: UITextView = {
        let result = UITextView()
        result.fwPlaceholder = "我是TextView2\n我是第二行\n我是第三行"
        result.fwSetBorderColor(Theme.borderColor, width: 0.5, cornerRadius: 8)
        result.fwTouchResign = true
        result.fwVerticalAlignment = .center
        return result
    }()
    
    override func renderView() {
        fwView.addSubview(textView)
        fwView.addSubview(textView2)
        fwView.addSubview(textView3)
        textView2.fwLayoutChain.left(16).right(16).topToBottomOfView(textView, withOffset: 16)
        textView3.fwLayoutChain.left(16).right(16).topToBottomOfView(textView2, withOffset: 16).height(44)
    }
    
    override func renderModel() {
        fwSetRightBarItem("切换") { [weak self] sender in
            self?.fwShowSheet(withTitle: nil, message: nil, cancel: "取消", actions: ["垂直居上", "垂直居中", "垂直居下"], actionBlock: { index in
                var verticalAlignment: UIControl.ContentVerticalAlignment = .top
                if index == 1 {
                    verticalAlignment = .center
                } else if index == 2 {
                    verticalAlignment = .bottom
                }
                self?.textView.fwVerticalAlignment = verticalAlignment
                self?.textView2.fwVerticalAlignment = verticalAlignment
                self?.textView3.fwVerticalAlignment = verticalAlignment
            })
        }
    }
}
