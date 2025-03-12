//
//  TestSwiftUIController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/24.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

#if canImport(SwiftUI)
import Combine
import FWFramework
import SwiftUI

class TestSwiftUIController: UIViewController, ViewControllerProtocol {
    func setupSubviews() {
        app.navigationBarHidden = Bool.random()

        let hostingView = TestSwiftUIContent()
            .viewContext(self, userInfo: [
                "color": Color.green
            ])
            .navigationBarConfigure(
                leading: Icon.backImage,
                title: "TestSwiftUIViewController",
                background: UIColor.app.randomColor
            )
            .wrappedHostingView()
        view.addSubview(hostingView)
        hostingView.app.layoutChain
            .horizontal()
            .top(toSafeArea: .zero)
            .bottom()
    }
}

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
                        let success = Bool.random()
                        if success {
                            view.state = .success()
                        } else {
                            view.state = .failure(NSError(domain: "Test", code: 0, userInfo: [NSLocalizedDescriptionKey: "出错啦!"]))
                        }
                    }
                }
        } content: { _, _ in
            TestSwiftUIContent()
        } failure: { view, error in
            Button(error?.localizedDescription ?? "") {
                view.state = .loading
            }
        }
    }

    // MARK: - Lifecycle
    override func didInitialize() {
        hidesBottomBarWhenPushed = true
        extendedLayoutIncludesOpaqueBars = true
        navigationItem.hidesBackButton = true
        if mode != 2 {
            app.navigationBarHidden = Bool.random()
        }
    }

    override func setupSubviews() {
        rootView = stateView
            .viewContext(self)
            .then(mode == 2, body: { view in
                view.navigationBarBackButtonHidden(true)
                    .navigationBarHidden(Bool.random())
            })
            .navigationBarConfigure(
                leading: Button(action: {
                    Navigator.close(animated: true)
                }, label: {
                    HStack {
                        Spacer()
                        Image(uiImage: Icon.backImage?.app.image(tintColor: AppTheme.textColor) ?? UIImage())
                        Spacer()
                    }
                }),
                title: Text("SwiftUIViewController - \(mode)"),
                background: Color(UIColor.app.randomColor)
            )
            .eraseToAnyView()
    }
}

class TestSwiftUIModel: ObservableViewModel {
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

struct TestSwiftUIContent: View {
    @Environment(\.viewContext) var viewContext: ViewContext

    @ObservedObject var viewModel: TestSwiftUIModel = .init()

    @State var topSize: CGSize = .zero
    @State var contentOffset: CGPoint = .zero
    @State var shouldRefresh: Bool = false
    @State var attributedColor = UIColor.app.randomColor
    @State var attributedChanged: Bool = false

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
            ScrollView {
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

                        Text {
                            Text("width: \(Int(topSize.width))")
                                .concatenate {
                                    Text(" ")
                                }

                            Text("height: \(Int(topSize.height))")
                        }
                        .hostingViewInitialize { hostingView in
                            hostingView.backgroundColor = UIColor.app.randomColor
                        }

                        AttributedText(NSMutableAttributedString {
                            "我是富文本，"

                            NSAttributedString(string: "点击我可以变色，", attributes: [
                                .foregroundColor: attributedColor,
                                .init("URL"): 1
                            ])

                            if attributedChanged {
                                "我是动态内容，"
                            }

                            NSAttributedString(string: "点击我切换动态内容，", attributes: [
                                .foregroundColor: UIColor.blue,
                                .init("URL"): 2
                            ])

                            "我可以跳转"

                            NSAttributedString(string: "https://www.baidu.com", attributes: [
                                .foregroundColor: UIColor.blue,
                                .link: APP.safeURL("https://www.baidu.com")
                            ])
                        }) { link in
                            if let url = link as? URL {
                                Router.openURL(url)
                            } else if let value = link as? Int {
                                if value == 1 {
                                    attributedColor = UIColor.app.randomColor
                                } else if value == 2 {
                                    attributedChanged.toggle()
                                }
                            }
                        }
                        .font(APP.font(16))
                        .foregroundColor(Color.black)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 16)
                    .captureSize(in: $topSize)

                    Toggle(isOn: $buttonRemovable) {
                        EmptyView()
                    }
                    .toggleStyle(TestSwiftUIToggleStyle())

                    HStack(alignment: .center, spacing: 16) {
                        HStack {
                            Spacer()
                            Text("Close")
                            Spacer()
                        }
                        .wrappedButton {
                            viewContext.viewController?.app.close()
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .frame(width: (APP.screenWidth - 64) / 3, height: 40)
                        .border(Color.gray, width: Divider.defaultSize, cornerRadius: 20)

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
                        .frame(width: (APP.screenWidth - 64) / 3, height: 40)
                        .border(Color.gray, width: Divider.defaultSize, cornerRadius: 20)
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
                        .frame(width: (APP.screenWidth - 64) / 3, height: 40)
                        .border(Color.gray, width: Divider.defaultSize, cornerRadius: 20)
                        .visible(buttonVisible)
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }

                Button {
                    let vc = TestSwiftUIListController()
                    Navigator.open(vc)

                    viewContext.object = "Object"
                    viewContext.userInfo = ["color": Color(UIColor.app.randomColor)]
                    viewContext.send()
                } label: {
                    ViewWrapper {
                        Text("Open List")
                            .wrappedHostingView()
                    }
                    .frame(height: 44)
                    .background(viewContext.userInfo?["color"] as? Color ?? .yellow)
                }

                Button("Push SwiftUI") {
                    let viewController = TestSwiftUIController()
                    Navigator.topNavigationController?.pushViewController(viewController, animated: true)
                }
                .frame(height: 44)

                Button("Push HostingController") {
                    let viewController = TestSwiftUIHostingController()
                    viewContext.viewController?.app.open(viewController)
                }
                .frame(height: 44)

                Button("Present HostingController") {
                    let viewController = TestSwiftUIHostingController()
                    viewContext.viewController?.present(viewController, animated: true)
                }
                .frame(height: 44)

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
                    .frame(height: 44)
                }

                Button("Show Loading") {
                    showingLoading = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showingLoading = false
                    }
                }
                .frame(height: 44)

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
                .frame(height: 44)

                Button(viewModel.isEnglish ? "Language" : "多语言") {
                    viewModel.isEnglish = !viewModel.isEnglish
                }
                .frame(height: 44)

                ForEach(moreItems, id: \.self) { title in
                    Button {
                        Router.openURL(title)
                    } label: {
                        Text(title)
                    }
                    .frame(height: 44)
                }
            }
            .captureContentOffset(in: $contentOffset)
            .scrollViewRefreshing(action: { completionHandler in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    moreItems = []
                    completionHandler(false)
                }
            })
            .scrollViewLoading(action: { completionHandler in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    var newItems = moreItems
                    newItems.append("http://www.baidu.com")
                    moreItems = newItems
                    completionHandler(moreItems.count >= 5)
                }
            })
        }
        .hoverContentOffset(visible: contentOffset.y >= 44) {
            Text("Hover Header")
                .frame(width: APP.screenWidth, height: 44)
                .background(Color.white)
                .shadow(color: Color.color(0x000000, 0.1), radius: 5, x: 0, y: 2)
        }
        .removable(showingEmpty)
        .showAlert($showingAlert) { viewController in
            viewController.app.showAlert(title: "我是标题", message: "我是内容")
        }
        .showToast($showingToast, customize: { viewController in
            viewController.app.showMessage(text: "我是提示信息我是提示信息我是提示信息我是提示信息我是提示信息我是提示信息我是提示信息")
        })
        .showEmpty(showingEmpty, customize: { viewController in
            viewController.app.showEmptyView(text: "我是标题", detail: "我是详细信息我是提示信息我是提示信息我是提示信息我是提示信息我是提示信息我是提示信息", image: UIImage.app.appIconImage(), action: "刷新") { _ in
                showingEmpty = false
            }
        })
        .showLoading(showingLoading)
        .showProgress(showingProgress, customize: { viewController in
            viewController.app.showProgress(progressValue, text: "上传中(\(Int(progressValue * 100))%)")
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

struct TestSwiftUIToggleStyle: ToggleStyle {
    func makeBody(configuration: ToggleStyleConfiguration) -> some View {
        HStack {
            configuration.label

            RoundedRectangle(cornerRadius: 25.5)
                .frame(width: 51, height: 31, alignment: .center)
                .overlay(
                    Circle()
                        .foregroundColor(Color(.systemBackground))
                        .padding(3)
                        .offset(x: configuration.isOn ? 10 : -10, y: 0)
                        .animation(.linear(duration: 0.2))
                )
                .foregroundColor(Color(.label))
                .onTapGesture(perform: {
                    configuration.isOn.toggle()
                })
        }
    }
}

#endif
