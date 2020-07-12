//
//  FWStorekitManager.h
//  FWFramework
//
//  Created by wuyong on 2017/5/18.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

NS_ASSUME_NONNULL_BEGIN

// 内购管理器
@interface FWStorekitManager : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>

// 产品标记列表
@property (nonatomic, strong, readonly, nullable) NSSet *productIdentifiers;

// 产品列表
@property (nonatomic, strong, readonly, nullable) NSArray *products;

// 已支付产品列表
@property (nonatomic, strong, readonly, nullable) NSMutableSet *purchasedProducts;

// 产品请求
@property (nonatomic, strong, readonly, nullable) SKProductsRequest *request;

// 是否是生产环境，默认NO
@property (nonatomic, assign) BOOL production;

/*! @brief 单例模式 */
@property (class, nonatomic, readonly) FWStorekitManager *sharedInstance;

// 初始化产品标识列表，第一步
- (void)setupProductIdentifiers:(NSSet *)productIdentifiers;

// 获取产品列表，第二步
- (void)requestProductsWithCompletion:(nullable void (^)(SKProductsRequest *request, SKProductsResponse *response))completion;

// 购买产品，第三步
- (void)buyProduct:(SKProduct *)product onCompletion:(nullable void (^)(SKPaymentTransaction *transcation))completion;

// 客户端检查凭证，第四步。安全考虑，推荐在服务端检查凭证。凭证数据：[NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]]
- (void)checkReceipt:(nullable NSData *)receiptData onCompletion:(nullable void (^)(NSString * _Nullable response, NSError * _Nullable error))completion;

// 客户端检查凭证，附带公钥，第四步。安全考虑，推荐在服务端检查凭证。凭证数据：[NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]]
- (void)checkReceipt:(nullable NSData *)receiptData sharedSecret:(nullable NSString *)secretKey onCompletion:(nullable void (^)(NSString * _Nullable response, NSError * _Nullable error))completion;

// 保存已购买产品，第五步
- (void)provideContentWithTransaction:(SKPaymentTransaction *)transaction;

// 恢复购买
- (void)restoreProductsWithCompletion:(nullable void (^)(SKPaymentQueue *payment, NSError * _Nullable error))completion;

// 检查产品是否购买
- (BOOL)isPurchasedProductIdentifier:(NSString *)productIdentifier;

// 清除所有保存的产品
- (void)clearSavedPurchasedProducts;

// 清除单个保存的产品
- (void)clearSavedPurchasedProductIdentifier:(NSString *)productIdentifier;

// 获取产品的本地货币价格
- (nullable NSString *)getLocalePrice:(SKProduct *)product;

@end

NS_ASSUME_NONNULL_END
