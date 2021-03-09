//
//  UITableView+FWFramework.h
//  FWFramework
//
//  Created by wuyong on 2017/6/1.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITableView+FWBackgroundView.h"
#import "UITableView+FWTemplateLayout.h"

NS_ASSUME_NONNULL_BEGIN

// UITableView分类(Plain有悬停，Group无悬停)
@interface UITableView (FWFramework)

/// 清空Grouped样式默认多余边距，注意CGFLOAT_MIN才会生效，0不会生效
- (void)fwResetGroupedStyle;

/// 设置Plain样式sectionHeader和Footer跟随滚动(不悬停)，在scrollViewDidScroll:中调用即可(需先禁用内边距适应)
- (void)fwFollowWithHeader:(CGFloat)headerHeight footer:(CGFloat)footerHeight;

/// reloadData完成回调
- (void)fwReloadDataWithCompletion:(nullable void (^)(void))completion;

/// reloadData清空尺寸缓存
- (void)fwReloadDataWithoutCache;

/// reloadData禁用动画
- (void)fwReloadDataWithoutAnimation;

/// reloadSections禁用动画
- (void)fwReloadSectionsWithoutAnimation:(NSIndexSet *)sections;

/// reloadRows禁用动画
- (void)fwReloadRowsWithoutAnimation:(NSArray<NSIndexPath *> *)indexPaths;

@end

@interface UITableViewCell (FWFramework)

/// 设置分割线内边距，iOS8+默认15.f，设为UIEdgeInsetsZero可去掉
@property (nonatomic, assign) UIEdgeInsets fwSeparatorInset;

/// 获取当前所属tableView
@property (nonatomic, weak, readonly, nullable) UITableView *fwTableView;

/// 获取当前显示indexPath
@property (nonatomic, readonly, nullable) NSIndexPath *fwIndexPath;

@end

NS_ASSUME_NONNULL_END
