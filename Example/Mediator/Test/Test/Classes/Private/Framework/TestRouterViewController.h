//
//  TestRouterViewController.h
//  Example
//
//  Created by wuyong on 2018/11/30.
//  Copyright © 2018 wuyong.site. All rights reserved.
//

#import "TestViewController.h"

@interface TestRouter : NSObject

FWStaticString(ROUTE_TEST);
FWStaticString(ROUTE_WILDCARD);
FWStaticString(ROUTE_OBJECT);
FWStaticString(ROUTE_OBJECT_UNMATCH);
FWStaticString(ROUTE_LOADER);
FWStaticString(ROUTE_CONTROLLER);
FWStaticString(ROUTE_JAVASCRIPT);
FWStaticString(ROUTE_HOME);
FWStaticString(ROUTE_HOME_TEST);
FWStaticString(ROUTE_HOME_SETTINGS);
FWStaticString(ROUTE_CLOSE);

@end

@interface TestRouterResultViewController : TestViewController <FWRouterProtocol>

@property (nonatomic, strong) FWRouterContext *context;

@end

@interface TestRouterViewController : TestViewController

@end
