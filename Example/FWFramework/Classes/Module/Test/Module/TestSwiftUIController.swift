//
//  TestSwiftUIController.swift
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
class TestSwiftUIController: UIViewController, ViewControllerProtocol {
    
    func setupSubviews() {
        fw.navigationBarHidden = [true, false].randomElement()!
        
        let hostingView = TestSwiftUIContent()
            .viewContext(self, userInfo: [
                "color": Color.green
            ])
            .navigationBarConfigure(
                leading: Icon.backImage,
                title: "TestSwiftUIViewController",
                background: UIColor.fw.randomColor
            )
            .wrappedHostingView()
        view.addSubview(hostingView)
        hostingView.fw.layoutChain
            .horizontal()
            .top(toSafeArea: .zero)
            .bottom()
    }
    
}

@available(iOS 13.0, *)
class TestSwiftUIHostingController: HostingController, ViewControllerProtocol {
    
    // MARK: - Accessor
    var mode: Int = [0, 1, 2].randomElement()!
    
    var error: String?
    
    // MARK: - Subviews
    var stateView: some View {
        StateView { view in
            LoadingPluginView()
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        let success = [true, false].randomElement()!
                        if success {
                            view.state = .success()
                        } else {
                            view.state = .failure(NSError(domain: "Test", code: 0, userInfo: [NSLocalizedDescriptionKey: "出错啦!"]))
                        }
                    }
                }
        } content: { view, _ in
            TestSwiftUIContent()
        } failure: { view, error in
            Button(error?.localizedDescription ?? "") {
                view.state = .loading
            }
        }
    }
    
    // MARK: - Lifecycle
    override func setupNavbar() {
        hidesBottomBarWhenPushed = true
        extendedLayoutIncludesOpaqueBars = true
        navigationItem.hidesBackButton = true
        if mode != 2 {
            fw.navigationBarHidden = [true, false].randomElement()!
        }
    }
    
    override func setupSubviews() {
        rootView = stateView
            .viewContext(self)
            .then(mode == 2, body: { view in
                view.navigationBarBackButtonHidden(true)
                    .navigationBarHidden([true, false].randomElement()!)
            })
            .navigationBarConfigure(
                leading: Button(action: {
                    Navigator.closeViewController(animated: true)
                }, label: {
                    HStack {
                        Spacer()
                        Image(uiImage: Icon.backImage?.fw.image(tintColor: AppTheme.textColor) ?? UIImage())
                        Spacer()
                    }
                }),
                title: Text("SwiftUIViewController - \(mode)"),
                background: Color(UIColor.fw.randomColor)
            )
            .eraseToAnyView()
    }
    
}

@available(iOS 13.0, *)
class TestSwiftUIModel: ViewModel {
    // View中可通过$viewModel.isEnglish获取Binding<Bool>
    @Published var isEnglish: Bool = true
    
    @Published var items: [String] = []
    
    // 数据改变时调用editSubject.send(self)通知视图刷新
    var editPublisher: AnyPublisher<String, Never> { editSubject.eraseToAnyPublisher() }
    private let editSubject = PassthroughSubject<String, Never>()
    
    init(isEnglish: Bool = true) {
        self.isEnglish = isEnglish
    }
    
    func reloadData() {
        // 请求数据，并修改items，通知View刷新
    }
}



@available(iOS 13.0, *)
struct TestSwiftUIContent: View {
    
    @Environment(\.viewContext) var viewContext: ViewContext
    
    @ObservedObject var viewModel: TestSwiftUIModel = TestSwiftUIModel()
    
    @State var topSize: CGSize = .zero
    @State var contentOffset: CGPoint = .zero
    @State var shouldRefresh: Bool = false
    
    @State var moreItems: [String] = []
    
    @State var buttonRemovable: Bool = false
    @State var buttonVisible: Bool = true
    
    @State var showingAlert: Bool = false
    @State var showingToast: Bool = false
    @State var showingEmpty: Bool = false
    @State var showingLoading: Bool = false
    @State var showingProgress: Bool = false
    @State var progressValue: CGFloat = 0
    
    var body: some View {
        GeometryReader { proxy in
            List {
                VStack(alignment: .center, spacing: 16) {
                    ZStack {
                        InvisibleView()
                            .captureContentOffset(proxy: proxy)
                        
                        Text("contentOffset: \(Int(contentOffset.y))")
                    }
                    
                    VStack {
                        HStack(alignment: .center, spacing: 50) {
                            ImageView(url: "https://ww4.sinaimg.cn/bmiddle/eaeb7349jw1ewbhiu69i2g20b4069e86.gif")
                                .contentMode(.scaleAspectFill)
                                .clipped()
                                .cornerRadius(50)
                                .frame(width: 100, height: 100)
                            
                            WebImageView("http://kvm.wuyong.site/images/images/animation.png")
                                .resizable()
                                .clipped()
                                .frame(width: 100, height: 100)
                        }
                        
                        Text("width: \(Int(topSize.width)) height: \(Int(topSize.height))")
                    }
                    .padding(.top, 16)
                    .captureSize(in: $topSize)
                    
                    HStack(alignment: .center, spacing: 16) {
                        Button {
                            viewContext.viewController?.fw.close()
                        } label: {
                            HStack {
                                Spacer()
                                Text("Close")
                                Spacer()
                            }
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .frame(width: (FW.screenWidth - 64) / 3, height: 40)
                        .border(Color.gray, cornerRadius: 20)
                        
                        Button {
                            buttonVisible.toggle()
                        } label: {
                            HStack {
                                Spacer()
                                Text("Visible")
                                Spacer()
                            }
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .frame(width: (FW.screenWidth - 64) / 3, height: 40)
                        .border(Color.gray, cornerRadius: 20)
                        .removable(buttonRemovable)
                        
                        Button {
                            buttonRemovable.toggle()
                        } label: {
                            HStack {
                                Spacer()
                                Text("Removable")
                                Spacer()
                            }
                        }
                        .frame(width: (FW.screenWidth - 64) / 3, height: 40)
                        .border(Color.gray, cornerRadius: 20)
                        .visible(buttonVisible)
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }
                
                Button {
                    Router.openURL("https://www.baidu.com")
                    
                    viewContext.object = "Object"
                    viewContext.userInfo = ["color": Color(UIColor.fw.randomColor)]
                    viewContext.send()
                } label: {
                    ViewWrapper {
                        Text("Open Router")
                            .wrappedHostingView()
                    }
                    .frame(height: 44)
                    .background(viewContext.userInfo?["color"] as? Color ?? .yellow)
                }
                
                Button("Push SwiftUI") {
                    let viewController = TestSwiftUIController()
                    Navigator.topNavigationController?.pushViewController(viewController, animated: true)
                }
                
                Button("Push HostingController") {
                    let viewController = TestSwiftUIHostingController()
                    viewContext.viewController?.fw.open(viewController)
                }
                
                Button("Present HostingController") {
                    let viewController = TestSwiftUIHostingController()
                    viewContext.viewController?.present(viewController, animated: true)
                }
                
                ForEach(["Show Alert", "Show Toast", "Show Empty"], id: \.self) { title in
                    Button(title) {
                        if title == "Show Alert" {
                            showingAlert = true
                        } else if title == "Show Toast" {
                            showingToast = true
                        } else {
                            showingEmpty = true
                        }
                    }
                }
                
                Button("Show Loading") {
                    showingLoading = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showingLoading = false
                    }
                }
                
                Button("Show Progress") {
                    showingProgress = true
                    TestController.mockProgress { progress, finished in
                        if finished {
                            showingProgress = false
                        } else {
                            progressValue = progress
                        }
                    }
                }
                
                Button(viewModel.isEnglish ? "Language" : "多语言") {
                    viewModel.isEnglish = !viewModel.isEnglish
                }
                
                ForEach(moreItems, id: \.self) { title in
                    Button {
                        Router.openURL(title)
                    } label: {
                        Text(title)
                    }
                }
            }
            .listStyle(.plain)
            .captureContentOffset(in: $contentOffset)
            .introspectTableView { tableView in
                if tableView.fw.tempObject != nil { return }
                tableView.fw.tempObject = true
                
                tableView.fw.resetGroupedStyle()
                
                tableView.fw.setRefreshing {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        tableView.fw.endRefreshing()
                        moreItems = []
                    }
                }
                
                tableView.fw.setLoading {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        tableView.fw.endLoading()
                        tableView.fw.shouldLoading = moreItems.count < 5
                        var newItems = moreItems
                        newItems.append("http://www.baidu.com")
                        moreItems = newItems
                    }
                }
            }
        }
        .removable(showingEmpty)
        .showAlert($showingAlert) { viewController in
            viewController.fw.showAlert(title: "我是标题", message: "我是内容")
        }
        .showToast($showingToast, customize: { viewController in
            viewController.fw.showMessage(text: "我是提示信息我是提示信息我是提示信息我是提示信息我是提示信息我是提示信息我是提示信息")
        })
        .showEmptyView(showingEmpty, builder: {
            EmptyPluginView()
                .text("我是标题")
                .detail("我是详细信息我是提示信息我是提示信息我是提示信息我是提示信息我是提示信息我是提示信息")
                .image(UIImage.fw.appIconImage())
                .action("刷新") { _ in
                    showingEmpty = false
                }
        })
        .showLoadingView(showingLoading, builder: {
            LoadingPluginView()
                .onCancel {
                    showingLoading = false
                }
        })
        .showProgressView(showingProgress, builder: {
            ProgressPluginView(progressValue)
                .text("上传中(\(Int(progressValue * 100))%)")
        })
        .transformViewContext(transform: { viewContext in
            DispatchQueue.main.async {
                print("viewController: \(String(describing: viewContext.viewController))")
                print("hostingView: \(String(describing: viewContext.hostingView))")
                print("rootView: \(String(describing: viewContext.rootView))")
            }
        })
        .onReceive(viewContext.subject) { context in
            print("userInfo: \(String(describing: context.userInfo))")
            shouldRefresh = !shouldRefresh
        }
        .onReceive(viewContext.$object) { object in
            print("object: \(String(describing: object))")
        }
    }
    
}

#endif