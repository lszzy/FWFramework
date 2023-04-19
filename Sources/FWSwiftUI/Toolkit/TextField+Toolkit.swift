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
            if !textField.fw_propertyBool(forName: "textFieldConfigure") {
                textField.fw_setPropertyBool(true, forName: "textFieldConfigure")
                
                if autoFocus, let viewController = textField.fw_viewController {
                    viewController.fw_observeLifecycleState { [weak textField] vc, state in
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
    }
    
    /// 配置TextView视图，仅调用一次，一般用于配置键盘管理，自动聚焦等
    public func textViewConfigure(
        autoFocus: Bool = false,
        configuration: @escaping (UITextView) -> Void
    ) -> some View {
        return introspectTextView { textView in
            if !textView.fw_propertyBool(forName: "textViewConfigure") {
                textView.fw_setPropertyBool(true, forName: "textViewConfigure")
                
                if autoFocus, let viewController = textView.fw_viewController {
                    viewController.fw_observeLifecycleState { [weak textView] vc, state in
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
    
}

#endif
