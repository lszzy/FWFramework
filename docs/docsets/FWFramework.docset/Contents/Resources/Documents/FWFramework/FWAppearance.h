/**
 @header     FWAppearance.h
 @indexgroup FWFramework
      FWAppearance
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/8
 */

#import "FWWrapper.h"

NS_ASSUME_NONNULL_BEGIN

/**
 UIAppearance扩展类，支持任意NSObject对象使用UIAppearance能力
 @note 系统默认时机是在didMoveToWindow处理UIAppearance
 
 @see https://github.com/Tencent/QMUI_iOS
 */
NS_SWIFT_NAME(Appearance)
@interface FWAppearance : NSObject

/// 获取指定 Class 的 appearance 对象，每个 Class 全局只会存在一个 appearance 对象
+ (id)appearanceForClass:(Class)aClass;

/// 获取指定 appearance 对象的关联 Class，通过解析_UIAppearance对象获取
+ (Class)classForAppearance:(id)appearance;

@end

@interface FWObjectWrapper (FWAppearance)

/// 从 appearance 里取值并赋值给当前实例，通常在对象的 init 里调用
- (void)applyAppearance;

@end

NS_ASSUME_NONNULL_END