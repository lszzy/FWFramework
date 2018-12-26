//
//  FWCacheDefaults.h
//  FWFramework
//
//  Created by wuyong on 2017/5/10.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import "FWCacheAbstract.h"

// NSUserDefaults缓存
@interface FWCacheDefaults : FWCacheAbstract

// 单例对象
+ (instancetype)sharedInstance;

// 分组对象
- (instancetype)initWithGroup:(NSString *)group;

@end
