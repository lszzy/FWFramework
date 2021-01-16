//
//  TestCollectionViewController.m
//  Example
//
//  Created by wuyong on 2018/10/18.
//  Copyright © 2018 wuyong.site. All rights reserved.
//

#import "TestCollectionViewController.h"

static NSString * const kTestCollectionCellID = @"kTestCollectionCellID";

@interface TestCollectionCell : UICollectionViewCell

@end

@implementation TestCollectionCell

@end

static NSString * const kTestCollectionHeaderViewID = @"kTestCollectionHeaderViewID";

@interface TestCollectionHeaderView : UICollectionReusableView

@end

@implementation TestCollectionHeaderView

@end

static NSString * const kTestCollectionFooterViewID = @"kTestCollectionFooterViewID";

@interface TestCollectionFooterView : UICollectionReusableView

@end

@implementation TestCollectionFooterView

@end

@interface TestCollectionViewController () <FWCollectionViewController, UICollectionViewDelegateFlowLayout>

@end

@implementation TestCollectionViewController

- (UICollectionViewLayout *)renderCollectionViewLayout
{
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake((FWScreenWidth - 30) / 2.f, 100);
    layout.minimumLineSpacing = 10;
    layout.minimumInteritemSpacing = 10;
    // 设置悬浮
    if (@available(iOS 9.0, *)) {
        layout.sectionHeadersPinToVisibleBounds = YES;
    }
    return layout;
}

- (void)renderCollectionView
{
    self.collectionView.backgroundColor = [Theme tableColor];
    [self.collectionView registerClass:[TestCollectionCell class] forCellWithReuseIdentifier:kTestCollectionCellID];
    [self.collectionView registerClass:[TestCollectionHeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:kTestCollectionHeaderViewID];
    [self.collectionView registerClass:[TestCollectionFooterView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:kTestCollectionFooterViewID];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 2;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return section == 0 ? 0 : 21;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return section == 0 ? UIEdgeInsetsZero : UIEdgeInsetsMake(10, 10, 10, 10);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    TestCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kTestCollectionCellID forIndexPath:indexPath];
    cell.contentView.backgroundColor = [UIColor fwRandomColor];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    return section == 0 ? CGSizeZero : CGSizeMake(FWScreenWidth, 50);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section
{
    return section == 0 ? CGSizeMake(FWScreenWidth, 100) : CGSizeZero;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        UICollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:kTestCollectionHeaderViewID forIndexPath:indexPath];
        headerView.backgroundColor = [UIColor fwRandomColor];
        return headerView;
    } else if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        UICollectionReusableView *footerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:kTestCollectionFooterViewID forIndexPath:indexPath];
        footerView.backgroundColor = [UIColor fwRandomColor];
        return footerView;
    }
    return nil;
}

@end
