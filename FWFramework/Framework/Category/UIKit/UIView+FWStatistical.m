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
#import "UIWindow+FWFramework.h"
#import "FWAspect.h"
#import <objc/runtime.h>

#pragma mark - FWStatistical

NSString *const FWStatisticalEventTriggeredNotification = @"FWStatisticalEventTriggeredNotification";

@interface FWStatisticalObject ()

@property (nonatomic, weak, nullable) __kindof UIView *view;
@property (nonatomic, strong, nullable) NSIndexPath *indexPath;

@end

@implementation FWStatisticalObject

- (instancetype)initWithName:(NSString *)name
{
    return [self initWithName:name object:nil];
}

- (instancetype)initWithName:(NSString *)name object:(id)object
{
    return [self initWithName:name object:object userInfo:nil];
}

- (instancetype)initWithName:(NSString *)name object:(id)object userInfo:(NSDictionary *)userInfo
{
    self = [super init];
    if (self) {
        _name = [name copy];
        _object = object;
        _userInfo = [userInfo copy];
    }
    return self;
}

@end

#pragma mark - UIView+FWStatistical

@implementation UIView (FWStatistical)

#pragma mark - Click

- (FWStatisticalObject *)fwStatisticalClick
{
    return objc_getAssociatedObject(self, @selector(fwStatisticalClick));
}

- (void)setFwStatisticalClick:(FWStatisticalObject *)fwStatisticalClick
{
    objc_setAssociatedObject(self, @selector(fwStatisticalClick), fwStatisticalClick, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [self fwStatisticalClickRegister];
}

- (FWStatisticalBlock)fwStatisticalClickBlock
{
    return objc_getAssociatedObject(self, @selector(fwStatisticalClickBlock));
}

- (void)setFwStatisticalClickBlock:(FWStatisticalBlock)fwStatisticalClickBlock
{
    objc_setAssociatedObject(self, @selector(fwStatisticalClickBlock), fwStatisticalClickBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
    
    [self fwStatisticalClickRegister];
}

- (void)fwStatisticalClickRegister
{
    if (objc_getAssociatedObject(self, _cmd) != nil) return;
    objc_setAssociatedObject(self, _cmd, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if ([self isKindOfClass:[UITableView class]]) {
        [(NSObject *)((UITableView *)self).delegate fwHookSelector:@selector(tableView:didSelectRowAtIndexPath:) withBlock:^(id<FWAspectInfo> aspectInfo, UITableView *tableView, NSIndexPath *indexPath){
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            [tableView fwStatisticalClickHandler:cell indexPath:indexPath];
        } options:FWAspectPositionAfter error:NULL];
        return;
    }
    
    if ([self isKindOfClass:[UICollectionView class]]) {
        [(NSObject *)((UICollectionView *)self).delegate fwHookSelector:@selector(collectionView:didSelectItemAtIndexPath:) withBlock:^(id<FWAspectInfo> aspectInfo, UICollectionView *collectionView, NSIndexPath *indexPath){
            UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
            [collectionView fwStatisticalClickHandler:cell indexPath:indexPath];
        } options:FWAspectPositionAfter error:NULL];
        return;
    }
    
    if ([self isKindOfClass:[UIControl class]]) {
        [(UIControl *)self fwAddBlock:^(UIControl *sender) {
            [sender fwStatisticalClickHandler:nil indexPath:nil];
        } forControlEvents:UIControlEventTouchUpInside];
        return;
    }
    
    if (![self isKindOfClass:[UITableViewCell class]] &&
        ![self isKindOfClass:[UICollectionViewCell class]]) {
        for (UIGestureRecognizer *gesture in self.gestureRecognizers) {
            if ([gesture isKindOfClass:[UITapGestureRecognizer class]]) {
                [gesture fwAddBlock:^(UIGestureRecognizer *sender) {
                    [sender.view fwStatisticalClickHandler:nil indexPath:nil];
                }];
            }
        }
    }
}

- (void)fwStatisticalClickHandler:(UIView *)cell indexPath:(NSIndexPath *)indexPath
{
    FWStatisticalObject *object = cell.fwStatisticalClick ?: self.fwStatisticalClick;
    if (!object) {
        object = [FWStatisticalObject new];
    }
    object.view = self;
    object.indexPath = indexPath;
    if (self.fwStatisticalClickBlock) {
        self.fwStatisticalClickBlock(object);
    }
    if (self.fwStatisticalClick) {
        [[NSNotificationCenter defaultCenter] postNotificationName:FWStatisticalEventTriggeredNotification object:object userInfo:object.userInfo];
    }
}

#pragma mark - Exposure

- (BOOL)fwIsExposed
{
    if (self == nil || self.hidden || self.alpha <= 0.1 || !self.window ||
        self.bounds.size.width == 0 || self.bounds.size.height == 0) {
        return NO;
    }
    
    CGRect rect = [self convertRect:self.bounds toView:UIWindow.fwMainWindow];
    CGRect screenRect = [UIScreen mainScreen].bounds;
    if (CGRectContainsRect(screenRect, rect) && !CGRectIsEmpty(rect) && !CGRectIsNull(rect)) {
        return YES;
    }
    return NO;
}

- (FWStatisticalObject *)fwStatisticalExposure
{
    return objc_getAssociatedObject(self, @selector(fwStatisticalExposure));
}

- (void)setFwStatisticalExposure:(FWStatisticalObject *)fwStatisticalExposure
{
    objc_setAssociatedObject(self, @selector(fwStatisticalExposure), fwStatisticalExposure, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [self fwStatisticalExposureRegister];
}

- (FWStatisticalBlock)fwStatisticalExposureBlock
{
    return objc_getAssociatedObject(self, @selector(fwStatisticalExposureBlock));
}

- (void)setFwStatisticalExposureBlock:(FWStatisticalBlock)fwStatisticalExposureBlock
{
    objc_setAssociatedObject(self, @selector(fwStatisticalExposureBlock), fwStatisticalExposureBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
    
    [self fwStatisticalExposureRegister];
}

- (void)fwStatisticalExposureRegister
{
    if (objc_getAssociatedObject(self, _cmd) != nil) return;
    objc_setAssociatedObject(self, _cmd, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
}

- (void)fwStatisticalExposureHandler:(UIView *)cell indexPath:(NSIndexPath *)indexPath
{
    FWStatisticalObject *object = cell.fwStatisticalExposure ?: self.fwStatisticalExposure;
    if (!object) {
        object = [FWStatisticalObject new];
    }
    object.view = self;
    object.indexPath = indexPath;
    if (self.fwStatisticalExposureBlock) {
        self.fwStatisticalExposureBlock(object);
    }
    if (self.fwStatisticalExposure) {
        [[NSNotificationCenter defaultCenter] postNotificationName:FWStatisticalEventTriggeredNotification object:object userInfo:object.userInfo];
    }
}

@end

@implementation UIControl (FWStatistical)

#pragma mark - Changed

- (FWStatisticalObject *)fwStatisticalChanged
{
    return objc_getAssociatedObject(self, @selector(fwStatisticalChanged));
}

- (void)setFwStatisticalChanged:(FWStatisticalObject *)fwStatisticalChanged
{
    objc_setAssociatedObject(self, @selector(fwStatisticalChanged), fwStatisticalChanged, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [self fwStatisticalChangedRegister];
}

- (FWStatisticalBlock)fwStatisticalChangedBlock
{
    return objc_getAssociatedObject(self, @selector(fwStatisticalChangedBlock));
}

- (void)setFwStatisticalChangedBlock:(FWStatisticalBlock)fwStatisticalChangedBlock
{
    objc_setAssociatedObject(self, @selector(fwStatisticalChangedBlock), fwStatisticalChangedBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
    
    [self fwStatisticalChangedRegister];
}

- (void)fwStatisticalChangedRegister
{
    if (objc_getAssociatedObject(self, _cmd) != nil) return;
    objc_setAssociatedObject(self, _cmd, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [self fwAddBlock:^(UIControl *sender) {
        [sender fwStatisticalChangedHandler];
    } forControlEvents:UIControlEventValueChanged];
}

- (void)fwStatisticalChangedHandler
{
    FWStatisticalObject *object = self.fwStatisticalChanged ?: [FWStatisticalObject new];
    object.view = self;
    if (self.fwStatisticalChangedBlock) {
        self.fwStatisticalChangedBlock(object);
    }
    if (self.fwStatisticalChanged) {
        [[NSNotificationCenter defaultCenter] postNotificationName:FWStatisticalEventTriggeredNotification object:object userInfo:object.userInfo];
    }
}

@end
