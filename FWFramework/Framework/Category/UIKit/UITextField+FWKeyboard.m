//
//  UITextField+FWKeyboard.m
//  FWFramework
//
//  Created by wuyong on 2017/4/6.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "UITextField+FWKeyboard.h"
#import <objc/runtime.h>

#pragma mark - FWInnerKeyboardTarget

// 键盘动画偏移值，多个输入框共用一个
static CGFloat globalOffset = 0.0;

@interface FWInnerKeyboardTarget : NSObject

@property (nonatomic, assign) BOOL keyboardManager;

@property (nonatomic, assign) CGFloat keyboardSpacing;

@property (nonatomic, assign) BOOL touchResign;

@property (nonatomic, weak) UIView *keyboardView;

@property (nonatomic, weak, readonly) UIView<UITextInput> *textInput;

@property (nonatomic, strong) UITapGestureRecognizer *touchGesture;

@property (nonatomic, weak) UIView *animationView;

- (instancetype)initWithTextInput:(UIView<UITextInput> *)textInput;

@end

@implementation FWInnerKeyboardTarget

- (instancetype)initWithTextInput:(UIView<UITextInput> *)textInput
{
    self = [super init];
    if (self) {
        _textInput = textInput;
        _keyboardSpacing = 10.0;
        
        // 监听开始和结束编辑
        if ([textInput isKindOfClass:[UITextField class]]) {
            [(UITextField *)textInput addTarget:self action:@selector(editingDidBegin) forControlEvents:UIControlEventEditingDidBegin];
            [(UITextField *)textInput addTarget:self action:@selector(editingDidEnd) forControlEvents:UIControlEventEditingDidEnd];
        } else if ([textInput isKindOfClass:[UITextView class]]) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editingDidBegin) name:UITextViewTextDidBeginEditingNotification object:textInput];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editingDidEnd) name:UITextViewTextDidEndEditingNotification object:textInput];
        }
        
        // 监听键盘弹出事件
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// 获取关联的视图控制器
- (UIViewController *)viewController
{
    UIResponder *responder = [self.textInput nextResponder];
    while (responder) {
        if ([responder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)responder;
        }
        responder = [responder nextResponder];
    }
    return nil;
}

#pragma mark - Resign

- (void)editingDidBegin
{
    if (self.touchResign) {
        [self touchGestureEnable:YES];
    }
}

- (void)editingDidEnd
{
    if (self.touchResign) {
        [self touchGestureEnable:NO];
    }
}

- (void)touchGestureEnable:(BOOL)enable
{
    // 获取关联的视图控制器视图
    UIView *gestureView = self.viewController.view;
    if (!gestureView) {
        return;
    }
    
    // 初始化手势
    if (!self.touchGesture) {
        self.touchGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(touchGestureAction:)];
    }
    
    // 启用或禁用手势
    if (enable) {
        [gestureView addGestureRecognizer:self.touchGesture];
    } else {
        [gestureView removeGestureRecognizer:self.touchGesture];
    }
}

- (void)touchGestureAction:(UITapGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateEnded) {
        [self.textInput resignFirstResponder];
    }
}

#pragma mark - Keyboard

- (void)keyboardWillShow:(NSNotification *)note
{
    // 输入框处于激活状态才处理
    if (!self.textInput.isFirstResponder) {
        return;
    }
    
    // 视图上移到键盘上方处理
    if (self.keyboardView) {
        // 获取用户信息
        NSDictionary *userInfo = [NSDictionary dictionaryWithDictionary:note.userInfo];
        // 获取键盘高度
        CGFloat keyboardHeight = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
        // 获取键盘动画时间
        CGFloat animationDuration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
        
        // 保存当前动画视图，供hide动画使用。如果直接使用keyboardView并在hide之前修改了该视图，会导致动画不能还原
        self.animationView = self.keyboardView;
        void (^animation)(void) = ^void(void){
            self.animationView.transform = CGAffineTransformMakeTranslation(0, -keyboardHeight);
        };
        if (animationDuration > 0) {
            [UIView animateWithDuration:animationDuration animations:animation];
        } else {
            animation();
        }
    }
    
    // 输入框自动滚动到键盘上方处理
    if (self.keyboardManager) {
        // 获取用户信息
        NSDictionary *userInfo = [NSDictionary dictionaryWithDictionary:note.userInfo];
        CGRect keyboardRect = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
        // 获取动画视图和窗口视图
        UIView *targetView = self.viewController.view;
        UIWindow *targetWindow = self.textInput.window ? self.textInput.window : targetView.window;
        if (!targetView || !targetWindow) {
            return;
        }
        
        // 注意：此处应该是需要转换控件的参考系视图，而不是自身。即textField.superview frame| textField bounds，而不是textField frame
        // 此处相对于window，因为keyboardRect相对于window而言。要么不转换，要么同时转换
        CGRect convertRect = [self.textInput.superview convertRect:self.textInput.frame toView:targetWindow];
        // 多个输入框时不会调用willHide，导致不会还原
        CGFloat maxY = CGRectGetMaxY(convertRect);
        if (globalOffset != 0) {
            maxY -= globalOffset;
        }
        
        // 判断是否需要自动滚动动画
        if (CGRectGetMinY(keyboardRect) - self.keyboardSpacing < maxY) {
            // 计算动画偏移高度
            CGFloat animationOffset = CGRectGetMinY(keyboardRect) - self.keyboardSpacing - maxY;
            globalOffset = animationOffset;
            // 获取键盘动画时间
            CGFloat animationDuration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
            
            // 保存当前动画视图，供hide动画使用。如果直接使用并在hide之前修改了该视图，会导致动画不能还原
            self.animationView = targetView;
            void (^animation)(void) = ^void(void){
                self.animationView.transform = CGAffineTransformMakeTranslation(0, animationOffset);
            };
            if (animationDuration > 0) {
                [UIView animateWithDuration:animationDuration animations:animation];
            } else {
                animation();
            }
        }
    }
}

- (void)keyboardWillHide:(NSNotification *)note
{
    // 输入框处于激活状态才处理
    if (!self.textInput.isFirstResponder) {
        return;
    }
    
    // 视图上移到键盘上方处理
    if (self.keyboardView) {
        // 获取用户信息
        NSDictionary *userInfo = [NSDictionary dictionaryWithDictionary:note.userInfo];
        // 获取键盘动画时间
        CGFloat animationDuration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
        
        // 获取动画视图，不能直接使用keyboardView，原因见show方法注释
        void (^animation)(void) = ^void(void){
            self.animationView.transform = CGAffineTransformIdentity;
        };
        if (animationDuration > 0) {
            [UIView animateWithDuration:animationDuration animations:animation];
        } else {
            animation();
        }
    }
    
    // 输入框自动滚动到键盘上方处理
    if (self.keyboardManager) {
        // 获取用户信息
        NSDictionary *userInfo = [NSDictionary dictionaryWithDictionary:note.userInfo];
        UIView *targetView = self.viewController.view;
        if (!targetView) {
            return;
        }
        
        // 重置键盘动画偏移值
        globalOffset = 0.0;
        // 获取键盘动画时间
        CGFloat animationDuration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
        
        // 获取动画视图，不能直接使用targetView，原因见show方法注释
        void (^animation)(void) = ^void(void){
            self.animationView.transform = CGAffineTransformIdentity;
        };
        if (animationDuration > 0) {
            [UIView animateWithDuration:animationDuration animations:animation];
        } else {
            animation();
        }
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
