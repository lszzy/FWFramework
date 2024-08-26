//
//  TestSwiftUIListController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/24.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

#if canImport(SwiftUI)
import Combine
import FWFramework
import SwiftUI

class TestSwiftUIListController: UIViewController, ViewControllerProtocol {
    var style: Int = 0

    private lazy var contentView: TestSwiftUIListContent = {
        let result = TestSwiftUIListContent()
        result.viewModel.style = style
        return result
    }()

    func setupNavbar() {
        app.setRightBarItem(UIBarButtonItem.SystemItem.action.rawValue) { [weak self] _ in
            self?.app.showSheet(title: nil, message: nil, actions: ["automatic", "plain", "grouped", "sidebar (14+)", "insetGrouped (14+)", "inset (14+)", "beginRefreshing", "beginLoading"], actionBlock: { index in
                if index < 6 {
                    let vc = TestSwiftUIListController()
                    vc.style = index
                    Navigator.push(vc, pop: 1, animated: false)
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
                    .removable(viewModel.items.isEmpty)
            } footer: {
                Text("Footer")
                    .padding(.leading, 16)
                    .resetHeaderStyle(background: Color(AppTheme.cellColor))
                    .removable(viewModel.items.isEmpty)
            }
        }
        .then { list in
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
        }
        .resetListStyle(background: Color(AppTheme.tableColor), isPlainStyle: viewModel.style == 1)
        .listViewRefreshing(
            shouldBegin: $viewModel.beginRefreshing,
            action: { completionHandler in
                viewModel.refreshData(completionHandler: completionHandler)
            }
        )
        .listViewLoading(
            shouldBegin: $viewModel.beginLoading,
            action: { completionHandler in
                viewModel.loadData(completionHandler: completionHandler)
            }
        )
        .showListEmpty(viewModel.showsEmpty) { scrollView in
            scrollView.app.showEmptyView(text: viewModel.error?.localizedDescription) { _ in
                viewModel.beginRefreshing = true
            }
        }
        .onAppear {
            DispatchQueue.main.async {
                viewModel.beginRefreshing = true
            }
        }
    }
}

class TestSwiftUIListModel: ViewModel, @unchecked Sendable {
    var style: Int = 0
    var error: Error? {
        didSet {
            showsEmpty = error != nil
        }
    }

    @Published var beginRefreshing = false
    @Published var beginLoading = false
    @Published var showsEmpty = false

    @Published var items: [String] = []

    func refreshData(completionHandler: @escaping @MainActor @Sendable (Bool?) -> Void) {
        error = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self else { return }

            let isSuccess = Bool.random()
            if isSuccess {
                var newItems: [String] = []
                for i in 0..<5 {
                    newItems.append("\(i + 1)")
                }

                items = newItems
                completionHandler(items.count >= 30)
            } else {
                error = NSError(domain: "Test", code: 0, userInfo: [NSLocalizedDescriptionKey: "请求失败"])
                items = []
                completionHandler(true)
            }
        }
    }

    func loadData(completionHandler: @escaping @MainActor @Sendable (Bool?) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self else { return }

            var newItems = items
            for i in 0..<5 {
                newItems.append("\(items.count + i + 1)")
            }
            items = newItems
            completionHandler(items.count >= 30)
        }
    }
}

#endif
