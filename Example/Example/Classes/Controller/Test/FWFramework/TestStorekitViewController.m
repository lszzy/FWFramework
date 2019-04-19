//
//  TestStorekitViewController.m
//  Example
//
//  Created by wuyong on 2017/5/18.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import "TestStorekitViewController.h"

@implementation TestStorekitViewController

- (void)renderView
{
    UIButton *button = [AppStandard buttonWithStyle:kAppButtonStyleDefault];
    [button setTitle:@"内购" forState:UIControlStateNormal];
    [button fwAddTouchTarget:self action:@selector(onBuy:)];
    [self.view addSubview:button]; {
        [button fwAlignAxisToSuperview:NSLayoutAttributeCenterX];
        [button fwPinEdgeToSuperview:NSLayoutAttributeTop withInset:10];
    }
}

- (void)onBuy:(UIButton *)sender
{
    NSSet *productSet = [[NSSet alloc] initWithObjects:@"20161107104255001", nil];
    FWStorekitManager *manager = [FWStorekitManager sharedInstance];
    [manager setupProductIdentifiers:productSet];
    
    manager.production = NO;
    
    [manager requestProductsWithCompletion:^(SKProductsRequest *request, SKProductsResponse *response) {
        if (response.products.count < 1) {
            NSLog(@"Fail: 产品不存在");
            return;
        }
        
        SKProduct *product = [manager.products objectAtIndex:0];
        NSLog(@"Price: %@", [manager getLocalePrice:product]);
        NSLog(@"Title: %@", product.localizedTitle);
        
        [manager buyProduct:product onCompletion:^(SKPaymentTransaction *transcation) {
            if (transcation.error) {
                NSLog(@"Fail %@", [transcation.error localizedDescription]);
            } else if (transcation.transactionState == SKPaymentTransactionStatePurchased) {
                [manager checkReceipt:[NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]] sharedSecret:@"your sharesecret" onCompletion:^(NSString *response, NSError *error) {
                    NSDictionary *resDict = [response fwJsonDecode];
                    if ([resDict[@"status"] integerValue] == 0) {
                        [manager provideContentWithTransaction:transcation];
                        NSLog(@"SUCCESS %@", response);
                        NSLog(@"Pruchases %@", manager.purchasedProducts);
                    } else {
                        NSLog(@"Fail");
                    }
                }];
            } else if (transcation.transactionState == SKPaymentTransactionStateFailed) {
                NSLog(@"Fail");
            }
        }];
    }];
}

@end
