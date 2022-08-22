//
//  FWQuartzCore.m
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import "FWQuartzCore.h"
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

@end
