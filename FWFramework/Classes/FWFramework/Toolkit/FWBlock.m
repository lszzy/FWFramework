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
#import <objc/runtime.h>

#pragma mark - FWTimerClassWrapper+FWBlock

@implementation FWTimerClassWrapper (FWBlock)

- (NSTimer *)commonTimerWithTimeInterval:(NSTimeInterval)seconds target:(id)target selector:(SEL)selector userInfo:(id)userInfo repeats:(BOOL)repeats
{
    NSTimer *timer = [NSTimer timerWithTimeInterval:seconds target:target selector:selector userInfo:userInfo repeats:repeats];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    return timer;
}

- (NSTimer *)commonTimerWithTimeInterval:(NSTimeInterval)seconds block:(void (^)(NSTimer *))block repeats:(BOOL)repeats
{
    NSTimer *timer = [self timerWithTimeInterval:seconds block:block repeats:repeats];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    return timer;
}

- (NSTimer *)commonTimerWithCountDown:(NSInteger)seconds block:(void (^)(NSInteger))block
{
    __block NSInteger countdown = seconds;
    NSTimer *timer = [self commonTimerWithTimeInterval:1 block:^(NSTimer *timer) {
        if (countdown <= 0) {
            block(0);
            [timer invalidate];
        } else {
            countdown--;
            // 时间+1，防止倒计时显示0秒
            block(countdown + 1);
        }
    } repeats:YES];
    
    // 立即触发定时器，默认等待1秒后才执行
    [timer fire];
    return timer;
}

- (NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)seconds block:(void (^)(NSTimer *))block repeats:(BOOL)repeats
{
    return [NSTimer scheduledTimerWithTimeInterval:seconds target:[self class] selector:@selector(timerAction:) userInfo:[block copy] repeats:repeats];
}

- (NSTimer *)timerWithTimeInterval:(NSTimeInterval)seconds block:(void (^)(NSTimer *))block repeats:(BOOL)repeats
{
    return [NSTimer timerWithTimeInterval:seconds target:[self class] selector:@selector(timerAction:) userInfo:[block copy] repeats:repeats];
}

+ (void)timerAction:(NSTimer *)timer
{
    if ([timer userInfo]) {
        void (^block)(NSTimer *timer) = (void (^)(NSTimer *timer))[timer userInfo];
        block(timer);
    }
}

@end

#pragma mark - FWTimerWrapper+FWFoundation

@implementation FWTimerWrapper (FWFoundation)

- (void)pauseTimer
{
    if (![self.base isValid]) return;
    [self.base setFireDate:[NSDate distantFuture]];
}

- (void)resumeTimer
{
    if (![self.base isValid]) return;
    [self.base setFireDate:[NSDate date]];
}

- (void)resumeTimerAfterDelay:(NSTimeInterval)delay
{
    if (![self.base isValid]) return;
    [self.base setFireDate:[NSDate dateWithTimeIntervalSinceNow:delay]];
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

#pragma mark - FWGestureRecognizerWrapper+FWBlock

@implementation FWGestureRecognizerWrapper (FWBlock)

- (NSString *)addBlock:(void (^)(id sender))block
{
    FWInnerBlockTarget *target = [[FWInnerBlockTarget alloc] init];
    target.block = block;
    [self.base addTarget:target action:@selector(invoke:)];
    NSMutableArray *targets = [self innerBlockTargets];
    [targets addObject:target];
    return target.identifier;
}

- (void)removeBlock:(NSString *)identifier
{
    if (!identifier) return;
    NSMutableArray *targets = [self innerBlockTargets];
    [targets enumerateObjectsUsingBlock:^(FWInnerBlockTarget *target, NSUInteger idx, BOOL *stop) {
        if ([identifier isEqualToString:target.identifier]) {
            [self.base removeTarget:target action:@selector(invoke:)];
            [targets removeObject:target];
        }
    }];
}

- (void)removeAllBlocks
{
    NSMutableArray *targets = [self innerBlockTargets];
    [targets enumerateObjectsUsingBlock:^(id target, NSUInteger idx, BOOL *stop) {
        [self.base removeTarget:target action:@selector(invoke:)];
    }];
    [targets removeAllObjects];
}

- (NSMutableArray *)innerBlockTargets
{
    NSMutableArray *targets = objc_getAssociatedObject(self.base, _cmd);
    if (!targets) {
        targets = [NSMutableArray array];
        objc_setAssociatedObject(self.base, _cmd, targets, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return targets;
}

@end

#pragma mark - FWGestureRecognizerClassWrapper+FWBlock

@implementation FWGestureRecognizerClassWrapper (FWBlock)

- (__kindof UIGestureRecognizer *)gestureRecognizerWithBlock:(void (^)(id))block
{
    UIGestureRecognizer *gestureRecognizer = [[self.base alloc] init];
    [gestureRecognizer.fw addBlock:block];
    return gestureRecognizer;
}

@end

#pragma mark - FWViewWrapper+FWBlock

@implementation FWViewWrapper (FWBlock)

- (void)addTapGestureWithTarget:(id)target action:(SEL)action
{
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:target action:action];
    [self.base addGestureRecognizer:gesture];
}

- (NSString *)addTapGestureWithBlock:(void (^)(id sender))block
{
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] init];
    NSString *identifier = [gesture.fw addBlock:block];
    objc_setAssociatedObject(gesture, @selector(addTapGestureWithBlock:), identifier, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self.base addGestureRecognizer:gesture];
    return identifier;
}

- (void)removeTapGesture:(NSString *)identifier
{
    if (!identifier) return;
    for (UIGestureRecognizer *gesture in self.base.gestureRecognizers) {
        if ([gesture isKindOfClass:[UITapGestureRecognizer class]]) {
            NSString *gestureIdentifier = objc_getAssociatedObject(gesture, @selector(addTapGestureWithBlock:));
            if (gestureIdentifier && [identifier isEqualToString:gestureIdentifier]) {
                [self.base removeGestureRecognizer:gesture];
            }
        }
    }
}

- (void)removeAllTapGestures
{
    for (UIGestureRecognizer *gesture in self.base.gestureRecognizers) {
        if ([gesture isKindOfClass:[UITapGestureRecognizer class]]) {
            [self.base removeGestureRecognizer:gesture];
        }
    }
}

@end

#pragma mark - FWControlWrapper+FWBlock

@implementation FWControlWrapper (FWBlock)

- (NSString *)addBlock:(void (^)(id sender))block forControlEvents:(UIControlEvents)controlEvents
{
    FWInnerBlockTarget *target = [[FWInnerBlockTarget alloc] init];
    target.block = block;
    target.events = controlEvents;
    [self.base addTarget:target action:@selector(invoke:) forControlEvents:controlEvents];
    NSMutableArray *targets = [self innerBlockTargets];
    [targets addObject:target];
    return target.identifier;
}

- (void)removeBlock:(NSString *)identifier forControlEvents:(UIControlEvents)controlEvents
{
    if (!identifier) return;
    [self removeAllBlocksForControlEvents:controlEvents identifier:identifier];
}

- (void)removeAllBlocksForControlEvents:(UIControlEvents)controlEvents
{
    [self removeAllBlocksForControlEvents:controlEvents identifier:nil];
}

- (void)removeAllBlocksForControlEvents:(UIControlEvents)controlEvents identifier:(NSString *)identifier
{
    NSMutableArray *targets = [self innerBlockTargets];
    NSMutableArray *removes = [NSMutableArray array];
    for (FWInnerBlockTarget *target in targets) {
        if (target.events & controlEvents) {
            BOOL shouldRemove = !identifier || [identifier isEqualToString:target.identifier];
            if (!shouldRemove) continue;
            
            UIControlEvents newEvent = target.events & (~controlEvents);
            if (newEvent) {
                [self.base removeTarget:target action:@selector(invoke:) forControlEvents:target.events];
                target.events = newEvent;
                [self.base addTarget:target action:@selector(invoke:) forControlEvents:target.events];
            } else {
                [self.base removeTarget:target action:@selector(invoke:) forControlEvents:target.events];
                [removes addObject:target];
            }
        }
    }
    [targets removeObjectsInArray:removes];
}

- (NSMutableArray *)innerBlockTargets
{
    NSMutableArray *targets = objc_getAssociatedObject(self.base, _cmd);
    if (!targets) {
        targets = [NSMutableArray array];
        objc_setAssociatedObject(self.base, _cmd, targets, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return targets;
}

- (void)addTouchTarget:(id)target action:(SEL)action
{
    [self.base addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
}

- (NSString *)addTouchBlock:(void (^)(id sender))block
{
    return [self addBlock:block forControlEvents:UIControlEventTouchUpInside];
}

- (void)removeTouchBlock:(NSString *)identifier
{
    [self removeBlock:identifier forControlEvents:UIControlEventTouchUpInside];
}

@end

#pragma mark - FWBarButtonItemWrapper+FWBlock

@interface UIBarButtonItem (FWBlock)

@end

@implementation UIBarButtonItem (FWBlock)

- (void)innerInvokeTargetAction:(id)sender
{
    if (self.target && self.action && [self.target respondsToSelector:self.action]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        // 第一个参数UIBarButtonItem，第二个参数为UIControl或者手势对象
        [self.target performSelector:self.action withObject:self withObject:sender];
#pragma clang diagnostic pop
    }
}

@end

@implementation FWBarButtonItemWrapper (FWBlock)

- (NSDictionary<NSAttributedStringKey,id> *)titleAttributes
{
    return objc_getAssociatedObject(self.base, @selector(titleAttributes));
}

- (void)setTitleAttributes:(NSDictionary<NSAttributedStringKey,id> *)titleAttributes
{
    objc_setAssociatedObject(self.base, @selector(titleAttributes), titleAttributes, OBJC_ASSOCIATION_COPY_NONATOMIC);
    if (!titleAttributes) return;
    
    NSArray<NSNumber *> *states = @[@(UIControlStateNormal), @(UIControlStateHighlighted), @(UIControlStateDisabled), @(UIControlStateSelected), @(UIControlStateApplication), @(UIControlStateReserved)];
    for (NSNumber *state in states) {
        NSMutableDictionary *attributes = [self.base titleTextAttributesForState:[state unsignedIntegerValue]].mutableCopy ?: [NSMutableDictionary new];
        [attributes addEntriesFromDictionary:titleAttributes];
        [self.base setTitleTextAttributes:attributes forState:[state unsignedIntegerValue]];
    }
}

- (void)setBlock:(void (^)(id))block
{
    FWInnerBlockTarget *target = nil;
    SEL action = NULL;
    if (block) {
        target = [[FWInnerBlockTarget alloc] init];
        target.block = block;
        action = @selector(invoke:);
    }
    
    self.base.target = target;
    self.base.action = action;
    // 设置target为强引用，因为self.target为弱引用
    objc_setAssociatedObject(self.base, @selector(setBlock:), target, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)addItemEvent:(UIView *)customView
{
    // 进行self转发，模拟实际action回调参数
    if ([customView isKindOfClass:[UIControl class]]) {
        [((UIControl *)customView).fw addTouchTarget:self.base action:@selector(innerInvokeTargetAction:)];
    } else {
        [customView.fw addTapGestureWithTarget:self.base action:@selector(innerInvokeTargetAction:)];
    }
}

@end

#pragma mark - FWBarButtonItemClassWrapper+FWBlock

@implementation FWBarButtonItemClassWrapper (FWBlock)

- (UIBarButtonItem *)itemWithObject:(id)object target:(id)target action:(SEL)action
{
    UIBarButtonItem *barItem = nil;
    // NSString
    if ([object isKindOfClass:[NSString class]]) {
        barItem = [[self.base alloc] initWithTitle:object style:UIBarButtonItemStylePlain target:target action:action];
    // NSAttributedString
    } else if ([object isKindOfClass:[NSAttributedString class]]) {
        NSAttributedString *attributedString = (NSAttributedString *)object;
        barItem = [[self.base alloc] initWithTitle:attributedString.string style:UIBarButtonItemStylePlain target:target action:action];
        
        // 只支持NSFontAttributeName和NSForegroundColorAttributeName属性
        NSDictionary *attributes = [attributedString attributesAtIndex:0 effectiveRange:NULL];
        NSMutableDictionary *textAttributes = [NSMutableDictionary new];
        textAttributes[NSFontAttributeName] = attributes[NSFontAttributeName];
        textAttributes[NSForegroundColorAttributeName] = attributes[NSForegroundColorAttributeName];
        NSArray<NSNumber *> *states = @[@(UIControlStateNormal), @(UIControlStateHighlighted), @(UIControlStateDisabled), @(UIControlStateSelected), @(UIControlStateApplication), @(UIControlStateReserved)];
        for (NSNumber *state in states) {
            [barItem setTitleTextAttributes:textAttributes forState:[state unsignedIntegerValue]];
        }
    // UIImage
    } else if ([object isKindOfClass:[UIImage class]]) {
        barItem = [[self.base alloc] initWithImage:object style:UIBarButtonItemStylePlain target:target action:action];
    // NSNumber
    } else if ([object isKindOfClass:[NSNumber class]]) {
        barItem = [[self.base alloc] initWithBarButtonSystemItem:[object integerValue] target:target action:action];
    // UIView
    } else if ([object isKindOfClass:[UIView class]]) {
        barItem = [[self.base alloc] initWithCustomView:object];
        barItem.target = target;
        barItem.action = action;
        [barItem.fw addItemEvent:object];
    // Other
    } else {
        barItem = [[self.base alloc] init];
        barItem.target = target;
        barItem.action = action;
    }
    return barItem;
}

- (UIBarButtonItem *)itemWithObject:(id)object block:(void (^)(id))block
{
    UIBarButtonItem *barItem = [self itemWithObject:object target:nil action:nil];
    [barItem.fw setBlock:block];
    return barItem;
}

@end

#pragma mark - FWViewControllerWrapper+FWBlock

@implementation FWViewControllerWrapper (FWBlock)

- (NSString *)title
{
    return self.base.navigationItem.title;
}

- (void)setTitle:(NSString *)title
{
    self.base.navigationItem.title = title;
}

- (id)backBarItem
{
    return self.base.navigationItem.backBarButtonItem;
}

- (void)setBackBarItem:(id)object
{
    if ([object isKindOfClass:[UIImage class]]) {
        self.base.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage new] style:UIBarButtonItemStylePlain target:nil action:nil];
        self.base.navigationController.navigationBar.fw.backImage = (UIImage *)object;
    } else {
        UIBarButtonItem *backItem = [object isKindOfClass:[UIBarButtonItem class]] ? (UIBarButtonItem *)object : [UIBarButtonItem.fw itemWithObject:object ?: [UIImage new] target:nil action:nil];
        self.base.navigationItem.backBarButtonItem = backItem;
        self.base.navigationController.navigationBar.fw.backImage = nil;
    }
}

- (id)leftBarItem
{
    return self.base.navigationItem.leftBarButtonItem;
}

- (void)setLeftBarItem:(id)object
{
    if (!object || [object isKindOfClass:[UIBarButtonItem class]]) {
        self.base.navigationItem.leftBarButtonItem = object;
    } else {
        __weak UIViewController *weakController = self.base;
        self.base.navigationItem.leftBarButtonItem = [UIBarButtonItem.fw itemWithObject:object block:^(id  _Nonnull sender) {
            if (![weakController shouldPopController]) return;
            [weakController.fw closeViewControllerAnimated:YES];
        }];
    }
}

- (id)rightBarItem
{
    return self.base.navigationItem.rightBarButtonItem;
}

- (void)setRightBarItem:(id)object
{
    if (!object || [object isKindOfClass:[UIBarButtonItem class]]) {
        self.base.navigationItem.rightBarButtonItem = object;
    } else {
        __weak UIViewController *weakController = self.base;
        self.base.navigationItem.rightBarButtonItem = [UIBarButtonItem.fw itemWithObject:object block:^(id  _Nonnull sender) {
            if (![weakController shouldPopController]) return;
            [weakController.fw closeViewControllerAnimated:YES];
        }];
    }
}

- (void)setLeftBarItem:(id)object target:(id)target action:(SEL)action
{
    self.base.navigationItem.leftBarButtonItem = [UIBarButtonItem.fw itemWithObject:object target:target action:action];
}

- (void)setLeftBarItem:(id)object block:(void (^)(id sender))block
{
    self.base.navigationItem.leftBarButtonItem = [UIBarButtonItem.fw itemWithObject:object block:block];
}

- (void)setRightBarItem:(id)object target:(id)target action:(SEL)action
{
    self.base.navigationItem.rightBarButtonItem = [UIBarButtonItem.fw itemWithObject:object target:target action:action];
}

- (void)setRightBarItem:(id)object block:(void (^)(id sender))block
{
    self.base.navigationItem.rightBarButtonItem = [UIBarButtonItem.fw itemWithObject:object block:block];
}

- (void)addLeftBarItem:(id)object target:(id)target action:(SEL)action
{
    UIBarButtonItem *barItem = [UIBarButtonItem.fw itemWithObject:object target:target action:action];
    NSMutableArray *items = self.base.navigationItem.leftBarButtonItems ? [self.base.navigationItem.leftBarButtonItems mutableCopy] : [NSMutableArray new];
    [items addObject:barItem];
    self.base.navigationItem.leftBarButtonItems = [items copy];
}

- (void)addLeftBarItem:(id)object block:(void (^)(id sender))block
{
    UIBarButtonItem *barItem = [UIBarButtonItem.fw itemWithObject:object block:block];
    NSMutableArray *items = self.base.navigationItem.leftBarButtonItems ? [self.base.navigationItem.leftBarButtonItems mutableCopy] : [NSMutableArray new];
    [items addObject:barItem];
    self.base.navigationItem.leftBarButtonItems = [items copy];
}

- (void)addRightBarItem:(id)object target:(id)target action:(SEL)action
{
    UIBarButtonItem *barItem = [UIBarButtonItem.fw itemWithObject:object target:target action:action];
    NSMutableArray *items = self.base.navigationItem.rightBarButtonItems ? [self.base.navigationItem.rightBarButtonItems mutableCopy] : [NSMutableArray new];
    [items addObject:barItem];
    self.base.navigationItem.rightBarButtonItems = [items copy];
}

- (void)addRightBarItem:(id)object block:(void (^)(id sender))block
{
    UIBarButtonItem *barItem = [UIBarButtonItem.fw itemWithObject:object block:block];
    NSMutableArray *items = self.base.navigationItem.rightBarButtonItems ? [self.base.navigationItem.rightBarButtonItems mutableCopy] : [NSMutableArray new];
    [items addObject:barItem];
    self.base.navigationItem.rightBarButtonItems = [items copy];
}

@end
