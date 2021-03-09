//
//  TestWebViewController.h
//  Example
//
//  Created by wuyong on 2019/9/2.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

#import "TestViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface TestWebViewController : TestViewController <FWWebViewController>

@property (nonatomic, copy, nullable) NSString *requestUrl;

- (instancetype)initWithRequestUrl:(nullable NSString *)requestUrl;

@end

NS_ASSUME_NONNULL_END
