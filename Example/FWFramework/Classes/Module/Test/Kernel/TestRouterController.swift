//
//  TestRouterController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/5.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestRouterController: UIViewController, TableViewControllerProtocol, UISearchResultsUpdating {
    
    typealias TableElement = [String]
    
    static var popCount: Int = 0
    
    @StoredValue("routerStrictMode")
    static var routerStrictMode: Bool = false
    
    var testData: [TableElement] = [
        ["打开Web", "onOpenHttp"],
        ["打开完整Web", "onOpenHttp2"],
        ["打开异常Web", "onOpenHttp3"],
        ["打开重定向Web", "onOpenHttp4"],
        ["打开预缓存Web，需开启重用", "onOpenPreload"],
        ["测试Cookie", "onOpenCookie"],
        ["Url编码", "onOpenEncode"],
        ["Url未编码", "onOpenImage"],
        ["不规范Url", "onOpenSlash"],
        ["打开App", "onOpenApp"],
        ["打开Url", "onOpen"],
        ["中文Url", "onOpenChinese"],
        ["打开Url，通配符*", "onOpenWild"],
        ["打开Url，*id", "onOpenPage"],
        ["打开Url，:id", "onOpenShop"],
        ["打开Url，:id/:id", "onOpenItem"],
        ["打开Url，:id.html", "onOpenHtml"],
        ["打开Url，支持回调", "onOpenCallback"],
        ["解析Url，获取Object", "onOpenObject"],
        ["过滤Url", "onOpenFilter"],
        ["不支持的Url", "onOpenFailed"],
        ["RewriteUrl", "onRewrite1"],
        ["RewriteUrl URLEncode", "onRewrite2"],
        ["RewriteUrl URLDecode", "onRewrite3"],
        ["RewriteFilter", "onRewriteFilter"],
        ["不匹配的openUrl", "onOpenUnmatch"],
        ["不匹配的objectUrl", "onOpenUnmatch2"],
        ["打开objectUrl", "onOpenUnmatch3"],
        ["路由Parameter", "onOpenParameter"],
        ["自定义Handler", "onOpenHandler"],
        ["自动注册的Url", "onOpenLoader"],
        ["打电话", "onOpenTel"],
        ["跳转设置", "onOpenSettings"],
        ["跳转首页", "onOpenHome"],
        ["跳转home/undefined", "onOpenHome2"],
        ["不支持tab", "onOpenHome3"],
        ["关闭close", "onOpenClose"],
        ["通用链接douyin", "onOpenUniversalLinks"],
        ["外部safari", "onOpenUrl"],
        ["内部safari", "onOpenSafari"],
        ["打开两个界面", "onOpenMulti"],
        ["界面完成回调", "onOpenResult"],
        ["iOS14bug", "onOpen14"],
    ]
    
    private lazy var searchController: UISearchController = {
        let result = UISearchController(searchResultsController: nil)
        result.searchResultsUpdater = self
        result.obscuresBackgroundDuringPresentation = false
        definesPresentationContext = true
        
        let searchBar = result.searchBar
        searchBar.placeholder = "Search"
        searchBar.barTintColor = AppTheme.barColor
        searchBar.app.backgroundColor = AppTheme.barColor
        searchBar.app.textFieldBackgroundColor = AppTheme.tableColor
        searchBar.app.searchIconOffset = 10
        searchBar.app.searchTextOffset = 4
        searchBar.app.clearIconOffset = -6
        searchBar.app.font = APP.font(12)
        searchBar.app.textField.app.setCornerRadius(18)
        return result
    }()
    
    func updateSearchResults(for searchController: UISearchController) {
        let searchText = searchController.searchBar.text?.app.trimString ?? ""
        if searchText.isEmpty {
            tableData = testData
            tableView.reloadData()
            return
        }
        
        var resultData: [TableElement] = []
        for rowData in testData {
            if APP.safeString(rowData[0]).lowercased()
                .contains(searchText.lowercased()) {
                resultData.append(rowData)
            }
        }
        tableData = resultData
        tableView.reloadData()
    }
    
    func setupTableStyle() -> UITableView.Style {
        .grouped
    }
    
    func setupTableView() {
        tableView.tableHeaderView = searchController.searchBar
    }
    
    func setupTableLayout() {
        tableView.chain.edges()
    }
    
    func setupNavbar() {
        navigationItem.title = "Router"
        app.setRightBarItem(UIBarButtonItem.SystemItem.action.rawValue) { [weak self] _ in
            self?.app.showSheet(title: nil, message: nil, actions: [TestRouterController.routerStrictMode ? "关闭严格模式" : "开启严格模式"], actionBlock: { _ in
                TestRouterController.routerStrictMode = !TestRouterController.routerStrictMode
                Router.strictMode = TestRouterController.routerStrictMode
            })
        }
        
        var url = "http://test.com?id=我是中文"
        APP.debug("urlEncode: %@", String(describing: url.app.urlEncode))
        APP.debug("urlDecode: %@", String(describing: url.app.urlEncode?.app.urlDecode))
        APP.debug("urlEncodeComponent: %@", String(describing: url.app.urlEncodeComponent))
        APP.debug("urlDecodeComponent: %@", String(describing: url.app.urlEncodeComponent?.app.urlDecodeComponent))
        
        url = "app://tests/1?value=2&name=name2&title=我是字符串100%&url=https%3A%2F%2Fkvm.wuyong.site%2Ftest.php%3Fvalue%3D1%26name%3Dname1%23%2Fhome1#/home2"
        APP.debug("string.queryDecode: %@", String(describing: url.app.queryDecode))
        APP.debug("string.queryEncode: %@", String(describing: String.app.queryEncode(url.app.queryDecode)))
        let nsurl = URL.app.url(string: url)
        APP.debug("query.queryDecode: %@", String(describing: nsurl?.query?.app.queryDecode))
        APP.debug("url.queryParameters: %@", String(describing: nsurl?.app.queryParameters))
    }
    
    func setupSubviews() {
        let str = "http://test.com?id=我是中文"
        var url = URL(string: str)
        APP.debug("str: %@ =>\nurl: %@", str, String(describing: url))
        url = URL.app.url(string: str)
        APP.debug("str: %@ =>\nurl: %@", str, String(describing: url))
        
        var urlStr = Router.generateURL(TestRouter.testUrl, parameters: nil)
        APP.debug("url: %@", urlStr)
        urlStr = Router.generateURL(TestRouter.testUrl, parameters: [1])
        APP.debug("url: %@", urlStr)
        urlStr = Router.generateURL(TestRouter.testUrl, parameters: ["id": 2])
        APP.debug("url: %@", urlStr)
        urlStr = Router.generateURL(TestRouter.testUrl, parameters: 3)
        APP.debug("url: %@", urlStr)
        
        tableData.append(contentsOf: testData)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.app.cell(tableView: tableView)
        let rowData = tableData[indexPath.row]
        cell.textLabel?.text = rowData[0]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let rowData = tableData[indexPath.row]
        _ = self.perform(NSSelectorFromString(rowData[1]))
    }
    
}

@objc extension TestRouterController {
    
    func onOpenApp() {
        Router.openURL("app://")
    }
    
    func onOpen() {
        Router.openURL("app://tests/1#anchor")
    }
    
    func onOpenChinese() {
        Router.openURL("app://tests/%E4%B8%AD%E6%96%87?value=1#anchor")
    }
    
    func onOpenEncode() {
        Router.openURL("app://tests/1?value=2&name=name2&url=https%3A%2F%2Fkvm.wuyong.site%2Ftest.php%3Fvalue%3D1%26name%3Dname1%23%2Fhome1#/home2")
    }
    
    func onOpenImage() {
        Router.openURL("app://tests/1?url=https://kvm.wuyong.site/test.php")
    }
    
    func onOpenSlash() {
        Router.openURL("app:tests/1#anchor")
    }
    
    func onOpenWild() {
        Router.openURL(Router.generateURL(TestRouter.wildcardUrl, parameters: "not_found?id=1#anchor"))
    }
    
    func onOpenPage() {
        Router.openURL(Router.generateURL(TestRouter.pageUrl, parameters: ["id": "test/1"]))
    }
    
    func onOpenShop() {
        Router.openURL(Router.generateURL(TestRouter.shopUrl, parameters: 1))
    }
    
    func onOpenItem() {
        Router.openURL(Router.generateURL(TestRouter.itemUrl, parameters: [1, 2]))
    }
    
    func onOpenHtml() {
        Router.openURL(Router.generateURL(TestRouter.htmlUrl, parameters: ["id": 1]))
    }
    
    func onOpenCallback() {
        Router.openURL("\(TestRouter.wildcardTestUrl)?id=2") { result in
            UIWindow.app.showMessage(text: result as? String)
        }
    }
    
    func onOpenObject() {
        let vc = Router.object(forURL: TestRouter.objectUrl) as! TestRouterResultController
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }
    
    func onOpenFailed() {
        Router.openURL("app://tests?FWRouterBlock=1")
    }
    
    func onRewrite1() {
        Router.openURL("https://www.baidu.com/tests/66666")
    }
    
    func onRewrite2() {
        Router.openURL("https://www.baidu.com/wildcard/字符串?title=我是字符串100%")
    }
    
    func onRewrite3() {
        Router.openURL("https://www.baidu.com/wildcard2/%E5%8E%9F%E5%AD%90%E5%BC%B9")
    }
    
    func onOpenUnmatch() {
        Router.openURL(TestRouter.objectUnmatchUrl)
    }
    
    func onOpenUnmatch2() {
        _ = Router.object(forURL: TestRouter.objectUnmatchUrl)
    }
    
    func onOpenUnmatch3() {
        Router.openURL(TestRouter.objectUrl)
    }
    
    func onOpenParameter() {
        let parameter = Router.Parameter()
        parameter.routerOptions = [.embedInNavigation, .styleFullScreen]
        
        Router.openURL("http://www.wuyong.site/", userInfo: parameter.dictionaryValue)
    }
    
    func onOpenHandler() {
        let parameter = Router.Parameter()
        parameter.routerHandler = { context, vc in
            let nav = UINavigationController(rootViewController: vc)
            Navigator.present(nav)
        }
        
        Router.openURL("http://www.wuyong.site/", userInfo: parameter.dictionaryValue)
    }
    
    func onOpenLoader() {
        Router.openURL(TestRouter.loaderUrl)
    }
    
    func onOpenFilter() {
        Router.openURL("app://filter/1")
    }
    
    func onRewriteFilter() {
        Router.openURL("https://www.baidu.com/filter/1")
    }
    
    func onOpenTel() {
        Router.openURL("tel:10000")
    }
    
    func onOpenSettings() {
        Router.openURL(UIApplication.openSettingsURLString)
    }
    
    func onOpenHome() {
        Router.openURL(TestRouter.homeUrl)
    }
    
    func onOpenHome2() {
        Router.openURL("app://tab/home/undefined")
    }
    
    func onOpenHome3() {
        Router.openURL("app://tab")
    }
    
    func onOpenClose() {
        Router.openURL(TestRouter.closeUrl)
    }
    
    func onOpenHttp() {
        Router.openURL("http://kvm.wuyong.site/test.php#anchor")
    }
    
    func onOpenHttp2() {
        Router.openURL("https://www.baidu.com/?param=value#anchor")
    }
    
    func onOpenHttp3() {
        Router.openURL("http://username:password@localhost:8000/test:8001/directory%202/index.html?param=value#anchor")
    }
    
    func onOpenHttp4() {
        Router.openURL("http://www.wuyong.site/redirect.php?param=value#anchor")
    }
    
    func onOpenPreload() {
        Router.openURL("https://www.wuyong.site/#slide=1")
    }
    
    func onOpenCookie() {
        Router.openURL("http://kvm.wuyong.site/cookie.php?param=value#anchor")
    }
    
    func onOpenUniversalLinks() {
        let url = "https://v.douyin.com/JYmHJ9k/"
        UIApplication.app.openUniversalLinks(url) { success in
            if !success {
                Router.openURL(url)
            }
        }
    }
    
    func onOpenUrl() {
        UIApplication.app.openURL("http://kvm.wuyong.site/test.php")
    }
    
    func onOpenSafari() {
        UIApplication.app.openSafariController("http://kvm.wuyong.site/test.php") {
            APP.debug("SafariController completionHandler")
        }
    }
    
    func onOpenMulti() {
        Router.openURL(TestRouter.multiUrl)
    }
    
    func onOpenResult() {
        let vc = UIViewController()
        vc.title = "弹出框"
        vc.view.backgroundColor = AppTheme.backgroundColor
        vc.app.completionHandler = { [weak self] result in
            let result = result != nil ? APP.safeString(result) : "deinit"
            self?.app.showMessage(text: "完成回调：\(result)")
        }
        vc.app.setLeftBarItem("关闭") { [weak vc] _ in
            vc?.app.completionResult = "点击关闭"
            vc?.dismiss(animated: true)
        }
        vc.app.setRightBarItem("完成") { [weak vc] _ in
            vc?.app.completionResult = "点击完成"
            vc?.dismiss(animated: true)
        }
        
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }
    
    func onOpen14() {
        let vc = TestRouterResultController()
        vc.navigationItem.title = "iOS14 bug"
        vc.context = Router.Context(url: "http://kvm.wuyong.site/test.php?key=value")
        vc.app.shouldPopController = { [weak self] in
            TestRouterController.popCount += 1
            let index = TestRouterController.popCount % 3
            if index == 0 {
                self?.navigationController?.popToRootViewController(animated: true)
            } else if index == 1 {
                if let first = self?.navigationController?.viewControllers.first {
                    self?.navigationController?.popToViewController(first, animated: true)
                }
            } else {
                if let first = self?.navigationController?.viewControllers.first {
                    self?.navigationController?.setViewControllers([first], animated: true)
                }
            }
            return false
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
}

@objc extension Autoloader {
    @MainActor func loadApp_TestRouter() {
        APP.autoload(TestRouter.self)
        Router.strictMode = TestRouterController.routerStrictMode
    }
}

class TestRouter: NSObject {
    
    @objc static let testUrl = "app://tests/:id"
    @objc static let homeUrl = "app://tab/home"
    @objc static let wildcardUrl = "wildcard://*"
    @objc static let wildcardTestUrl = "wildcard://test1"
    @objc static let objectUrl = "object://test2"
    @objc static let objectUnmatchUrl = "object://test"
    @objc static let loaderUrl = "app://loader"
    @objc static let pageUrl = "app://page/*id"
    @objc static let shopUrl = "app://shops/:id"
    @objc static let itemUrl = "app://shops/:id/items/:itemId"
    @objc static let htmlUrl = "app://pages/:id.html"
    @objc static let javascriptUrl = "app://javascript"
    @objc static let closeUrl = "app://close"
    @objc static let multiUrl = "app://multi"
    
    @MainActor @objc static func testRouter(_ context: Router.Context) -> Any? {
        let vc = TestRouterResultController()
        vc.rule = testUrl
        vc.context = context
        Navigator.push(vc, animated: true)
        return nil
    }
    
    @MainActor @objc static func homeRouter(_ context: Router.Context) -> Any? {
        UIWindow.app.main?.app.selectTabBarController(index: 0)
        return nil
    }
    
    @MainActor @objc static func wildcardTestRouter(_ context: Router.Context) -> Any? {
        let vc = TestRouterResultController()
        vc.rule = wildcardTestUrl
        vc.context = context
        Navigator.push(vc, animated: true)
        return nil
    }
    
    @MainActor @objc static func pageRouter(_ context: Router.Context) -> Any? {
        let vc = TestRouterResultController()
        vc.rule = pageUrl
        vc.context = context
        Navigator.push(vc, animated: true)
        return nil
    }
    
    @MainActor @objc static func shopRouter(_ context: Router.Context) -> Any? {
        let vc = TestRouterResultController()
        vc.rule = shopUrl
        vc.context = context
        Navigator.push(vc, animated: true)
        return nil
    }
    
    @MainActor @objc static func itemRouter(_ context: Router.Context) -> Any? {
        let vc = TestRouterResultController()
        vc.rule = itemUrl
        vc.context = context
        Navigator.push(vc, animated: true)
        return nil
    }
    
    @MainActor @objc static func htmlRouter(_ context: Router.Context) -> Any? {
        let vc = TestRouterResultController()
        vc.rule = htmlUrl
        vc.context = context
        Navigator.push(vc, animated: true)
        return nil
    }
    
    @MainActor @objc static func objectRouter(_ context: Router.Context) -> Any? {
        let vc = TestRouterResultController()
        vc.rule = objectUrl
        vc.context = context
        return vc
    }
    
    @MainActor @objc static func objectUnmatchRouter(_ context: Router.Context) -> Any? {
        if context.isOpening {
            return "OBJECT UNMATCH"
        } else {
            Navigator.topPresentedController?.app.showAlert(title: "url not supported\nurl: \(context.url)\nparameters: \(context.parameters)", message: nil)
            return nil
        }
    }
    
    @MainActor @objc static func javascriptRouter(_ context: Router.Context) -> Any? {
        guard let webVC = Navigator.topViewController as? WebController,
              webVC.isViewLoaded else { return nil }
        
        let param = context.parameters["param"].safeString
        let result = "js:\(param) => app:2"
        let callback = context.parameters["callback"].safeString
        let javascript = "\(callback)('\(result)');"
        
        webVC.webView.evaluateJavaScript(javascript) { value, error in
            Navigator.topViewController?.app.showAlert(title: "App", message: "app:2 => js:\(String(describing: value))")
        }
        return nil
    }
    
    @MainActor @objc static func closeDefaultRouter(_ context: Router.Context) -> Any? {
        guard let topVC = Navigator.topViewController else { return nil }
        topVC.app.close()
        return nil
    }
    
    @MainActor @objc static func multiRouter(_ context: Router.Context) -> Any? {
        guard context.isOpening else { return nil }
        guard let nav = Navigator.topNavigationController else { return nil }
        
        let vc = TestRouterResultController()
        vc.showLoading = true
        vc.rule = context.url + "?page=1"
        vc.context = context
        
        let vc2 = TestRouterResultController()
        vc2.showLoading = true
        vc2.rule = context.url + "?page=2"
        vc2.context = context
        
        var vcs = nav.viewControllers
        vcs.append(vc)
        vcs.append(vc2)
        nav.setViewControllers(vcs, animated: true)
        
        // 预加载第一个界面，需放到setViewControllers之后导航栏才能获取到
        vc.loadViewIfNeeded()
        return nil
    }
    
    @MainActor @objc static func loaderRouter(_ context: Router.Context) -> Any? {
        let vc = TestRouterResultController()
        vc.rule = loaderUrl
        vc.context = context
        return vc
    }
    
}

extension TestRouter: AutoloadProtocol {
    
    static func autoload() {
        registerFilters()
        registerRouters()
        registerRewrites()
    }
    
    static func registerFilters() {
        Router.sharedLoader.append { input in
            if (input as String) == TestRouter.loaderUrl {
                return TestRouterResultController.self
            }
            return nil
        }
        
        Router.routeFilter = { context in
            let url = APP.safeURL(context.url)
            if UIApplication.app.isSystemURL(url) {
                DispatchQueue.app.mainAsync {
                    UIApplication.app.openURL(url)
                }
                return false
            }
            
            if url.absoluteString.hasPrefix("app://filter/") {
                let vc = TestRouterResultController()
                vc.rule = "app://filter/"
                vc.context = context
                DispatchQueue.app.mainAsync {
                    Navigator.push(vc, animated: true)
                }
                return false
            }
            
            return true
        }
        
        Router.routeHandler = { context, object in
            if context.isOpening {
                if let vc = object as? UIViewController {
                    let userInfo = Router.Parameter(dictionaryValue: context.userInfo)
                    if userInfo.routerHandler != nil {
                        userInfo.routerHandler?(context, vc)
                    } else {
                        DispatchQueue.app.mainAsync {
                            Navigator.open(vc, animated: true, options: userInfo.routerOptions ?? [])
                        }
                    }
                } else {
                    DispatchQueue.app.mainAsync {
                        Navigator.topPresentedController?.app.showAlert(title: "url not supported\nurl: \(context.url)\nparameters: \(context.parameters)", message: nil)
                    }
                }
            }
            
            return object
        }
        
        Router.errorHandler = { context in
            if context.url == "app://" {
                DispatchQueue.app.mainAsync {
                    UIWindow.app.showMessage(text: "打开App，不报错")
                }
                return
            }
            DispatchQueue.app.mainAsync {
                Navigator.topPresentedController?.app.showAlert(title: "url not supported\nurl: \(context.url)\nparameters: \(context.parameters)", message: nil)
            }
        }
    }
    
    static func registerRouters() {
        Router.registerClass(TestRouter.self)
        
        Router.registerURL(TestRouter.wildcardUrl) { context in
            let vc = TestRouterResultController()
            vc.rule = TestRouter.wildcardUrl
            vc.context = context
            Navigator.push(vc, animated: true)
            return nil
        }
    }
    
    static func registerRewrites() {
        Router.rewriteFilter = { url in
            return url.replacingOccurrences(of: "https://www.baidu.com/filter/", with: "app://filter/")
        }
        
        Router.addRewriteRule("(?:https://)?www.baidu.com/tests/(\\d+)", targetRule: "app://tests/$1")
        Router.addRewriteRule("(?:https://)?www.baidu.com/wildcard/(.*)", targetRule: "wildcard://$$1")
        Router.addRewriteRule("(?:https://)?www.baidu.com/wildcard2/(.*)", targetRule: "wildcard://$#1")
    }
    
}

class TestRouterResultController: UIViewController, ViewControllerProtocol {
    
    var rule: String?
    var context: Router.Context?
    var showLoading: Bool = false
    
    func setupNavbar() {
        navigationItem.title = rule ?? context?.url
        
        if app.isPresented {
            app.setLeftBarItem(Icon.closeImage) { [weak self] _ in
                self?.app.close()
            }
        }
        
        if context?.completion != nil {
            app.setRightBarItem("完成") { [weak self] _ in
                guard let context = self?.context else { return }
                
                Router.completeURL(context, result: "我是回调数据")
                self?.app.close()
            }
        }
    }
    
    func setupSubviews() {
        let label = UILabel()
        label.numberOfLines = 0
        label.text = "url: \(APP.safeString(context?.url))\n\n" + (rule != nil ? "rule: \(rule!)\n\n" : "") + "parameters: \(APP.safeString(context?.parameters))"
        view.addSubview(label)
        label.app.layoutChain
            .center()
            .width(APP.screenWidth - 40)
        
        if showLoading {
            label.isHidden = true
            app.showLoading()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.app.hideLoading()
                label.isHidden = false
            }
        }
    }
    
}
