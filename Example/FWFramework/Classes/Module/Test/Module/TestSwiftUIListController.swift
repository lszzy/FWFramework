//
//  TestSwiftUIListController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/24.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

#if canImport(SwiftUI)
import SwiftUI
import Combine
import FWFramework

@available(iOS 13.0, *)
class TestSwiftUIListController: UIViewController, ViewControllerProtocol {
    
    func setupSubviews() {
        let hostingView = TestSwiftUIListContent()
            .navigationBarConfigure(
                leading: Icon.backImage,
                title: "TestSwiftUIListController",
                background: AppTheme.barColor
            )
            .wrappedHostingView()
        
        view.addSubview(hostingView)
        hostingView.app.layoutChain
            .horizontal()
            .top(toSafeArea: .zero)
            .bottom()
    }
    
}

@available(iOS 13.0, *)
struct TestSwiftUIListContent: View {
    
    @Environment(\.viewContext) var viewContext: ViewContext
    
    @ObservedObject var viewModel = TestSwiftUIListModel()
    
    var body: some View {
        List(viewModel.items, id: \.hash) { item in
            Text(item)
        }
    }
    
}

@available(iOS 13.0, *)
class TestSwiftUIListModel: ViewModel {
    
    @Published var items: [String] = {
        var result: [String] = []
        for i in 0 ..< 20 {
            result.append("\(i + 1)")
        }
        return result
    }()
    
}

#endif
