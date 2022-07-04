/**
 @header     FWBlock.m
 @indexgroup FWFramework
      FWBlock
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/10/16
 */

#import "FWBlock.h"
#import "FWBarAppearance.h"
#import "FWNavigation.h"
#import "FWToolkit.h"
#import "FWFoundation.h"
#import <objc/runtime.h>

#pragma mark - FWBlock

void FWSynchronized(id object, void (^closure)(void)) {
    @synchronized(object) {
        closure();
    }
}

#pragma mark - NSTimer+FWBlock

@implementation NSTimer (FWBlock)

+ (NSTimer *)fw_commonTimerWithTimeInterval:(NSTimeInterval)seconds target:(id)target selector:(SEL)selector userInfo:(id)userInfo repeats:(BOOL)repeats
{
    NSTimer *timer = [NSTimer timerWithTimeInterval:seconds target:target selector:selector userInfo:userInfo repeats:repeats];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    return timer;
}

+ (NSTimer *)fw_commonTimerWithTimeInterval:(NSTimeInterval)seconds block:(void (^)(NSTimer *))block repeats:(BOOL)repeats
{
    NSTimer *timer = [self fw_timerWithTimeInterval:seconds block:block repeats:repeats];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    return timer;
}

+ (NSTimer *)fw_commonTimerWithCountDown:(NSInteger)seconds block:(void (^)(NSInteger))block
{
    NSTimeInterval startTime = NSDate.fw_currentTime;
    NSTimer *timer = [self fw_commonTimerWithTimeInterval:1 block:^(NSTimer *timer) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSInteger countDown = seconds - (NSInteger)round(NSDate.fw_currentTime - startTime);
            if (countDown <= 0) {
                block(0);
                [timer invalidate];
            } else {
                block(countDown);
            }
        });
    } repeats:YES];
    
    // 立即触发定时器，默认等待1秒后才执行
    [timer fire];
    return timer;
}

+ (NSTimer *)fw_scheduledTimerWithTimeInterval:(NSTimeInterval)seconds block:(void (^)(NSTimer *))block repeats:(BOOL)repeats
{
    return [NSTimer scheduledTimerWithTimeInterval:seconds target:[self class] selector:@selector(fw_timerAction:) userInfo:[block copy] repeats:repeats];
}

+ (NSTimer *)fw_timerWithTimeInterval:(NSTimeInterval)seconds block:(void (^)(NSTimer *))block repeats:(BOOL)repeats
{
    return [NSTimer timerWithTimeInterval:seconds target:[self class] selector:@selector(fw_timerAction:) userInfo:[block copy] repeats:repeats];
}

+ (void)fw_timerAction:(NSTimer *)timer
{
    if ([timer userInfo]) {
        void (^block)(NSTimer *timer) = (void (^)(NSTimer *timer))[timer userInfo];
        block(timer);
    }
}

- (void)fw_pauseTimer
{
    if (![self isValid]) return;
    [self setFireDate:[NSDate distantFuture]];
}

- (void)fw_resumeTimer
{
    if (![self isValid]) return;
    [self setFireDate:[NSDate date]];
}

- (void)fw_resumeTimerAfterDelay:(NSTimeInterval)delay
{
    if (![self isValid]) return;
    [self setFireDate:[NSDate dateWithTimeIntervalSinceNow:delay]];
}

@end

#pragma mark - FWInnerBlockTarget

@interface FWInnerBlockTarget : NSObject

@property (nonatomic, copy) NSString *identifier;

@property (nonatomic, copy) void (^block)(id sender);

@property (nonatomic, assign) UIControlEvents events;

- (void)invoke:(id)sender;

@end

@implementation FWInnerBlockTarget

- (instancetype)init
{
    self = [super init];
    if (self) {
        _identifier = NSUUID.UUID.UUIDString;
    }
    return self;
}

- (void)invoke:(id)sender
{
    if (self.block) {
        self.block(sender);
    }
}

@end

#pragma mark - UIGestureRecognizer+FWBlock

@implementation UIGestureRecognizer (FWBlock)

- (NSString *)fw_addBlock:(void (^)(id sender))block
{
    FWInnerBlockTarget *target = [[FWInnerBlockTarget alloc] init];
    target.block = block;
    [self addTarget:target action:@selector(invoke:)];
    NSMutableArray *targets = [self fw_innerBlockTargets];
    [targets addObject:target];
    return target.identifier;
}

- (void)fw_removeBlock:(NSString *)identifier
{
    if (!identifier) return;
    NSMutableArray *targets = [self fw_innerBlockTargets];
    [targets enumerateObjectsUsingBlock:^(FWInnerBlockTarget *target, NSUInteger idx, BOOL *stop) {
        if ([identifier isEqualToString:target.identifier]) {
            [self removeTarget:target action:@selector(invoke:)];
            [targets removeObject:target];
        }
    }];
}

- (void)fw_removeAllBlocks
{
    NSMutableArray *targets = [self fw_innerBlockTargets];
    [targets enumerateObjectsUsingBlock:^(id target, NSUInteger idx, BOOL *stop) {
        [self removeTarget:target action:@selector(invoke:)];
    }];
    [targets removeAllObjects];
}

- (NSMutableArray *)fw_innerBlockTargets
{
    NSMutableArray *targets = objc_getAssociatedObject(self, _cmd);
    if (!targets) {
        targets = [NSMutableArray array];
        objc_setAssociatedObject(self, _cmd, targets, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return targets;
}

+ (instancetype)fw_gestureRecognizerWithBlock:(void (^)(id))block
{
    UIGestureRecognizer *gestureRecognizer = [[self alloc] init];
    [gestureRecognizer fw_addBlock:block];
    return gestureRecognizer;
}

@end

#pragma mark - UIView+FWBlock

@implementation UIView (FWBlock)

- (void)fw_addTapGestureWithTarget:(id)target action:(SEL)action
{
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:target action:action];
    [self addGestureRecognizer:gesture];
}

- (NSString *)fw_addTapGestureWithBlock:(void (^)(id sender))block
{
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] init];
    NSString *identifier = [gesture fw_addBlock:block];
    objc_setAssociatedObject(gesture, @selector(fw_addTapGestureWithBlock:), identifier, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self addGestureRecognizer:gesture];
    return identifier;
}

- (void)fw_removeTapGesture:(NSString *)identifier
{
    if (!identifier) return;
    for (UIGestureRecognizer *gesture in self.gestureRecognizers) {
        if ([gesture isKindOfClass:[UITapGestureRecognizer class]]) {
            NSString *gestureIdentifier = objc_getAssociatedObject(gesture, @selector(fw_addTapGestureWithBlock:));
            if (gestureIdentifier && [identifier isEqualToString:gestureIdentifier]) {
                [self removeGestureRecognizer:gesture];
            }
        }
    }
}

- (void)fw_removeAllTapGestures
{
    for (UIGestureRecognizer *gesture in self.gestureRecognizers) {
        if ([gesture isKindOfClass:[UITapGestureRecognizer class]]) {
            [self removeGestureRecognizer:gesture];
        }
    }
}

@end

#pragma mark - UIControl+FWBlock

@implementation UIControl (FWBlock)

- (NSString *)fw_addBlock:(void (^)(id sender))block forControlEvents:(UIControlEvents)controlEvents
{
    FWInnerBlockTarget *target = [[FWInnerBlockTarget alloc] init];
    target.block = block;
    target.events = controlEvents;
    [self addTarget:target action:@selector(invoke:) forControlEvents:controlEvents];
    NSMutableArray *targets = [self fw_innerBlockTargets];
    [targets addObject:target];
    return target.identifier;
}

- (void)fw_removeBlock:(NSString *)identifier forControlEvents:(UIControlEvents)controlEvents
{
    if (!identifier) return;
    [self fw_removeAllBlocksForControlEvents:controlEvents identifier:identifier];
}

- (void)fw_removeAllBlocksForControlEvents:(UIControlEvents)controlEvents
{
    [self fw_removeAllBlocksForControlEvents:controlEvents identifier:nil];
}

- (void)fw_removeAllBlocksForControlEvents:(UIControlEvents)controlEvents identifier:(NSString *)identifier
{
    NSMutableArray *targets = [self fw_innerBlockTargets];
    NSMutableArray *removes = [NSMutableArray array];
    for (FWInnerBlockTarget *target in targets) {
        if (target.events & controlEvents) {
            BOOL shouldRemove = !identifier || [identifier isEqualToString:target.identifier];
            if (!shouldRemove) continue;
            
            UIControlEvents newEvent = target.events & (~controlEvents);
            if (newEvent) {
                [self removeTarget:target action:@selector(invoke:) forControlEvents:target.events];
                target.events = newEvent;
                [self addTarget:target action:@selector(invoke:) forControlEvents:target.events];
            } else {
                [self removeTarget:target action:@selector(invoke:) forControlEvents:target.events];
                [removes addObject:target];
            }
        }
    }
    [targets removeObjectsInArray:removes];
}

- (NSMutableArray *)fw_innerBlockTargets
{
    NSMutableArray *targets = objc_getAssociatedObject(self, _cmd);
    if (!targets) {
        targets = [NSMutableArray array];
        objc_setAssociatedObject(self, _cmd, targets, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return targets;
}

- (void)fw_addTouchTarget:(id)target action:(SEL)action
{
    [self addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
}

- (NSString *)fw_addTouchBlock:(void (^)(id sender))block
{
    return [self fw_addBlock:block forControlEvents:UIControlEventTouchUpInside];
}

- (void)fw_removeTouchBlock:(NSString *)identifier
{
    [self fw_removeBlock:identifier forControlEvents:UIControlEventTouchUpInside];
}

@end

#pragma mark - UIBarButtonItem+FWBlock

@implementation UIBarButtonItem (FWBlock)

- (NSDictionary<NSAttributedStringKey,id> *)fw_titleAttributes
{
    return objc_getAssociatedObject(self, @selector(fw_titleAttributes));
}

- (void)setFw_titleAttributes:(NSDictionary<NSAttributedStringKey,id> *)titleAttributes
{
    objc_setAssociatedObject(self, @selector(fw_titleAttributes), titleAttributes, OBJC_ASSOCIATION_COPY_NONATOMIC);
    if (!titleAttributes) return;
    
    NSArray<NSNumber *> *states = @[@(UIControlStateNormal), @(UIControlStateHighlighted), @(UIControlStateDisabled), @(UIControlStateSelected), @(UIControlStateApplication), @(UIControlStateReserved)];
    for (NSNumber *state in states) {
        NSMutableDictionary *attributes = [self titleTextAttributesForState:[state unsignedIntegerValue]].mutableCopy ?: [NSMutableDictionary new];
        [attributes addEntriesFromDictionary:titleAttributes];
        [self setTitleTextAttributes:attributes forState:[state unsignedIntegerValue]];
    }
}

- (void)fw_setBlock:(void (^)(id))block
{
    FWInnerBlockTarget *target = nil;
    SEL action = NULL;
    if (block) {
        target = [[FWInnerBlockTarget alloc] init];
        target.block = block;
        action = @selector(invoke:);
    }
    
    self.target = target;
    self.action = action;
    // 设置target为强引用，因为self.target为弱引用
    objc_setAssociatedObject(self, @selector(fw_setBlock:), target, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)fw_addItemEvent:(UIView *)customView
{
    // 进行self转发，模拟实际action回调参数
    if ([customView isKindOfClass:[UIControl class]]) {
        [((UIControl *)customView) fw_addTouchTarget:self action:@selector(fw_innerInvokeTargetAction:)];
    } else {
        [customView fw_addTapGestureWithTarget:self action:@selector(fw_innerInvokeTargetAction:)];
    }
}

- (void)fw_innerInvokeTargetAction:(id)sender
{
    if (self.target && self.action && [self.target respondsToSelector:self.action]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        // 第一个参数UIBarButtonItem，第二个参数为UIControl或者手势对象
        [self.target performSelector:self.action withObject:self withObject:sender];
#pragma clang diagnostic pop
    }
}

+ (instancetype)fw_itemWithObject:(id)object target:(id)target action:(SEL)action
{
    UIBarButtonItem *barItem = nil;
    // NSString
    if ([object isKindOfClass:[NSString class]]) {
        barItem = [[self alloc] initWithTitle:object style:UIBarButtonItemStylePlain target:target action:action];
    // NSAttributedString
    } else if ([object isKindOfClass:[NSAttributedString class]]) {
        NSAttributedString *attributedString = (NSAttributedString *)object;
        barItem = [[self alloc] initWithTitle:attributedString.string style:UIBarButtonItemStylePlain target:target action:action];
        barItem.fw_titleAttributes = [attributedString attributesAtIndex:0 effectiveRange:NULL];
    // UIImage
    } else if ([object isKindOfClass:[UIImage class]]) {
        barItem = [[self alloc] initWithImage:object style:UIBarButtonItemStylePlain target:target action:action];
    // NSNumber
    } else if ([object isKindOfClass:[NSNumber class]]) {
        barItem = [[self alloc] initWithBarButtonSystemItem:[object integerValue] target:target action:action];
    // UIView
    } else if ([object isKindOfClass:[UIView class]]) {
        barItem = [[self alloc] initWithCustomView:object];
        barItem.target = target;
        barItem.action = action;
        [barItem fw_addItemEvent:object];
    // Other
    } else {
        barItem = [[self alloc] init];
        barItem.target = target;
        barItem.action = action;
    }
    return barItem;
}

+ (UIBarButtonItem *)fw_itemWithObject:(id)object block:(void (^)(id))block
{
    UIBarButtonItem *barItem = [self fw_itemWithObject:object target:nil action:nil];
    [barItem fw_setBlock:block];
    return barItem;
}

@end

#pragma mark - UIViewController+FWBlock

@implementation UIViewController (FWBlock)

- (NSString *)fw_title
{
    return self.navigationItem.title;
}

- (void)setFw_title:(NSString *)title
{
    self.navigationItem.title = title;
}

- (id)fw_backBarItem
{
    return self.navigationItem.backBarButtonItem;
}

- (void)setFw_backBarItem:(id)object
{
    if ([object isKindOfClass:[UIImage class]]) {
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage new] style:UIBarButtonItemStylePlain target:nil action:nil];
        self.navigationController.navigationBar.fw_backImage = (UIImage *)object;
    } else {
        UIBarButtonItem *backItem = [object isKindOfClass:[UIBarButtonItem class]] ? (UIBarButtonItem *)object : [UIBarButtonItem fw_itemWithObject:object ?: [UIImage new] target:nil action:nil];
        self.navigationItem.backBarButtonItem = backItem;
        self.navigationController.navigationBar.fw_backImage = nil;
    }
}

- (id)fw_leftBarItem
{
    return self.navigationItem.leftBarButtonItem;
}

- (void)setFw_leftBarItem:(id)object
{
    if (!object || [object isKindOfClass:[UIBarButtonItem class]]) {
        self.navigationItem.leftBarButtonItem = object;
    } else {
        __weak UIViewController *weakController = self;
        self.navigationItem.leftBarButtonItem = [UIBarButtonItem fw_itemWithObject:object block:^(id  _Nonnull sender) {
            if (![weakController shouldPopController]) return;
            [weakController fw_closeViewControllerAnimated:YES];
        }];
    }
}

- (id)fw_rightBarItem
{
    return self.navigationItem.rightBarButtonItem;
}

- (void)setFw_rightBarItem:(id)object
{
    if (!object || [object isKindOfClass:[UIBarButtonItem class]]) {
        self.navigationItem.rightBarButtonItem = object;
    } else {
        __weak UIViewController *weakController = self;
        self.navigationItem.rightBarButtonItem = [UIBarButtonItem fw_itemWithObject:object block:^(id  _Nonnull sender) {
            if (![weakController shouldPopController]) return;
            [weakController fw_closeViewControllerAnimated:YES];
        }];
    }
}

- (void)fw_setLeftBarItem:(id)object target:(id)target action:(SEL)action
{
    self.navigationItem.leftBarButtonItem = [UIBarButtonItem fw_itemWithObject:object target:target action:action];
}

- (void)fw_setLeftBarItem:(id)object block:(void (^)(id sender))block
{
    self.navigationItem.leftBarButtonItem = [UIBarButtonItem fw_itemWithObject:object block:block];
}

- (void)fw_setRightBarItem:(id)object target:(id)target action:(SEL)action
{
    self.navigationItem.rightBarButtonItem = [UIBarButtonItem fw_itemWithObject:object target:target action:action];
}

- (void)fw_setRightBarItem:(id)object block:(void (^)(id sender))block
{
    self.navigationItem.rightBarButtonItem = [UIBarButtonItem fw_itemWithObject:object block:block];
}

- (void)fw_addLeftBarItem:(id)object target:(id)target action:(SEL)action
{
    UIBarButtonItem *barItem = [UIBarButtonItem fw_itemWithObject:object target:target action:action];
    NSMutableArray *items = self.navigationItem.leftBarButtonItems ? [self.navigationItem.leftBarButtonItems mutableCopy] : [NSMutableArray new];
    [items addObject:barItem];
    self.navigationItem.leftBarButtonItems = [items copy];
}

- (void)fw_addLeftBarItem:(id)object block:(void (^)(id sender))block
{
    UIBarButtonItem *barItem = [UIBarButtonItem fw_itemWithObject:object block:block];
    NSMutableArray *items = self.navigationItem.leftBarButtonItems ? [self.navigationItem.leftBarButtonItems mutableCopy] : [NSMutableArray new];
    [items addObject:barItem];
    self.navigationItem.leftBarButtonItems = [items copy];
}

- (void)fw_addRightBarItem:(id)object target:(id)target action:(SEL)action
{
    UIBarButtonItem *barItem = [UIBarButtonItem fw_itemWithObject:object target:target action:action];
    NSMutableArray *items = self.navigationItem.rightBarButtonItems ? [self.navigationItem.rightBarButtonItems mutableCopy] : [NSMutableArray new];
    [items addObject:barItem];
    self.navigationItem.rightBarButtonItems = [items copy];
}

- (void)fw_addRightBarItem:(id)object block:(void (^)(id sender))block
{
    UIBarButtonItem *barItem = [UIBarButtonItem fw_itemWithObject:object block:block];
    NSMutableArray *items = self.navigationItem.rightBarButtonItems ? [self.navigationItem.rightBarButtonItems mutableCopy] : [NSMutableArray new];
    [items addObject:barItem];
    self.navigationItem.rightBarButtonItems = [items copy];
}

@end
