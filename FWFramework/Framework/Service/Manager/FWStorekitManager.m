//
//  FWStorekitManager.m
//  FWFramework
//
//  Created by wuyong on 2017/5/18.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import "FWStorekitManager.h"
#import "FWKeychainManager.h"

@interface FWStorekitManager ()

@property (nonatomic, strong) NSSet *productIdentifiers;

@property (nonatomic, strong) NSArray *products;

@property (nonatomic, strong) NSMutableSet *purchasedProducts;

@property (nonatomic, strong) SKProductsRequest *request;

@property (nonatomic,copy) void (^requestProductsBlock)(SKProductsRequest *request , SKProductsResponse *response);

@property (nonatomic,copy) void (^buyProductCompleteBlock)(SKPaymentTransaction *transcation);

@property (nonatomic,copy) void (^restoreCompletedBlock)(SKPaymentQueue *payment, NSError *error);

@property (nonatomic,copy) void (^checkReceiptCompleteBlock)(NSString *response, NSError *error);

@property (nonatomic,strong) NSMutableData *receiptRequestData;

@end

@implementation FWStorekitManager

+ (instancetype)sharedInstance
{
    static FWStorekitManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FWStorekitManager alloc] init];
    });
    return instance;
}

- (void)setupProductIdentifiers:(NSSet *)productIdentifiers
{
    // 保存产品标记
    self.productIdentifiers = productIdentifiers;
    
    // 检查之前已购买的产品
    NSMutableSet *purchasedProducts = [NSMutableSet set];
    for (NSString *productIdentifier in self.productIdentifiers) {
        BOOL productPurchased = [self isPurchasedProductIdentifier:productIdentifier];
        if (productPurchased) {
            [purchasedProducts addObject:productIdentifier];
        }
    }
    
    if ([SKPaymentQueue defaultQueue]) {
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        self.purchasedProducts = purchasedProducts;
    }
}

- (void)dealloc
{
    if ([SKPaymentQueue defaultQueue]) {
        [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
    }
}

- (BOOL)isPurchasedProductIdentifier:(NSString *)productIdentifier
{
    BOOL productPurchased = NO;
    
    NSString *password = [[FWKeychainManager sharedInstance] passwordForService:@"FWStorekit" account:productIdentifier];
    if ([@"YES" isEqualToString:password]) {
        productPurchased = YES;
    }
    
    return productPurchased;
}

- (void)requestProductsWithCompletion:(void (^)(SKProductsRequest *, SKProductsResponse *))completion
{
    self.request = [[SKProductsRequest alloc] initWithProductIdentifiers:self.productIdentifiers];
    self.requestProductsBlock = completion;
    self.request.delegate = self;
    
    [self.request start];
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    self.products = response.products;
    self.request = nil;
    
    if (self.requestProductsBlock) {
        self.requestProductsBlock(request, response);
    }
}

- (void)recordTransaction:(SKPaymentTransaction *)transaction
{
    // TODO: 记录事物到服务端
}

- (void)provideContentWithTransaction:(SKPaymentTransaction *)transaction
{
    NSString *productIdentifier = @"";
    if (transaction.originalTransaction) {
        productIdentifier = transaction.originalTransaction.payment.productIdentifier;
    } else {
        productIdentifier = transaction.payment.productIdentifier;
    }
    
    if (productIdentifier) {
        [[FWKeychainManager sharedInstance] setPassword:@"YES" forService:@"FWStorekit" account:productIdentifier];
        [self.purchasedProducts addObject:productIdentifier];
    }
}

- (void)clearSavedPurchasedProducts
{
    for (NSString *productIdentifier in self.productIdentifiers) {
        [self clearSavedPurchasedProductIdentifier:productIdentifier];
    }
}

- (void)clearSavedPurchasedProductIdentifier:(NSString *)productIdentifier
{
    [[FWKeychainManager sharedInstance] deletePasswordForService:@"FWStorekit" account:productIdentifier];
    [self.purchasedProducts removeObject:productIdentifier];
}

- (void)completeTransaction:(SKPaymentTransaction *)transaction
{
    [self recordTransaction:transaction];
    
    if ([SKPaymentQueue defaultQueue]) {
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    }
    
    if (self.buyProductCompleteBlock) {
        self.buyProductCompleteBlock(transaction);
    }
}

- (void)restoreTransaction:(SKPaymentTransaction *)transaction
{
    [self recordTransaction:transaction];
    [self provideContentWithTransaction:transaction];
    
    if ([SKPaymentQueue defaultQueue]) {
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        
        if (self.buyProductCompleteBlock) {
            self.buyProductCompleteBlock(transaction);
        }
    }
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction
{
    if (transaction.error.code != SKErrorPaymentCancelled) {
        NSLog(@"Transaction error: %@ %ld", transaction.error.localizedDescription,(long)transaction.error.code);
    }
    
    if ([SKPaymentQueue defaultQueue]) {
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        
        if (self.buyProductCompleteBlock) {
            self.buyProductCompleteBlock(transaction);
        }
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions
{
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
                break;
            default:
                break;
        }
    }
}

- (void)buyProduct:(SKProduct *)product onCompletion:(void (^)(SKPaymentTransaction *))completion
{
    self.buyProductCompleteBlock = completion;
    self.restoreCompletedBlock = nil;
    
    SKPayment *payment = [SKPayment paymentWithProduct:product];
    if ([SKPaymentQueue defaultQueue]) {
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }
}

- (void)restoreProductsWithCompletion:(void (^)(SKPaymentQueue *, NSError *))completion
{
    self.buyProductCompleteBlock = nil;
    self.restoreCompletedBlock = completion;
    
    if ([SKPaymentQueue defaultQueue]) {
        [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
    } else {
        NSLog(@"Cannot get the default Queue");
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    NSLog(@"Transaction error: %@ %ld", error.localizedDescription,(long)error.code);
    
    if (self.restoreCompletedBlock) {
        self.restoreCompletedBlock(queue, error);
    }
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    for (SKPaymentTransaction *transaction in queue.transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStateRestored: {
                [self recordTransaction:transaction];
                [self provideContentWithTransaction:transaction];
                break;
            }
            default:
                break;
        }
    }
    
    if (self.restoreCompletedBlock) {
        self.restoreCompletedBlock(queue, nil);
    }
}

- (void)checkReceipt:(NSData *)receiptData onCompletion:(void (^)(NSString *, NSError *))completion
{
    [self checkReceipt:receiptData sharedSecret:nil onCompletion:completion];
}

- (void)checkReceipt:(NSData *)receiptData sharedSecret:(NSString *)secretKey onCompletion:(void (^)(NSString *, NSError *))completion
{
    
    self.checkReceiptCompleteBlock = completion;
    
    NSError *jsonError = nil;
    NSString *receiptBase64 = [[NSString alloc] initWithData:[receiptData base64EncodedDataWithOptions:0] encoding:NSUTF8StringEncoding];
    
    NSData *jsonData = nil;
    if (secretKey.length > 0) {
        jsonData = [NSJSONSerialization dataWithJSONObject:[NSDictionary dictionaryWithObjectsAndKeys:receiptBase64, @"receipt-data",
                                                            secretKey, @"password",
                                                            nil]
                                                   options:NSJSONWritingPrettyPrinted
                                                     error:&jsonError];
    } else {
        jsonData = [NSJSONSerialization dataWithJSONObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                            receiptBase64,@"receipt-data",
                                                            nil]
                                                   options:NSJSONWritingPrettyPrinted
                                                     error:&jsonError];
    }
    
    NSURL *requestURL = nil;
    if (self.production) {
        requestURL = [NSURL URLWithString:@"https://buy.itunes.apple.com/verifyReceipt"];
    } else {
        requestURL = [NSURL URLWithString:@"https://sandbox.itunes.apple.com/verifyReceipt"];
    }
    
    NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:requestURL];
    [req setHTTPMethod:@"POST"];
    [req setHTTPBody:jsonData];
    
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    if (conn) {
        self.receiptRequestData = [[NSMutableData alloc] init];
    } else {
        NSError *error = nil;
        NSMutableDictionary *errorDetail = [[NSMutableDictionary alloc] init];
        [errorDetail setValue:@"Can't create connection" forKey:NSLocalizedDescriptionKey];
        error = [NSError errorWithDomain:@"FWFramework" code:100 userInfo:errorDetail];
        if (self.checkReceiptCompleteBlock) {
            self.checkReceiptCompleteBlock(nil, error);
        }
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"Cannot transmit receipt data. %@",[error localizedDescription]);
    
    if (self.checkReceiptCompleteBlock) {
        self.checkReceiptCompleteBlock(nil, error);
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [self.receiptRequestData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.receiptRequestData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSString *response = [[NSString alloc] initWithData:self.receiptRequestData encoding:NSUTF8StringEncoding];
    
    if (self.checkReceiptCompleteBlock) {
        self.checkReceiptCompleteBlock(response, nil);
    }
}

- (NSString *)getLocalePrice:(SKProduct *)product
{
    if (product) {
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        [formatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
        [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        [formatter setLocale:product.priceLocale];
        
        return [formatter stringFromNumber:product.price];
    }
    return @"";
}

@end
