/*!
 @header     UIView+FWFramework.h
 @indexgroup FWFramework
 @brief      UIView+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/18
 */

#import <UIKit/UIKit.h>
#import "UIView+FWAutoLayout.h"
#import "UIView+FWAnimation.h"
#import "UIView+FWBadge.h"
#import "UIView+FWBlock.h"
#import "UIView+FWBorder.h"
#import "UIView+FWDrag.h"
#import "UIView+FWFrame.h"
#import "UIView+FWIndicator.h"
#import "UIView+FWLayer.h"
#import "UIView+FWViewChain.h"
#import "UIView+FWLayoutChain.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief UIView+FWFramework
 @discussion 事件穿透实现方法：重写-hitTest:withEvent:方法，当为指定视图(如self)时返回nil排除即可
 */
@interface UIView (FWFramework)

#pragma mark - Transform

// 获取当前view的transform scale x
@property(nonatomic, assign, readonly) CGFloat fwScaleX;

// 获取当前view的transform scale y
@property(nonatomic, assign, readonly) CGFloat fwScaleY;

// 获取当前view的transform translation x
@property(nonatomic, assign, readonly) CGFloat fwTranslationX;

// 获取当前view的transform translation y
@property(nonatomic, assign, readonly) CGFloat fwTranslationY;

#pragma mark - Size

// 设置自定义估算尺寸，CGSizeZero为清空自定义设置
- (void)fwSetIntrinsicContentSize:(CGSize)size;

// 计算当前视图适合大小，需实现sizeThatFits:方法
- (CGSize)fwFitSize;

// 计算指定边界，当前视图适合大小，需实现sizeThatFits:方法
- (CGSize)fwFitSizeWithDrawSize:(CGSize)drawSize;

#pragma mark - ViewController

// 获取响应的视图控制器
- (nullable UIViewController *)fwViewController;

#pragma mark - Subview

// 移除所有子视图
- (void)fwRemoveAllSubviews;

// 递归查找指定子类的第一个视图
- (nullable __kindof UIView *)fwSubviewOfClass:(Class)clazz;

// 递归查找指定条件的第一个视图
- (nullable __kindof UIView *)fwSubviewOfBlock:(BOOL (^)(UIView *view))block;

// 添加到父视图，nil时为从父视图移除
- (void)fwMoveToSuperview:(nullable UIView *)view;

#pragma mark - Snapshot

// 图片截图
- (nullable UIImage *)fwSnapshotImage;

// Pdf截图
- (nullable NSData *)fwSnapshotPdf;

@end

NS_ASSUME_NONNULL_END
