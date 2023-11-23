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
    var testFailed = false
    
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
            "name": Validator<String>.isNotNil.anyValidator,
            // 成功：必须为String且可以为Nil | 失败：必须为String且不能为空
            "nullName": (testFailed ? Validator<String>.isNotEmpty : Validator<String>.isValid).anyValidator,
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
        return testFailed ? 3 : 0
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

class TestUploadRequest: HTTPRequest {
    
    
    var uploadData: Any?
    var fileName: String = ""
    
    override func requestUrl() -> String {
        "http://127.0.0.1:8001/upload"
    }
    
    override func requestMethod() -> RequestMethod {
        .POST
    }
    
    override func requestArgument() -> Any? {
        return ["path": "/website/test/"]
    }
    
    override func requestSerializerType() -> RequestSerializerType {
        .JSON
    }
    
    override func requestFormDataEnabled() -> Bool {
        true
    }
    
    override func requestFormData(_ formData: RequestMultipartFormData) {
        if let imageData = uploadData as? Data {
            formData.appendPart(withFileData: imageData, name: "files[]", fileName: fileName, mimeType: Data.app.mimeType(from: Data.app.imageFormat(for: imageData)))
        } else if let videoURL = uploadData as? URL {
            try? formData.appendPart(withFileURL: videoURL, name: "files[]", fileName: fileName, mimeType: Data.app.mimeType(from: "mp4"))
        }
    }
    
}

class TestDownloadRequest: HTTPRequest {
    
    var fileName: String = ""
    var savePath: String = "" {
        didSet {
            resumableDownloadPath = savePath
        }
    }
    
    override func requestUrl() -> String {
        "http://127.0.0.1:8001/download"
    }
    
    override func requestMethod() -> RequestMethod {
        .GET
    }
    
    override func requestArgument() -> Any? {
        return ["path": "/website/test/\(fileName)"]
    }
    
}

class TestRequestController: UIViewController {
    
    private var httpProxyKey = "httpProxyDisabled"
    private var testPath: String {
        return FileManager.app.pathDocument.app.appendingPath(["website", "test"])
    }
    
    // MARK: - Subviews
    private lazy var requestButton: UIButton = {
        let button = AppTheme.largeButton()
        button.setTitle("Start Request", for: .normal)
        button.app.addTouch(target: self, action: #selector(onRequest))
        return button
    }()
    
    private lazy var retryButton: UIButton = {
        let button = AppTheme.largeButton()
        button.setTitle("Retry Request", for: .normal)
        button.app.addTouch(target: self, action: #selector(onRetry))
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
    
    private lazy var uploadButton: UIButton = {
        let button = AppTheme.largeButton()
        button.setTitle("Upload Request", for: .normal)
        button.app.addTouch(target: self, action: #selector(onUpload))
        return button
    }()
    
    private lazy var downloadButton: UIButton = {
        let button = AppTheme.largeButton()
        button.setTitle("Download Request", for: .normal)
        button.app.addTouch(target: self, action: #selector(onDownload))
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
            self?.app.showSheet(title: nil, message: nil, actions: [URLSession.app.httpProxyDisabled ? "允许代理抓包(下次启动生效)" : "禁止代理抓包(下次启动生效)", "获取手机网络代理", "清理上传下载缓存"], actionBlock: { index in
                guard let self = self else { return }
                if index == 0 {
                    URLSession.app.httpProxyDisabled = !URLSession.app.httpProxyDisabled
                    UserDefaults.app.setObject(URLSession.app.httpProxyDisabled, forKey: self.httpProxyKey)
                } else if index == 1 {
                    let proxyString = URLSession.app.httpProxyString ?? ""
                    self.app.showMessage(text: "网络代理: \n\(proxyString)")
                } else if index == 2 {
                    FileManager.app.removeItem(atPath: self.testPath)
                }
            })
        }
    }
   
    func setupSubviews() {
        view.addSubview(requestButton)
        view.addSubview(retryButton)
        view.addSubview(asyncButton)
        view.addSubview(syncButton)
        view.addSubview(uploadButton)
        view.addSubview(downloadButton)
        view.addSubview(observeButton)
    }
    
    func setupLayout() {
        requestButton.app.layoutChain
            .centerX()
            .top(toSafeArea: 20)
        
        retryButton.app.layoutChain
            .centerX()
            .top(toViewBottom: requestButton, offset: 20)
        
        asyncButton.app.layoutChain
            .centerX()
            .top(toViewBottom: retryButton, offset: 20)
        
        syncButton.app.layoutChain
            .centerX()
            .top(toViewBottom: asyncButton, offset: 20)
        
        uploadButton.app.layoutChain
            .centerX()
            .top(toViewBottom: syncButton, offset: 20)
        
        downloadButton.app.layoutChain
            .centerX()
            .top(toViewBottom: uploadButton, offset: 20)
        
        observeButton.app.layoutChain
            .centerX()
            .top(toViewBottom: downloadButton, offset: 20)
    }
    
}

// MARK: - Action
private extension TestRequestController {
    
    @objc func onRequest() {
        let request = TestModelRequest()
        request.testFailed = [true, false].randomElement()!
        request.context = self
        request.autoShowLoading = true
        request.autoShowError = true
        request.start { [weak self] _ in
            var message = "json请求成功: \n\(request.responseName)"
            let serverTime = request.responseServerTime
            if serverTime > 0 {
                Date.app.currentTime = serverTime
                message += "\n当前服务器时间：\(serverTime)"
            }
            self?.app.showMessage(text: message)
        } failure: { _ in }
    }
    
    @objc func onRetry() {
        let request = TestWeatherRequest()
        request.context = self
        request.autoShowLoading = true
        request.autoShowError = true
        request.testFailed = true
        APP.start(request) { [weak self] req in
            self?.app.showMessage(text: "天气请求成功: \n\(req.city) - \(req.temp)℃")
        } failure: { _ in }
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
            request.start { [weak self] _ in
                finishedCount += 1
                if finishedCount == requests.count {
                    self?.app.hideLoading()
                    let requestTime = Benchmark.end("async")
                    self?.app.showMessage(text: String(format: "异步请求完成：%.3fms", requestTime * 1000))
                }
            } failure: { [weak self] _ in
                finishedCount += 1
                if finishedCount == requests.count {
                    self?.app.hideLoading()
                    let requestTime = Benchmark.end("async")
                    self?.app.showMessage(text: String(format: "异步请求完成：%.3fms", requestTime * 1000))
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
            request.startSynchronously { [weak self] _ in
                finishedCount += 1
                if finishedCount == requests.count {
                    self?.app.hideLoading()
                    let requestTime = Benchmark.end("sync")
                    self?.app.showMessage(text: String(format: "同步请求完成：%.3fms", requestTime * 1000))
                }
            } failure: { [weak self] _ in
                finishedCount += 1
                if finishedCount == requests.count {
                    self?.app.hideLoading()
                    let requestTime = Benchmark.end("sync")
                    self?.app.showMessage(text: String(format: "同步请求完成：%.3fms", requestTime * 1000))
                }
            }
        }
    }
    
    @objc func onUpload() {
        FileManager.app.createDirectory(atPath: testPath)
        app.showImagePicker(filterType: [.image, .video], selectionLimit: 1, allowsEditing: true) { [weak self] results, info, cancelled in
            if let image = results.first as? UIImage {
                self?.app.showLoading()
                UIImage.app.compressDatas([image], maxWidth: 1024, maxLength: 512 * 1024) { imageDatas in
                    self?.app.hideLoading(delayed: true)
                    
                    self?.onUploadData(imageDatas.first)
                }
            } else if let videoURL = results.first as? URL {
                self?.onUploadData(videoURL)
            } else {
                self?.app.showMessage(text: "已取消")
            }
        }
    }
    
    private func onUploadData(_ uploadData: Any?) {
        let isVideo = uploadData is URL
        let request = TestUploadRequest()
        request.context = self
        request.uploadData = uploadData
        request.fileName = isVideo ? "upload.mp4" : "upload.jpg"
        request.autoShowLoading = true
        request.start { [weak self] _ in
            var previewUrl = "http://127.0.0.1:8001/download?" + String.app.queryEncode(["path": "/website/test/\(request.fileName)"])
            if isVideo {
                previewUrl = (self?.testPath ?? "").app.appendingPath(request.fileName)
            }
            
            self?.app.showConfirm(title: "上传\(isVideo ? "视频" : "图片")成功", message: "是否打开预览？", confirmBlock: {
                self?.app.showImagePreview(imageURLs: [previewUrl], imageInfos: nil, currentIndex: 0)
            })
        } failure: { [weak self] _ in
            self?.app.showMessage(text: RequestError.isConnectionError(request.error) ? "请先开启Debug Web Server" : request.error?.localizedDescription)
        }
    }
    
    @objc func onDownload() {
        FileManager.app.createDirectory(atPath: testPath)
        var fileName = "upload.mp4"
        var saveName = "download.mp4"
        var isVideo = true
        if !FileManager.app.fileExists(atPath: testPath.app.appendingPath(fileName), isDirectory: false) {
            fileName = "upload.jpg"
            saveName = "download.jpg"
            isVideo = false
        }
        
        let request = TestDownloadRequest()
        request.fileName = fileName
        request.savePath = testPath.app.appendingPath(saveName)
        request.context = self
        request.autoShowLoading = true
        request.start { [weak self] _ in
            var previewUrl = "http://127.0.0.1:8001/download?" + String.app.queryEncode(["path": "/website/test/\(saveName)"])
            if isVideo {
                previewUrl = request.savePath
            }
            
            self?.app.showConfirm(title: "下载\(isVideo ? "视频" : "图片")成功", message: "是否打开预览？", confirmBlock: {
                self?.app.showImagePreview(imageURLs: [previewUrl], imageInfos: nil, currentIndex: 0)
            })
        } failure: { [weak self] _ in
            self?.app.showMessage(text: RequestError.isConnectionError(request.error) ? "请先开启Debug Web Server" : request.error?.localizedDescription)
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
