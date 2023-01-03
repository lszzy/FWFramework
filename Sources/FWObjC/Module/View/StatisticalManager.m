//
//  StatisticalManager.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "StatisticalManager.h"
#import "Swizzle.h"
#import <objc/runtime.h>

#if FWMacroSPM



#else

#import <FWFramework/FWFramework-Swift.h>

#endif

#pragma mark - __FWStatistical

NSNotificationName const __FWStatisticalEventTriggeredNotification = @"FWStatisticalEventTriggeredNotification";

@interface UIView (__FWStatisticalInternal)

+ (void)fw_enableStatistical;

@end

@interface __FWStatisticalManager ()

@property (nonatomic, strong) NSMutableDictionary *eventHandlers;

@end

@implementation __FWStatisticalManager

+ (instancetype)sharedInstance
{
    static __FWStatisticalManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[__FWStatisticalManager alloc] init];
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

- (void)setStatisticalEnabled:(BOOL)enabled
{
    _statisticalEnabled = enabled;
    if (enabled) [UIView fw_enableStatistical];
}

- (void)registerEvent:(NSString *)name withHandler:(__FWStatisticalBlock)handler
{
    [self.eventHandlers setObject:handler forKey:name];
}

- (void)__handleEvent:(__FWStatisticalObject *)object
{
    __FWStatisticalBlock eventHandler = [self.eventHandlers objectForKey:object.name];
    if (eventHandler) {
        eventHandler(object);
    }
    if (self.globalHandler) {
        self.globalHandler(object);
    }
    if (self.notificationEnabled) {
        [[NSNotificationCenter defaultCenter] postNotificationName:__FWStatisticalEventTriggeredNotification object:object userInfo:object.userInfo];
    }
}

@end

@interface __FWStatisticalObject ()

@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) id object;
@property (nonatomic, copy) NSDictionary *userInfo;
@property (nonatomic, weak) __kindof UIView *view;
@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, assign) NSInteger triggerCount;
@property (nonatomic, assign) NSTimeInterval triggerDuration;
@property (nonatomic, assign) NSTimeInterval totalDuration;
@property (nonatomic, assign) BOOL isExposure;
@property (nonatomic, assign) BOOL isFinished;

@end

@implementation __FWStatisticalObject

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

- (id)copyWithZone:(NSZone *)zone
{
    __FWStatisticalObject *object = [[[self class] allocWithZone:zone] init];
    object.name = [self.name copy];
    object.object = self.object;
    object.userInfo = [self.userInfo copy];
    object.triggerOnce = self.triggerOnce;
    object.triggerIgnored = self.triggerIgnored;
    object.shieldView = self.shieldView;
    object.shieldViewBlock = self.shieldViewBlock;
    return object;
}

- (void)__triggerClick:(UIView *)view indexPath:(NSIndexPath *)indexPath triggerCount:(NSInteger)triggerCount
{
    self.view = view;
    self.indexPath = indexPath;
    self.triggerCount = triggerCount;
    self.isExposure = NO;
    self.isFinished = YES;
}

- (void)__triggerExposure:(UIView *)view indexPath:(NSIndexPath *)indexPath triggerCount:(NSInteger)triggerCount duration:(NSTimeInterval)duration totalDuration:(NSTimeInterval)totalDuration
{
    self.view = view;
    self.indexPath = indexPath;
    self.triggerCount = triggerCount;
    self.triggerDuration = duration;
    self.totalDuration = totalDuration;
    self.isExposure = YES;
    self.isFinished = duration > 0;
}

@end

#pragma mark - UIView+__FWExposure

@interface __FWStatisticalTarget : NSObject

@property (nonatomic, weak, readonly) UIView *view;

- (instancetype)initWithView:(UIView *)view;

- (void)statisticalExposureCalculate;

@end

typedef NS_ENUM(NSInteger, __FWStatisticalExposureState) {
    __FWStatisticalExposureStateNone,
    __FWStatisticalExposureStatePartly,
    __FWStatisticalExposureStateFully,
};

@implementation UIView (__FWExposure)

#pragma mark - Hook

+ (void)fw_enableStatistical
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __FWSwizzleClass(UIView, @selector(setFrame:), __FWSwizzleReturn(void), __FWSwizzleArgs(CGRect frame), __FWSwizzleCode({
            __FWSwizzleOriginal(frame);
            [selfObject fw_statisticalExposureUpdate];
        }));
        __FWSwizzleClass(UIView, @selector(setHidden:), __FWSwizzleReturn(void), __FWSwizzleArgs(BOOL hidden), __FWSwizzleCode({
            __FWSwizzleOriginal(hidden);
            [selfObject fw_statisticalExposureUpdate];
        }));
        __FWSwizzleClass(UIView, @selector(setAlpha:), __FWSwizzleReturn(void), __FWSwizzleArgs(CGFloat alpha), __FWSwizzleCode({
            __FWSwizzleOriginal(alpha);
            [selfObject fw_statisticalExposureUpdate];
        }));
        __FWSwizzleClass(UIView, @selector(setBounds:), __FWSwizzleReturn(void), __FWSwizzleArgs(CGRect bounds), __FWSwizzleCode({
            __FWSwizzleOriginal(bounds);
            [selfObject fw_statisticalExposureUpdate];
        }));
        __FWSwizzleClass(UIView, @selector(didMoveToWindow), __FWSwizzleReturn(void), __FWSwizzleArgs(), __FWSwizzleCode({
            __FWSwizzleOriginal();
            [selfObject fw_statisticalExposureUpdate];
        }));
        
        __FWSwizzleClass(UITableView, @selector(reloadData), __FWSwizzleReturn(void), __FWSwizzleArgs(), __FWSwizzleCode({
            __FWSwizzleOriginal();
            [selfObject fw_statisticalExposureUpdate];
        }));
        __FWSwizzleClass(UICollectionView, @selector(reloadData), __FWSwizzleReturn(void), __FWSwizzleArgs(), __FWSwizzleCode({
            __FWSwizzleOriginal();
            [selfObject fw_statisticalExposureUpdate];
        }));
        __FWSwizzleClass(UITableViewCell, @selector(didMoveToSuperview), __FWSwizzleReturn(void), __FWSwizzleArgs(), __FWSwizzleCode({
            __FWSwizzleOriginal();
            
            if (selfObject.fw_statisticalClick || selfObject.fw_statisticalClickBlock) {
                [selfObject fw_statisticalClickCellRegister];
            }
            if (selfObject.fw_statisticalExposure || selfObject.fw_statisticalExposureBlock) {
                [selfObject fw_statisticalExposureCellRegister];
            }
        }));
        __FWSwizzleClass(UICollectionViewCell, @selector(didMoveToSuperview), __FWSwizzleReturn(void), __FWSwizzleArgs(), __FWSwizzleCode({
            __FWSwizzleOriginal();
            
            if (selfObject.fw_statisticalClick || selfObject.fw_statisticalClickBlock) {
                [selfObject fw_statisticalClickCellRegister];
            }
            if (selfObject.fw_statisticalExposure || selfObject.fw_statisticalExposureBlock) {
                [selfObject fw_statisticalExposureCellRegister];
            }
        }));
    });
}

#pragma mark - Exposure

- (__FWStatisticalObject *)fw_statisticalExposure
{
    return objc_getAssociatedObject(self, @selector(fw_statisticalExposure));
}

- (void)setFw_statisticalExposure:(__FWStatisticalObject *)statisticalExposure
{
    objc_setAssociatedObject(self, @selector(fw_statisticalExposure), statisticalExposure, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self fw_statisticalExposureRegister];
}

- (__FWStatisticalBlock)fw_statisticalExposureBlock
{
    return objc_getAssociatedObject(self, @selector(fw_statisticalExposureBlock));
}

- (void)setFw_statisticalExposureBlock:(__FWStatisticalBlock)statisticalExposureBlock
{
    objc_setAssociatedObject(self, @selector(fw_statisticalExposureBlock), statisticalExposureBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
    [self fw_statisticalExposureRegister];
}

#pragma mark - Accessor

- (BOOL)fw_statisticalExposureIsRegistered
{
    return [objc_getAssociatedObject(self, @selector(fw_statisticalExposureIsRegistered)) boolValue];
}

- (BOOL)fw_statisticalExposureIsProxy
{
    return [objc_getAssociatedObject(self, @selector(fw_statisticalExposureIsProxy)) boolValue];
}

- (void)setFw_statisticalExposureIsProxy:(BOOL)isProxy
{
    objc_setAssociatedObject(self, @selector(fw_statisticalExposureIsProxy), @(isProxy), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)fw_statisticalExposureIsFully
{
    return [objc_getAssociatedObject(self, @selector(fw_statisticalExposureIsFully)) boolValue];
}

- (void)setFw_statisticalExposureIsFully:(BOOL)isFully
{
    objc_setAssociatedObject(self, @selector(fw_statisticalExposureIsFully), @(isFully), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)fw_statisticalExposureIdentifier
{
    NSIndexPath *indexPath = nil;
    if ([self isKindOfClass:[UITableViewCell class]] || [self isKindOfClass:[UICollectionViewCell class]]) {
        indexPath = [((UITableViewCell *)self) fw_indexPath];
    }
    
    NSString *identifier = [NSString stringWithFormat:@"%@-%@-%@-%@", @(indexPath.section), @(indexPath.row), self.fw_statisticalExposure.name, self.fw_statisticalExposure.object];
    return identifier;
}

- (BOOL)fw_statisticalExposureCustom
{
    if ([self conformsToProtocol:@protocol(__FWStatisticalDelegate)] &&
        [self respondsToSelector:@selector(statisticalExposureWithCallback:)]) {
        __weak UIView *weakBase = self;
        [(id<__FWStatisticalDelegate>)self statisticalExposureWithCallback:^(__kindof UIView * _Nullable cell, NSIndexPath * _Nullable indexPath, NSTimeInterval duration) {
            if ([weakBase fw_statisticalExposureFullyState:[weakBase fw_statisticalExposureState]]) {
                [weakBase fw_statisticalTriggerExposure:cell indexPath:indexPath duration:duration];
            }
        }];
        return YES;
    }
    return NO;
}

- (__FWStatisticalExposureState)fw_statisticalExposureState
{
    if (!self.fw_isViewVisible) {
        return __FWStatisticalExposureStateNone;
    }
    
    UIViewController *viewController = self.fw_viewController;
    if (viewController && (!viewController.view.window || viewController.presentedViewController)) {
        return __FWStatisticalExposureStateNone;
    }
    
    UIView *targetView = viewController.view ?: self.window;
    UIView *superview = self.superview;
    BOOL superviewHidden = NO;
    while (superview && superview != targetView) {
        if (!superview.fw_isViewVisible) {
            superviewHidden = YES;
            break;
        }
        superview = superview.superview;
    }
    if (superviewHidden) {
        return __FWStatisticalExposureStateNone;
    }
    
    CGRect viewRect = [self convertRect:self.bounds toView:targetView];
    viewRect = CGRectMake(floor(viewRect.origin.x), floor(viewRect.origin.y), floor(viewRect.size.width), floor(viewRect.size.height));
    CGRect targetRect = targetView.bounds;
    __FWStatisticalExposureState state = __FWStatisticalExposureStateNone;
    if (!CGRectIsEmpty(viewRect)) {
        if (CGRectContainsRect(targetRect, viewRect)) {
            state = __FWStatisticalExposureStateFully;
        } else if (CGRectIntersectsRect(targetRect, viewRect)) {
            state = __FWStatisticalExposureStatePartly;
        }
    }
    if (state == __FWStatisticalExposureStateNone) {
        return state;
    }
    
    UIView *shieldView = nil;
    if (self.fw_statisticalExposure.shieldView) {
        shieldView = self.fw_statisticalExposure.shieldView;
    } else if (self.fw_statisticalExposure.shieldViewBlock) {
        shieldView = self.fw_statisticalExposure.shieldViewBlock();
    }
    if (!shieldView || !shieldView.fw_isViewVisible) {
        return state;
    }
    CGRect shieldRect = [shieldView convertRect:shieldView.bounds toView:targetView];
    if (!CGRectIsEmpty(shieldRect)) {
        if (CGRectContainsRect(shieldRect, viewRect)) {
            return __FWStatisticalExposureStateNone;
        } else if (CGRectIntersectsRect(shieldRect, viewRect)) {
            return __FWStatisticalExposureStatePartly;
        }
    }
    return state;
}

- (void)fw_setStatisticalExposureState
{
    NSString *oldIdentifier = objc_getAssociatedObject(self, @selector(fw_statisticalExposureIdentifier)) ?: @"";
    NSString *identifier = [self fw_statisticalExposureIdentifier];
    BOOL identifierChanged = oldIdentifier.length > 0 && ![identifier isEqualToString:oldIdentifier];
    if (oldIdentifier.length < 1 || identifierChanged) {
        objc_setAssociatedObject(self, @selector(fw_statisticalExposureIdentifier), identifier, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        if (oldIdentifier.length < 1) [self fw_statisticalExposureCustom];
    }
    
    __FWStatisticalExposureState oldState = [objc_getAssociatedObject(self, @selector(fw_statisticalExposureState)) integerValue];
    __FWStatisticalExposureState state = [self fw_statisticalExposureState];
    if (state == oldState && !identifierChanged) return;
    objc_setAssociatedObject(self, @selector(fw_statisticalExposureState), @(state), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if ([self fw_statisticalExposureFullyState:state] &&
        (![self fw_statisticalExposureIsFully] || identifierChanged)) {
        [self setFw_statisticalExposureIsFully:YES];
        if ([self fw_statisticalExposureCustom]) {
        } else if ([self isKindOfClass:[UITableViewCell class]]) {
            [((UITableViewCell *)self).fw_tableView fw_statisticalTriggerExposure:self indexPath:((UITableViewCell *)self).fw_indexPath duration:0];
        } else if ([self isKindOfClass:[UICollectionViewCell class]]) {
            [((UICollectionViewCell *)self).fw_collectionView fw_statisticalTriggerExposure:self indexPath:((UICollectionViewCell *)self).fw_indexPath duration:0];
        } else {
            [self fw_statisticalTriggerExposure:nil indexPath:nil duration:0];
        }
    } else if (state == __FWStatisticalExposureStateNone || identifierChanged) {
        [self setFw_statisticalExposureIsFully:NO];
    }
}

- (BOOL)fw_statisticalExposureFullyState:(__FWStatisticalExposureState)state
{
    BOOL isFullyState = (state == __FWStatisticalExposureStateFully);
    if (!isFullyState && __FWStatisticalManager.sharedInstance.exposurePartly) {
        isFullyState = (state == __FWStatisticalExposureStatePartly);
    }
    return isFullyState;
}

#pragma mark - Private

- (void)fw_statisticalExposureRegister
{
    if ([self fw_statisticalExposureIsRegistered]) return;
    objc_setAssociatedObject(self, @selector(fw_statisticalExposureIsRegistered), @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if ([self isKindOfClass:[UITableViewCell class]] || [self isKindOfClass:[UICollectionViewCell class]]) {
        [self fw_statisticalExposureCellRegister];
        return;
    }
    
    if (self.superview) {
        [self.superview fw_statisticalExposureRegister];
    }
    
    if (self.fw_statisticalExposure || self.fw_statisticalExposureBlock || [self fw_statisticalExposureIsProxy]) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self.fw_innerStatisticalTarget selector:@selector(statisticalExposureCalculate) object:nil];
        [self.fw_innerStatisticalTarget performSelector:@selector(statisticalExposureCalculate) withObject:nil afterDelay:0 inModes:@[__FWStatisticalManager.sharedInstance.runLoopMode]];
    }
}

- (void)fw_statisticalExposureCellRegister
{
    if (!self.superview) return;
    UIView *proxyView = nil;
    if ([self conformsToProtocol:@protocol(__FWStatisticalDelegate)] &&
        [self respondsToSelector:@selector(statisticalCellProxyView)]) {
        proxyView = [(id<__FWStatisticalDelegate>)self statisticalCellProxyView];
    } else {
        proxyView = [self isKindOfClass:[UITableViewCell class]] ? [((UITableViewCell *)self) fw_tableView] : [((UICollectionViewCell *)self) fw_collectionView];
    }
    [proxyView setFw_statisticalExposureIsProxy:YES];
    [proxyView fw_statisticalExposureRegister];
}

- (void)fw_statisticalExposureUpdate
{
    if (![self fw_statisticalExposureIsRegistered]) return;
    
    UIViewController *viewController = self.fw_viewController;
    if (viewController && (!viewController.view.window || viewController.presentedViewController)) return;
    
    [self fw_statisticalExposureRecursive];
}

- (void)fw_statisticalExposureRecursive
{
    if (![self fw_statisticalExposureIsRegistered]) return;

    if (self.fw_statisticalExposure || self.fw_statisticalExposureBlock || [self fw_statisticalExposureIsProxy]) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self.fw_innerStatisticalTarget selector:@selector(statisticalExposureCalculate) object:nil];
        [self.fw_innerStatisticalTarget performSelector:@selector(statisticalExposureCalculate) withObject:nil afterDelay:0 inModes:@[__FWStatisticalManager.sharedInstance.runLoopMode]];
    }
    
    [self.subviews enumerateObjectsUsingBlock:^(UIView *obj, NSUInteger idx, BOOL *stop) {
        [obj fw_statisticalExposureRecursive];
    }];
}

- (__FWStatisticalTarget *)fw_innerStatisticalTarget
{
    __FWStatisticalTarget *target = objc_getAssociatedObject(self, _cmd);
    if (!target) {
        target = [[__FWStatisticalTarget alloc] initWithView:self];
        objc_setAssociatedObject(self, _cmd, target, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return target;
}

@end

@implementation __FWStatisticalTarget

- (instancetype)initWithView:(UIView *)view
{
    self = [super init];
    if (self) {
        _view = view;
    }
    return self;
}

- (void)statisticalExposureCalculate
{
    if ([self.view isKindOfClass:[UITableView class]] || [self.view isKindOfClass:[UICollectionView class]]) {
        [self.view.subviews enumerateObjectsUsingBlock:^(UIView *obj, NSUInteger idx, BOOL *stop) {
            [obj fw_setStatisticalExposureState];
        }];
    } else {
        [self.view fw_setStatisticalExposureState];
    }
}

@end
