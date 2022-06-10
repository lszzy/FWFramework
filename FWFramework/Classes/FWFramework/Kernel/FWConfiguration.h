//
//  FWConfiguration.h
//  FWFramework
//
//  Created by wuyong on 2022/6/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 配置模板协议，配置模板类需实现
NS_SWIFT_NAME(ConfigurationTemplateProtocol)
@protocol FWConfigurationTemplateProtocol <NSObject>

@required
/// 应用配置方法，必须实现
- (void)applyConfiguration;

@end

/// 配置基类，使用时继承即可
///
/// 默认自动查找类名格式优先级：[配置类]+Template > [配置类]+DefaultTemplate
NS_SWIFT_NAME(Configuration)
@interface FWConfiguration : NSObject

/// 当前所使用配置版本
@property (nonatomic, strong, nullable) id<FWConfigurationTemplateProtocol> configurationTemplate;

/// 单例模式对象
+ (instancetype)sharedInstance NS_REFINED_FOR_SWIFT;

/// 初始化配置，重复调用无效，子类可重写
- (void)initializeConfiguration;

@end

NS_ASSUME_NONNULL_END
