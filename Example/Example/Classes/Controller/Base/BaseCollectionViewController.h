//
//  BaseCollectionViewController.h
//  EasiCustomer
//
//  Created by wuyong on 2018/9/21.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "BaseViewController.h"

/*!
 @brief 集合视图基类
 */
@interface BaseCollectionViewController : BaseViewController <UICollectionViewDataSource, UICollectionViewDelegate>

// 数据源
@property (nonatomic, readonly) NSMutableArray *dataList;

// 集合视图
@property (nonatomic, readonly) UICollectionView *collectionView;

// 渲染集合视图，loadView自动调用
- (UICollectionView *)renderCollectionView;

// 渲染集合视图布局，loadView自动调用
- (UICollectionViewLayout *)renderCollectionViewLayout;

// 渲染集合布局，默认铺满，loadView自动调用
- (void)renderCollectionLayout;

@end
