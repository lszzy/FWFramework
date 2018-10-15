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

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief UIView+FWFramework
 */
@interface UIView (FWFramework)

#pragma mark - ViewController

// 获取响应的视图控制器
- (nullable UIViewController *)fwViewController;

#pragma mark - Subview

// 递归查找指定子类的第一个视图
- (nullable __kindof UIView *)fwSubviewOfClass:(Class)clazz;

// 递归查找指定条件的第一个视图
- (nullable __kindof UIView *)fwSubviewOfBlock:(BOOL (^)(UIView *view))block;

#pragma mark - Snapshot

// 图片截图
- (nullable UIImage *)fwSnapshotImage;

// Pdf截图
- (nullable NSData *)fwSnapshotPdf;

@end

NS_ASSUME_NONNULL_END
