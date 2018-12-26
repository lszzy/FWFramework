//
//  FWCacheMemory.h
//  FWFramework
//
//  Created by wuyong on 2017/5/10.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import "FWCacheAbstract.h"

// 内存缓存
@interface FWCacheMemory : FWCacheAbstract

// 单例对象
+ (instancetype)sharedInstance;

@end
