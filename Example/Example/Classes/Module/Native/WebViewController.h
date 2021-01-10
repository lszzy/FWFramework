//
//  WebViewController.h
//  Example
//
//  Created by wuyong on 2019/9/2.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

#import "BaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface WebViewController : BaseViewController <FWWebViewController>

@property (nonatomic, copy, nullable) NSString *requestUrl;

@end

NS_ASSUME_NONNULL_END
