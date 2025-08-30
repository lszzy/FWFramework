//
//  PurchaseManager.swift
//  FWFramework
//
//  Created by wuyong on 2025/7/2.
//

import StoreKit
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

// MARK: - PurchaseManager
/// 内购支付管理器
///
/// consumable: 消耗型，可重复购买，同时只能有一笔未完成的交易，完成后不可退款
/// nonConsumable: 非消耗型，未退款时不可重复购买，只能购买一次，完成后也可退款
@available(iOS 15.0, *)
public class PurchaseManager: @unchecked Sendable {
    /// 单例模式
    public static let shared = PurchaseManager()

    private var listenerTask: Task<Void, Never>?

    public init() {}

    deinit {
        stopListening()
    }

    /// 是否允许交易
    public var canMakePayments: Bool {
        AppStore.canMakePayments
    }

    /// 获取产品列表
    public func products(_ identifiers: [String]) async throws -> [Product] {
        try await Product.products(for: identifiers)
    }

    /// 获取指定产品
    public func product(_ identifier: String) async throws -> Product {
        if let product = try await (products([identifier])).first { return product }
        throw Product.PurchaseError.productUnavailable
    }

    /// 支付指定产品ID，成功时自动验证（验证失败抛异常），可指定自动完成交易（默认false）
    @MainActor public func purchase(
        _ identifier: String,
        finishAutomatically: Bool = false,
        quantity: Int? = nil,
        appAccountToken: String? = nil,
        options: Set<Product.PurchaseOption> = []
    ) async throws -> Product.PurchaseResult {
        let product = try await product(identifier)
        return try await purchase(
            product,
            finishAutomatically: finishAutomatically,
            quantity: quantity,
            appAccountToken: appAccountToken,
            options: options
        )
    }

    /// 支付指定产品，成功时自动验证（验证失败抛异常），可指定自动完成交易（默认false）
    @MainActor public func purchase(
        _ product: Product,
        finishAutomatically: Bool = false,
        quantity: Int? = nil,
        appAccountToken: String? = nil,
        options: Set<Product.PurchaseOption> = []
    ) async throws -> Product.PurchaseResult {
        var purchaseOptions = options
        if let quantity {
            purchaseOptions.insert(.quantity(quantity))
        }
        if let appAccountToken, let tokenUUID = UUID(uuidString: appAccountToken) {
            purchaseOptions.insert(.appAccountToken(tokenUUID))
        }

        let result = try await product.purchase(options: purchaseOptions)
        switch result {
        case let .success(verificationResult):
            switch verificationResult {
            case let .verified(transaction):
                if finishAutomatically {
                    await transaction.finish()
                }
                return result
            case let .unverified(_, error):
                throw error
            }
        default:
            return result
        }
    }

    /// 完成指定产品ID最近一次交易，消耗型商品完成后不能退款且不再返回
    @discardableResult
    public func finish(_ productIdentifier: String) async -> Transaction? {
        guard let transaction = await latestTransaction(productIdentifier, includingRefunds: true) else { return nil }
        await transaction.finish()
        return transaction
    }

    /// 完成指定交易，消耗型商品完成后不能退款且不再返回
    public func finish(_ transaction: Transaction) async {
        await transaction.finish()
    }

    /// 完成指定交易ID，消耗型商品完成后不能退款且不再返回
    @discardableResult
    public func finish(_ transactionId: UInt64) async -> Bool {
        var transaction: Transaction?
        for await verificationResult in Transaction.all {
            if let purchase = verifiedTransaction(verificationResult, includingRefunds: true), purchase.id == transactionId {
                transaction = purchase
                break
            }
        }
        guard let transaction else { return false }

        await transaction.finish()
        return true
    }

    /// 获取所有已支付未退款的交易列表，按支付时间倒序排列（进行中，同一商品有未完成的交易不能再次购买）
    public func purchasedTransactions() async -> [Transaction] {
        var transactions: [Transaction] = []
        for await verificationResult in Transaction.all {
            if let transaction = verifiedTransaction(verificationResult) {
                transactions.append(transaction)
            }
        }
        return transactions.sorted { $0.purchaseDate > $1.purchaseDate }
    }

    /// 根据商品ID获取最近一次已验证的交易，默认未包含已退款订单
    public func latestTransaction(
        _ productIdentifier: String,
        includingRefunds: Bool = false
    ) async -> Transaction? {
        let latestTransaction = await Transaction.latest(for: productIdentifier)
        return verifiedTransaction(latestTransaction, includingRefunds: includingRefunds)
    }

    /// 获取已验证的支付结果，默认未包含已退款订单
    public func verifiedTransaction(
        _ verificationResult: VerificationResult<Transaction>?,
        includingRefunds: Bool = false
    ) -> Transaction? {
        guard let verificationResult else { return nil }
        switch verificationResult {
        case let .verified(transaction):
            if includingRefunds || transaction.revocationDate == nil {
                return transaction
            }
            return nil
        case .unverified:
            return nil
        }
    }
    
    /// 同步交易列表
    public func syncTransactions() async throws {
        try await AppStore.sync()
    }

    /// 同步并恢复已购买的未退款交易，按支付时间倒序排列
    @discardableResult
    public func restorePurchases() async throws -> [Transaction] {
        try await syncTransactions()
        return await purchasedTransactions()
    }

    /// 开始监听交易更新，主线程回调更新句柄（已验证订单，含退款）
    public func startListening(_ listener: (@MainActor @Sendable (Transaction) -> Void)?) {
        listenerTask?.cancel()
        listenerTask = Task { [weak self] in
            for await verificationResult in Transaction.updates {
                if let transaction = self?.verifiedTransaction(verificationResult, includingRefunds: true) {
                    DispatchQueue.fw.mainAsync {
                        listener?(transaction)
                    }
                }
            }
        }
    }

    /// 停止监听交易更新
    public func stopListening() {
        listenerTask?.cancel()
        listenerTask = nil
    }

    /// 指定产品ID退款最近一次交易
    @discardableResult
    public func refund(_ productIdentifier: String) async throws -> Transaction.RefundRequestStatus {
        guard let transaction = await latestTransaction(productIdentifier) else { return .userCancelled }
        return try await refund(transaction)
    }

    /// 指定交易退款
    @discardableResult
    public func refund(_ transaction: Transaction) async throws -> Transaction.RefundRequestStatus {
        try await transaction.beginRefundRequest(in: UIWindow.fw.mainScene!)
    }

    /// 指定交易ID退款
    @discardableResult
    @MainActor public func refund(_ transactionId: UInt64) async throws -> Transaction.RefundRequestStatus {
        try await Transaction.beginRefundRequest(for: transactionId, in: UIWindow.fw.mainScene!)
    }

    /// 管理订阅
    @MainActor public func manageSubscriptions() async throws {
        try await AppStore.showManageSubscriptions(in: UIWindow.fw.mainScene!)
    }

    /// 获取支付国家码
    public func countryCode() async -> String? {
        let storefront = await Storefront.current
        return storefront?.countryCode
    }
}

// MARK: - Autoloader+Purchase
@available(iOS 15.0, *)
@objc extension Autoloader {
    static func loadPlugin_Purchase() {}
}
