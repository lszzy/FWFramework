//////////////////////////////////////////////////////////////////////////////////////////////////
//
//  WebSocket.swift
//  Starscream
//
//  Created by Dalton Cherry on 7/16/14.
//  Copyright (c) 2014-2019 Dalton Cherry.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
//////////////////////////////////////////////////////////////////////////////////////////////////

import Foundation
import CommonCrypto
import zlib

// MARK: - WebSocket
public enum ErrorType: Error {
    case compressionError
    case securityError
    case protocolError //There was an error parsing the WebSocket frames
    case serverError
}

public struct WSError: Error {
    public let type: ErrorType
    public let message: String
    public let code: UInt16
    
    public init(type: ErrorType, message: String, code: UInt16) {
        self.type = type
        self.message = message
        self.code = code
    }
}

public protocol WebSocketClient: AnyObject {
    func connect()
    func disconnect(closeCode: UInt16)
    func write(string: String, completion: (() -> ())?)
    func write(stringData: Data, completion: (() -> ())?)
    func write(data: Data, completion: (() -> ())?)
    func write(ping: Data, completion: (() -> ())?)
    func write(pong: Data, completion: (() -> ())?)
}

//implements some of the base behaviors
extension WebSocketClient {
    public func write(string: String) {
        write(string: string, completion: nil)
    }
    
    public func write(data: Data) {
        write(data: data, completion: nil)
    }
    
    public func write(ping: Data) {
        write(ping: ping, completion: nil)
    }
    
    public func write(pong: Data) {
        write(pong: pong, completion: nil)
    }
    
    public func disconnect() {
        disconnect(closeCode: CloseCode.normal.rawValue)
    }
}

public enum WebSocketEvent {
    case connected([String: String])
    case disconnected(String, UInt16)
    case text(String)
    case binary(Data)
    case pong(Data?)
    case ping(Data?)
    case error(Error?)
    case viabilityChanged(Bool)
    case reconnectSuggested(Bool)
    case cancelled
}

public protocol WebSocketDelegate: AnyObject {
    func didReceive(event: WebSocketEvent, client: WebSocketClient)
}

/// WebSocket客户端
///
/// [Starscream](https://github.com/daltoniam/Starscream)
open class WebSocket: WebSocketClient, EngineDelegate {
    private let engine: Engine
    public weak var delegate: WebSocketDelegate?
    public var onEvent: ((WebSocketEvent) -> Void)?
    
    public var request: URLRequest
    // Where the callback is executed. It defaults to the main UI thread queue.
    public var callbackQueue = DispatchQueue.main
    public var respondToPingWithPong: Bool {
        set {
            guard let e = engine as? WSEngine else { return }
            e.respondToPingWithPong = newValue
        }
        get {
            guard let e = engine as? WSEngine else { return true }
            return e.respondToPingWithPong
        }
    }
    
    public init(request: URLRequest, engine: Engine) {
        self.request = request
        self.engine = engine
    }
    
    public convenience init(request: URLRequest, certPinner: CertificatePinning? = FoundationSecurity(), compressionHandler: CompressionHandler? = nil, useCustomEngine: Bool = true) {
        if #available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *), !useCustomEngine {
            self.init(request: request, engine: NativeEngine())
        } else if #available(macOS 10.14, iOS 12.0, watchOS 5.0, tvOS 12.0, *) {
            self.init(request: request, engine: WSEngine(transport: TCPTransport(), certPinner: certPinner, compressionHandler: compressionHandler))
        } else {
            self.init(request: request, engine: WSEngine(transport: FoundationTransport(), certPinner: certPinner, compressionHandler: compressionHandler))
        }
    }
    
    public func connect() {
        engine.register(delegate: self)
        engine.start(request: request)
    }
    
    public func disconnect(closeCode: UInt16 = CloseCode.normal.rawValue) {
        engine.stop(closeCode: closeCode)
    }
    
    public func forceDisconnect() {
        engine.forceStop()
    }
    
    public func write(data: Data, completion: (() -> ())?) {
         write(data: data, opcode: .binaryFrame, completion: completion)
    }
    
    public func write(string: String, completion: (() -> ())?) {
        engine.write(string: string, completion: completion)
    }
    
    public func write(stringData: Data, completion: (() -> ())?) {
        write(data: stringData, opcode: .textFrame, completion: completion)
    }
    
    public func write(ping: Data, completion: (() -> ())?) {
        write(data: ping, opcode: .ping, completion: completion)
    }
    
    public func write(pong: Data, completion: (() -> ())?) {
        write(data: pong, opcode: .pong, completion: completion)
    }
    
    private func write(data: Data, opcode: FrameOpCode, completion: (() -> ())?) {
        engine.write(data: data, opcode: opcode, completion: completion)
    }
    
    // MARK: - EngineDelegate
    public func didReceive(event: WebSocketEvent) {
        callbackQueue.async { [weak self] in
            guard let s = self else { return }
            s.delegate?.didReceive(event: event, client: s)
            s.onEvent?(event)
        }
    }
}

// MARK: - WebSocketServer
public enum ConnectionEvent {
    case connected([String: String])
    case disconnected(String, UInt16)
    case text(String)
    case binary(Data)
    case pong(Data?)
    case ping(Data?)
    case error(Error)
}

public protocol Connection {
    func write(data: Data, opcode: FrameOpCode)
}

public protocol ConnectionDelegate: AnyObject {
    func didReceive(event: ServerEvent)
}

public enum ServerEvent {
    case connected(Connection, [String: String])
    case disconnected(Connection, String, UInt16)
    case text(Connection, String)
    case binary(Connection, Data)
    case pong(Connection, Data?)
    case ping(Connection, Data?)
}

public protocol Server {
    func start(address: String, port: UInt16) -> Error?
    func stop()
}

#if canImport(Network)
import Network

/// WebSocketServer is a Network.framework implementation of a WebSocket server
@available(watchOS, unavailable)
@available(macOS 10.14, iOS 12.0, watchOS 5.0, tvOS 12.0, *)
public class WebSocketServer: Server, ConnectionDelegate {
    public var onEvent: ((ServerEvent) -> Void)?
    public var callbackQueue = DispatchQueue.main
    private var connections = [String: ServerConnection]()
    private var listener: NWListener?
    private let queue = DispatchQueue(label: "com.vluxe.starscream.server.networkstream", attributes: [])
    
    public init() {
        
    }
    
    public func start(address: String, port: UInt16) -> Error? {
        //TODO: support TLS cert adding/binding
        let parameters = NWParameters(tls: nil, tcp: NWProtocolTCP.Options())
        let p = NWEndpoint.Port(rawValue: port)!
        parameters.requiredLocalEndpoint = NWEndpoint.hostPort(host: NWEndpoint.Host.name(address, nil), port: p)
        
        guard let listener = try? NWListener(using: parameters, on: p) else {
            return WSError(type: .serverError, message: "unable to start the listener at: \(address):\(port)", code: 0)
        }
        listener.newConnectionHandler = {[weak self] conn in
            let transport = TCPTransport(connection: conn)
            let c = ServerConnection(transport: transport)
            c.delegate = self
            self?.connections[c.uuid] = c
        }
//        listener.stateUpdateHandler = { state in
//            switch state {
//            case .ready:
//                print("ready to get sockets!")
//            case .setup:
//                print("setup to get sockets!")
//            case .cancelled:
//                print("server cancelled!")
//            case .waiting(let error):
//                print("waiting error: \(error)")
//            case .failed(let error):
//                print("server failed: \(error)")
//            @unknown default:
//                print("wat?")
//            }
//        }
        self.listener = listener
        listener.start(queue: queue)
        return nil
    }
    
    public func stop() {
        listener?.cancel()
    }
    
    public func didReceive(event: ServerEvent) {
        switch event {
        case .disconnected(let conn, _, _):
            guard let conn = conn as? ServerConnection else {
                return
            }
            connections.removeValue(forKey: conn.uuid)
        default:
            break
        }
        
        callbackQueue.async { [weak self] in
            self?.onEvent?(event)
        }
    }
}

@available(macOS 10.14, iOS 12.0, watchOS 5.0, tvOS 12.0, *)
public class ServerConnection: Connection, HTTPServerDelegate, FramerEventClient, FrameCollectorDelegate, TransportEventClient {
    let transport: TCPTransport
    private let httpHandler = FoundationHTTPServerHandler()
    private let framer = WSFramer(isServer: true)
    private let frameHandler = FrameCollector()
    private var didUpgrade = false
    public var onEvent: ((ConnectionEvent) -> Void)?
    public weak var delegate: ConnectionDelegate?
    private let id: String
    var uuid: String {
        return id
    }
    
    init(transport: TCPTransport) {
        self.id = UUID().uuidString
        self.transport = transport
        transport.register(delegate: self)
        httpHandler.register(delegate: self)
        framer.register(delegate: self)
        frameHandler.delegate = self
    }
    
    public func write(data: Data, opcode: FrameOpCode) {
        let wsData = framer.createWriteFrame(opcode: opcode, payload: data, isCompressed: false)
        transport.write(data: wsData, completion: {_ in })
    }
    
    // MARK: - TransportEventClient
    
    public func connectionChanged(state: ConnectionState) {
        switch state {
        case .connected:
            break
        case .waiting:
            break
        case .failed(let error):
            print("server connection error: \(error ?? WSError(type: .protocolError, message: "default error, no extra data", code: 0))") //handleError(error)
        case .viability(_):
            break
        case .shouldReconnect(_):
            break
        case .receive(let data):
            if didUpgrade {
                framer.add(data: data)
            } else {
                httpHandler.parse(data: data)
            }
        case .cancelled:
            print("server connection cancelled!")
            //broadcast(event: .cancelled)
        }
    }
    
    /// MARK: - HTTPServerDelegate
    
    public func didReceive(event: HTTPEvent) {
        switch event {
        case .success(let headers):
            didUpgrade = true
            let response = httpHandler.createResponse(headers: [:])
            transport.write(data: response, completion: {_ in })
            delegate?.didReceive(event: .connected(self, headers))
            onEvent?(.connected(headers))
        case .failure(let error):
            onEvent?(.error(error))
        }
    }
    
    /// MARK: - FrameCollectorDelegate
    
    public func frameProcessed(event: FrameEvent) {
        switch event {
        case .frame(let frame):
            frameHandler.add(frame: frame)
        case .error(let error):
            onEvent?(.error(error))
        }
    }
    
    public func didForm(event: FrameCollector.Event) {
        switch event {
        case .text(let string):
            delegate?.didReceive(event: .text(self, string))
            onEvent?(.text(string))
        case .binary(let data):
            delegate?.didReceive(event: .binary(self, data))
            onEvent?(.binary(data))
        case .pong(let data):
            delegate?.didReceive(event: .pong(self, data))
            onEvent?(.pong(data))
        case .ping(let data):
            delegate?.didReceive(event: .ping(self, data))
            onEvent?(.ping(data))
        case .closed(let reason, let code):
            delegate?.didReceive(event: .disconnected(self, reason, code))
            onEvent?(.disconnected(reason, code))
        case .error(let error):
            onEvent?(.error(error))
        }
    }
    
    public func decompress(data: Data, isFinal: Bool) -> Data? {
        return nil
    }
}
#endif

// MARK: - Security
public enum SecurityErrorCode: UInt16 {
    case acceptFailed = 1
    case pinningFailed = 2
}

public enum PinningState {
    case success
    case failed(CFError?)
}

// CertificatePinning protocol provides an interface for Transports to handle Certificate
// or Public Key Pinning.
public protocol CertificatePinning: AnyObject {
    func evaluateTrust(trust: SecTrust, domain: String?, completion: ((PinningState) -> ()))
}

// validates the "Sec-WebSocket-Accept" header as defined 1.3 of the RFC 6455
// https://tools.ietf.org/html/rfc6455#section-1.3
public protocol HeaderValidator: AnyObject {
    func validate(headers: [String: String], key: String) -> Error?
}

public enum FoundationSecurityError: Error {
    case invalidRequest
}

public class FoundationSecurity  {
    var allowSelfSigned = false
    
    public init(allowSelfSigned: Bool = false) {
        self.allowSelfSigned = allowSelfSigned
    }
    
    
}

extension FoundationSecurity: CertificatePinning {
    public func evaluateTrust(trust: SecTrust, domain: String?, completion: ((PinningState) -> ())) {
        if allowSelfSigned {
            completion(.success)
            return
        }
        
        SecTrustSetPolicies(trust, SecPolicyCreateSSL(true, domain as NSString?))
        
        handleSecurityTrust(trust: trust, completion: completion)
    }
    
    private func handleSecurityTrust(trust: SecTrust, completion: ((PinningState) -> ())) {
        if #available(iOS 12.0, OSX 10.14, watchOS 5.0, tvOS 12.0, *) {
            var error: CFError?
            if SecTrustEvaluateWithError(trust, &error) {
                completion(.success)
            } else {
                completion(.failed(error))
            }
        } else {
            handleOldSecurityTrust(trust: trust, completion: completion)
        }
    }
    
    private func handleOldSecurityTrust(trust: SecTrust, completion: ((PinningState) -> ())) {
        var result: SecTrustResultType = .unspecified
        SecTrustEvaluate(trust, &result)
        if result == .unspecified || result == .proceed {
            completion(.success)
        } else {
            let e = CFErrorCreate(kCFAllocatorDefault, "FoundationSecurityError" as NSString?, Int(result.rawValue), nil)
            completion(.failed(e))
        }
    }
}

extension FoundationSecurity: HeaderValidator {
    public func validate(headers: [String: String], key: String) -> Error? {
        if let acceptKey = headers[HTTPWSHeader.acceptName] {
            let sha = "\(key)258EAFA5-E914-47DA-95CA-C5AB0DC85B11".sha1Base64()
            if sha != acceptKey {
                return WSError(type: .securityError, message: "accept header doesn't match", code: SecurityErrorCode.acceptFailed.rawValue)
            }
        }
        return nil
    }
}

private extension String {
    func sha1Base64() -> String {
        let data = self.data(using: .utf8)!
        let pointer = data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> [UInt8] in
            var digest = [UInt8](repeating: 0, count:Int(CC_SHA1_DIGEST_LENGTH))
            CC_SHA1(bytes.baseAddress, CC_LONG(data.count), &digest)
            return digest
        }
        return Data(pointer).base64EncodedString()
    }
}

// MARK: - Compression
public protocol CompressionHandler {
    func load(headers: [String: String])
    func decompress(data: Data, isFinal: Bool) -> Data?
    func compress(data: Data) -> Data?
}

public class WSCompression: CompressionHandler {
    let headerWSExtensionName = "Sec-WebSocket-Extensions"
    var decompressor: Decompressor?
    var compressor: Compressor?
    var decompressorTakeOver = false
    var compressorTakeOver = false
    
    public init() {
        
    }
    
    public func load(headers: [String: String]) {
        guard let extensionHeader = headers[headerWSExtensionName] else { return }
        decompressorTakeOver = false
        compressorTakeOver = false
        
        let parts = extensionHeader.components(separatedBy: ";")
        for p in parts {
            let part = p.trimmingCharacters(in: .whitespaces)
            if part.hasPrefix("server_max_window_bits=") {
                let valString = part.components(separatedBy: "=")[1]
                if let val = Int(valString.trimmingCharacters(in: .whitespaces)) {
                    decompressor = Decompressor(windowBits: val)
                }
            } else if part.hasPrefix("client_max_window_bits=") {
                let valString = part.components(separatedBy: "=")[1]
                if let val = Int(valString.trimmingCharacters(in: .whitespaces)) {
                    compressor = Compressor(windowBits: val)
                }
            } else if part == "client_no_context_takeover" {
                compressorTakeOver = true
            } else if part == "server_no_context_takeover" {
                decompressorTakeOver = true
            }
        }
    }
    
    public func decompress(data: Data, isFinal: Bool) -> Data? {
        guard let decompressor = decompressor else { return nil }
        do {
            let decompressedData = try decompressor.decompress(data, finish: isFinal)
            if decompressorTakeOver {
                try decompressor.reset()
            }
            return decompressedData
        } catch {
            //do nothing with the error for now
        }
        return nil
    }
    
    public func compress(data: Data) -> Data? {
        guard let compressor = compressor else { return nil }
        do {
            let compressedData = try compressor.compress(data)
            if compressorTakeOver {
                try compressor.reset()
            }
            return compressedData
        } catch {
            //do nothing with the error for now
        }
        return nil
    }
    

}

class Decompressor {
    private var strm = z_stream()
    private var buffer = [UInt8](repeating: 0, count: 0x2000)
    private var inflateInitialized = false
    private let windowBits: Int

    init?(windowBits: Int) {
        self.windowBits = windowBits
        guard initInflate() else { return nil }
    }

    private func initInflate() -> Bool {
        if Z_OK == inflateInit2_(&strm, -CInt(windowBits),
                                 ZLIB_VERSION, CInt(MemoryLayout<z_stream>.size))
        {
            inflateInitialized = true
            return true
        }
        return false
    }

    func reset() throws {
        teardownInflate()
        guard initInflate() else { throw WSError(type: .compressionError, message: "Error for decompressor on reset", code: 0) }
    }

    func decompress(_ data: Data, finish: Bool) throws -> Data {
        return try data.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> Data in
            return try decompress(bytes: bytes, count: data.count, finish: finish)
        }
    }

    func decompress(bytes: UnsafePointer<UInt8>, count: Int, finish: Bool) throws -> Data {
        var decompressed = Data()
        try decompress(bytes: bytes, count: count, out: &decompressed)

        if finish {
            let tail:[UInt8] = [0x00, 0x00, 0xFF, 0xFF]
            try decompress(bytes: tail, count: tail.count, out: &decompressed)
        }

        return decompressed
    }

    private func decompress(bytes: UnsafePointer<UInt8>, count: Int, out: inout Data) throws {
        var res: CInt = 0
        strm.next_in = UnsafeMutablePointer<UInt8>(mutating: bytes)
        strm.avail_in = CUnsignedInt(count)

        repeat {
            buffer.withUnsafeMutableBytes { (bufferPtr) in
                strm.next_out = bufferPtr.bindMemory(to: UInt8.self).baseAddress
                strm.avail_out = CUnsignedInt(bufferPtr.count)

                res = inflate(&strm, 0)
            }

            let byteCount = buffer.count - Int(strm.avail_out)
            out.append(buffer, count: byteCount)
        } while res == Z_OK && strm.avail_out == 0

        guard (res == Z_OK && strm.avail_out > 0)
            || (res == Z_BUF_ERROR && Int(strm.avail_out) == buffer.count)
            else {
                throw WSError(type: .compressionError, message: "Error on decompressing", code: 0)
        }
    }

    private func teardownInflate() {
        if inflateInitialized, Z_OK == inflateEnd(&strm) {
            inflateInitialized = false
        }
    }

    deinit {
        teardownInflate()
    }
}

class Compressor {
    private var strm = z_stream()
    private var buffer = [UInt8](repeating: 0, count: 0x2000)
    private var deflateInitialized = false
    private let windowBits: Int

    init?(windowBits: Int) {
        self.windowBits = windowBits
        guard initDeflate() else { return nil }
    }

    private func initDeflate() -> Bool {
        if Z_OK == deflateInit2_(&strm, Z_DEFAULT_COMPRESSION, Z_DEFLATED,
                                 -CInt(windowBits), 8, Z_DEFAULT_STRATEGY,
                                 ZLIB_VERSION, CInt(MemoryLayout<z_stream>.size))
        {
            deflateInitialized = true
            return true
        }
        return false
    }

    func reset() throws {
        teardownDeflate()
        guard initDeflate() else { throw WSError(type: .compressionError, message: "Error for compressor on reset", code: 0) }
    }

    func compress(_ data: Data) throws -> Data {
        var compressed = Data()
        var res: CInt = 0
        data.withUnsafeBytes { (ptr:UnsafePointer<UInt8>) -> Void in
            strm.next_in = UnsafeMutablePointer<UInt8>(mutating: ptr)
            strm.avail_in = CUnsignedInt(data.count)

            repeat {
                buffer.withUnsafeMutableBytes { (bufferPtr) in
                    strm.next_out = bufferPtr.bindMemory(to: UInt8.self).baseAddress
                    strm.avail_out = CUnsignedInt(bufferPtr.count)

                    res = deflate(&strm, Z_SYNC_FLUSH)
                }

                let byteCount = buffer.count - Int(strm.avail_out)
                compressed.append(buffer, count: byteCount)
            }
            while res == Z_OK && strm.avail_out == 0

        }

        guard res == Z_OK && strm.avail_out > 0
            || (res == Z_BUF_ERROR && Int(strm.avail_out) == buffer.count)
        else {
            throw WSError(type: .compressionError, message: "Error on compressing", code: 0)
        }

        compressed.removeLast(4)
        return compressed
    }

    private func teardownDeflate() {
        if deflateInitialized, Z_OK == deflateEnd(&strm) {
            deflateInitialized = false
        }
    }

    deinit {
        teardownDeflate()
    }
}

internal extension Data {
    struct ByteError: Swift.Error {}
    
    #if swift(>=5.0)
    func withUnsafeBytes<ResultType, ContentType>(_ completion: (UnsafePointer<ContentType>) throws -> ResultType) rethrows -> ResultType {
        return try withUnsafeBytes {
            if let baseAddress = $0.baseAddress, $0.count > 0 {
                return try completion(baseAddress.assumingMemoryBound(to: ContentType.self))
            } else {
                throw ByteError()
            }
        }
    }
    #endif
    
    #if swift(>=5.0)
    mutating func withUnsafeMutableBytes<ResultType, ContentType>(_ completion: (UnsafeMutablePointer<ContentType>) throws -> ResultType) rethrows -> ResultType {
        return try withUnsafeMutableBytes {
            if let baseAddress = $0.baseAddress, $0.count > 0 {
                return try completion(baseAddress.assumingMemoryBound(to: ContentType.self))
            } else {
                throw ByteError()
            }
        }
    }
    #endif
}

// MARK: - Engine
public protocol EngineDelegate: AnyObject {
    func didReceive(event: WebSocketEvent)
}

public protocol Engine {
    func register(delegate: EngineDelegate)
    func start(request: URLRequest)
    func stop(closeCode: UInt16)
    func forceStop()
    func write(data: Data, opcode: FrameOpCode, completion: (() -> ())?)
    func write(string: String, completion: (() -> ())?)
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public class NativeEngine: NSObject, Engine, URLSessionDataDelegate, URLSessionWebSocketDelegate {
    private var task: URLSessionWebSocketTask?
    weak var delegate: EngineDelegate?

    public func register(delegate: EngineDelegate) {
        self.delegate = delegate
    }

    public func start(request: URLRequest) {
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
        task = session.webSocketTask(with: request)
        doRead()
        task?.resume()
    }

    public func stop(closeCode: UInt16) {
        let closeCode = URLSessionWebSocketTask.CloseCode(rawValue: Int(closeCode)) ?? .normalClosure
        task?.cancel(with: closeCode, reason: nil)
    }

    public func forceStop() {
        stop(closeCode: UInt16(URLSessionWebSocketTask.CloseCode.abnormalClosure.rawValue))
    }

    public func write(string: String, completion: (() -> ())?) {
        task?.send(.string(string), completionHandler: { (error) in
            completion?()
        })
    }

    public func write(data: Data, opcode: FrameOpCode, completion: (() -> ())?) {
        switch opcode {
        case .binaryFrame:
            task?.send(.data(data), completionHandler: { (error) in
                completion?()
            })
        case .textFrame:
            let text = String(data: data, encoding: .utf8)!
            write(string: text, completion: completion)
        case .ping:
            task?.sendPing(pongReceiveHandler: { (error) in
                completion?()
            })
        default:
            break //unsupported
        }
    }

    private func doRead() {
        task?.receive { [weak self] (result) in
            switch result {
            case .success(let message):
                switch message {
                case .string(let string):
                    self?.broadcast(event: .text(string))
                case .data(let data):
                    self?.broadcast(event: .binary(data))
                @unknown default:
                    break
                }
                break
            case .failure(let error):
                self?.broadcast(event: .error(error))
                return
            }
            self?.doRead()
        }
    }

    private func broadcast(event: WebSocketEvent) {
        delegate?.didReceive(event: event)
    }
    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        let p = `protocol` ?? ""
        broadcast(event: .connected([HTTPWSHeader.protocolName: p]))
    }
    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        var r = ""
        if let d = reason {
            r = String(data: d, encoding: .utf8) ?? ""
        }
        broadcast(event: .disconnected(r, UInt16(closeCode.rawValue)))
    }
}

public class WSEngine: Engine, TransportEventClient, FramerEventClient,
FrameCollectorDelegate, HTTPHandlerDelegate {
    private let transport: Transport
    private let framer: Framer
    private let httpHandler: HTTPHandler
    private let compressionHandler: CompressionHandler?
    private let certPinner: CertificatePinning?
    private let headerChecker: HeaderValidator
    private var request: URLRequest!
    
    private let frameHandler = FrameCollector()
    private var didUpgrade = false
    private var secKeyValue = ""
    private let writeQueue = DispatchQueue(label: "com.vluxe.starscream.writequeue")
    private let mutex = DispatchSemaphore(value: 1)
    private var canSend = false
    
    weak var delegate: EngineDelegate?
    public var respondToPingWithPong: Bool = true
    
    public init(transport: Transport,
                certPinner: CertificatePinning? = nil,
                headerValidator: HeaderValidator = FoundationSecurity(),
                httpHandler: HTTPHandler = FoundationHTTPHandler(),
                framer: Framer = WSFramer(),
                compressionHandler: CompressionHandler? = nil) {
        self.transport = transport
        self.framer = framer
        self.httpHandler = httpHandler
        self.certPinner = certPinner
        self.headerChecker = headerValidator
        self.compressionHandler = compressionHandler
        framer.updateCompression(supports: compressionHandler != nil)
        frameHandler.delegate = self
    }
    
    public func register(delegate: EngineDelegate) {
        self.delegate = delegate
    }
    
    public func start(request: URLRequest) {
        mutex.wait()
        let isConnected = canSend
        mutex.signal()
        if isConnected {
            return
        }
        
        self.request = request
        transport.register(delegate: self)
        framer.register(delegate: self)
        httpHandler.register(delegate: self)
        frameHandler.delegate = self
        guard let url = request.url else {
            return
        }
        transport.connect(url: url, timeout: request.timeoutInterval, certificatePinning: certPinner)
    }
    
    public func stop(closeCode: UInt16 = CloseCode.normal.rawValue) {
        let capacity = MemoryLayout<UInt16>.size
        var pointer = [UInt8](repeating: 0, count: capacity)
        writeUint16(&pointer, offset: 0, value: closeCode)
        let payload = Data(bytes: pointer, count: MemoryLayout<UInt16>.size)
        write(data: payload, opcode: .connectionClose, completion: { [weak self] in
            self?.reset()
            self?.forceStop()
        })
    }
    
    public func forceStop() {
        transport.disconnect()
    }
    
    public func write(string: String, completion: (() -> ())?) {
        let data = string.data(using: .utf8)!
        write(data: data, opcode: .textFrame, completion: completion)
    }
    
    public func write(data: Data, opcode: FrameOpCode, completion: (() -> ())?) {
        writeQueue.async { [weak self] in
            guard let s = self else { return }
            s.mutex.wait()
            let canWrite = s.canSend
            s.mutex.signal()
            if !canWrite {
                return
            }
            
            var isCompressed = false
            var sendData = data
            if let compressedData = s.compressionHandler?.compress(data: data) {
                sendData = compressedData
                isCompressed = true
            }
            
            let frameData = s.framer.createWriteFrame(opcode: opcode, payload: sendData, isCompressed: isCompressed)
            s.transport.write(data: frameData, completion: {_ in
                completion?()
            })
        }
    }
    
    // MARK: - TransportEventClient
    
    public func connectionChanged(state: ConnectionState) {
        switch state {
        case .connected:
            secKeyValue = HTTPWSHeader.generateWebSocketKey()
            let wsReq = HTTPWSHeader.createUpgrade(request: request, supportsCompression: framer.supportsCompression(), secKeyValue: secKeyValue)
            let data = httpHandler.convert(request: wsReq)
            transport.write(data: data, completion: {_ in })
        case .waiting:
            break
        case .failed(let error):
            handleError(error)
        case .viability(let isViable):
            broadcast(event: .viabilityChanged(isViable))
        case .shouldReconnect(let status):
            broadcast(event: .reconnectSuggested(status))
        case .receive(let data):
            if didUpgrade {
                framer.add(data: data)
            } else {
                let offset = httpHandler.parse(data: data)
                if offset > 0 {
                    let extraData = data.subdata(in: offset..<data.endIndex)
                    framer.add(data: extraData)
                }
            }
        case .cancelled:
            broadcast(event: .cancelled)
        }
    }
    
    // MARK: - HTTPHandlerDelegate
    
    public func didReceiveHTTP(event: HTTPEvent) {
        switch event {
        case .success(let headers):
            if let error = headerChecker.validate(headers: headers, key: secKeyValue) {
                handleError(error)
                return
            }
            mutex.wait()
            didUpgrade = true
            canSend = true
            mutex.signal()
            compressionHandler?.load(headers: headers)
            if let url = request.url {
                HTTPCookie.cookies(withResponseHeaderFields: headers, for: url).forEach {
                    HTTPCookieStorage.shared.setCookie($0)
                }
            }

            broadcast(event: .connected(headers))
        case .failure(let error):
            handleError(error)
        }
    }
    
    // MARK: - FramerEventClient
    
    public func frameProcessed(event: FrameEvent) {
        switch event {
        case .frame(let frame):
            frameHandler.add(frame: frame)
        case .error(let error):
            handleError(error)
        }
    }
    
    // MARK: - FrameCollectorDelegate
    
    public func decompress(data: Data, isFinal: Bool) -> Data? {
        return compressionHandler?.decompress(data: data, isFinal: isFinal)
    }
    
    public func didForm(event: FrameCollector.Event) {
        switch event {
        case .text(let string):
            broadcast(event: .text(string))
        case .binary(let data):
            broadcast(event: .binary(data))
        case .pong(let data):
            broadcast(event: .pong(data))
        case .ping(let data):
            broadcast(event: .ping(data))
            if respondToPingWithPong {
                write(data: data ?? Data(), opcode: .pong, completion: nil)
            }
        case .closed(let reason, let code):
            broadcast(event: .disconnected(reason, code))
            stop(closeCode: code)
        case .error(let error):
            handleError(error)
        }
    }
    
    private func broadcast(event: WebSocketEvent) {
        delegate?.didReceive(event: event)
    }
    
    //This call can be coming from a lot of different queues/threads.
    //be aware of that when modifying shared variables
    private func handleError(_ error: Error?) {
        if let wsError = error as? WSError {
            stop(closeCode: wsError.code)
        } else {
            stop()
        }
        
        delegate?.didReceive(event: .error(error))
    }
    
    private func reset() {
        mutex.wait()
        canSend = false
        didUpgrade = false
        mutex.signal()
    }
    
}

// MARK: - Transport
public enum ConnectionState {
    case connected
    case waiting
    case cancelled
    case failed(Error?)
    
    //the viability (connection status) of the connection has updated
    //e.g. connection is down, connection came back up, etc
    case viability(Bool)
    
    //the connection has upgrade to wifi from cellular.
    //you should consider reconnecting to take advantage of this
    case shouldReconnect(Bool)
    
    //the connection receive data
    case receive(Data)
}

public protocol TransportEventClient: AnyObject {
    func connectionChanged(state: ConnectionState)
}

public protocol Transport: AnyObject {
    func register(delegate: TransportEventClient)
    func connect(url: URL, timeout: Double, certificatePinning: CertificatePinning?)
    func disconnect()
    func write(data: Data, completion: @escaping ((Error?) -> ()))
    var usingTLS: Bool { get }
}

#if canImport(Network)
import Network

public enum TCPTransportError: Error {
    case invalidRequest
}

@available(macOS 10.14, iOS 12.0, watchOS 5.0, tvOS 12.0, *)
public class TCPTransport: Transport {
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "com.vluxe.starscream.networkstream", attributes: [])
    private weak var delegate: TransportEventClient?
    private var isRunning = false
    private var isTLS = false
    
    public var usingTLS: Bool {
        return self.isTLS
    }
    
    public init(connection: NWConnection) {
        self.connection = connection
        start()
    }
    
    public init() {
        //normal connection, will use the "connect" method below
    }
    
    public func connect(url: URL, timeout: Double = 10, certificatePinning: CertificatePinning? = nil) {
        guard let parts = url.getParts() else {
            delegate?.connectionChanged(state: .failed(TCPTransportError.invalidRequest))
            return
        }
        self.isTLS = parts.isTLS
        let options = NWProtocolTCP.Options()
        options.connectionTimeout = Int(timeout.rounded(.up))

        let tlsOptions = isTLS ? NWProtocolTLS.Options() : nil
        if let tlsOpts = tlsOptions {
            sec_protocol_options_set_verify_block(tlsOpts.securityProtocolOptions, { (sec_protocol_metadata, sec_trust, sec_protocol_verify_complete) in
                let trust = sec_trust_copy_ref(sec_trust).takeRetainedValue()
                guard let pinner = certificatePinning else {
                    sec_protocol_verify_complete(true)
                    return
                }
                pinner.evaluateTrust(trust: trust, domain: parts.host, completion: { (state) in
                    switch state {
                    case .success:
                        sec_protocol_verify_complete(true)
                    case .failed(_):
                        sec_protocol_verify_complete(false)
                    }
                })
            }, queue)
        }
        let parameters = NWParameters(tls: tlsOptions, tcp: options)
        let conn = NWConnection(host: NWEndpoint.Host.name(parts.host, nil), port: NWEndpoint.Port(rawValue: UInt16(parts.port))!, using: parameters)
        connection = conn
        start()
    }
    
    public func disconnect() {
        isRunning = false
        connection?.cancel()
    }
    
    public func register(delegate: TransportEventClient) {
        self.delegate = delegate
    }
    
    public func write(data: Data, completion: @escaping ((Error?) -> ())) {
        connection?.send(content: data, completion: .contentProcessed { (error) in
            completion(error)
        })
    }
    
    private func start() {
        guard let conn = connection else {
            return
        }
        conn.stateUpdateHandler = { [weak self] (newState) in
            switch newState {
            case .ready:
                self?.delegate?.connectionChanged(state: .connected)
            case .waiting:
                self?.delegate?.connectionChanged(state: .waiting)
            case .cancelled:
                self?.delegate?.connectionChanged(state: .cancelled)
            case .failed(let error):
                self?.delegate?.connectionChanged(state: .failed(error))
            case .setup, .preparing:
                break
            @unknown default:
                break
            }
        }
        
        conn.viabilityUpdateHandler = { [weak self] (isViable) in
            self?.delegate?.connectionChanged(state: .viability(isViable))
        }
        
        conn.betterPathUpdateHandler = { [weak self] (isBetter) in
            self?.delegate?.connectionChanged(state: .shouldReconnect(isBetter))
        }
        
        conn.start(queue: queue)
        isRunning = true
        readLoop()
    }
    
    //readLoop keeps reading from the connection to get the latest content
    private func readLoop() {
        if !isRunning {
            return
        }
        connection?.receive(minimumIncompleteLength: 2, maximumLength: 4096, completion: {[weak self] (data, context, isComplete, error) in
            guard let s = self else {return}
            if let data = data {
                s.delegate?.connectionChanged(state: .receive(data))
            }
            
            // Refer to https://developer.apple.com/documentation/network/implementing_netcat_with_network_framework
            if let context = context, context.isFinal, isComplete {
                return
            }
            
            if error == nil {
                s.readLoop()
            }

        })
    }
}
#else
typealias TCPTransport = FoundationTransport
#endif

public enum FoundationTransportError: Error {
    case invalidRequest
    case invalidOutputStream
    case timeout
}

public class FoundationTransport: NSObject, Transport, StreamDelegate {
    private weak var delegate: TransportEventClient?
    private let workQueue = DispatchQueue(label: "com.vluxe.starscream.websocket", attributes: [])
    private var inputStream: InputStream?
    private var outputStream: OutputStream?
    private var isOpen = false
    private var onConnect: ((InputStream, OutputStream) -> Void)?
    private var isTLS = false
    private var certPinner: CertificatePinning?
    
    public var usingTLS: Bool {
        return self.isTLS
    }
    
    public init(streamConfiguration: ((InputStream, OutputStream) -> Void)? = nil) {
        super.init()
        onConnect = streamConfiguration
    }
    
    deinit {
        inputStream?.delegate = nil
        outputStream?.delegate = nil
    }
    
    public func connect(url: URL, timeout: Double = 10, certificatePinning: CertificatePinning? = nil) {
        guard let parts = url.getParts() else {
            delegate?.connectionChanged(state: .failed(FoundationTransportError.invalidRequest))
            return
        }
        self.certPinner = certificatePinning
        self.isTLS = parts.isTLS
        var readStream: Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?
        let h = parts.host as NSString
        CFStreamCreatePairWithSocketToHost(nil, h, UInt32(parts.port), &readStream, &writeStream)
        inputStream = readStream!.takeRetainedValue()
        outputStream = writeStream!.takeRetainedValue()
        guard let inStream = inputStream, let outStream = outputStream else {
                return
        }
        inStream.delegate = self
        outStream.delegate = self
    
        if isTLS {
            let key = CFStreamPropertyKey(rawValue: kCFStreamPropertySocketSecurityLevel)
            CFReadStreamSetProperty(inStream, key, kCFStreamSocketSecurityLevelNegotiatedSSL)
            CFWriteStreamSetProperty(outStream, key, kCFStreamSocketSecurityLevelNegotiatedSSL)
        }
        
        onConnect?(inStream, outStream)
        
        isOpen = false
        CFReadStreamSetDispatchQueue(inStream, workQueue)
        CFWriteStreamSetDispatchQueue(outStream, workQueue)
        inStream.open()
        outStream.open()
        
        
        workQueue.asyncAfter(deadline: .now() + timeout, execute: { [weak self] in
            guard let s = self else { return }
            if !s.isOpen {
                s.delegate?.connectionChanged(state: .failed(FoundationTransportError.timeout))
            }
        })
    }
    
    public func disconnect() {
        if let stream = inputStream {
            stream.delegate = nil
            CFReadStreamSetDispatchQueue(stream, nil)
            stream.close()
        }
        if let stream = outputStream {
            stream.delegate = nil
            CFWriteStreamSetDispatchQueue(stream, nil)
            stream.close()
        }
        isOpen = false
        outputStream = nil
        inputStream = nil
    }
    
    public func register(delegate: TransportEventClient) {
        self.delegate = delegate
    }
    
    public func write(data: Data, completion: @escaping ((Error?) -> ())) {
        guard let outStream = outputStream else {
            completion(FoundationTransportError.invalidOutputStream)
            return
        }
        var total = 0
        let buffer = UnsafeRawPointer((data as NSData).bytes).assumingMemoryBound(to: UInt8.self)
        //NOTE: this might need to be dispatched to the work queue instead of being written inline. TBD.
        while total < data.count {
            let written = outStream.write(buffer, maxLength: data.count)
            if written < 0 {
                completion(FoundationTransportError.invalidOutputStream)
                return
            }
            total += written
        }
        completion(nil)
    }
    
    private func getSecurityData() -> (SecTrust?, String?) {
        #if os(watchOS)
        return (nil, nil)
        #else
        guard let outputStream = outputStream else {
            return (nil, nil)
        }
        let trust = outputStream.property(forKey: kCFStreamPropertySSLPeerTrust as Stream.PropertyKey) as! SecTrust?
        var domain = outputStream.property(forKey: kCFStreamSSLPeerName as Stream.PropertyKey) as! String?
        
        if domain == nil,
            let sslContextOut = CFWriteStreamCopyProperty(outputStream, CFStreamPropertyKey(rawValue: kCFStreamPropertySSLContext)) as! SSLContext? {
            var peerNameLen: Int = 0
            SSLGetPeerDomainNameLength(sslContextOut, &peerNameLen)
            var peerName = Data(count: peerNameLen)
            let _ = peerName.withUnsafeMutableBytes { (peerNamePtr: UnsafeMutablePointer<Int8>) in
                SSLGetPeerDomainName(sslContextOut, peerNamePtr, &peerNameLen)
            }
            if let peerDomain = String(bytes: peerName, encoding: .utf8), peerDomain.count > 0 {
                domain = peerDomain
            }
        }
        return (trust, domain)
        #endif
    }
    
    private func read() {
        guard let stream = inputStream else {
            return
        }
        let maxBuffer = 4096
        let buf = NSMutableData(capacity: maxBuffer)
        let buffer = UnsafeMutableRawPointer(mutating: buf!.bytes).assumingMemoryBound(to: UInt8.self)
        let length = stream.read(buffer, maxLength: maxBuffer)
        if length < 1 {
            return
        }
        let data = Data(bytes: buffer, count: length)
        delegate?.connectionChanged(state: .receive(data))
    }
    
    // MARK: - StreamDelegate
    
    open func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .hasBytesAvailable:
            if aStream == inputStream {
                read()
            }
        case .errorOccurred:
            delegate?.connectionChanged(state: .failed(aStream.streamError))
        case .endEncountered:
            if aStream == inputStream {
                delegate?.connectionChanged(state: .cancelled)
            }
        case .openCompleted:
            if aStream == inputStream {
                let (trust, domain) = getSecurityData()
                if let pinner = certPinner, let trust = trust {
                    pinner.evaluateTrust(trust: trust, domain:  domain, completion: { [weak self] (state) in
                        switch state {
                        case .success:
                            self?.isOpen = true
                            self?.delegate?.connectionChanged(state: .connected)
                        case .failed(let error):
                            self?.delegate?.connectionChanged(state: .failed(error))
                        }
                        
                    })
                } else {
                    isOpen = true
                    delegate?.connectionChanged(state: .connected)
                }
            }
        case .endEncountered:
            if aStream == inputStream {
                delegate?.connectionChanged(state: .cancelled)
            }
        default:
            break
        }
    }
}

// MARK: - Framer
let FinMask: UInt8          = 0x80
let OpCodeMask: UInt8       = 0x0F
let RSVMask: UInt8          = 0x70
let RSV1Mask: UInt8         = 0x40
let MaskMask: UInt8         = 0x80
let PayloadLenMask: UInt8   = 0x7F
let MaxFrameSize: Int       = 32

// Standard WebSocket close codes
public enum CloseCode: UInt16 {
    case normal                 = 1000
    case goingAway              = 1001
    case protocolError          = 1002
    case protocolUnhandledType  = 1003
    // 1004 reserved.
    case noStatusReceived       = 1005
    //1006 reserved.
    case encoding               = 1007
    case policyViolated         = 1008
    case messageTooBig          = 1009
}

public enum FrameOpCode: UInt8 {
    case continueFrame = 0x0
    case textFrame = 0x1
    case binaryFrame = 0x2
    // 3-7 are reserved.
    case connectionClose = 0x8
    case ping = 0x9
    case pong = 0xA
    // B-F reserved.
    case unknown = 100
}

public struct Frame {
    let isFin: Bool
    let needsDecompression: Bool
    let isMasked: Bool
    let opcode: FrameOpCode
    let payloadLength: UInt64
    let payload: Data
    let closeCode: UInt16 //only used by connectionClose opcode
}

public enum FrameEvent {
    case frame(Frame)
    case error(Error)
}

public protocol FramerEventClient: AnyObject {
    func frameProcessed(event: FrameEvent)
}

public protocol Framer {
    func add(data: Data)
    func register(delegate: FramerEventClient)
    func createWriteFrame(opcode: FrameOpCode, payload: Data, isCompressed: Bool) -> Data
    func updateCompression(supports: Bool)
    func supportsCompression() -> Bool
}

public class WSFramer: Framer {
    private let queue = DispatchQueue(label: "com.vluxe.starscream.wsframer", attributes: [])
    private weak var delegate: FramerEventClient?
    private var buffer = Data()
    public var compressionEnabled = false
    private let isServer: Bool
    
    public init(isServer: Bool = false) {
        self.isServer = isServer
    }
    
    public func updateCompression(supports: Bool) {
        compressionEnabled = supports
    }
    
    public func supportsCompression() -> Bool {
        return compressionEnabled
    }
    
    enum ProcessEvent {
        case needsMoreData
        case processedFrame(Frame, Int)
        case failed(Error)
    }
    
    public func add(data: Data) {
        queue.async { [weak self] in
            self?.buffer.append(data)
            while(true) {
               let event = self?.process() ?? .needsMoreData
                switch event {
                case .needsMoreData:
                    return
                case .processedFrame(let frame, let split):
                    guard let s = self else { return }
                    s.delegate?.frameProcessed(event: .frame(frame))
                    if split >= s.buffer.count {
                        s.buffer = Data()
                        return
                    }
                    s.buffer = s.buffer.advanced(by: split)
                case .failed(let error):
                    self?.delegate?.frameProcessed(event: .error(error))
                    self?.buffer = Data()
                    return
                }
            }
        }
    }

    public func register(delegate: FramerEventClient) {
        self.delegate = delegate
    }
    
    private func process() -> ProcessEvent {
        if buffer.count < 2 {
            return .needsMoreData
        }
        var pointer = [UInt8]()
        buffer.withUnsafeBytes { pointer.append(contentsOf: $0) }

        let isFin = (FinMask & pointer[0])
        let opcodeRawValue = (OpCodeMask & pointer[0])
        let opcode = FrameOpCode(rawValue: opcodeRawValue) ?? .unknown
        let isMasked = (MaskMask & pointer[1])
        let payloadLen = (PayloadLenMask & pointer[1])
        let RSV1 = (RSVMask & pointer[0])
        var needsDecompression = false
        
        if compressionEnabled && opcode != .continueFrame {
           needsDecompression = (RSV1Mask & pointer[0]) > 0
        }
        if !isServer && (isMasked > 0 || RSV1 > 0) && opcode != .pong && !needsDecompression {
            let errCode = CloseCode.protocolError.rawValue
            return .failed(WSError(type: .protocolError, message: "masked and rsv data is not currently supported", code: errCode))
        }
        let isControlFrame = (opcode == .connectionClose || opcode == .ping || opcode == .pong)
        if !isControlFrame && (opcode != .binaryFrame && opcode != .continueFrame &&
            opcode != .textFrame && opcode != .pong) {
            let errCode = CloseCode.protocolError.rawValue
            return .failed(WSError(type: .protocolError, message: "unknown opcode: \(opcodeRawValue)", code: errCode))
        }
        if isControlFrame && isFin == 0 {
            let errCode = CloseCode.protocolError.rawValue
            return .failed(WSError(type: .protocolError, message: "control frames can't be fragmented", code: errCode))
        }
        
        var offset = 2
    
        if isControlFrame && payloadLen > 125 {
            return .failed(WSError(type: .protocolError, message: "payload length is longer than allowed for a control frame", code: CloseCode.protocolError.rawValue))
        }
        
        var dataLength = UInt64(payloadLen)
        var closeCode = CloseCode.normal.rawValue
        if opcode == .connectionClose {
            if payloadLen == 1 {
                closeCode = CloseCode.protocolError.rawValue
                dataLength = 0
            } else if payloadLen > 1 {
                if pointer.count < 4 {
                    return .needsMoreData
                }
                let size = MemoryLayout<UInt16>.size
                closeCode = pointer.readUint16(offset: offset)
                offset += size
                dataLength -= UInt64(size)
                if closeCode < 1000 || (closeCode > 1003 && closeCode < 1007) || (closeCode > 1013 && closeCode < 3000) {
                    closeCode = CloseCode.protocolError.rawValue
                }
            }
        }
        
        if payloadLen == 127 {
             let size = MemoryLayout<UInt64>.size
            if size + offset > pointer.count {
                return .needsMoreData
            }
            dataLength = pointer.readUint64(offset: offset)
            offset += size
        } else if payloadLen == 126 {
            let size = MemoryLayout<UInt16>.size
            if size + offset > pointer.count {
                return .needsMoreData
            }
            dataLength = UInt64(pointer.readUint16(offset: offset))
            offset += size
        }
        
        let maskStart = offset
        if isServer {
            offset += MemoryLayout<UInt32>.size
        }
        
        if dataLength > (pointer.count - offset) {
            return .needsMoreData
        }
        
        //I don't like this cast, but Data's count returns an Int.
        //Might be a problem with huge payloads. Need to revisit.
        let readDataLength = Int(dataLength)
        
        let payload: Data
        if readDataLength == 0 {
            payload = Data()
        } else {
            if isServer {
                payload = pointer.unmaskData(maskStart: maskStart, offset: offset, length: readDataLength)
            } else {
                let end = offset + readDataLength
                payload = Data(pointer[offset..<end])
            }
        }
        offset += readDataLength

        let frame = Frame(isFin: isFin > 0, needsDecompression: needsDecompression, isMasked: isMasked > 0, opcode: opcode, payloadLength: dataLength, payload: payload, closeCode: closeCode)
        return .processedFrame(frame, offset)
    }
    
    public func createWriteFrame(opcode: FrameOpCode, payload: Data, isCompressed: Bool) -> Data {
        let payloadLength = payload.count
        
        let capacity = payloadLength + MaxFrameSize
        var pointer = [UInt8](repeating: 0, count: capacity)
        
        //set the framing info
        pointer[0] = FinMask | opcode.rawValue
        if isCompressed {
             pointer[0] |= RSV1Mask
        }
        
        var offset = 2 //skip pass the framing info
        if payloadLength < 126 {
            pointer[1] = UInt8(payloadLength)
        } else if payloadLength <= Int(UInt16.max) {
            pointer[1] = 126
            writeUint16(&pointer, offset: offset, value: UInt16(payloadLength))
            offset += MemoryLayout<UInt16>.size
        } else {
            pointer[1] = 127
            writeUint64(&pointer, offset: offset, value: UInt64(payloadLength))
            offset += MemoryLayout<UInt64>.size
        }
        
        //clients are required to mask the payload data, but server don't according to the RFC
        if !isServer {
            pointer[1] |= MaskMask
            
            //write the random mask key in
            let maskKey: UInt32 = UInt32.random(in: 0...UInt32.max)
            
            writeUint32(&pointer, offset: offset, value: maskKey)
            let maskStart = offset
            offset += MemoryLayout<UInt32>.size
            
            //now write the payload data in
            for i in 0..<payloadLength {
                pointer[offset] = payload[i] ^ pointer[maskStart + (i % MemoryLayout<UInt32>.size)]
                offset += 1
            }
        } else {
            for i in 0..<payloadLength {
                pointer[offset] = payload[i]
                offset += 1
            }
        }
        return Data(pointer[0..<offset])
    }
}

/// MARK: - functions for simpler array buffer reading and writing

public protocol MyWSArrayType {}
extension UInt8: MyWSArrayType {}

public extension Array where Element: MyWSArrayType & UnsignedInteger {
    
    /**
     Read a UInt16 from a buffer.
     - parameter offset: is the offset index to start the read from (e.g. buffer[0], buffer[1], etc).
     - returns: a UInt16 of the value from the buffer
     */
    func readUint16(offset: Int) -> UInt16 {
        return (UInt16(self[offset + 0]) << 8) | UInt16(self[offset + 1])
    }
    
    /**
     Read a UInt64 from a buffer.
     - parameter offset: is the offset index to start the read from (e.g. buffer[0], buffer[1], etc).
     - returns: a UInt64 of the value from the buffer
     */
    func readUint64(offset: Int) -> UInt64 {
        var value = UInt64(0)
        for i in 0...7 {
            value = (value << 8) | UInt64(self[offset + i])
        }
        return value
    }
    
    func unmaskData(maskStart: Int, offset: Int, length: Int) -> Data {
        var unmaskedBytes = [UInt8](repeating: 0, count: length)
        let maskSize = MemoryLayout<UInt32>.size
        for i in 0..<length {
            unmaskedBytes[i] = UInt8(self[offset + i] ^ self[maskStart + (i % maskSize)])
        }
        return Data(unmaskedBytes)
    }
}

/**
 Write a UInt16 to the buffer. It fills the 2 array "slots" of the UInt8 array.
 - parameter buffer: is the UInt8 array (pointer) to write the value too.
 - parameter offset: is the offset index to start the write from (e.g. buffer[0], buffer[1], etc).
 */
public func writeUint16( _ buffer: inout [UInt8], offset: Int, value: UInt16) {
    buffer[offset + 0] = UInt8(value >> 8)
    buffer[offset + 1] = UInt8(value & 0xff)
}

/**
 Write a UInt32 to the buffer. It fills the 4 array "slots" of the UInt8 array.
 - parameter buffer: is the UInt8 array (pointer) to write the value too.
 - parameter offset: is the offset index to start the write from (e.g. buffer[0], buffer[1], etc).
 */
public func writeUint32( _ buffer: inout [UInt8], offset: Int, value: UInt32) {
    for i in 0...3 {
        buffer[offset + i] = UInt8((value >> (8*UInt32(3 - i))) & 0xff)
    }
}

/**
 Write a UInt64 to the buffer. It fills the 8 array "slots" of the UInt8 array.
 - parameter buffer: is the UInt8 array (pointer) to write the value too.
 - parameter offset: is the offset index to start the write from (e.g. buffer[0], buffer[1], etc).
 */
public func writeUint64( _ buffer: inout [UInt8], offset: Int, value: UInt64) {
    for i in 0...7 {
        buffer[offset + i] = UInt8((value >> (8*UInt64(7 - i))) & 0xff)
    }
}

public protocol FrameCollectorDelegate: AnyObject {
    func didForm(event: FrameCollector.Event)
    func decompress(data: Data, isFinal: Bool) -> Data?
}

public class FrameCollector {
    public enum Event {
        case text(String)
        case binary(Data)
        case pong(Data?)
        case ping(Data?)
        case error(Error)
        case closed(String, UInt16)
    }
    weak var delegate: FrameCollectorDelegate?
    var buffer = Data()
    var frameCount = 0
    var isText = false //was the first frame a text frame or a binary frame?
    var needsDecompression = false
    
    public func add(frame: Frame) {
        //check single frame action and out of order frames
        if frame.opcode == .connectionClose {
            var code = frame.closeCode
            var reason = "connection closed by server"
            if let customCloseReason = String(data: frame.payload, encoding: .utf8) {
                reason = customCloseReason
            } else {
                code = CloseCode.protocolError.rawValue
            }
            delegate?.didForm(event: .closed(reason, code))
            return
        } else if frame.opcode == .pong {
            delegate?.didForm(event: .pong(frame.payload))
            return
        } else if frame.opcode == .ping {
            delegate?.didForm(event: .ping(frame.payload))
            return
        } else if frame.opcode == .continueFrame && frameCount == 0 {
            let errCode = CloseCode.protocolError.rawValue
            delegate?.didForm(event: .error(WSError(type: .protocolError, message: "first frame can't be a continue frame", code: errCode)))
            reset()
            return
        } else if frameCount > 0 && frame.opcode != .continueFrame {
            let errCode = CloseCode.protocolError.rawValue
            delegate?.didForm(event: .error(WSError(type: .protocolError, message: "second and beyond of fragment message must be a continue frame", code: errCode)))
            reset()
            return
        }
        if frameCount == 0 {
            isText = frame.opcode == .textFrame
            needsDecompression = frame.needsDecompression
        }
        
        let payload: Data
        if needsDecompression {
            payload = delegate?.decompress(data: frame.payload, isFinal: frame.isFin) ?? frame.payload
        } else {
            payload = frame.payload
        }
        buffer.append(payload)
        frameCount += 1

        if frame.isFin {
            if isText {
                if let string = String(data: buffer, encoding: .utf8) {
                    delegate?.didForm(event: .text(string))
                } else {
                    let errCode = CloseCode.protocolError.rawValue
                    delegate?.didForm(event: .error(WSError(type: .protocolError, message: "not valid UTF-8 data", code: errCode)))
                }
            } else {
                delegate?.didForm(event: .binary(buffer))
            }
            reset()
        }
    }
    
    func reset() {
        buffer = Data()
        frameCount = 0
    }
}

public enum HTTPUpgradeError: Error {
    case notAnUpgrade(Int, [String: String])
    case invalidData
}

public struct HTTPWSHeader {
    static let upgradeName        = "Upgrade"
    static let upgradeValue       = "websocket"
    static let hostName           = "Host"
    static let connectionName     = "Connection"
    static let connectionValue    = "Upgrade"
    static let protocolName       = "Sec-WebSocket-Protocol"
    static let versionName        = "Sec-WebSocket-Version"
    static let versionValue       = "13"
    static let extensionName      = "Sec-WebSocket-Extensions"
    static let keyName            = "Sec-WebSocket-Key"
    static let originName         = "Origin"
    static let acceptName         = "Sec-WebSocket-Accept"
    static let switchProtocolCode = 101
    static let defaultSSLSchemes  = ["wss", "https"]
    
    /// Creates a new URLRequest based off the source URLRequest.
    /// - Parameter request: the request to "upgrade" the WebSocket request by adding headers.
    /// - Parameter supportsCompression: set if the client support text compression.
    /// - Parameter secKeyName: the security key to use in the WebSocket request. https://tools.ietf.org/html/rfc6455#section-1.3
    /// - returns: A URLRequest request to be converted to data and sent to the server.
    public static func createUpgrade(request: URLRequest, supportsCompression: Bool, secKeyValue: String) -> URLRequest {
        guard let url = request.url, let parts = url.getParts() else {
            return request
        }
        
        var req = request
        if request.value(forHTTPHeaderField: HTTPWSHeader.originName) == nil {
            var origin = url.absoluteString
            if let hostUrl = URL (string: "/", relativeTo: url) {
                origin = hostUrl.absoluteString
                origin.remove(at: origin.index(before: origin.endIndex))
            }
            req.setValue(origin, forHTTPHeaderField: HTTPWSHeader.originName)
        }
        req.setValue(HTTPWSHeader.upgradeValue, forHTTPHeaderField: HTTPWSHeader.upgradeName)
        req.setValue(HTTPWSHeader.connectionValue, forHTTPHeaderField: HTTPWSHeader.connectionName)
        req.setValue(HTTPWSHeader.versionValue, forHTTPHeaderField: HTTPWSHeader.versionName)
        req.setValue(secKeyValue, forHTTPHeaderField: HTTPWSHeader.keyName)
        
        if let cookies = HTTPCookieStorage.shared.cookies(for: url), !cookies.isEmpty {
            let headers = HTTPCookie.requestHeaderFields(with: cookies)
            for (key, val) in headers {
                req.setValue(val, forHTTPHeaderField: key)
            }
        }
        
        if supportsCompression {
            let val = "permessage-deflate; client_max_window_bits; server_max_window_bits=15"
            req.setValue(val, forHTTPHeaderField: HTTPWSHeader.extensionName)
        }
        let hostValue = req.allHTTPHeaderFields?[HTTPWSHeader.hostName] ?? "\(parts.host):\(parts.port)"
        req.setValue(hostValue, forHTTPHeaderField: HTTPWSHeader.hostName)
        return req
    }
    
    // generateWebSocketKey 16 random characters between a-z and return them as a base64 string
    public static func generateWebSocketKey() -> String {
        return Data((0..<16).map{ _ in UInt8.random(in: 97...122) }).base64EncodedString()
    }
}

public enum HTTPEvent {
    case success([String: String])
    case failure(Error)
}

public protocol HTTPHandlerDelegate: AnyObject {
    func didReceiveHTTP(event: HTTPEvent)
}

public protocol HTTPHandler {
    func register(delegate: HTTPHandlerDelegate)
    func convert(request: URLRequest) -> Data
    func parse(data: Data) -> Int
}

public protocol HTTPServerDelegate: AnyObject {
    func didReceive(event: HTTPEvent)
}

public protocol HTTPServerHandler {
    func register(delegate: HTTPServerDelegate)
    func parse(data: Data)
    func createResponse(headers: [String: String]) -> Data
}

public struct URLParts {
    let port: Int
    let host: String
    let isTLS: Bool
}

public extension URL {
    /// isTLSScheme returns true if the scheme is https or wss
    var isTLSScheme: Bool {
        guard let scheme = self.scheme else {
            return false
        }
        return HTTPWSHeader.defaultSSLSchemes.contains(scheme)
    }
    
    /// getParts pulls host and port from the url.
    func getParts() -> URLParts? {
        guard let host = self.host else {
            return nil // no host, this isn't a valid url
        }
        let isTLS = isTLSScheme
        var port = self.port ?? 0
        if self.port == nil {
            if isTLS {
                port = 443
            } else {
                port = 80
            }
        }
        return URLParts(port: port, host: host, isTLS: isTLS)
    }
}

#if os(watchOS)
public typealias FoundationHTTPHandler = StringHTTPHandler
#else
public class FoundationHTTPHandler: HTTPHandler {

    var buffer = Data()
    weak var delegate: HTTPHandlerDelegate?
    
    public init() {
        
    }
    
    public func convert(request: URLRequest) -> Data {
        let msg = CFHTTPMessageCreateRequest(kCFAllocatorDefault, request.httpMethod! as CFString,
                                             request.url! as CFURL, kCFHTTPVersion1_1).takeRetainedValue()
        if let headers = request.allHTTPHeaderFields {
            for (aKey, aValue) in headers {
                CFHTTPMessageSetHeaderFieldValue(msg, aKey as CFString, aValue as CFString)
            }
        }
        if let body = request.httpBody {
            CFHTTPMessageSetBody(msg, body as CFData)
        }
        guard let data = CFHTTPMessageCopySerializedMessage(msg) else {
            return Data()
        }
        return data.takeRetainedValue() as Data
    }
    
    public func parse(data: Data) -> Int {
        let offset = findEndOfHTTP(data: data)
        if offset > 0 {
            buffer.append(data.subdata(in: 0..<offset))
        } else {
            buffer.append(data)
        }
        if parseContent(data: buffer) {
            buffer = Data()
        }
        return offset
    }
    
    //returns true when the buffer should be cleared
    func parseContent(data: Data) -> Bool {
        var pointer = [UInt8]()
        data.withUnsafeBytes { pointer.append(contentsOf: $0) }

        let response = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, false).takeRetainedValue()
        if !CFHTTPMessageAppendBytes(response, pointer, data.count) {
            return false //not enough data, wait for more
        }
        if !CFHTTPMessageIsHeaderComplete(response) {
            return false //not enough data, wait for more
        }
        
        if let cfHeaders = CFHTTPMessageCopyAllHeaderFields(response) {
            let nsHeaders = cfHeaders.takeRetainedValue() as NSDictionary
            var headers = [String: String]()
            for (key, value) in nsHeaders {
                if let key = key as? String, let value = value as? String {
                    headers[key] = value
                }
            }
            
            let code = CFHTTPMessageGetResponseStatusCode(response)
            if code != HTTPWSHeader.switchProtocolCode {
                delegate?.didReceiveHTTP(event: .failure(HTTPUpgradeError.notAnUpgrade(code, headers)))
                return true
            }
            
            delegate?.didReceiveHTTP(event: .success(headers))
            return true
        }
        
        delegate?.didReceiveHTTP(event: .failure(HTTPUpgradeError.invalidData))
        return true
    }
    
    public func register(delegate: HTTPHandlerDelegate) {
        self.delegate = delegate
    }
    
    private func findEndOfHTTP(data: Data) -> Int {
        let endBytes = [UInt8(ascii: "\r"), UInt8(ascii: "\n"), UInt8(ascii: "\r"), UInt8(ascii: "\n")]
        var pointer = [UInt8]()
        data.withUnsafeBytes { pointer.append(contentsOf: $0) }
        var k = 0
        for i in 0..<data.count {
            if pointer[i] == endBytes[k] {
                k += 1
                if k == 4 {
                    return i + 1
                }
            } else {
                k = 0
            }
        }
        return -1
    }
}
#endif

public class FoundationHTTPServerHandler: HTTPServerHandler {
    var buffer = Data()
    weak var delegate: HTTPServerDelegate?
    let getVerb: NSString = "GET"
    
    public func register(delegate: HTTPServerDelegate) {
        self.delegate = delegate
    }
    
    public func createResponse(headers: [String: String]) -> Data {
        #if os(watchOS)
        //TODO: build response header
        return Data()
        #else
        let response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, HTTPWSHeader.switchProtocolCode,
                                                   nil, kCFHTTPVersion1_1).takeRetainedValue()
        
        //TODO: add other values to make a proper response here...
        //TODO: also sec key thing (Sec-WebSocket-Key)
        for (key, value) in headers {
            CFHTTPMessageSetHeaderFieldValue(response, key as CFString, value as CFString)
        }
        guard let cfData = CFHTTPMessageCopySerializedMessage(response)?.takeRetainedValue() else {
            return Data()
        }
        return cfData as Data
        #endif
    }
    
    public func parse(data: Data) {
        buffer.append(data)
        if parseContent(data: buffer) {
            buffer = Data()
        }
    }
    
    //returns true when the buffer should be cleared
    func parseContent(data: Data) -> Bool {
        var pointer = [UInt8]()
        data.withUnsafeBytes { pointer.append(contentsOf: $0) }
        #if os(watchOS)
        //TODO: parse data
        return false
        #else
        let response = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, true).takeRetainedValue()
        if !CFHTTPMessageAppendBytes(response, pointer, data.count) {
            return false //not enough data, wait for more
        }
        if !CFHTTPMessageIsHeaderComplete(response) {
            return false //not enough data, wait for more
        }
        if let method = CFHTTPMessageCopyRequestMethod(response)?.takeRetainedValue() {
            if (method as NSString) != getVerb {
                delegate?.didReceive(event: .failure(HTTPUpgradeError.invalidData))
                return true
            }
        }
        
        if let cfHeaders = CFHTTPMessageCopyAllHeaderFields(response) {
            let nsHeaders = cfHeaders.takeRetainedValue() as NSDictionary
            var headers = [String: String]()
            for (key, value) in nsHeaders {
                if let key = key as? String, let value = value as? String {
                    headers[key] = value
                }
            }
            delegate?.didReceive(event: .success(headers))
            return true
        }
        
        delegate?.didReceive(event: .failure(HTTPUpgradeError.invalidData))
        return true
        #endif
    }
}

public class StringHTTPHandler: HTTPHandler {
    
    var buffer = Data()
    weak var delegate: HTTPHandlerDelegate?
    
    public init() {
        
    }
    
    public func convert(request: URLRequest) -> Data {
        guard let url = request.url else {
            return Data()
        }
        
        var path = url.absoluteString
        let offset = (url.scheme?.count ?? 2) + 3
        path = String(path[path.index(path.startIndex, offsetBy: offset)..<path.endIndex])
        if let range = path.range(of: "/") {
            path = String(path[range.lowerBound..<path.endIndex])
        } else {
            path = "/"
            if let query = url.query {
                path += "?" + query
            }
        }
        
        var httpBody = "\(request.httpMethod ?? "GET") \(path) HTTP/1.1\r\n"
        if let headers = request.allHTTPHeaderFields {
            for (key, val) in headers {
                httpBody += "\(key): \(val)\r\n"
            }
        }
        httpBody += "\r\n"
        
        guard var data = httpBody.data(using: .utf8) else {
            return Data()
        }
        
        if let body = request.httpBody {
            data.append(body)
        }
        
        return data
    }
    
    public func parse(data: Data) -> Int {
        let offset = findEndOfHTTP(data: data)
        if offset > 0 {
            buffer.append(data.subdata(in: 0..<offset))
            if parseContent(data: buffer) {
                buffer = Data()
            }
        } else {
            buffer.append(data)
        }
        return offset
    }
    
    //returns true when the buffer should be cleared
    func parseContent(data: Data) -> Bool {
        guard let str = String(data: data, encoding: .utf8) else {
            delegate?.didReceiveHTTP(event: .failure(HTTPUpgradeError.invalidData))
            return true
        }
        let splitArr = str.components(separatedBy: "\r\n")
        var code = -1
        var i = 0
        var headers = [String: String]()
        for str in splitArr {
            if i == 0 {
                let responseSplit = str.components(separatedBy: .whitespaces)
                guard responseSplit.count > 1 else {
                    delegate?.didReceiveHTTP(event: .failure(HTTPUpgradeError.invalidData))
                    return true
                }
                if let c = Int(responseSplit[1]) {
                    code = c
                }
            } else {
                guard let separatorIndex = str.firstIndex(of: ":") else { break }
                let key = str.prefix(upTo: separatorIndex).trimmingCharacters(in: .whitespaces)
                let val = str.suffix(from: str.index(after: separatorIndex)).trimmingCharacters(in: .whitespaces)
                headers[key.lowercased()] = val
            }
            i += 1
        }
        
        if code != HTTPWSHeader.switchProtocolCode {
            delegate?.didReceiveHTTP(event: .failure(HTTPUpgradeError.notAnUpgrade(code, headers)))
            return true
        }
        
        delegate?.didReceiveHTTP(event: .success(headers))
        return true
    }
    
    public func register(delegate: HTTPHandlerDelegate) {
        self.delegate = delegate
    }
    
    private func findEndOfHTTP(data: Data) -> Int {
        let endBytes = [UInt8(ascii: "\r"), UInt8(ascii: "\n"), UInt8(ascii: "\r"), UInt8(ascii: "\n")]
        var pointer = [UInt8]()
        data.withUnsafeBytes { pointer.append(contentsOf: $0) }
        var k = 0
        for i in 0..<data.count {
            if pointer[i] == endBytes[k] {
                k += 1
                if k == 4 {
                    return i + 1
                }
            } else {
                k = 0
            }
        }
        return -1
    }
}
