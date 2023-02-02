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
    
    override func requestCompleteFilter() {
        let responseJSON = JSON(responseJSONObject)
        responseName = responseJSON["name"].stringValue
    }
    
}

class TestWeatherRequest: BaseRequest {
    
    var city: String = ""
    var temp: String = ""
    
    override func requestUrl() -> String {
        "http://www.weather.com.cn/data/sk/101040100.html"
    }
    
    override func responseSerializerType() -> ResponseSerializerType {
        .HTTP
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
        URLSession.fw.httpProxyDisabled = UserDefaults.standard.bool(forKey: httpProxyKey)
        
        fw.setRightBarItem("切换") { [weak self] _ in
            self?.fw.showSheet(title: nil, message: nil, actions: ["禁止代理抓包", "允许代理抓包", "获取手机网络代理", "获取本地DNS的IP地址"], actionBlock: { index in
                guard let self = self else { return }
                if index == 0 {
                    URLSession.fw.httpProxyDisabled = true
                    UserDefaults.fw.setObject(true, forKey: self.httpProxyKey)
                } else if index == 1 {
                    URLSession.fw.httpProxyDisabled = false
                    UserDefaults.fw.setObject(false, forKey: self.httpProxyKey)
                } else if index == 2 {
                    let proxyString = URLSession.fw.httpProxyString ?? ""
                    self.fw.showMessage(text: "网络代理: \n\(proxyString)")
                } else if index == 3 {
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
    }
    
    func setupLayout() {
        requestButton.fw.layoutChain
            .centerX()
            .top(toSafeArea: 50)
        
        weatherButton.fw.layoutChain
            .centerX()
            .top(toViewBottom: requestButton, offset: 20)
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
            self.fw.showAlert(title: "json请求失败", message: request.error?.localizedDescription)
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
            self.fw.showAlert(title: "天气请求失败", message: request.error?.localizedDescription)
        }
    }
    
}
