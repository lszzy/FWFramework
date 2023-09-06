//
//  FWKeyboard.m
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import "FWKeyboard.h"
#import "FWBlock.h"
#import "FWMessage.h"
#import "FWUIKit.h"
#import "FWProxy.h"
#import "FWRuntime.h"
#import <objc/runtime.h>

#pragma mark - FWInnerKeyboardTarget

static BOOL fwStaticKeyboardShowing = NO;
static CGFloat fwStaticKeyboardOrigin = 0;
static CGFloat fwStaticKeyboardOffset = 0;
static UITapGestureRecognizer *fwStaticKeyboardGesture = nil;

@interface FWInnerKeyboardTarget : NSObject

@property (nonatomic, assign) BOOL keyboardManager;
@property (nonatomic, assign) CGFloat keyboardDistance;
@property (nonatomic, copy) CGFloat (^keyboardDistanceBlock)(CGFloat keyboardHeight, CGFloat height);
@property (nonatomic, assign) CGFloat reboundDistance;
@property (nonatomic, assign) BOOL keyboardResign;
@property (nonatomic, assign) BOOL touchResign;

@property (nonatomic, assign) BOOL returnResign;
@property (nonatomic, assign) BOOL returnNext;
@property (nonatomic, copy) void (^returnBlock)(id textInput);

@property (nonatomic, strong) UIToolbar *keyboardToolbar;
@property (nonatomic, strong) id toolbarPreviousButton;
@property (nonatomic, strong) id toolbarNextButton;
@property (nonatomic, strong) id toolbarDoneButton;
@property (nonatomic, assign) BOOL previousButtonInitialized;
@property (nonatomic, assign) BOOL nextButtonInitialized;
@property (nonatomic, assign) BOOL doneButtonInitialized;
@property (nonatomic, copy) UIResponder * (^previousResponder)(id textInput);
@property (nonatomic, copy) UIResponder * (^nextResponder)(id textInput);
@property (nonatomic, assign) NSInteger previousResponderTag;
@property (nonatomic, assign) NSInteger nextResponderTag;
@property (nonatomic, strong) UIBarButtonItem *previousItem;
@property (nonatomic, strong) UIBarButtonItem *nextItem;

@property (nonatomic, weak, readonly) UIView<UITextInput> *textInput;
@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, weak) UIViewController *viewController;
@property (nonatomic, assign) BOOL keyboardActive;

@end

@implementation FWInnerKeyboardTarget

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
        _viewController = [self.textInput fw_viewController];
    }
    return _viewController;
}

#pragma mark - Resign

- (void)editingDidBegin
{
    if (!self.touchResign) return;
    if (!self.viewController) return;
    
    if (!fwStaticKeyboardGesture) {
        fwStaticKeyboardGesture = [UITapGestureRecognizer fw_gestureRecognizerWithBlock:^(UITapGestureRecognizer *sender) {
            if (sender.state == UIGestureRecognizerStateEnded) {
                [sender.view endEditing:YES];
            }
        }];
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

- (void)innerReturnAction
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
        CGFloat textInputOffset = self.keyboardDistanceBlock ? self.keyboardDistanceBlock(keyboardRect.size.height, convertRect.size.height) : self.keyboardDistance;
        CGFloat targetOffsetY = MAX(contentOffset.y + textInputOffset + CGRectGetMaxY(convertRect) - CGRectGetMinY(keyboardRect), fwStaticKeyboardOffset);
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
    CGFloat textInputOffset = self.keyboardDistanceBlock ? self.keyboardDistanceBlock(keyboardRect.size.height, convertRect.size.height) : self.keyboardDistance;
    CGFloat viewTargetY = MIN(viewFrame.origin.y - textInputOffset + CGRectGetMinY(keyboardRect) - CGRectGetMaxY(convertRect), fwStaticKeyboardOrigin);
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
    UIBarButtonItem *titleItem = title ? [UIBarButtonItem fw_itemWithObject:title block:nil] : nil;
    titleItem.enabled = NO;
    BOOL previousEnabled = self.previousResponder != nil || self.previousResponderTag > 0;
    BOOL nextEnabled = self.nextResponder != nil || self.nextResponderTag > 0;
    UIBarButtonItem *previousItem = ((previousEnabled || nextEnabled) && self.toolbarPreviousButton) ? [UIBarButtonItem fw_itemWithObject:self.toolbarPreviousButton target:self action:@selector(goPrevious)] : nil;
    previousItem.enabled = previousEnabled;
    self.previousItem = previousItem;
    UIBarButtonItem *nextItem = ((previousEnabled || nextEnabled) && self.toolbarNextButton) ? [UIBarButtonItem fw_itemWithObject:self.toolbarNextButton target:self action:@selector(goNext)] : nil;
    nextItem.enabled = nextEnabled;
    self.nextItem = nextItem;
    UIBarButtonItem *doneItem = self.toolbarDoneButton ? (doneBlock ? [UIBarButtonItem fw_itemWithObject:self.toolbarDoneButton block:doneBlock] : [UIBarButtonItem fw_itemWithObject:self.toolbarDoneButton target:self.textInput action:@selector(resignFirstResponder)]) : nil;
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

#pragma mark - FWTextViewDelegateProxy

@interface FWTextViewDelegateProxy : FWDelegateProxy <UITextViewDelegate>

@end

@implementation FWTextViewDelegateProxy

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    BOOL shouldChange = YES;
    // 先执行代理方法
    if (self.delegate && [self.delegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
        shouldChange = [self.delegate textView:textView shouldChangeTextInRange:range replacementText:text];
    }
    
    // 再执行内部方法
    if (textView.fw_returnResign || textView.fw_returnNext || textView.fw_returnBlock) {
        // 判断是否输入回车
        if ([text isEqualToString:@"\n"]) {
            // 切换到下一个输入框
            if (textView.fw_returnNext) {
                [textView fw_goNext];
            // 关闭键盘
            } else if (textView.fw_returnResign) {
                [textView resignFirstResponder];
            }
            // 执行回调
            if (textView.fw_returnBlock) {
                textView.fw_returnBlock(textView);
            }
            shouldChange = NO;
        }
    }
    return shouldChange;
}

@end

#pragma mark - UITextField+FWKeyboard

@implementation UITextField (FWKeyboard)

- (BOOL)fw_keyboardManager
{
    return self.fw_innerKeyboardTarget.keyboardManager;
}

- (void)setFw_keyboardManager:(BOOL)keyboardManager
{
    self.fw_innerKeyboardTarget.keyboardManager = keyboardManager;
}

- (CGFloat)fw_keyboardDistance
{
    return self.fw_innerKeyboardTarget.keyboardDistance;
}

- (void)setFw_keyboardDistance:(CGFloat)keyboardDistance
{
    self.fw_innerKeyboardTarget.keyboardDistance = keyboardDistance;
}

- (CGFloat (^)(CGFloat, CGFloat))fw_keyboardDistanceBlock
{
    return self.fw_innerKeyboardTarget.keyboardDistanceBlock;
}

- (void)setFw_keyboardDistanceBlock:(CGFloat (^)(CGFloat, CGFloat))keyboardDistanceBlock
{
    self.fw_innerKeyboardTarget.keyboardDistanceBlock = keyboardDistanceBlock;
}

- (CGFloat)fw_reboundDistance
{
    return self.fw_innerKeyboardTarget.reboundDistance;
}

- (void)setFw_reboundDistance:(CGFloat)reboundDistance
{
    self.fw_innerKeyboardTarget.reboundDistance = reboundDistance;
}

- (BOOL)fw_keyboardResign
{
    return self.fw_innerKeyboardTarget.keyboardResign;
}

- (void)setFw_keyboardResign:(BOOL)keyboardResign
{
    self.fw_innerKeyboardTarget.keyboardResign = keyboardResign;
}

- (BOOL)fw_touchResign
{
    return self.fw_innerKeyboardTarget.touchResign;
}

- (void)setFw_touchResign:(BOOL)touchResign
{
    self.fw_innerKeyboardTarget.touchResign = touchResign;
}

- (UIScrollView *)fw_keyboardScrollView
{
    return self.fw_innerKeyboardTarget.scrollView;
}

- (void)setFw_keyboardScrollView:(UIScrollView *)keyboardScrollView
{
    self.fw_innerKeyboardTarget.scrollView = keyboardScrollView;
}

- (FWInnerKeyboardTarget *)fw_innerKeyboardTarget
{
    FWInnerKeyboardTarget *target = objc_getAssociatedObject(self, _cmd);
    if (!target) {
        target = [[FWInnerKeyboardTarget alloc] initWithTextInput:self];
        objc_setAssociatedObject(self, _cmd, target, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return target;
}

#pragma mark - Return

- (BOOL)fw_returnResign
{
    return self.fw_innerKeyboardTarget.returnResign;
}

- (void)setFw_returnResign:(BOOL)returnResign
{
    self.fw_innerKeyboardTarget.returnResign = returnResign;
    [self fw_innerReturnEvent];
}

- (BOOL)fw_returnNext
{
    return self.fw_innerKeyboardTarget.returnNext;
}

- (void)setFw_returnNext:(BOOL)returnNext
{
    self.fw_innerKeyboardTarget.returnNext = returnNext;
    [self fw_innerReturnEvent];
}

- (void (^)(UITextField *textField))fw_returnBlock
{
    return self.fw_innerKeyboardTarget.returnBlock;
}

- (void)setFw_returnBlock:(void (^)(UITextField *textField))returnBlock
{
    self.fw_innerKeyboardTarget.returnBlock = returnBlock;
    [self fw_innerReturnEvent];
}

- (void)fw_innerReturnEvent
{
    id object = objc_getAssociatedObject(self, _cmd);
    if (!object) {
        [self addTarget:self.fw_innerKeyboardTarget action:@selector(innerReturnAction) forControlEvents:UIControlEventEditingDidEndOnExit];
        objc_setAssociatedObject(self, _cmd, @(1), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

#pragma mark - Toolbar

- (UIToolbar *)fw_keyboardToolbar
{
    return self.fw_innerKeyboardTarget.keyboardToolbar;
}

- (void)setFw_keyboardToolbar:(UIToolbar *)keyboardToolbar
{
    self.fw_innerKeyboardTarget.keyboardToolbar = keyboardToolbar;
}

- (id)fw_toolbarPreviousButton
{
    return self.fw_innerKeyboardTarget.toolbarPreviousButton;
}

- (void)setFw_toolbarPreviousButton:(id)toolbarPreviousButton
{
    self.fw_innerKeyboardTarget.previousButtonInitialized = YES;
    self.fw_innerKeyboardTarget.toolbarPreviousButton = toolbarPreviousButton;
}

- (id)fw_toolbarNextButton
{
    return self.fw_innerKeyboardTarget.toolbarNextButton;
}

- (void)setFw_toolbarNextButton:(id)toolbarNextButton
{
    self.fw_innerKeyboardTarget.nextButtonInitialized = YES;
    self.fw_innerKeyboardTarget.toolbarNextButton = toolbarNextButton;
}

- (id)fw_toolbarDoneButton
{
    return self.fw_innerKeyboardTarget.toolbarDoneButton;
}

- (void)setFw_toolbarDoneButton:(id)toolbarDoneButton
{
    self.fw_innerKeyboardTarget.doneButtonInitialized = YES;
    self.fw_innerKeyboardTarget.toolbarDoneButton = toolbarDoneButton;
}

- (UIResponder * (^)(UITextField *))fw_previousResponder
{
    return self.fw_innerKeyboardTarget.previousResponder;
}

- (void)setFw_previousResponder:(UIResponder * (^)(UITextField *))previousResponder
{
    self.fw_innerKeyboardTarget.previousResponder = previousResponder;
}

- (UIResponder * (^)(UITextField *))fw_nextResponder
{
    return self.fw_innerKeyboardTarget.nextResponder;
}

- (void)setFw_nextResponder:(UIResponder * (^)(UITextField *))nextResponder
{
    self.fw_innerKeyboardTarget.nextResponder = nextResponder;
}

- (NSInteger)fw_previousResponderTag
{
    return self.fw_innerKeyboardTarget.previousResponderTag;
}

- (void)setFw_previousResponderTag:(NSInteger)previousResponderTag
{
    self.fw_innerKeyboardTarget.previousResponderTag = previousResponderTag;
}

- (NSInteger)fw_nextResponderTag
{
    return self.fw_innerKeyboardTarget.nextResponderTag;
}

- (void)setFw_nextResponderTag:(NSInteger)nextResponderTag
{
    self.fw_innerKeyboardTarget.nextResponderTag = nextResponderTag;
}

- (void)fw_goPrevious
{
    [self.fw_innerKeyboardTarget goPrevious];
}

- (void)fw_goNext
{
    [self.fw_innerKeyboardTarget goNext];
}

- (CGFloat)fw_keyboardHeight:(NSNotification *)notification
{
    return [self.fw_innerKeyboardTarget keyboardHeight:notification];
}

- (void)fw_keyboardAnimate:(NSNotification *)notification
             animations:(void (^)(void))animations
             completion:(void (^)(BOOL))completion
{
    [self.fw_innerKeyboardTarget keyboardAnimate:notification animations:animations completion:completion];
}

- (void)fw_addToolbarWithTitle:(id)title
                  doneBlock:(void (^)(id sender))doneBlock
{
    [self.fw_innerKeyboardTarget addToolbarWithTitle:title doneBlock:doneBlock];
}

- (void)fw_addToolbarWithTitleItem:(UIBarButtonItem *)titleItem
                   previousItem:(UIBarButtonItem *)previousItem
                       nextItem:(UIBarButtonItem *)nextItem
                       doneItem:(UIBarButtonItem *)doneItem
{
    [self.fw_innerKeyboardTarget addToolbarWithTitleItem:titleItem previousItem:previousItem nextItem:nextItem doneItem:doneItem];
}

@end

#pragma mark - UITextView+FWKeyboard

@implementation UITextView (FWKeyboard)

- (BOOL)fw_keyboardManager
{
    return self.fw_innerKeyboardTarget.keyboardManager;
}

- (void)setFw_keyboardManager:(BOOL)keyboardManager
{
    self.fw_innerKeyboardTarget.keyboardManager = keyboardManager;
}

- (CGFloat)fw_keyboardDistance
{
    return self.fw_innerKeyboardTarget.keyboardDistance;
}

- (void)setFw_keyboardDistance:(CGFloat)keyboardDistance
{
    self.fw_innerKeyboardTarget.keyboardDistance = keyboardDistance;
}

- (CGFloat (^)(CGFloat, CGFloat))fw_keyboardDistanceBlock
{
    return self.fw_innerKeyboardTarget.keyboardDistanceBlock;
}

- (void)setFw_keyboardDistanceBlock:(CGFloat (^)(CGFloat, CGFloat))keyboardDistanceBlock
{
    self.fw_innerKeyboardTarget.keyboardDistanceBlock = keyboardDistanceBlock;
}

- (CGFloat)fw_reboundDistance
{
    return self.fw_innerKeyboardTarget.reboundDistance;
}

- (void)setFw_reboundDistance:(CGFloat)reboundDistance
{
    self.fw_innerKeyboardTarget.reboundDistance = reboundDistance;
}

- (BOOL)fw_keyboardResign
{
    return self.fw_innerKeyboardTarget.keyboardResign;
}

- (void)setFw_keyboardResign:(BOOL)keyboardResign
{
    self.fw_innerKeyboardTarget.keyboardResign = keyboardResign;
}

- (BOOL)fw_touchResign
{
    return self.fw_innerKeyboardTarget.touchResign;
}

- (void)setFw_touchResign:(BOOL)touchResign
{
    self.fw_innerKeyboardTarget.touchResign = touchResign;
}

- (UIScrollView *)fw_keyboardScrollView
{
    return self.fw_innerKeyboardTarget.scrollView;
}

- (void)setFw_keyboardScrollView:(UIScrollView *)keyboardScrollView
{
    self.fw_innerKeyboardTarget.scrollView = keyboardScrollView;
}

- (FWInnerKeyboardTarget *)fw_innerKeyboardTarget
{
    FWInnerKeyboardTarget *target = objc_getAssociatedObject(self, _cmd);
    if (!target) {
        target = [[FWInnerKeyboardTarget alloc] initWithTextInput:self];
        objc_setAssociatedObject(self, _cmd, target, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return target;
}

#pragma mark - Return

- (BOOL)fw_returnResign
{
    return self.fw_innerKeyboardTarget.returnResign;
}

- (void)setFw_returnResign:(BOOL)returnResign
{
    self.fw_innerKeyboardTarget.returnResign = returnResign;
    self.fw_delegateProxyEnabled = YES;
}

- (BOOL)fw_returnNext
{
    return self.fw_innerKeyboardTarget.returnNext;
}

- (void)setFw_returnNext:(BOOL)returnNext
{
    self.fw_innerKeyboardTarget.returnNext = returnNext;
    self.fw_delegateProxyEnabled = YES;
}

- (void (^)(UITextView *textView))fw_returnBlock
{
    return self.fw_innerKeyboardTarget.returnBlock;
}

- (void)setFw_returnBlock:(void (^)(UITextView *textView))returnBlock
{
    self.fw_innerKeyboardTarget.returnBlock = returnBlock;
    self.fw_delegateProxyEnabled = YES;
}

#pragma mark - Delegate

- (id<UITextViewDelegate>)fw_delegate
{
    if (!self.fw_delegateProxyEnabled) {
        return self.delegate;
    } else {
        return self.fw_delegateProxy.delegate;
    }
}

- (void)setFw_delegate:(id<UITextViewDelegate>)delegate
{
    if (!self.fw_delegateProxyEnabled) {
        self.delegate = delegate;
    } else {
        self.fw_delegateProxy.delegate = delegate;
    }
}

- (BOOL)fw_delegateProxyEnabled
{
    return self.delegate == self.fw_delegateProxy;
}

- (void)setFw_delegateProxyEnabled:(BOOL)enabled
{
    if (enabled != self.fw_delegateProxyEnabled) {
        if (enabled) {
            self.fw_delegateProxy.delegate = self.delegate;
            self.delegate = self.fw_delegateProxy;
        } else {
            self.delegate = self.fw_delegateProxy.delegate;
            self.fw_delegateProxy.delegate = nil;
        }
    }
}

- (__kindof FWDelegateProxy *)fw_delegateProxy
{
    FWDelegateProxy *proxy = objc_getAssociatedObject(self, _cmd);
    if (!proxy) {
        proxy = [[FWTextViewDelegateProxy alloc] init];
        objc_setAssociatedObject(self, _cmd, proxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return proxy;
}

#pragma mark - Toolbar

- (UIToolbar *)fw_keyboardToolbar
{
    return self.fw_innerKeyboardTarget.keyboardToolbar;
}

- (void)setFw_keyboardToolbar:(UIToolbar *)keyboardToolbar
{
    self.fw_innerKeyboardTarget.keyboardToolbar = keyboardToolbar;
}

- (id)fw_toolbarPreviousButton
{
    return self.fw_innerKeyboardTarget.toolbarPreviousButton;
}

- (void)setFw_toolbarPreviousButton:(id)toolbarPreviousButton
{
    self.fw_innerKeyboardTarget.previousButtonInitialized = YES;
    self.fw_innerKeyboardTarget.toolbarPreviousButton = toolbarPreviousButton;
}

- (id)fw_toolbarNextButton
{
    return self.fw_innerKeyboardTarget.toolbarNextButton;
}

- (void)setFw_toolbarNextButton:(id)toolbarNextButton
{
    self.fw_innerKeyboardTarget.nextButtonInitialized = YES;
    self.fw_innerKeyboardTarget.toolbarNextButton = toolbarNextButton;
}

- (id)fw_toolbarDoneButton
{
    return self.fw_innerKeyboardTarget.toolbarDoneButton;
}

- (void)setFw_toolbarDoneButton:(id)toolbarDoneButton
{
    self.fw_innerKeyboardTarget.doneButtonInitialized = YES;
    self.fw_innerKeyboardTarget.toolbarDoneButton = toolbarDoneButton;
}

- (UIResponder * (^)(UITextView *))fw_previousResponder
{
    return self.fw_innerKeyboardTarget.previousResponder;
}

- (void)setFw_previousResponder:(UIResponder * (^)(UITextView *))previousResponder
{
    self.fw_innerKeyboardTarget.previousResponder = previousResponder;
}

- (UIResponder * (^)(UITextView *))fw_nextResponder
{
    return self.fw_innerKeyboardTarget.nextResponder;
}

- (void)setFw_nextResponder:(UIResponder * (^)(UITextView *))nextResponder
{
    self.fw_innerKeyboardTarget.nextResponder = nextResponder;
}

- (NSInteger)fw_previousResponderTag
{
    return self.fw_innerKeyboardTarget.previousResponderTag;
}

- (void)setFw_previousResponderTag:(NSInteger)previousResponderTag
{
    self.fw_innerKeyboardTarget.previousResponderTag = previousResponderTag;
}

- (NSInteger)fw_nextResponderTag
{
    return self.fw_innerKeyboardTarget.nextResponderTag;
}

- (void)setFw_nextResponderTag:(NSInteger)nextResponderTag
{
    self.fw_innerKeyboardTarget.nextResponderTag = nextResponderTag;
}

- (void)fw_goPrevious
{
    [self.fw_innerKeyboardTarget goPrevious];
}

- (void)fw_goNext
{
    [self.fw_innerKeyboardTarget goNext];
}

- (CGFloat)fw_keyboardHeight:(NSNotification *)notification
{
    return [self.fw_innerKeyboardTarget keyboardHeight:notification];
}

- (void)fw_keyboardAnimate:(NSNotification *)notification
             animations:(void (^)(void))animations
             completion:(void (^)(BOOL))completion
{
    [self.fw_innerKeyboardTarget keyboardAnimate:notification animations:animations completion:completion];
}

- (void)fw_addToolbarWithTitle:(id)title
                  doneBlock:(void (^)(id sender))doneBlock
{
    [self.fw_innerKeyboardTarget addToolbarWithTitle:title doneBlock:doneBlock];
}

- (void)fw_addToolbarWithTitleItem:(UIBarButtonItem *)titleItem
                   previousItem:(UIBarButtonItem *)previousItem
                       nextItem:(UIBarButtonItem *)nextItem
                       doneItem:(UIBarButtonItem *)doneItem
{
    [self.fw_innerKeyboardTarget addToolbarWithTitleItem:titleItem previousItem:previousItem nextItem:nextItem doneItem:doneItem];
}

@end

#pragma mark - UITextView+FWPlaceholder

@interface FWInnerPlaceholderTarget : NSObject

@property (nonatomic, weak, readonly) UITextView *textView;
@property (nonatomic, assign) CGFloat lastHeight;

- (instancetype)initWithTextView:(UITextView *)textView;

- (void)setNeedsUpdatePlaceholder;
- (void)setNeedsUpdateText;

@end

@implementation UITextView (FWPlaceholder)

- (UILabel *)fw_placeholderLabel
{
    UILabel *label = objc_getAssociatedObject(self, @selector(fw_placeholderLabel));
    if (!label) {
        static UIColor *defaultPlaceholderColor = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            UITextField *textField = [[UITextField alloc] init];
            textField.placeholder = @" ";
            UILabel *placeholderLabel = [textField fw_invokeGetter:@"_placeholderLabel"];
            defaultPlaceholderColor = placeholderLabel.textColor;
        });
        
        NSAttributedString *originalText = self.attributedText;
        self.text = @" ";
        self.attributedText = originalText;
        
        label = [[UILabel alloc] init];
        label.textColor = defaultPlaceholderColor;
        label.numberOfLines = 0;
        label.userInteractionEnabled = NO;
        label.font = self.font;
        objc_setAssociatedObject(self, @selector(fw_placeholderLabel), label, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [self.fw_innerPlaceholderTarget setNeedsUpdatePlaceholder];
        [self insertSubview:label atIndex:0];
        
        [self fw_observeNotification:UITextViewTextDidChangeNotification object:self target:self.fw_innerPlaceholderTarget action:@selector(setNeedsUpdateText)];

        [self fw_observeProperty:@"attributedText" target:self.fw_innerPlaceholderTarget action:@selector(setNeedsUpdateText)];
        [self fw_observeProperty:@"text" target:self.fw_innerPlaceholderTarget action:@selector(setNeedsUpdateText)];
        [self fw_observeProperty:@"bounds" target:self.fw_innerPlaceholderTarget action:@selector(setNeedsUpdatePlaceholder)];
        [self fw_observeProperty:@"frame" target:self.fw_innerPlaceholderTarget action:@selector(setNeedsUpdatePlaceholder)];
        [self fw_observeProperty:@"textAlignment" target:self.fw_innerPlaceholderTarget action:@selector(setNeedsUpdatePlaceholder)];
        [self fw_observeProperty:@"textContainerInset" target:self.fw_innerPlaceholderTarget action:@selector(setNeedsUpdatePlaceholder)];
        
        [self fw_observeProperty:@"font" block:^(UITextView *textView, NSDictionary *change) {
            if (change[NSKeyValueChangeNewKey] != nil) textView.fw_placeholderLabel.font = textView.font;
            [textView.fw_innerPlaceholderTarget setNeedsUpdatePlaceholder];
        }];
    }
    return label;
}

- (FWInnerPlaceholderTarget *)fw_innerPlaceholderTarget
{
    FWInnerPlaceholderTarget *target = objc_getAssociatedObject(self, _cmd);
    if (!target) {
        target = [[FWInnerPlaceholderTarget alloc] initWithTextView:self];
        objc_setAssociatedObject(self, _cmd, target, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return target;
}

- (NSString *)fw_placeholder
{
    return self.fw_placeholderLabel.text;
}

- (void)setFw_placeholder:(NSString *)placeholder
{
    self.fw_placeholderLabel.text = placeholder;
    [self.fw_innerPlaceholderTarget setNeedsUpdatePlaceholder];
}

- (NSAttributedString *)fw_attributedPlaceholder
{
    return self.fw_placeholderLabel.attributedText;
}

- (void)setFw_attributedPlaceholder:(NSAttributedString *)attributedPlaceholder
{
    self.fw_placeholderLabel.attributedText = attributedPlaceholder;
    [self.fw_innerPlaceholderTarget setNeedsUpdatePlaceholder];
}

- (UIColor *)fw_placeholderColor
{
    return self.fw_placeholderLabel.textColor;
}

- (void)setFw_placeholderColor:(UIColor *)placeholderColor
{
    self.fw_placeholderLabel.textColor = placeholderColor;
}

- (UIEdgeInsets)fw_placeholderInset
{
    NSValue *value = objc_getAssociatedObject(self, @selector(fw_placeholderInset));
    return value ? value.UIEdgeInsetsValue : UIEdgeInsetsZero;
}

- (void)setFw_placeholderInset:(UIEdgeInsets)inset
{
    objc_setAssociatedObject(self, @selector(fw_placeholderInset), [NSValue valueWithUIEdgeInsets:inset], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self.fw_innerPlaceholderTarget setNeedsUpdatePlaceholder];
}

- (UIControlContentVerticalAlignment)fw_verticalAlignment
{
    NSNumber *value = objc_getAssociatedObject(self, @selector(fw_verticalAlignment));
    return value ? value.integerValue : UIControlContentVerticalAlignmentTop;
}

- (void)setFw_verticalAlignment:(UIControlContentVerticalAlignment)verticalAlignment
{
    objc_setAssociatedObject(self, @selector(fw_verticalAlignment), @(verticalAlignment), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self.fw_innerPlaceholderTarget setNeedsUpdatePlaceholder];
}

- (CGFloat)fw_lineHeight
{
    return [objc_getAssociatedObject(self, @selector(fw_lineHeight)) doubleValue];
}

- (void)setFw_lineHeight:(CGFloat)lineHeight
{
    objc_setAssociatedObject(self, @selector(fw_lineHeight), @(lineHeight), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    self.fw_placeholderLabel.fw_lineHeight = lineHeight;
    [self.fw_innerPlaceholderTarget setNeedsUpdatePlaceholder];
    
    NSMutableDictionary<NSAttributedStringKey, id> *typingAttributes = self.typingAttributes.mutableCopy;
    NSParagraphStyle *style = typingAttributes[NSParagraphStyleAttributeName];
    NSMutableParagraphStyle *paragraphStyle = style ? style.mutableCopy : [NSMutableParagraphStyle new];
    paragraphStyle.minimumLineHeight = lineHeight;
    paragraphStyle.maximumLineHeight = lineHeight;
    
    typingAttributes[NSParagraphStyleAttributeName] = paragraphStyle;
    self.typingAttributes = typingAttributes;
}

- (BOOL)fw_autoHeightEnabled
{
    return [objc_getAssociatedObject(self, @selector(fw_autoHeightEnabled)) boolValue];
}

- (void)setFw_autoHeightEnabled:(BOOL)enabled
{
    objc_setAssociatedObject(self, @selector(fw_autoHeightEnabled), @(enabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self.fw_innerPlaceholderTarget setNeedsUpdateText];
}

- (CGFloat)fw_maxHeight
{
    NSNumber *value = objc_getAssociatedObject(self, @selector(fw_maxHeight));
    return value ? value.doubleValue : CGFLOAT_MAX;
}

- (void)setFw_maxHeight:(CGFloat)height
{
    objc_setAssociatedObject(self, @selector(fw_maxHeight), @(height), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self.fw_innerPlaceholderTarget setNeedsUpdateText];
}

- (CGFloat)fw_minHeight
{
    return [objc_getAssociatedObject(self, @selector(fw_minHeight)) doubleValue];
}

- (void)setFw_minHeight:(CGFloat)height
{
    objc_setAssociatedObject(self, @selector(fw_minHeight), @(height), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self.fw_innerPlaceholderTarget setNeedsUpdateText];
}

- (void (^)(CGFloat))fw_heightDidChange
{
    return objc_getAssociatedObject(self, @selector(fw_heightDidChange));
}

- (void)setFw_heightDidChange:(void (^)(CGFloat))block
{
    objc_setAssociatedObject(self, @selector(fw_heightDidChange), block, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)fw_autoHeightWithMaxHeight:(CGFloat)maxHeight didChange:(void (^)(CGFloat))didChange
{
    self.fw_maxHeight = maxHeight;
    if (didChange) self.fw_heightDidChange = didChange;
    self.fw_autoHeightEnabled = YES;
}

@end

@implementation FWInnerPlaceholderTarget

- (instancetype)initWithTextView:(UITextView *)textView
{
    self = [super init];
    if (self) {
        _textView = textView;
    }
    return self;
}

- (void)setNeedsUpdatePlaceholder
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updatePlaceholder) object:nil];
    [self performSelector:@selector(updatePlaceholder) withObject:nil afterDelay:0];
}

- (void)setNeedsUpdateText
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateText) object:nil];
    [self performSelector:@selector(updateText) withObject:nil afterDelay:0];
}

- (void)updatePlaceholder
{
    // 调整contentInset实现垂直分布，不使用contentOffset是因为光标移动会不正常
    UIEdgeInsets contentInset = self.textView.contentInset;
    contentInset.top = 0;
    if (self.textView.contentSize.height < self.textView.bounds.size.height) {
        CGFloat height = ceil([self.textView sizeThatFits:CGSizeMake(self.textView.bounds.size.width, CGFLOAT_MAX)].height);
        switch (self.textView.fw_verticalAlignment) {
            case UIControlContentVerticalAlignmentCenter:
                contentInset.top = (self.textView.bounds.size.height - height) / 2.0;
                break;
            case UIControlContentVerticalAlignmentBottom:
                contentInset.top = self.textView.bounds.size.height - height;
                break;
            default:
                break;
        }
    }
    self.textView.contentInset = contentInset;
    
    if (self.textView.text.length) {
        self.textView.fw_placeholderLabel.hidden = YES;
    } else {
        CGRect targetFrame;
        UIEdgeInsets inset = [self.textView fw_placeholderInset];
        if (!UIEdgeInsetsEqualToEdgeInsets(inset, UIEdgeInsetsZero)) {
            targetFrame = CGRectMake(inset.left, inset.top, CGRectGetWidth(self.textView.bounds) - inset.left - inset.right, CGRectGetHeight(self.textView.bounds) - inset.top - inset.bottom);
        } else {
            CGFloat x = self.textView.textContainer.lineFragmentPadding + self.textView.textContainerInset.left;
            CGFloat width = CGRectGetWidth(self.textView.bounds) - x - self.textView.textContainer.lineFragmentPadding - self.textView.textContainerInset.right;
            CGFloat height = ceil([self.textView.fw_placeholderLabel sizeThatFits:CGSizeMake(width, 0)].height);
            height = MIN(height, self.textView.bounds.size.height - self.textView.textContainerInset.top - self.textView.textContainerInset.bottom);
            
            CGFloat y = self.textView.textContainerInset.top;
            switch (self.textView.fw_verticalAlignment) {
                case UIControlContentVerticalAlignmentCenter:
                    y = (self.textView.bounds.size.height - height) / 2.0 - self.textView.contentInset.top;
                    break;
                case UIControlContentVerticalAlignmentBottom:
                    y = self.textView.bounds.size.height - height - self.textView.textContainerInset.bottom - self.textView.contentInset.top;
                    break;
                default:
                    break;
            }
            targetFrame = CGRectMake(x, y, width, height);
        }
        
        self.textView.fw_placeholderLabel.hidden = NO;
        self.textView.fw_placeholderLabel.textAlignment = self.textView.textAlignment;
        self.textView.fw_placeholderLabel.frame = targetFrame;
    }
}

- (void)updateText
{
    [self updatePlaceholder];
    if (!self.textView.fw_autoHeightEnabled) return;
    
    CGFloat height = ceil([self.textView sizeThatFits:CGSizeMake(self.textView.bounds.size.width, CGFLOAT_MAX)].height);
    height = MAX(self.textView.fw_minHeight, MIN(height, self.textView.fw_maxHeight));
    if (height == self.lastHeight) return;
    
    CGRect targetFrame = self.textView.frame;
    targetFrame.size.height = height;
    self.textView.frame = targetFrame;
    if (self.textView.fw_heightDidChange) self.textView.fw_heightDidChange(height);
    self.lastHeight = height;
}

@end
