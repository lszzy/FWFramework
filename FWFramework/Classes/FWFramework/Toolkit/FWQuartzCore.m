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

@implementation FWAnimationWrapper (FWQuartzCore)

- (FWInnerAnimationTarget *)innerAnimationTarget:(BOOL)lazyload
{
    FWInnerAnimationTarget *target = objc_getAssociatedObject(self.base, _cmd);
    if (!target && lazyload) {
        target = [[FWInnerAnimationTarget alloc] init];
        objc_setAssociatedObject(self.base, _cmd, target, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return target;
}

- (void (^)(CAAnimation * _Nonnull))startBlock
{
    FWInnerAnimationTarget *target = [self innerAnimationTarget:NO];
    return target.startBlock;
}

- (void)setStartBlock:(void (^)(CAAnimation * _Nonnull))startBlock
{
    FWInnerAnimationTarget *target = [self innerAnimationTarget:YES];
    target.startBlock = startBlock;
    self.base.delegate = target;
}

- (void (^)(CAAnimation * _Nonnull, BOOL))stopBlock
{
    FWInnerAnimationTarget *target = [self innerAnimationTarget:NO];
    return target.stopBlock;
}

- (void)setStopBlock:(void (^)(CAAnimation * _Nonnull, BOOL))stopBlock
{
    FWInnerAnimationTarget *target = [self innerAnimationTarget:YES];
    target.stopBlock = stopBlock;
    self.base.delegate = target;
}

@end

#pragma mark - FWLayerWrapper+FWQuartzCore

@implementation FWLayerWrapper (FWQuartzCore)

- (UIColor *)themeBackgroundColor
{
    return objc_getAssociatedObject(self.base, @selector(themeBackgroundColor));
}

- (void)setThemeBackgroundColor:(UIColor *)themeBackgroundColor
{
    objc_setAssociatedObject(self.base, @selector(themeBackgroundColor), themeBackgroundColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.base.backgroundColor = themeBackgroundColor.CGColor;
}

- (UIColor *)themeBorderColor
{
    return objc_getAssociatedObject(self.base, @selector(themeBorderColor));
}

- (void)setThemeBorderColor:(UIColor *)themeBorderColor
{
    objc_setAssociatedObject(self.base, @selector(themeBorderColor), themeBorderColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.base.borderColor = themeBorderColor.CGColor;
}

- (UIColor *)themeShadowColor
{
    return objc_getAssociatedObject(self.base, @selector(themeShadowColor));
}

- (void)setThemeShadowColor:(UIColor *)themeShadowColor
{
    objc_setAssociatedObject(self.base, @selector(themeShadowColor), themeShadowColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.base.shadowColor = themeShadowColor.CGColor;
}

- (UIImage *)themeContents
{
    return objc_getAssociatedObject(self.base, @selector(themeContents));
}

- (void)setThemeContents:(UIImage *)themeContents
{
    objc_setAssociatedObject(self.base, @selector(themeContents), themeContents, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.base.contents = (id)themeContents.fw.image.CGImage;
}

- (void)themeChanged:(FWThemeStyle)style
{
    [super themeChanged:style];
    
    if (self.themeBackgroundColor != nil) {
        self.base.backgroundColor = self.themeBackgroundColor.CGColor;
    }
    if (self.themeBorderColor != nil) {
        self.base.borderColor = self.themeBorderColor.CGColor;
    }
    if (self.themeShadowColor != nil) {
        self.base.shadowColor = self.themeShadowColor.CGColor;
    }
    if (self.themeContents && self.themeContents.fw.isThemeImage) {
        self.base.contents = (id)self.themeContents.fw.image.CGImage;
    }
}

@end

#pragma mark - FWGradientLayerWrapper+FWQuartzCore

@implementation FWGradientLayerWrapper (FWQuartzCore)

- (NSArray<UIColor *> *)themeColors
{
    return objc_getAssociatedObject(self.base, @selector(themeColors));
}

- (void)setThemeColors:(NSArray<UIColor *> *)themeColors
{
    objc_setAssociatedObject(self.base, @selector(themeColors), themeColors, OBJC_ASSOCIATION_COPY_NONATOMIC);
    
    NSMutableArray *colors = nil;
    if (themeColors != nil) {
        colors = [NSMutableArray new];
        for (UIColor *color in themeColors) {
            [colors addObject:(id)color.CGColor];
        }
    }
    self.base.colors = colors.copy;
}

- (void)themeChanged:(FWThemeStyle)style
{
    [super themeChanged:style];
    
    if (self.themeColors != nil) {
        NSMutableArray *colors = [NSMutableArray new];
        for (UIColor *color in self.themeColors) {
            [colors addObject:(id)color.CGColor];
        }
        self.base.colors = colors.copy;
    }
}

@end
