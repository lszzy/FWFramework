//
//  CollectionViewController.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "CollectionViewController.h"
#import <objc/runtime.h>

#if FWMacroSPM

@interface UIView ()

- (NSArray<NSLayoutConstraint *> *)fw_pinEdgesToSuperview:(UIEdgeInsets)insets;

@end

#else

#import <FWFramework/FWFramework-Swift.h>

#endif

#pragma mark - __FWViewControllerManager+__FWCollectionViewController

@implementation __FWViewControllerManager (__FWCollectionViewController)

+ (void)load
{
    __FWViewControllerIntercepter *intercepter = [[__FWViewControllerIntercepter alloc] init];
    intercepter.viewDidLoadIntercepter = @selector(collectionViewControllerViewDidLoad:);
    intercepter.forwardSelectors = @{
        @"collectionView" : @"fw_innerCollectionView",
        @"collectionData" : @"fw_innerCollectionData",
        @"setupCollectionViewLayout" : @"fw_innerSetupCollectionViewLayout",
        @"setupCollectionLayout" : @"fw_innerSetupCollectionLayout",
    };
    [[__FWViewControllerManager sharedInstance] registerProtocol:@protocol(__FWCollectionViewController) withIntercepter:intercepter];
}

- (void)collectionViewControllerViewDidLoad:(UIViewController<__FWCollectionViewController> *)viewController
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

#pragma mark - UIViewController+__FWCollectionViewController

@interface UIViewController (__FWCollectionViewController)

@end

@implementation UIViewController (__FWCollectionViewController)

- (UICollectionView *)fw_innerCollectionView
{
    UICollectionView *collectionView = objc_getAssociatedObject(self, _cmd);
    if (!collectionView) {
        UICollectionViewLayout *viewLayout = [(id<__FWCollectionViewController>)self setupCollectionViewLayout];
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
    UICollectionView *collectionView = [(id<__FWCollectionViewController>)self collectionView];
    [collectionView fw_pinEdgesToSuperview:UIEdgeInsetsZero];
}

@end
