//
//  FWCacheDefaults.h
//  FWFramework
//
//  Created by wuyong on 2017/5/10.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "FWCacheAbstract.h"

// NSUserDefaults缓存
@interface FWCacheUserDefaults : FWCacheAbstract

// 单例对象
+ (instancetype)sharedInstance;

// 分组对象
- (instancetype)initWithGroup:(NSString *)group;

@end
