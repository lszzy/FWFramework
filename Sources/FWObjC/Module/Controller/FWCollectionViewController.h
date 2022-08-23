//
//  FWCollectionViewController.h
//  
//
//  Created by wuyong on 2022/8/23.
//

#import "FWViewController.h"

NS_ASSUME_NONNULL_BEGIN

/**
 集合视图控制器协议，可覆写
 */
NS_SWIFT_NAME(CollectionViewControllerProtocol)
@protocol FWCollectionViewController <FWViewController, UICollectionViewDataSource, UICollectionViewDelegate>

@optional

/// 集合视图，默认不显示滚动条
@property (nonatomic, readonly) UICollectionView *collectionView NS_SWIFT_UNAVAILABLE("");

/// 集合数据，默认空数组，延迟加载
@property (nonatomic, readonly) NSMutableArray *collectionData NS_SWIFT_UNAVAILABLE("");

/// 渲染集合视图内容布局，只调用一次
- (UICollectionViewLayout *)setupCollectionViewLayout;

/// 渲染集合视图，setupSubviews之前调用，默认未实现
- (void)setupCollectionView;

/// 渲染集合视图布局，setupSubviews之前调用，默认铺满
- (void)setupCollectionLayout;

@end

/**
 管理器集合视图控制器分类
 */
@interface FWViewControllerManager (FWCollectionViewController)

@end

NS_ASSUME_NONNULL_END
