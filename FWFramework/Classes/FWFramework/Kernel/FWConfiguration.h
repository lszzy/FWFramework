//
//  FWConfiguration.h
//  FWFramework
//
//  Created by wuyong on 2022/6/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 配置模板基类，使用时继承即可
NS_SWIFT_NAME(ConfigurationTemplate)
@interface FWConfigurationTemplate : NSObject

/// 应用配置方法，子类重写
- (void)applyConfiguration;

@end

/// 配置基类，使用时继承即可
NS_SWIFT_NAME(Configuration)
@interface FWConfiguration : NSObject

/// 单例模式对象
+ (instancetype)sharedInstance NS_REFINED_FOR_SWIFT;

/// 初始化配置，子类可重写，默认自动查找类名格式：[FWConfiguration]+Template
- (void)initializeConfiguration;

@end

NS_ASSUME_NONNULL_END
