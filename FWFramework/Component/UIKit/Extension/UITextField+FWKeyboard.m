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
@property (nonatomic, assign) BOOL isKeyboardShow;
@property (nonatomic, assign) CGFloat viewOriginY;
@property (nonatomic, assign) CGFloat viewOffsetY;

@end

@implementation FWInnerKeyboardController

- (instancetype)init
{
    self = [super init];
    if (self) {
        _touchGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(touchGestureAction:)];
        // 继续响应其它touch事件
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
        
        if ([textInput isKindOfClass:[UITextField class]]) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editingDidBegin) name:UITextFieldTextDidBeginEditingNotification object:textInput];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editingDidEnd) name:UITextFieldTextDidEndEditingNotification object:textInput];
        } else if ([textInput isKindOfClass:[UITextView class]]) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editingDidBegin) name:UITextViewTextDidBeginEditingNotification object:textInput];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editingDidEnd) name:UITextViewTextDidEndEditingNotification object:textInput];
        }
        
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
        keyboardController = [[FWInnerKeyboardController alloc] init];
        keyboardController.viewController = viewController;
        objc_setAssociatedObject(viewController, _cmd, keyboardController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    _keyboardController = keyboardController;
    return _keyboardController;
}

#pragma mark - Resign

- (void)editingDidBegin
{
    if (self.touchResign) {
        [self.keyboardController touchGestureEnable:YES];
    }
}

- (void)editingDidEnd
{
    if (self.touchResign) {
        [self.keyboardController touchGestureEnable:NO];
    }
}

#pragma mark - Keyboard

- (void)keyboardWillShow:(NSNotification *)notification
{
    if (!self.textInput.isFirstResponder) return;
    
    if (self.keyboardView) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithDictionary:notification.userInfo];
        CGFloat keyboardHeight = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
        CGFloat animationDuration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
        
        [UIView animateWithDuration:animationDuration animations:^{
            self.keyboardView.transform = CGAffineTransformMakeTranslation(0, -keyboardHeight);
        } completion:nil];
    }
    
    if (self.keyboardManager) {
        if (!self.keyboardController) return;
        UIWindow *targetWindow = self.textInput.window ? self.textInput.window : self.keyboardController.viewController.view.window;
        if (!targetWindow) return;
        
        NSDictionary *userInfo = [NSDictionary dictionaryWithDictionary:notification.userInfo];
        CGRect keyboardRect = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
        CGFloat animationDuration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
        CGRect convertRect = [self.textInput.superview convertRect:self.textInput.frame toView:targetWindow];
        CGFloat maxY = CGRectGetMaxY(convertRect);
        if (self.keyboardController.viewOffsetY != 0) {
            maxY -= self.keyboardController.viewOffsetY;
        }
        
        if (!self.keyboardController.isKeyboardShow) {
            self.keyboardController.isKeyboardShow = YES;
            self.keyboardController.viewOriginY = self.keyboardController.viewController.view.fwY;
        }
        
        // 判断是否需要自动滚动动画
        if (CGRectGetMinY(keyboardRect) - self.keyboardSpacing < maxY) {
            CGFloat animationOffset = CGRectGetMinY(keyboardRect) - self.keyboardSpacing - maxY;
            self.keyboardController.viewOffsetY = animationOffset;
            [UIView animateWithDuration:animationDuration animations:^{
                self.keyboardController.viewController.view.fwY = self.keyboardController.viewOriginY + animationOffset;
            } completion:nil];
        }
    }
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    if (!self.textInput.isFirstResponder) return;
    
    if (self.keyboardView) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithDictionary:notification.userInfo];
        CGFloat animationDuration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
        
        [UIView animateWithDuration:animationDuration animations:^{
            self.keyboardView.transform = CGAffineTransformIdentity;
        } completion:nil];
    }
    
    if (self.keyboardManager) {
        if (!self.keyboardController) return;
        NSDictionary *userInfo = [NSDictionary dictionaryWithDictionary:notification.userInfo];
        CGFloat animationDuration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
        
        [UIView animateWithDuration:animationDuration animations:^{
            self.keyboardController.viewController.view.fwY = self.keyboardController.viewOriginY;
        } completion:^(BOOL finished) {
            self.keyboardController.isKeyboardShow = NO;
            self.keyboardController.viewOriginY = 0;
            self.keyboardController.viewOffsetY = 0;
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
