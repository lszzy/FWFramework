//
//  FWUIKit.m
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import "FWUIKit.h"
#import "FWSwizzle.h"
#import "FWToolkit.h"
#import "FWEncode.h"
#import <objc/runtime.h>
#import <sys/sysctl.h>
#import <CoreImage/CoreImage.h>

#if FWMacroSPM

@interface UIView ()

- (NSArray<NSLayoutConstraint *> *)fw_pinEdgesToSuperview:(UIEdgeInsets)insets;
- (NSArray<NSLayoutConstraint *> *)fw_setDimensions:(CGSize)size;
- (NSLayoutConstraint *)fw_setDimension:(NSLayoutAttribute)dimension size:(CGFloat)size relation:(NSLayoutRelation)relation priority:(UILayoutPriority)priority;
- (NSLayoutConstraint *)fw_pinEdgeToSuperview:(NSLayoutAttribute)edge inset:(CGFloat)inset relation:(NSLayoutRelation)relation priority:(UILayoutPriority)priority;

@end

@interface NSObject ()

- (NSString *)fw_observeProperty:(NSString *)property block:(void (^)(id object, NSDictionary<NSKeyValueChangeKey, id> *change))block;
- (void)fw_unobserveProperty:(NSString *)property;
- (NSString *)fw_observeNotification:(NSNotificationName)name object:(nullable id)object target:(nullable id)target action:(SEL)action;
+ (BOOL)fw_swizzleMethod:(nullable id)target selector:(SEL)originalSelector identifier:(nullable NSString *)identifier block:(id (^)(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)))block;
+ (BOOL)fw_exchangeInstanceMethod:(SEL)originalSelector swizzleMethod:(SEL)swizzleSelector;
- (nullable id)fw_invokeGetter:(NSString *)name;

@end

@interface NSDate ()

@property (class, nonatomic, assign) NSTimeInterval fw_currentTime;

@end

@interface UIImage ()

+ (nullable UIImage *)fw_imageWithView:(UIView *)view;
+ (nullable UIImage *)fw_imageWithSize:(CGSize)size block:(void (NS_NOESCAPE ^)(CGContextRef context))block;
+ (nullable UIImage *)fw_imageWithColor:(UIColor *)color;

@end

#else

#import <FWFramework/FWFramework-Swift.h>

#endif

#pragma mark - UIImageView+FWUIKit

@implementation UIImageView (FWUIKit)

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

- (__kindof UIViewController *)fw_selectTabBarIndex:(NSUInteger)index
{
    UITabBarController *tabbarController = [self fw_rootTabBarController];
    if (!tabbarController) return nil;
    
    UINavigationController *targetNavigation = nil;
    if (tabbarController.viewControllers.count > index) {
        targetNavigation = tabbarController.viewControllers[index];
    }
    if (!targetNavigation) return nil;
    
    return [self fw_selectTabBar:tabbarController navigation:targetNavigation];
}

- (__kindof UIViewController *)fw_selectTabBarController:(Class)viewController
{
    UITabBarController *tabbarController = [self fw_rootTabBarController];
    if (!tabbarController) return nil;
    
    UINavigationController *targetNavigation = nil;
    for (UINavigationController *navigationController in tabbarController.viewControllers) {
        if ([navigationController isKindOfClass:viewController] ||
            ([navigationController isKindOfClass:[UINavigationController class]] &&
             [navigationController.viewControllers.firstObject isKindOfClass:viewController])) {
            targetNavigation = navigationController;
            break;
        }
    }
    if (!targetNavigation) return nil;
    
    return [self fw_selectTabBar:tabbarController navigation:targetNavigation];
}

- (__kindof UIViewController *)fw_selectTabBarBlock:(__attribute__((noescape)) BOOL (^)(__kindof UIViewController *))block
{
    UITabBarController *tabbarController = [self fw_rootTabBarController];
    if (!tabbarController) return nil;
    
    UINavigationController *targetNavigation = nil;
    for (UINavigationController *navigationController in tabbarController.viewControllers) {
        UIViewController *viewController = navigationController;
        if ([navigationController isKindOfClass:[UINavigationController class]]) {
            viewController = navigationController.viewControllers.firstObject;
        }
        if (viewController && block(viewController)) {
            targetNavigation = navigationController;
            break;
        }
    }
    if (!targetNavigation) return nil;
    
    return [self fw_selectTabBar:tabbarController navigation:targetNavigation];
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

- (UIViewController *)fw_selectTabBar:(UITabBarController *)tabbarController navigation:(UINavigationController *)targetNavigation
{
    UINavigationController *currentNavigation = tabbarController.selectedViewController;
    if (currentNavigation != targetNavigation) {
        if ([currentNavigation isKindOfClass:[UINavigationController class]] &&
            currentNavigation.viewControllers.count > 1) {
            [currentNavigation popToRootViewControllerAnimated:NO];
        }
        tabbarController.selectedViewController = targetNavigation;
    }
    
    UIViewController *targetController = targetNavigation;
    if ([targetNavigation isKindOfClass:[UINavigationController class]]) {
        targetController = targetNavigation.viewControllers.firstObject;
        if (targetNavigation.viewControllers.count > 1) {
            [targetNavigation popToRootViewControllerAnimated:NO];
        }
    }
    return targetController;
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

- (NSTimeInterval)fw_touchEventTimestamp
{
    return [objc_getAssociatedObject(self, @selector(fw_touchEventTimestamp)) doubleValue];
}

- (void)setFw_touchEventTimestamp:(NSTimeInterval)timestamp
{
    objc_setAssociatedObject(self, @selector(fw_touchEventTimestamp), @(timestamp), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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
        [contentView fw_pinEdgesToSuperview:UIEdgeInsetsZero];
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
                [view fw_pinEdgeToSuperview:NSLayoutAttributeLeft inset:0 relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
                [view fw_pinEdgeToSuperview:NSLayoutAttributeTop inset:toPosition relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
                [view fw_setDimensions:view.bounds.size];
            }
        }
    } else {
        if (view.superview != fromSuperview) {
            [view removeFromSuperview];
            [fromSuperview addSubview:view]; {
                [view fw_pinEdgesToSuperview:UIEdgeInsetsZero];
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
            if (rect.origin.x != 0) caretRect.origin.x = rect.origin.x;
            if (rect.origin.y != 0) caretRect.origin.y = rect.origin.y;
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
            
            CGRect rect = rectValue.CGRectValue;
            if (rect.origin.x != 0) caretRect.origin.x = rect.origin.x;
            if (rect.origin.y != 0) caretRect.origin.y = rect.origin.y;
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
