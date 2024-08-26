//
//  URLRequestSerialization.swift
//  FWFramework
//
//  Created by wuyong on 2023/11/17.
//

import Foundation
import MobileCoreServices
import UIKit

public protocol URLRequestSerialization: AnyObject {
    func requestBySerializingRequest(_ request: URLRequest, parameters: Any?) throws -> URLRequest
}

public enum HTTPRequestQueryStringSerializationStyle: Int, Sendable {
    case `default` = 0
}

open class HTTPRequestSerializer: NSObject, URLRequestSerialization {
    open var stringEncoding: String.Encoding = .utf8
    open var allowsCellularAccess = true
    open var cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    open var httpShouldHandleCookies = true
    open var httpShouldUsePipelining = false
    open var networkServiceType: URLRequest.NetworkServiceType = .default
    open var timeoutInterval: TimeInterval = 60
    open var httpMethodsEncodingParametersInURI: Set<String> = ["GET", "HEAD", "DELETE"]
    open var httpRequestHeaders: [String: String] {
        var headers: [String: String] = [:]
        requestHeaderModificationQueue.sync {
            headers = self.mutableHTTPRequestHeaders
        }
        return headers
    }

    private var mutableHTTPRequestHeaders: [String: String] = [:]
    private let requestHeaderModificationQueue = DispatchQueue(label: "requestHeaderModificationQueue", attributes: .concurrent)
    private var queryStringSerializationStyle: HTTPRequestQueryStringSerializationStyle = .default
    private var queryStringSerialization: ((_ request: URLRequest, _ parameters: Any) throws -> String?)?

    override public init() {
        super.init()

        var acceptLanguagesComponents: [String] = []
        for (idx, obj) in NSLocale.preferredLanguages.enumerated() {
            let q: Float = 1.0 - (Float(idx) * 0.1)
            acceptLanguagesComponents.append(String(format: "%@;q=%0.1g", obj, q))
            if q <= 0.5 {
                break
            }
        }
        setValue(acceptLanguagesComponents.joined(separator: ", "), forHTTPHeaderField: "Accept-Language")

        let userAgent = String(format: "%@/%@ (%@; %@; iOS %@) FWFramework/%@", UIApplication.fw.appExecutable, UIApplication.fw.appVersion, UIApplication.fw.appIdentifier, UIDevice.fw.deviceModel, UIDevice.fw.iosVersionString, WrapperGlobal.version)
        setValue(userAgent, forHTTPHeaderField: "User-Agent")
    }

    open func setValue(_ value: String?, forHTTPHeaderField field: String) {
        requestHeaderModificationQueue.sync(flags: .barrier) {
            self.mutableHTTPRequestHeaders[field] = value
        }
    }

    open func value(forHTTPHeaderField field: String) -> String? {
        var value: String?
        requestHeaderModificationQueue.sync {
            value = self.mutableHTTPRequestHeaders[field]
        }
        return value
    }

    open func setAuthorizationHeaderField(username: String, password: String) {
        let basicAuthCredentials = String(format: "%@:%@", username, password).data(using: .utf8)
        let base64AuthCredentials = basicAuthCredentials?.base64EncodedString()
        setValue(String(format: "Basic %@", base64AuthCredentials ?? ""), forHTTPHeaderField: "Authorization")
    }

    open func clearAuthorizationHeader() {
        requestHeaderModificationQueue.sync(flags: .barrier) {
            _ = self.mutableHTTPRequestHeaders.removeValue(forKey: "Authorization")
        }
    }

    open func setQueryStringSerialization(style: HTTPRequestQueryStringSerializationStyle) {
        queryStringSerializationStyle = style
        queryStringSerialization = nil
    }

    open func setQueryStringSerialization(block: ((_ request: URLRequest, _ parameters: Any) throws -> String?)?) {
        queryStringSerialization = block
    }

    open func request(method: String, urlString: String, parameters: Any?) throws -> URLRequest {
        var url = URL(string: urlString)
        if url == nil, let encodeString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            url = URL(string: encodeString)
        }

        var urlRequest = URLRequest(url: url ?? URL())
        urlRequest.httpMethod = method
        urlRequest.allowsCellularAccess = allowsCellularAccess
        urlRequest.cachePolicy = cachePolicy
        urlRequest.httpShouldHandleCookies = httpShouldHandleCookies
        urlRequest.httpShouldUsePipelining = httpShouldUsePipelining
        urlRequest.networkServiceType = networkServiceType
        urlRequest.timeoutInterval = timeoutInterval

        let mutableRequest = try requestBySerializingRequest(urlRequest, parameters: parameters)
        return mutableRequest
    }

    open func multipartFormRequest(method: String, urlString: String, parameters: [String: Any]?, constructingBody block: ((MultipartFormData) -> Void)?) throws -> URLRequest {
        guard method != "GET" && method != "HEAD" else {
            throw NSError(domain: NSURLErrorDomain, code: NSURLErrorUnsupportedURL, userInfo: nil)
        }

        let mutableRequest = try request(method: method, urlString: urlString, parameters: nil)
        let formData = StreamingMultipartFormData(urlRequest: mutableRequest, stringEncoding: .utf8)

        if let parameters {
            let pairs = Self.queryStringPairs(from: parameters)
            for pair in pairs {
                var data: Data?
                if let value = pair.value as? Data {
                    data = value
                } else if pair.value is NSNull {
                    data = Data()
                } else {
                    data = String.fw.safeString(pair.value).data(using: stringEncoding)
                }

                if let data {
                    formData.appendPart(formData: data, name: String.fw.safeString(pair.field))
                }
            }
        }

        block?(formData)
        return formData.requestByFinalizingMultipartFormData()
    }

    open func request(multipartFormRequest request: URLRequest, writingStreamContentsToFile fileURL: URL, completionHandler: (@Sendable (Error?) -> Void)?) -> URLRequest? {
        guard let inputStream = request.httpBodyStream,
              fileURL.isFileURL,
              let outputStream = OutputStream(url: fileURL, append: false) else { return nil }

        let sendableError = SendableObject<Error?>(nil)
        let sendableInputStream = SendableObject(inputStream)
        let sendableOutputStream = SendableObject(outputStream)
        DispatchQueue.global(qos: .default).async {
            sendableInputStream.object.schedule(in: .current, forMode: .default)
            sendableOutputStream.object.schedule(in: .current, forMode: .default)

            sendableInputStream.object.open()
            sendableOutputStream.object.open()

            while sendableInputStream.object.hasBytesAvailable && sendableOutputStream.object.hasSpaceAvailable {
                var buffer = [UInt8](repeating: 0, count: 1024)

                let bytesRead = sendableInputStream.object.read(&buffer, maxLength: 1024)
                if sendableInputStream.object.streamError != nil || bytesRead < 0 {
                    sendableError.object = sendableInputStream.object.streamError
                    break
                }

                let bytesWritten = sendableOutputStream.object.write(buffer, maxLength: bytesRead)
                if sendableOutputStream.object.streamError != nil || bytesWritten < 0 {
                    sendableError.object = sendableOutputStream.object.streamError
                    break
                }

                if bytesRead == 0 && bytesWritten == 0 {
                    break
                }
            }

            sendableOutputStream.object.close()
            sendableInputStream.object.close()

            if completionHandler != nil {
                DispatchQueue.main.async {
                    completionHandler?(sendableError.object)
                }
            }
        }

        var mutableRequest = request
        mutableRequest.httpBodyStream = nil
        return mutableRequest
    }

    open func requestBySerializingRequest(_ request: URLRequest, parameters: Any?) throws -> URLRequest {
        var mutableRequest = request
        for (field, value) in httpRequestHeaders {
            if request.value(forHTTPHeaderField: field) == nil {
                mutableRequest.setValue(value, forHTTPHeaderField: field)
            }
        }

        var query: String?
        if let parameters {
            if queryStringSerialization != nil {
                query = try queryStringSerialization?(request, parameters)
            } else {
                switch queryStringSerializationStyle {
                case .default:
                    query = Self.queryString(from: parameters as? [AnyHashable: Any] ?? [:])
                }
            }
        }

        if httpMethodsEncodingParametersInURI.contains(request.httpMethod?.uppercased() ?? "") {
            if let query, !query.isEmpty {
                let urlString = mutableRequest.url?.absoluteString ?? ""
                mutableRequest.url = URL(string: urlString.appendingFormat(mutableRequest.url?.query != nil ? "&%@" : "?%@", query))
            }
        } else {
            if mutableRequest.value(forHTTPHeaderField: "Content-Type") == nil {
                mutableRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            }
            mutableRequest.httpBody = (query ?? "").data(using: stringEncoding)
        }

        return mutableRequest
    }
}

extension HTTPRequestSerializer {
    public static let URLRequestSerializationErrorDomain = "site.wuyong.error.serialization.request"
    public static let NetworkingOperationFailingURLRequestErrorKey = "site.wuyong.serialization.request.error.response"
    public static let UploadStream3GSuggestedPacketSize: UInt = 1024 * 16
    public static let UploadStream3GSuggestedDelay: TimeInterval = 0.2

    public static func percentEscapedString(from string: String) -> String {
        let CharactersGeneralDelimitersToEncode = ":#[]@"
        let CharactersSubDelimitersToEncode = "!$&'()*+,;="

        var allowedCharacterSet = CharacterSet.urlQueryAllowed
        allowedCharacterSet.remove(charactersIn: CharactersGeneralDelimitersToEncode + CharactersSubDelimitersToEncode)

        let batchSize = 50
        var index = 0
        var escaped = ""

        while index < string.count {
            let length = min(string.count - index, batchSize)
            let range = string.index(string.startIndex, offsetBy: index)..<string.index(string.startIndex, offsetBy: index + length)

            let substring = String(string[range])
            if let encoded = substring.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) {
                escaped.append(encoded)
            }

            index += length
        }

        return escaped
    }

    public static func queryString(from parameters: [AnyHashable: Any]) -> String {
        var mutablePairs: [String] = []
        let pairs = queryStringPairs(from: parameters)
        for pair in pairs {
            mutablePairs.append(pair.urlEncodedStringValue)
        }
        return mutablePairs.joined(separator: "&")
    }

    private static func queryStringPairs(from dictionary: [AnyHashable: Any]) -> [QueryStringPair] {
        queryStringPairs(key: nil, value: dictionary)
    }

    private static func queryStringPairs(key: String?, value: Any) -> [QueryStringPair] {
        var queryStringComponents: [QueryStringPair] = []

        if let dictionary = value as? [AnyHashable: Any] {
            let nestedKeys = dictionary.keys.map { String.fw.safeString($0) }.sorted { $0 < $1 }
            for nestedKey in nestedKeys {
                if let nestedValue = dictionary[nestedKey] {
                    queryStringComponents.append(contentsOf: queryStringPairs(key: (key != nil) ? "\(key!)[\(nestedKey)]" : nestedKey, value: nestedValue))
                }
            }
        } else if let array = value as? [Any] {
            for nestedValue in array {
                queryStringComponents.append(contentsOf: queryStringPairs(key: "\(key ?? "")[]", value: nestedValue))
            }
        } else if let set = value as? Set<AnyHashable> {
            let objs = set.sorted { String.fw.safeString($0) < String.fw.safeString($1) }
            for obj in objs {
                queryStringComponents.append(contentsOf: queryStringPairs(key: key, value: obj))
            }
        } else {
            queryStringComponents.append(QueryStringPair(field: key, value: value))
        }

        return queryStringComponents
    }

    private class QueryStringPair {
        let field: Any?
        let value: Any?

        init(field: Any?, value: Any?) {
            self.field = field
            self.value = value
        }

        var urlEncodedStringValue: String {
            if Any?.isNil(value) || value is NSNull {
                return HTTPRequestSerializer.percentEscapedString(from: String.fw.safeString(field))
            } else {
                return String(format: "%@=%@", HTTPRequestSerializer.percentEscapedString(from: String.fw.safeString(field)), HTTPRequestSerializer.percentEscapedString(from: String.fw.safeString(value)))
            }
        }
    }
}

public protocol MultipartFormData: AnyObject {
    func appendPart(fileURL: URL, name: String) throws

    func appendPart(fileURL: URL, name: String, fileName: String, mimeType: String) throws

    func appendPart(inputStream: InputStream?, length: UInt64, name: String, fileName: String, mimeType: String)

    func appendPart(fileData: Data, name: String, fileName: String, mimeType: String)

    func appendPart(formData: Data, name: String)

    func appendPart(headers: [String: String]?, body: Data)

    func appendPart(inputStream: InputStream?, length: UInt64, headers: [String: String]?)

    func throttleBandwidth(packetSize numberOfBytes: Int, delay: TimeInterval)
}

open class StreamingMultipartFormData: NSObject, MultipartFormData {
    private var request: URLRequest
    private var stringEncoding: String.Encoding
    private var boundary: String
    private var bodyStream: MultipartBodyStream

    public init(urlRequest: URLRequest, stringEncoding: String.Encoding) {
        request = urlRequest
        self.stringEncoding = stringEncoding
        boundary = Self.createMultipartFormBoundary()
        bodyStream = MultipartBodyStream(stringEncoding: stringEncoding)
        super.init()
    }

    open func requestByFinalizingMultipartFormData() -> URLRequest {
        if bodyStream.isEmpty {
            return request
        }

        bodyStream.setInitialAndFinalBoundaries()
        request.httpBodyStream = bodyStream

        request.setValue(String(format: "multipart/form-data; boundary=%@", boundary), forHTTPHeaderField: "Content-Type")
        request.setValue(String(format: "%llu", bodyStream.contentLength), forHTTPHeaderField: "Content-Length")
        return request
    }

    open func appendPart(fileURL: URL, name: String) throws {
        let fileName = fileURL.lastPathComponent
        let mimeType = Self.contentTypeForPathExtension(fileURL.pathExtension)
        try appendPart(fileURL: fileURL, name: name, fileName: fileName, mimeType: mimeType)
    }

    open func appendPart(fileURL: URL, name: String, fileName: String, mimeType: String) throws {
        if !fileURL.isFileURL {
            throw NSError(domain: HTTPRequestSerializer.URLRequestSerializationErrorDomain, code: NSURLErrorBadURL, userInfo: [NSLocalizedDescriptionKey: "Expected URL to be a file URL"])
        }

        let checkResult = try? fileURL.checkResourceIsReachable()
        if checkResult == nil || checkResult == false {
            throw NSError(domain: HTTPRequestSerializer.URLRequestSerializationErrorDomain, code: NSURLErrorBadURL, userInfo: [NSLocalizedDescriptionKey: "File URL not reachable."])
        }

        guard let fileAttributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path) else {
            throw NSError(domain: HTTPRequestSerializer.URLRequestSerializationErrorDomain, code: NSURLErrorBadURL, userInfo: [NSLocalizedDescriptionKey: "File URL not reachable."])
        }

        var headers = [String: String]()
        headers["Content-Disposition"] = String(format: "form-data; name=\"%@\"; filename=\"%@\"", name, fileName)
        headers["Content-Type"] = mimeType

        let bodyPart = HTTPBodyPart()
        bodyPart.stringEncoding = stringEncoding
        bodyPart.headers = headers
        bodyPart.boundary = boundary
        bodyPart.body = fileURL
        bodyPart.bodyContentLength = fileAttributes[.size] as? UInt64 ?? 0
        bodyStream.appendHTTPBodyPart(bodyPart)
    }

    open func appendPart(inputStream: InputStream?, length: UInt64, name: String, fileName: String, mimeType: String) {
        var headers = [String: String]()
        headers["Content-Disposition"] = String(format: "form-data; name=\"%@\"; filename=\"%@\"", name, fileName)
        headers["Content-Type"] = mimeType

        let bodyPart = HTTPBodyPart()
        bodyPart.stringEncoding = stringEncoding
        bodyPart.headers = headers
        bodyPart.boundary = boundary
        bodyPart.body = inputStream
        bodyPart.bodyContentLength = length
        bodyStream.appendHTTPBodyPart(bodyPart)
    }

    open func appendPart(fileData data: Data, name: String, fileName: String, mimeType: String) {
        var headers = [String: String]()
        headers["Content-Disposition"] = String(format: "form-data; name=\"%@\"; filename=\"%@\"", name, fileName)
        headers["Content-Type"] = mimeType

        appendPart(headers: headers, body: data)
    }

    open func appendPart(formData data: Data, name: String) {
        var headers = [String: String]()
        headers["Content-Disposition"] = String(format: "form-data; name=\"%@\"", name)

        appendPart(headers: headers, body: data)
    }

    open func appendPart(headers: [String: String]?, body: Data) {
        let bodyPart = HTTPBodyPart()
        bodyPart.stringEncoding = stringEncoding
        bodyPart.headers = headers
        bodyPart.boundary = boundary
        bodyPart.body = body
        bodyPart.bodyContentLength = UInt64(body.count)
        bodyStream.appendHTTPBodyPart(bodyPart)
    }

    open func appendPart(inputStream: InputStream?, length: UInt64, headers: [String: String]?) {
        let bodyPart = HTTPBodyPart()
        bodyPart.stringEncoding = stringEncoding
        bodyPart.headers = headers
        bodyPart.boundary = boundary
        bodyPart.body = inputStream
        bodyPart.bodyContentLength = length
        bodyStream.appendHTTPBodyPart(bodyPart)
    }

    open func throttleBandwidth(packetSize numberOfBytes: Int, delay: TimeInterval) {
        bodyStream.numberOfBytesInPacket = numberOfBytes
        bodyStream.delay = delay
    }
}

extension StreamingMultipartFormData {
    private static let multipartFormCRLF = "\r\n"

    private static func createMultipartFormBoundary() -> String {
        String(format: "Boundary+%08X%08X", arc4random(), arc4random())
    }

    private static func multipartFormInitialBoundary(_ boundary: String) -> String {
        "--\(boundary)\(multipartFormCRLF)"
    }

    private static func multipartFormEncapsulationBoundary(_ boundary: String) -> String {
        "\(multipartFormCRLF)--\(boundary)\(multipartFormCRLF)"
    }

    private static func multipartFormFinalBoundary(_ boundary: String) -> String {
        "\(multipartFormCRLF)--\(boundary)--\(multipartFormCRLF)"
    }

    private static func contentTypeForPathExtension(_ ext: String) -> String {
        if let UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, ext as CFString, nil)?.takeRetainedValue(),
           let contentType = UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType)?.takeRetainedValue() {
            return contentType as String
        }
        return "application/octet-stream"
    }

    private enum HTTPBodyPartReadPhase: Int {
        case encapsulationBoundary = 1
        case header = 2
        case body = 3
        case finalBoundary = 4
    }

    private class HTTPBodyPart: NSObject, @unchecked Sendable {
        var stringEncoding: String.Encoding = .utf8
        var headers: [String: String]?
        var boundary: String = ""
        var body: Any?
        var bodyContentLength: UInt64 = 0
        var inputStream: InputStream? {
            get {
                if _inputStream == nil {
                    if let stream = body as? InputStream {
                        _inputStream = stream
                    } else if let data = body as? Data {
                        _inputStream = InputStream(data: data)
                    } else if let url = body as? URL {
                        _inputStream = InputStream(url: url)
                    } else {
                        _inputStream = InputStream(data: Data())
                    }
                }
                return _inputStream
            }
            set {
                _inputStream = newValue
            }
        }

        private var _inputStream: InputStream?

        var hasInitialBoundary = false
        var hasFinalBoundary = false
        var hasBytesAvailable: Bool {
            if phase == .finalBoundary {
                return true
            }

            let streamStatus = inputStream?.streamStatus ?? .notOpen
            switch streamStatus {
            case .notOpen, .opening, .open, .reading, .writing:
                return true
            default:
                return false
            }
        }

        var contentLength: UInt64 {
            var length: UInt64 = 0

            let encapsulationBoundaryData = (hasInitialBoundary ? multipartFormInitialBoundary(boundary) : multipartFormEncapsulationBoundary(boundary)).data(using: stringEncoding)
            length += UInt64(encapsulationBoundaryData?.count ?? 0)

            let headersData = stringForHeaders.data(using: stringEncoding)
            length += UInt64(headersData?.count ?? 0)

            length += bodyContentLength

            let closingBoundaryData = hasFinalBoundary ? multipartFormFinalBoundary(boundary).data(using: stringEncoding) : Data()
            length += UInt64(closingBoundaryData?.count ?? 0)

            return length
        }

        private var phase: HTTPBodyPartReadPhase?
        private var phaseReadOffset: Int = 0
        private var stringForHeaders: String {
            var headerString = ""
            for (field, value) in headers ?? [:] {
                headerString.append(String(format: "%@: %@%@", field, value, StreamingMultipartFormData.multipartFormCRLF))
            }
            headerString.append(StreamingMultipartFormData.multipartFormCRLF)
            return headerString
        }

        override init() {
            super.init()
            transitionToNextPhase()
        }

        deinit {
            if _inputStream != nil {
                _inputStream?.close()
                _inputStream = nil
            }
        }

        func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength length: Int) -> Int {
            var totalNumberOfBytesRead = 0

            if phase == .encapsulationBoundary {
                let encapsulationBoundaryData = (hasInitialBoundary ? multipartFormInitialBoundary(boundary) : multipartFormEncapsulationBoundary(boundary)).data(using: stringEncoding) ?? Data()
                totalNumberOfBytesRead += readData(encapsulationBoundaryData as NSData, into: &buffer[totalNumberOfBytesRead], maxLength: length - totalNumberOfBytesRead)
            }

            if phase == .header {
                let headersData = stringForHeaders.data(using: stringEncoding) ?? Data()
                totalNumberOfBytesRead += readData(headersData as NSData, into: &buffer[totalNumberOfBytesRead], maxLength: length - totalNumberOfBytesRead)
            }

            if phase == .body {
                let numberOfBytesRead = inputStream?.read(&buffer[totalNumberOfBytesRead], maxLength: length - totalNumberOfBytesRead) ?? 0
                if numberOfBytesRead == -1 {
                    return -1
                } else {
                    totalNumberOfBytesRead += numberOfBytesRead

                    if (inputStream?.streamStatus.rawValue ?? 0) >= Stream.Status.atEnd.rawValue {
                        transitionToNextPhase()
                    }
                }
            }

            if phase == .finalBoundary {
                let closingBoundaryData = hasFinalBoundary ? (multipartFormFinalBoundary(boundary).data(using: stringEncoding) ?? Data()) : Data()
                totalNumberOfBytesRead += readData(closingBoundaryData as NSData, into: &buffer[totalNumberOfBytesRead], maxLength: length - totalNumberOfBytesRead)
            }

            return totalNumberOfBytesRead
        }

        @discardableResult
        private func transitionToNextPhase() -> Bool {
            if !Thread.isMainThread {
                DispatchQueue.main.sync {
                    _ = self.transitionToNextPhase()
                }
                return true
            }

            switch phase {
            case .encapsulationBoundary:
                phase = .header
            case .header:
                inputStream?.schedule(in: .current, forMode: .common)
                inputStream?.open()
                phase = .body
            case .body:
                inputStream?.close()
                phase = .finalBoundary
            default:
                phase = .encapsulationBoundary
            }
            phaseReadOffset = 0

            return true
        }

        private func readData(_ data: NSData, into buffer: UnsafeMutablePointer<UInt8>, maxLength length: Int) -> Int {
            let range = NSRange(location: phaseReadOffset, length: min(data.length - phaseReadOffset, length))
            data.getBytes(buffer, range: range)

            phaseReadOffset += range.length
            if phaseReadOffset >= data.length {
                transitionToNextPhase()
            }
            return range.length
        }
    }

    private class MultipartBodyStream: InputStream, StreamDelegate {
        var numberOfBytesInPacket: Int = .max
        var delay: TimeInterval = 0
        var inputStream: InputStream?
        var contentLength: UInt64 {
            var length: UInt64 = 0
            for bodyPart in httpBodyParts {
                length += bodyPart.contentLength
            }
            return length
        }

        var isEmpty: Bool { httpBodyParts.count == 0 }

        private var stringEncoding: String.Encoding = .utf8
        private var httpBodyParts: [HTTPBodyPart] = []
        private var httpBodyPartEnumerator: NSEnumerator?
        private var currentHTTPBodyPart: HTTPBodyPart?

        private var _streamStatus: Stream.Status = .notOpen
        private var _streamError: Error?

        init(stringEncoding: String.Encoding) {
            super.init(data: Data())
            self.stringEncoding = stringEncoding
        }

        func setInitialAndFinalBoundaries() {
            if httpBodyParts.count > 0 {
                for bodyPart in httpBodyParts {
                    bodyPart.hasInitialBoundary = false
                    bodyPart.hasFinalBoundary = false
                }

                httpBodyParts.first?.hasInitialBoundary = true
                httpBodyParts.last?.hasFinalBoundary = true
            }
        }

        func appendHTTPBodyPart(_ bodyPart: HTTPBodyPart) {
            httpBodyParts.append(bodyPart)
        }

        override var streamStatus: Stream.Status {
            _streamStatus
        }

        override var streamError: Error? {
            _streamError
        }

        override var hasBytesAvailable: Bool {
            streamStatus == .open
        }

        override func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength length: Int) -> Int {
            if streamStatus == .closed { return 0 }

            var totalNumberOfBytesRead = 0

            while totalNumberOfBytesRead < min(length, numberOfBytesInPacket) {
                if currentHTTPBodyPart == nil || !currentHTTPBodyPart!.hasBytesAvailable {
                    currentHTTPBodyPart = httpBodyPartEnumerator?.nextObject() as? HTTPBodyPart
                    if currentHTTPBodyPart == nil {
                        break
                    }
                } else {
                    let maxLength = min(length, numberOfBytesInPacket) - totalNumberOfBytesRead
                    let numberOfBytesRead = currentHTTPBodyPart?.read(&buffer[totalNumberOfBytesRead], maxLength: maxLength) ?? 0
                    if numberOfBytesRead == -1 {
                        _streamError = currentHTTPBodyPart?.inputStream?.streamError
                        break
                    } else {
                        totalNumberOfBytesRead += numberOfBytesRead

                        if delay > 0.0 {
                            Thread.sleep(forTimeInterval: delay)
                        }
                    }
                }
            }

            return totalNumberOfBytesRead
        }

        override func getBuffer(_ buffer: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>, length len: UnsafeMutablePointer<Int>) -> Bool {
            false
        }

        override func open() {
            if streamStatus == .open { return }
            _streamStatus = .open

            setInitialAndFinalBoundaries()
            httpBodyPartEnumerator = (httpBodyParts as NSArray).objectEnumerator()
        }

        override func close() {
            _streamStatus = .closed
        }

        override func property(forKey key: Stream.PropertyKey) -> Any? {
            nil
        }

        override func setProperty(_ property: Any?, forKey key: Stream.PropertyKey) -> Bool {
            false
        }

        override func schedule(in aRunLoop: RunLoop, forMode mode: RunLoop.Mode) {}

        override func remove(from aRunLoop: RunLoop, forMode mode: RunLoop.Mode) {}

        @objc func _scheduleInCFRunLoop(_ aRunLoop: CFRunLoop, forMode aMode: CFString) {}

        @objc func _unscheduleFromCFRunLoop(_ aRunLoop: CFRunLoop, forMode mode: CFString) {}

        @objc func _setCFClientFlags(_ inFlags: CFOptionFlags, callback: CFReadStreamClientCallBack!, context: UnsafeMutablePointer<CFStreamClientContext>) -> Bool {
            false
        }
    }
}

open class JSONRequestSerializer: HTTPRequestSerializer {
    open var writingOptions: JSONSerialization.WritingOptions = []

    override public init() {
        super.init()
    }

    public convenience init(writingOptions: JSONSerialization.WritingOptions) {
        self.init()
        self.writingOptions = writingOptions
    }

    override open func requestBySerializingRequest(_ request: URLRequest, parameters: Any?) throws -> URLRequest {
        if httpMethodsEncodingParametersInURI.contains(request.httpMethod?.uppercased() ?? "") {
            return try super.requestBySerializingRequest(request, parameters: parameters)
        }

        var mutableRequest = request
        for (field, value) in httpRequestHeaders {
            if request.value(forHTTPHeaderField: field) == nil {
                mutableRequest.setValue(value, forHTTPHeaderField: field)
            }
        }
        if mutableRequest.value(forHTTPHeaderField: "Content-Type") == nil {
            mutableRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        if let parameters {
            if !JSONSerialization.isValidJSONObject(parameters) {
                throw NSError(domain: Self.URLRequestSerializationErrorDomain, code: NSURLErrorCannotDecodeContentData, userInfo: [NSLocalizedDescriptionKey: "The `parameters` argument is not valid JSON."])
            }

            let jsonData = try JSONSerialization.data(withJSONObject: parameters, options: writingOptions)
            mutableRequest.httpBody = jsonData
        }

        return mutableRequest
    }
}

open class PropertyListRequestSerializer: HTTPRequestSerializer {
    open var format: PropertyListSerialization.PropertyListFormat = .xml
    open var writeOptions: PropertyListSerialization.WriteOptions = 0

    override public init() {
        super.init()
    }

    public convenience init(format: PropertyListSerialization.PropertyListFormat, writeOptions: PropertyListSerialization.WriteOptions) {
        self.init()
        self.format = format
        self.writeOptions = writeOptions
    }

    override open func requestBySerializingRequest(_ request: URLRequest, parameters: Any?) throws -> URLRequest {
        if httpMethodsEncodingParametersInURI.contains(request.httpMethod?.uppercased() ?? "") {
            return try super.requestBySerializingRequest(request, parameters: parameters)
        }

        var mutableRequest = request
        for (field, value) in httpRequestHeaders {
            if request.value(forHTTPHeaderField: field) == nil {
                mutableRequest.setValue(value, forHTTPHeaderField: field)
            }
        }
        if mutableRequest.value(forHTTPHeaderField: "Content-Type") == nil {
            mutableRequest.setValue("application/x-plist", forHTTPHeaderField: "Content-Type")
        }

        if let parameters {
            let plistData = try PropertyListSerialization.data(fromPropertyList: parameters, format: format, options: writeOptions)
            mutableRequest.httpBody = plistData
        }

        return mutableRequest
    }
}
