//
//  TestRequestController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2023/2/2.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import FWFramework
import UIKit

class TestModelRequest: BaseRequest {
    
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
    
    override func requestCompleteFilter() {
        let responseJSON = JSON(responseJSONObject)
        responseName = responseJSON["name"].stringValue
    }
    
}

class TestWeatherRequest: BaseRequest {
    
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
        let responseJSON = JSON(responseString?.fw.jsonDecode)
        city = responseJSON["weatherinfo"]["city"].stringValue
        temp = responseJSON["weatherinfo"]["temp"].stringValue
    }
    
}

class TestRequestController: UIViewController {
    
    private var httpProxyKey = "httpProxyDisabled"
    
    // MARK: - Subviews
    private lazy var requestButton: UIButton = {
        let button = AppTheme.largeButton()
        button.setTitle("Start Request", for: .normal)
        button.fw.addTouch(target: self, action: #selector(onRequest))
        return button
    }()
    
    private lazy var weatherButton: UIButton = {
        let button = AppTheme.largeButton()
        button.setTitle("Start Weather", for: .normal)
        button.fw.addTouch(target: self, action: #selector(onWeather))
        return button
    }()
    
    private lazy var failedButton: UIButton = {
        let button = AppTheme.largeButton()
        button.setTitle("Failed Request", for: .normal)
        button.fw.addTouch(target: self, action: #selector(onFailed))
        return button
    }()
    
    private lazy var asyncButton: UIButton = {
        let button = AppTheme.largeButton()
        button.setTitle("Async Request", for: .normal)
        button.fw.addTouch(target: self, action: #selector(onAsync))
        return button
    }()
    
    private lazy var syncButton: UIButton = {
        let button = AppTheme.largeButton()
        button.setTitle("Sync Request", for: .normal)
        button.fw.addTouch(target: self, action: #selector(onSync))
        return button
    }()
    
}

// MARK: - Setup
extension TestRequestController: ViewControllerProtocol {
    
    func didInitialize() {
        // 测试\udf36|\udd75等字符会导致json解码失败问题
        var jsonString = "{\"name\": \"\\u8499\\u81ea\\u7f8e\\u5473\\u6ce1\\u6912\\u7b0b\\ud83d\\ude04\\\\udf36\\ufe0f\"}"
        var jsonObject = jsonString.fw.jsonDecode
        FW.debug("name: %@\njson: %@", JSON(jsonObject)["name"].stringValue, String.fw.jsonEncode(jsonObject ?? [:]) ?? "")
        
        jsonString = "{\"name\": \"Test1\\udd75Test2\\ud83dTest3\\u8499\\u81ea\\u7f8e\\u5473\\u6ce1\\u6912\\u7b0b\\ud83d\\ude04\\udf36\\ufe0f\"}"
        jsonObject = jsonString.fw.jsonDecode
        FW.debug("name2: %@\njson2: %@", JSON(jsonObject)["name"].stringValue, String.fw.jsonEncode(jsonObject ?? [:]) ?? "")
        
        // 测试%导致stringByRemovingPercentEncoding返回nil问题
        var queryValue = "我是字符串100%测试"
        FW.debug("query: %@", queryValue.removingPercentEncoding ?? "")
        queryValue = "%E6%88%91%E6%98%AF%E5%AD%97%E7%AC%A6%E4%B8%B2100%25%E6%B5%8B%E8%AF%95"
        FW.debug("query2: %@", queryValue.removingPercentEncoding ?? "")
    }
    
    func setupNavbar() {
        NetworkConfig.shared().debugLogEnabled = true
        URLSession.fw.httpProxyDisabled = UserDefaults.standard.bool(forKey: httpProxyKey)
        
        fw.setRightBarItem("切换") { [weak self] _ in
            self?.fw.showSheet(title: nil, message: nil, actions: [URLSession.fw.httpProxyDisabled ? "允许代理抓包(下次启动生效)" : "禁止代理抓包(下次启动生效)", "获取手机网络代理", "获取本地DNS的IP地址"], actionBlock: { index in
                guard let self = self else { return }
                if index == 0 {
                    URLSession.fw.httpProxyDisabled = !URLSession.fw.httpProxyDisabled
                    UserDefaults.fw.setObject(URLSession.fw.httpProxyDisabled, forKey: self.httpProxyKey)
                } else if index == 1 {
                    let proxyString = URLSession.fw.httpProxyString ?? ""
                    self.fw.showMessage(text: "网络代理: \n\(proxyString)")
                } else if index == 2 {
                    self.fw.showPrompt(title: "请输入域名", message: nil, cancel: nil, confirm: nil, promptBlock: { textField in
                        textField.text = "kvm.wuyong.site"
                    }, confirmBlock: { [weak self] host in
                        self?.fw.showLoading()
                        DispatchQueue.global().async {
                            let ipAddress = URLSession.fw.ipAddress(host: host) ?? ""
                            DispatchQueue.main.async {
                                self?.fw.hideLoading()
                                self?.fw.showMessage(text: "IP地址: \n\(ipAddress)")
                            }
                        }
                    })
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
    }
    
    func setupLayout() {
        requestButton.fw.layoutChain
            .centerX()
            .top(toSafeArea: 50)
        
        weatherButton.fw.layoutChain
            .centerX()
            .top(toViewBottom: requestButton, offset: 20)
        
        failedButton.fw.layoutChain
            .centerX()
            .top(toViewBottom: weatherButton, offset: 20)
        
        asyncButton.fw.layoutChain
            .centerX()
            .top(toViewBottom: failedButton, offset: 20)
        
        syncButton.fw.layoutChain
            .centerX()
            .top(toViewBottom: asyncButton, offset: 20)
    }
    
}

// MARK: - Action
private extension TestRequestController {
    
    @objc func onRequest() {
        self.fw.showLoading()
        let request = TestModelRequest()
        request.startWithCompletionBlock { _ in
            self.fw.hideLoading()
            self.fw.showMessage(text: "json请求成功: \n\(request.responseName)")
        } failure: { _ in
            self.fw.hideLoading()
            self.fw.showMessage(text: "json请求失败: \n\(request.error?.localizedDescription ?? "")")
        }
    }
    
    @objc func onWeather() {
        self.fw.showLoading()
        let request = TestWeatherRequest()
        request.startWithCompletionBlock { _ in
            self.fw.hideLoading()
            self.fw.showMessage(text: "天气请求成功: \n\(request.city) - \(request.temp)℃")
        } failure: { _ in
            self.fw.hideLoading()
            self.fw.showMessage(text: "天气请求失败: \n\(request.error?.localizedDescription ?? "")")
        }
    }
    
    @objc func onFailed() {
        self.fw.showLoading()
        let request = TestWeatherRequest()
        request.testFailed = true
        request.startWithCompletionBlock { _ in
            self.fw.hideLoading()
            self.fw.showMessage(text: "天气请求成功: \n\(request.city) - \(request.temp)℃")
        } failure: { _ in
            self.fw.hideLoading()
            self.fw.showMessage(text: "天气请求失败: \n\(request.error?.localizedDescription ?? "")")
        }
    }
    
    @objc func onAsync() {
        self.fw.showLoading()
        let requests: [BaseRequest] = [
            TestWeatherRequest(),
            TestWeatherRequest(),
            TestModelRequest(),
            TestModelRequest(),
        ]
        var finishedCount: Int = 0
        Benchmark.begin("async")
        for request in requests {
            request.startWithCompletionBlock { _ in
                finishedCount += 1
                if finishedCount == requests.count {
                    self.fw.hideLoading()
                    let requestTime = Benchmark.end("async")
                    self.fw.showMessage(text: String(format: "异步请求完成：%.3fms", requestTime * 1000))
                }
            } failure: { _ in
                finishedCount += 1
                if finishedCount == requests.count {
                    self.fw.hideLoading()
                    let requestTime = Benchmark.end("async")
                    self.fw.showMessage(text: String(format: "异步请求完成：%.3fms", requestTime * 1000))
                }
            }
        }
    }
    
    @objc func onSync() {
        self.fw.showLoading()
        let requests: [BaseRequest] = [
            TestWeatherRequest(),
            TestWeatherRequest(),
            TestModelRequest(),
            TestModelRequest(),
        ]
        var finishedCount: Int = 0
        Benchmark.begin("sync")
        for request in requests {
            request.startWithCompletionBlock { _ in
                finishedCount += 1
                if finishedCount == requests.count {
                    self.fw.hideLoading()
                    let requestTime = Benchmark.end("sync")
                    self.fw.showMessage(text: String(format: "同步请求完成：%.3fms", requestTime * 1000))
                }
            } failure: { _ in
                finishedCount += 1
                if finishedCount == requests.count {
                    self.fw.hideLoading()
                    let requestTime = Benchmark.end("sync")
                    self.fw.showMessage(text: String(format: "同步请求完成：%.3fms", requestTime * 1000))
                }
            }
        }
    }
    
}
