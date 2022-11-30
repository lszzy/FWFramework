//
//  FWStatisticalManager.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "FWStatisticalManager.h"
#import "FWSwizzle.h"
#import "FWUIKit.h"
#import <objc/runtime.h>

#if FWMacroSPM

@interface NSObject ()

+ (BOOL)fw_swizzleMethod:(nullable id)target selector:(SEL)originalSelector identifier:(nullable NSString *)identifier block:(id (^)(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)))block;
- (BOOL)fw_isSwizzleInstanceMethod:(SEL)originalSelector identifier:(NSString *)identifier;

@end

@interface UIControl ()

- (NSString *)fw_addBlock:(void (^)(id sender))block for:(UIControlEvents)controlEvents;

@end

@interface UIGestureRecognizer ()

- (NSString *)fw_addBlock:(void (^)(id sender))block;

@end

#else

#import <FWFramework/FWFramework-Swift.h>

#endif

#pragma mark - FWStatistical

NSNotificationName const FWStatisticalEventTriggeredNotification = @"FWStatisticalEventTriggeredNotification";

@interface UIView (FWStatisticalInternal)

+ (void)fw_enableStatistical;

@end

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

- (void)setStatisticalEnabled:(BOOL)enabled
{
    _statisticalEnabled = enabled;
    if (enabled) [UIView fw_enableStatistical];
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

- (id)copyWithZone:(NSZone *)zone
{
    FWStatisticalObject *object = [[[self class] allocWithZone:zone] init];
    object.name = [self.name copy];
    object.object = self.object;
    object.userInfo = [self.userInfo copy];
    object.triggerOnce = self.triggerOnce;
    object.triggerIgnored = self.triggerIgnored;
    object.shieldView = self.shieldView;
    object.shieldViewBlock = self.shieldViewBlock;
    return object;
}

@end

#pragma mark - UIView+FWStatistical

@implementation UIView (FWStatistical)

- (FWStatisticalObject *)fw_statisticalClick
{
    return objc_getAssociatedObject(self, @selector(fw_statisticalClick));
}

- (void)setFw_statisticalClick:(FWStatisticalObject *)statisticalClick
{
    objc_setAssociatedObject(self, @selector(fw_statisticalClick), statisticalClick, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self fw_statisticalClickRegister];
}

- (FWStatisticalBlock)fw_statisticalClickBlock
{
    return objc_getAssociatedObject(self, @selector(fw_statisticalClickBlock));
}

- (void)setFw_statisticalClickBlock:(FWStatisticalBlock)statisticalClickBlock
{
    objc_setAssociatedObject(self, @selector(fw_statisticalClickBlock), statisticalClickBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
    [self fw_statisticalClickRegister];
}

- (BOOL)fw_statisticalClickIsRegistered
{
    return [objc_getAssociatedObject(self, @selector(fw_statisticalClickIsRegistered)) boolValue];
}

#pragma mark - Private

- (void)fw_statisticalClickRegister
{
    if ([self fw_statisticalClickIsRegistered]) return;
    objc_setAssociatedObject(self, @selector(fw_statisticalClickIsRegistered), @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if ([self isKindOfClass:[UITableViewCell class]] || [self isKindOfClass:[UICollectionViewCell class]]) {
        [self fw_statisticalClickCellRegister];
        return;
    }
    
    if ([self conformsToProtocol:@protocol(FWStatisticalDelegate)] &&
        [self respondsToSelector:@selector(statisticalClickWithCallback:)]) {
        __weak UIView *weakBase = self;
        [(id<FWStatisticalDelegate>)self statisticalClickWithCallback:^(__kindof UIView * _Nullable cell, NSIndexPath * _Nullable indexPath) {
            [weakBase fw_statisticalTriggerClick:cell indexPath:indexPath];
        }];
        return;
    }
    
    if ([self isKindOfClass:[UITableView class]]) {
        FWSwizzleMethod(((UITableView *)self).delegate, @selector(tableView:didSelectRowAtIndexPath:), @"FWStatisticalManager", FWSwizzleType(NSObject<UITableViewDelegate> *), FWSwizzleReturn(void), FWSwizzleArgs(UITableView *tableView, NSIndexPath *indexPath), FWSwizzleCode({
            FWSwizzleOriginal(tableView, indexPath);
            
            if (![selfObject fw_isSwizzleInstanceMethod:@selector(tableView:didSelectRowAtIndexPath:) identifier:@"FWStatisticalManager"]) return;
            if (![tableView fw_statisticalClickIsRegistered]) return;
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            [tableView fw_statisticalTriggerClick:cell indexPath:indexPath];
        }));
        return;
    }
    
    if ([self isKindOfClass:[UICollectionView class]]) {
        FWSwizzleMethod(((UICollectionView *)self).delegate, @selector(collectionView:didSelectItemAtIndexPath:), @"FWStatisticalManager", FWSwizzleType(NSObject<UICollectionViewDelegate> *), FWSwizzleReturn(void), FWSwizzleArgs(UICollectionView *collectionView, NSIndexPath *indexPath), FWSwizzleCode({
            FWSwizzleOriginal(collectionView, indexPath);
            
            if (![selfObject fw_isSwizzleInstanceMethod:@selector(collectionView:didSelectItemAtIndexPath:) identifier:@"FWStatisticalManager"]) return;
            if (![collectionView fw_statisticalClickIsRegistered]) return;
            UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
            [collectionView fw_statisticalTriggerClick:cell indexPath:indexPath];
        }));
        return;
    }
    
    if ([self isKindOfClass:[UIControl class]]) {
        UIControlEvents controlEvents = UIControlEventTouchUpInside;
        if ([self isKindOfClass:[UIDatePicker class]] ||
            [self isKindOfClass:[UIPageControl class]] ||
            [self isKindOfClass:[UISegmentedControl class]] ||
            [self isKindOfClass:[UISlider class]] ||
            [self isKindOfClass:[UIStepper class]] ||
            [self isKindOfClass:[UISwitch class]] ||
            [self isKindOfClass:[UITextField class]]) {
            controlEvents = UIControlEventValueChanged;
        }
        [((UIControl *)self) fw_addBlock:^(UIControl *sender) {
            [sender fw_statisticalTriggerClick:nil indexPath:nil];
        } for:controlEvents];
        return;
    }
    
    for (UIGestureRecognizer *gesture in self.gestureRecognizers) {
        if ([gesture isKindOfClass:[UITapGestureRecognizer class]]) {
            [gesture fw_addBlock:^(UIGestureRecognizer *sender) {
                [sender.view fw_statisticalTriggerClick:nil indexPath:nil];
            }];
        }
    }
}

- (void)fw_statisticalClickCellRegister
{
    if (!self.superview) return;
    UIView *proxyView = nil;
    if ([self conformsToProtocol:@protocol(FWStatisticalDelegate)] &&
        [self respondsToSelector:@selector(statisticalCellProxyView)]) {
        proxyView = [(id<FWStatisticalDelegate>)self statisticalCellProxyView];
    } else {
        proxyView = [self isKindOfClass:[UITableViewCell class]] ? [((UITableViewCell *)self) fw_tableView] : [((UICollectionViewCell *)self) fw_collectionView];
    }
    [proxyView fw_statisticalClickRegister];
}

- (NSInteger)fw_statisticalClickCount:(NSIndexPath *)indexPath
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

- (void)fw_statisticalTriggerClick:(UIView *)cell indexPath:(NSIndexPath *)indexPath
{
    FWStatisticalObject *object = cell.fw_statisticalClick ?: self.fw_statisticalClick;
    if (!object) object = [FWStatisticalObject new];
    if (object.triggerIgnored) return;
    NSInteger triggerCount = [self fw_statisticalClickCount:indexPath];
    if (triggerCount > 1 && object.triggerOnce) return;
    
    object.view = self;
    object.indexPath = indexPath;
    object.triggerCount = triggerCount;
    object.isExposure = NO;
    object.isFinished = YES;
    
    if (cell.fw_statisticalClickBlock) {
        cell.fw_statisticalClickBlock(object);
    } else if (self.fw_statisticalClickBlock) {
        self.fw_statisticalClickBlock(object);
    }
    if (cell.fw_statisticalClick || self.fw_statisticalClick) {
        [[FWStatisticalManager sharedInstance] handleEvent:object];
    }
}

@end

#pragma mark - UIView+FWExposure

@interface FWInnerStatisticalTarget : NSObject

@property (nonatomic, weak, readonly) UIView *view;

- (instancetype)initWithView:(UIView *)view;

- (void)statisticalExposureCalculate;

@end

typedef NS_ENUM(NSInteger, FWStatisticalExposureState) {
    FWStatisticalExposureStateNone,
    FWStatisticalExposureStatePartly,
    FWStatisticalExposureStateFully,
};

@implementation UIView (FWExposure)

#pragma mark - Hook

+ (void)fw_enableStatistical
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWSwizzleClass(UIView, @selector(setFrame:), FWSwizzleReturn(void), FWSwizzleArgs(CGRect frame), FWSwizzleCode({
            FWSwizzleOriginal(frame);
            [selfObject fw_statisticalExposureUpdate];
        }));
        FWSwizzleClass(UIView, @selector(setHidden:), FWSwizzleReturn(void), FWSwizzleArgs(BOOL hidden), FWSwizzleCode({
            FWSwizzleOriginal(hidden);
            [selfObject fw_statisticalExposureUpdate];
        }));
        FWSwizzleClass(UIView, @selector(setAlpha:), FWSwizzleReturn(void), FWSwizzleArgs(CGFloat alpha), FWSwizzleCode({
            FWSwizzleOriginal(alpha);
            [selfObject fw_statisticalExposureUpdate];
        }));
        FWSwizzleClass(UIView, @selector(setBounds:), FWSwizzleReturn(void), FWSwizzleArgs(CGRect bounds), FWSwizzleCode({
            FWSwizzleOriginal(bounds);
            [selfObject fw_statisticalExposureUpdate];
        }));
        FWSwizzleClass(UIView, @selector(didMoveToWindow), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            FWSwizzleOriginal();
            [selfObject fw_statisticalExposureUpdate];
        }));
        
        FWSwizzleClass(UITableView, @selector(reloadData), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            FWSwizzleOriginal();
            [selfObject fw_statisticalExposureUpdate];
        }));
        FWSwizzleClass(UICollectionView, @selector(reloadData), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            FWSwizzleOriginal();
            [selfObject fw_statisticalExposureUpdate];
        }));
        FWSwizzleClass(UITableViewCell, @selector(didMoveToSuperview), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            FWSwizzleOriginal();
            
            if (selfObject.fw_statisticalClick || selfObject.fw_statisticalClickBlock) {
                [selfObject fw_statisticalClickCellRegister];
            }
            if (selfObject.fw_statisticalExposure || selfObject.fw_statisticalExposureBlock) {
                [selfObject fw_statisticalExposureCellRegister];
            }
        }));
        FWSwizzleClass(UICollectionViewCell, @selector(didMoveToSuperview), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            FWSwizzleOriginal();
            
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

- (FWStatisticalObject *)fw_statisticalExposure
{
    return objc_getAssociatedObject(self, @selector(fw_statisticalExposure));
}

- (void)setFw_statisticalExposure:(FWStatisticalObject *)statisticalExposure
{
    objc_setAssociatedObject(self, @selector(fw_statisticalExposure), statisticalExposure, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self fw_statisticalExposureRegister];
}

- (FWStatisticalBlock)fw_statisticalExposureBlock
{
    return objc_getAssociatedObject(self, @selector(fw_statisticalExposureBlock));
}

- (void)setFw_statisticalExposureBlock:(FWStatisticalBlock)statisticalExposureBlock
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
    if ([self conformsToProtocol:@protocol(FWStatisticalDelegate)] &&
        [self respondsToSelector:@selector(statisticalExposureWithCallback:)]) {
        __weak UIView *weakBase = self;
        [(id<FWStatisticalDelegate>)self statisticalExposureWithCallback:^(__kindof UIView * _Nullable cell, NSIndexPath * _Nullable indexPath, NSTimeInterval duration) {
            if ([weakBase fw_statisticalExposureFullyState:[weakBase fw_statisticalExposureState]]) {
                [weakBase fw_statisticalTriggerExposure:cell indexPath:indexPath duration:duration];
            }
        }];
        return YES;
    }
    return NO;
}

- (FWStatisticalExposureState)fw_statisticalExposureState
{
    if (!self.fw_isViewVisible) {
        return FWStatisticalExposureStateNone;
    }
    
    UIViewController *viewController = self.fw_viewController;
    if (viewController && (!viewController.view.window || viewController.presentedViewController)) {
        return FWStatisticalExposureStateNone;
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
            return FWStatisticalExposureStateNone;
        } else if (CGRectIntersectsRect(shieldRect, viewRect)) {
            return FWStatisticalExposureStatePartly;
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
    
    FWStatisticalExposureState oldState = [objc_getAssociatedObject(self, @selector(fw_statisticalExposureState)) integerValue];
    FWStatisticalExposureState state = [self fw_statisticalExposureState];
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
    } else if (state == FWStatisticalExposureStateNone || identifierChanged) {
        [self setFw_statisticalExposureIsFully:NO];
    }
}

- (BOOL)fw_statisticalExposureFullyState:(FWStatisticalExposureState)state
{
    BOOL isFullyState = (state == FWStatisticalExposureStateFully);
    if (!isFullyState && FWStatisticalManager.sharedInstance.exposurePartly) {
        isFullyState = (state == FWStatisticalExposureStatePartly);
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
        [self.fw_innerStatisticalTarget performSelector:@selector(statisticalExposureCalculate) withObject:nil afterDelay:0 inModes:@[FWStatisticalManager.sharedInstance.runLoopMode]];
    }
}

- (void)fw_statisticalExposureCellRegister
{
    if (!self.superview) return;
    UIView *proxyView = nil;
    if ([self conformsToProtocol:@protocol(FWStatisticalDelegate)] &&
        [self respondsToSelector:@selector(statisticalCellProxyView)]) {
        proxyView = [(id<FWStatisticalDelegate>)self statisticalCellProxyView];
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
        [self.fw_innerStatisticalTarget performSelector:@selector(statisticalExposureCalculate) withObject:nil afterDelay:0 inModes:@[FWStatisticalManager.sharedInstance.runLoopMode]];
    }
    
    [self.subviews enumerateObjectsUsingBlock:^(UIView *obj, NSUInteger idx, BOOL *stop) {
        [obj fw_statisticalExposureRecursive];
    }];
}

- (FWInnerStatisticalTarget *)fw_innerStatisticalTarget
{
    FWInnerStatisticalTarget *target = objc_getAssociatedObject(self, _cmd);
    if (!target) {
        target = [[FWInnerStatisticalTarget alloc] initWithView:self];
        objc_setAssociatedObject(self, _cmd, target, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return target;
}

- (NSInteger)fw_statisticalExposureCount:(NSIndexPath *)indexPath
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

- (NSTimeInterval)fw_statisticalExposureDuration:(NSTimeInterval)duration indexPath:(NSIndexPath *)indexPath
{
    NSMutableDictionary *triggerDict = objc_getAssociatedObject(self, _cmd);
    if (!triggerDict) {
        triggerDict = [[NSMutableDictionary alloc] init];
        objc_setAssociatedObject(self, _cmd, triggerDict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    NSString *triggerKey = [NSString stringWithFormat:@"%@.%@", @(indexPath.section), @(indexPath.row)];
    NSTimeInterval triggerDuration = [[triggerDict objectForKey:triggerKey] doubleValue] + duration;
    [triggerDict setObject:@(triggerDuration) forKey:triggerKey];
    return triggerDuration;
}

- (void)fw_statisticalTriggerExposure:(UIView *)cell indexPath:(NSIndexPath *)indexPath duration:(NSTimeInterval)duration
{
    FWStatisticalObject *object = cell.fw_statisticalExposure ?: self.fw_statisticalExposure;
    if (!object) object = [FWStatisticalObject new];
    if (object.triggerIgnored) return;
    NSInteger triggerCount = [self fw_statisticalExposureCount:indexPath];
    if (triggerCount > 1 && object.triggerOnce) return;
    
    object.view = self;
    object.indexPath = indexPath;
    object.triggerCount = triggerCount;
    object.triggerDuration = duration;
    object.totalDuration = [self fw_statisticalExposureDuration:duration indexPath:indexPath];
    object.isExposure = YES;
    object.isFinished = duration > 0;
    
    if (cell.fw_statisticalExposureBlock) {
        cell.fw_statisticalExposureBlock(object);
    } else if (self.fw_statisticalExposureBlock) {
        self.fw_statisticalExposureBlock(object);
    }
    if (cell.fw_statisticalExposure || self.fw_statisticalExposure) {
        [[FWStatisticalManager sharedInstance] handleEvent:object];
    }
}

@end

@implementation FWInnerStatisticalTarget

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
