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

#pragma mark - FWViewControllerManager+FWCollectionViewController

@implementation FWViewControllerManager (FWCollectionViewController)

+ (void)load
{
    FWViewControllerIntercepter *intercepter = [[FWViewControllerIntercepter alloc] init];
    intercepter.loadViewIntercepter = @selector(collectionViewControllerLoadView:);
    intercepter.forwardSelectors = @{
        @"collectionView" : @"fwInnerCollectionView",
        @"collectionData" : @"fwInnerCollectionData",
        @"renderCollectionViewLayout" : @"fwInnerRenderCollectionViewLayout",
        @"renderCollectionLayout" : @"fwInnerRenderCollectionLayout",
    };
    [[FWViewControllerManager sharedInstance] registerProtocol:@protocol(FWCollectionViewController) withIntercepter:intercepter];
}

- (void)collectionViewControllerLoadView:(UIViewController<FWCollectionViewController> *)viewController
{
    UICollectionView *collectionView = [viewController collectionView];
    collectionView.dataSource = viewController;
    collectionView.delegate = viewController;
    [viewController.view addSubview:collectionView];
    
    if ([viewController respondsToSelector:@selector(renderCollectionView)]) {
        [viewController renderCollectionView];
    }
    
    [viewController renderCollectionLayout];
    [collectionView setNeedsLayout];
    [collectionView layoutIfNeeded];
}

@end

#pragma mark - UIViewController+FWCollectionViewController

@interface UIViewController (FWCollectionViewController)

@end

@implementation UIViewController (FWCollectionViewController)

- (UICollectionView *)fwInnerCollectionView
{
    UICollectionView *collectionView = objc_getAssociatedObject(self, _cmd);
    if (!collectionView) {
        UICollectionViewLayout *viewLayout = [(id<FWCollectionViewController>)self renderCollectionViewLayout];
        collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:viewLayout];
        collectionView.showsVerticalScrollIndicator = NO;
        collectionView.showsHorizontalScrollIndicator = NO;
        if (@available(iOS 11.0, *)) {
            collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        objc_setAssociatedObject(self, _cmd, collectionView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return collectionView;
}

- (NSMutableArray *)fwInnerCollectionData
{
    NSMutableArray *collectionData = objc_getAssociatedObject(self, _cmd);
    if (!collectionData) {
        collectionData = [[NSMutableArray alloc] init];
        objc_setAssociatedObject(self, _cmd, collectionData, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return collectionData;
}

- (UICollectionViewLayout *)fwInnerRenderCollectionViewLayout
{
    UICollectionViewFlowLayout *viewLayout = [[UICollectionViewFlowLayout alloc] init];
    return viewLayout;
}

- (void)fwInnerRenderCollectionLayout
{
    UICollectionView *collectionView = [(id<FWCollectionViewController>)self collectionView];
    [collectionView fwPinEdgesToSuperview];
}

@end
