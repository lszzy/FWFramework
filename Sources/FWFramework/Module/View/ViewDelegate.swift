//
//  ViewDelegate.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
#if FWMacroSPM
import FWObjC
#endif

// MARK: - ScrollViewDelegate
/// 常用滚动视图事件代理，可继承
open class ScrollViewDelegate: DelegateProxy<UIScrollViewDelegate>, UIScrollViewDelegate {
    
    /// 滚动句柄，默认nil
    open var didScroll: ((UIScrollView) -> Void)?
    /// 即将开始拖动句柄，默认nil
    open var willBeginDragging: ((UIScrollView) -> Void)?
    /// 即将停止拖动句柄，默认nil
    open var willEndDragging: ((UIScrollView, CGPoint, UnsafeMutablePointer<CGPoint>) -> Void)?
    /// 已经停止拖动句柄，默认nil
    open var didEndDragging: ((UIScrollView, Bool) -> Void)?
    /// 已经停止减速句柄，默认nil
    open var didEndDecelerating: ((UIScrollView) -> Void)?
    /// 已经停止滚动动画句柄，默认nil
    open var didEndScrollingAnimation: ((UIScrollView) -> Void)?
    
    // MARK: - Lifecycle
    /// 初始化并绑定scrollView
    public convenience init(scrollView: UIScrollView) {
        self.init()
        scrollView.delegate = self
    }
    
    // MARK: - UIScrollViewDelegate
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if delegate?.scrollViewDidScroll?(scrollView) != nil {
            return
        }
        
        didScroll?(scrollView)
    }
    
    open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if delegate?.scrollViewWillBeginDragging?(scrollView) != nil {
            return
        }
        
        willBeginDragging?(scrollView)
    }
    
    open func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if delegate?.scrollViewWillEndDragging?(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset) != nil {
            return
        }
        
        willEndDragging?(scrollView, velocity, targetContentOffset)
    }
    
    open func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if delegate?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate) != nil {
            return
        }
        
        didEndDragging?(scrollView, decelerate)
    }
    
    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if delegate?.scrollViewDidEndDecelerating?(scrollView) != nil {
            return
        }
        
        didEndDecelerating?(scrollView)
    }
    
    open func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if delegate?.scrollViewDidEndScrollingAnimation?(scrollView) != nil {
            return
        }
        
        didEndScrollingAnimation?(scrollView)
    }
}

// MARK: - TextFieldDelegate
/// 常用TextField事件代理，可继承
open class TextFieldDelegate: DelegateProxy<UITextFieldDelegate>, UITextFieldDelegate {
    
    /// 是否应该开始编辑，默认nil
    open var shouldBeginEditing: ((UITextField) -> Bool)?
    /// 已开始编辑，默认nil
    open var didBeginEditing: ((UITextField) -> Void)?
    /// 是否应该结束编辑，默认nil
    open var shouldEndEditing: ((UITextField) -> Bool)?
    /// 已结束编辑，默认nil
    open var didEndEditing: ((UITextField) -> Void)?
    /// 是否应该改变字符，默认nil
    open var shouldChangeCharacters: ((UITextField, NSRange, String) -> Bool)?
    /// 选中已改变，仅iOS13+支持，默认nil
    open var didChangeSelection: ((UITextField) -> Void)?
    /// 是否应该清除，默认nil
    open var shouldClear: ((UITextField) -> Bool)?
    /// 是否应该回车，默认nil
    open var shouldReturn: ((UITextField) -> Bool)?
    
    // MARK: - Lifecycle
    /// 初始化并绑定textField
    public convenience init(textField: UITextField) {
        self.init()
        textField.delegate = self
    }
    
    // MARK: - UITextFieldDelegate
    open func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if let shouldBegin = delegate?.textFieldShouldBeginEditing?(textField) {
            return shouldBegin
        }
        
        return shouldBeginEditing?(textField) ?? true
    }
    
    open func textFieldDidBeginEditing(_ textField: UITextField) {
        if delegate?.textFieldDidBeginEditing?(textField) != nil {
            return
        }
        
        didBeginEditing?(textField)
    }
    
    open func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if let shouldEnd = delegate?.textFieldShouldEndEditing?(textField) {
            return shouldEnd
        }
        
        return shouldEndEditing?(textField) ?? true
    }
    
    open func textFieldDidEndEditing(_ textField: UITextField) {
        if delegate?.textFieldDidEndEditing?(textField) != nil {
            return
        }
        
        didEndEditing?(textField)
    }
    
    open func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let shouldChange = delegate?.textField?(textField, shouldChangeCharactersIn: range, replacementString: string) {
            return shouldChange
        }
        
        return shouldChangeCharacters?(textField, range, string) ?? true
    }
    
    @available(iOS 13.0, *)
    open func textFieldDidChangeSelection(_ textField: UITextField) {
        if delegate?.textFieldDidChangeSelection?(textField) != nil {
            return
        }
        
        didChangeSelection?(textField)
    }
    
    open func textFieldShouldClear(_ textField: UITextField) -> Bool {
        if let shouldClear = delegate?.textFieldShouldClear?(textField) {
            return shouldClear
        }
        
        return shouldClear?(textField) ?? true
    }
    
    open func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let shouldReturn = delegate?.textFieldShouldReturn?(textField) {
            return shouldReturn
        }
        
        return shouldReturn?(textField) ?? true
    }
    
}

// MARK: - TextViewDelegate
/// 常用TextView事件代理，可继承
open class TextViewDelegate: DelegateProxy<UITextViewDelegate>, UITextViewDelegate {
    
    /// 是否应该开始编辑，默认nil
    open var shouldBeginEditing: ((UITextView) -> Bool)?
    /// 已开始编辑，默认nil
    open var didBeginEditing: ((UITextView) -> Void)?
    /// 是否应该结束编辑，默认nil
    open var shouldEndEditing: ((UITextView) -> Bool)?
    /// 已结束编辑，默认nil
    open var didEndEditing: ((UITextView) -> Void)?
    /// 是否应该改变文本，默认nil
    open var shouldChangeText: ((UITextView, NSRange, String) -> Bool)?
    /// 文本已改变，默认nil
    open var didChange: ((UITextView) -> Void)?
    /// 选中已改变，默认nil
    open var didChangeSelection: ((UITextView) -> Void)?
    
    // MARK: - Lifecycle
    /// 初始化并绑定textView
    public convenience init(textView: UITextView) {
        self.init()
        textView.delegate = self
    }
    
    // MARK: - UITextViewDelegate
    open func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        if let shouldBegin = delegate?.textViewShouldBeginEditing?(textView) {
            return shouldBegin
        }
        
        return shouldBeginEditing?(textView) ?? true
    }
    
    open func textViewDidBeginEditing(_ textView: UITextView) {
        if delegate?.textViewDidBeginEditing?(textView) != nil {
            return
        }
        
        didBeginEditing?(textView)
    }
    
    open func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        if let shouldEnd = delegate?.textViewShouldEndEditing?(textView) {
            return shouldEnd
        }
        
        return shouldEndEditing?(textView) ?? true
    }
    
    open func textViewDidEndEditing(_ textView: UITextView) {
        if delegate?.textViewDidEndEditing?(textView) != nil {
            return
        }
        
        didEndEditing?(textView)
    }
    
    open func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if let shouldChange = delegate?.textView?(textView, shouldChangeTextIn: range, replacementText: text) {
            return shouldChange
        }
        
        return shouldChangeText?(textView, range, text) ?? true
    }
    
    open func textViewDidChangeSelection(_ textView: UITextView) {
        if delegate?.textViewDidChangeSelection?(textView) != nil {
            return
        }
        
        didChangeSelection?(textView)
    }
    
}

// MARK: - UIScrollView+ScrollViewDelegate
@_spi(FW) extension UIScrollView {
    
    /// 滚动事件代理，需手工设置delegate生效
    public var fw_scrollDelegate: ScrollViewDelegate {
        get {
            if let result = fw_property(forName: "fw_scrollDelegate") as? ScrollViewDelegate {
                return result
            } else {
                let result = ScrollViewDelegate()
                fw_setProperty(result, forName: "fw_scrollDelegate")
                return result
            }
        }
        set {
            fw_setProperty(newValue, forName: "fw_scrollDelegate")
        }
    }
    
}

// MARK: - UITextField+TextFieldDelegate
@_spi(FW) extension UITextField {
    
    /// 输入事件代理，需手工设置delegate生效
    public var fw_textDelegate: TextFieldDelegate {
        get {
            if let result = fw_property(forName: "fw_textDelegate") as? TextFieldDelegate {
                return result
            } else {
                let result = TextFieldDelegate()
                fw_setProperty(result, forName: "fw_textDelegate")
                return result
            }
        }
        set {
            fw_setProperty(newValue, forName: "fw_textDelegate")
        }
    }
    
}

// MARK: - UITextView+TextViewDelegate
@_spi(FW) extension UITextView {
    
    /// 输入事件代理，需手工设置delegate生效
    public var fw_textDelegate: TextViewDelegate {
        get {
            if let result = fw_property(forName: "fw_textDelegate") as? TextViewDelegate {
                return result
            } else {
                let result = TextViewDelegate()
                fw_setProperty(result, forName: "fw_textDelegate")
                return result
            }
        }
        set {
            fw_setProperty(newValue, forName: "fw_textDelegate")
        }
    }
    
}
