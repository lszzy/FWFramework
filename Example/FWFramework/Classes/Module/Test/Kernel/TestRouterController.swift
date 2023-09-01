//
//  TestRouterController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/5.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestRouterController: UIViewController, TableViewControllerProtocol {
    
    static var popCount: Int = 0
    
    func setupTableStyle() -> UITableView.Style {
        .grouped
    }
    
    func setupTableLayout() {
        tableView.fw.pinEdges()
    }
    
    func setupNavbar() {
        navigationItem.title = "Router"
        fw.setRightBarItem(UIBarButtonItem.SystemItem.action.rawValue) { [weak self] _ in
            self?.fw.showSheet(title: nil, message: nil, actions: [Autoloader.routerStrictMode ? "关闭严格模式" : "开启严格模式"], actionBlock: { _ in
                Autoloader.routerStrictMode = !Autoloader.routerStrictMode
                Router.strictMode = Autoloader.routerStrictMode
            })
        }
        
        var url = "http://test.com?id=我是中文"
        FW.debug("urlEncode: %@", String(describing: url.fw.urlEncode))
        FW.debug("urlDecode: %@", String(describing: url.fw.urlEncode?.fw.urlDecode))
        FW.debug("urlEncodeComponent: %@", String(describing: url.fw.urlEncodeComponent))
        FW.debug("urlDecodeComponent: %@", String(describing: url.fw.urlEncodeComponent?.fw.urlDecodeComponent))
        
        url = "app://tests/1?value=2&name=name2&title=我是字符串100%&url=https%3A%2F%2Fkvm.wuyong.site%2Ftest.php%3Fvalue%3D1%26name%3Dname1%23%2Fhome1#/home2"
        FW.debug("string.queryDecode: %@", String(describing: url.fw.queryDecode))
        FW.debug("string.queryEncode: %@", String(describing: String.fw.queryEncode(url.fw.queryDecode)))
        let nsurl = URL.fw.url(string: url)
        FW.debug("query.queryDecode: %@", String(describing: nsurl?.query?.fw.queryDecode))
        FW.debug("url.queryDictionary: %@", String(describing: nsurl?.fw.queryDictionary))
    }
    
    func setupSubviews() {
        let str = "http://test.com?id=我是中文"
        var url = URL(string: str)
        FW.debug("str: %@ =>\nurl: %@", str, String(describing: url))
        url = URL.fw.url(string: str)
        FW.debug("str: %@ =>\nurl: %@", str, String(describing: url))
        
        var urlStr = Router.generateURL(TestRouter.testUrl, parameters: nil)
        FW.debug("url: %@", urlStr)
        urlStr = Router.generateURL(TestRouter.testUrl, parameters: [1])
        FW.debug("url: %@", urlStr)
        urlStr = Router.generateURL(TestRouter.testUrl, parameters: ["id": 2])
        FW.debug("url: %@", urlStr)
        urlStr = Router.generateURL(TestRouter.testUrl, parameters: 3)
        FW.debug("url: %@", urlStr)
        
        tableData.addObjects(from: [
            ["打开Web", "onOpenHttp"],
            ["打开完整Web", "onOpenHttp2"],
            ["打开异常Web", "onOpenHttp3"],
            ["测试Cookie", "onOpenCookie"],
            ["Url编码", "onOpenEncode"],
            ["Url未编码", "onOpenImage"],
            ["不规范Url", "onOpenSlash"],
            ["打开App", "onOpenApp"],
            ["打开Url", "onOpen"],
            ["中文Url", "onOpenChinese"],
            ["打开Url，通配符*", "onOpenWild"],
            ["打开Url，*id", "onOpenWild2"],
            ["打开Url，协议", "onOpenController"],
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
            ["自动注册的Url", "onOpenLoader"],
            ["跳转telprompt", "onOpenTel"],
            ["跳转设置", "onOpenSettings"],
            ["跳转首页", "onOpenHome"],
            ["跳转home/undefined", "onOpenHome2"],
            ["不支持tab", "onOpenHome3"],
            ["关闭close", "onOpenClose"],
            ["通用链接douyin", "onOpenUniversalLinks"],
            ["外部safari", "onOpenUrl"],
            ["内部safari", "onOpenSafari"],
            ["iOS14bug", "onOpen14"],
        ])
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.fw.cell(tableView: tableView)
        let rowData = tableData.object(at: indexPath.row) as! [String]
        cell.textLabel?.text = rowData[0]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let rowData = tableData.object(at: indexPath.row) as! [String]
        fw.invokeMethod(NSSelectorFromString(rowData[1]))
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
        Router.openURL("wildcard://not_found?id=1#anchor")
    }
    
    func onOpenWild2() {
        Router.openURL(Router.generateURL(TestRouter.pageUrl, parameters: "test/1"))
    }
    
    func onOpenController() {
        Router.openURL(Router.generateURL(TestRouter.itemUrl, parameters: [1, 2]))
    }
    
    func onOpenCallback() {
        Router.openURL("\(TestRouter.wildcardUrl)?id=2") { result in
            UIWindow.fw.showMessage(text: result)
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
        Router.object(forURL: TestRouter.objectUnmatchUrl)
    }
    
    func onOpenUnmatch3() {
        Router.openURL(TestRouter.objectUrl)
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
        Router.openURL("telprompt:10000")
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
    
    func onOpenCookie() {
        Router.openURL("http://kvm.wuyong.site/cookie.php?param=value#anchor")
    }
    
    func onOpenUniversalLinks() {
        let url = "https://v.douyin.com/JYmHJ9k/"
        UIApplication.fw.openUniversalLinks(url) { success in
            if !success {
                Router.openURL(url)
            }
        }
    }
    
    func onOpenUrl() {
        UIApplication.fw.openURL("http://kvm.wuyong.site/test.php")
    }
    
    func onOpenSafari() {
        UIApplication.fw.openSafariController("http://kvm.wuyong.site/test.php") {
            FW.debug("SafariController completionHandler")
        }
    }
    
    func onOpen14() {
        let vc = TestRouterResultController()
        vc.navigationItem.title = "iOS14 bug"
        vc.context = RouterContext(url: "http://kvm.wuyong.site/test.php?key=value")
        vc.fw.shouldPopController = { [weak self] in
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
    
    @StoredValue("routerStrictMode")
    static var routerStrictMode: Bool = false
    
    func loadTestRouter() {
        FW.autoload(TestRouter.self)
        Router.strictMode = Autoloader.routerStrictMode
    }
    
}

@objcMembers
class TestRouter: NSObject, AutoloadProtocol {
    
    static let testUrl = "app://tests/:id"
    static let homeUrl = "app://tab/home"
    static let wildcardUrl = "wildcard://test1"
    static let objectUrl = "object://test2"
    static let objectUnmatchUrl = "object://test"
    static let loaderUrl = "app://loader"
    static let pageUrl = "app://page/*id"
    static let itemUrl = "app://shops/:id/items/:itemId"
    static let javascriptUrl = "app://javascript"
    static let closeUrl = "app://close"
    
    class func testRouter(_ context: RouterContext) -> Any? {
        let vc = TestRouterResultController()
        vc.context = context
        Navigator.push(vc, animated: true)
        return nil
    }
    
    class func homeRouter(_ context: RouterContext) -> Any? {
        UIWindow.fw.main?.fw.selectTabBarController(index: 0)
        return nil
    }
    
    class func wildcardRouter(_ context: RouterContext) -> Any? {
        let vc = TestRouterResultController()
        vc.context = context
        Navigator.push(vc, animated: true)
        return nil
    }
    
    class func pageRouter(_ context: RouterContext) -> Any? {
        let vc = TestRouterResultController()
        vc.context = context
        Navigator.push(vc, animated: true)
        return nil
    }
    
    class func itemRouter(_ context: RouterContext) -> Any? {
        let vc = TestRouterResultController()
        vc.context = context
        Navigator.push(vc, animated: true)
        return nil
    }
    
    class func objectRouter(_ context: RouterContext) -> Any? {
        let vc = TestRouterResultController()
        vc.context = context
        return vc
    }
    
    class func objectUnmatchRouter(_ context: RouterContext) -> Any? {
        if context.isOpening {
            return "OBJECT UNMATCH"
        } else {
            Navigator.topPresentedController?.fw.showAlert(title: "url not supported\nurl: \(context.url)\nparameters: \(context.parameters)", message: nil)
            return nil
        }
    }
    
    class func javascriptRouter(_ context: RouterContext) -> Any? {
        guard let webVC = Navigator.topViewController as? WebController,
              webVC.isViewLoaded else { return nil }
        
        let param = context.parameters["param"].safeString
        let result = "js:\(param) => app:2"
        let callback = context.parameters["callback"].safeString
        let javascript = "\(callback)('\(result)');"
        
        webVC.webView.evaluateJavaScript(javascript) { value, error in
            Navigator.topViewController?.fw.showAlert(title: "App", message: "app:2 => js:\(String(describing: value))")
        }
        return nil
    }
    
    class func closeRouter(_ context: RouterContext) -> Any? {
        guard let topVC = Navigator.topViewController else { return nil }
        topVC.fw.close()
        return nil
    }
    
    class func loaderRouter(_ context: RouterContext) -> Any? {
        let vc = TestRouterResultController()
        vc.context = context
        return vc
    }
    
    static func autoload() {
        registerFilters()
        registerRouters()
        registerRewrites()
    }
    
    static func registerFilters() {
        Router.sharedLoader.add { input in
            if (input as String) == TestRouter.loaderUrl {
                return TestRouterResultController.self
            }
            return nil
        }
        
        Router.setRouteFilter { context in
            let url = FW.safeURL(context.url)
            if UIApplication.fw.isSystemURL(url) {
                UIApplication.fw.openURL(url)
                return false
            }
            
            if url.absoluteString.hasPrefix("app://filter/") {
                let vc = TestRouterResultController()
                vc.context = context
                Navigator.push(vc, animated: true)
                return false
            }
            
            return true
        }
        
        Router.setRouteHandler { context, object in
            if context.isOpening {
                if let vc = object as? UIViewController {
                    Navigator.open(vc, animated: true)
                } else {
                    Navigator.topPresentedController?.fw.showAlert(title: "url not supported\nurl: \(context.url)\nparameters: \(context.parameters)", message: nil)
                }
            }
            
            return object
        }
        
        Router.setErrorHandler { context in
            if context.url == "app://" {
                UIWindow.fw.showMessage(text: "打开App，不报错")
                return
            }
            Navigator.topPresentedController?.fw.showAlert(title: "url not supported\nurl: \(context.url)\nparameters: \(context.parameters)", message: nil)
        }
    }
    
    static func registerRouters() {
        Router.registerClass(TestRouter.self)
        
        Router.registerURL("wildcard://*") { context in
            let vc = TestRouterResultController()
            vc.context = context
            Navigator.push(vc, animated: true)
            return nil
        }
    }
    
    static func registerRewrites() {
        Router.setRewriteFilter { url in
            return url.replacingOccurrences(of: "https://www.baidu.com/filter/", with: "app://filter/")
        }
        
        Router.addRewriteRule("(?:https://)?www.baidu.com/tests/(\\d+)", targetRule: "app://tests/$1")
        Router.addRewriteRule("(?:https://)?www.baidu.com/wildcard/(.*)", targetRule: "wildcard://$$1")
        Router.addRewriteRule("(?:https://)?www.baidu.com/wildcard2/(.*)", targetRule: "wildcard://$#1")
    }
    
}

class TestRouterResultController: UIViewController, ViewControllerProtocol {
    
    var context: RouterContext?
    
    func setupNavbar() {
        navigationItem.title = context?.url
        
        if context?.completion != nil {
            fw.setRightBarItem("完成") { [weak self] _ in
                guard let context = self?.context else { return }
                
                Router.completeURL(context, result: "我是回调数据")
                self?.fw.close()
            }
        }
    }
    
    func setupSubviews() {
        let label = UILabel()
        label.numberOfLines = 0
        label.text = "URL: \(FW.safeString(context?.url))\n\nparameters: \(FW.safeString(context?.parameters))"
        view.addSubview(label)
        label.fw.layoutChain
            .center()
            .width(FW.screenWidth - 40)
    }
    
}
