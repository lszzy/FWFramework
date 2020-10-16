/*!
 @header     FWBlock.m
 @indexgroup FWFramework
 @brief      FWBlock
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/10/16
 */

#import "FWBlock.h"
#import <objc/runtime.h>

#pragma mark - CADisplayLink+FWBlock

@implementation CADisplayLink (FWBlock)

+ (CADisplayLink *)fwCommonDisplayLinkWithTarget:(id)target selector:(SEL)selector
{
    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:target selector:selector];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    return displayLink;
}

+ (CADisplayLink *)fwCommonDisplayLinkWithBlock:(void (^)(CADisplayLink *))block
{
    CADisplayLink *displayLink = [self fwDisplayLinkWithBlock:block];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    return displayLink;
}

+ (CADisplayLink *)fwDisplayLinkWithBlock:(void (^)(CADisplayLink *))block
{
    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(fwInnerDisplayLinkBlock:)];
    objc_setAssociatedObject(displayLink, @selector(fwDisplayLinkWithBlock:), block, OBJC_ASSOCIATION_COPY_NONATOMIC);
    return displayLink;
}

+ (void)fwInnerDisplayLinkBlock:(CADisplayLink *)displayLink
{
    void (^block)(CADisplayLink *displayLink) = objc_getAssociatedObject(displayLink, @selector(fwDisplayLinkWithBlock:));
    if (block) {
        block(displayLink);
    }
}

@end

#pragma mark - NSTimer+FWBlock

@implementation NSTimer (FWBlock)

+ (NSTimer *)fwCommonTimerWithTimeInterval:(NSTimeInterval)seconds target:(id)target selector:(SEL)selector userInfo:(id)userInfo repeats:(BOOL)repeats
{
    NSTimer *timer = [NSTimer timerWithTimeInterval:seconds target:target selector:selector userInfo:userInfo repeats:repeats];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    return timer;
}

+ (NSTimer *)fwCommonTimerWithTimeInterval:(NSTimeInterval)seconds block:(void (^)(NSTimer *))block repeats:(BOOL)repeats
{
    NSTimer *timer = [NSTimer fwTimerWithTimeInterval:seconds block:block repeats:repeats];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    return timer;
}

+ (NSTimer *)fwCommonTimerWithCountDown:(NSInteger)seconds block:(void (^)(NSInteger))block
{
    __block NSInteger countdown = seconds;
    NSTimer *timer = [self fwCommonTimerWithTimeInterval:1 block:^(NSTimer *timer) {
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

+ (NSTimer *)fwScheduledTimerWithTimeInterval:(NSTimeInterval)seconds block:(void (^)(NSTimer *))block repeats:(BOOL)repeats
{
    return [NSTimer scheduledTimerWithTimeInterval:seconds target:self selector:@selector(fwInnerTimerBlock:) userInfo:[block copy] repeats:repeats];
}

+ (NSTimer *)fwTimerWithTimeInterval:(NSTimeInterval)seconds block:(void (^)(NSTimer *))block repeats:(BOOL)repeats
{
    return [NSTimer timerWithTimeInterval:seconds target:self selector:@selector(fwInnerTimerBlock:) userInfo:[block copy] repeats:repeats];
}

+ (void)fwInnerTimerBlock:(NSTimer *)timer
{
    if ([timer userInfo]) {
        void (^block)(NSTimer *timer) = (void (^)(NSTimer *timer))[timer userInfo];
        block(timer);
    }
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

+ (instancetype)fwGestureRecognizerWithBlock:(void (^)(id))block
{
    UIGestureRecognizer *gestureRecognizer = [[self alloc] init];
    [gestureRecognizer fwAddBlock:block];
    return gestureRecognizer;
}

- (NSString *)fwAddBlock:(void (^)(id sender))block
{
    FWInnerBlockTarget *target = [[FWInnerBlockTarget alloc] init];
    target.block = block;
    [self addTarget:target action:@selector(invoke:)];
    NSMutableArray *targets = [self fwInnerBlockTargets];
    [targets addObject:target];
    return target.identifier;
}

- (void)fwRemoveBlock:(NSString *)identifier
{
    if (!identifier) return;
    NSMutableArray *targets = [self fwInnerBlockTargets];
    [targets enumerateObjectsUsingBlock:^(FWInnerBlockTarget *target, NSUInteger idx, BOOL *stop) {
        if ([identifier isEqualToString:target.identifier]) {
            [self removeTarget:target action:@selector(invoke:)];
            [targets removeObject:target];
        }
    }];
}

- (void)fwRemoveAllBlocks
{
    NSMutableArray *targets = [self fwInnerBlockTargets];
    [targets enumerateObjectsUsingBlock:^(id target, NSUInteger idx, BOOL *stop) {
        [self removeTarget:target action:@selector(invoke:)];
    }];
    [targets removeAllObjects];
}

- (NSMutableArray *)fwInnerBlockTargets
{
    NSMutableArray *targets = objc_getAssociatedObject(self, _cmd);
    if (!targets) {
        targets = [NSMutableArray array];
        objc_setAssociatedObject(self, _cmd, targets, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return targets;
}

@end

#pragma mark - UIView+FWBlock

@implementation UIView (FWBlock)

- (void)fwAddTapGestureWithTarget:(id)target action:(SEL)action
{
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:target action:action];
    [self addGestureRecognizer:gesture];
}

- (NSString *)fwAddTapGestureWithBlock:(void (^)(id sender))block
{
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] init];
    NSString *identifier = [gesture fwAddBlock:block];
    objc_setAssociatedObject(gesture, @selector(fwAddTapGestureWithBlock:), identifier, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self addGestureRecognizer:gesture];
    return identifier;
}

- (void)fwRemoveTapGesture:(NSString *)identifier
{
    if (!identifier) return;
    for (UIGestureRecognizer *gesture in self.gestureRecognizers) {
        if ([gesture isKindOfClass:[UITapGestureRecognizer class]]) {
            NSString *gestureIdentifier = objc_getAssociatedObject(gesture, @selector(fwAddTapGestureWithBlock:));
            if (gestureIdentifier && [identifier isEqualToString:gestureIdentifier]) {
                [self removeGestureRecognizer:gesture];
            }
        }
    }
}

- (void)fwRemoveAllTapGestures
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

- (NSString *)fwAddBlock:(void (^)(id sender))block forControlEvents:(UIControlEvents)controlEvents
{
    FWInnerBlockTarget *target = [[FWInnerBlockTarget alloc] init];
    target.block = block;
    target.events = controlEvents;
    [self addTarget:target action:@selector(invoke:) forControlEvents:controlEvents];
    NSMutableArray *targets = [self fwInnerBlockTargets];
    [targets addObject:target];
    return target.identifier;
}

- (void)fwRemoveBlock:(NSString *)identifier forControlEvents:(UIControlEvents)controlEvents
{
    if (!identifier) return;
    [self fwRemoveAllBlocksForControlEvents:controlEvents identifier:identifier];
}

- (void)fwRemoveAllBlocksForControlEvents:(UIControlEvents)controlEvents
{
    [self fwRemoveAllBlocksForControlEvents:controlEvents identifier:nil];
}

- (void)fwRemoveAllBlocksForControlEvents:(UIControlEvents)controlEvents identifier:(NSString *)identifier
{
    NSMutableArray *targets = [self fwInnerBlockTargets];
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

- (NSMutableArray *)fwInnerBlockTargets
{
    NSMutableArray *targets = objc_getAssociatedObject(self, _cmd);
    if (!targets) {
        targets = [NSMutableArray array];
        objc_setAssociatedObject(self, _cmd, targets, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return targets;
}

- (void)fwAddTouchTarget:(id)target action:(SEL)action
{
    [self addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
}

- (NSString *)fwAddTouchBlock:(void (^)(id sender))block
{
    return [self fwAddBlock:block forControlEvents:UIControlEventTouchUpInside];
}

- (void)fwRemoveTouchBlock:(NSString *)identifier
{
    [self fwRemoveBlock:identifier forControlEvents:UIControlEventTouchUpInside];
}

@end

#pragma mark - UIBarButtonItem+FWBlock

static void *kUIBarButtonItemFWBlockKey = &kUIBarButtonItemFWBlockKey;

@implementation UIBarButtonItem (FWBlock)

+ (instancetype)fwBarItemWithObject:(id)object target:(id)target action:(SEL)action
{
    UIBarButtonItem *barItem = nil;
    // NSString
    if ([object isKindOfClass:[NSString class]]) {
        barItem = [[self alloc] initWithTitle:object style:UIBarButtonItemStylePlain target:target action:action];
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
        // 目标动作存在，则添加点击手势，可设置target为空取消响应
        if (barItem.target && barItem.action) {
            // 进行self转发，模拟实际action回调参数
            if ([object isKindOfClass:[UIControl class]]) {
                [(UIControl *)object fwAddTouchTarget:barItem action:@selector(fwInnerTargetAction:)];
            } else {
                [(UIView *)object fwAddTapGestureWithTarget:barItem action:@selector(fwInnerTargetAction:)];
            }
        }
    // Other
    } else {
        barItem = [[self alloc] init];
        barItem.target = target;
        barItem.action = action;
    }
    return barItem;
}

+ (instancetype)fwBarItemWithObject:(id)object block:(void (^)(id))block
{
    FWInnerBlockTarget *target = nil;
    SEL action = NULL;
    if (block) {
        target = [[FWInnerBlockTarget alloc] init];
        target.block = block;
        action = @selector(invoke:);
    }
    
    UIBarButtonItem *barItem = [self fwBarItemWithObject:object target:target action:action];
    if (target) {
        // 设置target为强引用，因为self.target为弱引用
        objc_setAssociatedObject(barItem, kUIBarButtonItemFWBlockKey, target, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return barItem;
}

- (void)fwInnerTargetAction:(id)sender
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
