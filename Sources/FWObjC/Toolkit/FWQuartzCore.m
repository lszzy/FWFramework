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

#pragma mark - CADisplayLink+FWQuartzCore

@implementation CADisplayLink (FWQuartzCore)

+ (CADisplayLink *)fw_commonDisplayLinkWithTarget:(id)target selector:(SEL)selector
{
    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:target selector:selector];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    return displayLink;
}

+ (CADisplayLink *)fw_commonDisplayLinkWithBlock:(void (^)(CADisplayLink *))block
{
    CADisplayLink *displayLink = [self fw_displayLinkWithBlock:block];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    return displayLink;
}

+ (CADisplayLink *)fw_displayLinkWithBlock:(void (^)(CADisplayLink *))block
{
    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:[self class] selector:@selector(fw_displayLinkAction:)];
    objc_setAssociatedObject(displayLink, @selector(fw_displayLinkWithBlock:), block, OBJC_ASSOCIATION_COPY_NONATOMIC);
    return displayLink;
}

+ (void)fw_displayLinkAction:(CADisplayLink *)displayLink
{
    void (^block)(CADisplayLink *displayLink) = objc_getAssociatedObject(displayLink, @selector(fw_displayLinkWithBlock:));
    if (block) {
        block(displayLink);
    }
}

@end

#pragma mark - FWAnimationWrapper+FWQuartzCore

@interface FWInnerAnimationTarget : NSObject <CAAnimationDelegate>

@property (nonatomic, copy) void (^startBlock)(CAAnimation *animation);

@property (nonatomic, copy) void (^stopBlock)(CAAnimation *animation, BOOL finished);

@end

@implementation FWInnerAnimationTarget

- (void)animationDidStart:(CAAnimation *)anim
{
    if (self.startBlock) self.startBlock(anim);
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    if (self.stopBlock) self.stopBlock(anim, flag);
}

@end

@implementation CAAnimation (FWQuartzCore)

- (FWInnerAnimationTarget *)fw_innerAnimationTarget:(BOOL)lazyload
{
    FWInnerAnimationTarget *target = objc_getAssociatedObject(self, _cmd);
    if (!target && lazyload) {
        target = [[FWInnerAnimationTarget alloc] init];
        objc_setAssociatedObject(self, _cmd, target, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return target;
}

- (void (^)(CAAnimation * _Nonnull))fw_startBlock
{
    FWInnerAnimationTarget *target = [self fw_innerAnimationTarget:NO];
    return target.startBlock;
}

- (void)setFw_startBlock:(void (^)(CAAnimation * _Nonnull))startBlock
{
    FWInnerAnimationTarget *target = [self fw_innerAnimationTarget:YES];
    target.startBlock = startBlock;
    self.delegate = target;
}

- (void (^)(CAAnimation * _Nonnull, BOOL))fw_stopBlock
{
    FWInnerAnimationTarget *target = [self fw_innerAnimationTarget:NO];
    return target.stopBlock;
}

- (void)setFw_stopBlock:(void (^)(CAAnimation * _Nonnull, BOOL))stopBlock
{
    FWInnerAnimationTarget *target = [self fw_innerAnimationTarget:YES];
    target.stopBlock = stopBlock;
    self.delegate = target;
}

@end

#pragma mark - CALayer+FWQuartzCore

@implementation CALayer (FWQuartzCore)

- (UIColor *)fw_themeBackgroundColor
{
    return objc_getAssociatedObject(self, @selector(fw_themeBackgroundColor));
}

- (void)setFw_themeBackgroundColor:(UIColor *)themeBackgroundColor
{
    objc_setAssociatedObject(self, @selector(fw_themeBackgroundColor), themeBackgroundColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.backgroundColor = themeBackgroundColor.CGColor;
}

- (UIColor *)fw_themeBorderColor
{
    return objc_getAssociatedObject(self, @selector(fw_themeBorderColor));
}

- (void)setFw_themeBorderColor:(UIColor *)themeBorderColor
{
    objc_setAssociatedObject(self, @selector(fw_themeBorderColor), themeBorderColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.borderColor = themeBorderColor.CGColor;
}

- (UIColor *)fw_themeShadowColor
{
    return objc_getAssociatedObject(self, @selector(fw_themeShadowColor));
}

- (void)setFw_themeShadowColor:(UIColor *)themeShadowColor
{
    objc_setAssociatedObject(self, @selector(fw_themeShadowColor), themeShadowColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.shadowColor = themeShadowColor.CGColor;
}

- (UIImage *)fw_themeContents
{
    return objc_getAssociatedObject(self, @selector(fw_themeContents));
}

- (void)setFw_themeContents:(UIImage *)themeContents
{
    objc_setAssociatedObject(self, @selector(fw_themeContents), themeContents, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.contents = (id)themeContents.fw_image.CGImage;
}

- (void)fw_themeChanged:(FWThemeStyle)style
{
    [super fw_themeChanged:style];
    
    if (self.fw_themeBackgroundColor != nil) {
        self.backgroundColor = self.fw_themeBackgroundColor.CGColor;
    }
    if (self.fw_themeBorderColor != nil) {
        self.borderColor = self.fw_themeBorderColor.CGColor;
    }
    if (self.fw_themeShadowColor != nil) {
        self.shadowColor = self.fw_themeShadowColor.CGColor;
    }
    if (self.fw_themeContents && self.fw_themeContents.fw_isThemeImage) {
        self.contents = (id)self.fw_themeContents.fw_image.CGImage;
    }
}

- (void)fw_setShadowColor:(UIColor *)color
                  offset:(CGSize)offset
                  radius:(CGFloat)radius
{
    self.shadowColor = color.CGColor;
    self.shadowOffset = offset;
    self.shadowRadius = radius;
    self.shadowOpacity = 1.0;
}

@end

#pragma mark - CAGradientLayer+FWQuartzCore

@implementation CAGradientLayer (FWQuartzCore)

- (NSArray<UIColor *> *)fw_themeColors
{
    return objc_getAssociatedObject(self, @selector(fw_themeColors));
}

- (void)setFw_themeColors:(NSArray<UIColor *> *)themeColors
{
    objc_setAssociatedObject(self, @selector(fw_themeColors), themeColors, OBJC_ASSOCIATION_COPY_NONATOMIC);
    
    NSMutableArray *colors = nil;
    if (themeColors != nil) {
        colors = [NSMutableArray new];
        for (UIColor *color in themeColors) {
            [colors addObject:(id)color.CGColor];
        }
    }
    self.colors = colors.copy;
}

- (void)fw_themeChanged:(FWThemeStyle)style
{
    [super fw_themeChanged:style];
    
    if (self.fw_themeColors != nil) {
        NSMutableArray *colors = [NSMutableArray new];
        for (UIColor *color in self.fw_themeColors) {
            [colors addObject:(id)color.CGColor];
        }
        self.colors = colors.copy;
    }
}

+ (CAGradientLayer *)fw_gradientLayer:(CGRect)frame
                              colors:(NSArray *)colors
                           locations:(NSArray<NSNumber *> *)locations
                          startPoint:(CGPoint)startPoint
                            endPoint:(CGPoint)endPoint
{
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = frame;
    gradientLayer.colors = colors;
    gradientLayer.locations = locations;
    gradientLayer.startPoint = startPoint;
    gradientLayer.endPoint = endPoint;
    return gradientLayer;
}

@end

#pragma mark - UIView+FWQuartzCore

@implementation UIView (FWQuartzCore)

- (void)fw_drawBezierPath:(UIBezierPath *)bezierPath
             strokeWidth:(CGFloat)strokeWidth
             strokeColor:(UIColor *)strokeColor
               fillColor:(UIColor *)fillColor
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    
    CGContextSetLineWidth(ctx, strokeWidth);
    CGContextSetLineCap(ctx, kCGLineCapRound);
    [strokeColor setStroke];
    CGContextAddPath(ctx, bezierPath.CGPath);
    CGContextStrokePath(ctx);
    
    if (fillColor) {
        [fillColor setFill];
        CGContextAddPath(ctx, bezierPath.CGPath);
        CGContextFillPath(ctx);
    }
    
    CGContextRestoreGState(ctx);
}

- (void)fw_drawLinearGradient:(CGRect)rect
                      colors:(NSArray *)colors
                   locations:(const CGFloat *)locations
                   direction:(UISwipeGestureRecognizerDirection)direction
{
    NSArray<NSValue *> *linePoints = [UIBezierPath fw_linePointsWithRect:rect direction:direction];
    CGPoint startPoint = [linePoints.firstObject CGPointValue];
    CGPoint endPoint = [linePoints.lastObject CGPointValue];
    [self fw_drawLinearGradient:rect colors:colors locations:locations startPoint:startPoint endPoint:endPoint];
}

- (void)fw_drawLinearGradient:(CGRect)rect
                      colors:(NSArray *)colors
                   locations:(const CGFloat *)locations
                  startPoint:(CGPoint)startPoint
                    endPoint:(CGPoint)endPoint
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    
    CGContextAddRect(ctx, rect);
    CGContextClip(ctx);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)colors, locations);
    CGContextDrawLinearGradient(ctx, gradient, startPoint, endPoint, 0);
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
    
    CGContextRestoreGState(ctx);
}

- (CAGradientLayer *)fw_addGradientLayer:(CGRect)frame
                                 colors:(NSArray *)colors
                              locations:(NSArray<NSNumber *> *)locations
                             startPoint:(CGPoint)startPoint
                               endPoint:(CGPoint)endPoint
{
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = frame;
    gradientLayer.colors = colors;
    gradientLayer.locations = locations;
    gradientLayer.startPoint = startPoint;
    gradientLayer.endPoint = endPoint;
    
    [self.layer addSublayer:gradientLayer];
    return gradientLayer;
}

- (CALayer *)fw_addDashLayer:(CGRect)rect
                 lineLength:(CGFloat)lineLength
                lineSpacing:(CGFloat)lineSpacing
                  lineColor:(UIColor *)lineColor
{
    CAShapeLayer *dashLayer = [CAShapeLayer layer];
    dashLayer.frame = rect;
    dashLayer.fillColor = [UIColor clearColor].CGColor;
    dashLayer.strokeColor = lineColor.CGColor;
    
    BOOL isVertical = (lineLength + lineSpacing > rect.size.width) ? YES : NO;
    dashLayer.lineWidth = isVertical ? CGRectGetWidth(rect) : CGRectGetHeight(rect);
    dashLayer.lineJoin = kCALineJoinRound;
    dashLayer.lineDashPattern = @[@(lineLength), @(lineSpacing)];
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    if (isVertical) {
        [path moveToPoint:CGPointMake(CGRectGetWidth(rect) / 2, 0)];
        [path addLineToPoint:CGPointMake(CGRectGetWidth(rect) / 2, CGRectGetHeight(rect))];
    } else {
        [path moveToPoint:CGPointMake(0, CGRectGetHeight(rect) / 2)];
        [path addLineToPoint:CGPointMake(CGRectGetWidth(rect), CGRectGetHeight(rect) / 2)];
    }
    dashLayer.path = path.CGPath;
    [self.layer addSublayer:dashLayer];
    return dashLayer;
}

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
