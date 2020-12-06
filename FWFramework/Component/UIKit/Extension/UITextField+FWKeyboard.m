//
//  UITextField+FWKeyboard.m
//  FWFramework
//
//  Created by wuyong on 2017/4/6.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "UITextField+FWKeyboard.h"
#import "FWProxy.h"
#import "FWBlock.h"
#import "FWHelper.h"
#import <objc/runtime.h>

#pragma mark - FWInnerKeyboardTarget

static BOOL fwStaticKeyboardShowing = NO;
static CGFloat fwStaticKeyboardOrigin = 0;
static UITapGestureRecognizer *fwStaticKeyboardGesture = nil;

@interface FWInnerKeyboardTarget : NSObject

@property (nonatomic, assign) BOOL keyboardManager;
@property (nonatomic, assign) CGFloat keyboardSpacing;
@property (nonatomic, assign) BOOL keyboardResign;
@property (nonatomic, assign) BOOL touchResign;

@property (nonatomic, assign) BOOL returnResign;
@property (nonatomic, weak) UIResponder *returnResponder;
@property (nonatomic, copy) void (^returnBlock)(id textInput);

@property (nonatomic, weak, readonly) UIView<UITextInput> *textInput;
@property (nonatomic, weak) UIViewController *viewController;
@property (nonatomic, assign) BOOL keyboardActive;

@end

@implementation FWInnerKeyboardTarget

- (instancetype)initWithTextInput:(UIView<UITextInput> *)textInput
{
    self = [super init];
    if (self) {
        _textInput = textInput;
        _keyboardSpacing = 10.0;
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
    if (keyboardManager != _keyboardManager) {
        _keyboardManager = keyboardManager;
        
        if (keyboardManager) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
        } else {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
        }
    }
}

- (void)setTouchResign:(BOOL)touchResign
{
    if (touchResign != _touchResign) {
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
}

- (void)setKeyboardResign:(BOOL)keyboardResign
{
    if (keyboardResign != _keyboardResign) {
        _keyboardResign = keyboardResign;
        
        if (keyboardResign) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appResignActive) name:UIApplicationWillResignActiveNotification object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
        } else {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
        }
    }
}

- (UIViewController *)viewController
{
    if (!_viewController) {
        _viewController = [self.textInput fwViewController];
    }
    return _viewController;
}

#pragma mark - Resign

- (void)editingDidBegin
{
    if (!self.touchResign) return;
    if (!self.viewController) return;
    
    if (!fwStaticKeyboardGesture) {
        fwStaticKeyboardGesture = [UITapGestureRecognizer fwGestureRecognizerWithBlock:^(UITapGestureRecognizer *sender) {
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

#pragma mark - Keyboard

- (void)keyboardWillShow:(NSNotification *)notification
{
    if (!self.textInput.isFirstResponder) return;
    if (!self.keyboardManager || !self.viewController) return;
    
    if (!fwStaticKeyboardShowing) {
        fwStaticKeyboardShowing = YES;
        fwStaticKeyboardOrigin = self.viewController.view.frame.origin.y;
    }
    
    CGRect keyboardRect = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat animationDuration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    UIView *convertView = self.textInput.window ?: self.viewController.view.window;
    CGRect convertRect = [self.textInput convertRect:self.textInput.bounds toView:convertView];
    CGFloat viewTargetY = MIN(self.viewController.view.frame.origin.y + CGRectGetMinY(keyboardRect) - self.keyboardSpacing - CGRectGetMaxY(convertRect), fwStaticKeyboardOrigin);
    
    CGRect viewFrame = self.viewController.view.frame;
    viewFrame.origin.y = viewTargetY;
    [UIView animateWithDuration:animationDuration animations:^{
        // 修复iOS14当vc.hidesBottomBarWhenPushed为YES时view.frame会被导航栏重置引起的滚动失效问题
        if (@available(iOS 14.0, *)) {
            self.viewController.view.layer.frame = viewFrame;
        } else {
            self.viewController.view.frame = viewFrame;
        }
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    if (!self.textInput.isFirstResponder) return;
    if (!self.keyboardManager || !self.viewController || !fwStaticKeyboardShowing) return;
    
    CGFloat viewOriginY = fwStaticKeyboardOrigin;
    fwStaticKeyboardShowing = NO;
    fwStaticKeyboardOrigin = 0;
    
    CGFloat animationDuration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    
    CGRect viewFrame = self.viewController.view.frame;
    viewFrame.origin.y = viewOriginY;
    [UIView animateWithDuration:animationDuration animations:^{
        // 修复iOS14当vc.hidesBottomBarWhenPushed为YES时view.frame会被导航栏重置引起的滚动失效问题
        if (@available(iOS 14.0, *)) {
            self.viewController.view.layer.frame = viewFrame;
        } else {
            self.viewController.view.frame = viewFrame;
        }
    }];
}

#pragma mark - Toolbar

- (void)addToolbar:(UIBarStyle)barStyle title:(NSString *)title block:(void (^)(id sender))block
{
    UIBarButtonItem *rightItem = nil;
    NSString *rightTitle = title.length > 0 ? title : NSLocalizedString(@"完成", nil);
    if (block != nil) {
        rightItem = [UIBarButtonItem fwBarItemWithObject:rightTitle block:block];
        rightItem.style = UIBarButtonItemStyleDone;
    } else {
        rightItem = [[UIBarButtonItem alloc] initWithTitle:rightTitle style:UIBarButtonItemStyleDone target:self.textInput action:@selector(resignFirstResponder)];
    }
    [self addToolbar:barStyle leftItem:nil rightItem:rightItem];
}

- (void)addToolbar:(UIBarStyle)barStyle leftItem:(UIBarButtonItem *)leftItem rightItem:(UIBarButtonItem *)rightItem
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
    ((UITextField *)self.textInput).inputAccessoryView = toolbar;
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
    return self.fwInnerKeyboardTarget.returnResign;
}

- (void)setFwReturnResign:(BOOL)fwReturnResign
{
    self.fwInnerKeyboardTarget.returnResign = fwReturnResign;
    [self fwInnerReturnEvent];
}

- (UIResponder *)fwReturnResponder
{
    return self.fwInnerKeyboardTarget.returnResponder;
}

- (void)setFwReturnResponder:(UIResponder *)fwReturnResponder
{
    self.fwInnerKeyboardTarget.returnResponder = fwReturnResponder;
    [self fwInnerReturnEvent];
}

- (void (^)(UITextField *textField))fwReturnBlock
{
    return self.fwInnerKeyboardTarget.returnBlock;
}

- (void)setFwReturnBlock:(void (^)(UITextField *textField))fwReturnBlock
{
    self.fwInnerKeyboardTarget.returnBlock = fwReturnBlock;
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
    [self.fwInnerKeyboardTarget addToolbar:barStyle title:title block:block];
}

- (void)fwAddToolbar:(UIBarStyle)barStyle leftItem:(UIBarButtonItem *)leftItem rightItem:(UIBarButtonItem *)rightItem
{
    [self.fwInnerKeyboardTarget addToolbar:barStyle leftItem:leftItem rightItem:rightItem];
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
    return self.fwInnerKeyboardTarget.returnResign;
}

- (void)setFwReturnResign:(BOOL)fwReturnResign
{
    self.fwInnerKeyboardTarget.returnResign = fwReturnResign;
    self.fwDelegateProxyEnabled = YES;
}

- (UIResponder *)fwReturnResponder
{
    return self.fwInnerKeyboardTarget.returnResponder;
}

- (void)setFwReturnResponder:(UIResponder *)fwReturnResponder
{
    self.fwInnerKeyboardTarget.returnResponder = fwReturnResponder;
    self.fwDelegateProxyEnabled = YES;
}

- (void (^)(UITextView *textView))fwReturnBlock
{
    return self.fwInnerKeyboardTarget.returnBlock;
}

- (void)setFwReturnBlock:(void (^)(UITextView *textView))fwReturnBlock
{
    self.fwInnerKeyboardTarget.returnBlock = fwReturnBlock;
    self.fwDelegateProxyEnabled = YES;
}

#pragma mark - Toolbar

- (void)fwAddToolbar:(UIBarStyle)barStyle title:(NSString *)title block:(void (^)(id sender))block
{
    [self.fwInnerKeyboardTarget addToolbar:barStyle title:title block:block];
}

- (void)fwAddToolbar:(UIBarStyle)barStyle leftItem:(UIBarButtonItem *)leftItem rightItem:(UIBarButtonItem *)rightItem
{
    [self.fwInnerKeyboardTarget addToolbar:barStyle leftItem:leftItem rightItem:rightItem];
}

@end
