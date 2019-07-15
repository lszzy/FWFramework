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

// 绑定数据模型
@property (nullable, nonatomic, strong) id fwModel;

// 根据数据模型计算cell尺寸，子类重写
+ (CGSize)fwSizeWithModel:(nullable id)model;

@end

// iOS9+可通过UICollectionViewFlowLayout调用sectionHeadersPinToVisibleBounds实现Header悬停效果
@interface UICollectionViewFlowLayout (FWFramework)

// 设置Header和Footer是否悬停，支持iOS9+
- (void)fwHoverWithHeader:(BOOL)header footer:(BOOL)footer;

@end

@interface UICollectionReusableView (FWFramework)

// 绑定数据模型
@property (nullable, nonatomic, strong) id fwModel;

// 根据数据模型计算view尺寸，子类重写
+ (CGSize)fwSizeWithModel:(nullable id)model;

@end

NS_ASSUME_NONNULL_END
