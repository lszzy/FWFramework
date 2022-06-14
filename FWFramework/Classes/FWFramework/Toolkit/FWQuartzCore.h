/**
 @header     FWQuartzCore.h
 @indexgroup FWFramework
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/10/22
 */

#import <QuartzCore/QuartzCore.h>
#import "FWWrapper.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWDisplayLinkClassWrapper+FWQuartzCore

/**
 如果block参数不会被持有并后续执行，可声明为NS_NOESCAPE，不会触发循环引用
 */
@interface FWDisplayLinkClassWrapper (FWQuartzCore)

/**
 创建CADisplayLink，使用target-action，自动CommonModes添加到当前的运行循环中，避免ScrollView滚动时不触发
 
 @param target 目标
 @param selector 方法
 @return CADisplayLink
 */
- (CADisplayLink *)commonDisplayLinkWithTarget:(id)target selector:(SEL)selector;

/**
 创建CADisplayLink，使用block，自动CommonModes添加到当前的运行循环中，避免ScrollView滚动时不触发
 
 @param block 代码块
 @return CADisplayLink
 */
- (CADisplayLink *)commonDisplayLinkWithBlock:(void (^)(CADisplayLink *displayLink))block;

/**
 创建CADisplayLink，使用block，需要调用addToRunLoop:forMode:安排到当前的运行循环中(CommonModes避免ScrollView滚动时不触发)。
 @note 示例：[displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes]
 
 @param block 代码块
 @return CADisplayLink
 */
- (CADisplayLink *)displayLinkWithBlock:(void (^)(CADisplayLink *displayLink))block;

@end

#pragma mark - FWAnimationWrapper+FWQuartzCore

@interface FWAnimationWrapper (FWQuartzCore)

/// 设置动画开始回调，需要在add之前添加，因为add时会自动拷贝一份对象
@property (nonatomic, copy, nullable) void (^startBlock)(CAAnimation *animation);

/// 设置动画停止回调
@property (nonatomic, copy, nullable) void (^stopBlock)(CAAnimation *animation, BOOL finished);

@end

#pragma mark - CALayer+FWQuartzCore

@interface CALayer (FWQuartzCore)

/// 设置主题背景色，启用主题订阅后可跟随系统改变，清空时需置为nil
@property (nullable, nonatomic, strong) UIColor *fw_themeBackgroundColor NS_REFINED_FOR_SWIFT;

/// 设置主题边框色，启用主题订阅后可跟随系统改变，清空时需置为nil
@property (nullable, nonatomic, strong) UIColor *fw_themeBorderColor NS_REFINED_FOR_SWIFT;

/// 设置主题阴影色，启用主题订阅后可跟随系统改变，清空时需置为nil
@property (nullable, nonatomic, strong) UIColor *fw_themeShadowColor NS_REFINED_FOR_SWIFT;

/// 设置主题内容图片，启用主题订阅后可跟随系统改变，清空时需置为nil
@property (nullable, nonatomic, strong) UIImage *fw_themeContents NS_REFINED_FOR_SWIFT;

@end

#pragma mark - CAGradientLayer+FWQuartzCore

@interface CAGradientLayer (FWQuartzCore)

/// 设置主题渐变色，启用主题订阅后可跟随系统改变，清空时需置为nil
@property (nullable, nonatomic, copy) NSArray<UIColor *> *fw_themeColors NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
