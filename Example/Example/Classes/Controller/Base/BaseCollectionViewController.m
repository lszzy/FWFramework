//
//  BaseCollectionViewController.m
//  EasiCustomer
//
//  Created by wuyong on 2018/9/21.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "BaseCollectionViewController.h"

@interface BaseCollectionViewController ()

@end

@implementation BaseCollectionViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // 初始化集合数据
        _dataList = [[NSMutableArray alloc] initWithCapacity:0];
    }
    return self;
}

#pragma mark - Render

- (void)setupView
{
    // 创建自动布局集合
    _collectionView = [self renderCollectionView];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    _collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_collectionView];
    
    // 渲染集合布局
    [self renderCollectionLayout];
    
    // 初始化集合frame
    [_collectionView setNeedsLayout];
    [_collectionView layoutIfNeeded];
}

- (UICollectionView *)renderCollectionView
{
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:[self renderCollectionViewLayout]];
    collectionView.showsHorizontalScrollIndicator = NO;
    collectionView.showsVerticalScrollIndicator = NO;
    // 默认集合背景色
    collectionView.backgroundColor = [UIColor appColorBg];
    // 禁用内边距适应
    [collectionView fwContentInsetAdjustmentNever];
    return collectionView;
}

- (UICollectionViewLayout *)renderCollectionViewLayout
{
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    return layout;
}

- (void)renderCollectionLayout
{
    [self.collectionView fwPinEdgesToSuperview];
}

#pragma mark - UICollectionView

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.dataList.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

@end
