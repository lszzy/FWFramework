/*!
 @header     FWAppConfig.h
 @indexgroup FWFramework
 @brief      FWAppConfig
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/5/14
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief 框架应用统一配置类，应用可继承重写
 */
@interface FWAppConfig : NSObject

/// 单例模式，可设置为子类
@property (class, nonatomic, strong) FWAppConfig *sharedInstance;

@end

NS_ASSUME_NONNULL_END
