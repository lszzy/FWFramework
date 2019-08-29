/*!
 @header     FWCollectionViewController.m
 @indexgroup FWFramework
 @brief      FWCollectionViewController
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/8/28
 */

#import "FWCollectionViewController.h"
#import "UIView+FWAutoLayout.h"
#import <objc/runtime.h>

#pragma mark - UIViewController+FWCollectionViewController

@interface UIViewController (FWCollectionViewController)

@end

@implementation UIViewController (FWCollectionViewController)

- (UICollectionView *)fwInnerCollectionView
{
    UICollectionView *collectionView = objc_getAssociatedObject(self, @selector(collectionView));
    if (!collectionView) {
        collectionView = [(id<FWCollectionViewController>)self renderCollectionView];
        objc_setAssociatedObject(self, @selector(collectionView), collectionView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return collectionView;
}

- (NSMutableArray *)fwInnerCollectionData
{
    NSMutableArray *collectionData = objc_getAssociatedObject(self, @selector(collectionData));
    if (!collectionData) {
        collectionData = [[NSMutableArray alloc] init];
        objc_setAssociatedObject(self, @selector(collectionData), collectionData, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return collectionData;
}

- (UICollectionViewLayout *)fwInnerRenderCollectionViewLayout
{
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    return flowLayout;
}

- (UICollectionView *)fwInnerRenderCollectionView
{
    UICollectionViewLayout *viewLayout = [(id<FWCollectionViewController>)self renderCollectionViewLayout];
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:viewLayout];
    collectionView.showsVerticalScrollIndicator = NO;
    collectionView.showsHorizontalScrollIndicator = NO;
    if (@available(iOS 11.0, *)) {
        collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    return collectionView;
}

- (void)fwInnerRenderCollectionLayout
{
    UICollectionView *collectionView = [(id<FWCollectionViewController>)self collectionView];
    [collectionView fwPinEdgesToSuperview];
}

@end

#pragma mark - FWViewControllerManager+FWCollectionViewController

@implementation FWViewControllerManager (FWCollectionViewController)

+ (void)load
{
    FWViewControllerIntercepter *intercepter = [[FWViewControllerIntercepter alloc] init];
    intercepter.loadViewIntercepter = @selector(collectionViewControllerLoadView:);
    intercepter.forwardSelectors = @{@"collectionView" : @"fwInnerCollectionView",
                                     @"collectionData" : @"fwInnerCollectionData",
                                     @"renderCollectionViewLayout" : @"fwInnerRenderCollectionViewLayout",
                                     @"renderCollectionView" : @"fwInnerRenderCollectionView",
                                     @"renderCollectionLayout" : @"fwInnerRenderCollectionLayout"};
    [[FWViewControllerManager sharedInstance] registerProtocol:@protocol(FWCollectionViewController) withIntercepter:intercepter];
}

- (void)collectionViewControllerLoadView:(UIViewController<FWCollectionViewController> *)viewController
{
    UICollectionView *collectionView = [viewController collectionView];
    collectionView.dataSource = viewController;
    collectionView.delegate = viewController;
    [viewController.view addSubview:collectionView];
    [viewController renderCollectionLayout];
    
    [collectionView setNeedsLayout];
    [collectionView layoutIfNeeded];
}

@end
