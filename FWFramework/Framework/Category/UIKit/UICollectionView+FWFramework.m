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

- (id)fwModel
{
    return objc_getAssociatedObject(self, @selector(fwModel));
}

- (void)setFwModel:(id)fwModel
{
    if (fwModel != self.fwModel) {
        [self willChangeValueForKey:@"fwModel"];
        objc_setAssociatedObject(self, @selector(fwModel), fwModel, fwModel ? OBJC_ASSOCIATION_RETAIN_NONATOMIC : OBJC_ASSOCIATION_ASSIGN);
        [self didChangeValueForKey:@"fwModel"];
    }
}

+ (CGSize)fwSizeWithModel:(id)model
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

- (id)fwModel
{
    return objc_getAssociatedObject(self, @selector(fwModel));
}

- (void)setFwModel:(id)fwModel
{
    if (fwModel != self.fwModel) {
        [self willChangeValueForKey:@"fwModel"];
        objc_setAssociatedObject(self, @selector(fwModel), fwModel, fwModel ? OBJC_ASSOCIATION_RETAIN_NONATOMIC : OBJC_ASSOCIATION_ASSIGN);
        [self didChangeValueForKey:@"fwModel"];
    }
}

+ (CGSize)fwSizeWithModel:(id)model
{
    return CGSizeZero;
}

@end
