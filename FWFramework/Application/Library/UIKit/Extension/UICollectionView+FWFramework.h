/*!
 @header     UICollectionView+FWFramework.h
 @indexgroup FWFramework
 @brief      UICollectionView+FWFramework
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/5/31
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// UICollectionView分类
@interface UICollectionView (FWFramework)

// reloadData完成回调
- (void)fwReloadDataWithCompletion:(nullable void (^)(void))completion;

@end

@interface UICollectionViewCell (FWFramework)

/// 通用绑定视图模型方法
@property (nullable, nonatomic, strong) id fwViewModel;

/// 根据视图模型自动计算cell大小，子类可重写
+ (CGSize)fwSizeWithViewModel:(nullable id)viewModel collectionView:(UICollectionView *)collectionView;

// 获取当前所属collectionView
- (nullable UICollectionView *)fwCollectionView;

// 获取当前显示indexPath
- (nullable NSIndexPath *)fwIndexPath;

@end

// iOS9+可通过UICollectionViewFlowLayout调用sectionHeadersPinToVisibleBounds实现Header悬停效果
@interface UICollectionViewFlowLayout (FWFramework)

// 设置Header和Footer是否悬停，支持iOS9+
- (void)fwHoverWithHeader:(BOOL)header footer:(BOOL)footer;

@end

@interface UICollectionReusableView (FWFramework)

/// 通用绑定视图模型方法
@property (nullable, nonatomic, strong) id fwViewModel;

/// 根据视图模型自动计算view大小，子类可重写
+ (CGSize)fwSizeWithViewModel:(nullable id)viewModel collectionView:(UICollectionView *)collectionView;

@end

NS_ASSUME_NONNULL_END
