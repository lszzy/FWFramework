//
//  NetworkMocker.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import Foundation

#if DEBUG

/// The protocol which can be used to send Mocked data back. Use the `Mocker` to register `Mock` data
///
/// - see: [Mocker](https://github.com/WeTransfer/Mocker)
open class NetworkMockerURLProtocol: URLProtocol {
    enum Error: Swift.Error, LocalizedError, CustomDebugStringConvertible {
        case missingMockedData(url: String)
        case explicitMockFailure(url: String)

        var errorDescription: String? {
            debugDescription
        }

        var debugDescription: String {
            switch self {
            case let .missingMockedData(url):
                return "Missing mock for URL: \(url)"
            case let .explicitMockFailure(url: url):
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

        if let onRequestHandler = mock.onRequestHandler {
            onRequestHandler.handleRequest(request)
        }

        guard let delay = mock.delay else {
            finishRequest(for: mock, data: data, response: response)
            return
        }

        responseWorkItem = DispatchWorkItem(block: { [weak self] in
            guard let self else { return }
            finishRequest(for: mock, data: data, response: response)
        })

        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).asyncAfter(deadline: .now() + delay, execute: responseWorkItem!)
    }

    private func finishRequest(for mock: NetworkMock, data: Data, response: HTTPURLResponse) {
        if let redirectLocation = data.redirectLocation {
            client?.urlProtocol(self, wasRedirectedTo: URLRequest(url: redirectLocation), redirectResponse: response)
        } else if let requestError = mock.requestError {
            client?.urlProtocol(self, didFailWithError: requestError)
        } else {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: mock.cacheStoragePolicy)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        }

        mock.completion?()
    }

    /// Implementation does nothing, but is needed for a valid inheritance of URLProtocol.
    override public func stopLoading() {
        responseWorkItem?.cancel()
    }

    /// Simply sends back the passed request. Implementation is needed for a valid inheritance of URLProtocol.
    override public class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    /// Overrides needed to define a valid inheritance of URLProtocol.
    override public class func canInit(with request: URLRequest) -> Bool {
        NetworkMocker.shouldHandle(request)
    }
}

extension Data {
    /// Returns the redirect location from the raw HTTP response if exists.
    fileprivate var redirectLocation: URL? {
        let locationComponent = String(data: self, encoding: String.Encoding.utf8)?.components(separatedBy: "\n").first(where: { value -> Bool in
            return value.contains("Location:")
        })

        guard let redirectLocationString = locationComponent?.components(separatedBy: "Location:").last, let redirectLocation = URL(string: redirectLocationString.trimmingCharacters(in: NSCharacterSet.whitespaces)) else {
            return nil
        }
        return redirectLocation
    }
}

/// A handler for verifying outgoing requests.
public struct NetworkMockOnRequestHandler {
    public typealias OnRequest<HTTPBody> = @Sendable (_ request: URLRequest, _ httpBody: HTTPBody?) -> Void

    private let internalCallback: @Sendable (_ request: URLRequest) -> Void
    let legacyCallback: NetworkMock.OnRequest?

    /// Creates a new request handler using the given `HTTPBody` type, which can be any `Decodable`.
    /// - Parameters:
    ///   - httpBodyType: The decodable type to use for parsing the request body.
    ///   - callback: The callback which will be called just before the request executes.
    public init<HTTPBody: Decodable>(httpBodyType: HTTPBody.Type?, callback: @escaping OnRequest<HTTPBody>) {
        self.internalCallback = { request in
            guard
                let httpBody = request.httpBodyStreamData() ?? request.httpBody,
                let decodedObject = try? JSONDecoder().decode(HTTPBody.self, from: httpBody)
            else {
                callback(request, nil)
                return
            }
            callback(request, decodedObject)
        }
        self.legacyCallback = nil
    }

    /// Creates a new request handler using the given callback to call on request without parsing the body arguments.
    /// - Parameter requestCallback: The callback which will be executed just before the request executes, containing the request.
    public init(requestCallback: @escaping @Sendable (_ request: URLRequest) -> Void) {
        self.internalCallback = requestCallback
        self.legacyCallback = nil
    }

    /// Creates a new request handler using the given callback to call on request without parsing the body arguments and without passing the request.
    /// - Parameter callback: The callback which will be executed just before the request executes.
    public init(callback: @escaping @Sendable () -> Void) {
        self.internalCallback = { _ in
            callback()
        }
        self.legacyCallback = nil
    }

    /// Creates a new request handler using the given callback to call on request.
    /// - Parameter jsonDictionaryCallback: The callback that executes just before the request executes, containing the HTTP Body Arguments as a JSON Object Dictionary.
    public init(jsonDictionaryCallback: @escaping @Sendable (_ request: URLRequest, _ httpBodyArguments: [String: Any]?) -> Void) {
        self.internalCallback = { request in
            guard
                let httpBody = request.httpBodyStreamData() ?? request.httpBody,
                let jsonObject = try? JSONSerialization.jsonObject(with: httpBody, options: .fragmentsAllowed) as? [String: Any]
            else {
                jsonDictionaryCallback(request, nil)
                return
            }
            jsonDictionaryCallback(request, jsonObject)
        }
        self.legacyCallback = nil
    }

    /// Creates a new request handler using the given callback to call on request.
    /// - Parameter jsonDictionaryCallback: The callback that executes just before the request executes, containing the HTTP Body Arguments as a JSON Object Array.
    public init(jsonArrayCallback: @escaping @Sendable (_ request: URLRequest, _ httpBodyArguments: [[String: Any]]?) -> Void) {
        self.internalCallback = { request in
            guard
                let httpBody = request.httpBodyStreamData() ?? request.httpBody,
                let jsonObject = try? JSONSerialization.jsonObject(with: httpBody, options: .fragmentsAllowed) as? [[String: Any]]
            else {
                jsonArrayCallback(request, nil)
                return
            }
            jsonArrayCallback(request, jsonObject)
        }
        self.legacyCallback = nil
    }

    init(legacyCallback: NetworkMock.OnRequest?) {
        self.internalCallback = { request in
            guard
                let httpBody = request.httpBodyStreamData() ?? request.httpBody,
                let jsonObject = try? JSONSerialization.jsonObject(with: httpBody, options: .fragmentsAllowed) as? [String: Any]
            else {
                legacyCallback?(request, nil)
                return
            }
            legacyCallback?(request, jsonObject)
        }
        self.legacyCallback = legacyCallback
    }

    func handleRequest(_ request: URLRequest) {
        internalCallback(request)
    }
}

extension URLRequest {
    /// We need to use the http body stream data as the URLRequest once launched converts the `httpBody` to this stream of data.
    fileprivate func httpBodyStreamData() -> Data? {
        guard let bodyStream = httpBodyStream else { return nil }

        bodyStream.open()

        // Will read 16 chars per iteration. Can use bigger buffer if needed
        let bufferSize = 16
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
    public enum HTTPVersion: String {
        case http1_0 = "HTTP/1.0"
        case http1_1 = "HTTP/1.1"
        case http2_0 = "HTTP/2.0"
    }

    /// The way Mocker handles unregistered urls
    public enum Mode {
        /// The default mode: only URLs registered with the `ignore(_ url: URL)` method are ignored for mocking.
        ///
        /// - Registered mocked URL: Mocked.
        /// - Registered ignored URL: Ignored by Mocker, default process is applied as if the Mocker doesn't exist.
        /// - Any other URL: Raises an error.
        case optout

        /// Only registered mocked URLs are mocked, all others pass through.
        ///
        /// - Registered mocked URL: Mocked.
        /// - Any other URL: Ignored by Mocker, default process is applied as if the Mocker doesn't exist.
        case optin
    }

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

    private actor Configuration {
        static var mode: Mode = .optout
        static var shared = NetworkMocker()
        static var httpVersion: HTTPVersion = .http1_1
    }

    /// The mode defines how unknown URLs are handled. Defaults to `optout` which means requests without a mock will fail.
    public static var mode: Mode {
        get { Configuration.mode }
        set { Configuration.mode = newValue }
    }

    /// The shared instance of the Mocker, can be used to register and return mocks.
    static var shared: NetworkMocker {
        get { Configuration.shared }
        set { Configuration.shared = newValue }
    }

    /// The HTTP Version to use in the mocked response.
    public static var httpVersion: HTTPVersion {
        get { Configuration.httpVersion }
        set { Configuration.httpVersion = newValue }
    }

    /// The registrated mocks.
    private(set) var mocks: [NetworkMock] = []

    /// URLs to ignore for mocking.
    public var ignoredURLs: [URL] {
        ignoredRules.map(\.urlToIgnore)
    }

    private var ignoredRules: [IgnoredRule] = []

    /// For Thread Safety access.
    private let queue = DispatchQueue(label: "mocker.mocks.access.queue", attributes: .concurrent)

    private init() {
        // Whenever someone is requesting the Mocker, we want the URL protocol to be activated.
        _ = URLProtocol.registerClass(NetworkMockerURLProtocol.self)
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
public struct NetworkMock: Equatable, @unchecked Sendable {
    /// HTTP method definitions.
    ///
    /// See https://tools.ietf.org/html/rfc7231#section-4.3
    public enum HTTPMethod: String, Sendable {
        case options = "OPTIONS"
        case get = "GET"
        case head = "HEAD"
        case post = "POST"
        case put = "PUT"
        case patch = "PATCH"
        case delete = "DELETE"
        case trace = "TRACE"
        case connect = "CONNECT"
    }

    public typealias OnRequest = @Sendable (_ request: URLRequest, _ httpBodyArguments: [String: Any]?) -> Void

    /// The type of the data which designates the Content-Type header. If set to `nil`, no Content-Type header is added to the headers.
    public let contentType: DataType?

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
    public var completion: (@Sendable () -> Void)?

    /// The on request handler which will be executed everytime this `Mock` was started. Can be used within unit tests for validating that a request has been started. The handler must be set before calling `register`.
    public var onRequestHandler: NetworkMockOnRequestHandler?

    private init(url: URL? = nil, ignoreQuery: Bool = false, cacheStoragePolicy: URLCache.StoragePolicy = .notAllowed, contentType: DataType? = nil, statusCode: Int, data: [HTTPMethod: Data], requestError: Error? = nil, additionalHeaders: [String: String] = [:], fileExtensions: [String]? = nil) {
        guard data.count > 0 else {
            preconditionFailure("At least one entry is required in the data dictionary")
        }

        self.urlToMock = url
        let generatedURL = URL(string: "https://mocked.wetransfer.com/\(contentType?.name ?? "no-content")/\(statusCode)/\(data.keys.first!.rawValue)")!
        self.generatedURL = generatedURL
        var request = URLRequest(url: url ?? generatedURL)
        request.httpMethod = data.keys.first!.rawValue
        self.request = request
        self.ignoreQuery = ignoreQuery
        self.requestError = requestError
        self.contentType = contentType
        self.statusCode = statusCode
        self.data = data
        self.cacheStoragePolicy = cacheStoragePolicy

        var headers = additionalHeaders
        if let contentType {
            headers["Content-Type"] = contentType.headerValue
        }
        self.headers = headers

        self.fileExtensions = fileExtensions?.map { $0.replacingOccurrences(of: ".", with: "") }
    }

    /// Creates a `Mock` for the given content type. The mock will be automatically matched based on a URL created from the given parameters.
    ///
    /// - Parameters:
    ///   - contentType: The type of the data which designates the Content-Type header. Defaults to `nil`, which means that no Content-Type header is added to the headers.
    ///   - statusCode: The HTTP status code to return with the response.
    ///   - data: The data which will be returned as the response based on the HTTP Method.
    ///   - additionalHeaders: Additional headers to be added to the response.
    public init(contentType: DataType?, statusCode: Int, data: [HTTPMethod: Data], additionalHeaders: [String: String] = [:]) {
        self.init(
            url: nil,
            contentType: contentType,
            statusCode: statusCode,
            data: data,
            additionalHeaders: additionalHeaders,
            fileExtensions: nil
        )
    }

    /// Creates a `Mock` for the given URL.
    ///
    /// - Parameters:
    ///   - url: The URL to match for and to return the mocked data for.
    ///   - ignoreQuery: If `true`, checking the URL will ignore the query and match only for the scheme, host and path. Defaults to `false`.
    ///   - cacheStoragePolicy: The caching strategy. Defaults to `notAllowed`.
    ///   - contentType: The type of the data which designates the Content-Type header. Defaults to `nil`, which means that no Content-Type header is added to the headers.
    ///   - statusCode: The HTTP status code to return with the response.
    ///   - data: The data which will be returned as the response based on the HTTP Method.
    ///   - additionalHeaders: Additional headers to be added to the response.
    ///   - requestError: If provided, the URLSession will report the passed error rather than returning data. Defaults to `nil`.
    public init(url: URL, ignoreQuery: Bool = false, cacheStoragePolicy: URLCache.StoragePolicy = .notAllowed, contentType: DataType? = nil, statusCode: Int, data: [HTTPMethod: Data], additionalHeaders: [String: String] = [:], requestError: Error? = nil) {
        self.init(
            url: url,
            ignoreQuery: ignoreQuery,
            cacheStoragePolicy: cacheStoragePolicy,
            contentType: contentType,
            statusCode: statusCode,
            data: data,
            requestError: requestError,
            additionalHeaders: additionalHeaders,
            fileExtensions: nil
        )
    }

    /// Creates a `Mock` for the given file extensions. The mock will only be used for urls matching the extension.
    ///
    /// - Parameters:
    ///   - fileExtensions: The file extension to match for.
    ///   - contentType: The type of the data which designates the Content-Type header. Defaults to `nil`, which means that no Content-Type header is added to the headers.
    ///   - statusCode: The HTTP status code to return with the response.
    ///   - data: The data which will be returned as the response based on the HTTP Method.
    ///   - additionalHeaders: Additional headers to be added to the response.
    public init(fileExtensions: String..., contentType: DataType? = nil, statusCode: Int, data: [HTTPMethod: Data], additionalHeaders: [String: String] = [:]) {
        self.init(
            url: nil,
            contentType: contentType,
            statusCode: statusCode,
            data: data,
            additionalHeaders: additionalHeaders,
            fileExtensions: fileExtensions
        )
    }

    /// Creates a `Mock` for the given `URLRequest`.
    ///
    /// - Parameters:
    ///   - request: The URLRequest, from which the URL and request method is used to match for and to return the mocked data for.
    ///   - ignoreQuery: If `true`, checking the URL will ignore the query and match only for the scheme, host and path. Defaults to `false`.
    ///   - cacheStoragePolicy: The caching strategy. Defaults to `notAllowed`.
    ///   - contentType: The type of the data which designates the Content-Type header. Defaults to `nil`, which means that no Content-Type header is added to the headers.
    ///   - statusCode: The HTTP status code to return with the response.
    ///   - data: The data which will be returned as the response. Defaults to an empty `Data` instance.
    ///   - additionalHeaders: Additional headers to be added to the response.
    ///   - requestError: If provided, the URLSession will report the passed error rather than returning data. Defaults to `nil`.
    public init(request: URLRequest, ignoreQuery: Bool = false, cacheStoragePolicy: URLCache.StoragePolicy = .notAllowed, contentType: DataType? = nil, statusCode: Int, data: Data = Data(), additionalHeaders: [String: String] = [:], requestError: Error? = nil) {
        guard let requestHTTPMethod = NetworkMock.HTTPMethod(rawValue: request.httpMethod ?? "") else {
            preconditionFailure("Unexpected http method")
        }

        self.init(
            url: request.url,
            ignoreQuery: ignoreQuery,
            cacheStoragePolicy: cacheStoragePolicy,
            contentType: contentType,
            statusCode: statusCode,
            data: [requestHTTPMethod: data],
            requestError: requestError,
            additionalHeaders: additionalHeaders,
            fileExtensions: nil
        )
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
    static func ==(mock: NetworkMock, request: URLRequest) -> Bool {
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

    public static func ==(lhs: NetworkMock, rhs: NetworkMock) -> Bool {
        let lhsHTTPMethods: [String] = lhs.data.keys.compactMap { $0.rawValue }.sorted()
        let rhsHTTPMethods: [String] = rhs.data.keys.compactMap { $0.rawValue }.sorted()

        if let lhsFileExtensions = lhs.fileExtensions, let rhsFileExtensions = rhs.fileExtensions, !lhsFileExtensions.isEmpty || !rhsFileExtensions.isEmpty {
            /// The mocks are targeting file extensions specifically, check on those.
            return lhsFileExtensions == rhsFileExtensions && lhsHTTPMethods == rhsHTTPMethods
        }

        return lhs.request.url!.absoluteString == rhs.request.url!.absoluteString && lhsHTTPMethods == rhsHTTPMethods
    }
}

extension NetworkMock {
    /// The types of content of a request. Will be used as Content-Type header inside a `Mock`.
    public struct DataType: Sendable {
        /// Name of the data type.
        public let name: String

        /// The header value of the data type.
        public let headerValue: String

        public init(name: String, headerValue: String) {
            self.name = name
            self.headerValue = headerValue
        }
    }
}

extension NetworkMock.DataType {
    public static let json = NetworkMock.DataType(name: "json", headerValue: "application/json; charset=utf-8")
    public static let html = NetworkMock.DataType(name: "html", headerValue: "text/html; charset=utf-8")
    public static let imagePNG = NetworkMock.DataType(name: "imagePNG", headerValue: "image/png")
    public static let pdf = NetworkMock.DataType(name: "pdf", headerValue: "application/pdf")
    public static let mp4 = NetworkMock.DataType(name: "mp4", headerValue: "video/mp4")
    public static let zip = NetworkMock.DataType(name: "zip", headerValue: "application/zip")
}

extension URL {
    /// Returns the base URL string build with the scheme, host and path. "https://www.wetransfer.com/v1/test?param=test" would be "https://www.wetransfer.com/v1/test".
    var baseString: String? {
        guard let scheme, let host else { return nil }
        return scheme + "://" + host + path
    }
}

#endif
