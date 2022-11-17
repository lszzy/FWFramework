//
//  FWQuartzCore.m
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import "FWQuartzCore.h"
#import "FWUIKit.h"
#import "FWTheme.h"
#import <objc/runtime.h>
#if FWMacroSPM
@import FWFramework;
#else
#import <FWFramework/FWFramework-Swift.h>
#endif

#pragma mark - UIView+FWQuartzCore

@implementation UIView (FWQuartzCore)

#pragma mark - Drag

- (BOOL)fw_dragEnabled
{
    return self.fw_dragGesture.enabled;
}

- (void)setFw_dragEnabled:(BOOL)dragEnabled
{
    self.fw_dragGesture.enabled = dragEnabled;
}

- (CGRect)fw_dragLimit
{
    return [objc_getAssociatedObject(self, @selector(fw_dragLimit)) CGRectValue];
}

- (void)setFw_dragLimit:(CGRect)dragLimit
{
    if (CGRectEqualToRect(dragLimit, CGRectZero) ||
        CGRectContainsRect(dragLimit, self.frame)) {
        objc_setAssociatedObject(self, @selector(fw_dragLimit), [NSValue valueWithCGRect:dragLimit], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (CGRect)fw_dragArea
{
    return [objc_getAssociatedObject(self, @selector(fw_dragArea)) CGRectValue];
}

- (void)setFw_dragArea:(CGRect)dragArea
{
    CGRect relativeFrame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    if (CGRectContainsRect(relativeFrame, dragArea)) {
        objc_setAssociatedObject(self, @selector(fw_dragArea), [NSValue valueWithCGRect:dragArea], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (BOOL)fw_dragVertical
{
    NSNumber *value = objc_getAssociatedObject(self, @selector(fw_dragVertical));
    return value ? [value boolValue] : YES;
}

- (void)setFw_dragVertical:(BOOL)dragVertical
{
    objc_setAssociatedObject(self, @selector(fw_dragVertical), [NSNumber numberWithBool:dragVertical], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)fw_dragHorizontal
{
    NSNumber *value = objc_getAssociatedObject(self, @selector(fw_dragHorizontal));
    return value ? [value boolValue] : YES;
}

- (void)setFw_dragHorizontal:(BOOL)dragHorizontal
{
    objc_setAssociatedObject(self, @selector(fw_dragHorizontal), [NSNumber numberWithBool:dragHorizontal], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void (^)(UIView *))fw_dragStartedBlock
{
    return objc_getAssociatedObject(self, @selector(fw_dragStartedBlock));
}

- (void)setFw_dragStartedBlock:(void (^)(UIView *))dragStartedBlock
{
    objc_setAssociatedObject(self, @selector(fw_dragStartedBlock), dragStartedBlock, OBJC_ASSOCIATION_COPY);
}

- (void (^)(UIView *))fw_dragMovedBlock
{
    return objc_getAssociatedObject(self, @selector(fw_dragMovedBlock));
}

- (void)setFw_dragMovedBlock:(void (^)(UIView *))dragMovedBlock
{
    objc_setAssociatedObject(self, @selector(fw_dragMovedBlock), dragMovedBlock, OBJC_ASSOCIATION_COPY);
}

- (void (^)(UIView *))fw_dragEndedBlock
{
    return objc_getAssociatedObject(self, @selector(fw_dragEndedBlock));
}

- (void)setFw_dragEndedBlock:(void (^)(UIView *))dragEndedBlock
{
    objc_setAssociatedObject(self, @selector(fw_dragEndedBlock), dragEndedBlock, OBJC_ASSOCIATION_COPY);
}

- (UIPanGestureRecognizer *)fw_dragGesture
{
    UIPanGestureRecognizer *gesture = objc_getAssociatedObject(self, _cmd);
    if (!gesture) {
        // 初始化拖动手势，默认禁用
        gesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(fw_innerDragHandler:)];
        gesture.maximumNumberOfTouches = 1;
        gesture.minimumNumberOfTouches = 1;
        gesture.cancelsTouchesInView = NO;
        gesture.enabled = NO;
        self.fw_dragArea = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        [self addGestureRecognizer:gesture];
        
        objc_setAssociatedObject(self, _cmd, gesture, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return gesture;
}

- (void)fw_innerDragHandler:(UIPanGestureRecognizer *)sender
{
    // 检查是否能够在拖动区域拖动
    CGPoint locationInView = [sender locationInView:self];
    if (!CGRectContainsPoint(self.fw_dragArea, locationInView) &&
        sender.state == UIGestureRecognizerStateBegan) {
        return;
    }
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        CGPoint locationInView = [sender locationInView:self];
        CGPoint locationInSuperview = [sender locationInView:self.superview];
        
        self.layer.anchorPoint = CGPointMake(locationInView.x / self.bounds.size.width, locationInView.y / self.bounds.size.height);
        self.center = locationInSuperview;
    }
    
    if (sender.state == UIGestureRecognizerStateBegan && self.fw_dragStartedBlock) {
        self.fw_dragStartedBlock(self);
    }
    
    if (sender.state == UIGestureRecognizerStateChanged && self.fw_dragMovedBlock) {
        self.fw_dragMovedBlock(self);
    }
    
    if (sender.state == UIGestureRecognizerStateEnded && self.fw_dragEndedBlock) {
        self.fw_dragEndedBlock(self);
    }
    
    CGPoint translation = [sender translationInView:[self superview]];
    
    CGFloat newXOrigin = CGRectGetMinX(self.frame) + (([self fw_dragHorizontal]) ? translation.x : 0);
    CGFloat newYOrigin = CGRectGetMinY(self.frame) + (([self fw_dragVertical]) ? translation.y : 0);
    
    CGRect cagingArea = self.fw_dragLimit;
    
    CGFloat cagingAreaOriginX = CGRectGetMinX(cagingArea);
    CGFloat cagingAreaOriginY = CGRectGetMinY(cagingArea);
    
    CGFloat cagingAreaRightSide = cagingAreaOriginX + CGRectGetWidth(cagingArea);
    CGFloat cagingAreaBottomSide = cagingAreaOriginY + CGRectGetHeight(cagingArea);
    
    if (!CGRectEqualToRect(cagingArea, CGRectZero)) {
        // 确保视图在限制区域内
        if (newXOrigin <= cagingAreaOriginX ||
            newXOrigin + CGRectGetWidth(self.frame) >= cagingAreaRightSide) {
            newXOrigin = CGRectGetMinX(self.frame);
        }
        
        if (newYOrigin <= cagingAreaOriginY ||
            newYOrigin + CGRectGetHeight(self.frame) >= cagingAreaBottomSide) {
            newYOrigin = CGRectGetMinY(self.frame);
        }
    }
    
    [self setFrame:CGRectMake(newXOrigin,
                              newYOrigin,
                              CGRectGetWidth(self.frame),
                              CGRectGetHeight(self.frame))];
    
    [sender setTranslation:(CGPoint){0, 0} inView:[self superview]];
}

@end

#pragma mark - FWGradientView

@implementation FWGradientView

+ (Class)layerClass
{
    return [CAGradientLayer class];
}

- (instancetype)initWithColors:(NSArray<UIColor *> *)colors locations:(NSArray<NSNumber *> *)locations startPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint
{
    self = [super init];
    if (self) {
        [self setColors:colors locations:locations startPoint:startPoint endPoint:endPoint];
    }
    return self;
}

- (void)setColors:(NSArray<UIColor *> *)colors locations:(NSArray<NSNumber *> *)locations startPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint
{
    NSMutableArray *cgColors = [NSMutableArray array];
    for (UIColor *color in colors) {
        [cgColors addObject:(__bridge id)color.CGColor];
    }
    self.gradientLayer.colors = [cgColors copy];
    self.gradientLayer.locations = locations;
    self.gradientLayer.startPoint = startPoint;
    self.gradientLayer.endPoint = endPoint;
}

- (CAGradientLayer *)gradientLayer
{
    return (CAGradientLayer *)self.layer;
}

- (NSArray *)colors
{
    return self.gradientLayer.colors;
}

- (void)setColors:(NSArray *)colors
{
    self.gradientLayer.colors = colors;
}

- (NSArray<NSNumber *> *)locations
{
    return self.gradientLayer.locations;
}

- (void)setLocations:(NSArray<NSNumber *> *)locations
{
    self.gradientLayer.locations = locations;
}

- (CGPoint)startPoint
{
    return self.gradientLayer.startPoint;
}

- (void)setStartPoint:(CGPoint)startPoint
{
    self.gradientLayer.startPoint = startPoint;
}

- (CGPoint)endPoint
{
    return self.gradientLayer.endPoint;
}

- (void)setEndPoint:(CGPoint)endPoint
{
    self.gradientLayer.endPoint = endPoint;
}

@end
