//
//  WebController.h
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/24.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

@import FWFramework;

NS_ASSUME_NONNULL_BEGIN

@interface WebController : UIViewController <FWWebViewController>

- (instancetype)initWithRequestUrl:(nullable NSString *)requestUrl;

@end

NS_ASSUME_NONNULL_END
