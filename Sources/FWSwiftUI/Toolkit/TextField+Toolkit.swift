//
//  TextField+Toolkit.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/18.
//

#if canImport(SwiftUI)
import SwiftUI

// MARK: - TextField+Toolkit
@available(iOS 13.0, *)
extension View {
    
    /// 配置TextField视图，仅调用一次，一般用于配置键盘管理，自动聚焦等
    public func textFieldConfigure(
        autoFocus: Bool = false,
        configuration: @escaping (UITextField) -> Void
    ) -> some View {
        return introspectTextField { textField in
            guard textField.fw.property(forName: "textFieldConfigure") == nil else { return }
            textField.fw.setProperty(NSNumber(value: true), forName: "textFieldConfigure")
            
            if autoFocus, let viewController = textField.fw.viewController {
                viewController.fw.visibleStateChanged = { [weak textField] vc, state in
                    if state == .didAppear {
                        textField?.becomeFirstResponder()
                    } else if state == .willDisappear {
                        vc.view.endEditing(true)
                    }
                }
            }
            
            configuration(textField)
        }
    }
    
    /// 配置TextView视图，仅调用一次，一般用于配置键盘管理，自动聚焦等
    public func textViewConfigure(
        autoFocus: Bool = false,
        configuration: @escaping (UITextView) -> Void
    ) -> some View {
        return introspectTextView { textView in
            guard textView.fw.property(forName: "textViewConfigure") == nil else { return }
            textView.fw.setProperty(NSNumber(value: true), forName: "textViewConfigure")
            
            if autoFocus, let viewController = textView.fw.viewController {
                viewController.fw.visibleStateChanged = { [weak textView] vc, state in
                    if state == .didAppear {
                        textView?.becomeFirstResponder()
                    } else if state == .willDisappear {
                        vc.view.endEditing(true)
                    }
                }
            }
            
            configuration(textView)
        }
    }
    
}

#endif