//
//  ViewDelegate.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

// MARK: - Wrapper+UIScrollView
@MainActor extension Wrapper where Base: UIScrollView {
    /// 滚动事件代理，需手工设置delegate生效
    public var scrollDelegate: ScrollViewDelegate {
        get {
            if let result = property(forName: "scrollDelegate") as? ScrollViewDelegate {
                return result
            } else {
                let result = ScrollViewDelegate()
                setProperty(result, forName: "scrollDelegate")
                return result
            }
        }
        set {
            setProperty(newValue, forName: "scrollDelegate")
        }
    }
}

// MARK: - Wrapper+UITextField
@MainActor extension Wrapper where Base: UITextField {
    /// 输入事件代理，需手工设置delegate生效
    public var textDelegate: TextFieldDelegate {
        get {
            if let result = property(forName: "textDelegate") as? TextFieldDelegate {
                return result
            } else {
                let result = TextFieldDelegate()
                setProperty(result, forName: "textDelegate")
                return result
            }
        }
        set {
            setProperty(newValue, forName: "textDelegate")
        }
    }
}

// MARK: - Wrapper+UITextView
@MainActor extension Wrapper where Base: UITextView {
    /// 输入事件代理，需手工设置delegate生效
    public var textDelegate: TextViewDelegate {
        get {
            if let result = property(forName: "textDelegate") as? TextViewDelegate {
                return result
            } else {
                let result = TextViewDelegate()
                setProperty(result, forName: "textDelegate")
                return result
            }
        }
        set {
            setProperty(newValue, forName: "textDelegate")
        }
    }
}

// MARK: - Wrapper+UISearchBar
@MainActor extension Wrapper where Base: UISearchBar {
    /// 搜索栏事件代理，需手工设置delegate生效
    public var searchDelegate: SearchBarDelegate {
        get {
            if let result = property(forName: "searchDelegate") as? SearchBarDelegate {
                return result
            } else {
                let result = SearchBarDelegate()
                setProperty(result, forName: "searchDelegate")
                return result
            }
        }
        set {
            setProperty(newValue, forName: "searchDelegate")
        }
    }
}

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

// MARK: - SearchBarDelegate
/// 常用SearchBar事件代理，可继承
open class SearchBarDelegate: DelegateProxy<UISearchBarDelegate>, UISearchBarDelegate {
    /// 是否应该开始编辑，默认nil
    open var shouldBeginEditing: ((UISearchBar) -> Bool)?
    /// 已开始编辑，默认nil
    open var didBeginEditing: ((UISearchBar) -> Void)?
    /// 是否应该结束编辑，默认nil
    open var shouldEndEditing: ((UISearchBar) -> Bool)?
    /// 已结束编辑，默认nil
    open var didEndEditing: ((UISearchBar) -> Void)?
    /// 文字已改变，默认nil
    open var textDidChange: ((UISearchBar, String) -> Void)?
    /// 是否应该改变文字，默认nil
    open var shouldChangeText: ((UISearchBar, NSRange, String) -> Bool)?
    /// 点击搜索按钮，默认nil
    open var searchButtonClicked: ((UISearchBar) -> Void)?
    /// 点击取消按钮，默认nil
    open var cancelButtonClicked: ((UISearchBar) -> Void)?

    // MARK: - Lifecycle
    /// 初始化并绑定searchBar
    public convenience init(searchBar: UISearchBar) {
        self.init()
        searchBar.delegate = self
    }

    // MARK: - UISearchBarDelegate
    open func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        if let shouldBegin = delegate?.searchBarShouldBeginEditing?(searchBar) {
            return shouldBegin
        }

        return shouldBeginEditing?(searchBar) ?? true
    }

    open func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        if delegate?.searchBarTextDidBeginEditing?(searchBar) != nil {
            return
        }

        didBeginEditing?(searchBar)
    }

    open func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        if let shouldEnd = delegate?.searchBarShouldEndEditing?(searchBar) {
            return shouldEnd
        }

        return shouldEndEditing?(searchBar) ?? true
    }

    open func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        if delegate?.searchBarTextDidEndEditing?(searchBar) != nil {
            return
        }

        didEndEditing?(searchBar)
    }

    open func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if delegate?.searchBar?(searchBar, textDidChange: searchText) != nil {
            return
        }

        textDidChange?(searchBar, searchText)
    }

    open func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if let shouldChange = delegate?.searchBar?(searchBar, shouldChangeTextIn: range, replacementText: text) {
            return shouldChange
        }

        return shouldChangeText?(searchBar, range, text) ?? true
    }

    open func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if delegate?.searchBarSearchButtonClicked?(searchBar) != nil {
            return
        }

        searchButtonClicked?(searchBar)
    }

    open func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if delegate?.searchBarCancelButtonClicked?(searchBar) != nil {
            return
        }

        cancelButtonClicked?(searchBar)
    }
}
