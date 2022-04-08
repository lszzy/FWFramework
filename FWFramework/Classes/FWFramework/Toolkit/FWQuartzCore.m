/**
 @header     FWQuartzCore.m
 @indexgroup FWFramework
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/10/22
 */

#import "FWQuartzCore.h"
#import "FWTheme.h"
#import <objc/runtime.h>

#pragma mark - FWDisplayLinkClassWrapper+FWQuartzCore

@implementation FWDisplayLinkClassWrapper (FWQuartzCore)

- (CADisplayLink *)commonDisplayLinkWithTarget:(id)target selector:(SEL)selector
{
    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:target selector:selector];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    return displayLink;
}

- (CADisplayLink *)commonDisplayLinkWithBlock:(void (^)(CADisplayLink *))block
{
    CADisplayLink *displayLink = [self displayLinkWithBlock:block];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    return displayLink;
}

- (CADisplayLink *)displayLinkWithBlock:(void (^)(CADisplayLink *))block
{
    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:[self class] selector:@selector(displayLinkAction:)];
    objc_setAssociatedObject(displayLink, @selector(displayLinkWithBlock:), block, OBJC_ASSOCIATION_COPY_NONATOMIC);
    return displayLink;
}

+ (void)displayLinkAction:(CADisplayLink *)displayLink
{
    void (^block)(CADisplayLink *displayLink) = objc_getAssociatedObject(displayLink, @selector(displayLinkWithBlock:));
    if (block) {
        block(displayLink);
    }
}

@end

#pragma mark - CAAnimation+FWQuartzCore

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

- (FWInnerAnimationTarget *)fwInnerAnimationTarget:(BOOL)lazyload
{
    FWInnerAnimationTarget *target = objc_getAssociatedObject(self, _cmd);
    if (!target && lazyload) {
        target = [[FWInnerAnimationTarget alloc] init];
        objc_setAssociatedObject(self, _cmd, target, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return target;
}

- (void (^)(CAAnimation * _Nonnull))fwStartBlock
{
    FWInnerAnimationTarget *target = [self fwInnerAnimationTarget:NO];
    return target.startBlock;
}

- (void)setFwStartBlock:(void (^)(CAAnimation * _Nonnull))startBlock
{
    FWInnerAnimationTarget *target = [self fwInnerAnimationTarget:YES];
    target.startBlock = startBlock;
    self.delegate = target;
}

- (void (^)(CAAnimation * _Nonnull, BOOL))fwStopBlock
{
    FWInnerAnimationTarget *target = [self fwInnerAnimationTarget:NO];
    return target.stopBlock;
}

- (void)setFwStopBlock:(void (^)(CAAnimation * _Nonnull, BOOL))stopBlock
{
    FWInnerAnimationTarget *target = [self fwInnerAnimationTarget:YES];
    target.stopBlock = stopBlock;
    self.delegate = target;
}

@end

#pragma mark - CALayer+FWQuartzCore

@implementation CALayer (FWQuartzCore)

- (UIColor *)fwThemeBackgroundColor
{
    return objc_getAssociatedObject(self, @selector(fwThemeBackgroundColor));
}

- (void)setFwThemeBackgroundColor:(UIColor *)fwThemeBackgroundColor
{
    objc_setAssociatedObject(self, @selector(fwThemeBackgroundColor), fwThemeBackgroundColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.backgroundColor = fwThemeBackgroundColor.CGColor;
}

- (UIColor *)fwThemeBorderColor
{
    return objc_getAssociatedObject(self, @selector(fwThemeBorderColor));
}

- (void)setFwThemeBorderColor:(UIColor *)fwThemeBorderColor
{
    objc_setAssociatedObject(self, @selector(fwThemeBorderColor), fwThemeBorderColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.borderColor = fwThemeBorderColor.CGColor;
}

- (UIColor *)fwThemeShadowColor
{
    return objc_getAssociatedObject(self, @selector(fwThemeShadowColor));
}

- (void)setFwThemeShadowColor:(UIColor *)fwThemeShadowColor
{
    objc_setAssociatedObject(self, @selector(fwThemeShadowColor), fwThemeShadowColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.shadowColor = fwThemeShadowColor.CGColor;
}

- (UIImage *)fwThemeContents
{
    return objc_getAssociatedObject(self, @selector(fwThemeContents));
}

- (void)setFwThemeContents:(UIImage *)fwThemeContents
{
    objc_setAssociatedObject(self, @selector(fwThemeContents), fwThemeContents, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.contents = (id)fwThemeContents.fwImage.CGImage;
}

- (void)fwThemeChanged:(FWThemeStyle)style
{
    [super fwThemeChanged:style];
    
    if (self.fwThemeBackgroundColor != nil) {
        self.backgroundColor = self.fwThemeBackgroundColor.CGColor;
    }
    if (self.fwThemeBorderColor != nil) {
        self.borderColor = self.fwThemeBorderColor.CGColor;
    }
    if (self.fwThemeShadowColor != nil) {
        self.shadowColor = self.fwThemeShadowColor.CGColor;
    }
    if (self.fwThemeContents && self.fwThemeContents.fwIsThemeImage) {
        self.contents = (id)self.fwThemeContents.fwImage.CGImage;
    }
}

@end

#pragma mark - CAGradientLayer+FWQuartzCore

@implementation CAGradientLayer (FWQuartzCore)

- (NSArray<UIColor *> *)fwThemeColors
{
    return objc_getAssociatedObject(self, @selector(fwThemeColors));
}

- (void)setFwThemeColors:(NSArray<UIColor *> *)fwThemeColors
{
    objc_setAssociatedObject(self, @selector(fwThemeColors), fwThemeColors, OBJC_ASSOCIATION_COPY_NONATOMIC);
    
    NSMutableArray *colors = nil;
    if (fwThemeColors != nil) {
        colors = [NSMutableArray new];
        for (UIColor *color in fwThemeColors) {
            [colors addObject:(id)color.CGColor];
        }
    }
    self.colors = colors.copy;
}

- (void)fwThemeChanged:(FWThemeStyle)style
{
    [super fwThemeChanged:style];
    
    if (self.fwThemeColors != nil) {
        NSMutableArray *colors = [NSMutableArray new];
        for (UIColor *color in self.fwThemeColors) {
            [colors addObject:(id)color.CGColor];
        }
        self.colors = colors.copy;
    }
}

@end
