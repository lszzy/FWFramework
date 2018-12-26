//
//  FWCacheFile.h
//  FWFramework
//
//  Created by wuyong on 2017/5/11.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import "FWCacheAbstract.h"

// 文件缓存
@interface FWCacheFile : FWCacheAbstract

// 单例对象
+ (instancetype)sharedInstance;

// 指定路径
- (instancetype)initWithPath:(NSString *)path;

@end
