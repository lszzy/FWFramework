//
//  FWStorekitManager.h
//  FWFramework
//
//  Created by wuyong on 2017/5/18.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

// 内购管理器
@interface FWStorekitManager : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>

// 产品标记列表
@property (nonatomic, strong, readonly) NSSet *productIdentifiers;

// 产品列表
@property (nonatomic, strong, readonly) NSArray *products;

// 已支付产品列表
@property (nonatomic, strong, readonly) NSMutableSet *purchasedProducts;

// 产品请求
@property (nonatomic, strong, readonly) SKProductsRequest *request;

// 是否是生产环境，默认NO
@property (nonatomic, assign) BOOL production;

// 单例模式
+ (instancetype)sharedInstance;

// 初始化产品标识列表，第一步
- (void)setupProductIdentifiers:(NSSet *)productIdentifiers;

// 获取产品列表，第二步
- (void)requestProductsWithCompletion:(void (^)(SKProductsRequest *request, SKProductsResponse *response))completion;

// 购买产品，第三步
- (void)buyProduct:(SKProduct *)product onCompletion:(void (^)(SKPaymentTransaction *transcation))completion;

// 客户端检查凭证，第四步。安全考虑，推荐在服务端检查凭证。凭证数据：[NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]]
- (void)checkReceipt:(NSData *)receiptData onCompletion:(void (^)(NSString *response, NSError *error))completion;

// 客户端检查凭证，附带公钥，第四步。安全考虑，推荐在服务端检查凭证。凭证数据：[NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]]
- (void)checkReceipt:(NSData *)receiptData sharedSecret:(NSString *)secretKey onCompletion:(void (^)(NSString *response, NSError *error))completion;

// 保存已购买产品，第五步
- (void)provideContentWithTransaction:(SKPaymentTransaction *)transaction;

// 恢复购买
- (void)restoreProductsWithCompletion:(void (^)(SKPaymentQueue *payment, NSError *error))completion;

// 检查产品是否购买
- (BOOL)isPurchasedProductIdentifier:(NSString *)productIdentifier;

// 清除所有保存的产品
- (void)clearSavedPurchasedProducts;

// 清除单个保存的产品
- (void)clearSavedPurchasedProductIdentifier:(NSString *)productIdentifier;

// 获取产品的本地货币价格
- (NSString *)getLocalePrice:(SKProduct *)product;

@end
