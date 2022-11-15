//
//  FWCollectionViewController.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "FWCollectionViewController.h"
#import "FWAutoLayout.h"
#import <objc/runtime.h>
#if FWMacroSPM
@import FWFramework;
#else
#import <FWFramework/FWFramework-Swift.h>
#endif

#pragma mark - FWViewControllerManager+FWCollectionViewController

@implementation FWViewControllerManager (FWCollectionViewController)

+ (void)load
{
    FWViewControllerIntercepter *intercepter = [[FWViewControllerIntercepter alloc] init];
    intercepter.viewDidLoadIntercepter = @selector(collectionViewControllerViewDidLoad:);
    intercepter.forwardSelectors = @{
        @"collectionView" : @"fw_innerCollectionView",
        @"collectionData" : @"fw_innerCollectionData",
        @"setupCollectionViewLayout" : @"fw_innerSetupCollectionViewLayout",
        @"setupCollectionLayout" : @"fw_innerSetupCollectionLayout",
    };
    [[FWViewControllerManager sharedInstance] registerProtocol:@protocol(FWCollectionViewController) withIntercepter:intercepter];
}

- (void)collectionViewControllerViewDidLoad:(UIViewController<FWCollectionViewController> *)viewController
{
    UICollectionView *collectionView = [viewController collectionView];
    collectionView.dataSource = viewController;
    collectionView.delegate = viewController;
    [viewController.view addSubview:collectionView];
    
    if (self.hookCollectionViewController) {
        self.hookCollectionViewController(viewController);
    }
    
    if ([viewController respondsToSelector:@selector(setupCollectionView)]) {
        [viewController setupCollectionView];
    }
    
    [viewController setupCollectionLayout];
    [collectionView setNeedsLayout];
    [collectionView layoutIfNeeded];
}

@end

#pragma mark - UIViewController+FWCollectionViewController

@interface UIViewController (FWCollectionViewController)

@end

@implementation UIViewController (FWCollectionViewController)

- (UICollectionView *)fw_innerCollectionView
{
    UICollectionView *collectionView = objc_getAssociatedObject(self, _cmd);
    if (!collectionView) {
        UICollectionViewLayout *viewLayout = [(id<FWCollectionViewController>)self setupCollectionViewLayout];
        collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:viewLayout];
        collectionView.showsVerticalScrollIndicator = NO;
        collectionView.showsHorizontalScrollIndicator = NO;
        objc_setAssociatedObject(self, _cmd, collectionView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return collectionView;
}

- (NSMutableArray *)fw_innerCollectionData
{
    NSMutableArray *collectionData = objc_getAssociatedObject(self, _cmd);
    if (!collectionData) {
        collectionData = [[NSMutableArray alloc] init];
        objc_setAssociatedObject(self, _cmd, collectionData, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return collectionData;
}

- (UICollectionViewLayout *)fw_innerSetupCollectionViewLayout
{
    UICollectionViewFlowLayout *viewLayout = [[UICollectionViewFlowLayout alloc] init];
    viewLayout.minimumLineSpacing = 0;
    viewLayout.minimumInteritemSpacing = 0;
    return viewLayout;
}

- (void)fw_innerSetupCollectionLayout
{
    UICollectionView *collectionView = [(id<FWCollectionViewController>)self collectionView];
    [collectionView fw_pinEdgesToSuperview:UIEdgeInsetsZero];
}

@end
