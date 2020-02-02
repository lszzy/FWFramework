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

@interface FWStatisticalManager ()

@property (nonatomic, strong) NSMutableDictionary *eventHandlers;

@end

@implementation FWStatisticalManager

+ (instancetype)sharedInstance
{
    static FWStatisticalManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FWStatisticalManager alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _eventHandlers = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)registerEvent:(NSString *)name withHandler:(FWStatisticalBlock)handler
{
    [self.eventHandlers setObject:handler forKey:name];
}

- (void)handleEvent:(FWStatisticalObject *)object
{
    FWStatisticalBlock eventHandler = [self.eventHandlers objectForKey:object.name];
    if (eventHandler) {
        eventHandler(object);
    }
    if (self.globalHandler) {
        self.globalHandler(object);
    }
    if (self.notificationEnabled) {
        [[NSNotificationCenter defaultCenter] postNotificationName:FWStatisticalEventTriggeredNotification object:object userInfo:object.userInfo];
    }
}

@end

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
    
    if ([self conformsToProtocol:@protocol(FWStatisticalDelegate)] && [self respondsToSelector:@selector(statisticalClickWithCallback:)]) {
        __weak __typeof__(self) self_weak_ = self;
        [(id<FWStatisticalDelegate>)self statisticalClickWithCallback:^(__kindof UIView * _Nullable cell, NSIndexPath * _Nullable indexPath) {
            __typeof__(self) self = self_weak_;
            [self fwStatisticalClickHandler:cell indexPath:indexPath];
        }];
        return;
    }
    
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
    
    if (![self isKindOfClass:[UITableViewCell class]] && ![self isKindOfClass:[UICollectionViewCell class]]) {
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
        [[FWStatisticalManager sharedInstance] handleEvent:object];
    }
}

@end

@implementation UIControl (FWStatistical)

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
        [[FWStatisticalManager sharedInstance] handleEvent:object];
    }
}

@end

#pragma mark - UIView+FWExposure

typedef NS_ENUM(NSInteger, FWStatisticalExposureState) {
    FWStatisticalExposureStateNone,
    FWStatisticalExposureStatePartly,
    FWStatisticalExposureStateFully,
};

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
        [self fwSwizzleInstanceMethod:@selector(willMoveToWindow:) with:@selector(fwInnerUIViewWillMoveToWindow:)];
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

- (void)fwInnerUIViewWillMoveToWindow:(UIWindow *)newWindow
{
    [self fwInnerUIViewWillMoveToWindow:newWindow];
    
    if (newWindow && ([self isKindOfClass:[UITableViewCell class]] || [self isKindOfClass:[UICollectionViewCell class]])) {
        if (self.fwStatisticalClick || self.fwStatisticalClickBlock) {
            UIView *targetView = [self isKindOfClass:[UITableViewCell class]] ? [(UITableViewCell *)self fwTableView] : [(UICollectionViewCell *)self fwCollectionView];
            [targetView fwStatisticalClickRegister];
        }
        if (self.fwStatisticalExposure || self.fwStatisticalExposureBlock) {
            UIView *targetView = [self isKindOfClass:[UITableViewCell class]] ? [(UITableViewCell *)self fwTableView] : [(UICollectionViewCell *)self fwCollectionView];
            [targetView fwStatisticalExposureRegister];
        }
    }
}

- (void)fwInnerUIViewDidMoveToWindow
{
    [self fwInnerUIViewDidMoveToWindow];
    
    if (![self fwStatisticalExposureIsRegistered]) return;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(fwStatisticalExposureCalculate) object:nil];
    [self performSelector:@selector(fwStatisticalExposureUpdate) withObject:nil afterDelay:0 inModes:@[NSDefaultRunLoopMode]];
}

#pragma mark - Exposure

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

- (BOOL)fwStatisticalExposureIsFully
{
    return [objc_getAssociatedObject(self, @selector(fwStatisticalExposureIsFully)) boolValue];
}

- (void)setFwStatisticalExposureIsFully:(BOOL)isFully
{
    objc_setAssociatedObject(self, @selector(fwStatisticalExposureIsFully), @(isFully), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSIndexPath *)fwStatisticalExposureIndexPath
{
    return objc_getAssociatedObject(self, @selector(fwStatisticalExposureIndexPath));
}

- (BOOL)fwStatisticalExposureIndexPathChanged
{
    if ([self isKindOfClass:[UITableViewCell class]] || [self isKindOfClass:[UICollectionViewCell class]]) {
        NSIndexPath *oldIndexPath = [self fwStatisticalExposureIndexPath];
        NSIndexPath *indexPath = [(UITableViewCell *)self fwIndexPath];
        objc_setAssociatedObject(self, @selector(fwStatisticalExposureIndexPath), indexPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        if (indexPath && (!oldIndexPath || [indexPath compare:oldIndexPath] != NSOrderedSame)) {
            [self setFwStatisticalExposureIsFully:NO];
            return YES;
        }
    }
    return NO;
}

- (FWStatisticalExposureState)fwStatisticalExposureState
{
    return [objc_getAssociatedObject(self, @selector(fwStatisticalExposureState)) integerValue];
}

- (void)setFwStatisticalExposureState:(FWStatisticalExposureState)state
{
    FWStatisticalExposureState oldState = [self fwStatisticalExposureState];
    BOOL indexPathChanged = [self fwStatisticalExposureIndexPathChanged];
    if (state == oldState && !indexPathChanged) return;
    objc_setAssociatedObject(self, @selector(fwStatisticalExposureState), @(state), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (state == FWStatisticalExposureStateNone) {
        [self setFwStatisticalExposureIsFully:NO];
        return;
    }
    if (state != FWStatisticalExposureStateFully || [self fwStatisticalExposureIsFully]) return;
    
    [self setFwStatisticalExposureIsFully:YES];
    if ([self conformsToProtocol:@protocol(FWStatisticalDelegate)] && [self respondsToSelector:@selector(statisticalExposureWithCallback:)]) {
        __weak __typeof__(self) self_weak_ = self;
        [(id<FWStatisticalDelegate>)self statisticalExposureWithCallback:^(__kindof UIView * _Nullable cell, NSIndexPath * _Nullable indexPath) {
            __typeof__(self) self = self_weak_;
            if ([self fwExposureStateInViewController] == FWStatisticalExposureStateFully) {
                [self fwStatisticalExposureHandler:cell indexPath:indexPath];
            }
        }];
    } else if ([self isKindOfClass:[UITableViewCell class]]) {
        [((UITableViewCell *)self).fwTableView fwStatisticalExposureHandler:self indexPath:((UITableViewCell *)self).fwIndexPath];
    } else if ([self isKindOfClass:[UICollectionViewCell class]]) {
        [((UICollectionViewCell *)self).fwCollectionView fwStatisticalExposureHandler:self indexPath:((UICollectionViewCell *)self).fwIndexPath];
    } else {
        [self fwStatisticalExposureHandler:nil indexPath:nil];
    }
}

- (FWStatisticalExposureState)fwExposureStateInViewController
{
    if (self == nil || self.hidden || self.alpha <= 0.01 || !self.window ||
        self.bounds.size.width == 0 || self.bounds.size.height == 0) {
        return FWStatisticalExposureStateNone;
    }
    
    UIView *targetView = self.fwViewController.view ?: self.window;
    UIView *superview = self.superview;
    BOOL superviewHidden = NO;
    while (superview && superview != targetView) {
        if (superview.hidden || superview.alpha <= 0.01 ||
            superview.bounds.size.width == 0 || superview.bounds.size.height == 0) {
            superviewHidden = YES;
            break;
        }
        superview = superview.superview;
    }
    if (superviewHidden) {
        return FWStatisticalExposureStateNone;
    }
    
    CGRect viewRect = [self convertRect:self.bounds toView:targetView];
    CGRect targetRect = targetView.bounds;
    if (!CGRectIsEmpty(viewRect) && !CGRectIsNull(viewRect)) {
        if (CGRectContainsRect(targetRect, viewRect)) {
            return FWStatisticalExposureStateFully;
        } else if (CGRectIntersectsRect(targetRect, viewRect)) {
            return FWStatisticalExposureStatePartly;
        }
    }
    return FWStatisticalExposureStateNone;
}

- (BOOL)fwStatisticalExposureIsRegistered
{
    if (![objc_getAssociatedObject(self, @selector(fwStatisticalExposureIsRegistered)) boolValue]) return NO;
    if ([self isKindOfClass:[UITableViewCell class]] || [self isKindOfClass:[UICollectionViewCell class]]) return NO;
    return YES;
}

- (void)fwStatisticalExposureRegister
{
    if ([objc_getAssociatedObject(self, @selector(fwStatisticalExposureIsRegistered)) boolValue]) return;
    objc_setAssociatedObject(self, @selector(fwStatisticalExposureIsRegistered), @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if ([self isKindOfClass:[UITableViewCell class]] || [self isKindOfClass:[UICollectionViewCell class]]) return;
    
    if (self.superview) {
        [self.superview fwStatisticalExposureRegister];
    }
}

- (void)fwStatisticalExposureUpdate
{
    if (![self fwStatisticalExposureIsRegistered]) return;

    if ([self isKindOfClass:[UITableView class]] || [self isKindOfClass:[UICollectionView class]] ||
        self.fwStatisticalExposure || self.fwStatisticalExposureBlock) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(fwStatisticalExposureCalculate) object:nil];
        [self performSelector:@selector(fwStatisticalExposureCalculate) withObject:nil afterDelay:0 inModes:@[NSDefaultRunLoopMode]];
    }
    
    [self.subviews enumerateObjectsUsingBlock:^(UIView *obj, NSUInteger idx, BOOL *stop) {
        [obj fwStatisticalExposureUpdate];
    }];
}

- (void)fwStatisticalExposureCalculate
{
    if ([self isKindOfClass:[UITableView class]]) {
        [((UITableView *)self).visibleCells enumerateObjectsUsingBlock:^(__kindof UITableViewCell *obj, NSUInteger idx, BOOL *stop) {
            [obj fwStatisticalExposureCalculate];
        }];
    } else if ([self isKindOfClass:[UICollectionView class]]) {
        [((UICollectionView *)self).visibleCells enumerateObjectsUsingBlock:^(__kindof UICollectionViewCell *obj, NSUInteger idx, BOOL *stop) {
            [obj fwStatisticalExposureCalculate];
        }];
    } else {
        [self setFwStatisticalExposureState:[self fwExposureStateInViewController]];
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
    
    if (cell.fwStatisticalExposureBlock) {
        cell.fwStatisticalExposureBlock(object);
    } else if (self.fwStatisticalExposureBlock) {
        self.fwStatisticalExposureBlock(object);
    }
    if (cell.fwStatisticalExposure || self.fwStatisticalExposure) {
        [[FWStatisticalManager sharedInstance] handleEvent:object];
    }
}

@end
