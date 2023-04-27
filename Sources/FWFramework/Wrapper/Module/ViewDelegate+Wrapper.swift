//
//  ScrollView+Wrapper.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

extension Wrapper where Base: UIScrollView {
    
    /// 滚动事件代理，需手工设置delegate生效
    public var scrollDelegate: ScrollViewDelegate {
        get { base.fw_scrollDelegate }
        set { base.fw_scrollDelegate = newValue }
    }
    
}

extension Wrapper where Base: UITextField {
    
    /// 输入事件代理，需手工设置delegate生效
    public var textDelegate: TextFieldDelegate {
        get { base.fw_textDelegate }
        set { base.fw_textDelegate = newValue }
    }
    
}

extension Wrapper where Base: UITextView {
    
    /// 输入事件代理，需手工设置delegate生效
    public var textDelegate: TextViewDelegate {
        get { base.fw_textDelegate }
        set { base.fw_textDelegate = newValue }
    }
    
}

extension Wrapper where Base: UISearchBar {
    
    /// 搜索栏事件代理，需手工设置delegate生效
    public var searchDelegate: SearchBarDelegate {
        get { base.fw_searchDelegate }
        set { base.fw_searchDelegate = newValue }
    }
    
}
