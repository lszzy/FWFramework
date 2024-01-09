//
//  TestRequestController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2023/2/2.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import FWFramework
import UIKit

// 继承HTTPRequest及重载Builder示例
class AppRequest: HTTPRequest {
    
    class Builder: HTTPRequest.Builder {
        override func build() -> AppRequest {
            return AppRequest(builder: self)
        }
    }
    
    override func urlRequestFilter(_ urlRequest: inout URLRequest) {
        super.urlRequestFilter(&urlRequest)
        
        urlRequest.setValue("", forHTTPHeaderField: "Authorization")
    }
    
}

// 解析单个ResponseModel实例
class TestModelRequest: HTTPRequest, ResponseModelRequest {
    typealias ResponseModel = TestModel
    
    /*
    // 兼容JSONModel协议
    struct TestModel: JSONModel {
        var name: String = ""
    }*/
    
    // 也兼容CodableModel协议
    struct TestModel: CodableModel {
        var name: String = ""
    }
    
    /*
    // 不实现时自动解析，实现为手工解析
    func responseModelFilter() -> TestModel? {
        decodeResponseModel()
    }*/
    
    var testFailed = false
    
    override func requestUrl() -> String {
        "http://kvm.wuyong.site/test.json?t=\(Date.app.currentTime)"
    }
    
    override func responseSerializerType() -> ResponseSerializerType {
        .JSON
    }
    
    override func requestTimeoutInterval() -> TimeInterval {
        30
    }
    
    override func urlRequestFilter(_ urlRequest: inout URLRequest) {
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
    
}

// 解析ResponseModel数组实例
class TestWeatherRequest: HTTPRequest, ResponseModelRequest {
    typealias ResponseModel = [TestWeatherModel]
    
    struct TestWeatherModel: JSONModel {
        var city: String = ""
        var temp: String = ""
    }
    
    // 后台预加载数据模型
    override func preloadResponseModel() -> Bool {
        return true
    }
    
    // 不实现时自动解析，实现为手工解析
    func responseModelFilter() -> [TestWeatherModel]? {
        decodeResponseModel(designatedPath: "weatherinfo")
    }
    
    var testFailed = false
    
    override func requestUrl() -> String {
        "http://www.weather.com.cn/data/sk/101040100.html"
    }
    
    override func responseSerializerType() -> ResponseSerializerType {
        testFailed ? .JSON : .HTTP
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

// 请求缓存实例
class TestCacheRequest: HTTPRequest, ResponseModelRequest {
    typealias ResponseModel = String
    
    func responseModelFilter() -> String? {
        decodeResponseModel(designatedPath: "time")
    }
    
    override func requestUrl() -> String {
        "http://kvm.wuyong.site/time.php"
    }
    
    override func responseSerializerType() -> ResponseSerializerType {
        .JSON
    }
    
    override func requestTimeoutInterval() -> TimeInterval {
        30
    }
    
    override func cacheTimeInSeconds() -> Int {
        60 * 60
    }
    
    override func requestCompletePreprocessor() {
        super.requestCompletePreprocessor()
        
        if !isDataFromCache {
            // 模拟网络请求慢的情况，以便显示loading
            Thread.sleep(forTimeInterval: 0.5)
        }
    }
    
}

class TestUploadRequest: HTTPRequest {
    
    var uploadData: Any?
    var fileName: String = ""
    
    override init() {
        super.init()
        
        constructingBodyBlock = { [weak self] formData in
            if let imageData = self?.uploadData as? Data {
                formData.append(imageData, name: "files[]", fileName: self?.fileName ?? "", mimeType: Data.app.mimeType(from: Data.app.imageFormat(for: imageData)))
            } else if let videoURL = self?.uploadData as? URL {
                formData.append(videoURL, name: "files[]", fileName: self?.fileName ?? "", mimeType: Data.app.mimeType(from: "mp4"))
            }
            // 默认插件限制宽度以模拟长时间上传
            if let streamingFormData = formData as? StreamingMultipartFormData {
                streamingFormData.throttleBandwidth(withPacketSize: 1024 * 100, delay: 0.1)
            }
        }
    }
    
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
    private lazy var succeedButton: UIButton = {
        let button = AppTheme.largeButton()
        button.setTitle("Succeed Request", for: .normal)
        button.app.addTouch(target: self, action: #selector(onSucceed))
        return button
    }()
    
    private lazy var failedButton: UIButton = {
        let button = AppTheme.largeButton()
        button.setTitle("Failed Request", for: .normal)
        button.app.addTouch(target: self, action: #selector(onFailed))
        return button
    }()
    
    private lazy var cacheButton: UIButton = {
        let button = AppTheme.largeButton()
        button.setTitle("Cache Request", for: .normal)
        button.app.addTouch(target: self, action: #selector(onCache))
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadCache()
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
        view.addSubview(succeedButton)
        view.addSubview(failedButton)
        view.addSubview(cacheButton)
        view.addSubview(retryButton)
        view.addSubview(asyncButton)
        view.addSubview(syncButton)
        view.addSubview(uploadButton)
        view.addSubview(downloadButton)
        view.addSubview(observeButton)
    }
    
    func setupLayout() {
        succeedButton.app.layoutChain
            .centerX()
            .top(toSafeArea: 10)
        
        failedButton.app.layoutChain
            .centerX()
            .top(toViewBottom: succeedButton, offset: 10)
        
        cacheButton.app.layoutChain
            .centerX()
            .top(toViewBottom: failedButton, offset: 10)
        
        retryButton.app.layoutChain
            .centerX()
            .top(toViewBottom: cacheButton, offset: 10)
        
        asyncButton.app.layoutChain
            .centerX()
            .top(toViewBottom: retryButton, offset: 10)
        
        syncButton.app.layoutChain
            .centerX()
            .top(toViewBottom: asyncButton, offset: 10)
        
        uploadButton.app.layoutChain
            .centerX()
            .top(toViewBottom: syncButton, offset: 10)
        
        downloadButton.app.layoutChain
            .centerX()
            .top(toViewBottom: uploadButton, offset: 10)
        
        observeButton.app.layoutChain
            .centerX()
            .top(toViewBottom: downloadButton, offset: 10)
    }
    
}

// MARK: - Action
private extension TestRequestController {
    
    @objc func onSucceed() {
        let request: AppRequest = AppRequest.Builder()
            .requestUrl("http://kvm.wuyong.site/test.json")
            .responseSerializerType(.JSON)
            .requestTimeoutInterval(30)
            .requestCachePolicy(.reloadIgnoringLocalAndRemoteCacheData)
            .requestArgument({
                var param: [String: Any] = [:]
                param["key"] = "value"
                return param
            }())
            .requestHeaders([
                "X-Access-Key": "",
                "X-Timestamp": "",
                "X-Nonce-Data": "",
                "X-Meta-Data": "",
                "X-Sign-Data": "",
            ])
            .jsonValidator([
                "name": Validator<String>.isNotNil.anyValidator,
                "nullName": Validator<String>.isValid.anyValidator,
            ])
            .build()
        
        request
            .context(self)
            .autoShowLoading(true)
            .autoShowError(true)
            .preloadResponseModel(true)
            .safeResponseModel(of: TestModelRequest.TestModel.self, success: { [weak self] responseModel in
                var message = "json请求成功：\n" + responseModel.name
                let serverTime = request.responseServerTime
                if serverTime > 0 {
                    Date.app.currentTime = serverTime
                    message += "\n当前服务器时间：\(serverTime)"
                }
                self?.app.showMessage(text: message)
            })
            .responseError({ error in
            })
            .start()
    }
    
    @objc func onFailed() {
        let request = TestModelRequest()
        request.testFailed = true
        request.context = self
        request.autoShowLoading = true
        request.start { [weak self] (req: TestModelRequest) in
            let message = "json请求成功: \n\(req.safeResponseModel.name)"
            self?.app.showMessage(text: message)
        } failure: { [weak self] req in
            var message = "json请求失败: \n\(req.error!.localizedDescription)"
            let serverTime = req.responseServerTime
            if serverTime > 0 {
                Date.app.currentTime = serverTime
                message += "\n当前服务器时间：\(serverTime)"
            }
            self?.app.showMessage(text: message)
        }
    }
    
    private func loadCache() {
        TestCacheRequest()
            .context(self)
            .autoShowLoading(true)
            .preloadCacheModel(true)
            .responseSuccess { [weak self] (req: TestCacheRequest) in
                self?.cacheButton.setTitle(req.safeResponseModel, for: .normal)
            }
            .responseFailure { [weak self] req in
                self?.app.showMessage(error: req.error)
            }
            .start()
    }
    
    @objc func onCache() {
        TestCacheRequest()
            .context(self)
            .autoShowLoading(true)
            .autoShowError(true)
            .responseSuccess { [weak self] (req: TestCacheRequest) in
                self?.cacheButton.setTitle(req.safeResponseModel, for: .normal)
            }
            .start()
    }
    
    @objc func onRetry() {
        let request = TestWeatherRequest()
        request.context = self
        request.autoShowLoading = true
        request.autoShowError = true
        request.testFailed = true
        request.start { [weak self] (req: TestWeatherRequest) in
            guard req.isFinished else { return }
            
            self?.app.showMessage(text: "天气请求成功: \n\(req.safeResponseModel.first?.city ?? "") - \(req.safeResponseModel.first?.temp ?? "")℃")
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
            request.start { [weak self] _ in
                finishedCount += 1
                if finishedCount == requests.count {
                    self?.app.hideLoading()
                    let requestTime = Benchmark.end("async")
                    self?.app.showMessage(text: String(format: "异步请求成功：%.3fms", requestTime * 1000))
                }
            } failure: { [weak self] _ in
                finishedCount += 1
                if finishedCount == requests.count {
                    self?.app.hideLoading()
                    let requestTime = Benchmark.end("async")
                    self?.app.showMessage(text: String(format: "异步请求失败：%.3fms", requestTime * 1000))
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
            request.isSynchronously = true
            request.start { [weak self] _ in
                finishedCount += 1
                if finishedCount == requests.count {
                    self?.app.hideLoading()
                    let requestTime = Benchmark.end("sync")
                    self?.app.showMessage(text: String(format: "同步请求成功：%.3fms", requestTime * 1000))
                }
            } failure: { [weak self] _ in
                finishedCount += 1
                if finishedCount == requests.count {
                    self?.app.hideLoading()
                    let requestTime = Benchmark.end("sync")
                    self?.app.showMessage(text: String(format: "同步请求失败：%.3fms", requestTime * 1000))
                }
            }
        }
    }
    
    @objc func onUpload() {
        FileManager.app.createDirectory(atPath: testPath)
        app.showImagePicker(filterType: [.image, .video], selectionLimit: 1, allowsEditing: true) { [weak self] results, info, cancelled in
            if let image = results.first as? UIImage {
                self?.app.showProgress(0.01, text: "压缩中...")
                UIImage.app.compressDatas([image], maxWidth: 1024, maxLength: 512 * 1024) { imageDatas in
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
        let fileName = isVideo ? "upload.mp4" : "upload.jpg"
        let filePath = testPath.app.appendingPath(fileName)
        FileManager.app.removeItem(atPath: filePath)
        
        let request = TestUploadRequest()
        request.context = self
        request.uploadData = uploadData
        request.uploadProgressBlock = { [weak self] progress in
            DispatchQueue.app.mainAsync {
                self?.app.showProgress(progress.fractionCompleted, text: "上传中...")
            }
        }
        request.fileName = fileName
        request.start { [weak self] _ in
            self?.app.hideProgress()
            
            let previewUrl = "http://127.0.0.1:8001/download?" + String.app.queryEncode(["path": "/website/test/\(fileName)"])
            let previewRequest = URLRequest(url: APP.safeURL(previewUrl), cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
            let fileSize = String.app.sizeString(FileManager.app.fileSize(filePath))
            
            self?.app.showConfirm(title: "上传\(isVideo ? "视频" : "图片")成功，大小: \(fileSize)", message: "是否打开预览？", confirmBlock: {
                self?.app.showImagePreview(imageURLs: [isVideo ? filePath : previewRequest], imageInfos: nil, currentIndex: 0)
            })
        } failure: { [weak self] request in
            self?.app.hideProgress()
            
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
            let previewUrl = "http://127.0.0.1:8001/download?" + String.app.queryEncode(["path": "/website/test/\(saveName)"])
            let previewRequest = URLRequest(url: APP.safeURL(previewUrl), cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
            let filePath = request.savePath
            let fileSize = String.app.sizeString(FileManager.app.fileSize(filePath))
            
            self?.app.showConfirm(title: "下载\(isVideo ? "视频" : "图片")成功，大小: \(fileSize)", message: "是否打开预览？", confirmBlock: {
                self?.app.showImagePreview(imageURLs: [isVideo ? filePath : previewRequest], imageInfos: nil, currentIndex: 0)
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
