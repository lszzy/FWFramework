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

- (UICollectionView *)collectionView
{
    UICollectionView *collectionView = objc_getAssociatedObject(self, _cmd);
    if (!collectionView) {
        collectionView = [[FWViewControllerManager sharedInstance] performIntercepter:_cmd withObject:self];
        objc_setAssociatedObject(self, _cmd, collectionView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return collectionView;
}

#pragma mark - UICollectionView

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.collectionData.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

@end
