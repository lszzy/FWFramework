//
//  TestRouterViewController.h
//  Example
//
//  Created by wuyong on 2018/11/30.
//  Copyright © 2018 wuyong.site. All rights reserved.
//

#import "BaseViewController.h"

@interface TestRouterResultViewController : BaseViewController

@property (nonatomic, strong) NSDictionary *parameters;
@property (nonatomic, copy) FWBlockParam completion;

@end

@interface TestRouterViewController : BaseViewController

@end
