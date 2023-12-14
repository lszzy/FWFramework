//
//  Concurrency.swift
//  FWFramework
//
//  Created by wuyong on 2023/11/21.
//

#if compiler(>=5.6.0) && canImport(_Concurrency)

import Foundation

// MARK: - Concurrency+Promise
extension Promise {
    
    /// 异步获取结果值
    public var value: Any {
        get async throws {
            try await withCheckedThrowingContinuation { continuation in
                done { value in
                    continuation.resume(returning: value)
                } catch: { error in
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// 异步获取结果值，可声明类型
    public func value<T: Any>() async throws -> T {
        let value = try await value
        return value as! T
    }
    
}

// MARK: - Concurrency+Plugin
@_spi(FW) extension UIImage {
    
    /// 异步下载网络图片
    public static func fw_downloadImage(_ url: URLParameter?, options: WebImageOptions = [], context: [ImageCoderOptions: Any]? = nil) async throws -> UIImage {
        let target = NSObject()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                target.fw_tempObject = UIImage.fw_downloadImage(url, options: options, context: context) { image, _, error in
                    if let image = image {
                        continuation.resume(returning: image)
                    } else {
                        continuation.resume(throwing: error ?? RequestError.unknown)
                    }
                }
            }
        } onCancel: {
            UIImage.fw_cancelImageDownload(target.fw_tempObject)
        }
    }
    
}

// MARK: - Concurrency+Request
extension HTTPRequest {
    
    /// 异步获取完成响应，注意非Task取消也会触发(Continuation流程)
    public func response<T: HTTPRequest>() async -> T {
        await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                requestCancelledBlock { (request: T) in
                    if !Task.isCancelled {
                        continuation.resume(returning: request)
                    }
                }
                .response { (request: T) in
                    continuation.resume(returning: request)
                }
                .start()
            }
        } onCancel: {
            self.cancel()
        }
    }
    
    /// 异步获取成功响应，注意非Task取消也会触发(Continuation流程)
    public func responseSuccess<T: HTTPRequest>() async throws -> T {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                requestCancelledBlock { _ in
                    if !Task.isCancelled {
                        continuation.resume(throwing: CancellationError())
                    }
                }
                .responseSuccess { (request: T) in
                    continuation.resume(returning: request)
                }
                .responseError { error in
                    continuation.resume(throwing: error)
                }
                .start()
            }
        } onCancel: {
            self.cancel()
        }
    }
    
    /// 异步获取响应模型，注意非Task取消也会触发(Continuation流程)
    public func responseModel<T: AnyCodableModel>(of type: T.Type, designatedPath: String? = nil) async throws -> T? {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                requestCancelledBlock { _ in
                    if !Task.isCancelled {
                        continuation.resume(throwing: CancellationError())
                    }
                }
                .responseModel(of: type, designatedPath: designatedPath) { responseModel in
                    continuation.resume(returning: responseModel)
                }
                .responseError { error in
                    continuation.resume(throwing: error)
                }
                .start()
            }
        } onCancel: {
            self.cancel()
        }
    }
    
    /// 异步获取安全响应模型，注意非Task取消也会触发(Continuation流程)
    public func safeResponseModel<T: AnyCodableModel>(of type: T.Type, designatedPath: String? = nil) async throws -> T {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                requestCancelledBlock { _ in
                    if !Task.isCancelled {
                        continuation.resume(throwing: CancellationError())
                    }
                }
                .safeResponseModel(of: type, designatedPath: designatedPath) { responseModel in
                    continuation.resume(returning: responseModel)
                }
                .responseError { error in
                    continuation.resume(throwing: error)
                }
                .start()
            }
        } onCancel: {
            self.cancel()
        }
    }
    
}

extension ResponseModelRequest where Self: HTTPRequest {
    
    /// 异步获取模型响应，注意非Task取消也会触发(Continuation流程)
    public func responseModel() async throws -> ResponseModel? {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                requestCancelledBlock { _ in
                    if !Task.isCancelled {
                        continuation.resume(throwing: CancellationError())
                    }
                }
                .responseModel() { responseModel in
                    continuation.resume(returning: responseModel)
                }
                .responseError { error in
                    continuation.resume(throwing: error)
                }
                .start()
            }
        } onCancel: {
            self.cancel()
        }
    }
    
}

extension ResponseModelRequest where Self: HTTPRequest, ResponseModel: AnyCodableModel {
    
    /// 异步获取安全模型响应，注意非Task取消也会触发(Continuation流程)
    public func safeResponseModel() async throws -> ResponseModel {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                requestCancelledBlock { _ in
                    if !Task.isCancelled {
                        continuation.resume(throwing: CancellationError())
                    }
                }
                .safeResponseModel() { responseModel in
                    continuation.resume(returning: responseModel)
                }
                .responseError { error in
                    continuation.resume(throwing: error)
                }
                .start()
            }
        } onCancel: {
            self.cancel()
        }
    }
    
}

#endif
