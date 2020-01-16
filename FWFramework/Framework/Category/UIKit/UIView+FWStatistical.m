/*!
 @header     UIView+FWStatistical.m
 @indexgroup FWFramework
 @brief      UIView+FWStatistical
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/1/16
 */

#import "UIView+FWStatistical.h"
#import "UIView+FWBlock.h"
#import "FWAspect.h"
#import <objc/runtime.h>

@implementation UIView (FWStatistical)

#pragma mark - Click

- (void)fwTrackTappedWithBlock:(void (^)(id))block
{
    [self fwTrackGesture:[UITapGestureRecognizer class] withBlock:block];
}

- (void)fwTrackGesture:(Class)clazz withBlock:(void (^)(id))block
{
    for (UIGestureRecognizer *gesture in self.gestureRecognizers) {
        if ([gesture isKindOfClass:clazz]) {
            [gesture fwAddBlock:block];
        }
    }
}

@end

@implementation UIControl (FWStatistical)

#pragma mark - Click

- (void)fwTrackTouchedWithBlock:(void (^)(id))block
{
    [self fwTrackEvent:UIControlEventTouchUpInside withBlock:block];
}

- (void)fwTrackChangedWithBlock:(void (^)(id))block
{
    [self fwTrackEvent:UIControlEventValueChanged withBlock:block];
}

- (void)fwTrackEvent:(UIControlEvents)event withBlock:(void (^)(id))block
{
    [self fwAddBlock:block forControlEvents:event];
}

@end

@implementation UITableView (FWStatistical)

#pragma mark - Click

- (void)fwTrackSelectWithBlock:(void (^)(UITableView *, NSIndexPath *))block
{
    objc_setAssociatedObject(self, @selector(fwTrackSelectWithBlock:), block, OBJC_ASSOCIATION_COPY_NONATOMIC);
    [(NSObject *)self.delegate fwHookSelector:@selector(tableView:didSelectRowAtIndexPath:) withBlock:^(id<FWAspectInfo> aspectInfo, UITableView *tableView, NSIndexPath *indexPath){
        void (^trackBlock)(UITableView *, NSIndexPath *) = objc_getAssociatedObject(tableView, @selector(fwTrackSelectWithBlock:));
        if (trackBlock) {
            trackBlock(tableView, indexPath);
        }
    } options:FWAspectPositionAfter error:NULL];
}

@end

@implementation UICollectionView (FWStatistical)

#pragma mark - Click

- (void)fwTrackSelectWithBlock:(void (^)(UICollectionView *, NSIndexPath *))block
{
    objc_setAssociatedObject(self, @selector(fwTrackSelectWithBlock:), block, OBJC_ASSOCIATION_COPY_NONATOMIC);
    [(NSObject *)self.delegate fwHookSelector:@selector(collectionView:didSelectItemAtIndexPath:) withBlock:^(id<FWAspectInfo> aspectInfo, UICollectionView *collectionView, NSIndexPath *indexPath){
        void (^trackBlock)(UICollectionView *, NSIndexPath *) = objc_getAssociatedObject(collectionView, @selector(fwTrackSelectWithBlock:));
        if (trackBlock) {
            trackBlock(collectionView, indexPath);
        }
    } options:FWAspectPositionAfter error:NULL];
}

@end
