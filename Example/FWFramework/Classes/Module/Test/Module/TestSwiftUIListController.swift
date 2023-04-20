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
    
    private lazy var contentView: TestSwiftUIListContent = {
        let result = TestSwiftUIListContent()
        return result
    }()
    
    func setupNavbar() {
        app.setRightBarItem(UIBarButtonItem.SystemItem.action.rawValue) { [weak self] _ in
            self?.app.showSheet(title: nil, message: nil, actions: ["automatic", "plain", "grouped", "sidebar (14+)", "insetGrouped (14+)", "inset (14+)", "beginRefreshing", "beginLoading"], actionBlock: { index in
                if index < 6 {
                    self?.contentView.viewModel.style = index
                } else if index == 6 {
                    self?.contentView.viewModel.beginRefreshing = true
                } else if index == 7 {
                    self?.contentView.viewModel.beginLoading = true
                }
            })
        }
    }
    
    func setupSubviews() {
        let hostingView = contentView
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
        List {
            Section {
                ForEach(viewModel.items, id: \.hash) { item in
                    Text(item)
                        .padding(.leading, 16)
                        .resetCellStyle(background: Color(AppTheme.cellColor))
                }
            } header: {
                Text("Header")
                    .padding(.leading, 16)
                    .resetHeaderStyle(background: Color(AppTheme.cellColor))
            } footer: {
                Text("Footer\nFooter 2")
                    .padding(.leading, 16)
                    .resetHeaderStyle(background: Color(AppTheme.cellColor))
            }
        }
        .then({ list in
            switch viewModel.style {
            case 0:
                return list.listStyle(.automatic).eraseToAnyView()
            case 1:
                return list.listStyle(.plain).eraseToAnyView()
            case 2:
                return list.listStyle(.grouped).eraseToAnyView()
            case 3:
                if #available(iOS 14.0, *) {
                    return list.listStyle(.sidebar).eraseToAnyView()
                }
            case 4:
                if #available(iOS 14.0, *) {
                    return list.listStyle(.insetGrouped).eraseToAnyView()
                }
            case 5:
                if #available(iOS 14.0, *) {
                    return list.listStyle(.inset).eraseToAnyView()
                }
            default:
                break
            }
            return list.eraseToAnyView()
        })
        .resetListStyle(background: Color(AppTheme.tableColor), isPlainStyle: viewModel.style == 1)
        .listViewRefreshing(
            shouldBegin: $viewModel.beginRefreshing,
            action: { completionHandler in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    completionHandler()
                }
            })
        .listViewLoading(
            shouldBegin: $viewModel.beginLoading,
            action: { completionHandler in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    completionHandler(!viewModel.addItems())
                }
            })
    }
    
}

@available(iOS 13.0, *)
class TestSwiftUIListModel: ViewModel {
    
    @Published var style: Int = 0
    
    @Published var beginRefreshing = false
    @Published var beginLoading = false
    
    @Published var items: [String] = {
        var result: [String] = []
        for i in 0 ..< 20 {
            result.append("\(i + 1)")
        }
        return result
    }()
    
    func addItems() -> Bool {
        var newItems = items
        for i in 0 ..< 5 {
            newItems.append("\(items.count + i + 1)")
        }
        items = newItems
        return items.count < 30
    }
    
}

#endif
