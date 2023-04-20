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
        _ configuration: @escaping (UITextField) -> Void,
        autoFocus viewContext: ViewContext? = nil
    ) -> some View {
        return introspectTextField { textField in
            guard !textField.fw_propertyBool(forName: "textFieldConfigure") else { return }
            textField.fw_setPropertyBool(true, forName: "textFieldConfigure")
            
            if let viewController = viewContext?.viewController {
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
    
    /// 配置TextView视图，仅调用一次，一般用于配置键盘管理，自动聚焦等
    public func textViewConfigure(
        _ configuration: @escaping (UITextView) -> Void,
        autoFocus viewContext: ViewContext? = nil
    ) -> some View {
        return introspectTextView { textView in
            guard !textView.fw_propertyBool(forName: "textViewConfigure") else { return }
            textView.fw_setPropertyBool(true, forName: "textViewConfigure")
            
            if let viewController = viewContext?.viewController {
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

#endif
