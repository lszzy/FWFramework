/*!
 @header     FWCollectionViewController.h
 @indexgroup FWFramework
 @brief      FWCollectionViewController
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/8/28
 */

#import "FWViewController.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief 集合视图控制器协议，可覆写
 */
@protocol FWCollectionViewController <FWViewController, UICollectionViewDataSource, UICollectionViewDelegate>

@optional

/// 集合视图，默认不显示滚动条
@property (nonatomic, readonly) UICollectionView *collectionView NS_SWIFT_UNAVAILABLE("");

/// 集合数据，默认空数组，延迟加载
@property (nonatomic, readonly) NSMutableArray *collectionData NS_SWIFT_UNAVAILABLE("");

/// 渲染集合视图内容布局，只调用一次
- (UICollectionViewLayout *)renderCollectionViewLayout;

/// 渲染集合视图，renderView之前调用，默认未实现
- (void)renderCollectionView;

/// 渲染集合视图布局，renderView之前调用，默认铺满
- (void)renderCollectionLayout;

@end

/*!
 @brief 管理器集合视图控制器分类
 */
@interface FWViewControllerManager (FWCollectionViewController)

@end

NS_ASSUME_NONNULL_END
