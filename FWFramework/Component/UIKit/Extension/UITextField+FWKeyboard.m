//
//  UITextField+FWKeyboard.m
//  FWFramework
//
//  Created by wuyong on 2017/4/6.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "UITextField+FWKeyboard.h"
#import "UIView+FWFramework.h"
#import "FWProxy.h"
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
    if (!self.keyboardManager) return;
    if (!self.keyboardController) return;
    
    CGRect keyboardRect = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat animationDuration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];

    if (!self.keyboardController.keyboardShowing) {
        self.keyboardController.keyboardShowing = YES;
        self.keyboardController.animationOrigin = self.keyboardController.viewController.view.fwY;
    }
    
    UIView *convertView = self.textInput.window ?: self.keyboardController.viewController.view.window;
    CGRect convertRect = [self.textInput convertRect:self.textInput.bounds toView:convertView];
    CGFloat animationOffset = CGRectGetMinY(keyboardRect) - self.keyboardSpacing - CGRectGetMaxY(convertRect);
    CGFloat targetY = self.keyboardController.viewController.view.fwY + animationOffset;
    if (targetY > self.keyboardController.animationOrigin) {
        targetY = self.keyboardController.animationOrigin;
    }
    [UIView animateWithDuration:animationDuration animations:^{
        self.keyboardController.viewController.view.fwY = targetY;
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    if (!self.textInput.isFirstResponder) return;
    if (!self.keyboardManager) return;
    if (!self.keyboardController.keyboardShowing) return;
    
    CGFloat animationOrigin = self.keyboardController.animationOrigin;
    CGFloat animationDuration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    self.keyboardController.keyboardShowing = NO;
    self.keyboardController.animationOrigin = 0;
    
    [UIView animateWithDuration:animationDuration animations:^{
        self.keyboardController.viewController.view.fwY = animationOrigin;
    }];
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
    if (textView.fwReturnResign || textView.fwReturnResponder || textView.fwReturnBlock) {
        // 判断是否输入回车
        if ([text isEqualToString:@"\n"]) {
            // 切换到下一个输入框
            if (textView.fwReturnResponder) {
                [textView.fwReturnResponder becomeFirstResponder];
            // 关闭键盘
            } else if (textView.fwReturnResign) {
                [textView resignFirstResponder];
            }
            // 执行回调
            if (textView.fwReturnBlock) {
                textView.fwReturnBlock(textView);
            }
            shouldChange = NO;
        }
    }
    return shouldChange;
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

- (FWInnerKeyboardTarget *)fwInnerKeyboardTarget
{
    FWInnerKeyboardTarget *target = objc_getAssociatedObject(self, _cmd);
    if (!target) {
        target = [[FWInnerKeyboardTarget alloc] initWithTextInput:self];
        objc_setAssociatedObject(self, _cmd, target, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return target;
}

#pragma mark - Return

- (BOOL)fwReturnResign
{
    return [objc_getAssociatedObject(self, @selector(fwReturnResign)) boolValue];
}

- (void)setFwReturnResign:(BOOL)fwReturnResign
{
    objc_setAssociatedObject(self, @selector(fwReturnResign), @(fwReturnResign), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self fwInnerReturnEvent];
}

- (UIResponder *)fwReturnResponder
{
    FWWeakObject *value = objc_getAssociatedObject(self, @selector(fwReturnResponder));
    return value.object;
}

- (void)setFwReturnResponder:(UIResponder *)fwReturnResponder
{
    // 此处weak引用responder
    objc_setAssociatedObject(self, @selector(fwReturnResponder), [[FWWeakObject alloc] initWithObject:fwReturnResponder], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self fwInnerReturnEvent];
}

- (void (^)(UITextField *textField))fwReturnBlock
{
    return objc_getAssociatedObject(self, @selector(fwReturnBlock));
}

- (void)setFwReturnBlock:(void (^)(UITextField *textField))fwReturnBlock
{
    objc_setAssociatedObject(self, @selector(fwReturnBlock), fwReturnBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
    [self fwInnerReturnEvent];
}

- (void)fwInnerReturnEvent
{
    id object = objc_getAssociatedObject(self, _cmd);
    if (!object) {
        [self addTarget:self action:@selector(fwInnerReturnAction) forControlEvents:UIControlEventEditingDidEndOnExit];
        objc_setAssociatedObject(self, _cmd, @(1), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (void)fwInnerReturnAction
{
    // 切换到下一个输入框
    if (self.fwReturnResponder) {
        [self.fwReturnResponder becomeFirstResponder];
    // 关闭键盘
    } else if (self.fwReturnResign) {
        [self resignFirstResponder];
    }
    // 执行回调
    if (self.fwReturnBlock) {
        self.fwReturnBlock(self);
    }
}

#pragma mark - Toolbar

- (void)fwAddToolbar:(UIBarStyle)barStyle title:(NSString *)title block:(void (^)(id sender))block
{
    UIBarButtonItem *rightItem = nil;
    NSString *rightTitle = title.length > 0 ? title : NSLocalizedString(@"完成", nil);
    if (block != nil) {
        rightItem = [UIBarButtonItem fwBarItemWithObject:rightTitle block:block];
        rightItem.style = UIBarButtonItemStyleDone;
    } else {
        rightItem = [[UIBarButtonItem alloc] initWithTitle:rightTitle style:UIBarButtonItemStyleDone target:self action:@selector(resignFirstResponder)];
    }
    [self fwAddToolbar:barStyle leftItem:nil rightItem:rightItem];
}

- (void)fwAddToolbar:(UIBarStyle)barStyle leftItem:(UIBarButtonItem *)leftItem rightItem:(UIBarButtonItem *)rightItem
{
    NSMutableArray<UIBarButtonItem *> *items = [NSMutableArray array];
    if (leftItem != nil) {
        [items addObject:leftItem];
    }
    [items addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
    if (rightItem != nil) {
        [items addObject:rightItem];
    }
    
    UIToolbar *toolbar = [UIToolbar new];
    toolbar.items = [items copy];
    toolbar.barStyle = barStyle;
    [toolbar sizeToFit];
    self.inputAccessoryView = toolbar;
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

- (FWInnerKeyboardTarget *)fwInnerKeyboardTarget
{
    FWInnerKeyboardTarget *target = objc_getAssociatedObject(self, _cmd);
    if (!target) {
        target = [[FWInnerKeyboardTarget alloc] initWithTextInput:self];
        objc_setAssociatedObject(self, _cmd, target, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return target;
}

#pragma mark - Delegate

- (id<UITextViewDelegate>)fwDelegate
{
    if (!self.fwDelegateProxyEnabled) {
        return self.delegate;
    } else {
        return self.fwDelegateProxy.delegate;
    }
}

- (void)setFwDelegate:(id<UITextViewDelegate>)fwDelegate
{
    if (!self.fwDelegateProxyEnabled) {
        self.delegate = fwDelegate;
    } else {
        self.fwDelegateProxy.delegate = fwDelegate;
    }
}

- (BOOL)fwDelegateProxyEnabled
{
    return self.delegate == self.fwDelegateProxy;
}

- (void)setFwDelegateProxyEnabled:(BOOL)enabled
{
    if (enabled != self.fwDelegateProxyEnabled) {
        if (enabled) {
            self.fwDelegateProxy.delegate = self.delegate;
            self.delegate = self.fwDelegateProxy;
        } else {
            self.delegate = self.fwDelegateProxy.delegate;
            self.fwDelegateProxy.delegate = nil;
        }
    }
}

- (__kindof FWDelegateProxy *)fwDelegateProxy
{
    FWDelegateProxy *proxy = objc_getAssociatedObject(self, _cmd);
    if (!proxy) {
        proxy = [[FWTextViewDelegateProxy alloc] init];
        objc_setAssociatedObject(self, _cmd, proxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return proxy;
}

#pragma mark - Return

- (BOOL)fwReturnResign
{
    return [objc_getAssociatedObject(self, @selector(fwReturnResign)) boolValue];
}

- (void)setFwReturnResign:(BOOL)fwReturnResign
{
    objc_setAssociatedObject(self, @selector(fwReturnResign), @(fwReturnResign), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.fwDelegateProxyEnabled = YES;
}

- (UIResponder *)fwReturnResponder
{
    FWWeakObject *value = objc_getAssociatedObject(self, @selector(fwReturnResponder));
    return value.object;
}

- (void)setFwReturnResponder:(UIResponder *)fwReturnResponder
{
    // 此处weak引用responder
    objc_setAssociatedObject(self, @selector(fwReturnResponder), [[FWWeakObject alloc] initWithObject:fwReturnResponder], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.fwDelegateProxyEnabled = YES;
}

- (void (^)(UITextView *textView))fwReturnBlock
{
    return objc_getAssociatedObject(self, @selector(fwReturnBlock));
}

- (void)setFwReturnBlock:(void (^)(UITextView *textView))fwReturnBlock
{
    objc_setAssociatedObject(self, @selector(fwReturnBlock), fwReturnBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
    self.fwDelegateProxyEnabled = YES;
}

#pragma mark - Toolbar

- (void)fwAddToolbar:(UIBarStyle)barStyle title:(NSString *)title block:(void (^)(id sender))block
{
    UIBarButtonItem *rightItem = nil;
    NSString *rightTitle = title.length > 0 ? title : NSLocalizedString(@"完成", nil);
    if (block != nil) {
        rightItem = [UIBarButtonItem fwBarItemWithObject:rightTitle block:block];
        rightItem.style = UIBarButtonItemStyleDone;
    } else {
        rightItem = [[UIBarButtonItem alloc] initWithTitle:rightTitle style:UIBarButtonItemStyleDone target:self action:@selector(resignFirstResponder)];
    }
    [self fwAddToolbar:barStyle leftItem:nil rightItem:rightItem];
}

- (void)fwAddToolbar:(UIBarStyle)barStyle leftItem:(UIBarButtonItem *)leftItem rightItem:(UIBarButtonItem *)rightItem
{
    NSMutableArray<UIBarButtonItem *> *items = [NSMutableArray array];
    if (leftItem != nil) {
        [items addObject:leftItem];
    }
    [items addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
    if (rightItem != nil) {
        [items addObject:rightItem];
    }
    
    UIToolbar *toolbar = [UIToolbar new];
    toolbar.items = [items copy];
    toolbar.barStyle = barStyle;
    [toolbar sizeToFit];
    self.inputAccessoryView = toolbar;
}

@end
