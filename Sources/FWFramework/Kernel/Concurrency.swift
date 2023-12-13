//
//  Concurrency.swift
//  FWFramework
//
//  Created by wuyong on 2023/11/21.
//

#if compiler(>=5.6.0) && canImport(_Concurrency)

import Foundation

// MARK: - Concurrency+Request
extension HTTPRequest {
    
    /// 异步获取响应模型，自动开始请求
    public func responseModel<T: AnyCodableModel>(of type: T.Type, designatedPath: String? = nil) async throws -> T? {
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                responseModel(of: type, designatedPath: designatedPath) { responseModel in
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
    
    /// 异步获取安全响应模型，自动开始请求
    public func safeResponseModel<T: AnyCodableModel>(of type: T.Type, designatedPath: String? = nil) async throws -> T {
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                safeResponseModel(of: type, designatedPath: designatedPath) { responseModel in
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
    
    /// 异步获取模型响应，自动开始请求
    public func responseModel() async throws -> ResponseModel? {
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                responseModel() { responseModel in
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
    
    /// 异步获取安全模型响应，自动开始请求
    public func safeResponseModel() async throws -> ResponseModel {
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                safeResponseModel() { responseModel in
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
