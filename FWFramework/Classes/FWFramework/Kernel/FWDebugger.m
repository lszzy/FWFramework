//
//  FWDebugger.m
//  FWFramework
//
//  Created by wuyong on 2022/4/24.
//

#import "FWDebugger.h"
#import "FWAdaptive.h"
#import "FWSwizzle.h"
#import "FWToolkit.h"
#import <objc/runtime.h>

@implementation NSObject (FWDebugger)

- (NSString *)fw_methodList {
    id methodList = [self.fw invokeGetter:@"_methodDescription"];
    return [methodList isKindOfClass:[NSString class]] ? methodList : @"";
}

- (NSString *)fw_shortMethodList {
    id shortMethodList = [self.fw invokeGetter:@"_shortMethodDescription"];
    return [shortMethodList isKindOfClass:[NSString class]] ? shortMethodList : @"";
}

- (NSString *)fw_ivarList {
    id ivarList = [self.fw invokeGetter:@"_ivarDescription"];
    return [ivarList isKindOfClass:[NSString class]] ? ivarList : @"";
}

@end

@implementation UIView (FWDebugger)

- (NSString *)fw_viewInfo {
    id viewInfo = [self.fw invokeGetter:@"recursiveDescription"];
    return [viewInfo isKindOfClass:[NSString class]] ? viewInfo : @"";
}

- (BOOL)fw_showDebugColor {
    return self.fw_innerShowDebugColor;
}

- (void)setFw_showDebugColor:(BOOL)showDebugColor {
    self.fw_innerShowDebugColor = showDebugColor;
}

- (BOOL)fw_randomDebugColor {
    return self.fw_innerRandomDebugColor;
}

- (void)setFw_randomDebugColor:(BOOL)randomDebugColor {
    self.fw_innerRandomDebugColor = randomDebugColor;
}

- (BOOL)fw_showDebugBorder {
    return self.fw_innerShowDebugBorder;
}

- (void)setFw_showDebugBorder:(BOOL)showDebugBorder {
    self.fw_innerShowDebugBorder = showDebugBorder;
}

- (UIColor *)fw_debugBorderColor {
    return self.fw_innerDebugBorderColor;
}

- (void)setFw_debugBorderColor:(UIColor *)debugBorderColor {
    self.fw_innerDebugBorderColor = debugBorderColor;
}

+ (void)fw_swizzleDebugColor {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWSwizzleClass(UIView, @selector(layoutSubviews), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            FWSwizzleOriginal();
            
            if (selfObject.fw_innerShowDebugColor) {
                selfObject.backgroundColor = [selfObject fw_debugColor];
                [selfObject fw_renderDebugColor:selfObject.subviews];
            } else if (objc_getAssociatedObject(selfObject, @selector(fw_innerShowDebugColor))) {
                selfObject.backgroundColor = nil;
                [selfObject fw_renderDebugColor:selfObject.subviews];
            }
        }));
    });
}

- (void)fw_updateDebugColor {
    if (self.fw_showDebugColor) {
        [UIView fw_swizzleDebugColor];
    }
    [self setNeedsLayout];
}

- (void)fw_renderDebugColor:(NSArray *)subviews {
    for (UIView *view in subviews) {
        if ([view isKindOfClass:[UIStackView class]]) {
            UIStackView *stackView = (UIStackView *)view;
            [self fw_renderDebugColor:stackView.arrangedSubviews];
        }
        view.fw_showDebugColor = self.fw_showDebugColor;
        view.fw_randomDebugColor = self.fw_randomDebugColor;
        if (view.fw_showDebugColor) {
            view.backgroundColor = [view fw_debugColor];
        } else {
            view.backgroundColor = nil;
        }
    }
}

- (UIColor *)fw_debugColor {
    if (self.fw_randomDebugColor) {
        return [UIColor.fw.randomColor colorWithAlphaComponent:0.3];
    } else {
        return [UIColor colorWithRed:1.0 green:0 blue:0 alpha:0.3];
    }
}

+ (void)fw_swizzleDebugBorder {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWSwizzleClass(UIView, @selector(layoutSubviews), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            FWSwizzleOriginal();
            
            if (selfObject.fw_innerShowDebugBorder) {
                selfObject.layer.borderWidth = FWPixelOne;
                selfObject.layer.borderColor = selfObject.fw_innerDebugBorderColor.CGColor;
                [selfObject fw_renderDebugBorder:selfObject.subviews];
            } else if (objc_getAssociatedObject(selfObject, @selector(fw_innerShowDebugBorder))) {
                selfObject.layer.borderWidth = 0;
                selfObject.layer.borderColor = nil;
                [selfObject fw_renderDebugBorder:selfObject.subviews];
            }
        }));
    });
}

- (void)fw_updateDebugBorder {
    if (self.fw_showDebugBorder) {
        [UIView fw_swizzleDebugBorder];
    }
    [self setNeedsLayout];
}

- (void)fw_renderDebugBorder:(NSArray *)subviews {
    for (UIView *view in subviews) {
        if ([view isKindOfClass:[UIStackView class]]) {
            UIStackView *stackView = (UIStackView *)view;
            [self fw_renderDebugBorder:stackView.arrangedSubviews];
        }
        view.fw_showDebugBorder = self.fw_showDebugBorder;
        view.fw_debugBorderColor = self.fw_debugBorderColor;
        if (view.fw_showDebugBorder) {
            view.layer.borderWidth = FWPixelOne;
            view.layer.borderColor = view.fw_debugBorderColor.CGColor;
        } else {
            view.layer.borderWidth = 0;
            view.layer.borderColor = nil;
        }
    }
}

- (BOOL)fw_innerShowDebugColor {
    return [objc_getAssociatedObject(self, @selector(fw_innerShowDebugColor)) boolValue];
}

- (void)setFw_innerShowDebugColor:(BOOL)showDebugColor {
    objc_setAssociatedObject(self, @selector(fw_innerShowDebugColor), @(showDebugColor), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self fw_updateDebugColor];
}

- (BOOL)fw_innerRandomDebugColor {
    return [objc_getAssociatedObject(self, @selector(fw_innerRandomDebugColor)) boolValue];
}

- (void)setFw_innerRandomDebugColor:(BOOL)randomDebugColor {
    objc_setAssociatedObject(self, @selector(fw_innerRandomDebugColor), @(randomDebugColor), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)fw_innerShowDebugBorder {
    return [objc_getAssociatedObject(self, @selector(fw_innerShowDebugBorder)) boolValue];
}

- (void)setFw_innerShowDebugBorder:(BOOL)showDebugBorder {
    objc_setAssociatedObject(self, @selector(fw_innerShowDebugBorder), @(showDebugBorder), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self fw_updateDebugBorder];
}

- (UIColor *)fw_innerDebugBorderColor {
    UIColor *color = objc_getAssociatedObject(self, @selector(fw_innerDebugBorderColor));
    return color ?: [UIColor colorWithRed:1.0 green:0 blue:0 alpha:0.3];
}

- (void)setFw_innerDebugBorderColor:(UIColor *)color {
    objc_setAssociatedObject(self, @selector(fw_innerDebugBorderColor), color, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation UILabel (FWDebugger)

- (BOOL)fw_showPrincipalLines {
    return self.fw_innerShowPrincipalLines;
}

- (void)setFw_showPrincipalLines:(BOOL)showPrincipalLines {
    self.fw_innerShowPrincipalLines = showPrincipalLines;
}

- (UIColor *)fw_principalLineColor {
    return self.fw_innerPrincipalLineColor;
}

- (void)setFw_principalLineColor:(UIColor *)color {
    self.fw_innerPrincipalLineColor = color;
}

- (CAShapeLayer *)fw_principalLineLayer {
    return objc_getAssociatedObject(self, @selector(fw_principalLineLayer));
}

- (void)setFw_principalLineLayer:(CAShapeLayer *)layer {
    objc_setAssociatedObject(self, @selector(fw_principalLineLayer), layer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (void)fw_swizzlePrincipalLines {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWSwizzleClass(UILabel, @selector(layoutSubviews), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            FWSwizzleOriginal();
            
            UILabel *label = selfObject;
            if (!label.fw_principalLineLayer || label.fw_principalLineLayer.hidden)  return;
            label.fw_principalLineLayer.frame = label.bounds;
            
            NSRange range = NSMakeRange(0, label.attributedText.length);
            CGFloat baselineOffset = [[label.attributedText attribute:NSBaselineOffsetAttributeName atIndex:0 effectiveRange:&range] doubleValue];
            CGFloat lineOffset = baselineOffset * 2;
            UIFont *font = label.font;
            CGFloat maxX = CGRectGetWidth(label.bounds);
            CGFloat maxY = CGRectGetHeight(label.bounds);
            CGFloat descenderY = maxY + font.descender - lineOffset;
            CGFloat xHeightY = maxY - (font.xHeight - font.descender) - lineOffset;
            CGFloat capHeightY = maxY - (font.capHeight - font.descender) - lineOffset;
            CGFloat lineHeightY = maxY - font.lineHeight - lineOffset;
            
            void (^addLineAtY)(UIBezierPath *, CGFloat) = ^void(UIBezierPath *p, CGFloat y) {
                CGFloat offset = FWPixelOne / 2;
                y = FWFlatValue(y) - offset;
                [p moveToPoint:CGPointMake(0, y)];
                [p addLineToPoint:CGPointMake(maxX, y)];
            };
            UIBezierPath *path = [UIBezierPath bezierPath];
            addLineAtY(path, descenderY);
            addLineAtY(path, xHeightY);
            addLineAtY(path, capHeightY);
            addLineAtY(path, lineHeightY);
            label.fw_principalLineLayer.path = path.CGPath;
        }));
    });
}

- (void)fw_updatePrincipalLines {
    if (self.fw_showPrincipalLines && !self.fw_principalLineLayer) {
        CAShapeLayer *layer = [CAShapeLayer layer];
        self.fw_principalLineLayer = layer;
        layer.strokeColor = self.fw_principalLineColor.CGColor;
        layer.lineWidth = FWPixelOne;
        [self.layer addSublayer:layer];
        
        [UILabel fw_swizzlePrincipalLines];
    }
    self.fw_principalLineLayer.hidden = !self.fw_showPrincipalLines;
}

- (BOOL)fw_innerShowPrincipalLines {
    return [objc_getAssociatedObject(self, @selector(fw_innerShowPrincipalLines)) boolValue];
}

- (void)setFw_innerShowPrincipalLines:(BOOL)showPrincipalLines {
    objc_setAssociatedObject(self, @selector(fw_innerShowPrincipalLines), @(showPrincipalLines), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self fw_updatePrincipalLines];
}

- (UIColor *)fw_innerPrincipalLineColor {
    UIColor *color = objc_getAssociatedObject(self, @selector(fw_innerPrincipalLineColor));
    return color ?: [UIColor colorWithRed:1.0 green:0 blue:0 alpha:0.3];
}

- (void)setFw_innerPrincipalLineColor:(UIColor *)color {
    objc_setAssociatedObject(self, @selector(fw_innerPrincipalLineColor), color, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
