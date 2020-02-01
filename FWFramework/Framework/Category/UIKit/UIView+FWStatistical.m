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
#import "UIView+FWFramework.h"
#import "NSObject+FWRuntime.h"
#import "UITableView+FWFramework.h"
#import "UICollectionView+FWFramework.h"
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

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self fwSwizzleInstanceMethod:@selector(willMoveToWindow:) with:@selector(fwInnerWillMoveToWindow:)];
    });
}

- (void)fwInnerWillMoveToWindow:(UIWindow *)newWindow
{
    [self fwInnerWillMoveToWindow:newWindow];
    
    if ([self isKindOfClass:[UITableViewCell class]] ||
        [self isKindOfClass:[UICollectionViewCell class]]) {
        if (newWindow && (self.fwStatisticalClick || self.fwStatisticalClickBlock)) {
            UIView *targetView = [self isKindOfClass:[UITableViewCell class]] ? [(UITableViewCell *)self fwTableView] : [(UICollectionViewCell *)self fwCollectionView];
            [targetView fwStatisticalClickRegister];
        }
    }
}

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
    
    if (cell.fwStatisticalClickBlock) {
        cell.fwStatisticalClickBlock(object);
    } else if (self.fwStatisticalClickBlock) {
        self.fwStatisticalClickBlock(object);
    }
    if (cell.fwStatisticalClick || self.fwStatisticalClick) {
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

#pragma mark - UIView+FWExposure

@implementation UIView (FWExposure)

#pragma mark - Hook

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self fwSwizzleInstanceMethod:@selector(setFrame:) with:@selector(fwInnerUIViewSetFrame:)];
        [self fwSwizzleInstanceMethod:@selector(setHidden:) with:@selector(fwInnerUIViewSetHidden:)];
        [self fwSwizzleInstanceMethod:@selector(setAlpha:) with:@selector(fwInnerUIViewSetAlpha:)];
        [self fwSwizzleInstanceMethod:@selector(setBounds:) with:@selector(fwInnerUIViewSetBounds:)];
        [self fwSwizzleInstanceMethod:@selector(didMoveToWindow) with:@selector(fwInnerUIViewDidMoveToWindow)];
    });
}

- (void)fwInnerUIViewSetFrame:(CGRect)frame
{
    [self fwInnerUIViewSetFrame:frame];
    [self fwStatisticalExposureUpdate];
}

- (void)fwInnerUIViewSetBounds:(CGRect)bounds
{
    [self fwInnerUIViewSetBounds:bounds];
    [self fwStatisticalExposureUpdate];
}

- (void)fwInnerUIViewSetHidden:(BOOL)hidden
{
    [self fwInnerUIViewSetHidden:hidden];
    [self fwStatisticalExposureUpdate];
}

- (void)fwInnerUIViewSetAlpha:(CGFloat)alpha
{
    [self fwInnerUIViewSetAlpha:alpha];
    [self fwStatisticalExposureUpdate];
}

- (void)fwInnerUIViewDidMoveToWindow
{
    [self fwInnerUIViewDidMoveToWindow];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(fwStatisticalExposureCalculate) object:nil];
    [self performSelector:@selector(fwStatisticalExposureUpdate) withObject:nil afterDelay:0 inModes:@[NSDefaultRunLoopMode]];
}

#pragma mark - Exposure

- (FWStatisticalExposureState)fwExposureStateInSuperview:(UIView *)superview
{
    if (superview == nil || self == nil || self.hidden || self.alpha <= 0.01 || !self.window ||
        self.bounds.size.width == 0 || self.bounds.size.height == 0) {
        return FWStatisticalExposureStateNone;
    }
    
    CGRect viewRect = [self convertRect:self.bounds toView:superview];
    CGRect superviewRect = superview.bounds;
    if (!CGRectIsEmpty(viewRect) && !CGRectIsNull(viewRect)) {
        if (CGRectContainsRect(superviewRect, viewRect)) {
            return FWStatisticalExposureStateFully;
        } else if (CGRectIntersectsRect(superviewRect, viewRect)) {
            return FWStatisticalExposureStatePartly;
        }
    }
    return FWStatisticalExposureStateNone;
}

- (FWStatisticalExposureState)fwExposureStateInViewController
{
    return [self fwExposureStateInSuperview:self.fwViewController.view];
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

- (BOOL)fwStatisticalExposureEnabled
{
    return [objc_getAssociatedObject(self, @selector(fwStatisticalExposureEnabled)) boolValue];
}

- (void)fwStatisticalExposureEnable
{
    if ([self fwStatisticalExposureEnabled]) return;
    objc_setAssociatedObject(self, @selector(fwStatisticalExposureEnabled), @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if (self.superview) {
        [self.superview fwStatisticalExposureEnable];
    }
}

- (BOOL)fwStatisticalExposureRegistered
{
    return [objc_getAssociatedObject(self, @selector(fwStatisticalExposureRegistered)) boolValue];
}

- (void)fwStatisticalExposureRegister
{
    if ([self fwStatisticalExposureRegistered]) return;
    objc_setAssociatedObject(self, @selector(fwStatisticalExposureRegistered), @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if ([self isKindOfClass:[UITableView class]]) {
        
        return;
    }
    
    if ([self isKindOfClass:[UICollectionView class]]) {
        
        return;
    }
    
    //if (![self isKindOfClass:[UITableViewCell class]] &&
        //![self isKindOfClass:[UICollectionViewCell class]]) {
        if (self.superview) {
            [self.superview fwStatisticalExposureEnable];
        }
    //}
}

- (FWStatisticalExposureState)fwStatisticalExposureState
{
    return [objc_getAssociatedObject(self, @selector(fwStatisticalExposureState)) integerValue];
}

- (BOOL)fwStatisticalExposureFully
{
    return [objc_getAssociatedObject(self, @selector(fwStatisticalExposureFully)) boolValue];
}

- (void)setFwStatisticalExposureFully:(BOOL)fully
{
    objc_setAssociatedObject(self, @selector(fwStatisticalExposureFully), @(fully), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setFwStatisticalExposureState:(FWStatisticalExposureState)state
{
    FWStatisticalExposureState oldState = [self fwStatisticalExposureState];
    if (state != oldState) {
        objc_setAssociatedObject(self, @selector(fwStatisticalExposureState), @(state), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        if (state == FWStatisticalExposureStateFully && ![self fwStatisticalExposureFully]) {
            if ([self isKindOfClass:[UITableViewCell class]]) {
                [self fwStatisticalExposureHandler:nil indexPath:((UITableViewCell *)self).fwIndexPath];
            } else {
                [self fwStatisticalExposureHandler:nil indexPath:nil];
            }
        }
        
        if (state == FWStatisticalExposureStateFully) {
            [self setFwStatisticalExposureFully:YES];
        } else if (state == FWStatisticalExposureStateNone) {
            [self setFwStatisticalExposureFully:NO];
        }
    }
}

- (void)fwStatisticalExposureUpdate
{
    if (![self fwStatisticalExposureRegistered] && ![self fwStatisticalExposureEnabled]) return;

    if ([self fwStatisticalExposureRegistered]) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(fwStatisticalExposureCalculate) object:nil];
        [self performSelector:@selector(fwStatisticalExposureCalculate) withObject:nil afterDelay:0 inModes:@[NSDefaultRunLoopMode]];
    }
    
    [self.subviews enumerateObjectsUsingBlock:^(UIView *obj, NSUInteger idx, BOOL *stop) {
        [obj fwStatisticalExposureUpdate];
    }];
}

- (void)fwStatisticalExposureCalculate
{
    static NSMutableDictionary *counts = nil;
    static NSInteger index = 0;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        counts = [NSMutableDictionary new];
    });

    if ([self fwStatisticalExposureRegistered]) {
        NSInteger count = [[counts objectForKey:@(self.hash)] integerValue];
        [counts setObject:@(++count) forKey:@(self.hash)];
        //NSLog(@"%@: %@ => %@", @(++index), @(self.hash), @(count));
        
        [self setFwStatisticalExposureState:[self fwExposureStateInViewController]];
        return;
    }
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
