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

@implementation FWObjectWrapper (FWDebugger)

- (NSString *)methodList {
    id methodList = [self invokeGetter:@"_methodDescription"];
    return [methodList isKindOfClass:[NSString class]] ? methodList : @"";
}

- (NSString *)shortMethodList {
    id shortMethodList = [self invokeGetter:@"_shortMethodDescription"];
    return [shortMethodList isKindOfClass:[NSString class]] ? shortMethodList : @"";
}

- (NSString *)ivarList {
    id ivarList = [self invokeGetter:@"_ivarDescription"];
    return [ivarList isKindOfClass:[NSString class]] ? ivarList : @"";
}

@end

@interface FWViewWrapper (FWDebuggerInternal)

- (void)updateDebugColor;

@end

@interface UIView (FWDebugger)

@end

@implementation UIView (FWDebugger)

- (BOOL)innerShowDebugColor {
    return [objc_getAssociatedObject(self, @selector(innerShowDebugColor)) boolValue];
}

- (void)setInnerShowDebugColor:(BOOL)showDebugColor {
    objc_setAssociatedObject(self, @selector(innerShowDebugColor), @(showDebugColor), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self.fw updateDebugColor];
}

- (BOOL)innerRandomDebugColor {
    return [objc_getAssociatedObject(self, @selector(innerRandomDebugColor)) boolValue];
}

- (void)setInnerRandomDebugColor:(BOOL)randomDebugColor {
    objc_setAssociatedObject(self, @selector(innerRandomDebugColor), @(randomDebugColor), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation FWViewWrapper (FWDebugger)

- (NSString *)viewInfo {
    id viewInfo = [self invokeGetter:@"recursiveDescription"];
    return [viewInfo isKindOfClass:[NSString class]] ? viewInfo : @"";
}

- (BOOL)showDebugColor {
    return self.base.innerShowDebugColor;
}

- (void)setShowDebugColor:(BOOL)showDebugColor {
    self.base.innerShowDebugColor = showDebugColor;
}

- (BOOL)randomDebugColor {
    return self.base.innerRandomDebugColor;
}

- (void)setRandomDebugColor:(BOOL)randomDebugColor {
    self.base.innerRandomDebugColor = randomDebugColor;
}

+ (void)swizzleDebugColor {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWSwizzleClass(UIView, @selector(layoutSubviews), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            FWSwizzleOriginal();
            
            if (selfObject.innerShowDebugColor) {
                selfObject.backgroundColor = [selfObject.fw debugColor];
                [selfObject.fw renderDebugColor:selfObject.subviews];
            } else if (objc_getAssociatedObject(selfObject, @selector(innerShowDebugColor))) {
                selfObject.backgroundColor = nil;
                [selfObject.fw renderDebugColor:selfObject.subviews];
            }
        }));
    });
}

- (void)updateDebugColor {
    if (self.showDebugColor) {
        [FWViewWrapper swizzleDebugColor];
    }
    [self.base setNeedsLayout];
}

- (void)renderDebugColor:(NSArray *)subviews {
    for (UIView *view in subviews) {
        if ([view isKindOfClass:[UIStackView class]]) {
            UIStackView *stackView = (UIStackView *)view;
            [self renderDebugColor:stackView.arrangedSubviews];
        }
        view.fw.showDebugColor = self.showDebugColor;
        view.fw.randomDebugColor = self.randomDebugColor;
        if (view.fw.showDebugColor) {
            view.backgroundColor = [view.fw debugColor];
        } else {
            view.backgroundColor = nil;
        }
    }
}

- (UIColor *)debugColor {
    if (self.randomDebugColor) {
        return [UIColor.fw.randomColor colorWithAlphaComponent:0.3];
    } else {
        return [UIColor colorWithRed:1.0 green:0 blue:0 alpha:0.3];
    }
}

@end

@interface FWLabelWrapper (FWDebuggerInternal)

- (void)updatePrincipalLines;

@end

@interface UILabel (FWDebugger)

@end

@implementation UILabel (FWDebugger)

- (BOOL)innerShowPrincipalLines {
    return [objc_getAssociatedObject(self, @selector(innerShowPrincipalLines)) boolValue];
}

- (void)setInnerShowPrincipalLines:(BOOL)showPrincipalLines {
    objc_setAssociatedObject(self, @selector(innerShowPrincipalLines), @(showPrincipalLines), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self.fw updatePrincipalLines];
}

- (UIColor *)innerPrincipalLineColor {
    UIColor *color = objc_getAssociatedObject(self, @selector(innerPrincipalLineColor));
    return color ?: [UIColor colorWithRed:1.0 green:0 blue:0 alpha:0.3];
}

- (void)setInnerPrincipalLineColor:(UIColor *)color {
    objc_setAssociatedObject(self, @selector(innerPrincipalLineColor), color, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation FWLabelWrapper (FWDebugger)

- (BOOL)showPrincipalLines {
    return self.base.innerShowPrincipalLines;
}

- (void)setShowPrincipalLines:(BOOL)showPrincipalLines {
    self.base.innerShowPrincipalLines = showPrincipalLines;
}

- (UIColor *)principalLineColor {
    return self.base.innerPrincipalLineColor;
}

- (void)setPrincipalLineColor:(UIColor *)color {
    self.base.innerPrincipalLineColor = color;
}

- (CAShapeLayer *)principalLineLayer {
    return objc_getAssociatedObject(self.base, @selector(principalLineLayer));
}

- (void)setPrincipalLineLayer:(CAShapeLayer *)layer {
    objc_setAssociatedObject(self.base, @selector(principalLineLayer), layer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (void)swizzlePrincipalLines {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWSwizzleClass(UILabel, @selector(layoutSubviews), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            FWSwizzleOriginal();
            
            UILabel *label = selfObject;
            if (!label.fw.principalLineLayer || label.fw.principalLineLayer.hidden)  return;
            label.fw.principalLineLayer.frame = label.bounds;
            
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
            label.fw.principalLineLayer.path = path.CGPath;
        }));
    });
}

- (void)updatePrincipalLines {
    if (self.showPrincipalLines && !self.principalLineLayer) {
        CAShapeLayer *layer = [CAShapeLayer layer];
        self.principalLineLayer = layer;
        layer.strokeColor = self.principalLineColor.CGColor;
        layer.lineWidth = FWPixelOne;
        [self.base.layer addSublayer:layer];
        
        [FWLabelWrapper swizzlePrincipalLines];
    }
    self.principalLineLayer.hidden = !self.showPrincipalLines;
}

@end
