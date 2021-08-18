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
        let result = UITextView(frame: CGRect(x: 16, y: 16, width: FWScreenWidth - 32, height: 30))
        result.fwPlaceholder = "我是TextView1"
        result.fwSetBorderColor(Theme.borderColor, width: 0.5, cornerRadius: 8)
        result.fwAutoHeightEnabled = true
        result.fwMaxLength = 100
        return result
    }()
    
    private lazy var textView2: UITextView = {
        let result = UITextView()
        result.fwPlaceholder = "我是TextView2\n我有两行"
        result.fwSetBorderColor(Theme.borderColor, width: 0.5, cornerRadius: 8)
        result.fwAutoHeight(withMaxHeight: 100) { height in
            result.fwLayoutChain.height(height)
        }
        return result
    }()
    
    override func renderView() {
        fwView.addSubview(textView)
        fwView.addSubview(textView2)
        textView2.fwLayoutChain.left(16).right(16)
            .topToBottomOfView(textView, withOffset: 16)
            .height(textView2.fwHeight)
    }
}
