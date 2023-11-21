//
//  TestRequestController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2023/2/2.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import FWFramework
import UIKit

class TestModelRequest: HTTPRequest {
    
    private(set) var responseName = ""
    
    override func requestUrl() -> String {
        "http://kvm.wuyong.site/test.json"
    }
    
    override func responseSerializerType() -> ResponseSerializerType {
        .JSON
    }
    
    override func requestTimeoutInterval() -> TimeInterval {
        30
    }
    
    override func filterUrlRequest(_ urlRequest: NSMutableURLRequest) {
        urlRequest.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        
        // 一般在filterUrlRequest中进行请求签名，注意header不能含有中文等非法字符
        let headers = [
            "Authorization": "",
            "X-Access-Key": "",
            "X-Timestamp": "",
            "X-Nonce-Data": "",
            "X-Meta-Data": "",
            "X-Sign-Data": "",
        ]
        for (field, value) in headers {
            urlRequest.setValue(value, forHTTPHeaderField: field)
        }
    }
    
    override func jsonValidator() -> Any? {
        return [
            // 必须为String且不能为nil
            "name": Validator<String>().anyValidator,
            // 必须为String且可以为Nil
            "nullName": Validator<String>.isValid.anyValidator,
        ]
    }
    
    override func requestCompleteFilter() {
        let responseJSON = JSON(responseJSONObject)
        responseName = responseJSON["name"].stringValue
    }
    
}

class TestWeatherRequest: HTTPRequest {
    
    var city: String = ""
    var temp: String = ""
    var testFailed = false
    
    override func requestUrl() -> String {
        "http://www.weather.com.cn/data/sk/101040100.html"
    }
    
    override func responseSerializerType() -> ResponseSerializerType {
        testFailed ? .JSON : .HTTP
    }
    
    override func requestCompleteFilter() {
        let responseJSON = JSON(responseString?.app.jsonDecode)
        city = responseJSON["weatherinfo"]["city"].stringValue
        temp = responseJSON["weatherinfo"]["temp"].stringValue
    }
    
    override func requestRetryCount() -> Int {
        return testFailed ? 2 : 0
    }
    
    override func requestRetryInterval() -> TimeInterval {
        return testFailed ? 1 : 0
    }
    
    override func requestRetryTimeout() -> TimeInterval {
        return testFailed ? 30 : 30
    }
    
    override func requestRetryValidator(_ response: HTTPURLResponse, responseObject: Any?, error: Error?) -> Bool {
        return true
    }
    
}

class TestRequestController: UIViewController {
    
    private var httpProxyKey = "httpProxyDisabled"
    
    // MARK: - Subviews
    private lazy var requestButton: UIButton = {
        let button = AppTheme.largeButton()
        button.setTitle("Start Request", for: .normal)
        button.app.addTouch(target: self, action: #selector(onRequest))
        return button
    }()
    
    private lazy var weatherButton: UIButton = {
        let button = AppTheme.largeButton()
        button.setTitle("Start Weather", for: .normal)
        button.app.addTouch(target: self, action: #selector(onWeather))
        return button
    }()
    
    private lazy var failedButton: UIButton = {
        let button = AppTheme.largeButton()
        button.setTitle("Failed Request", for: .normal)
        button.app.addTouch(target: self, action: #selector(onFailed))
        return button
    }()
    
    private lazy var asyncButton: UIButton = {
        let button = AppTheme.largeButton()
        button.setTitle("Async Request", for: .normal)
        button.app.addTouch(target: self, action: #selector(onAsync))
        return button
    }()
    
    private lazy var syncButton: UIButton = {
        let button = AppTheme.largeButton()
        button.setTitle("Sync Request", for: .normal)
        button.app.addTouch(target: self, action: #selector(onSync))
        return button
    }()
    
    private lazy var observeButton: UIButton = {
        let button = AppTheme.largeButton()
        button.setTitle("Observe Status", for: .normal)
        button.app.addTouch(target: self, action: #selector(onObserve))
        return button
    }()
    
}

// MARK: - Setup
extension TestRequestController: ViewControllerProtocol {
    
    func didInitialize() {
        // 测试\udf36|\udd75等字符会导致json解码失败问题
        var jsonString = "{\"name\": \"\\u8499\\u81ea\\u7f8e\\u5473\\u6ce1\\u6912\\u7b0b\\ud83d\\ude04\\\\udf36\\ufe0f\"}"
        var jsonObject = jsonString.app.jsonDecode
        APP.debug("name: %@\njson: %@", JSON(jsonObject)["name"].stringValue, String.app.jsonEncode(jsonObject ?? [String: Any]()) ?? "")
        
        jsonString = "{\"name\": \"Test1\\udd75Test2\\ud83dTest3\\u8499\\u81ea\\u7f8e\\u5473\\u6ce1\\u6912\\u7b0b\\ud83d\\ude04\\udf36\\ufe0f\"}"
        jsonObject = jsonString.app.jsonDecode
        APP.debug("name2: %@\njson2: %@", JSON(jsonObject)["name"].stringValue, String.app.jsonEncode(jsonObject ?? [String: Any]()) ?? "")
        
        // 测试%导致stringByRemovingPercentEncoding返回nil问题
        var queryValue = "我是字符串100%测试"
        APP.debug("query: %@", queryValue.removingPercentEncoding ?? "")
        queryValue = "%E6%88%91%E6%98%AF%E5%AD%97%E7%AC%A6%E4%B8%B2100%25%E6%B5%8B%E8%AF%95"
        APP.debug("query2: %@", queryValue.removingPercentEncoding ?? "")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        onStopObserve()
    }
    
    func setupNavbar() {
        URLSession.app.httpProxyDisabled = UserDefaults.standard.bool(forKey: httpProxyKey)
        
        app.setRightBarItem("切换") { [weak self] _ in
            self?.app.showSheet(title: nil, message: nil, actions: [URLSession.app.httpProxyDisabled ? "允许代理抓包(下次启动生效)" : "禁止代理抓包(下次启动生效)", "获取手机网络代理"], actionBlock: { index in
                guard let self = self else { return }
                if index == 0 {
                    URLSession.app.httpProxyDisabled = !URLSession.app.httpProxyDisabled
                    UserDefaults.app.setObject(URLSession.app.httpProxyDisabled, forKey: self.httpProxyKey)
                } else if index == 1 {
                    let proxyString = URLSession.app.httpProxyString ?? ""
                    self.app.showMessage(text: "网络代理: \n\(proxyString)")
                }
            })
        }
    }
   
    func setupSubviews() {
        view.addSubview(requestButton)
        view.addSubview(weatherButton)
        view.addSubview(failedButton)
        view.addSubview(asyncButton)
        view.addSubview(syncButton)
        view.addSubview(observeButton)
    }
    
    func setupLayout() {
        requestButton.app.layoutChain
            .centerX()
            .top(toSafeArea: 50)
        
        weatherButton.app.layoutChain
            .centerX()
            .top(toViewBottom: requestButton, offset: 20)
        
        failedButton.app.layoutChain
            .centerX()
            .top(toViewBottom: weatherButton, offset: 20)
        
        asyncButton.app.layoutChain
            .centerX()
            .top(toViewBottom: failedButton, offset: 20)
        
        syncButton.app.layoutChain
            .centerX()
            .top(toViewBottom: asyncButton, offset: 20)
        
        observeButton.app.layoutChain
            .centerX()
            .top(toViewBottom: syncButton, offset: 20)
    }
    
}

// MARK: - Action
private extension TestRequestController {
    
    @objc func onRequest() {
        self.app.showLoading()
        let request = TestModelRequest()
        request.start { _ in
            self.app.hideLoading()
            
            var message = "json请求成功: \n\(request.responseName)"
            let serverTime = request.responseServerTime
            if serverTime > 0 {
                Date.app.currentTime = serverTime
                message += "\n当前服务器时间：\(serverTime)"
            }
            self.app.showMessage(text: message)
        } failure: { _ in
            self.app.hideLoading()
            
            var message = "json请求\(RequestError.isConnectionError(request.error) ? "失败" : "异常"): \n\(request.error?.localizedDescription ?? "")"
            let serverTime = request.responseServerTime
            if serverTime > 0 {
                Date.app.currentTime = serverTime
                message += "\n当前服务器时间：\(serverTime)"
            }
            self.app.showMessage(text: message)
        }
    }
    
    @objc func onWeather() {
        self.app.showLoading()
        let request = TestWeatherRequest()
        request.start { _ in
            self.app.hideLoading()
            self.app.showMessage(text: "天气请求成功: \n\(request.city) - \(request.temp)℃")
        } failure: { _ in
            self.app.hideLoading()
            self.app.showMessage(text: "天气请求\(RequestError.isConnectionError(request.error) ? "失败" : "异常"): \n\(request.error?.localizedDescription ?? "")")
        }
    }
    
    @objc func onFailed() {
        self.app.showLoading()
        let request = TestWeatherRequest()
        request.testFailed = true
        request.start { _ in
            self.app.hideLoading()
            self.app.showMessage(text: "天气请求成功: \n\(request.city) - \(request.temp)℃")
        } failure: { _ in
            self.app.hideLoading()
            self.app.showMessage(text: "天气请求\(RequestError.isConnectionError(request.error) ? "失败" : "异常"): \n\(request.error?.localizedDescription ?? "")")
        }
    }
    
    @objc func onAsync() {
        self.app.showLoading()
        let requests: [HTTPRequest] = [
            TestWeatherRequest(),
            TestWeatherRequest(),
            TestModelRequest(),
            TestModelRequest(),
        ]
        var finishedCount: Int = 0
        Benchmark.begin("async")
        for request in requests {
            request.start { _ in
                finishedCount += 1
                if finishedCount == requests.count {
                    self.app.hideLoading()
                    let requestTime = Benchmark.end("async")
                    self.app.showMessage(text: String(format: "异步请求完成：%.3fms", requestTime * 1000))
                }
            } failure: { _ in
                finishedCount += 1
                if finishedCount == requests.count {
                    self.app.hideLoading()
                    let requestTime = Benchmark.end("async")
                    self.app.showMessage(text: String(format: "异步请求完成：%.3fms", requestTime * 1000))
                }
            }
        }
    }
    
    @objc func onSync() {
        self.app.showLoading()
        let requests: [HTTPRequest] = [
            TestWeatherRequest(),
            TestWeatherRequest(),
            TestModelRequest(),
            TestModelRequest(),
        ]
        var finishedCount: Int = 0
        Benchmark.begin("sync")
        for request in requests {
            request.startSynchronously { _ in
                finishedCount += 1
                if finishedCount == requests.count {
                    self.app.hideLoading()
                    let requestTime = Benchmark.end("sync")
                    self.app.showMessage(text: String(format: "同步请求完成：%.3fms", requestTime * 1000))
                }
            } failure: { _ in
                finishedCount += 1
                if finishedCount == requests.count {
                    self.app.hideLoading()
                    let requestTime = Benchmark.end("sync")
                    self.app.showMessage(text: String(format: "同步请求完成：%.3fms", requestTime * 1000))
                }
            }
        }
    }
    
    @objc func onObserve() {
        if NetworkReachabilityManager.shared.isListening {
            onStopObserve()
            return
        }
        
        NetworkReachabilityManager.shared.startListening { [weak self] status in
            switch status {
            case .unknown:
                self?.observeButton.setTitle("Unknown", for: .normal)
            case .notReachable:
                self?.observeButton.setTitle("Not Reachable", for: .normal)
            case .reachable(let connectionType):
                self?.observeButton.setTitle(connectionType == .ethernetOrWiFi ? "WiFi Reachable" : "WWAN Reachable", for: .normal)
            }
        }
    }
    
    @objc func onStopObserve() {
        NetworkReachabilityManager.shared.stopListening()
        observeButton.setTitle("Observe Status", for: .normal)
    }
    
}
