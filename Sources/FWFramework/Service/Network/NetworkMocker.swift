//
//  NetworkMocker.swift
//  
//
//  Created by wuyong on 2022/8/23.
//

import Foundation
#if FWMacroSPM
import FWObjC
#endif

#if DEBUG

/// The protocol which can be used to send Mocked data back. Use the `Mocker` to register `Mock` data
///
/// - see: [Mocker](https://github.com/WeTransfer/Mocker)
open class NetworkMockerURLProtocol: URLProtocol {

    enum Error: Swift.Error, LocalizedError, CustomDebugStringConvertible {
        case missingMockedData(url: String)
        case explicitMockFailure(url: String)

        var errorDescription: String? {
            return debugDescription
        }

        var debugDescription: String {
            switch self {
            case .missingMockedData(let url):
                return "Missing mock for URL: \(url)"
            case .explicitMockFailure(url: let url):
                return "Induced error for URL: \(url)"
            }
        }
    }

    private var responseWorkItem: DispatchWorkItem?

    /// Returns Mocked data based on the mocks register in the `Mocker`. Will end up in an error when no Mock data is found for the request.
    override public func startLoading() {
        guard
            let mock = NetworkMocker.mock(for: request),
            let response = HTTPURLResponse(url: mock.request.url!, statusCode: mock.statusCode, httpVersion: NetworkMocker.httpVersion.rawValue, headerFields: mock.headers),
            let data = mock.data(for: request)
        else {
            print("\n\n 🚨 No mocked data found for url \(String(describing: request.url?.absoluteString)) method \(String(describing: request.httpMethod)). Did you forget to use `register()`? 🚨 \n\n")
            client?.urlProtocol(self, didFailWithError: Error.missingMockedData(url: String(describing: request.url?.absoluteString)))
            return
        }

        if let onRequest = mock.onRequest {
            onRequest(request, request.postBodyArguments)
        }

        guard let delay = mock.delay else {
            finishRequest(for: mock, data: data, response: response)
            return
        }

        self.responseWorkItem = DispatchWorkItem(block: { [weak self] in
            guard let self = self else { return }
            self.finishRequest(for: mock, data: data, response: response)
        })

        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).asyncAfter(deadline: .now() + delay, execute: responseWorkItem!)
    }

    private func finishRequest(for mock: NetworkMock, data: Data, response: HTTPURLResponse) {
        if let redirectLocation = data.redirectLocation {
            self.client?.urlProtocol(self, wasRedirectedTo: URLRequest(url: redirectLocation), redirectResponse: response)
        } else if let requestError = mock.requestError {
            self.client?.urlProtocol(self, didFailWithError: requestError)
        } else {
            self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: mock.cacheStoragePolicy)
            self.client?.urlProtocol(self, didLoad: data)
            self.client?.urlProtocolDidFinishLoading(self)
        }

        mock.completion?()
    }

    /// Implementation does nothing, but is needed for a valid inheritance of URLProtocol.
    override public func stopLoading() {
        responseWorkItem?.cancel()
    }

    /// Simply sends back the passed request. Implementation is needed for a valid inheritance of URLProtocol.
    override public class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    /// Overrides needed to define a valid inheritance of URLProtocol.
    override public class func canInit(with request: URLRequest) -> Bool {
        return NetworkMocker.shouldHandle(request)
    }
}

private extension Data {
    /// Returns the redirect location from the raw HTTP response if exists.
    var redirectLocation: URL? {
        let locationComponent = String(data: self, encoding: String.Encoding.utf8)?.components(separatedBy: "\n").first(where: { (value) -> Bool in
            return value.contains("Location:")
        })

        guard let redirectLocationString = locationComponent?.components(separatedBy: "Location:").last, let redirectLocation = URL(string: redirectLocationString.trimmingCharacters(in: NSCharacterSet.whitespaces)) else {
            return nil
        }
        return redirectLocation
    }
}

private extension URLRequest {
    var postBodyArguments: [String: Any]? {
        guard let httpBody = httpBodyStreamData() ?? httpBody else { return nil }
        return try? JSONSerialization.jsonObject(with: httpBody, options: .fragmentsAllowed) as? [String: Any]
    }

    /// We need to use the http body stream data as the URLRequest once launched converts the `httpBody` to this stream of data.
    private func httpBodyStreamData() -> Data? {
        guard let bodyStream = self.httpBodyStream else { return nil }

        bodyStream.open()

        // Will read 16 chars per iteration. Can use bigger buffer if needed
        let bufferSize: Int = 16
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        var data = Data()

        while bodyStream.hasBytesAvailable {
            let readData = bodyStream.read(buffer, maxLength: bufferSize)
            data.append(buffer, count: readData)
        }

        buffer.deallocate()
        bodyStream.close()

        return data
    }
}

/// Can be used for registering Mocked data, returned by the `MockingURLProtocol`.
public struct NetworkMocker {
    private struct IgnoredRule: Equatable {
        let urlToIgnore: URL
        let ignoreQuery: Bool

        /// Checks if the passed URL should be ignored.
        ///
        /// - Parameter url: The URL to check for.
        /// - Returns: `true` if it should be ignored, `false` if the URL doesn't correspond to ignored rules.
        func shouldIgnore(_ url: URL) -> Bool {
            if ignoreQuery {
                return urlToIgnore.baseString == url.baseString
            }

            return urlToIgnore.absoluteString == url.absoluteString
        }
    }

    public enum HTTPVersion: String {
        case http1_0 = "HTTP/1.0"
        case http1_1 = "HTTP/1.1"
        case http2_0 = "HTTP/2.0"
    }

    /// The way Mocker handles unregistered urls
    public enum Mode {
        /// Only URLs registered with the `ignore(_ url: URL)` method are ignored for mocking.
        ///
        /// - Registered mocked URL: Mocked.
        /// - Registered ignored URL: Ignored by Mocker, default process is applied as if the Mocker doesn't exist.
        /// - Any other URL: Raises an error.
        case optout

        /// The default mode: only registered mocked URLs are mocked, all others pass through.
        ///
        /// - Registered mocked URL: Mocked.
        /// - Any other URL: Ignored by Mocker, default process is applied as if the Mocker doesn't exist.
        case optin
    }

    /// The mode defines how unknown URLs are handled. Defaults to `optin` which means requests without a mock are ignored.
    public static var mode: Mode = .optin

    /// The shared instance of the Mocker, can be used to register and return mocks.
    internal static var shared = NetworkMocker()

    /// The HTTP Version to use in the mocked response.
    public static var httpVersion: HTTPVersion = HTTPVersion.http1_1

    /// The registrated mocks.
    private(set) var mocks: [NetworkMock] = []

    /// URLs to ignore for mocking.
    public var ignoredURLs: [URL] {
        ignoredRules.map { $0.urlToIgnore }
    }

    private var ignoredRules: [IgnoredRule] = []

    /// For Thread Safety access.
    private let queue = DispatchQueue(label: "mocker.mocks.access.queue", attributes: .concurrent)

    private init() {
        // Whenever someone is requesting the Mocker, we want the URL protocol to be activated.
        _ = URLProtocol.registerClass(NetworkMockerURLProtocol.self)
    }
    
    /// Enable request  mock for NetworkAgent.
    public static func mockRequest() {
        var configuration = NetworkConfig.shared().sessionConfiguration
        if configuration == nil {
            configuration = URLSessionConfiguration.default
            NetworkConfig.shared().sessionConfiguration = configuration
        }
        
        let protocolClasses = configuration?.protocolClasses ?? []
        configuration?.protocolClasses = [NetworkMockerURLProtocol.self] + protocolClasses
    }

    /// Register new Mocked data. If a mock for the same URL and HTTPMethod exists, it will be overwritten.
    ///
    /// - Parameter mock: The Mock to be registered for future requests.
    public static func register(_ mock: NetworkMock) {
        shared.queue.async(flags: .barrier) {
            /// Delete the Mock if it was already registered.
            shared.mocks.removeAll(where: { $0 == mock })
            shared.mocks.append(mock)
        }
    }

    /// Register an URL to ignore for mocking. This will let the URL work as if the Mocker doesn't exist.
    ///
    /// - Parameter url: The URL to mock.
    /// - Parameter ignoreQuery: If `true`, checking the URL will ignore the query and match only for the scheme, host and path. Defaults to `false`.
    public static func ignore(_ url: URL, ignoreQuery: Bool = false) {
        shared.queue.async(flags: .barrier) {
            let rule = IgnoredRule(urlToIgnore: url, ignoreQuery: ignoreQuery)
            shared.ignoredRules.append(rule)
        }
    }

    /// Checks if the passed URL should be handled by the Mocker. If the URL is registered to be ignored, it will not handle the URL.
    ///
    /// - Parameter url: The URL to check for.
    /// - Returns: `true` if it should be mocked, `false` if the URL is registered as ignored.
    public static func shouldHandle(_ request: URLRequest) -> Bool {
        switch mode {
        case .optout:
            guard let url = request.url else { return false }
            return shared.queue.sync {
                !shared.ignoredRules.contains(where: { $0.shouldIgnore(url) })
            }
        case .optin:
            return mock(for: request) != nil
        }
    }

    /// Removes all registered mocks. Use this method in your tearDown function to make sure a Mock is not used in any other test.
    public static func removeAll() {
        shared.queue.sync(flags: .barrier) {
            shared.mocks.removeAll()
            shared.ignoredRules.removeAll()
        }
    }

    /// Retrieve a Mock for the given request. Matches on `request.url` and `request.httpMethod`.
    ///
    /// - Parameter request: The request to search for a mock.
    /// - Returns: A mock if found, `nil` if there's no mocked data registered for the given request.
    static func mock(for request: URLRequest) -> NetworkMock? {
        shared.queue.sync {
            /// First check for specific URLs
            if let specificMock = shared.mocks.first(where: { $0 == request && $0.fileExtensions == nil }) {
                return specificMock
            }
            /// Second, check for generic file extension Mocks
            return shared.mocks.first(where: { $0 == request })
        }
    }
}

/// A Mock which can be used for mocking data requests with the `Mocker` by calling `Mocker.register(...)`.
public struct NetworkMock: Equatable {

    /// HTTP method definitions.
    ///
    /// See https://tools.ietf.org/html/rfc7231#section-4.3
    public enum HTTPMethod: String {
        case options = "OPTIONS"
        case get     = "GET"
        case head    = "HEAD"
        case post    = "POST"
        case put     = "PUT"
        case patch   = "PATCH"
        case delete  = "DELETE"
        case trace   = "TRACE"
        case connect = "CONNECT"
    }

    /// The types of content of a request. Will be used as Content-Type header inside a `Mock`.
    public enum DataType: String {
        case json
        case html
        case imagePNG
        case pdf
        case mp4
        case zip

        var headerValue: String {
            switch self {
            case .json:
                return "application/json; charset=utf-8"
            case .html:
                return "text/html; charset=utf-8"
            case .imagePNG:
                return "image/png"
            case .pdf:
                return "application/pdf"
            case .mp4:
                return "video/mp4"
            case .zip:
                return "application/zip"
            }
        }
    }

    public typealias OnRequest = (_ request: URLRequest, _ httpBodyArguments: [String: Any]?) -> Void

    /// The type of the data which is returned.
    public let dataType: DataType

    /// If set, the error that URLProtocol will report as a result rather than returning data from the mock
    public let requestError: Error?

    /// The headers to send back with the response.
    public let headers: [String: String]

    /// The HTTP status code to return with the response.
    public let statusCode: Int

    /// The URL value generated based on the Mock data. Force unwrapped on purpose. If you access this URL while it's not set, this is a programming error.
    public var url: URL {
        if urlToMock == nil && !data.keys.contains(.get) {
            assertionFailure("For non GET mocks you should use the `request` property so the HTTP method is set.")
        }
        return urlToMock ?? generatedURL
    }

    /// The URL to mock as set implicitely from the init.
    private let urlToMock: URL?

    /// The URL generated from all the data set on this mock.
    private let generatedURL: URL

    /// The `URLRequest` to use if you did not set a specific URL.
    public let request: URLRequest

    /// If `true`, checking the URL will ignore the query and match only for the scheme, host and path.
    public let ignoreQuery: Bool

    /// The file extensions to match for.
    public let fileExtensions: [String]?

    /// The data which will be returned as the response based on the HTTP Method.
    private let data: [HTTPMethod: Data]

    /// Add a delay to a certain mock, which makes the response returned later.
    public var delay: DispatchTimeInterval?

    /// Allow response cache.
    public var cacheStoragePolicy: URLCache.StoragePolicy = .notAllowed

    /// The callback which will be executed everytime this `Mock` was completed. Can be used within unit tests for validating that a request has been executed. The callback must be set before calling `register`.
    public var completion: (() -> Void)?

    /// The callback which will be executed everytime this `Mock` was started. Can be used within unit tests for validating that a request has been started. The callback must be set before calling `register`.
    public var onRequest: OnRequest?

    private init(url: URL? = nil, ignoreQuery: Bool = false, cacheStoragePolicy: URLCache.StoragePolicy = .notAllowed, dataType: DataType, statusCode: Int, data: [HTTPMethod: Data], requestError: Error? = nil, additionalHeaders: [String: String] = [:], fileExtensions: [String]? = nil) {
        self.urlToMock = url
        let generatedURL = URL(string: "https://mocked.wetransfer.com/\(dataType.rawValue)/\(statusCode)/\(data.keys.first!.rawValue)")!
        self.generatedURL = generatedURL
        var request = URLRequest(url: url ?? generatedURL)
        request.httpMethod = data.keys.first!.rawValue
        self.request = request
        self.ignoreQuery = ignoreQuery
        self.requestError = requestError
        self.dataType = dataType
        self.statusCode = statusCode
        self.data = data
        self.cacheStoragePolicy = cacheStoragePolicy

        var headers = additionalHeaders
        headers["Content-Type"] = dataType.headerValue
        self.headers = headers

        self.fileExtensions = fileExtensions?.map({ $0.replacingOccurrences(of: ".", with: "") })
    }

    /// Creates a `Mock` for the given data type. The mock will be automatically matched based on a URL created from the given parameters.
    ///
    /// - Parameters:
    ///   - dataType: The type of the data which is returned.
    ///   - statusCode: The HTTP status code to return with the response.
    ///   - data: The data which will be returned as the response based on the HTTP Method.
    ///   - additionalHeaders: Additional headers to be added to the response.
    public init(dataType: DataType, statusCode: Int, data: [HTTPMethod: Data], additionalHeaders: [String: String] = [:]) {
        self.init(url: nil, dataType: dataType, statusCode: statusCode, data: data, additionalHeaders: additionalHeaders, fileExtensions: nil)
    }

    /// Creates a `Mock` for the given URL.
    ///
    /// - Parameters:
    ///   - url: The URL to match for and to return the mocked data for.
    ///   - ignoreQuery: If `true`, checking the URL will ignore the query and match only for the scheme, host and path. Defaults to `false`.
    ///   - cacheStoragePolicy: The caching strategy. Defaults to `notAllowed`.
    ///   - reportFailure: if `true`, the URLsession will report an error loading the URL rather than returning data. Defaults to `false`.
    ///   - dataType: The type of the data which is returned.
    ///   - statusCode: The HTTP status code to return with the response.
    ///   - data: The data which will be returned as the response based on the HTTP Method.
    ///   - additionalHeaders: Additional headers to be added to the response.
    public init(url: URL, ignoreQuery: Bool = false, cacheStoragePolicy: URLCache.StoragePolicy = .notAllowed, dataType: DataType, statusCode: Int, data: [HTTPMethod: Data], additionalHeaders: [String: String] = [:], requestError: Error? = nil) {
        self.init(url: url, ignoreQuery: ignoreQuery, cacheStoragePolicy: cacheStoragePolicy, dataType: dataType, statusCode: statusCode, data: data, requestError: requestError, additionalHeaders: additionalHeaders, fileExtensions: nil)
    }

    /// Creates a `Mock` for the given file extensions. The mock will only be used for urls matching the extension.
    ///
    /// - Parameters:
    ///   - fileExtensions: The file extension to match for.
    ///   - dataType: The type of the data which is returned.
    ///   - statusCode: The HTTP status code to return with the response.
    ///   - data: The data which will be returned as the response based on the HTTP Method.
    ///   - additionalHeaders: Additional headers to be added to the response.
    public init(fileExtensions: String..., dataType: DataType, statusCode: Int, data: [HTTPMethod: Data], additionalHeaders: [String: String] = [:]) {
        self.init(url: nil, dataType: dataType, statusCode: statusCode, data: data, additionalHeaders: additionalHeaders, fileExtensions: fileExtensions)
    }

    /// Registers the mock with the shared `Mocker`.
    public func register() {
        NetworkMocker.register(self)
    }

    /// Returns `Data` based on the HTTP Method of the passed request.
    ///
    /// - Parameter request: The request to match data for.
    /// - Returns: The `Data` which matches the request. Will be `nil` if no data is registered for the request `HTTPMethod`.
    func data(for request: URLRequest) -> Data? {
        guard let requestHTTPMethod = NetworkMock.HTTPMethod(rawValue: request.httpMethod ?? "") else { return nil }
        return data[requestHTTPMethod]
    }

    /// Used to compare the Mock data with the given `URLRequest`.
    static func == (mock: NetworkMock, request: URLRequest) -> Bool {
        guard let requestHTTPMethod = NetworkMock.HTTPMethod(rawValue: request.httpMethod ?? "") else { return false }

        if let fileExtensions = mock.fileExtensions {
            // If the mock contains a file extension, this should always be used to match for.
            guard let pathExtension = request.url?.pathExtension else { return false }
            return fileExtensions.contains(pathExtension)
        } else if mock.ignoreQuery {
            return mock.request.url!.baseString == request.url?.baseString && mock.data.keys.contains(requestHTTPMethod)
        }

        return mock.request.url!.absoluteString == request.url?.absoluteString && mock.data.keys.contains(requestHTTPMethod)
    }

    public static func == (lhs: NetworkMock, rhs: NetworkMock) -> Bool {
        let lhsHTTPMethods: [String] = lhs.data.keys.compactMap { $0.rawValue }
        let rhsHTTPMethods: [String] = rhs.data.keys.compactMap { $0.rawValue }

        if let lhsFileExtensions = lhs.fileExtensions, let rhsFileExtensions = rhs.fileExtensions, (!lhsFileExtensions.isEmpty || !rhsFileExtensions.isEmpty) {
            /// The mocks are targeting file extensions specifically, check on those.
            return lhsFileExtensions == rhsFileExtensions && lhsHTTPMethods == rhsHTTPMethods
        }

        return lhs.request.url!.absoluteString == rhs.request.url!.absoluteString && lhsHTTPMethods == rhsHTTPMethods
    }
}

extension URL {
    /// Returns the base URL string build with the scheme, host and path. "https://www.wetransfer.com/v1/test?param=test" would be "https://www.wetransfer.com/v1/test".
    var baseString: String? {
        guard let scheme = scheme, let host = host else { return nil }
        return scheme + "://" + host + path
    }
}

#endif
