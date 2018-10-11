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

/*!
 @brief UIView+FWFramework
 */
@interface UIView (FWFramework)

#pragma mark - ViewController

// 获取响应的视图控制器
- (UIViewController *)fwViewController;

#pragma mark - Snapshot

// 图片截图
- (UIImage *)fwSnapshotImage;

// Pdf截图
- (NSData *)fwSnapshotPdf;

@end
