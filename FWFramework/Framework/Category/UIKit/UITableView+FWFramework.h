//
//  UITableView+FWFramework.h
//  FWFramework
//
//  Created by wuyong on 2017/6/1.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITableView+FWTemplateLayout.h"

// UITableView分类(Plain有悬停，Group无悬停)
@interface UITableView (FWFramework)

// 设置Plain样式sectionHeader和Footer跟随滚动(不悬停)，在scrollViewDidScroll:中调用即可(需先禁用内边距适应)
- (void)fwFollowWithHeader:(CGFloat)headerHeight footer:(CGFloat)footerHeight;

// reloadData完成回调
- (void)fwReloadDataWithCompletion:(void (^)(void))completion;

@end

@interface UITableViewCell (FWFramework)

// 设置分割线内边距，iOS8+默认15.f，设为UIEdgeInsetsZero可去掉
@property (nonatomic, assign) UIEdgeInsets fwSeparatorInset;

// 绑定数据模型
@property (nonatomic, strong) id fwModel;

// 根据数据模型计算cell高度，子类重写
+ (CGFloat)fwHeightWithModel:(id)model;

@end

// UICollectionView分类
@interface UICollectionView (FWFramework)

// reloadData完成回调
- (void)fwReloadDataWithCompletion:(void (^)(void))completion;

@end

@interface UICollectionViewCell (FWFramework)

// 绑定数据模型
@property (nonatomic, strong) id fwModel;

// 根据数据模型计算cell尺寸，子类重写
+ (CGSize)fwSizeWithModel:(id)model;

@end

// iOS9+可通过UICollectionViewFlowLayout调用sectionHeadersPinToVisibleBounds实现Header悬停效果
@interface UICollectionViewFlowLayout (FWFramework)

// 设置Header和Footer是否悬停，支持iOS9+
- (void)fwHoverWithHeader:(BOOL)header footer:(BOOL)footer;

@end

@interface UICollectionReusableView (FWFramework)

// 绑定数据模型
@property (nonatomic, strong) id fwModel;

// 根据数据模型计算view尺寸，子类重写
+ (CGSize)fwSizeWithModel:(id)model;

@end
