//
//  Keyboard.m
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import "Keyboard.h"
#import <objc/runtime.h>

#if FWMacroSPM

@interface UIGestureRecognizer ()

+ (instancetype)__fw_gestureRecognizerWithBlock:(void (^)(id sender))block;

@end

@interface UIBarButtonItem ()

+ (instancetype)__fw_itemWithObject:(nullable id)object target:(nullable id)target action:(nullable SEL)action;
+ (instancetype)__fw_itemWithObject:(nullable id)object block:(nullable void (^)(id sender))block;

@end

#else

#import <FWFramework/FWFramework-Swift.h>

#endif

#pragma mark - __FWKeyboardTarget

static BOOL fwStaticKeyboardShowing = NO;
static CGFloat fwStaticKeyboardOrigin = 0;
static CGFloat fwStaticKeyboardOffset = 0;
static UITapGestureRecognizer *fwStaticKeyboardGesture = nil;

@interface __FWKeyboardTarget ()

@property (nonatomic, strong) UIBarButtonItem *previousItem;
@property (nonatomic, strong) UIBarButtonItem *nextItem;

@property (nonatomic, weak, readonly) UIView<UITextInput> *textInput;
@property (nonatomic, weak) UIViewController *viewController;
@property (nonatomic, assign) BOOL keyboardActive;

@end

@implementation __FWKeyboardTarget

- (instancetype)initWithTextInput:(UIView<UITextInput> *)textInput
{
    self = [super init];
    if (self) {
        _textInput = textInput;
        _keyboardDistance = 10.0;
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Accessor

- (void)setKeyboardManager:(BOOL)keyboardManager
{
    if (keyboardManager == _keyboardManager) return;
    _keyboardManager = keyboardManager;
    
    if (keyboardManager) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    } else {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    }
}

- (void)setTouchResign:(BOOL)touchResign
{
    if (touchResign == _touchResign) return;
    _touchResign = touchResign;
    
    if (touchResign) {
        if ([self.textInput isKindOfClass:[UITextField class]]) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editingDidBegin) name:UITextFieldTextDidBeginEditingNotification object:self.textInput];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editingDidEnd) name:UITextFieldTextDidEndEditingNotification object:self.textInput];
        } else if ([self.textInput isKindOfClass:[UITextView class]]) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editingDidBegin) name:UITextViewTextDidBeginEditingNotification object:self.textInput];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editingDidEnd) name:UITextViewTextDidEndEditingNotification object:self.textInput];
        }
    } else {
        if ([self.textInput isKindOfClass:[UITextField class]]) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidBeginEditingNotification object:self.textInput];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidEndEditingNotification object:self.textInput];
        } else if ([self.textInput isKindOfClass:[UITextView class]]) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidBeginEditingNotification object:self.textInput];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidEndEditingNotification object:self.textInput];
        }
    }
}

- (void)setKeyboardResign:(BOOL)keyboardResign
{
    if (keyboardResign == _keyboardResign) return;
    _keyboardResign = keyboardResign;
    
    if (keyboardResign) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appResignActive) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    } else {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    }
}

- (UIViewController *)viewController
{
    if (!_viewController) {
        _viewController = [self.textInput __fw_viewController];
    }
    return _viewController;
}

#pragma mark - Resign

- (void)editingDidBegin
{
    if (!self.touchResign) return;
    if (!self.viewController) return;
    
    if (!fwStaticKeyboardGesture) {
        fwStaticKeyboardGesture = [UITapGestureRecognizer __fw_gestureRecognizerWithBlock:^(UITapGestureRecognizer *sender) {
            if (sender.state == UIGestureRecognizerStateEnded) {
                [sender.view endEditing:YES];
            }
        }];
        fwStaticKeyboardGesture.cancelsTouchesInView = NO;
    }
    [self.viewController.view addGestureRecognizer:fwStaticKeyboardGesture];
}

- (void)editingDidEnd
{
    if (!self.touchResign) return;
    if (!self.viewController) return;
    
    if (fwStaticKeyboardGesture) {
        [self.viewController.view removeGestureRecognizer:fwStaticKeyboardGesture];
    }
}

- (void)appResignActive
{
    if (!self.keyboardResign) return;
    if (!self.textInput.isFirstResponder) return;
    
    self.keyboardActive = YES;
    [self.textInput resignFirstResponder];
}

- (void)appBecomeActive
{
    if (!self.keyboardResign) return;
    if (!self.keyboardActive) return;
    
    self.keyboardActive = NO;
    [self.textInput becomeFirstResponder];
}

#pragma mark - Action

- (void)invokeReturnAction
{
    // 切换到下一个输入框
    if (self.returnNext) {
        [self goNext];
    // 关闭键盘
    } else if (self.returnResign) {
        [self.textInput resignFirstResponder];
    }
    // 执行回调
    if (self.returnBlock) {
        self.returnBlock(self.textInput);
    }
}

#pragma mark - Keyboard

- (void)keyboardWillShow:(NSNotification *)notification
{
    if (!self.textInput.isFirstResponder) return;
    if (!self.keyboardManager || !self.viewController) return;
    
    if (self.scrollView != nil) {
        if (!fwStaticKeyboardShowing) {
            fwStaticKeyboardShowing = YES;
            fwStaticKeyboardOffset = self.scrollView.contentOffset.y;
        }
        
        CGRect keyboardRect = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
        CGFloat animationDuration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
        NSInteger animationCurve = [[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
        animationCurve = animationCurve << 16;
        UIView *convertView = self.textInput.window ?: self.viewController.view.window;
        CGRect convertRect = [self.textInput convertRect:self.textInput.bounds toView:convertView];
        CGPoint contentOffset = self.scrollView.contentOffset;
        CGFloat targetOffsetY = MAX(contentOffset.y + self.keyboardDistance + CGRectGetMaxY(convertRect) - CGRectGetMinY(keyboardRect), fwStaticKeyboardOffset);
        if (self.reboundDistance > 0 && targetOffsetY < contentOffset.y) {
            targetOffsetY = (targetOffsetY + self.reboundDistance >= contentOffset.y) ? contentOffset.y : targetOffsetY + self.reboundDistance;
        }
        
        contentOffset.y = targetOffsetY;
        [UIView animateWithDuration:animationDuration delay:0 options:(animationCurve | UIViewAnimationOptionBeginFromCurrentState) animations:^{
            self.scrollView.contentOffset = contentOffset;
        } completion:NULL];
        return;
    }
    
    if (!fwStaticKeyboardShowing) {
        fwStaticKeyboardShowing = YES;
        fwStaticKeyboardOrigin = self.viewController.view.frame.origin.y;
    }
    
    CGRect keyboardRect = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat animationDuration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    animationCurve = animationCurve << 16;
    UIView *convertView = self.textInput.window ?: self.viewController.view.window;
    CGRect convertRect = [self.textInput convertRect:self.textInput.bounds toView:convertView];
    CGRect viewFrame = self.viewController.view.frame;
    CGFloat viewTargetY = MIN(viewFrame.origin.y - self.keyboardDistance + CGRectGetMinY(keyboardRect) - CGRectGetMaxY(convertRect), fwStaticKeyboardOrigin);
    if (self.reboundDistance > 0 && viewTargetY > viewFrame.origin.y) {
        viewTargetY = (viewTargetY - self.reboundDistance <= viewFrame.origin.y) ? viewFrame.origin.y : viewTargetY - self.reboundDistance;
    }
    
    viewFrame.origin.y = viewTargetY;
    [UIView animateWithDuration:animationDuration delay:0 options:(animationCurve | UIViewAnimationOptionBeginFromCurrentState) animations:^{
        // 修复iOS14当vc.hidesBottomBarWhenPushed为YES时view.frame会被导航栏重置引起的滚动失效问题
        if (@available(iOS 14.0, *)) {
            self.viewController.view.layer.frame = viewFrame;
        } else {
            self.viewController.view.frame = viewFrame;
        }
    } completion:NULL];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    if (!self.textInput.isFirstResponder) return;
    if (!self.keyboardManager || !self.viewController || !fwStaticKeyboardShowing) return;
    
    if (self.scrollView != nil) {
        CGFloat originOffsetY = fwStaticKeyboardOffset;
        fwStaticKeyboardShowing = NO;
        fwStaticKeyboardOffset = 0;
        
        CGFloat animationDuration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
        NSInteger animationCurve = [[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
        animationCurve = animationCurve << 16;
        
        CGPoint contentOffset = self.scrollView.contentOffset;
        contentOffset.y = originOffsetY;
        [UIView animateWithDuration:animationDuration delay:0 options:(animationCurve | UIViewAnimationOptionBeginFromCurrentState) animations:^{
            self.scrollView.contentOffset = contentOffset;
        } completion:NULL];
        return;
    }
    
    CGFloat viewOriginY = fwStaticKeyboardOrigin;
    fwStaticKeyboardShowing = NO;
    fwStaticKeyboardOrigin = 0;
    
    CGFloat animationDuration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    animationCurve = animationCurve << 16;
    
    CGRect viewFrame = self.viewController.view.frame;
    viewFrame.origin.y = viewOriginY;
    [UIView animateWithDuration:animationDuration delay:0 options:(animationCurve | UIViewAnimationOptionBeginFromCurrentState) animations:^{
        // 修复iOS14当vc.hidesBottomBarWhenPushed为YES时view.frame会被导航栏重置引起的滚动失效问题
        if (@available(iOS 14.0, *)) {
            self.viewController.view.layer.frame = viewFrame;
        } else {
            self.viewController.view.frame = viewFrame;
        }
    } completion:NULL];
}

#pragma mark - Toolbar

- (UIToolbar *)keyboardToolbar
{
    if (!_keyboardToolbar) {
        _keyboardToolbar = [UIToolbar new];
    }
    return _keyboardToolbar;
}

- (id)toolbarPreviousButton
{
    if (!_toolbarPreviousButton && !_previousButtonInitialized) {
        _toolbarPreviousButton = [self.class toolbarPreviousImage];
    }
    return _toolbarPreviousButton;
}

- (id)toolbarNextButton
{
    if (!_toolbarNextButton && !_nextButtonInitialized) {
        _toolbarNextButton = [self.class toolbarNextImage];
    }
    return _toolbarNextButton;
}

- (id)toolbarDoneButton
{
    if (!_toolbarDoneButton && !_doneButtonInitialized) {
        _toolbarDoneButton = @(UIBarButtonSystemItemDone);
    }
    return _toolbarDoneButton;
}

- (void)setPreviousResponder:(UIResponder *(^)(id))previousResponder
{
    _previousResponder = previousResponder;
    self.previousItem.enabled = self.previousResponder != nil || self.previousResponderTag > 0;
}

- (void)setPreviousResponderTag:(NSInteger)previousResponderTag
{
    _previousResponderTag = previousResponderTag;
    self.previousItem.enabled = self.previousResponder != nil || self.previousResponderTag > 0;
}

- (void)setNextResponder:(UIResponder *(^)(id))nextResponder
{
    _nextResponder = nextResponder;
    self.nextItem.enabled = self.nextResponder != nil || self.nextResponderTag > 0;
}

- (void)setNextResponderTag:(NSInteger)nextResponderTag
{
    _nextResponderTag = nextResponderTag;
    self.nextItem.enabled = self.nextResponder != nil || self.nextResponderTag > 0;
}

- (void)goPrevious
{
    if (self.previousResponder) {
        UIResponder *previousInput = self.previousResponder(self.textInput);
        if (previousInput) [previousInput becomeFirstResponder];
        return;
    }
    
    if (self.previousResponderTag > 0) {
        UIView *targetView = self.viewController ? self.viewController.view : self.textInput.window;
        UIView *previousView = [targetView viewWithTag:self.previousResponderTag];
        if (previousView) [previousView becomeFirstResponder];
    }
}

- (void)goNext
{
    if (self.nextResponder) {
        UIResponder *nextInput = self.nextResponder(self.textInput);
        if (nextInput) [nextInput becomeFirstResponder];
        return;
    }
    
    if (self.nextResponderTag > 0) {
        UIView *targetView = self.viewController ? self.viewController.view : self.textInput.window;
        UIView *nextView = [targetView viewWithTag:self.nextResponderTag];
        if (nextView) [nextView becomeFirstResponder];
    }
}

- (CGFloat)keyboardHeight:(NSNotification *)notification
{
    CGRect keyboardRect = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    return keyboardRect.size.height;
}

- (void)keyboardAnimate:(NSNotification *)notification
             animations:(void (^)(void))animations
             completion:(void (^ __nullable)(BOOL finished))completion
{
    CGFloat animationDuration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    animationCurve = animationCurve << 16;
    
    [UIView animateWithDuration:animationDuration delay:0 options:(animationCurve | UIViewAnimationOptionBeginFromCurrentState) animations:animations completion:completion];
}

- (void)addToolbarWithTitle:(id)title
                  doneBlock:(void (^)(id sender))doneBlock
{
    UIBarButtonItem *titleItem = title ? [UIBarButtonItem __fw_itemWithObject:title block:nil] : nil;
    titleItem.enabled = NO;
    BOOL previousEnabled = self.previousResponder != nil || self.previousResponderTag > 0;
    BOOL nextEnabled = self.nextResponder != nil || self.nextResponderTag > 0;
    UIBarButtonItem *previousItem = ((previousEnabled || nextEnabled) && self.toolbarPreviousButton) ? [UIBarButtonItem __fw_itemWithObject:self.toolbarPreviousButton target:self action:@selector(goPrevious)] : nil;
    previousItem.enabled = previousEnabled;
    self.previousItem = previousItem;
    UIBarButtonItem *nextItem = ((previousEnabled || nextEnabled) && self.toolbarNextButton) ? [UIBarButtonItem __fw_itemWithObject:self.toolbarNextButton target:self action:@selector(goNext)] : nil;
    nextItem.enabled = nextEnabled;
    self.nextItem = nextItem;
    UIBarButtonItem *doneItem = self.toolbarDoneButton ? (doneBlock ? [UIBarButtonItem __fw_itemWithObject:self.toolbarDoneButton block:doneBlock] : [UIBarButtonItem __fw_itemWithObject:self.toolbarDoneButton target:self.textInput action:@selector(resignFirstResponder)]) : nil;
    doneItem.style = UIBarButtonItemStyleDone;
    
    [self addToolbarWithTitleItem:titleItem previousItem:previousItem nextItem:nextItem doneItem:doneItem];
}

- (void)addToolbarWithTitleItem:(UIBarButtonItem *)titleItem
                   previousItem:(UIBarButtonItem *)previousItem
                       nextItem:(UIBarButtonItem *)nextItem
                       doneItem:(UIBarButtonItem *)doneItem
{
    NSMutableArray<UIBarButtonItem *> *items = [NSMutableArray array];
    if (previousItem) [items addObject:previousItem];
    if (previousItem && nextItem) {
        UIBarButtonItem *fixedItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        fixedItem.width = 6;
        [items addObject:fixedItem];
    }
    if (nextItem) [items addObject:nextItem];
    [items addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
    if (titleItem) {
        [items addObject:titleItem];
        [items addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
    }
    if (doneItem) [items addObject:doneItem];
    
    UIToolbar *toolbar = self.keyboardToolbar;
    toolbar.items = [items copy];
    [toolbar sizeToFit];
    ((UITextField *)self.textInput).inputAccessoryView = toolbar;
}

// MARK: - Image

+ (UIImage *)toolbarPreviousImage
{
    static UIImage *previousImage = nil;
    if (previousImage == nil) {
        NSString *base64Data = @"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";
        
        NSData *data = [[NSData alloc] initWithBase64EncodedString:base64Data options:NSDataBase64DecodingIgnoreUnknownCharacters];
        previousImage = [[UIImage imageWithData:data scale:3] imageFlippedForRightToLeftLayoutDirection];
    }
    return previousImage;
}

+ (UIImage *)toolbarNextImage
{
    static UIImage *nextImage = nil;
    if (nextImage == nil) {
        NSString *base64Data = @"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";
        
        NSData *data = [[NSData alloc] initWithBase64EncodedString:base64Data options:NSDataBase64DecodingIgnoreUnknownCharacters];
        nextImage = [[UIImage imageWithData:data scale:3] imageFlippedForRightToLeftLayoutDirection];
    }
    return nextImage;
}

@end
