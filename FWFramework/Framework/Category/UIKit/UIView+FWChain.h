/*!
 @header     UIView+FWChain.h
 @indexgroup FWFramework
 @brief      UIView+FWChain
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/6/19
 */

#import <UIKit/UIKit.h>

#pragma mark - Macro

/*!
 @brief 定义类链式声明
 
 @param clazz 类名称
 */
#define FWDefChain( clazz ) \
    @property (class, nonatomic, copy, readonly) __kindof clazz *(^fwChain)(void); \
    @property (class, nonatomic, copy, readonly) __kindof clazz *(^fwChainFrame)(CGRect frame); \
    @property (nonatomic, copy, readonly) __kindof clazz *(^fwChainFrame)(CGRect frame); \
    @property (nonatomic, copy, readonly) __kindof clazz *(^fwChainBackgroundColor)(UIColor *backgroundColor); \
    @property (nonatomic, copy, readonly) __kindof clazz *(^fwChainAddSubview)(UIView *view); \
    @property (nonatomic, copy, readonly) __kindof clazz *(^fwChainMoveToSuperview)(UIView *view);

#pragma mark - UIView+FWChain

/*!
 @brief UIView常用链式调用分类
 */
@interface UIView (FWChain)

FWDefChain(UIView);

@end

@interface UILabel (FWChain)

FWDefChain(UILabel);

@property (nonatomic, copy, readonly) __kindof UILabel *(^fwChainText)(NSString *text);

@end
