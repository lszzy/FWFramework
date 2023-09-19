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
    
    /// 初始化TextField视图，仅调用一次，一般用于配置键盘管理，自动聚焦等
    public func textFieldInitialize(
        _ initialization: @escaping (UITextField) -> Void,
        autoFocus viewContext: ViewContext? = nil
    ) -> some View {
        return textFieldConfigure { textField in
            guard textField.fw.property(forName: "textFieldInitialize") == nil else { return }
            textField.fw.setProperty(NSNumber(value: true), forName: "textFieldInitialize")
            
            if let viewController = viewContext?.viewController {
                viewController.fw.visibleStateChanged = { [weak textField] vc, state in
                    if state == .didAppear {
                        textField?.becomeFirstResponder()
                    } else if state == .willDisappear {
                        vc.view.endEditing(true)
                    }
                }
            }
            
            initialization(textField)
        }
    }
    
    /// 配置TextField视图，可调用多次
    public func textFieldConfigure(
        _ configuration: @escaping (UITextField) -> Void
    ) -> some View {
        return introspect(.textField, on: .iOS(.all)) { textField in
            configuration(textField)
        }
    }
    
    /// 初始化TextView视图，仅调用一次，一般用于配置键盘管理，自动聚焦等
    public func textViewInitialize(
        _ initialization: @escaping (UITextView) -> Void,
        autoFocus viewContext: ViewContext? = nil
    ) -> some View {
        return textViewConfigure { textView in
            guard textView.fw.property(forName: "textViewInitialize") == nil else { return }
            textView.fw.setProperty(NSNumber(value: true), forName: "textViewInitialize")
            
            if let viewController = viewContext?.viewController {
                viewController.fw.visibleStateChanged = { [weak textView] vc, state in
                    if state == .didAppear {
                        textView?.becomeFirstResponder()
                    } else if state == .willDisappear {
                        vc.view.endEditing(true)
                    }
                }
            }
            
            initialization(textView)
        }
    }
    
    /// 配置TextView视图，可调用多次
    public func textViewConfigure(
        _ configuration: @escaping (UITextView) -> Void
    ) -> some View {
        return introspect(.textEditor, on: .iOS(.v14, .v15, .v16)) { textView in
            configuration(textView)
        }
    }
    
}

#endif
