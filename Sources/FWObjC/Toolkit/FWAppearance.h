//
//  FWAppearance.h
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import <UIKit/UIKit.h>

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

/// 从 appearance 里取值并赋值给指定实例，通常在对象的 init 里调用
+ (void)applyAppearance:(NSObject *)object;

@end

@interface NSObject (FWAppearance)

/// 从 appearance 里取值并赋值给当前实例，通常在对象的 init 里调用
- (void)fw_applyAppearance NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
