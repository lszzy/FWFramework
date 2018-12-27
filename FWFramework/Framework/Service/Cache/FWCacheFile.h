//
//  FWCacheFile.h
//  FWFramework
//
//  Created by wuyong on 2017/5/11.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "FWCacheAbstract.h"

// 文件缓存
@interface FWCacheFile : FWCacheAbstract

// 单例对象
+ (instancetype)sharedInstance;

// 指定路径
- (instancetype)initWithPath:(NSString *)path;

@end
