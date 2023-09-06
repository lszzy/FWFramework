//
//  FWUIKit.m
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import "FWUIKit.h"
#import "FWAdaptive.h"
#import "FWAutoLayout.h"
#import "FWBlock.h"
#import "FWFoundation.h"
#import "FWRuntime.h"
#import "FWSwizzle.h"
#import "FWToolkit.h"
#import "FWEncode.h"
#import "FWMessage.h"
#import <objc/runtime.h>
#import <sys/sysctl.h>
#import <CoreImage/CoreImage.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <net/if.h>

#if FWMacroTracking
@import AdSupport;
#endif

#pragma mark - UIBezierPath+FWUIKit

@implementation UIBezierPath (FWUIKit)

- (UIImage *)fw_shapeImage:(CGSize)size
              strokeWidth:(CGFloat)strokeWidth
              strokeColor:(UIColor *)strokeColor
                fillColor:(UIColor *)fillColor
{
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context) return nil;
    
    CGContextSetLineWidth(context, strokeWidth);
    CGContextSetLineCap(context, kCGLineCapRound);
    [strokeColor setStroke];
    CGContextAddPath(context, self.CGPath);
    CGContextStrokePath(context);
    
    if (fillColor) {
        [fillColor setFill];
        CGContextAddPath(context, self.CGPath);
        CGContextFillPath(context);
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (CAShapeLayer *)fw_shapeLayer:(CGRect)rect
                   strokeWidth:(CGFloat)strokeWidth
                   strokeColor:(UIColor *)strokeColor
                     fillColor:(UIColor *)fillColor
{
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.frame = rect;
    layer.lineWidth = strokeWidth;
    layer.lineCap = kCALineCapRound;
    layer.strokeColor = strokeColor.CGColor;
    if (fillColor) {
        layer.fillColor = fillColor.CGColor;
    }
    layer.path = self.CGPath;
    return layer;
}

+ (UIBezierPath *)fw_linesWithPoints:(NSArray *)points
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    NSValue *value = points[0];
    CGPoint p1 = [value CGPointValue];
    [path moveToPoint:p1];
    
    for (NSUInteger i = 1; i < points.count; i++) {
        value = points[i];
        CGPoint p2 = [value CGPointValue];
        [path addLineToPoint:p2];
    }
    return path;
}

+ (UIBezierPath *)fw_quadCurvedPathWithPoints:(NSArray *)points
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    NSValue *value = points[0];
    CGPoint p1 = [value CGPointValue];
    [path moveToPoint:p1];
    
    if (points.count == 2) {
        value = points[1];
        CGPoint p2 = [value CGPointValue];
        [path addLineToPoint:p2];
        return path;
    }
    
    for (NSUInteger i = 1; i < points.count; i++) {
        value = points[i];
        CGPoint p2 = [value CGPointValue];
        
        CGPoint midPoint = [self fw_middlePoint:p1 withPoint:p2];
        [path addQuadCurveToPoint:midPoint controlPoint:[self fw_controlPoint:midPoint withPoint:p1]];
        [path addQuadCurveToPoint:p2 controlPoint:[self fw_controlPoint:midPoint withPoint:p2]];
        
        p1 = p2;
    }
    return path;
}

+ (CGPoint)fw_middlePoint:(CGPoint)p1 withPoint:(CGPoint)p2
{
    return CGPointMake((p1.x + p2.x) / 2, (p1.y + p2.y) / 2);
}

+ (CGPoint)fw_controlPoint:(CGPoint)p1 withPoint:(CGPoint)p2
{
    CGPoint controlPoint = [self fw_middlePoint:p1 withPoint:p2];
    CGFloat diffY = fabs(p2.y - controlPoint.y);
    
    if (p1.y < p2.y)
        controlPoint.y += diffY;
    else if (p1.y > p2.y)
        controlPoint.y -= diffY;
    
    return controlPoint;
}

+ (CGFloat)fw_radianWithDegree:(CGFloat)degree
{
    return (M_PI * degree) / 180.f;
}

+ (CGFloat)fw_degreeWithRadian:(CGFloat)radian
{
    return (180.f * radian) / M_PI;
}

+ (NSArray<NSValue *> *)fw_linePointsWithRect:(CGRect)rect direction:(UISwipeGestureRecognizerDirection)direction
{
    CGPoint startPoint;
    CGPoint endPoint;
    switch (direction) {
        // 从左到右
        case UISwipeGestureRecognizerDirectionRight: {
            startPoint = CGPointMake(CGRectGetMinX(rect), CGRectGetMidY(rect));
            endPoint = CGPointMake(CGRectGetMaxX(rect), CGRectGetMidY(rect));
            break;
        }
        // 从下到上
        case UISwipeGestureRecognizerDirectionUp: {
            startPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));
            endPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect));
            break;
        }
        // 从右到左
        case UISwipeGestureRecognizerDirectionLeft: {
            startPoint = CGPointMake(CGRectGetMaxX(rect), CGRectGetMidY(rect));
            endPoint = CGPointMake(CGRectGetMinX(rect), CGRectGetMidY(rect));
            break;
        }
        // 从上到下
        case UISwipeGestureRecognizerDirectionDown:
        default: {
            startPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect));
            endPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));
            break;
        }
    }
    return [NSArray arrayWithObjects:[NSValue valueWithCGPoint:startPoint], [NSValue valueWithCGPoint:endPoint], nil];
}

@end

#pragma mark - UIDevice+FWUIKit

@implementation UIDevice (FWUIKit)

+ (void)fw_setDeviceTokenData:(NSData *)tokenData
{
    if (tokenData) {
        NSMutableString *deviceToken = [NSMutableString string];
        const char *bytes = tokenData.bytes;
        NSInteger count = tokenData.length;
        for (int i = 0; i < count; i++) {
            [deviceToken appendFormat:@"%02x", bytes[i] & 0x000000FF];
        }
        self.fw_deviceToken = [deviceToken copy];
    } else {
        self.fw_deviceToken = nil;
    }
}

+ (NSString *)fw_deviceToken
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"FWDeviceToken"];
}

+ (void)setFw_deviceToken:(NSString *)deviceToken
{
    if (deviceToken) {
        [[NSUserDefaults standardUserDefaults] setObject:deviceToken forKey:@"FWDeviceToken"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FWDeviceToken"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

+ (NSString *)fw_deviceModel
{
#if TARGET_OS_SIMULATOR
    return [NSString stringWithFormat:@"%s", getenv("SIMULATOR_MODEL_IDENTIFIER")];
#else
    static NSString *model;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        size_t size;
        sysctlbyname("hw.machine", NULL, &size, NULL, 0);
        char *machine = malloc(size);
        sysctlbyname("hw.machine", machine, &size, NULL, 0);
        model = [NSString stringWithUTF8String:machine];
        free(machine);
    });
    return model;
#endif
}

+ (NSString *)fw_deviceIDFV
{
    return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
}

+ (NSString *)fw_deviceIDFA
{
    #if FWMacroTracking
    return ASIdentifierManager.sharedManager.advertisingIdentifier.UUIDString;
    #else
    return nil;
    #endif
}

+ (BOOL)fw_isJailbroken
{
#if TARGET_OS_SIMULATOR
    return NO;
#else
    // 1
    NSArray *paths = @[@"/Applications/Cydia.app",
                       @"/private/var/lib/apt/",
                       @"/private/var/lib/cydia",
                       @"/private/var/stash"];
    for (NSString *path in paths) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            return YES;
        }
    }
    
    // 2
    FILE *bash = fopen("/bin/bash", "r");
    if (bash != NULL) {
        fclose(bash);
        return YES;
    }
    
    // 3
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, uuid);
    CFRelease(uuid);
    NSString *uuidString = (__bridge_transfer NSString *)string;
    NSString *path = [NSString stringWithFormat:@"/private/%@", uuidString];
    if ([@"test" writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:NULL]) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        return YES;
    }
    
    return NO;
#endif
}

+ (NSString *)fw_ipAddress
{
    NSString *ipAddr = nil;
    struct ifaddrs *addrs = NULL;
    
    int ret = getifaddrs(&addrs);
    if (0 == ret) {
        const struct ifaddrs * cursor = addrs;
        
        while (cursor) {
            if (AF_INET == cursor->ifa_addr->sa_family && 0 == (cursor->ifa_flags & IFF_LOOPBACK)) {
                ipAddr = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)cursor->ifa_addr)->sin_addr)];
                break;
            }
            
            cursor = cursor->ifa_next;
        }
        
        freeifaddrs(addrs);
    }
    
    return ipAddr;
}

+ (NSString *)fw_hostName
{
    char hostName[256];
    int success = gethostname(hostName, 255);
    if (success != 0) return nil;
    hostName[255] = '\0';
    
#if TARGET_OS_SIMULATOR
    return [NSString stringWithFormat:@"%s", hostName];
#else
    return [NSString stringWithFormat:@"%s.local", hostName];
#endif
}

+ (CTTelephonyNetworkInfo *)fw_networkInfo
{
    static CTTelephonyNetworkInfo *networkInfo = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        networkInfo = [[CTTelephonyNetworkInfo alloc] init];
    });
    return networkInfo;
}

+ (NSString *)fw_carrierName
{
    return [self fw_networkInfo].subscriberCellularProvider.carrierName;
}

+ (NSString *)fw_networkType
{
    NSString *networkType = nil;
    NSString *accessTechnology = [self fw_networkInfo].currentRadioAccessTechnology;
    if (!accessTechnology) return networkType;
    
    NSArray *types2G = @[CTRadioAccessTechnologyGPRS,
                         CTRadioAccessTechnologyEdge,
                         CTRadioAccessTechnologyCDMA1x];
    NSArray *types3G = @[CTRadioAccessTechnologyWCDMA,
                         CTRadioAccessTechnologyHSDPA,
                         CTRadioAccessTechnologyHSUPA,
                         CTRadioAccessTechnologyCDMAEVDORev0,
                         CTRadioAccessTechnologyCDMAEVDORevA,
                         CTRadioAccessTechnologyCDMAEVDORevB,
                         CTRadioAccessTechnologyeHRPD];
    NSArray *types4G = @[CTRadioAccessTechnologyLTE];
    NSArray *types5G = nil;
    if (@available(iOS 14.1, *)) {
        types5G = @[CTRadioAccessTechnologyNRNSA, CTRadioAccessTechnologyNR];
    }
    
    if ([types5G containsObject:accessTechnology]) {
        networkType = @"5G";
    } else if ([types4G containsObject:accessTechnology]) {
        networkType = @"4G";
    } else if ([types3G containsObject:accessTechnology]) {
        networkType = @"3G";
    } else if ([types2G containsObject:accessTechnology]) {
        networkType = @"2G";
    }
    return networkType;
}

@end

#pragma mark - UIView+FWUIKit

static void *kUIViewFWBorderLayerTopKey = &kUIViewFWBorderLayerTopKey;
static void *kUIViewFWBorderLayerLeftKey = &kUIViewFWBorderLayerLeftKey;
static void *kUIViewFWBorderLayerBottomKey = &kUIViewFWBorderLayerBottomKey;
static void *kUIViewFWBorderLayerRightKey = &kUIViewFWBorderLayerRightKey;

static void *kUIViewFWBorderLayerCornerKey = &kUIViewFWBorderLayerCornerKey;

static void *kUIViewFWBorderViewTopKey = &kUIViewFWBorderViewTopKey;
static void *kUIViewFWBorderViewLeftKey = &kUIViewFWBorderViewLeftKey;
static void *kUIViewFWBorderViewBottomKey = &kUIViewFWBorderViewBottomKey;
static void *kUIViewFWBorderViewRightKey = &kUIViewFWBorderViewRightKey;

@implementation UIView (FWUIKit)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWSwizzleClass(UIView, @selector(pointInside:withEvent:), FWSwizzleReturn(BOOL), FWSwizzleArgs(CGPoint point, UIEvent *event), FWSwizzleCode({
            NSValue *insetsValue = objc_getAssociatedObject(selfObject, @selector(fw_touchInsets));
            if (insetsValue) {
                UIEdgeInsets touchInsets = [insetsValue UIEdgeInsetsValue];
                CGRect bounds = selfObject.bounds;
                bounds = CGRectMake(bounds.origin.x - touchInsets.left,
                                    bounds.origin.y - touchInsets.top,
                                    bounds.size.width + touchInsets.left + touchInsets.right,
                                    bounds.size.height + touchInsets.top + touchInsets.bottom);
                return CGRectContainsPoint(bounds, point);
            }
            
            return FWSwizzleOriginal(point, event);
        }));
        
        FWSwizzleClass(UILabel, @selector(drawTextInRect:), FWSwizzleReturn(void), FWSwizzleArgs(CGRect rect), FWSwizzleCode({
            NSValue *contentInsetValue = objc_getAssociatedObject(selfObject, @selector(fw_contentInset));
            if (contentInsetValue) {
                rect = UIEdgeInsetsInsetRect(rect, [contentInsetValue UIEdgeInsetsValue]);
            }
            
            UIControlContentVerticalAlignment verticalAlignment = [objc_getAssociatedObject(selfObject, @selector(fw_verticalAlignment)) integerValue];
            if (verticalAlignment == UIControlContentVerticalAlignmentTop) {
                CGSize fitsSize = [selfObject sizeThatFits:rect.size];
                rect = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, fitsSize.height);
            } else if (verticalAlignment == UIControlContentVerticalAlignmentBottom) {
                CGSize fitsSize = [selfObject sizeThatFits:rect.size];
                rect = CGRectMake(rect.origin.x, rect.origin.y + (rect.size.height - fitsSize.height), rect.size.width, fitsSize.height);
            }
            
            FWSwizzleOriginal(rect);
        }));
        
        FWSwizzleClass(UILabel, @selector(intrinsicContentSize), FWSwizzleReturn(CGSize), FWSwizzleArgs(), FWSwizzleCode({
            CGSize size = FWSwizzleOriginal();
            NSValue *contentInsetValue = objc_getAssociatedObject(selfObject, @selector(fw_contentInset));
            if (contentInsetValue && !CGSizeEqualToSize(size, CGSizeZero)) {
                UIEdgeInsets contentInset = [contentInsetValue UIEdgeInsetsValue];
                size = CGSizeMake(size.width + contentInset.left + contentInset.right, size.height + contentInset.top + contentInset.bottom);
            }
            return size;
        }));
        
        FWSwizzleClass(UILabel, @selector(sizeThatFits:), FWSwizzleReturn(CGSize), FWSwizzleArgs(CGSize size), FWSwizzleCode({
            NSValue *contentInsetValue = objc_getAssociatedObject(selfObject, @selector(fw_contentInset));
            if (contentInsetValue) {
                UIEdgeInsets contentInset = [contentInsetValue UIEdgeInsetsValue];
                size = CGSizeMake(size.width - contentInset.left - contentInset.right, size.height - contentInset.top - contentInset.bottom);
                CGSize fitsSize = FWSwizzleOriginal(size);
                if (!CGSizeEqualToSize(fitsSize, CGSizeZero)) {
                    fitsSize = CGSizeMake(fitsSize.width + contentInset.left + contentInset.right, fitsSize.height + contentInset.top + contentInset.bottom);
                }
                return fitsSize;
            }
            
            return FWSwizzleOriginal(size);
        }));
        
        FWSwizzleClass(UIButton, @selector(setEnabled:), FWSwizzleReturn(void), FWSwizzleArgs(BOOL enabled), FWSwizzleCode({
            FWSwizzleOriginal(enabled);
            
            if (selfObject.fw_disabledAlpha > 0) {
                selfObject.alpha = enabled ? 1 : selfObject.fw_disabledAlpha;
            }
            if (selfObject.fw_disabledChanged) {
                selfObject.fw_disabledChanged(selfObject, enabled);
            }
        }));
        
        FWSwizzleClass(UIButton, @selector(setHighlighted:), FWSwizzleReturn(void), FWSwizzleArgs(BOOL highlighted), FWSwizzleCode({
            FWSwizzleOriginal(highlighted);
            
            if (selfObject.enabled && selfObject.fw_highlightedAlpha > 0) {
                selfObject.alpha = highlighted ? selfObject.fw_highlightedAlpha : 1;
            }
            if (selfObject.enabled && selfObject.fw_highlightedChanged) {
                selfObject.fw_highlightedChanged(selfObject, highlighted);
            }
        }));
    });
}

- (BOOL)fw_isViewVisible
{
    if (self.hidden || self.alpha <= 0.01 || !self.window) return NO;
    if (self.bounds.size.width == 0 || self.bounds.size.height == 0) return NO;
    return YES;
}

- (UIViewController *)fw_viewController
{
    UIResponder *responder = [self nextResponder];
    while (responder) {
        if ([responder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)responder;
        }
        responder = [responder nextResponder];
    }
    return nil;
}

- (UIEdgeInsets)fw_touchInsets
{
    return [objc_getAssociatedObject(self, @selector(fw_touchInsets)) UIEdgeInsetsValue];
}

- (void)setFw_touchInsets:(UIEdgeInsets)touchInsets
{
    objc_setAssociatedObject(self, @selector(fw_touchInsets), [NSValue valueWithUIEdgeInsets:touchInsets], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGRect)fw_fitFrame
{
    return self.frame;
}

- (void)setFw_fitFrame:(CGRect)fitFrame
{
    fitFrame.size = [self fw_fitSizeWithDrawSize:CGSizeMake(fitFrame.size.width, CGFLOAT_MAX)];
    self.frame = fitFrame;
}

- (CGSize)fw_fitSize
{
    if (CGSizeEqualToSize(self.frame.size, CGSizeZero)) {
        [self setNeedsLayout];
        [self layoutIfNeeded];
    }
    
    CGSize drawSize = CGSizeMake(self.frame.size.width, CGFLOAT_MAX);
    return [self fw_fitSizeWithDrawSize:drawSize];
}

- (CGSize)fw_fitSizeWithDrawSize:(CGSize)drawSize
{
    CGSize size = [self sizeThatFits:drawSize];
    return CGSizeMake(MIN(drawSize.width, ceilf(size.width)), MIN(drawSize.height, ceilf(size.height)));
}

- (__kindof UIView *)fw_subviewWithTag:(NSInteger)tag
{
    __block UIView *subview = nil;
    [self.subviews enumerateObjectsUsingBlock:^(__kindof UIView *obj, NSUInteger idx, BOOL *stop) {
        if (obj.tag == tag) {
            subview = obj;
            *stop = YES;
        }
    }];
    return subview;
}

- (void)fw_setShadowColor:(UIColor *)color
                  offset:(CGSize)offset
                  radius:(CGFloat)radius
{
    self.layer.shadowColor = color.CGColor;
    self.layer.shadowOffset = offset;
    self.layer.shadowRadius = radius;
    self.layer.shadowOpacity = 1.0;
}

- (void)fw_setBorderColor:(UIColor *)color width:(CGFloat)width
{
    self.layer.borderColor = color.CGColor;
    self.layer.borderWidth = width;
}

- (void)fw_setBorderColor:(UIColor *)color width:(CGFloat)width cornerRadius:(CGFloat)radius
{
    [self fw_setBorderColor:color width:width];
    [self fw_setCornerRadius:radius];
}

- (void)fw_setCornerRadius:(CGFloat)radius
{
    self.layer.cornerRadius = radius;
    self.layer.masksToBounds = YES;
}

- (void)fw_setBorderLayer:(UIRectEdge)edge color:(UIColor *)color width:(CGFloat)width
{
    [self fw_setBorderLayer:edge color:color width:width leftInset:0 rightInset:0];
}

- (void)fw_setBorderLayer:(UIRectEdge)edge color:(UIColor *)color width:(CGFloat)width leftInset:(CGFloat)leftInset rightInset:(CGFloat)rightInset
{
    CALayer *borderLayer;
    
    if ((edge & UIRectEdgeTop) == UIRectEdgeTop) {
        borderLayer = [self fw_innerBorderLayer:kUIViewFWBorderLayerTopKey edge:UIRectEdgeTop];
        borderLayer.frame = CGRectMake(leftInset, 0, self.bounds.size.width - leftInset - rightInset, width);
        borderLayer.backgroundColor = color.CGColor;
    }
    
    if ((edge & UIRectEdgeLeft) == UIRectEdgeLeft) {
        borderLayer = [self fw_innerBorderLayer:kUIViewFWBorderLayerLeftKey edge:UIRectEdgeLeft];
        borderLayer.frame = CGRectMake(0, leftInset, width, self.bounds.size.height - leftInset - rightInset);
        borderLayer.backgroundColor = color.CGColor;
    }
    
    if ((edge & UIRectEdgeBottom) == UIRectEdgeBottom) {
        borderLayer = [self fw_innerBorderLayer:kUIViewFWBorderLayerBottomKey edge:UIRectEdgeBottom];
        borderLayer.frame = CGRectMake(leftInset, self.bounds.size.height - width, self.bounds.size.width - leftInset - rightInset, width);
        borderLayer.backgroundColor = color.CGColor;
    }
    
    if ((edge & UIRectEdgeRight) == UIRectEdgeRight) {
        borderLayer = [self fw_innerBorderLayer:kUIViewFWBorderLayerRightKey edge:UIRectEdgeRight];
        borderLayer.frame = CGRectMake(self.bounds.size.width - width, leftInset, width, self.bounds.size.height - leftInset - rightInset);
        borderLayer.backgroundColor = color.CGColor;
    }
}

- (CALayer *)fw_innerBorderLayer:(const void *)edgeKey edge:(UIRectEdge)edge
{
    CALayer *borderLayer = objc_getAssociatedObject(self, edgeKey);
    if (!borderLayer) {
        borderLayer = [CALayer layer];
        [self.layer addSublayer:borderLayer];
        objc_setAssociatedObject(self, edgeKey, borderLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return borderLayer;
}

- (void)fw_setDashBorderLayer:(UIColor *)color width:(CGFloat)width cornerRadius:(CGFloat)radius lineLength:(CGFloat)lineLength lineSpacing:(CGFloat)lineSpacing
{
    CAShapeLayer *borderLayer = objc_getAssociatedObject(self, _cmd);
    if (!borderLayer) {
        borderLayer = [CAShapeLayer layer];
        [self.layer addSublayer:borderLayer];
        objc_setAssociatedObject(self, _cmd, borderLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    borderLayer.frame = self.bounds;
    borderLayer.fillColor = [UIColor clearColor].CGColor;
    borderLayer.strokeColor = color.CGColor;
    borderLayer.lineWidth = width;
    borderLayer.lineJoin = kCALineJoinRound;
    borderLayer.lineDashPattern = @[@(lineLength), @(lineSpacing)];
    borderLayer.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    borderLayer.path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(width / 2.0, width / 2.0, MAX(0, CGRectGetWidth(self.bounds) - width), MAX(0, CGRectGetHeight(self.bounds) - width)) cornerRadius:radius].CGPath;
}

- (void)fw_setCornerLayer:(UIRectCorner)corner radius:(CGFloat)radius
{
    CAShapeLayer *cornerLayer = [CAShapeLayer layer];
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:self.bounds byRoundingCorners:corner cornerRadii:CGSizeMake(radius, radius)];
    cornerLayer.frame = self.bounds;
    cornerLayer.path = path.CGPath;
    self.layer.mask = cornerLayer;
}

- (void)fw_setCornerLayer:(UIRectCorner)corner radius:(CGFloat)radius borderColor:(UIColor *)color width:(CGFloat)width
{
    [self fw_setCornerLayer:corner radius:radius];
    
    CAShapeLayer *borderLayer = objc_getAssociatedObject(self, kUIViewFWBorderLayerCornerKey);
    if (!borderLayer) {
        borderLayer = [CAShapeLayer layer];
        [self.layer addSublayer:borderLayer];
        objc_setAssociatedObject(self, kUIViewFWBorderLayerCornerKey, borderLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:self.bounds byRoundingCorners:corner cornerRadii:CGSizeMake(radius, radius)];
    borderLayer.frame = self.bounds;
    borderLayer.path = path.CGPath;
    borderLayer.strokeColor = color.CGColor;
    borderLayer.lineWidth = width * 2;
    borderLayer.fillColor = nil;
}

- (void)fw_setBorderView:(UIRectEdge)edge color:(UIColor *)color width:(CGFloat)width
{
    [self fw_setBorderView:edge color:color width:width leftInset:0 rightInset:0];
}

- (void)fw_setBorderView:(UIRectEdge)edge color:(UIColor *)color width:(CGFloat)width leftInset:(CGFloat)leftInset rightInset:(CGFloat)rightInset
{
    UIView *borderView;
    
    if ((edge & UIRectEdgeTop) == UIRectEdgeTop) {
        borderView = [self fw_innerBorderView:kUIViewFWBorderViewTopKey edge:UIRectEdgeTop];
        [borderView fw_setDimension:NSLayoutAttributeHeight toSize:width];
        [borderView fw_pinEdgeToSuperview:NSLayoutAttributeLeft withInset:leftInset];
        [borderView fw_pinEdgeToSuperview:NSLayoutAttributeRight withInset:rightInset];
        borderView.backgroundColor = color;
    }
    
    if ((edge & UIRectEdgeLeft) == UIRectEdgeLeft) {
        borderView = [self fw_innerBorderView:kUIViewFWBorderViewLeftKey edge:UIRectEdgeLeft];
        [borderView fw_setDimension:NSLayoutAttributeWidth toSize:width];
        [borderView fw_pinEdgeToSuperview:NSLayoutAttributeTop withInset:leftInset];
        [borderView fw_pinEdgeToSuperview:NSLayoutAttributeBottom withInset:rightInset];
        borderView.backgroundColor = color;
    }
    
    if ((edge & UIRectEdgeBottom) == UIRectEdgeBottom) {
        borderView = [self fw_innerBorderView:kUIViewFWBorderViewBottomKey edge:UIRectEdgeBottom];
        [borderView fw_setDimension:NSLayoutAttributeHeight toSize:width];
        [borderView fw_pinEdgeToSuperview:NSLayoutAttributeLeft withInset:leftInset];
        [borderView fw_pinEdgeToSuperview:NSLayoutAttributeRight withInset:rightInset];
        borderView.backgroundColor = color;
    }
    
    if ((edge & UIRectEdgeRight) == UIRectEdgeRight) {
        borderView = [self fw_innerBorderView:kUIViewFWBorderViewRightKey edge:UIRectEdgeRight];
        [borderView fw_setDimension:NSLayoutAttributeWidth toSize:width];
        [borderView fw_pinEdgeToSuperview:NSLayoutAttributeTop withInset:leftInset];
        [borderView fw_pinEdgeToSuperview:NSLayoutAttributeBottom withInset:rightInset];
        borderView.backgroundColor = color;
    }
}

- (UIView *)fw_innerBorderView:(const void *)edgeKey edge:(UIRectEdge)edge
{
    UIView *borderView = objc_getAssociatedObject(self, edgeKey);
    if (!borderView) {
        borderView = [[UIView alloc] init];
        [self addSubview:borderView];
        objc_setAssociatedObject(self, edgeKey, borderView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        if (edge == UIRectEdgeTop || edge == UIRectEdgeBottom) {
            [borderView fw_pinEdgeToSuperview:(edge == UIRectEdgeTop ? NSLayoutAttributeTop : NSLayoutAttributeBottom)];
            [borderView fw_setDimension:NSLayoutAttributeHeight toSize:0];
            [borderView fw_pinEdgeToSuperview:NSLayoutAttributeLeft];
            [borderView fw_pinEdgeToSuperview:NSLayoutAttributeRight];
        } else {
            [borderView fw_pinEdgeToSuperview:(edge == UIRectEdgeLeft ? NSLayoutAttributeLeft : NSLayoutAttributeRight)];
            [borderView fw_setDimension:NSLayoutAttributeWidth toSize:0];
            [borderView fw_pinEdgeToSuperview:NSLayoutAttributeTop];
            [borderView fw_pinEdgeToSuperview:NSLayoutAttributeBottom];
        }
    }
    return borderView;
}

- (dispatch_source_t)fw_startCountDown:(NSInteger)seconds block:(void (^)(NSInteger))block
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_source_t _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    dispatch_source_set_timer(_timer, dispatch_walltime(NULL, 0), 1.0 * NSEC_PER_SEC, 0);
    
    NSTimeInterval startTime = NSDate.fw_currentTime;
    __weak UIView *weakBase = self;
    __block BOOL hasWindow = NO;
    dispatch_source_set_event_handler(_timer, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSInteger countDown = seconds - (NSInteger)round(NSDate.fw_currentTime - startTime);
            if (countDown <= 0) {
                dispatch_source_cancel(_timer);
            }
            
            // 按钮从window移除时自动cancel倒计时
            if (!hasWindow && weakBase.window) {
                hasWindow = YES;
            } else if (hasWindow && !weakBase.window) {
                hasWindow = NO;
                countDown = 0;
                dispatch_source_cancel(_timer);
            }
            
            if (countDown <= 0) {
                block(0);
            } else {
                block(countDown);
            }
        });
    });
    dispatch_resume(_timer);
    return _timer;
}

- (UIVisualEffectView *)fw_setBlurEffect:(UIBlurEffectStyle)style
{
    for (UIView *subview in self.subviews) {
        if ([subview isKindOfClass:[UIVisualEffectView class]]) {
            [subview removeFromSuperview];
        }
    }
    
    if (((NSInteger)style) > -1) {
        UIBlurEffect *effect = [UIBlurEffect effectWithStyle:style];
        UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
        [self addSubview:effectView];
        [effectView fw_pinEdgesToSuperview];
        return effectView;
    }
    return nil;
}

- (void)fw_removeAllSubviews
{
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

- (__kindof UIView *)fw_subviewOfClass:(Class)clazz
{
    return [self fw_subviewOfBlock:^BOOL(UIView *view) {
        return [view isKindOfClass:clazz];
    }];
}

- (__kindof UIView *)fw_subviewOfBlock:(BOOL (^)(UIView *view))block
{
    if (block(self)) {
        return self;
    }
    
    /* 如果需要顺序查找所有子视图，失败后再递归查找，参考此代码即可
    for (UIView *subview in self.subviews) {
        if (block(subview)) {
            return subview;
        }
    } */
    
    for (UIView *subview in self.subviews) {
        UIView *resultView = [subview fw_subviewOfBlock:block];
        if (resultView) {
            return resultView;
        }
    }
    
    return nil;
}

- (__kindof UIView *)fw_superviewOfBlock:(BOOL (^)(UIView *))block
{
    UIView *resultView = nil;
    UIView *superview = self;
    while (superview != nil) {
        if (block(superview)) {
            resultView = superview;
            break;
        }
        superview = superview.superview;
    }
    return resultView;
}

- (UIImage *)fw_snapshotImage
{
    return [UIImage fw_imageWithView:self];
}

- (NSData *)fw_snapshotPdf
{
    CGRect bounds = self.bounds;
    NSMutableData *data = [NSMutableData data];
    CGDataConsumerRef consumer = CGDataConsumerCreateWithCFData((__bridge CFMutableDataRef)data);
    CGContextRef context = CGPDFContextCreate(consumer, &bounds, NULL);
    CGDataConsumerRelease(consumer);
    if (!context) return nil;
    CGPDFContextBeginPage(context, NULL);
    CGContextTranslateCTM(context, 0, bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    [self.layer renderInContext:context];
    CGPDFContextEndPage(context);
    CGPDFContextClose(context);
    CGContextRelease(context);
    return data;
}

- (NSInteger)fw_sortIndex
{
    return [objc_getAssociatedObject(self, @selector(fw_sortIndex)) integerValue];
}

- (void)setFw_sortIndex:(NSInteger)sortIndex
{
    objc_setAssociatedObject(self, @selector(fw_sortIndex), @(sortIndex), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)fw_sortSubviews
{
    NSMutableArray *sortViews = [NSMutableArray array];
    [self.subviews enumerateObjectsUsingBlock:^(__kindof UIView *view, NSUInteger idx, BOOL *stop) {
        if (view.fw_sortIndex != 0) [sortViews addObject:view];
    }];
    if (sortViews.count < 1) return;
    
    [sortViews sortUsingComparator:^NSComparisonResult(UIView *view1, UIView *view2) {
        return (view1.fw_sortIndex < 0 && view2.fw_sortIndex < 0) ? [@(view2.fw_sortIndex) compare:@(view1.fw_sortIndex)] : [@(view1.fw_sortIndex) compare:@(view2.fw_sortIndex)];
    }];
    [sortViews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
        view.fw_sortIndex < 0 ? [self sendSubviewToBack:view] : [self bringSubviewToFront:view];
    }];
}

@end

#pragma mark - UIImageView+FWUIKit

@implementation UIImageView (FWUIKit)

- (void)fw_setContentModeAspectFill
{
    self.contentMode = UIViewContentModeScaleAspectFill;
    self.layer.masksToBounds = YES;
}

- (void)fw_faceAware
{
    if (self.image == nil) {
        return;
    }
    
    [self fw_faceDetect:self.image];
}

- (void)fw_faceDetect:(UIImage *)aImage
{
    static CIDetector *_faceDetector = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace
                                           context:nil
                                           options:@{CIDetectorAccuracy: CIDetectorAccuracyHigh}];
    });
    
    __weak UIImageView *weakBase = self;
    dispatch_queue_t queue = dispatch_queue_create("site.wuyong.queue.uikit.face", NULL);
    dispatch_async(queue, ^{
        CIImage *image = aImage.CIImage;
        if (image == nil) {
            image = [CIImage imageWithCGImage:aImage.CGImage];
        }
        
        NSArray *features = [_faceDetector featuresInImage:image];
        if (features.count == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[weakBase fw_faceLayer:NO] removeFromSuperlayer];
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakBase fw_faceMark:features size:CGSizeMake(CGImageGetWidth(aImage.CGImage), CGImageGetHeight(aImage.CGImage))];
            });
        }
    });
}

- (void)fw_faceMark:(NSArray *)features size:(CGSize)size
{
    CGRect fixedRect = CGRectMake(MAXFLOAT, MAXFLOAT, 0, 0);
    CGFloat rightBorder = 0, bottomBorder = 0;
    for (CIFaceFeature *f in features){
        CGRect oneRect = f.bounds;
        oneRect.origin.y = size.height - oneRect.origin.y - oneRect.size.height;
        
        fixedRect.origin.x = MIN(oneRect.origin.x, fixedRect.origin.x);
        fixedRect.origin.y = MIN(oneRect.origin.y, fixedRect.origin.y);
        
        rightBorder = MAX(oneRect.origin.x + oneRect.size.width, rightBorder);
        bottomBorder = MAX(oneRect.origin.y + oneRect.size.height, bottomBorder);
    }
    
    fixedRect.size.width = rightBorder - fixedRect.origin.x;
    fixedRect.size.height = bottomBorder - fixedRect.origin.y;
    
    CGPoint fixedCenter = CGPointMake(fixedRect.origin.x + fixedRect.size.width / 2.0,
                                      fixedRect.origin.y + fixedRect.size.height / 2.0);
    CGPoint offset = CGPointZero;
    CGSize finalSize = size;
    if (size.width / size.height > self.bounds.size.width / self.bounds.size.height) {
        finalSize.height = self.bounds.size.height;
        finalSize.width = size.width/size.height * finalSize.height;
        fixedCenter.x = finalSize.width / size.width * fixedCenter.x;
        fixedCenter.y = finalSize.width / size.width * fixedCenter.y;
        
        offset.x = fixedCenter.x - self.bounds.size.width * 0.5;
        if (offset.x < 0) {
            offset.x = 0;
        } else if (offset.x + self.bounds.size.width > finalSize.width) {
            offset.x = finalSize.width - self.bounds.size.width;
        }
        offset.x = - offset.x;
    } else {
        finalSize.width = self.bounds.size.width;
        finalSize.height = size.height/size.width * finalSize.width;
        fixedCenter.x = finalSize.width / size.width * fixedCenter.x;
        fixedCenter.y = finalSize.width / size.width * fixedCenter.y;
        
        offset.y = fixedCenter.y - self.bounds.size.height * (1 - 0.618);
        if (offset.y < 0) {
            offset.y = 0;
        } else if (offset.y + self.bounds.size.height > finalSize.height){
            offset.y = finalSize.height - self.bounds.size.height;
        }
        offset.y = - offset.y;
    }
    
    CALayer *layer = [self fw_faceLayer:YES];
    layer.frame = CGRectMake(offset.x, offset.y, finalSize.width, finalSize.height);
    layer.contents = (id)self.image.CGImage;
}

- (CALayer *)fw_faceLayer:(BOOL)lazyload
{
    for (CALayer *layer in self.layer.sublayers) {
        if ([@"FWFaceLayer" isEqualToString:layer.name]) {
            return layer;
        }
    }
    
    if (lazyload) {
        CALayer *layer = [CALayer layer];
        layer.name = @"FWFaceLayer";
        layer.actions = @{
                          @"contents": [NSNull null],
                          @"bounds": [NSNull null],
                          @"position": [NSNull null],
                          };
        [self.layer addSublayer:layer];
        return layer;
    }
    
    return nil;
}

- (void)fw_reflect
{
    CGRect frame = self.frame;
    frame.origin.y += (frame.size.height + 1);
    
    UIImageView *reflectionImageView = [[UIImageView alloc] initWithFrame:frame];
    self.clipsToBounds = YES;
    reflectionImageView.contentMode = self.contentMode;
    [reflectionImageView setImage:self.image];
    reflectionImageView.transform = CGAffineTransformMakeScale(1.0, -1.0);
    
    CALayer *reflectionLayer = [reflectionImageView layer];
    
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.bounds = reflectionLayer.bounds;
    gradientLayer.position = CGPointMake(reflectionLayer.bounds.size.width / 2, reflectionLayer.bounds.size.height * 0.5);
    gradientLayer.colors = [NSArray arrayWithObjects:
                            (id)[[UIColor clearColor] CGColor],
                            (id)[[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.3] CGColor], nil];
    
    gradientLayer.startPoint = CGPointMake(0.5, 0.5);
    gradientLayer.endPoint = CGPointMake(0.5, 1.0);
    reflectionLayer.mask = gradientLayer;
    
    [self.superview addSubview:reflectionImageView];
}

- (void)fw_setImage:(UIImage *)image watermarkImage:(UIImage *)watermarkImage inRect:(CGRect)rect
{
    UIGraphicsBeginImageContextWithOptions(self.frame.size, NO, 0.0);
    
    [image drawInRect:self.bounds];
    [watermarkImage drawInRect:rect];
    
    UIImage *newPic = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    self.image = newPic;
}

- (void)fw_setImage:(UIImage *)image watermarkString:(NSAttributedString *)watermarkString inRect:(CGRect)rect
{
    UIGraphicsBeginImageContextWithOptions(self.frame.size, NO, 0.0);
    
    [image drawInRect:self.bounds];
    [watermarkString drawInRect:rect];
    
    UIImage *newPic = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    self.image = newPic;
}

- (void)fw_setImage:(UIImage *)image watermarkString:(NSAttributedString *)watermarkString atPoint:(CGPoint)point
{
    UIGraphicsBeginImageContextWithOptions(self.frame.size, NO, 0.0);
    
    [image drawInRect:self.bounds];
    [watermarkString drawAtPoint:point];
    
    UIImage *newPic = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    self.image = newPic;
}

@end

#pragma mark - UIWindow+FWUIKit

@implementation UIWindow (FWUIKit)

- (__kindof UIViewController *)fw_getTabBarControllerWithIndex:(NSInteger)index
{
    UITabBarController *tabbarController = [self fw_rootTabBarController];
    if (!tabbarController) return nil;
    
    UINavigationController *targetController = nil;
    if (tabbarController.viewControllers.count > index && index >= 0) {
        targetController = tabbarController.viewControllers[index];
    }
    
    if ([targetController isKindOfClass:[UINavigationController class]]) {
        targetController = targetController.viewControllers.firstObject;
    }
    return targetController;
}

- (__kindof UIViewController *)fw_getTabBarControllerOfClass:(Class)clazz
{
    UITabBarController *tabbarController = [self fw_rootTabBarController];
    if (!tabbarController) return nil;
    
    UIViewController *targetController = nil;
    for (UINavigationController *navigationController in tabbarController.viewControllers) {
        UIViewController *viewController = navigationController;
        if ([navigationController isKindOfClass:[UINavigationController class]]) {
            viewController = navigationController.viewControllers.firstObject;
        }
        if ([viewController isKindOfClass:clazz]) {
            targetController = viewController;
            break;
        }
    }
    return targetController;
}

- (__kindof UIViewController *)fw_getTabBarControllerWithBlock:(__attribute__((noescape)) BOOL (^)(__kindof UIViewController *))block
{
    UITabBarController *tabbarController = [self fw_rootTabBarController];
    if (!tabbarController) return nil;
    
    UIViewController *targetController = nil;
    for (UINavigationController *navigationController in tabbarController.viewControllers) {
        UIViewController *viewController = navigationController;
        if ([navigationController isKindOfClass:[UINavigationController class]]) {
            viewController = navigationController.viewControllers.firstObject;
        }
        if (viewController && block(viewController)) {
            targetController = viewController;
            break;
        }
    }
    return targetController;
}

- (__kindof UIViewController *)fw_selectTabBarControllerWithIndex:(NSInteger)index
{
    UIViewController *viewController = [self fw_getTabBarControllerWithIndex:index];
    if (!viewController) return nil;
    return [self fw_selectTabBarController:viewController];
}

- (__kindof UIViewController *)fw_selectTabBarControllerOfClass:(Class)clazz
{
    UIViewController *viewController = [self fw_getTabBarControllerOfClass:clazz];
    if (!viewController) return nil;
    return [self fw_selectTabBarController:viewController];
}

- (__kindof UIViewController *)fw_selectTabBarControllerWithBlock:(__attribute__((noescape)) BOOL (^)(__kindof UIViewController *))block
{
    UIViewController *viewController = [self fw_getTabBarControllerWithBlock:block];
    if (!viewController) return nil;
    return [self fw_selectTabBarController:viewController];
}

- (UITabBarController *)fw_rootTabBarController
{
    if ([self.rootViewController isKindOfClass:[UITabBarController class]]) {
        return (UITabBarController *)self.rootViewController;
    }
    
    if ([self.rootViewController isKindOfClass:[UINavigationController class]]) {
        UIViewController *firstController = ((UINavigationController *)self.rootViewController).viewControllers.firstObject;
        if ([firstController isKindOfClass:[UITabBarController class]]) {
            return (UITabBarController *)firstController;
        }
    }
    
    return nil;
}

- (UIViewController *)fw_selectTabBarController:(__kindof UIViewController *)viewController
{
    UITabBarController *tabbarController = [self fw_rootTabBarController];
    if (!tabbarController) return nil;
    
    UINavigationController *targetNavigation = viewController.navigationController ?: viewController;
    UINavigationController *currentNavigation = tabbarController.selectedViewController;
    if (currentNavigation != targetNavigation) {
        if ([currentNavigation isKindOfClass:[UINavigationController class]] &&
            currentNavigation.viewControllers.count > 1) {
            [currentNavigation popToRootViewControllerAnimated:NO];
        }
        tabbarController.selectedViewController = targetNavigation;
    }
    
    if ([targetNavigation isKindOfClass:[UINavigationController class]]) {
        if (targetNavigation.viewControllers.count > 1) {
            [targetNavigation popToRootViewControllerAnimated:NO];
        }
    }
    return viewController;
}

@end

#pragma mark - UILabel+FWUIKit

@implementation UILabel (FWUIKit)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // https://github.com/Tencent/QMUI_iOS
        [UILabel fw_exchangeInstanceMethod:@selector(setText:) swizzleMethod:@selector(fw_innerSetText:)];
        [UILabel fw_exchangeInstanceMethod:@selector(setAttributedText:) swizzleMethod:@selector(fw_innerSetAttributedText:)];
        [UILabel fw_exchangeInstanceMethod:@selector(setLineBreakMode:) swizzleMethod:@selector(fw_innerSetLineBreakMode:)];
        [UILabel fw_exchangeInstanceMethod:@selector(setTextAlignment:) swizzleMethod:@selector(fw_innerSetTextAlignment:)];
    });
}

- (void)fw_innerSetText:(NSString *)text
{
    if (!text) {
        [self fw_innerSetText:text];
        return;
    }
    if (!self.fw_textAttributes.count && ![self fw_issetLineHeight]) {
        [self fw_innerSetText:text];
        return;
    }
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:text attributes:self.fw_textAttributes];
    [self fw_innerSetAttributedText:[self fw_adjustedAttributedString:attributedString]];
}

- (void)fw_innerSetAttributedText:(NSAttributedString *)text
{
    if (!text || (!self.fw_textAttributes.count && ![self fw_issetLineHeight])) {
        [self fw_innerSetAttributedText:text];
        return;
    }
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text.string attributes:self.fw_textAttributes];
    attributedString = [[self fw_adjustedAttributedString:attributedString] mutableCopy];
    [text enumerateAttributesInRange:NSMakeRange(0, text.length) options:0 usingBlock:^(NSDictionary<NSString *,id> * _Nonnull attrs, NSRange range, BOOL * _Nonnull stop) {
        [attributedString addAttributes:attrs range:range];
    }];
    [self fw_innerSetAttributedText:attributedString];
}

- (void)fw_innerSetLineBreakMode:(NSLineBreakMode)lineBreakMode
{
    [self fw_innerSetLineBreakMode:lineBreakMode];
    if (!self.fw_textAttributes) return;
    if (self.fw_textAttributes[NSParagraphStyleAttributeName]) {
        NSMutableParagraphStyle *p = ((NSParagraphStyle *)self.fw_textAttributes[NSParagraphStyleAttributeName]).mutableCopy;
        p.lineBreakMode = lineBreakMode;
        NSMutableDictionary<NSAttributedStringKey, id> *attrs = self.fw_textAttributes.mutableCopy;
        attrs[NSParagraphStyleAttributeName] = p.copy;
        self.fw_textAttributes = attrs.copy;
    }
}

- (void)fw_innerSetTextAlignment:(NSTextAlignment)textAlignment
{
    [self fw_innerSetTextAlignment:textAlignment];
    if (!self.fw_textAttributes) return;
    if (self.fw_textAttributes[NSParagraphStyleAttributeName]) {
        NSMutableParagraphStyle *p = ((NSParagraphStyle *)self.fw_textAttributes[NSParagraphStyleAttributeName]).mutableCopy;
        p.alignment = textAlignment;
        NSMutableDictionary<NSAttributedStringKey, id> *attrs = self.fw_textAttributes.mutableCopy;
        attrs[NSParagraphStyleAttributeName] = p.copy;
        self.fw_textAttributes = attrs.copy;
    }
}

- (void)setFw_textAttributes:(NSDictionary<NSAttributedStringKey,id> *)textAttributes
{
    NSDictionary *prevTextAttributes = self.fw_textAttributes;
    if ([prevTextAttributes isEqualToDictionary:textAttributes]) {
        return;
    }
    
    objc_setAssociatedObject(self, @selector(fw_textAttributes), textAttributes, OBJC_ASSOCIATION_COPY_NONATOMIC);
    
    if (!self.text.length) {
        return;
    }
    NSMutableAttributedString *string = [self.attributedText mutableCopy];
    NSRange fullRange = NSMakeRange(0, string.length);
    
    if (prevTextAttributes) {
        NSMutableArray *willRemovedAttributes = [NSMutableArray array];
        [string enumerateAttributesInRange:NSMakeRange(0, string.length) options:0 usingBlock:^(NSDictionary<NSAttributedStringKey,id> * _Nonnull attrs, NSRange range, BOOL * _Nonnull stop) {
            if (NSEqualRanges(range, NSMakeRange(0, string.length - 1)) && [attrs[NSKernAttributeName] isEqualToNumber:prevTextAttributes[NSKernAttributeName]]) {
                [string removeAttribute:NSKernAttributeName range:NSMakeRange(0, string.length - 1)];
            }
            if (!NSEqualRanges(range, fullRange)) {
                return;
            }
            [attrs enumerateKeysAndObjectsUsingBlock:^(NSAttributedStringKey _Nonnull attr, id  _Nonnull value, BOOL * _Nonnull stop) {
                if (prevTextAttributes[attr] == value) {
                    [willRemovedAttributes addObject:attr];
                }
            }];
        }];
        [willRemovedAttributes enumerateObjectsUsingBlock:^(id  _Nonnull attr, NSUInteger idx, BOOL * _Nonnull stop) {
            [string removeAttribute:attr range:fullRange];
        }];
    }
    
    if (textAttributes) {
        [string addAttributes:textAttributes range:fullRange];
    }
    [self fw_innerSetAttributedText:[self fw_adjustedAttributedString:string]];
}

- (NSDictionary<NSAttributedStringKey, id> *)fw_textAttributes
{
    return (NSDictionary<NSAttributedStringKey, id> *)objc_getAssociatedObject(self, @selector(fw_textAttributes));
}

- (NSAttributedString *)fw_adjustedAttributedString:(NSAttributedString *)string
{
    if (!string.length) {
        return string;
    }
    NSMutableAttributedString *attributedString = nil;
    if ([string isKindOfClass:[NSMutableAttributedString class]]) {
        attributedString = (NSMutableAttributedString *)string;
    } else {
        attributedString = [string mutableCopy];
    }
    
    if (self.fw_textAttributes[NSKernAttributeName]) {
        [attributedString removeAttribute:NSKernAttributeName range:NSMakeRange(string.length - 1, 1)];
    }
    
    __block BOOL shouldAdjustLineHeight = [self fw_issetLineHeight];
    [attributedString enumerateAttribute:NSParagraphStyleAttributeName inRange:NSMakeRange(0, attributedString.length) options:0 usingBlock:^(NSParagraphStyle *style, NSRange range, BOOL * _Nonnull stop) {
        if (NSEqualRanges(range, NSMakeRange(0, attributedString.length))) {
            if (style && (style.maximumLineHeight || style.minimumLineHeight)) {
                shouldAdjustLineHeight = NO;
                *stop = YES;
            }
        }
    }];
    if (shouldAdjustLineHeight) {
        NSMutableParagraphStyle *paraStyle = [[NSMutableParagraphStyle alloc] init];
        paraStyle.minimumLineHeight = self.fw_lineHeight;
        paraStyle.maximumLineHeight = self.fw_lineHeight;
        paraStyle.lineBreakMode = self.lineBreakMode;
        paraStyle.alignment = self.textAlignment;
        [attributedString addAttribute:NSParagraphStyleAttributeName value:paraStyle range:NSMakeRange(0, attributedString.length)];
        
        CGFloat baselineOffset = (self.fw_lineHeight - self.font.lineHeight) / 4;
        [attributedString addAttribute:NSBaselineOffsetAttributeName value:@(baselineOffset) range:NSMakeRange(0, attributedString.length)];
    }
    return attributedString;
}

- (void)setFw_lineHeight:(CGFloat)lineHeight
{
    if (lineHeight < 0) {
        objc_setAssociatedObject(self, @selector(fw_lineHeight), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    } else {
        objc_setAssociatedObject(self, @selector(fw_lineHeight), @(lineHeight), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    if (!self.attributedText.string) return;
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:self.attributedText.string attributes:self.fw_textAttributes];
    attributedString = [[self fw_adjustedAttributedString:attributedString] mutableCopy];
    [self setAttributedText:attributedString];
}

- (CGFloat)fw_lineHeight
{
    if ([self fw_issetLineHeight]) {
        return [(NSNumber *)objc_getAssociatedObject(self, @selector(fw_lineHeight)) doubleValue];
    } else if (self.attributedText.length) {
        __block NSMutableAttributedString *string = [self.attributedText mutableCopy];
        __block CGFloat result = 0;
        [string enumerateAttribute:NSParagraphStyleAttributeName inRange:NSMakeRange(0, string.length) options:0 usingBlock:^(NSParagraphStyle *style, NSRange range, BOOL * _Nonnull stop) {
            if (NSEqualRanges(range, NSMakeRange(0, string.length))) {
                if (style && (style.maximumLineHeight || style.minimumLineHeight)) {
                    result = style.maximumLineHeight;
                    *stop = YES;
                }
            }
        }];
        return result == 0 ? self.font.lineHeight : result;
    } else if (self.text.length) {
        return self.font.lineHeight;
    }
    return 0;
}

- (BOOL)fw_issetLineHeight
{
    return !!objc_getAssociatedObject(self, @selector(fw_lineHeight));
}

- (UIEdgeInsets)fw_contentInset
{
    return [objc_getAssociatedObject(self, @selector(fw_contentInset)) UIEdgeInsetsValue];
}

- (void)setFw_contentInset:(UIEdgeInsets)contentInset
{
    UIEdgeInsets insets = UIEdgeInsetsMake([UIScreen fw_flatValue:contentInset.top], [UIScreen fw_flatValue:contentInset.left], [UIScreen fw_flatValue:contentInset.bottom], [UIScreen fw_flatValue:contentInset.right]);
    objc_setAssociatedObject(self, @selector(fw_contentInset), [NSValue valueWithUIEdgeInsets:insets], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self setNeedsDisplay];
}

- (UIControlContentVerticalAlignment)fw_verticalAlignment
{
    return [objc_getAssociatedObject(self, @selector(fw_verticalAlignment)) integerValue];
}

- (void)setFw_verticalAlignment:(UIControlContentVerticalAlignment)verticalAlignment
{
    objc_setAssociatedObject(self, @selector(fw_verticalAlignment), @(verticalAlignment), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self setNeedsDisplay];
}

- (void)fw_addLinkGestureWithBlock:(void (^)(id))block
{
    self.userInteractionEnabled = YES;
    [self fw_addTapGestureWithBlock:^(UITapGestureRecognizer *gesture) {
        if (![gesture.view isKindOfClass:[UILabel class]]) return;
        
        UILabel *label = (UILabel *)gesture.view;
        NSDictionary *attributes = [label fw_attributesWithGesture:gesture allowsSpacing:NO];
        id link = attributes[NSLinkAttributeName] ?: attributes[@"URL"];
        if (block) block(link);
    }];
}

- (NSDictionary<NSAttributedStringKey,id> *)fw_attributesWithGesture:(UIGestureRecognizer *)gesture allowsSpacing:(BOOL)allowsSpacing
{
    NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:self.bounds.size];
    textContainer.lineFragmentPadding = 0;
    textContainer.maximumNumberOfLines = self.numberOfLines;
    textContainer.lineBreakMode = self.lineBreakMode;
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    [layoutManager addTextContainer:textContainer];
    NSTextStorage *textStorage = [[NSTextStorage alloc] initWithAttributedString:self.attributedText];
    [textStorage addLayoutManager:layoutManager];

    CGPoint point = [gesture locationInView:self];
    CGFloat distance = 0;
    NSUInteger index = [layoutManager characterIndexForPoint:point inTextContainer:textContainer fractionOfDistanceBetweenInsertionPoints:&distance];
    if (!allowsSpacing && distance >= 1) return @{};
    return [self.attributedText attributesAtIndex:index effectiveRange:NULL];
}

- (void)fw_setFont:(UIFont *)font textColor:(UIColor *)textColor
{
    [self fw_setFont:font textColor:textColor text:nil];
}

- (void)fw_setFont:(UIFont *)font textColor:(UIColor *)textColor text:(NSString *)text
{
    if (font) self.font = font;
    if (textColor) self.textColor = textColor;
    if (text) self.text = text;
}

+ (instancetype)fw_labelWithFont:(UIFont *)font textColor:(UIColor *)textColor
{
    return [self fw_labelWithFont:font textColor:textColor text:nil];
}

+ (instancetype)fw_labelWithFont:(UIFont *)font textColor:(UIColor *)textColor text:(NSString *)text
{
    UILabel *label = [[self alloc] init];
    [label fw_setFont:font textColor:textColor text:text];
    return label;
}

- (CGSize)fw_textSize
{
    if (CGSizeEqualToSize(self.frame.size, CGSizeZero)) {
        [self setNeedsLayout];
        [self layoutIfNeeded];
    }
    
    NSMutableDictionary *attr = [[NSMutableDictionary alloc] init];
    attr[NSFontAttributeName] = self.font;
    if (self.lineBreakMode != NSLineBreakByWordWrapping) {
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        // 由于lineBreakMode默认值为TruncatingTail，多行显示时仍然按照WordWrapping计算
        if (self.numberOfLines != 1 && self.lineBreakMode == NSLineBreakByTruncatingTail) {
            paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
        } else {
            paragraphStyle.lineBreakMode = self.lineBreakMode;
        }
        attr[NSParagraphStyleAttributeName] = paragraphStyle;
    }
    
    CGSize drawSize = CGSizeMake(self.frame.size.width, CGFLOAT_MAX);
    CGSize size = [self.text boundingRectWithSize:drawSize
                                          options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin
                                       attributes:attr
                                          context:nil].size;
    return CGSizeMake(MIN(drawSize.width, ceilf(size.width)), MIN(drawSize.height, ceilf(size.height)));
}

- (CGSize)fw_attributedTextSize
{
    if (CGSizeEqualToSize(self.frame.size, CGSizeZero)) {
        [self setNeedsLayout];
        [self layoutIfNeeded];
    }
    
    CGSize drawSize = CGSizeMake(self.frame.size.width, CGFLOAT_MAX);
    CGSize size = [self.attributedText boundingRectWithSize:drawSize
                                                    options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin
                                                    context:nil].size;
    return CGSizeMake(MIN(drawSize.width, ceilf(size.width)), MIN(drawSize.height, ceilf(size.height)));
}

@end

#pragma mark - UIControl+FWUIKit

@implementation UIControl (FWUIKit)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWSwizzleClass(UIControl, @selector(sendAction:to:forEvent:), FWSwizzleReturn(void), FWSwizzleArgs(SEL action, id target, UIEvent *event), FWSwizzleCode({
            // 仅拦截Touch事件，且配置了间隔时间的Event
            if (event.type == UIEventTypeTouches && event.subtype == UIEventSubtypeNone && selfObject.fw_touchEventInterval > 0) {
                if ([[NSDate date] timeIntervalSince1970] - selfObject.fw_touchEventTimestamp < selfObject.fw_touchEventInterval) {
                    return;
                }
                selfObject.fw_touchEventTimestamp = [[NSDate date] timeIntervalSince1970];
            }
            
            FWSwizzleOriginal(action, target, event);
        }));
    });
}

- (NSTimeInterval)fw_touchEventInterval
{
    return [objc_getAssociatedObject(self, @selector(fw_touchEventInterval)) doubleValue];
}

- (void)setFw_touchEventInterval:(NSTimeInterval)interval
{
    objc_setAssociatedObject(self, @selector(fw_touchEventInterval), @(interval), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSTimeInterval)fw_touchEventTimestamp
{
    return [objc_getAssociatedObject(self, @selector(fw_touchEventTimestamp)) doubleValue];
}

- (void)setFw_touchEventTimestamp:(NSTimeInterval)timestamp
{
    objc_setAssociatedObject(self, @selector(fw_touchEventTimestamp), @(timestamp), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

#pragma mark - UIButton+FWUIKit

@implementation UIButton (FWUIKit)

+ (CGFloat)fw_highlightedAlpha
{
    NSNumber *value = objc_getAssociatedObject([UIButton class], @selector(fw_highlightedAlpha));
    return value ? value.doubleValue : 0.5;
}

+ (void)setFw_highlightedAlpha:(CGFloat)alpha
{
    objc_setAssociatedObject([UIButton class], @selector(fw_highlightedAlpha), @(alpha), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (CGFloat)fw_disabledAlpha
{
    NSNumber *value = objc_getAssociatedObject([UIButton class], @selector(fw_disabledAlpha));
    return value ? value.doubleValue : 0.3;
}

+ (void)setFw_disabledAlpha:(CGFloat)alpha
{
    objc_setAssociatedObject([UIButton class], @selector(fw_disabledAlpha), @(alpha), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)fw_disabledAlpha
{
    return [objc_getAssociatedObject(self, @selector(fw_disabledAlpha)) doubleValue];
}

- (void)setFw_disabledAlpha:(CGFloat)alpha
{
    objc_setAssociatedObject(self, @selector(fw_disabledAlpha), @(alpha), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if (alpha > 0) {
        self.alpha = self.isEnabled ? 1 : alpha;
    }
}

- (void (^)(UIButton * _Nonnull, BOOL))fw_disabledChanged
{
    return objc_getAssociatedObject(self, @selector(fw_disabledChanged));
}

- (void)setFw_disabledChanged:(void (^)(UIButton * _Nonnull, BOOL))block
{
    objc_setAssociatedObject(self, @selector(fw_disabledChanged), block, OBJC_ASSOCIATION_COPY_NONATOMIC);
    
    if (block) {
        block(self, self.isEnabled);
    }
}

- (CGFloat)fw_highlightedAlpha
{
    return [objc_getAssociatedObject(self, @selector(fw_highlightedAlpha)) doubleValue];
}

- (void)setFw_highlightedAlpha:(CGFloat)alpha
{
    objc_setAssociatedObject(self, @selector(fw_highlightedAlpha), @(alpha), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if (self.enabled && alpha > 0) {
        self.alpha = self.isHighlighted ? alpha : 1;
    }
}

- (void (^)(UIButton * _Nonnull, BOOL))fw_highlightedChanged
{
    return objc_getAssociatedObject(self, @selector(fw_highlightedChanged));
}

- (void)setFw_highlightedChanged:(void (^)(UIButton * _Nonnull, BOOL))block
{
    objc_setAssociatedObject(self, @selector(fw_highlightedChanged), block, OBJC_ASSOCIATION_COPY_NONATOMIC);
    
    if (self.enabled && block) {
        block(self, self.isHighlighted);
    }
}

- (void)fw_setTitle:(NSString *)title font:(UIFont *)font titleColor:(UIColor *)titleColor
{
    if (title) [self setTitle:title forState:UIControlStateNormal];
    if (font) self.titleLabel.font = font;
    if (titleColor) [self setTitleColor:titleColor forState:UIControlStateNormal];
}

- (void)fw_setTitle:(NSString *)title
{
    [self setTitle:title forState:UIControlStateNormal];
}

- (void)fw_setImage:(UIImage *)image
{
    [self setImage:image forState:UIControlStateNormal];
}

- (void)fw_setImageEdge:(UIRectEdge)edge spacing:(CGFloat)spacing
{
    CGSize imageSize = self.imageView.image.size;
    CGSize labelSize = self.titleLabel.intrinsicContentSize;
    switch (edge) {
        case UIRectEdgeLeft:
            self.imageEdgeInsets = UIEdgeInsetsMake(0, -spacing / 2.0, 0, spacing / 2.0);
            self.titleEdgeInsets = UIEdgeInsetsMake(0, spacing / 2.0, 0, -spacing / 2.0);
            break;
        case UIRectEdgeRight:
            self.imageEdgeInsets = UIEdgeInsetsMake(0, labelSize.width + spacing / 2.0, 0, -labelSize.width - spacing / 2.0);
            self.titleEdgeInsets = UIEdgeInsetsMake(0, -imageSize.width - spacing / 2.0, 0, imageSize.width + spacing / 2.0);
            break;
        case UIRectEdgeTop:
            self.imageEdgeInsets = UIEdgeInsetsMake(-labelSize.height - spacing / 2.0, 0, spacing / 2.0, -labelSize.width);
            self.titleEdgeInsets = UIEdgeInsetsMake(spacing / 2.0, -imageSize.width, -imageSize.height - spacing / 2.0, 0);
            break;
        case UIRectEdgeBottom:
            self.imageEdgeInsets = UIEdgeInsetsMake(spacing / 2.0, 0, -labelSize.height - spacing / 2.0, -labelSize.width);
            self.titleEdgeInsets = UIEdgeInsetsMake(-imageSize.height - spacing / 2.0, -imageSize.width, spacing / 2.0, 0);
            break;
        default:
            break;
    }
}

- (void)fw_setBackgroundColor:(UIColor *)backgroundColor forState:(UIControlState)state
{
    UIImage *image = nil;
    if (backgroundColor) {
        CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
        UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        CGContextSetFillColorWithColor(context, [backgroundColor CGColor]);
        CGContextFillRect(context, rect);
        
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    [self setBackgroundImage:image forState:state];
}

+ (instancetype)fw_buttonWithTitle:(NSString *)title font:(UIFont *)font titleColor:(UIColor *)titleColor
{
    UIButton *button = [self buttonWithType:UIButtonTypeCustom];
    [button fw_setTitle:title font:font titleColor:titleColor];
    return button;
}

+ (instancetype)fw_buttonWithImage:(UIImage *)image
{
    UIButton *button = [self buttonWithType:UIButtonTypeCustom];
    [button setImage:image forState:UIControlStateNormal];
    return button;
}

- (dispatch_source_t)fw_startCountDown:(NSInteger)seconds title:(NSString *)title waitTitle:(NSString *)waitTitle
{
    __weak UIButton *weakBase = self;
    return [self fw_startCountDown:seconds block:^(NSInteger countDown) {
        // 先设置titleLabel，再设置title，防止闪烁
        if (countDown <= 0) {
            weakBase.titleLabel.text = title;
            [weakBase setTitle:title forState:UIControlStateNormal];
            weakBase.enabled = YES;
        } else {
            NSString *waitText = [NSString stringWithFormat:waitTitle, countDown];
            weakBase.titleLabel.text = waitText;
            [weakBase setTitle:waitText forState:UIControlStateNormal];
            weakBase.enabled = NO;
        }
    }];
}

@end

#pragma mark - UIScrollView+FWUIKit

@implementation UIScrollView (FWUIKit)

- (BOOL)fw_canScroll
{
    return [self fw_canScrollVertical] || [self fw_canScrollHorizontal];
}

- (BOOL)fw_canScrollHorizontal
{
    if (self.bounds.size.width <= 0) return NO;
    return self.contentSize.width + self.adjustedContentInset.left + self.adjustedContentInset.right > CGRectGetWidth(self.bounds);
}

- (BOOL)fw_canScrollVertical
{
    if (self.bounds.size.height <= 0) return NO;
    return self.contentSize.height + self.adjustedContentInset.top + self.adjustedContentInset.bottom > CGRectGetHeight(self.bounds);
}

- (void)fw_scrollToEdge:(UIRectEdge)edge animated:(BOOL)animated
{
    CGPoint contentOffset = [self fw_contentOffsetOfEdge:edge];
    [self setContentOffset:contentOffset animated:animated];
}

- (BOOL)fw_isScrollToEdge:(UIRectEdge)edge
{
    CGPoint contentOffset = [self fw_contentOffsetOfEdge:edge];
    switch (edge) {
        case UIRectEdgeTop:
            return self.contentOffset.y <= contentOffset.y;
        case UIRectEdgeLeft:
            return self.contentOffset.x <= contentOffset.x;
        case UIRectEdgeBottom:
            return self.contentOffset.y >= contentOffset.y;
        case UIRectEdgeRight:
            return self.contentOffset.x >= contentOffset.x;
        default:
            return NO;
    }
}

- (CGPoint)fw_contentOffsetOfEdge:(UIRectEdge)edge
{
    CGPoint contentOffset = self.contentOffset;
    switch (edge) {
        case UIRectEdgeTop:
            contentOffset.y = -self.adjustedContentInset.top;
            break;
        case UIRectEdgeLeft:
            contentOffset.x = -self.adjustedContentInset.left;
            break;
        case UIRectEdgeBottom:
            contentOffset.y = self.contentSize.height - self.bounds.size.height + self.adjustedContentInset.bottom;
            break;
        case UIRectEdgeRight:
            contentOffset.x = self.contentSize.width - self.bounds.size.width + self.adjustedContentInset.right;
            break;
        default:
            break;
    }
    return contentOffset;
}

- (NSInteger)fw_totalPage
{
    if ([self fw_canScrollVertical]) {
        return (NSInteger)ceil((self.contentSize.height / self.frame.size.height));
    } else {
        return (NSInteger)ceil((self.contentSize.width / self.frame.size.width));
    }
}

- (NSInteger)fw_currentPage
{
    if ([self fw_canScrollVertical]) {
        CGFloat pageHeight = self.frame.size.height;
        return (NSInteger)floor((self.contentOffset.y - pageHeight / 2) / pageHeight) + 1;
    } else {
        CGFloat pageWidth = self.frame.size.width;
        return (NSInteger)floor((self.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    }
}

- (void)setFw_currentPage:(NSInteger)page
{
    if ([self fw_canScrollVertical]) {
        CGFloat offset = (self.frame.size.height * page);
        self.contentOffset = CGPointMake(0.f, offset);
    } else {
        CGFloat offset = (self.frame.size.width * page);
        self.contentOffset = CGPointMake(offset, 0.f);
    }
}

- (void)fw_setCurrentPage:(NSInteger)page animated:(BOOL)animated
{
    if ([self fw_canScrollVertical]) {
        CGFloat offset = (self.frame.size.height * page);
        [self setContentOffset:CGPointMake(0.f, offset) animated:animated];
    } else {
        CGFloat offset = (self.frame.size.width * page);
        [self setContentOffset:CGPointMake(offset, 0.f) animated:animated];
    }
}

- (BOOL)fw_isLastPage
{
    return (self.fw_currentPage == (self.fw_totalPage - 1));
}

- (CGFloat)fw_contentOffsetX
{
    return self.contentOffset.x;
}

- (void)setFw_contentOffsetX:(CGFloat)contentOffsetX
{
    self.contentOffset = CGPointMake(contentOffsetX, self.contentOffset.y);
}

- (CGFloat)fw_contentOffsetY
{
    return self.contentOffset.y;
}

- (void)setFw_contentOffsetY:(CGFloat)contentOffsetY
{
    self.contentOffset = CGPointMake(self.contentOffset.x, contentOffsetY);
}

- (UIView *)fw_contentView
{
    UIView *contentView = objc_getAssociatedObject(self, _cmd);
    if (!contentView) {
        contentView = [[UIView alloc] init];
        objc_setAssociatedObject(self, _cmd, contentView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        [self addSubview:contentView];
        [contentView fw_pinEdgesToSuperview];
    }
    return contentView;
}

- (CGFloat)fw_hoverView:(UIView *)view
         fromSuperview:(UIView *)fromSuperview
           toSuperview:(UIView *)toSuperview
            toPosition:(CGFloat)toPosition
{
    CGFloat distance = [fromSuperview.superview convertPoint:fromSuperview.frame.origin toView:toSuperview].y - toPosition;
    if (distance <= 0) {
        if (view.superview != toSuperview) {
            [view removeFromSuperview];
            [toSuperview addSubview:view]; {
                [view fw_pinEdgeToSuperview:NSLayoutAttributeLeft];
                [view fw_pinEdgeToSuperview:NSLayoutAttributeTop withInset:toPosition];
                [view fw_setDimensionsToSize:view.bounds.size];
            }
        }
    } else {
        if (view.superview != fromSuperview) {
            [view removeFromSuperview];
            [fromSuperview addSubview:view]; {
                [view fw_pinEdgesToSuperview];
            }
        }
    }
    return distance;
}

- (BOOL (^)(UIGestureRecognizer *))fw_shouldBegin
{
    return objc_getAssociatedObject(self, @selector(fw_shouldBegin));
}

- (void)setFw_shouldBegin:(BOOL (^)(UIGestureRecognizer *))shouldBegin
{
    objc_setAssociatedObject(self, @selector(fw_shouldBegin), shouldBegin, OBJC_ASSOCIATION_COPY_NONATOMIC);
    [UIScrollView fw_enablePanProxy];
}

- (BOOL (^)(UIGestureRecognizer *, UIGestureRecognizer *))fw_shouldRecognizeSimultaneously
{
    return objc_getAssociatedObject(self, @selector(fw_shouldRecognizeSimultaneously));
}

- (void)setFw_shouldRecognizeSimultaneously:(BOOL (^)(UIGestureRecognizer *, UIGestureRecognizer *))shouldRecognizeSimultaneously
{
    objc_setAssociatedObject(self, @selector(fw_shouldRecognizeSimultaneously), shouldRecognizeSimultaneously, OBJC_ASSOCIATION_COPY_NONATOMIC);
    [UIScrollView fw_enablePanProxy];
}

- (BOOL (^)(UIGestureRecognizer *, UIGestureRecognizer *))fw_shouldRequireFailure
{
    return objc_getAssociatedObject(self, @selector(fw_shouldRequireFailure));
}

- (void)setFw_shouldRequireFailure:(BOOL (^)(UIGestureRecognizer *, UIGestureRecognizer *))shouldRequireFailure
{
    objc_setAssociatedObject(self, @selector(fw_shouldRequireFailure), shouldRequireFailure, OBJC_ASSOCIATION_COPY_NONATOMIC);
    [UIScrollView fw_enablePanProxy];
}

- (BOOL (^)(UIGestureRecognizer *, UIGestureRecognizer *))fw_shouldBeRequiredToFail
{
    return objc_getAssociatedObject(self, @selector(fw_shouldBeRequiredToFail));
}

- (void)setFw_shouldBeRequiredToFail:(BOOL (^)(UIGestureRecognizer *, UIGestureRecognizer *))shouldBeRequiredToFail
{
    objc_setAssociatedObject(self, @selector(fw_shouldBeRequiredToFail), shouldBeRequiredToFail, OBJC_ASSOCIATION_COPY_NONATOMIC);
    [UIScrollView fw_enablePanProxy];
}

+ (void)fw_enablePanProxy
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [UIScrollView fw_exchangeInstanceMethod:@selector(gestureRecognizerShouldBegin:) swizzleMethod:@selector(fw_innerGestureRecognizerShouldBegin:)];
        [UIScrollView fw_exchangeInstanceMethod:@selector(gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:) swizzleMethod:@selector(fw_innerGestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:)];
        [UIScrollView fw_exchangeInstanceMethod:@selector(gestureRecognizer:shouldRequireFailureOfGestureRecognizer:) swizzleMethod:@selector(fw_innerGestureRecognizer:shouldRequireFailureOfGestureRecognizer:)];
        [UIScrollView fw_exchangeInstanceMethod:@selector(gestureRecognizer:shouldBeRequiredToFailByGestureRecognizer:) swizzleMethod:@selector(fw_innerGestureRecognizer:shouldBeRequiredToFailByGestureRecognizer:)];
    });
}

- (BOOL)fw_innerGestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    BOOL (^shouldBlock)(UIGestureRecognizer *) = objc_getAssociatedObject(self, @selector(fw_shouldBegin));
    if (shouldBlock) {
        return shouldBlock(gestureRecognizer);
    }
    
    return [self fw_innerGestureRecognizerShouldBegin:gestureRecognizer];
}

- (BOOL)fw_innerGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    BOOL (^shouldBlock)(UIGestureRecognizer *, UIGestureRecognizer *) = objc_getAssociatedObject(self, @selector(fw_shouldRecognizeSimultaneously));
    if (shouldBlock) {
        return shouldBlock(gestureRecognizer, otherGestureRecognizer);
    }
    
    return [self fw_innerGestureRecognizer:gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:otherGestureRecognizer];
}

- (BOOL)fw_innerGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    BOOL (^shouldBlock)(UIGestureRecognizer *, UIGestureRecognizer *) = objc_getAssociatedObject(self, @selector(fw_shouldRequireFailure));
    if (shouldBlock) {
        return shouldBlock(gestureRecognizer, otherGestureRecognizer);
    }
    
    return [self fw_innerGestureRecognizer:gestureRecognizer shouldRequireFailureOfGestureRecognizer:otherGestureRecognizer];
}

- (BOOL)fw_innerGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    BOOL (^shouldBlock)(UIGestureRecognizer *, UIGestureRecognizer *) = objc_getAssociatedObject(self, @selector(fw_shouldBeRequiredToFail));
    if (shouldBlock) {
        return shouldBlock(gestureRecognizer, otherGestureRecognizer);
    }
    
    return [self fw_innerGestureRecognizer:gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:otherGestureRecognizer];
}

@end

#pragma mark - UIGestureRecognizer+FWUIKit

@implementation UIGestureRecognizer (FWUIKit)

- (UIView *)fw_targetView
{
    return [self.view hitTest:[self locationInView:self.view] withEvent:nil];
}

- (BOOL)fw_isTracking
{
    return self.state == UIGestureRecognizerStateBegan || self.state == UIGestureRecognizerStateChanged;
}

- (BOOL)fw_isActive
{
    return self.isEnabled && (self.state == UIGestureRecognizerStateBegan || self.state == UIGestureRecognizerStateChanged);
}

- (BOOL)fw_hitTestWithView:(UIView *)view
{
    return [view hitTest:[self locationInView:view] withEvent:nil] != nil;
}

@end

#pragma mark - UIPanGestureRecognizer+FWUIKit

@implementation UIPanGestureRecognizer (FWUIKit)

- (UISwipeGestureRecognizerDirection)fw_swipeDirection
{
    CGPoint transition = [self translationInView:self.view];
    if (fabs(transition.x) > fabs(transition.y)) {
        if (transition.x < 0.0f) {
            return UISwipeGestureRecognizerDirectionLeft;
        } else if (transition.x > 0.0f) {
            return UISwipeGestureRecognizerDirectionRight;
        }
    } else {
        if (transition.y > 0.0f) {
            return UISwipeGestureRecognizerDirectionDown;
        } else if (transition.y < 0.0f) {
            return UISwipeGestureRecognizerDirectionUp;
        }
    }
    return 0;
}

- (CGFloat)fw_swipePercent
{
    CGFloat percent = 0;
    CGPoint transition = [self translationInView:self.view];
    if (fabs(transition.x) > fabs(transition.y)) {
        percent = fabs(transition.x) / self.view.bounds.size.width;
    } else {
        percent = fabs(transition.y) / self.view.bounds.size.height;
    }
    return MAX(0, MIN(1, percent));
}

- (CGFloat)fw_swipePercentOfDirection:(UISwipeGestureRecognizerDirection)direction
{
    CGFloat percent = 0;
    CGPoint transition = [self translationInView:self.view];
    switch (direction) {
        case UISwipeGestureRecognizerDirectionLeft:
            percent = -transition.x / self.view.bounds.size.width;
            break;
        case UISwipeGestureRecognizerDirectionRight:
            percent = transition.x / self.view.bounds.size.width;
            break;
        case UISwipeGestureRecognizerDirectionUp:
            percent = -transition.y / self.view.bounds.size.height;
            break;
        case UISwipeGestureRecognizerDirectionDown:
        default:
            percent = transition.y / self.view.bounds.size.height;
            break;
    }
    return MAX(0, MIN(1, percent));
}

@end

#pragma mark - UIPageControl+FWUIKit

@implementation UIPageControl (FWUIKit)

- (CGSize)fw_preferredSize
{
    CGSize size = self.bounds.size;
    if (size.height <= 0) {
        size = [self sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
        if (size.height <= 0) size = CGSizeMake(10, 10);
    }
    return size;
}

- (void)setFw_preferredSize:(CGSize)size
{
    CGFloat height = [self fw_preferredSize].height;
    CGFloat scale = size.height / height;
    self.transform = CGAffineTransformMakeScale(scale, scale);
}

@end

#pragma mark - UISlider+FWUIKit

@implementation UISlider (FWUIKit)

- (CGSize)fw_thumbSize
{
    NSValue *value = objc_getAssociatedObject(self, @selector(fw_thumbSize));
    return value ? [value CGSizeValue] : CGSizeZero;
}

- (void)setFw_thumbSize:(CGSize)thumbSize
{
    objc_setAssociatedObject(self, @selector(fw_thumbSize), [NSValue valueWithCGSize:thumbSize], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self fw_updateThumbImage];
}

- (UIColor *)fw_thumbColor
{
    return objc_getAssociatedObject(self, @selector(fw_thumbColor));
}

- (void)setFw_thumbColor:(UIColor *)thumbColor
{
    objc_setAssociatedObject(self, @selector(fw_thumbColor), thumbColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self fw_updateThumbImage];
}

- (void)fw_updateThumbImage
{
    CGSize thumbSize = self.fw_thumbSize;
    if (thumbSize.width <= 0 || thumbSize.height <= 0) return;
    UIColor *thumbColor = self.fw_thumbColor ?: (self.tintColor ?: [UIColor whiteColor]);
    UIImage *thumbImage = [UIImage fw_imageWithSize:thumbSize block:^(CGContextRef  _Nonnull context) {
        UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, thumbSize.width, thumbSize.height)];
        CGContextSetFillColorWithColor(context, thumbColor.CGColor);
        [path fill];
    }];
    
    [self setThumbImage:thumbImage forState:UIControlStateNormal];
    [self setThumbImage:thumbImage forState:UIControlStateHighlighted];
}

@end

#pragma mark - UISwitch+FWUIKit

@implementation UISwitch (FWUIKit)

- (CGSize)fw_preferredSize
{
    CGSize size = self.bounds.size;
    if (size.height <= 0) {
        size = [self sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
        if (size.height <= 0) size = CGSizeMake(51, 31);
    }
    return size;
}

- (void)setFw_preferredSize:(CGSize)size
{
    CGFloat height = [self fw_preferredSize].height;
    CGFloat scale = size.height / height;
    self.transform = CGAffineTransformMakeScale(scale, scale);
}

@end

#pragma mark - UITextField+FWUIKit

@interface FWInnerInputTarget : NSObject

@property (nonatomic, weak, readonly) UIView<UITextInput> *textInput;
@property (nonatomic, weak, readonly) UITextField *textField;
@property (nonatomic, assign) NSInteger maxLength;
@property (nonatomic, assign) NSInteger maxUnicodeLength;
@property (nonatomic, copy) void (^textChangedBlock)(NSString *text);
@property (nonatomic, assign) NSTimeInterval autoCompleteInterval;
@property (nonatomic, assign) NSTimeInterval autoCompleteTimestamp;
@property (nonatomic, copy) void (^autoCompleteBlock)(NSString *text);

@end

@implementation FWInnerInputTarget

- (instancetype)initWithTextInput:(UIView<UITextInput> *)textInput
{
    self = [super init];
    if (self) {
        _textInput = textInput;
        _autoCompleteInterval = 0.5;
    }
    return self;
}

- (UITextField *)textField
{
    return (UITextField *)self.textInput;
}

- (void)setAutoCompleteInterval:(NSTimeInterval)interval
{
    _autoCompleteInterval = interval > 0 ? interval : 0.5;
}

- (void)textLengthChanged
{
    if (self.maxLength > 0) {
        if (self.textInput.markedTextRange) {
            if (![self.textInput positionFromPosition:self.textInput.markedTextRange.start offset:0]) {
                if (self.textField.text.length > self.maxLength) {
                    // 获取maxLength处的整个字符range，并截取掉整个字符，防止半个Emoji
                    NSRange maxRange = [self.textField.text rangeOfComposedCharacterSequenceAtIndex:self.maxLength];
                    self.textField.text = [self.textField.text substringToIndex:maxRange.location];
                    // 此方法会导致末尾出现半个Emoji
                    // self.textField.text = [self.textField.text substringToIndex:self.maxLength];
                }
            }
        } else {
            if (self.textField.text.length > self.maxLength) {
                // 获取fwMaxLength处的整个字符range，并截取掉整个字符，防止半个Emoji
                NSRange maxRange = [self.textField.text rangeOfComposedCharacterSequenceAtIndex:self.maxLength];
                self.textField.text = [self.textField.text substringToIndex:maxRange.location];
                // 此方法会导致末尾出现半个Emoji
                // self.textField.text = [self.textField.text substringToIndex:self.maxLength];
            }
        }
    }
    
    if (self.maxUnicodeLength > 0) {
        if (self.textInput.markedTextRange) {
            if (![self.textInput positionFromPosition:self.textInput.markedTextRange.start offset:0]) {
                if ([self.textField.text fw_unicodeLength] > self.maxUnicodeLength) {
                    self.textField.text = [self.textField.text fw_unicodeSubstring:self.maxUnicodeLength];
                }
            }
        } else {
            if ([self.textField.text fw_unicodeLength] > self.maxUnicodeLength) {
                self.textField.text = [self.textField.text fw_unicodeSubstring:self.maxUnicodeLength];
            }
        }
    }
}

- (NSString *)filterText:(NSString *)text
{
    NSString *filterText = text;
    
    if (self.maxLength > 0) {
        if (self.textInput.markedTextRange) {
            if (![self.textInput positionFromPosition:self.textInput.markedTextRange.start offset:0]) {
                if (filterText.length > self.maxLength) {
                    // 获取maxLength处的整个字符range，并截取掉整个字符，防止半个Emoji
                    NSRange maxRange = [filterText rangeOfComposedCharacterSequenceAtIndex:self.maxLength];
                    filterText = [filterText substringToIndex:maxRange.location];
                    // 此方法会导致末尾出现半个Emoji
                    // filterText = [filterText substringToIndex:self.maxLength];
                }
            }
        } else {
            if (filterText.length > self.maxLength) {
                // 获取fwMaxLength处的整个字符range，并截取掉整个字符，防止半个Emoji
                NSRange maxRange = [filterText rangeOfComposedCharacterSequenceAtIndex:self.maxLength];
                filterText = [filterText substringToIndex:maxRange.location];
                // 此方法会导致末尾出现半个Emoji
                // filterText = [filterText substringToIndex:self.maxLength];
            }
        }
    }
    
    if (self.maxUnicodeLength > 0) {
        if (self.textInput.markedTextRange) {
            if (![self.textInput positionFromPosition:self.textInput.markedTextRange.start offset:0]) {
                if ([filterText fw_unicodeLength] > self.maxUnicodeLength) {
                    filterText = [filterText fw_unicodeSubstring:self.maxUnicodeLength];
                }
            }
        } else {
            if ([filterText fw_unicodeLength] > self.maxUnicodeLength) {
                filterText = [filterText fw_unicodeSubstring:self.maxUnicodeLength];
            }
        }
    }
    
    return filterText;
}

- (void)textChangedAction
{
    [self textLengthChanged];
    
    if (self.textChangedBlock) {
        NSString *inputText = self.textField.text.fw_trimString;
        self.textChangedBlock(inputText ?: @"");
    }
    
    if (self.autoCompleteBlock) {
        self.autoCompleteTimestamp = [[NSDate date] timeIntervalSince1970];
        NSString *inputText = self.textField.text.fw_trimString;
        if (inputText.length < 1) {
            self.autoCompleteBlock(@"");
        } else {
            NSTimeInterval currentTimestamp = self.autoCompleteTimestamp;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.autoCompleteInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (currentTimestamp == self.autoCompleteTimestamp) {
                    self.autoCompleteBlock(inputText);
                }
            });
        }
    }
}

@end

@implementation UITextField (FWUIKit)

- (NSInteger)fw_maxLength
{
    return [self fw_innerInputTarget:NO].maxLength;
}

- (void)setFw_maxLength:(NSInteger)maxLength
{
    [self fw_innerInputTarget:YES].maxLength = maxLength;
}

- (NSInteger)fw_maxUnicodeLength
{
    return [self fw_innerInputTarget:NO].maxUnicodeLength;
}

- (void)setFw_maxUnicodeLength:(NSInteger)maxUnicodeLength
{
    [self fw_innerInputTarget:YES].maxUnicodeLength = maxUnicodeLength;
}

- (void (^)(NSString *))fw_textChangedBlock
{
    return [self fw_innerInputTarget:NO].textChangedBlock;
}

- (void)setFw_textChangedBlock:(void (^)(NSString *))textChangedBlock
{
    [self fw_innerInputTarget:YES].textChangedBlock = textChangedBlock;
}

- (void)fw_textLengthChanged
{
    [[self fw_innerInputTarget:NO] textLengthChanged];
}

- (NSString *)fw_filterText:(NSString *)text
{
    FWInnerInputTarget *target = [self fw_innerInputTarget:NO];
    return target ? [target filterText:text] : text;
}

- (NSTimeInterval)fw_autoCompleteInterval
{
    return [self fw_innerInputTarget:NO].autoCompleteInterval;
}

- (void)setFw_autoCompleteInterval:(NSTimeInterval)autoCompleteInterval
{
    [self fw_innerInputTarget:YES].autoCompleteInterval = autoCompleteInterval;
}

- (void (^)(NSString *))fw_autoCompleteBlock
{
    return [self fw_innerInputTarget:NO].autoCompleteBlock;
}

- (void)setFw_autoCompleteBlock:(void (^)(NSString *))autoCompleteBlock
{
    [self fw_innerInputTarget:YES].autoCompleteBlock = autoCompleteBlock;
}

- (FWInnerInputTarget *)fw_innerInputTarget:(BOOL)lazyload
{
    FWInnerInputTarget *target = objc_getAssociatedObject(self, _cmd);
    if (!target && lazyload) {
        target = [[FWInnerInputTarget alloc] initWithTextInput:self];
        if ([self isKindOfClass:[UITextField class]]) {
            [self addTarget:target action:@selector(textChangedAction) forControlEvents:UIControlEventEditingChanged];
        }
        objc_setAssociatedObject(self, _cmd, target, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return target;
}

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWSwizzleClass(UITextField, @selector(canPerformAction:withSender:), FWSwizzleReturn(BOOL), FWSwizzleArgs(SEL action, id sender), FWSwizzleCode({
            if (selfObject.fw_menuDisabled) {
                return NO;
            }
            return FWSwizzleOriginal(action, sender);
        }));
        
        FWSwizzleClass(UITextField, @selector(caretRectForPosition:), FWSwizzleReturn(CGRect), FWSwizzleArgs(UITextPosition *position), FWSwizzleCode({
            CGRect caretRect = FWSwizzleOriginal(position);
            NSValue *rectValue = objc_getAssociatedObject(selfObject, @selector(fw_cursorRect));
            if (!rectValue) return caretRect;
            
            CGRect rect = rectValue.CGRectValue;
            if (rect.origin.x != 0) caretRect.origin.x += rect.origin.x;
            if (rect.origin.y != 0) caretRect.origin.y += rect.origin.y;
            if (rect.size.width != 0) caretRect.size.width = rect.size.width;
            if (rect.size.height != 0) caretRect.size.height = rect.size.height;
            return caretRect;
        }));
    });
}

- (BOOL)fw_menuDisabled
{
    return [objc_getAssociatedObject(self, @selector(fw_menuDisabled)) boolValue];
}

- (void)setFw_menuDisabled:(BOOL)menuDisabled
{
    objc_setAssociatedObject(self, @selector(fw_menuDisabled), @(menuDisabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGRect)fw_cursorRect
{
    NSValue *value = objc_getAssociatedObject(self, @selector(fw_cursorRect));
    return value ? [value CGRectValue] : CGRectZero;
}

- (void)setFw_cursorRect:(CGRect)cursorRect
{
    objc_setAssociatedObject(self, @selector(fw_cursorRect), [NSValue valueWithCGRect:cursorRect], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSRange)fw_selectedRange
{
    UITextPosition *beginning = self.beginningOfDocument;
    
    UITextRange *selectedRange = self.selectedTextRange;
    UITextPosition *selectionStart = selectedRange.start;
    UITextPosition *selectionEnd = selectedRange.end;
    
    NSInteger location = [self offsetFromPosition:beginning toPosition:selectionStart];
    NSInteger length = [self offsetFromPosition:selectionStart toPosition:selectionEnd];
    
    return NSMakeRange(location, length);
}

- (void)setFw_selectedRange:(NSRange)range
{
    UITextPosition *beginning = self.beginningOfDocument;
    UITextPosition *startPosition = [self positionFromPosition:beginning offset:range.location];
    UITextPosition *endPosition = [self positionFromPosition:beginning offset:NSMaxRange(range)];
    UITextRange *selectionRange = [self textRangeFromPosition:startPosition toPosition:endPosition];
    [self setSelectedTextRange:selectionRange];
}

- (void)fw_selectAllRange
{
    UITextRange *range = [self textRangeFromPosition:self.beginningOfDocument toPosition:self.endOfDocument];
    [self setSelectedTextRange:range];
}

- (void)fw_moveCursor:(NSInteger)offset
{
    __weak UITextField *weakBase = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        UITextPosition *position = [weakBase positionFromPosition:weakBase.beginningOfDocument offset:offset];
        weakBase.selectedTextRange = [weakBase textRangeFromPosition:position toPosition:position];
    });
}

@end

#pragma mark - UITextView+FWUIKit

@implementation UITextView (FWUIKit)

- (NSInteger)fw_maxLength
{
    return [self fw_innerInputTarget:NO].maxLength;
}

- (void)setFw_maxLength:(NSInteger)maxLength
{
    [self fw_innerInputTarget:YES].maxLength = maxLength;
}

- (NSInteger)fw_maxUnicodeLength
{
    return [self fw_innerInputTarget:NO].maxUnicodeLength;
}

- (void)setFw_maxUnicodeLength:(NSInteger)maxUnicodeLength
{
    [self fw_innerInputTarget:YES].maxUnicodeLength = maxUnicodeLength;
}

- (void (^)(NSString *))fw_textChangedBlock
{
    return [self fw_innerInputTarget:NO].textChangedBlock;
}

- (void)setFw_textChangedBlock:(void (^)(NSString *))textChangedBlock
{
    [self fw_innerInputTarget:YES].textChangedBlock = textChangedBlock;
}

- (void)fw_textLengthChanged
{
    [[self fw_innerInputTarget:NO] textLengthChanged];
}

- (NSString *)fw_filterText:(NSString *)text
{
    FWInnerInputTarget *target = [self fw_innerInputTarget:NO];
    return target ? [target filterText:text] : text;
}

- (NSTimeInterval)fw_autoCompleteInterval
{
    return [self fw_innerInputTarget:NO].autoCompleteInterval;
}

- (void)setFw_autoCompleteInterval:(NSTimeInterval)autoCompleteInterval
{
    [self fw_innerInputTarget:YES].autoCompleteInterval = autoCompleteInterval;
}

- (void (^)(NSString *))fw_autoCompleteBlock
{
    return [self fw_innerInputTarget:NO].autoCompleteBlock;
}

- (void)setFw_autoCompleteBlock:(void (^)(NSString *))autoCompleteBlock
{
    [self fw_innerInputTarget:YES].autoCompleteBlock = autoCompleteBlock;
}

- (FWInnerInputTarget *)fw_innerInputTarget:(BOOL)lazyload
{
    FWInnerInputTarget *target = objc_getAssociatedObject(self, _cmd);
    if (!target && lazyload) {
        target = [[FWInnerInputTarget alloc] initWithTextInput:self];
        if ([self isKindOfClass:[UITextView class]]) {
            [self fw_observeNotification:UITextViewTextDidChangeNotification object:self target:target action:@selector(textChangedAction)];
        }
        objc_setAssociatedObject(self, _cmd, target, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return target;
}

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWSwizzleClass(UITextView, @selector(canPerformAction:withSender:), FWSwizzleReturn(BOOL), FWSwizzleArgs(SEL action, id sender), FWSwizzleCode({
            if (selfObject.fw_menuDisabled) {
                return NO;
            }
            return FWSwizzleOriginal(action, sender);
        }));
        
        FWSwizzleClass(UITextView, @selector(caretRectForPosition:), FWSwizzleReturn(CGRect), FWSwizzleArgs(UITextPosition *position), FWSwizzleCode({
            CGRect caretRect = FWSwizzleOriginal(position);
            NSValue *rectValue = objc_getAssociatedObject(selfObject, @selector(fw_cursorRect));
            if (!rectValue) return caretRect;
            NSLog(@"rect: %@", NSStringFromCGRect(caretRect));
            
            CGRect rect = rectValue.CGRectValue;
            if (rect.origin.x != 0) caretRect.origin.x += rect.origin.x;
            if (rect.origin.y != 0) caretRect.origin.y += rect.origin.y;
            if (rect.size.width != 0) caretRect.size.width = rect.size.width;
            if (rect.size.height != 0) caretRect.size.height = rect.size.height;
            return caretRect;
        }));
    });
}

- (BOOL)fw_menuDisabled
{
    return [objc_getAssociatedObject(self, @selector(fw_menuDisabled)) boolValue];
}

- (void)setFw_menuDisabled:(BOOL)menuDisabled
{
    objc_setAssociatedObject(self, @selector(fw_menuDisabled), @(menuDisabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGRect)fw_cursorRect
{
    NSValue *value = objc_getAssociatedObject(self, @selector(fw_cursorRect));
    return value ? [value CGRectValue] : CGRectZero;
}

- (void)setFw_cursorRect:(CGRect)cursorRect
{
    objc_setAssociatedObject(self, @selector(fw_cursorRect), [NSValue valueWithCGRect:cursorRect], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSRange)fw_selectedRange
{
    UITextPosition *beginning = self.beginningOfDocument;
    
    UITextRange *selectedRange = self.selectedTextRange;
    UITextPosition *selectionStart = selectedRange.start;
    UITextPosition *selectionEnd = selectedRange.end;
    
    NSInteger location = [self offsetFromPosition:beginning toPosition:selectionStart];
    NSInteger length = [self offsetFromPosition:selectionStart toPosition:selectionEnd];
    
    return NSMakeRange(location, length);
}

- (void)setFw_selectedRange:(NSRange)range
{
    UITextPosition *beginning = self.beginningOfDocument;
    UITextPosition *startPosition = [self positionFromPosition:beginning offset:range.location];
    UITextPosition *endPosition = [self positionFromPosition:beginning offset:NSMaxRange(range)];
    UITextRange *selectionRange = [self textRangeFromPosition:startPosition toPosition:endPosition];
    [self setSelectedTextRange:selectionRange];
}

- (void)fw_selectAllRange
{
    UITextRange *range = [self textRangeFromPosition:self.beginningOfDocument toPosition:self.endOfDocument];
    [self setSelectedTextRange:range];
}

- (void)fw_moveCursor:(NSInteger)offset
{
    __weak UITextView *weakBase = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        UITextPosition *position = [weakBase positionFromPosition:weakBase.beginningOfDocument offset:offset];
        weakBase.selectedTextRange = [weakBase textRangeFromPosition:position toPosition:position];
    });
}

- (CGSize)fw_textSize
{
    if (CGSizeEqualToSize(self.frame.size, CGSizeZero)) {
        [self setNeedsLayout];
        [self layoutIfNeeded];
    }
    
    NSMutableDictionary *attr = [[NSMutableDictionary alloc] init];
    attr[NSFontAttributeName] = self.font;
    
    CGSize drawSize = CGSizeMake(self.frame.size.width, CGFLOAT_MAX);
    CGSize size = [self.text boundingRectWithSize:drawSize
                                          options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin
                                       attributes:attr
                                          context:nil].size;
    return CGSizeMake(MIN(drawSize.width, ceilf(size.width)) + self.textContainerInset.left + self.textContainerInset.right, MIN(drawSize.height, ceilf(size.height)) + self.textContainerInset.top + self.textContainerInset.bottom);
}

- (CGSize)fw_attributedTextSize
{
    if (CGSizeEqualToSize(self.frame.size, CGSizeZero)) {
        [self setNeedsLayout];
        [self layoutIfNeeded];
    }
    
    CGSize drawSize = CGSizeMake(self.frame.size.width, CGFLOAT_MAX);
    CGSize size = [self.attributedText boundingRectWithSize:drawSize
                                                    options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin
                                                    context:nil].size;
    return CGSizeMake(MIN(drawSize.width, ceilf(size.width)) + self.textContainerInset.left + self.textContainerInset.right, MIN(drawSize.height, ceilf(size.height)) + self.textContainerInset.top + self.textContainerInset.bottom);
}

@end

#pragma mark - UITableView+FWUIKit

@implementation UITableView (FWUIKit)

+ (void)fw_resetTableStyle
{
    if (@available(iOS 15.0, *)) {
        UITableView.appearance.sectionHeaderTopPadding = 0;
    }
}

- (BOOL)fw_estimatedLayout
{
    return self.estimatedRowHeight == UITableViewAutomaticDimension;
}

- (void)setFw_estimatedLayout:(BOOL)enabled
{
    if (enabled) {
        self.estimatedRowHeight = UITableViewAutomaticDimension;
        self.estimatedSectionHeaderHeight = UITableViewAutomaticDimension;
        self.estimatedSectionFooterHeight = UITableViewAutomaticDimension;
    } else {
        self.estimatedRowHeight = 0.f;
        self.estimatedSectionHeaderHeight = 0.f;
        self.estimatedSectionFooterHeight = 0.f;
    }
}

- (void)fw_resetTableStyle
{
    self.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, CGFLOAT_MIN)];
    self.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, CGFLOAT_MIN)];
    if (@available(iOS 15.0, *)) {
        self.sectionHeaderTopPadding = 0;
    }
}

- (void)fw_reloadDataWithCompletion:(void (^)(void))completion
{
    [UIView animateWithDuration:0 animations:^{
        [self reloadData];
    } completion:^(BOOL finished) {
        if (completion) {
            completion();
        }
    }];
}

- (void)fw_reloadDataWithoutAnimation
{
    [UIView performWithoutAnimation:^{
        [self reloadData];
    }];
}

@end

#pragma mark - UITableViewCell+FWUIKit

@implementation UITableViewCell (FWUIKit)

- (UIEdgeInsets)fw_separatorInset
{
    return self.separatorInset;
}

- (void)setFw_separatorInset:(UIEdgeInsets)separatorInset
{
    self.separatorInset = separatorInset;
    self.preservesSuperviewLayoutMargins = NO;
    self.layoutMargins = separatorInset;
}

- (UITableView *)fw_tableView
{
    UIView *superview = self.superview;
    while (superview) {
        if ([superview isKindOfClass:[UITableView class]]) {
            return (UITableView *)superview;
        }
        superview = superview.superview;
    }
    return nil;
}

- (NSIndexPath *)fw_indexPath
{
    return [[self fw_tableView] indexPathForCell:self];
}

@end

#pragma mark - UICollectionView+FWUIKit

@implementation UICollectionView (FWUIKit)

- (void)fw_reloadDataWithCompletion:(void (^)(void))completion
{
    [UIView animateWithDuration:0 animations:^{
        [self reloadData];
    } completion:^(BOOL finished) {
        if (completion) {
            completion();
        }
    }];
}

- (void)fw_reloadDataWithoutAnimation
{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [self reloadData];
    [CATransaction commit];
}

@end

#pragma mark - UICollectionViewCell+FWUIKit

@implementation UICollectionViewCell (FWUIKit)

- (UICollectionView *)fw_collectionView
{
    UIView *superview = self.superview;
    while (superview) {
        if ([superview isKindOfClass:[UICollectionView class]]) {
            return (UICollectionView *)superview;
        }
        superview = superview.superview;
    }
    return nil;
}

- (NSIndexPath *)fw_indexPath
{
    return [[self fw_collectionView] indexPathForCell:self];
}

@end

#pragma mark - UISearchBar+FWUIKit

@implementation UISearchBar (FWUIKit)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWSwizzleClass(UISearchBar, @selector(layoutSubviews), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            FWSwizzleOriginal();
            
            if (@available(iOS 13, *)) { } else {
                CGFloat textFieldMaxX = selfObject.bounds.size.width;
                NSValue *cancelInsetValue = objc_getAssociatedObject(selfObject, @selector(fw_cancelButtonInset));
                if (cancelInsetValue) {
                    UIButton *cancelButton = [selfObject fw_cancelButton];
                    if (cancelButton) {
                        UIEdgeInsets cancelInset = [cancelInsetValue UIEdgeInsetsValue];
                        CGFloat cancelWidth = [cancelButton sizeThatFits:selfObject.bounds.size].width;
                        textFieldMaxX = selfObject.bounds.size.width - cancelWidth - cancelInset.left - cancelInset.right;
                        UITextField *textField = [selfObject fw_textField];
                        CGRect frame = textField.frame;
                        frame.size.width = textFieldMaxX - frame.origin.x;
                        textField.frame = frame;
                    }
                }
                
                NSValue *contentInsetValue = objc_getAssociatedObject(selfObject, @selector(fw_contentInset));
                if (contentInsetValue) {
                    UIEdgeInsets contentInset = [contentInsetValue UIEdgeInsetsValue];
                    UITextField *textField = [selfObject fw_textField];
                    textField.frame = CGRectMake(contentInset.left, contentInset.top, textFieldMaxX - contentInset.left - contentInset.right, selfObject.bounds.size.height - contentInset.top - contentInset.bottom);
                }
            }
            
            NSNumber *isCenterValue = objc_getAssociatedObject(selfObject, @selector(fw_searchIconCenter));
            if (isCenterValue) {
                if (![isCenterValue boolValue]) {
                    NSNumber *offset = objc_getAssociatedObject(selfObject, @selector(fw_searchIconOffset));
                    [selfObject setPositionAdjustment:UIOffsetMake(offset ? offset.doubleValue : 0, 0) forSearchBarIcon:UISearchBarIconSearch];
                } else {
                    UITextField *textField = [selfObject fw_textField];
                    CGFloat placeholdWidth = [selfObject.placeholder boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:[NSDictionary dictionaryWithObjectsAndKeys:textField.font, NSFontAttributeName, nil] context:nil].size.width;
                    CGFloat textOffset = 4 + [selfObject searchTextPositionAdjustment].horizontal;
                    CGFloat iconWidth = textField.leftView ? textField.leftView.frame.size.width : 0;
                    CGFloat targetWidth = textField.frame.size.width - ceilf(placeholdWidth) - textOffset - iconWidth;
                    CGFloat position = targetWidth / 2 - 6;
                    [selfObject setPositionAdjustment:UIOffsetMake(position > 0 ? position : 0, 0) forSearchBarIcon:UISearchBarIconSearch];
                }
            }
        }));
        
        // iOS13因为层级关系变化，兼容处理
        if (@available(iOS 13, *)) {
            FWSwizzleMethod(objc_getClass("UISearchBarTextField"), @selector(setFrame:), nil, FWSwizzleType(UITextField *), FWSwizzleReturn(void), FWSwizzleArgs(CGRect frame), FWSwizzleCode({
                UISearchBar *searchBar = nil;
                if (@available(iOS 13.0, *)) {
                    searchBar = (UISearchBar *)selfObject.superview.superview.superview;
                } else {
                    searchBar = (UISearchBar *)selfObject.superview.superview;
                }
                if ([searchBar isKindOfClass:[UISearchBar class]]) {
                    CGFloat textFieldMaxX = searchBar.bounds.size.width;
                    NSValue *cancelInsetValue = objc_getAssociatedObject(searchBar, @selector(fw_cancelButtonInset));
                    if (cancelInsetValue) {
                        UIButton *cancelButton = [searchBar fw_cancelButton];
                        if (cancelButton) {
                            UIEdgeInsets cancelInset = [cancelInsetValue UIEdgeInsetsValue];
                            CGFloat cancelWidth = [cancelButton sizeThatFits:searchBar.bounds.size].width;
                            textFieldMaxX = searchBar.bounds.size.width - cancelWidth - cancelInset.left - cancelInset.right;
                            frame.size.width = textFieldMaxX - frame.origin.x;
                        }
                    }
                    
                    NSValue *contentInsetValue = objc_getAssociatedObject(searchBar, @selector(fw_contentInset));
                    if (contentInsetValue) {
                        UIEdgeInsets contentInset = [contentInsetValue UIEdgeInsetsValue];
                        frame = CGRectMake(contentInset.left, contentInset.top, textFieldMaxX - contentInset.left - contentInset.right, searchBar.bounds.size.height - contentInset.top - contentInset.bottom);
                    }
                }
                
                FWSwizzleOriginal(frame);
            }));
        }
        
        FWSwizzleMethod(objc_getClass("UINavigationButton"), @selector(setFrame:), nil, FWSwizzleType(UIButton *), FWSwizzleReturn(void), FWSwizzleArgs(CGRect frame), FWSwizzleCode({
            UISearchBar *searchBar = nil;
            if (@available(iOS 13.0, *)) {
                searchBar = (UISearchBar *)selfObject.superview.superview.superview;
            } else {
                searchBar = (UISearchBar *)selfObject.superview.superview;
            }
            if ([searchBar isKindOfClass:[UISearchBar class]]) {
                NSValue *cancelButtonInsetValue = objc_getAssociatedObject(searchBar, @selector(fw_cancelButtonInset));
                if (cancelButtonInsetValue) {
                    UIEdgeInsets cancelButtonInset = [cancelButtonInsetValue UIEdgeInsetsValue];
                    CGFloat cancelButtonWidth = [selfObject sizeThatFits:searchBar.bounds.size].width;
                    frame.origin.x = searchBar.bounds.size.width - cancelButtonWidth - cancelButtonInset.right;
                    frame.origin.y = cancelButtonInset.top;
                    frame.size.height = searchBar.bounds.size.height - cancelButtonInset.top - cancelButtonInset.bottom;
                }
            }
            
            FWSwizzleOriginal(frame);
        }));
    });
}

- (UIEdgeInsets)fw_contentInset
{
    return [objc_getAssociatedObject(self, @selector(fw_contentInset)) UIEdgeInsetsValue];
}

- (void)setFw_contentInset:(UIEdgeInsets)contentInset
{
    objc_setAssociatedObject(self, @selector(fw_contentInset), [NSValue valueWithUIEdgeInsets:contentInset], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self setNeedsLayout];
}

- (UIEdgeInsets)fw_cancelButtonInset
{
    return [objc_getAssociatedObject(self, @selector(fw_cancelButtonInset)) UIEdgeInsetsValue];
}

- (void)setFw_cancelButtonInset:(UIEdgeInsets)cancelButtonInset
{
    objc_setAssociatedObject(self, @selector(fw_cancelButtonInset), [NSValue valueWithUIEdgeInsets:cancelButtonInset], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self setNeedsLayout];
}

- (UITextField *)fw_textField
{
    return [self fw_invokeGetter:@"searchField"];
}

- (UIButton *)fw_cancelButton
{
    return [self fw_invokeGetter:@"cancelButton"];
}

- (UIColor *)fw_backgroundColor
{
    return objc_getAssociatedObject(self, @selector(fw_backgroundColor));
}

- (void)setFw_backgroundColor:(UIColor *)color
{
    objc_setAssociatedObject(self, @selector(fw_backgroundColor), color, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    self.backgroundImage = [UIImage fw_imageWithColor:color];
}

- (UIColor *)fw_textFieldBackgroundColor
{
    UITextField *textField = [self fw_textField];
    return textField.backgroundColor;
}

- (void)setFw_textFieldBackgroundColor:(UIColor *)color
{
    UITextField *textField = [self fw_textField];
    textField.backgroundColor = color;
}

- (CGFloat)fw_searchIconOffset
{
    NSNumber *value = objc_getAssociatedObject(self, @selector(fw_searchIconOffset));
    if (value) return value.doubleValue;
    return [self positionAdjustmentForSearchBarIcon:UISearchBarIconSearch].horizontal;
}

- (void)setFw_searchIconOffset:(CGFloat)offset
{
    objc_setAssociatedObject(self, @selector(fw_searchIconOffset), @(offset), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self setPositionAdjustment:UIOffsetMake(offset, 0) forSearchBarIcon:UISearchBarIconSearch];
}

- (CGFloat)fw_searchTextOffset
{
    return [self searchTextPositionAdjustment].horizontal;
}

- (void)setFw_searchTextOffset:(CGFloat)offset
{
    [self setSearchTextPositionAdjustment:UIOffsetMake(offset, 0)];
}

- (BOOL)fw_searchIconCenter
{
    return [objc_getAssociatedObject(self, @selector(fw_searchIconCenter)) boolValue];
}

- (void)setFw_searchIconCenter:(BOOL)center
{
    objc_setAssociatedObject(self, @selector(fw_searchIconCenter), @(center), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (BOOL)fw_forceCancelButtonEnabled
{
    return [objc_getAssociatedObject(self, @selector(fw_forceCancelButtonEnabled)) boolValue];
}

- (void)setFw_forceCancelButtonEnabled:(BOOL)enabled
{
    objc_setAssociatedObject(self, @selector(fw_forceCancelButtonEnabled), @(enabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    UIButton *cancelButton = [self fw_cancelButton];
    if (enabled) {
        cancelButton.enabled = YES;
        [cancelButton fw_observeProperty:@"enabled" block:^(UIButton *object, NSDictionary *change) {
            if (!object.enabled) object.enabled = YES;
        }];
    } else {
        [cancelButton fw_unobserveProperty:@"enabled"];
    }
}

@end

#pragma mark - UIViewController+FWUIKit

@implementation UIViewController (FWUIKit)

- (BOOL)fw_isRoot
{
    return !self.navigationController || self.navigationController.viewControllers.firstObject == self;
}

- (BOOL)fw_isChild
{
    UIViewController *parentController = self.parentViewController;
    if (parentController && ![parentController isKindOfClass:[UINavigationController class]] &&
        ![parentController isKindOfClass:[UITabBarController class]]) {
        return YES;
    }
    return NO;
}

- (BOOL)fw_isPresented
{
    UIViewController *viewController = self;
    if (self.navigationController) {
        if (self.navigationController.viewControllers.firstObject != self) return NO;
        viewController = self.navigationController;
    }
    return viewController.presentingViewController.presentedViewController == viewController;
}

- (BOOL)fw_isPageSheet
{
    if (@available(iOS 13.0, *)) {
        UIViewController *controller = self.navigationController ?: self;
        if (!controller.presentingViewController) return NO;
        UIModalPresentationStyle style = controller.modalPresentationStyle;
        if (style == UIModalPresentationAutomatic || style == UIModalPresentationPageSheet) return YES;
    }
    return NO;
}

- (BOOL)fw_isViewVisible
{
    return self.isViewLoaded && self.view.window;
}

- (UIView *)fw_ancestorView
{
    if (self.tabBarController.navigationController) {
        return self.tabBarController.navigationController.view;
    } else if (self.tabBarController) {
        return self.tabBarController.view;
    } else if (self.navigationController) {
        return self.navigationController.view;
    } else {
        return self.view;
    }
}

- (BOOL)fw_isDataLoaded
{
    return [objc_getAssociatedObject(self, @selector(fw_isDataLoaded)) boolValue];
}

- (void)setFw_isDataLoaded:(BOOL)isDataLoaded
{
    objc_setAssociatedObject(self, @selector(fw_isDataLoaded), @(isDataLoaded), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)fw_addChildViewController:(UIViewController *)viewController
{
    [self fw_addChildViewController:viewController inView:nil layout:nil];
}

- (void)fw_addChildViewController:(UIViewController *)viewController inView:(UIView *)view layout:(__attribute__((noescape)) void (^)(UIView *))layout
{
    [self addChildViewController:viewController];
    UIView *superview = view ?: self.view;
    [superview addSubview:viewController.view];
    if (layout != nil) {
        layout(viewController.view);
    } else {
        // viewController.view.frame = superview.bounds;
        [viewController.view fw_pinEdgesToSuperview];
    }
    [viewController didMoveToParentViewController:self];
}

- (void)fw_removeChildViewController:(UIViewController *)viewController
{
    [viewController willMoveToParentViewController:nil];
    [viewController removeFromParentViewController];
    [viewController.view removeFromSuperview];
}

@end
