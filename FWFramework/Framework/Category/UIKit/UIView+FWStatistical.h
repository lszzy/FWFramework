/*!
 @header     UIView+FWStatistical.h
 @indexgroup FWFramework
 @brief      UIView+FWStatistical
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/1/16
 */

#import <UIKit/UIKit.h>

/*!
 @brief Click点击统计和Exposure曝光统计
 */
@interface UIView (FWStatistical)

#pragma mark - Click

// 统计Tap手势点击事件，需先添加Tap手势
- (void)fwTrackTappedWithBlock:(void (^)(id sender))block;

// 统计指定类手势事件，需先添加指定类手势
- (void)fwTrackGesture:(Class)clazz withBlock:(void (^)(id sender))block;

@end

@interface UIControl (FWStatistical)

#pragma mark - Click

// 统计Touch点击事件
- (void)fwTrackTouchedWithBlock:(void (^)(id sender))block;

// 统计值Changed事件
- (void)fwTrackChangedWithBlock:(void (^)(id sender))block;

// 统计指定Event事件
- (void)fwTrackEvent:(UIControlEvents)event withBlock:(void (^)(id sender))block;

@end

@interface UITableView (FWStatistical)

#pragma mark - Click

// 统计Select点击事件，需先设置delegate
- (void)fwTrackSelectWithBlock:(void (^)(UITableView *tableView, NSIndexPath *indexPath))block;

@end
