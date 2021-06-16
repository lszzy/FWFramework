/*!
 @header     UICollectionView+FWFramework.m
 @indexgroup FWFramework
 @brief      UICollectionView+FWFramework
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/5/31
 */

#import "UICollectionView+FWFramework.h"
#import "FWDynamicLayout.h"

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

- (void)fwReloadDataWithoutCache
{
    [self fwClearSizeCache];
    [self reloadData];
}

- (void)fwReloadDataWithoutAnimation
{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [self reloadData];
    [CATransaction commit];
}

- (void)fwReloadSectionsWithoutAnimation:(NSIndexSet *)sections
{
    [self performBatchUpdates:^{
        [self reloadSections:sections];
    } completion:nil];
}

- (void)fwReloadItemsWithoutAnimation:(NSArray<NSIndexPath *> *)indexPaths
{
    [self performBatchUpdates:^{
        [self reloadItemsAtIndexPaths:indexPaths];
    } completion:nil];
}

- (void)fwPerformUpdates:(void (NS_NOESCAPE ^)(void))updates
{
    [self performBatchUpdates:updates completion:nil];
}

@end

@implementation UICollectionViewCell (FWFramework)

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
