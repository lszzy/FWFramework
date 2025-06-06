//
//  EventSource.swift
//  FWFramework
//
//  Created by wuyong on 2025/6/6.
//

import Alamofire
import Foundation

/// [AlamofireEventSource](https://github.com/dclelland/AlamofireEventSource)
extension Session {
    public func eventSourceRequest(
        _ convertible: URLConvertible,
        method: HTTPMethod = .get,
        headers: HTTPHeaders? = nil,
        lastEventID: String? = nil
    ) -> DataStreamRequest {
        streamRequest(convertible, headers: headers) { request in
            request.timeoutInterval = TimeInterval(Int32.max)
            request.headers.add(name: "Accept", value: "text/event-stream")
            request.headers.add(name: "Cache-Control", value: "no-cache")
            if let lastEventID {
                request.headers.add(name: "Last-Event-ID", value: lastEventID)
            }
        }
    }
}

extension DataStreamRequest {
    public struct EventSource {
        public let event: EventSourceEvent
        public let token: CancellationToken

        public func cancel() {
            token.cancel()
        }
    }

    public enum EventSourceEvent {
        case message(EventSourceMessage)
        case complete(Completion)
    }

    @discardableResult
    public func responseEventSource(
        using serializer: EventSourceSerializer = EventSourceSerializer(),
        on queue: DispatchQueue = .main,
        handler: @escaping (EventSource) -> Void
    ) -> DataStreamRequest {
        responseStream(using: serializer, on: queue) { stream in
            switch stream.event {
            case let .stream(result):
                for message in try result.get() {
                    handler(EventSource(event: .message(message), token: stream.token))
                }
            case let .complete(completion):
                handler(EventSource(event: .complete(completion), token: stream.token))
            }
        }
    }
}

extension DataStreamRequest {
    public struct DecodableEventSource<T: Decodable> {
        public let event: DecodableEventSourceEvent<T>
        public let token: CancellationToken

        public func cancel() {
            token.cancel()
        }
    }

    public enum DecodableEventSourceEvent<T: Decodable> {
        case message(DecodableEventSourceMessage<T>)
        case complete(Completion)
    }

    @discardableResult
    public func responseDecodableEventSource<T: Decodable>(
        using serializer: DecodableEventSourceSerializer<T> = DecodableEventSourceSerializer(),
        on queue: DispatchQueue = .main,
        handler: @escaping (DecodableEventSource<T>) -> Void
    ) -> DataStreamRequest {
        responseStream(using: serializer, on: queue) { stream in
            switch stream.event {
            case let .stream(result):
                for message in try result.get() {
                    handler(DecodableEventSource(event: .message(message), token: stream.token))
                }
            case let .complete(completion):
                handler(DecodableEventSource(event: .complete(completion), token: stream.token))
            }
        }
    }
}

public struct DecodableEventSourceMessage<T: Decodable>: @unchecked Sendable {
    public var event: String?
    public var id: String?
    public var data: T?
    public var retry: String?
}

public class DecodableEventSourceSerializer<T: Decodable>: DataStreamSerializer, @unchecked Sendable {
    public let decoder: DataDecoder

    private let serializer: EventSourceSerializer

    public init(
        decoder: DataDecoder = JSONDecoder(),
        delimiter: Data = EventSourceSerializer.doubleNewlineDelimiter
    ) {
        self.decoder = decoder
        self.serializer = EventSourceSerializer(delimiter: delimiter)
    }

    public func serialize(_ data: Data) throws -> [DecodableEventSourceMessage<T>] {
        try serializer.serialize(data).map { message in
            try DecodableEventSourceMessage(
                event: message.event,
                id: message.id,
                data: message.data?.data(using: .utf8).flatMap { data in
                    try decoder.decode(T.self, from: data)
                },
                retry: message.retry
            )
        }
    }
}

public struct EventSourceMessage: @unchecked Sendable {
    public var event: String?
    public var id: String?
    public var data: String?
    public var retry: String?
}

extension EventSourceMessage {
    init?(parsing string: String) {
        let fields = string.components(separatedBy: "\n").compactMap(Field.init(parsing:))
        for field in fields {
            switch field.key {
            case .event:
                self.event = event.map { $0 + "\n" + field.value } ?? field.value
            case .id:
                self.id = id.map { $0 + "\n" + field.value } ?? field.value
            case .data:
                self.data = data.map { $0 + "\n" + field.value } ?? field.value
            case .retry:
                self.retry = retry.map { $0 + "\n" + field.value } ?? field.value
            }
        }
    }
}

extension EventSourceMessage {
    struct Field {
        enum Key: String {
            case event
            case id
            case data
            case retry
        }

        var key: Key
        var value: String

        init?(parsing string: String) {
            let scanner = Scanner(string: string)

            guard let key = scanner.scanUpToString(":").flatMap(Key.init(rawValue:)) else {
                return nil
            }

            _ = scanner.scanString(":")

            guard let value = scanner.scanUpToString("\n") else {
                return nil
            }

            self.key = key
            self.value = value
        }
    }
}

public class EventSourceSerializer: DataStreamSerializer, @unchecked Sendable {
    public static let doubleNewlineDelimiter = "\n\n".data(using: .utf8)!

    public let delimiter: Data

    private var buffer = Data()

    public init(delimiter: Data = doubleNewlineDelimiter) {
        self.delimiter = delimiter
    }

    public func serialize(_ data: Data) throws -> [EventSourceMessage] {
        buffer.append(data)
        return extractMessagesFromBuffer().compactMap(EventSourceMessage.init(parsing:))
    }

    private func extractMessagesFromBuffer() -> [String] {
        var messages = [String]()
        var searchRange: Range<Data.Index> = buffer.startIndex..<buffer.endIndex

        while let delimiterRange = buffer.range(of: delimiter, in: searchRange) {
            let subdata = buffer.subdata(in: searchRange.startIndex..<delimiterRange.endIndex)

            if let message = String(bytes: subdata, encoding: .utf8) {
                messages.append(message)
            }

            searchRange = delimiterRange.endIndex..<buffer.endIndex
        }

        buffer.removeSubrange(buffer.startIndex..<searchRange.startIndex)
        return messages
    }
}
