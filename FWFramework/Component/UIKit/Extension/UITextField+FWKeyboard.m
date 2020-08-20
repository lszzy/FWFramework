//
//  UITextField+FWKeyboard.m
//  FWFramework
//
//  Created by wuyong on 2017/4/6.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "UITextField+FWKeyboard.h"
#import "UIView+FWFramework.h"
#import <objc/runtime.h>

#pragma mark - FWInnerKeyboardController

@interface FWInnerKeyboardController : NSObject

@property (nonatomic, weak) UIViewController *viewController;
@property (nonatomic, strong) UITapGestureRecognizer *touchGesture;
@property (nonatomic, assign) BOOL keyboardShowing;
@property (nonatomic, assign) CGFloat animationOrigin;

@end

@implementation FWInnerKeyboardController

- (instancetype)initWithViewController:(UIViewController *)viewController
{
    self = [super init];
    if (self) {
        _viewController = viewController;
        _touchGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(touchGestureAction:)];
        _touchGesture.cancelsTouchesInView = NO;
    }
    return self;
}

- (void)touchGestureEnable:(BOOL)enable
{
    if (enable) {
        [self.viewController.view addGestureRecognizer:self.touchGesture];
    } else {
        [self.viewController.view removeGestureRecognizer:self.touchGesture];
    }
}

- (void)touchGestureAction:(UITapGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateEnded) {
        [self.viewController.view endEditing:YES];
    }
}

@end

#pragma mark - FWInnerKeyboardTarget

@interface FWInnerKeyboardTarget : NSObject

@property (nonatomic, assign) BOOL keyboardManager;

@property (nonatomic, assign) CGFloat keyboardSpacing;

@property (nonatomic, assign) BOOL keyboardResign;

@property (nonatomic, assign) BOOL keyboardActive;

@property (nonatomic, assign) BOOL touchResign;

@property (nonatomic, weak) UIView *keyboardView;

@property (nonatomic, weak, readonly) UIView<UITextInput> *textInput;

@property (nonatomic, weak) FWInnerKeyboardController *keyboardController;

- (instancetype)initWithTextInput:(UIView<UITextInput> *)textInput;

@end

@implementation FWInnerKeyboardTarget

- (instancetype)initWithTextInput:(UIView<UITextInput> *)textInput
{
    self = [super init];
    if (self) {
        _textInput = textInput;
        _keyboardSpacing = 10.0;
        
        if ([self.textInput isKindOfClass:[UITextField class]]) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editingDidBegin) name:UITextFieldTextDidBeginEditingNotification object:self.textInput];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editingDidEnd) name:UITextFieldTextDidEndEditingNotification object:self.textInput];
        } else if ([self.textInput isKindOfClass:[UITextView class]]) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editingDidBegin) name:UITextViewTextDidBeginEditingNotification object:self.textInput];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editingDidEnd) name:UITextViewTextDidEndEditingNotification object:self.textInput];
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appResignActive) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (FWInnerKeyboardController *)keyboardController
{
    if (_keyboardController) return _keyboardController;
    
    UIViewController *viewController = [self.textInput fwViewController];
    if (!viewController) return nil;
    
    FWInnerKeyboardController *keyboardController = objc_getAssociatedObject(viewController, _cmd);
    if (!keyboardController) {
        keyboardController = [[FWInnerKeyboardController alloc] initWithViewController:viewController];
        objc_setAssociatedObject(viewController, _cmd, keyboardController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    _keyboardController = keyboardController;
    return _keyboardController;
}

#pragma mark - Resign

- (void)editingDidBegin
{
    if (!self.touchResign) return;
    [self.keyboardController touchGestureEnable:YES];
}

- (void)editingDidEnd
{
    if (!self.touchResign) return;
    [self.keyboardController touchGestureEnable:NO];
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

#pragma mark - Keyboard

- (void)keyboardWillShow:(NSNotification *)notification
{
    if (!self.textInput.isFirstResponder) return;
    if (!self.keyboardView && !self.keyboardManager) return;
    if (!self.keyboardController) return;
    
    CGRect keyboardRect = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat animationDuration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];

    if (self.keyboardView) {
        if (!self.keyboardController.keyboardShowing) {
            self.keyboardController.keyboardShowing = YES;
            self.keyboardController.animationOrigin = self.keyboardView.fwY;
        }
        
        [UIView animateWithDuration:animationDuration animations:^{
            self.keyboardView.transform = CGAffineTransformMakeTranslation(0, -keyboardRect.size.height);
        }];
    } else {
        if (!self.keyboardController.keyboardShowing) {
            self.keyboardController.keyboardShowing = YES;
            self.keyboardController.animationOrigin = self.keyboardController.viewController.view.fwY;
        }
        
        UIView *convertView = self.textInput.window ?: self.keyboardController.viewController.view.window;
        CGRect convertRect = [self.textInput.superview convertRect:self.textInput.frame toView:convertView];
        CGFloat animationOffset = CGRectGetMinY(keyboardRect) - self.keyboardSpacing - CGRectGetMaxY(convertRect);
        [UIView animateWithDuration:animationDuration animations:^{
            self.keyboardController.viewController.view.fwY = self.keyboardController.animationOrigin + MIN(animationOffset, 0);
        }];
    }
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    if (!self.textInput.isFirstResponder) return;
    if (!self.keyboardView && !self.keyboardManager) return;
    if (!self.keyboardController.keyboardShowing) return;
    
    CGFloat animationOrigin = self.keyboardController.animationOrigin;
    CGFloat animationDuration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    self.keyboardController.keyboardShowing = NO;
    self.keyboardController.animationOrigin = 0;
    
    if (self.keyboardView) {
        [UIView animateWithDuration:animationDuration animations:^{
            self.keyboardView.transform = CGAffineTransformIdentity;
        } completion:nil];
    } else {
        [UIView animateWithDuration:animationDuration animations:^{
            self.keyboardController.viewController.view.fwY = animationOrigin;
        }];
    }
}

@end

#pragma mark - UITextField+FWKeyboard

@implementation UITextField (FWKeyboard)

- (BOOL)fwKeyboardManager
{
    return self.fwInnerKeyboardTarget.keyboardManager;
}

- (void)setFwKeyboardManager:(BOOL)fwKeyboardManager
{
    self.fwInnerKeyboardTarget.keyboardManager = fwKeyboardManager;
}

- (CGFloat)fwKeyboardSpacing
{
    return self.fwInnerKeyboardTarget.keyboardSpacing;
}

- (void)setFwKeyboardSpacing:(CGFloat)fwKeyboardSpacing
{
    self.fwInnerKeyboardTarget.keyboardSpacing = fwKeyboardSpacing;
}

- (BOOL)fwKeyboardResign
{
    return self.fwInnerKeyboardTarget.keyboardResign;
}

- (void)setFwKeyboardResign:(BOOL)fwKeyboardResign
{
    self.fwInnerKeyboardTarget.keyboardResign = fwKeyboardResign;
}

- (BOOL)fwTouchResign
{
    return self.fwInnerKeyboardTarget.touchResign;
}

- (void)setFwTouchResign:(BOOL)fwTouchResign
{
    self.fwInnerKeyboardTarget.touchResign = fwTouchResign;
}

- (UIView *)fwKeyboardView
{
    return self.fwInnerKeyboardTarget.keyboardView;
}

- (void)setFwKeyboardView:(UIView *)fwKeyboardView
{
    self.fwInnerKeyboardTarget.keyboardView = fwKeyboardView;
}

- (FWInnerKeyboardTarget *)fwInnerKeyboardTarget
{
    FWInnerKeyboardTarget *target = objc_getAssociatedObject(self, _cmd);
    if (!target) {
        target = [[FWInnerKeyboardTarget alloc] initWithTextInput:self];
        objc_setAssociatedObject(self, _cmd, target, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return target;
}

@end

#pragma mark - UITextView+FWKeyboard

@implementation UITextView (FWKeyboard)

- (BOOL)fwKeyboardManager
{
    return self.fwInnerKeyboardTarget.keyboardManager;
}

- (void)setFwKeyboardManager:(BOOL)fwKeyboardManager
{
    self.fwInnerKeyboardTarget.keyboardManager = fwKeyboardManager;
}

- (CGFloat)fwKeyboardSpacing
{
    return self.fwInnerKeyboardTarget.keyboardSpacing;
}

- (void)setFwKeyboardSpacing:(CGFloat)fwKeyboardSpacing
{
    self.fwInnerKeyboardTarget.keyboardSpacing = fwKeyboardSpacing;
}

- (BOOL)fwKeyboardResign
{
    return self.fwInnerKeyboardTarget.keyboardResign;
}

- (void)setFwKeyboardResign:(BOOL)fwKeyboardResign
{
    self.fwInnerKeyboardTarget.keyboardResign = fwKeyboardResign;
}

- (BOOL)fwTouchResign
{
    return self.fwInnerKeyboardTarget.touchResign;
}

- (void)setFwTouchResign:(BOOL)fwTouchResign
{
    self.fwInnerKeyboardTarget.touchResign = fwTouchResign;
}

- (UIView *)fwKeyboardView
{
    return self.fwInnerKeyboardTarget.keyboardView;
}

- (void)setFwKeyboardView:(UIView *)fwKeyboardView
{
    self.fwInnerKeyboardTarget.keyboardView = fwKeyboardView;
}

- (FWInnerKeyboardTarget *)fwInnerKeyboardTarget
{
    FWInnerKeyboardTarget *target = objc_getAssociatedObject(self, _cmd);
    if (!target) {
        target = [[FWInnerKeyboardTarget alloc] initWithTextInput:self];
        objc_setAssociatedObject(self, _cmd, target, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return target;
}

@end
