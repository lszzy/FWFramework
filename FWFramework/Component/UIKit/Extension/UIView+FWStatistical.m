/*!
 @header     UIView+FWStatistical.m
 @indexgroup FWFramework
 @brief      UIView+FWStatistical
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/2/4
 */

#import "UIView+FWStatistical.h"
#import "NSObject+FWRuntime.h"
#import "UIView+FWFramework.h"
#import "UITableView+FWFramework.h"
#import "UICollectionView+FWFramework.h"
#import "FWSwizzle.h"
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
        _runLoopMode = NSDefaultRunLoopMode;
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
@property (nonatomic, assign) NSInteger triggerCount;

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

- (BOOL)fwStatisticalClickIsRegistered
{
    return [objc_getAssociatedObject(self, @selector(fwStatisticalClickIsRegistered)) boolValue];
}

#pragma mark - Private

- (void)fwStatisticalClickRegister
{
    if ([self fwStatisticalClickIsRegistered]) return;
    objc_setAssociatedObject(self, @selector(fwStatisticalClickIsRegistered), @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if ([self isKindOfClass:[UITableViewCell class]] || [self isKindOfClass:[UICollectionViewCell class]]) {
        [self fwStatisticalClickCellRegister];
        return;
    }
    
    if ([self conformsToProtocol:@protocol(FWStatisticalDelegate)] &&
        [self respondsToSelector:@selector(statisticalClickWithCallback:)]) {
        __weak __typeof__(self) self_weak_ = self;
        [(id<FWStatisticalDelegate>)self statisticalClickWithCallback:^(__kindof UIView * _Nullable cell, NSIndexPath * _Nullable indexPath) {
            __typeof__(self) self = self_weak_;
            [self fwStatisticalClickHandler:cell indexPath:indexPath];
        }];
        return;
    }
    
    if ([self isKindOfClass:[UITableView class]]) {
        FWSwizzleMethod(((UITableView *)self).delegate, @selector(tableView:didSelectRowAtIndexPath:), @"FWStatisticalManager", FWSwizzleType(NSObject<UITableViewDelegate> *), FWSwizzleReturn(void), FWSwizzleArgs(UITableView *tableView, NSIndexPath *indexPath), FWSwizzleCode({
            FWSwizzleOriginal(tableView, indexPath);
            
            if (![selfObject fwIsSwizzleMethod:@selector(tableView:didSelectRowAtIndexPath:) identifier:@"FWStatisticalManager"]) return;
            if (![tableView fwStatisticalClickIsRegistered]) return;
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            [tableView fwStatisticalClickHandler:cell indexPath:indexPath];
        }));
        return;
    }
    
    if ([self isKindOfClass:[UICollectionView class]]) {
        FWSwizzleMethod(((UICollectionView *)self).delegate, @selector(collectionView:didSelectItemAtIndexPath:), @"FWStatisticalManager", FWSwizzleType(NSObject<UICollectionViewDelegate> *), FWSwizzleReturn(void), FWSwizzleArgs(UICollectionView *collectionView, NSIndexPath *indexPath), FWSwizzleCode({
            FWSwizzleOriginal(collectionView, indexPath);
            
            if (![selfObject fwIsSwizzleMethod:@selector(collectionView:didSelectItemAtIndexPath:) identifier:@"FWStatisticalManager"]) return;
            if (![collectionView fwStatisticalClickIsRegistered]) return;
            UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
            [collectionView fwStatisticalClickHandler:cell indexPath:indexPath];
        }));
        return;
    }
    
    if ([self isKindOfClass:[UIControl class]]) {
        [(UIControl *)self fwAddBlock:^(UIControl *sender) {
            [sender fwStatisticalClickHandler:nil indexPath:nil];
        } forControlEvents:UIControlEventTouchUpInside];
        return;
    }
    
    for (UIGestureRecognizer *gesture in self.gestureRecognizers) {
        if ([gesture isKindOfClass:[UITapGestureRecognizer class]]) {
            [gesture fwAddBlock:^(UIGestureRecognizer *sender) {
                [sender.view fwStatisticalClickHandler:nil indexPath:nil];
            }];
        }
    }
}

- (void)fwStatisticalClickCellRegister
{
    if (!self.superview) return;
    if ([objc_getAssociatedObject(self, _cmd) boolValue]) return;
    objc_setAssociatedObject(self, _cmd, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    UIView *proxyView = nil;
    if ([self conformsToProtocol:@protocol(FWStatisticalDelegate)] &&
        [self respondsToSelector:@selector(statisticalCellProxyView)]) {
        proxyView = [(id<FWStatisticalDelegate>)self statisticalCellProxyView];
    } else {
        proxyView = [self isKindOfClass:[UITableViewCell class]] ? [(UITableViewCell *)self fwTableView] : [(UICollectionViewCell *)self fwCollectionView];
    }
    [proxyView fwStatisticalClickRegister];
}

- (NSInteger)fwStatisticalClickCount:(NSIndexPath *)indexPath
{
    NSMutableDictionary *triggerDict = objc_getAssociatedObject(self, _cmd);
    if (!triggerDict) {
        triggerDict = [[NSMutableDictionary alloc] init];
        objc_setAssociatedObject(self, _cmd, triggerDict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    NSString *triggerKey = [NSString stringWithFormat:@"%@.%@", @(indexPath.section), @(indexPath.row)];
    NSInteger triggerCount = [[triggerDict objectForKey:triggerKey] integerValue] + 1;
    [triggerDict setObject:@(triggerCount) forKey:triggerKey];
    return triggerCount;
}

- (void)fwStatisticalClickHandler:(UIView *)cell indexPath:(NSIndexPath *)indexPath
{
    FWStatisticalObject *object = cell.fwStatisticalClick ?: self.fwStatisticalClick;
    if (!object) object = [FWStatisticalObject new];
    object.view = self;
    object.indexPath = indexPath;
    NSInteger triggerCount = [self fwStatisticalClickCount:indexPath];
    if (triggerCount > 1 && object.triggerOnce) return;
    object.triggerCount = triggerCount;
    
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

#pragma mark - Private

- (void)fwStatisticalChangedRegister
{
    if (objc_getAssociatedObject(self, _cmd) != nil) return;
    objc_setAssociatedObject(self, _cmd, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [self fwAddBlock:^(UIControl *sender) {
        [sender fwStatisticalChangedHandler];
    } forControlEvents:UIControlEventValueChanged];
}

- (NSInteger)fwStatisticalChangedCount
{
    NSInteger triggerCount = [objc_getAssociatedObject(self, _cmd) integerValue] + 1;
    objc_setAssociatedObject(self, _cmd, @(triggerCount), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return triggerCount;
}

- (void)fwStatisticalChangedHandler
{
    FWStatisticalObject *object = self.fwStatisticalChanged ?: [FWStatisticalObject new];
    object.view = self;
    NSInteger triggerCount = [self fwStatisticalChangedCount];
    if (triggerCount > 1 && object.triggerOnce) return;
    object.triggerCount = triggerCount;
    
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
        FWSwizzleClass(UIView, @selector(setFrame:), FWSwizzleReturn(void), FWSwizzleArgs(CGRect frame), FWSwizzleCode({
            FWSwizzleOriginal(frame);
            
            [selfObject fwStatisticalExposureUpdate];
        }));
        FWSwizzleClass(UIView, @selector(setHidden:), FWSwizzleReturn(void), FWSwizzleArgs(BOOL hidden), FWSwizzleCode({
            FWSwizzleOriginal(hidden);
            
            [selfObject fwStatisticalExposureUpdate];
        }));
        FWSwizzleClass(UIView, @selector(setAlpha:), FWSwizzleReturn(void), FWSwizzleArgs(CGFloat alpha), FWSwizzleCode({
            FWSwizzleOriginal(alpha);
            
            [selfObject fwStatisticalExposureUpdate];
        }));
        FWSwizzleClass(UIView, @selector(setBounds:), FWSwizzleReturn(void), FWSwizzleArgs(CGRect bounds), FWSwizzleCode({
            FWSwizzleOriginal(bounds);
            
            [selfObject fwStatisticalExposureUpdate];
        }));
        FWSwizzleClass(UIView, @selector(didMoveToWindow), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            FWSwizzleOriginal();
            
            if (![selfObject fwStatisticalExposureIsRegistered]) return;
            [NSObject cancelPreviousPerformRequestsWithTarget:selfObject selector:@selector(fwStatisticalExposureCalculate) object:nil];
            [selfObject performSelector:@selector(fwStatisticalExposureUpdate) withObject:nil afterDelay:0 inModes:@[FWStatisticalManager.sharedInstance.runLoopMode]];
        }));
        
        FWSwizzleClass(UITableView, @selector(reloadData), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            FWSwizzleOriginal();
            
            [selfObject fwStatisticalExposureUpdate];
        }));
        FWSwizzleClass(UICollectionView, @selector(reloadData), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            FWSwizzleOriginal();
            
            [selfObject fwStatisticalExposureUpdate];
        }));
        FWSwizzleClass(UITableViewCell, @selector(didMoveToSuperview), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            FWSwizzleOriginal();
            
            if (selfObject.fwStatisticalClick || selfObject.fwStatisticalClickBlock) {
                [selfObject fwStatisticalClickCellRegister];
            }
            if (selfObject.fwStatisticalExposure || selfObject.fwStatisticalExposureBlock) {
                [selfObject fwStatisticalExposureCellRegister];
            }
        }));
        FWSwizzleClass(UICollectionViewCell, @selector(didMoveToSuperview), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            FWSwizzleOriginal();
            
            if (selfObject.fwStatisticalClick || selfObject.fwStatisticalClickBlock) {
                [selfObject fwStatisticalClickCellRegister];
            }
            if (selfObject.fwStatisticalExposure || selfObject.fwStatisticalExposureBlock) {
                [selfObject fwStatisticalExposureCellRegister];
            }
        }));
    });
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

#pragma mark - Accessor

- (BOOL)fwStatisticalExposureIsProxy
{
    return [objc_getAssociatedObject(self, @selector(fwStatisticalExposureIsProxy)) boolValue];
}

- (void)setFwStatisticalExposureIsProxy:(BOOL)isProxy
{
    objc_setAssociatedObject(self, @selector(fwStatisticalExposureIsProxy), @(isProxy), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)fwStatisticalExposureIsFully
{
    return [objc_getAssociatedObject(self, @selector(fwStatisticalExposureIsFully)) boolValue];
}

- (void)setFwStatisticalExposureIsFully:(BOOL)isFully
{
    objc_setAssociatedObject(self, @selector(fwStatisticalExposureIsFully), @(isFully), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)fwStatisticalExposureIdentifier
{
    NSIndexPath *indexPath = nil;
    if ([self isKindOfClass:[UITableViewCell class]] || [self isKindOfClass:[UICollectionView class]]) {
        indexPath = [(UITableViewCell *)self fwIndexPath];
    }
    
    NSString *identifier = [NSString stringWithFormat:@"%@-%@-%@-%@", @(indexPath.section), @(indexPath.row), self.fwStatisticalExposure.name, self.fwStatisticalExposure.object];
    return identifier;
}

- (BOOL)fwStatisticalExposureCustom
{
    if ([self conformsToProtocol:@protocol(FWStatisticalDelegate)] &&
        [self respondsToSelector:@selector(statisticalExposureWithCallback:)]) {
        __weak __typeof__(self) self_weak_ = self;
        [(id<FWStatisticalDelegate>)self statisticalExposureWithCallback:^(__kindof UIView * _Nullable cell, NSIndexPath * _Nullable indexPath) {
            __typeof__(self) self = self_weak_;
            if ([self fwStatisticalExposureState] == FWStatisticalExposureStateFully) {
                [self fwStatisticalExposureHandler:cell indexPath:indexPath];
            }
        }];
        return YES;
    }
    return NO;
}

- (FWStatisticalExposureState)fwStatisticalExposureState
{
    if (self == nil || self.hidden || self.alpha <= 0.01 || !self.window ||
        self.bounds.size.width == 0 || self.bounds.size.height == 0) {
        return FWStatisticalExposureStateNone;
    }
    
    UIViewController *viewController = self.fwViewController;
    if (viewController && (!viewController.view.window || viewController.presentedViewController)) {
        return FWStatisticalExposureStateNone;
    }
    
    UIView *targetView = viewController.view ?: self.window;
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
    viewRect = CGRectMake(floor(viewRect.origin.x), floor(viewRect.origin.y), floor(viewRect.size.width), floor(viewRect.size.height));
    CGRect targetRect = targetView.bounds;
    FWStatisticalExposureState state = FWStatisticalExposureStateNone;
    if (!CGRectIsEmpty(viewRect)) {
        if (CGRectContainsRect(targetRect, viewRect)) {
            state = FWStatisticalExposureStateFully;
        } else if (CGRectIntersectsRect(targetRect, viewRect)) {
            state = FWStatisticalExposureStatePartly;
        }
    }
    if (state == FWStatisticalExposureStateNone) {
        return state;
    }
    
    UIView *shieldView = nil;
    if (self.fwStatisticalExposure.shieldView) {
        shieldView = self.fwStatisticalExposure.shieldView;
    } else if (self.fwStatisticalExposure.shieldViewBlock) {
        shieldView = self.fwStatisticalExposure.shieldViewBlock();
    }
    if (!shieldView || shieldView.hidden || shieldView.alpha <= 0.01 ||
        shieldView.bounds.size.width == 0 || shieldView.bounds.size.height == 0) {
        return state;
    }
    CGRect shieldRect = [shieldView convertRect:shieldView.bounds toView:targetView];
    if (!CGRectIsEmpty(shieldRect)) {
        if (CGRectContainsRect(shieldRect, viewRect)) {
            return FWStatisticalExposureStateNone;
        } else if (CGRectIntersectsRect(shieldRect, viewRect)) {
            return FWStatisticalExposureStatePartly;
        }
    }
    return state;
}

- (void)setFwStatisticalExposureState
{
    FWStatisticalExposureState oldState = [objc_getAssociatedObject(self, @selector(fwStatisticalExposureState)) integerValue];
    NSString *oldIdentifier = objc_getAssociatedObject(self, @selector(fwStatisticalExposureIdentifier)) ?: @"";
    FWStatisticalExposureState state = [self fwStatisticalExposureState];
    NSString *identifier = [self fwStatisticalExposureIdentifier];
    
    objc_setAssociatedObject(self, @selector(fwStatisticalExposureIdentifier), identifier, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    BOOL stateChanged = ![identifier isEqualToString:oldIdentifier];
    if (stateChanged || state == FWStatisticalExposureStateNone) {
        [self setFwStatisticalExposureIsFully:NO];
    }
    if (state == oldState && !stateChanged) return;
    
    objc_setAssociatedObject(self, @selector(fwStatisticalExposureState), @(state), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (state == FWStatisticalExposureStateFully && ![self fwStatisticalExposureIsFully]) {
        [self setFwStatisticalExposureIsFully:YES];
        if ([self fwStatisticalExposureCustom]) {
        } else if ([self isKindOfClass:[UITableViewCell class]]) {
            [((UITableViewCell *)self).fwTableView fwStatisticalExposureHandler:self indexPath:((UITableViewCell *)self).fwIndexPath];
        } else if ([self isKindOfClass:[UICollectionViewCell class]]) {
            [((UICollectionViewCell *)self).fwCollectionView fwStatisticalExposureHandler:self indexPath:((UICollectionViewCell *)self).fwIndexPath];
        } else {
            [self fwStatisticalExposureHandler:nil indexPath:nil];
        }
    } else if (oldIdentifier.length < 1) {
        [self fwStatisticalExposureCustom];
    }
}

- (BOOL)fwStatisticalExposureIsRegistered
{
    if (![objc_getAssociatedObject(self, @selector(fwStatisticalExposureIsRegistered)) boolValue]) return NO;
    if ([self isKindOfClass:[UITableViewCell class]] || [self isKindOfClass:[UICollectionViewCell class]]) return NO;
    return YES;
}

#pragma mark - Private

- (void)fwStatisticalExposureRegister
{
    if ([objc_getAssociatedObject(self, @selector(fwStatisticalExposureIsRegistered)) boolValue]) return;
    objc_setAssociatedObject(self, @selector(fwStatisticalExposureIsRegistered), @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if ([self isKindOfClass:[UITableViewCell class]] || [self isKindOfClass:[UICollectionViewCell class]]) {
        [self fwStatisticalExposureCellRegister];
        return;
    }
    
    if (self.superview) {
        [self.superview fwStatisticalExposureRegister];
    }
    
    if (self.fwStatisticalExposure || self.fwStatisticalExposureBlock || [self fwStatisticalExposureIsProxy]) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(fwStatisticalExposureCalculate) object:nil];
        [self performSelector:@selector(fwStatisticalExposureCalculate) withObject:nil afterDelay:0 inModes:@[FWStatisticalManager.sharedInstance.runLoopMode]];
    }
}

- (void)fwStatisticalExposureCellRegister
{
    if (!self.superview) return;
    if ([objc_getAssociatedObject(self, _cmd) boolValue]) return;
    objc_setAssociatedObject(self, _cmd, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    UIView *proxyView = nil;
    if ([self conformsToProtocol:@protocol(FWStatisticalDelegate)] &&
        [self respondsToSelector:@selector(statisticalCellProxyView)]) {
        proxyView = [(id<FWStatisticalDelegate>)self statisticalCellProxyView];
    } else {
        proxyView = [self isKindOfClass:[UITableViewCell class]] ? [(UITableViewCell *)self fwTableView] : [(UICollectionViewCell *)self fwCollectionView];
    }
    [proxyView setFwStatisticalExposureIsProxy:YES];
    [proxyView fwStatisticalExposureRegister];
}

- (void)fwStatisticalExposureUpdate
{
    if (![self fwStatisticalExposureIsRegistered]) return;
    
    UIViewController *viewController = self.fwViewController;
    if (viewController && (!viewController.view.window || viewController.presentedViewController)) return;

    if (self.fwStatisticalExposure || self.fwStatisticalExposureBlock || [self fwStatisticalExposureIsProxy]) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(fwStatisticalExposureCalculate) object:nil];
        [self performSelector:@selector(fwStatisticalExposureCalculate) withObject:nil afterDelay:0 inModes:@[FWStatisticalManager.sharedInstance.runLoopMode]];
    }
    
    [self.subviews enumerateObjectsUsingBlock:^(UIView *obj, NSUInteger idx, BOOL *stop) {
        [obj fwStatisticalExposureUpdate];
    }];
}

- (void)fwStatisticalExposureCalculate
{
    if ([self isKindOfClass:[UITableView class]]) {
        [((UITableView *)self).visibleCells enumerateObjectsUsingBlock:^(__kindof UITableViewCell *obj, NSUInteger idx, BOOL *stop) {
            [obj setFwStatisticalExposureState];
        }];
    } else if ([self isKindOfClass:[UICollectionView class]]) {
        [((UICollectionView *)self).visibleCells enumerateObjectsUsingBlock:^(__kindof UICollectionViewCell *obj, NSUInteger idx, BOOL *stop) {
            [obj setFwStatisticalExposureState];
        }];
    } else {
        [self setFwStatisticalExposureState];
    }
}

- (NSInteger)fwStatisticalExposureCount:(NSIndexPath *)indexPath
{
    NSMutableDictionary *triggerDict = objc_getAssociatedObject(self, _cmd);
    if (!triggerDict) {
        triggerDict = [[NSMutableDictionary alloc] init];
        objc_setAssociatedObject(self, _cmd, triggerDict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    NSString *triggerKey = [NSString stringWithFormat:@"%@.%@", @(indexPath.section), @(indexPath.row)];
    NSInteger triggerCount = [[triggerDict objectForKey:triggerKey] integerValue] + 1;
    [triggerDict setObject:@(triggerCount) forKey:triggerKey];
    return triggerCount;
}

- (void)fwStatisticalExposureHandler:(UIView *)cell indexPath:(NSIndexPath *)indexPath
{
    FWStatisticalObject *object = cell.fwStatisticalExposure ?: self.fwStatisticalExposure;
    if (!object) object = [FWStatisticalObject new];
    object.view = self;
    object.indexPath = indexPath;
    NSInteger triggerCount = [self fwStatisticalExposureCount:indexPath];
    if (triggerCount > 1 && object.triggerOnce) return;
    object.triggerCount = triggerCount;
    
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
