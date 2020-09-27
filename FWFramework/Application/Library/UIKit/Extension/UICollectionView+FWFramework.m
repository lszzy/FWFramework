/*!
 @header     UICollectionView+FWFramework.m
 @indexgroup FWFramework
 @brief      UICollectionView+FWFramework
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/5/31
 */

#import "UICollectionView+FWFramework.h"
#import <objc/runtime.h>

@implementation UICollectionView (FWFramework)

- (void)fwReloadDataWithCompletion:(void (^)(void))completion
{
    [UIView animateWithDuration:0 animations:^{
        [self reloadData];
    } completion:^(BOOL finished) {
        if (completion) {
            completion();
        }
    }];
}

@end

@implementation UICollectionViewCell (FWFramework)

- (id)fwViewModel
{
    return objc_getAssociatedObject(self, @selector(fwViewModel));
}

- (void)setFwViewModel:(id)fwViewModel
{
    if (fwViewModel != self.fwViewModel) {
        [self willChangeValueForKey:@"fwViewModel"];
        objc_setAssociatedObject(self, @selector(fwViewModel), fwViewModel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [self didChangeValueForKey:@"fwViewModel"];
    }
}

+ (CGSize)fwSizeWithViewModel:(id)viewModel collectionView:(UICollectionView *)collectionView
{
    return CGSizeZero;
}

- (UICollectionView *)fwCollectionView
{
    UIView *superview = self.superview;
    while (superview) {
        if ([superview isKindOfClass:[UICollectionView class]]) {
            return (UICollectionView *)superview;
        }
        superview = superview.superview;
    }
    return nil;
}

- (NSIndexPath *)fwIndexPath
{
    return [[self fwCollectionView] indexPathForCell:self];
}

@end

@implementation UICollectionViewFlowLayout (FWFramework)

- (void)fwHoverWithHeader:(BOOL)header footer:(BOOL)footer
{
    if (@available(iOS 9.0, *)) {
        self.sectionHeadersPinToVisibleBounds = header;
        self.sectionFootersPinToVisibleBounds = footer;
    }
}

@end

@implementation UICollectionReusableView (FWFramework)

- (id)fwViewModel
{
    return objc_getAssociatedObject(self, @selector(fwViewModel));
}

- (void)setFwViewModel:(id)fwViewModel
{
    if (fwViewModel != self.fwViewModel) {
        [self willChangeValueForKey:@"fwViewModel"];
        objc_setAssociatedObject(self, @selector(fwViewModel), fwViewModel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [self didChangeValueForKey:@"fwViewModel"];
    }
}

+ (CGSize)fwSizeWithViewModel:(id)viewModel collectionView:(UICollectionView *)collectionView
{
    return CGSizeZero;
}

@end
