/**
 @header     FWKeyboard.m
 @indexgroup FWFramework
      FWKeyboard
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/10/22
 */

#import "FWKeyboard.h"
#import "FWBlock.h"
#import "FWUIKit.h"
#import "FWMessage.h"
#import "FWProxy.h"
#import "FWSwizzle.h"
#import <objc/runtime.h>

#pragma mark - FWInnerKeyboardTarget

static BOOL fwStaticKeyboardShowing = NO;
static CGFloat fwStaticKeyboardOrigin = 0;
static CGFloat fwStaticKeyboardOffset = 0;
static UITapGestureRecognizer *fwStaticKeyboardGesture = nil;

@interface FWInnerKeyboardTarget : NSObject

@property (nonatomic, assign) BOOL keyboardManager;
@property (nonatomic, assign) CGFloat keyboardDistance;
@property (nonatomic, assign) CGFloat reboundHeight;
@property (nonatomic, assign) BOOL keyboardResign;
@property (nonatomic, assign) BOOL touchResign;

@property (nonatomic, assign) BOOL returnResign;
@property (nonatomic, weak) UIResponder *returnResponder;
@property (nonatomic, copy) void (^returnBlock)(id textInput);

@property (nonatomic, strong) UIToolbar *keyboardToolbar;
@property (nonatomic, weak) UIResponder *previousResponder;
@property (nonatomic, weak) UIResponder *nextResponder;

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
        _keyboardDistance = 15.0;
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
        _viewController = [self.textInput.fw viewController];
    }
    return _viewController;
}

#pragma mark - Resign

- (void)editingDidBegin
{
    if (!self.touchResign) return;
    if (!self.viewController) return;
    
    if (!fwStaticKeyboardGesture) {
        fwStaticKeyboardGesture = [UITapGestureRecognizer.fw gestureRecognizerWithBlock:^(UITapGestureRecognizer *sender) {
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

- (void)innerReturnAction
{
    // 切换到下一个输入框
    if (self.returnResponder) {
        [self.returnResponder becomeFirstResponder];
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
        UIView *convertView = self.textInput.window ?: self.viewController.view.window;
        CGRect convertRect = [self.textInput convertRect:self.textInput.bounds toView:convertView];
        CGPoint contentOffset = self.scrollView.contentOffset;
        CGFloat targetOffsetY = MAX(contentOffset.y + self.keyboardDistance + CGRectGetMaxY(convertRect) - CGRectGetMinY(keyboardRect), fwStaticKeyboardOffset);
        
        BOOL shouldScroll = NO;
        if (targetOffsetY > contentOffset.y) {
            shouldScroll = YES;
        } else if (targetOffsetY <= contentOffset.y - self.reboundHeight) {
            shouldScroll = YES;
            targetOffsetY = targetOffsetY + self.reboundHeight;
        }
        if (shouldScroll) {
            contentOffset.y = targetOffsetY;
            [UIView animateWithDuration:animationDuration animations:^{
                self.scrollView.contentOffset = contentOffset;
            }];
        }
        return;
    }
    
    if (!fwStaticKeyboardShowing) {
        fwStaticKeyboardShowing = YES;
        fwStaticKeyboardOrigin = self.viewController.view.frame.origin.y;
    }
    
    CGRect keyboardRect = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat animationDuration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    UIView *convertView = self.textInput.window ?: self.viewController.view.window;
    CGRect convertRect = [self.textInput convertRect:self.textInput.bounds toView:convertView];
    CGRect viewFrame = self.viewController.view.frame;
    CGFloat viewTargetY = MIN(viewFrame.origin.y - self.keyboardDistance + CGRectGetMinY(keyboardRect) - CGRectGetMaxY(convertRect), fwStaticKeyboardOrigin);
    
    BOOL shouldScroll = NO;
    if (viewTargetY > viewFrame.origin.y) {
        shouldScroll = YES;
    } else if (viewTargetY <= viewFrame.origin.y - self.reboundHeight) {
        shouldScroll = YES;
        viewTargetY = viewTargetY + self.reboundHeight;
    }
    if (shouldScroll) {
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
        
        CGPoint contentOffset = self.scrollView.contentOffset;
        contentOffset.y = originOffsetY;
        [UIView animateWithDuration:animationDuration animations:^{
            self.scrollView.contentOffset = contentOffset;
        }];
        return;
    }
    
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

- (UIToolbar *)keyboardToolbar
{
    if (!_keyboardToolbar) {
        _keyboardToolbar = [UIToolbar new];
    }
    return _keyboardToolbar;
}

- (void)addToolbarWithTitle:(id)title
             previousButton:(id)previousButton
                 nextButton:(id)nextButton
                rightButton:(id)rightButton
                      block:(void (^)(id sender))block
{
    UIBarButtonItem *titleItem = title ? [UIBarButtonItem.fw itemWithObject:title block:nil] : nil;
    titleItem.enabled = NO;
    UIBarButtonItem *previousItem = previousButton ? [UIBarButtonItem.fw itemWithObject:previousButton target:self.previousResponder action:@selector(becomeFirstResponder)] : nil;
    previousItem.enabled = self.previousResponder != nil;
    UIBarButtonItem *nextItem = nextButton ? [UIBarButtonItem.fw itemWithObject:nextButton target:self.nextResponder action:@selector(becomeFirstResponder)] : nil;
    nextItem.enabled = self.nextResponder != nil;
    
    UIBarButtonItem *rightItem;
    if (rightButton) {
        if (block) {
            rightItem = [UIBarButtonItem.fw itemWithObject:rightButton block:block];
            rightItem.style = UIBarButtonItemStyleDone;
        } else {
            rightItem = [UIBarButtonItem.fw itemWithObject:rightButton target:self.textInput action:@selector(resignFirstResponder)];
        }
    }
    
    [self addToolbarWithTitleItem:titleItem previousItem:previousItem nextItem:nextItem rightItem:rightItem];
}

- (void)addToolbarWithTitleItem:(nullable UIBarButtonItem *)titleItem
                   previousItem:(nullable UIBarButtonItem *)previousItem
                       nextItem:(nullable UIBarButtonItem *)nextItem
                      rightItem:(nullable UIBarButtonItem *)rightItem
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
    if (rightItem) [items addObject:rightItem];
    
    UIToolbar *toolbar = self.keyboardToolbar;
    toolbar.items = [items copy];
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
    if (textView.fw.returnResign || textView.fw.returnResponder || textView.fw.returnBlock) {
        // 判断是否输入回车
        if ([text isEqualToString:@"\n"]) {
            // 切换到下一个输入框
            if (textView.fw.returnResponder) {
                [textView.fw.returnResponder becomeFirstResponder];
            // 关闭键盘
            } else if (textView.fw.returnResign) {
                [textView resignFirstResponder];
            }
            // 执行回调
            if (textView.fw.returnBlock) {
                textView.fw.returnBlock(textView);
            }
            shouldChange = NO;
        }
    }
    return shouldChange;
}

@end

#pragma mark - FWTextFieldWrapper+FWKeyboard

@interface FWTextFieldWrapper (FWKeyboardInternal)

@property (nonatomic, strong, readonly) FWInnerKeyboardTarget *innerKeyboardTarget;

- (void)innerReturnEvent;

@end

@interface UITextField (FWKeyboard)

@end

@implementation UITextField (FWKeyboard)

- (BOOL)innerKeyboardManager
{
    return self.fw.innerKeyboardTarget.keyboardManager;
}

- (void)setInnerKeyboardManager:(BOOL)keyboardManager
{
    self.fw.innerKeyboardTarget.keyboardManager = keyboardManager;
}

- (CGFloat)innerKeyboardDistance
{
    return self.fw.innerKeyboardTarget.keyboardDistance;
}

- (void)setInnerKeyboardDistance:(CGFloat)keyboardDistance
{
    self.fw.innerKeyboardTarget.keyboardDistance = keyboardDistance;
}

- (CGFloat)innerReboundHeight
{
    return self.fw.innerKeyboardTarget.reboundHeight;
}

- (void)setInnerReboundHeight:(CGFloat)reboundHeight
{
    self.fw.innerKeyboardTarget.reboundHeight = reboundHeight;
}

- (BOOL)innerKeyboardResign
{
    return self.fw.innerKeyboardTarget.keyboardResign;
}

- (void)setInnerKeyboardResign:(BOOL)keyboardResign
{
    self.fw.innerKeyboardTarget.keyboardResign = keyboardResign;
}

- (UIScrollView *)innerKeyboardScrollView
{
    return self.fw.innerKeyboardTarget.scrollView;
}

- (void)setInnerKeyboardScrollView:(UIScrollView *)keyboardScrollView
{
    self.fw.innerKeyboardTarget.scrollView = keyboardScrollView;
}

- (BOOL)innerTouchResign
{
    return self.fw.innerKeyboardTarget.touchResign;
}

- (void)setInnerTouchResign:(BOOL)touchResign
{
    self.fw.innerKeyboardTarget.touchResign = touchResign;
}

- (BOOL)innerReturnResign
{
    return self.fw.innerKeyboardTarget.returnResign;
}

- (void)setInnerReturnResign:(BOOL)returnResign
{
    self.fw.innerKeyboardTarget.returnResign = returnResign;
    [self.fw innerReturnEvent];
}

@end

@implementation FWTextFieldWrapper (FWKeyboard)

- (BOOL)keyboardManager
{
    return self.base.innerKeyboardManager;
}

- (void)setKeyboardManager:(BOOL)keyboardManager
{
    self.base.innerKeyboardManager = keyboardManager;
}

- (CGFloat)keyboardDistance
{
    return self.base.innerKeyboardDistance;
}

- (void)setKeyboardDistance:(CGFloat)keyboardDistance
{
    self.base.innerKeyboardDistance = keyboardDistance;
}

- (CGFloat)reboundHeight
{
    return self.base.innerReboundHeight;
}

- (void)setReboundHeight:(CGFloat)reboundHeight
{
    self.base.innerReboundHeight = reboundHeight;
}

- (BOOL)keyboardResign
{
    return self.base.innerKeyboardResign;
}

- (void)setKeyboardResign:(BOOL)keyboardResign
{
    self.base.innerKeyboardResign = keyboardResign;
}

- (BOOL)touchResign
{
    return self.base.innerTouchResign;
}

- (void)setTouchResign:(BOOL)touchResign
{
    self.base.innerTouchResign = touchResign;
}

- (UIScrollView *)keyboardScrollView
{
    return self.base.innerKeyboardScrollView;
}

- (void)setKeyboardScrollView:(UIScrollView *)keyboardScrollView
{
    self.base.innerKeyboardScrollView = keyboardScrollView;
}

- (FWInnerKeyboardTarget *)innerKeyboardTarget
{
    FWInnerKeyboardTarget *target = objc_getAssociatedObject(self.base, _cmd);
    if (!target) {
        target = [[FWInnerKeyboardTarget alloc] initWithTextInput:self.base];
        objc_setAssociatedObject(self.base, _cmd, target, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return target;
}

#pragma mark - Return

- (BOOL)returnResign
{
    return self.base.innerReturnResign;
}

- (void)setReturnResign:(BOOL)returnResign
{
    self.base.innerReturnResign = returnResign;
}

- (UIResponder *)returnResponder
{
    return self.innerKeyboardTarget.returnResponder;
}

- (void)setReturnResponder:(UIResponder *)returnResponder
{
    self.innerKeyboardTarget.returnResponder = returnResponder;
    [self innerReturnEvent];
}

- (void (^)(UITextField *textField))returnBlock
{
    return self.innerKeyboardTarget.returnBlock;
}

- (void)setReturnBlock:(void (^)(UITextField *textField))returnBlock
{
    self.innerKeyboardTarget.returnBlock = returnBlock;
    [self innerReturnEvent];
}

- (void)innerReturnEvent
{
    id object = objc_getAssociatedObject(self.base, _cmd);
    if (!object) {
        [self.base addTarget:self.innerKeyboardTarget action:@selector(innerReturnAction) forControlEvents:UIControlEventEditingDidEndOnExit];
        objc_setAssociatedObject(self.base, _cmd, @(1), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

#pragma mark - Toolbar

- (UIToolbar *)keyboardToolbar
{
    return self.innerKeyboardTarget.keyboardToolbar;
}

- (void)setKeyboardToolbar:(UIToolbar *)keyboardToolbar
{
    self.innerKeyboardTarget.keyboardToolbar = keyboardToolbar;
}

- (UIResponder *)previousResponder
{
    return self.innerKeyboardTarget.previousResponder;
}

- (void)setPreviousResponder:(UIResponder *)previousResponder
{
    self.innerKeyboardTarget.previousResponder = previousResponder;
}

- (UIResponder *)nextResponder
{
    return self.innerKeyboardTarget.nextResponder;
}

- (void)setNextResponder:(UIResponder *)nextResponder
{
    self.innerKeyboardTarget.nextResponder = nextResponder;
}

- (void)addToolbarWithTitle:(id)title
             previousButton:(id)previousButton
                 nextButton:(id)nextButton
                rightButton:(id)rightButton
                      block:(void (^)(id))block
{
    [self.innerKeyboardTarget addToolbarWithTitle:title previousButton:previousButton nextButton:nextButton rightButton:rightButton block:block];
}

- (void)addToolbarWithTitleItem:(UIBarButtonItem *)titleItem
                   previousItem:(UIBarButtonItem *)previousItem
                       nextItem:(UIBarButtonItem *)nextItem
                      rightItem:(UIBarButtonItem *)rightItem
{
    [self.innerKeyboardTarget addToolbarWithTitleItem:titleItem previousItem:previousItem nextItem:nextItem rightItem:rightItem];
}

@end

#pragma mark - FWTextViewWrapper+FWKeyboard

@interface FWTextViewWrapper (FWKeyboardInternal)

@property (nonatomic, strong, readonly) FWInnerKeyboardTarget *innerKeyboardTarget;

@property (nonatomic, assign) BOOL delegateProxyEnabled;

@end

@interface UITextView (FWKeyboard)

@end

@implementation UITextView (FWKeyboard)

- (BOOL)innerKeyboardManager
{
    return self.fw.innerKeyboardTarget.keyboardManager;
}

- (void)setInnerKeyboardManager:(BOOL)keyboardManager
{
    self.fw.innerKeyboardTarget.keyboardManager = keyboardManager;
}

- (CGFloat)innerKeyboardDistance
{
    return self.fw.innerKeyboardTarget.keyboardDistance;
}

- (void)setInnerKeyboardDistance:(CGFloat)keyboardDistance
{
    self.fw.innerKeyboardTarget.keyboardDistance = keyboardDistance;
}

- (CGFloat)innerReboundHeight
{
    return self.fw.innerKeyboardTarget.reboundHeight;
}

- (void)setInnerReboundHeight:(CGFloat)reboundHeight
{
    self.fw.innerKeyboardTarget.reboundHeight = reboundHeight;
}

- (BOOL)innerKeyboardResign
{
    return self.fw.innerKeyboardTarget.keyboardResign;
}

- (void)setInnerKeyboardResign:(BOOL)keyboardResign
{
    self.fw.innerKeyboardTarget.keyboardResign = keyboardResign;
}

- (UIScrollView *)innerKeyboardScrollView
{
    return self.fw.innerKeyboardTarget.scrollView;
}

- (void)setInnerKeyboardScrollView:(UIScrollView *)keyboardScrollView
{
    self.fw.innerKeyboardTarget.scrollView = keyboardScrollView;
}

- (BOOL)innerTouchResign
{
    return self.fw.innerKeyboardTarget.touchResign;
}

- (void)setInnerTouchResign:(BOOL)touchResign
{
    self.fw.innerKeyboardTarget.touchResign = touchResign;
}

- (BOOL)innerReturnResign
{
    return self.fw.innerKeyboardTarget.returnResign;
}

- (void)setInnerReturnResign:(BOOL)returnResign
{
    self.fw.innerKeyboardTarget.returnResign = returnResign;
    self.fw.delegateProxyEnabled = YES;
}

@end

@implementation FWTextViewWrapper (FWKeyboard)

- (BOOL)keyboardManager
{
    return self.base.innerKeyboardManager;
}

- (void)setKeyboardManager:(BOOL)keyboardManager
{
    self.base.innerKeyboardManager = keyboardManager;
}

- (CGFloat)keyboardDistance
{
    return self.base.innerKeyboardDistance;
}

- (void)setKeyboardDistance:(CGFloat)keyboardDistance
{
    self.base.innerKeyboardDistance = keyboardDistance;
}

- (CGFloat)reboundHeight
{
    return self.base.innerReboundHeight;
}

- (void)setReboundHeight:(CGFloat)reboundHeight
{
    self.base.innerReboundHeight = reboundHeight;
}

- (BOOL)keyboardResign
{
    return self.base.innerKeyboardResign;
}

- (void)setKeyboardResign:(BOOL)keyboardResign
{
    self.base.innerKeyboardResign = keyboardResign;
}

- (BOOL)touchResign
{
    return self.base.innerTouchResign;
}

- (void)setTouchResign:(BOOL)touchResign
{
    self.base.innerTouchResign = touchResign;
}

- (UIScrollView *)keyboardScrollView
{
    return self.base.innerKeyboardScrollView;
}

- (void)setKeyboardScrollView:(UIScrollView *)keyboardScrollView
{
    self.base.innerKeyboardScrollView = keyboardScrollView;
}

- (FWInnerKeyboardTarget *)innerKeyboardTarget
{
    FWInnerKeyboardTarget *target = objc_getAssociatedObject(self.base, _cmd);
    if (!target) {
        target = [[FWInnerKeyboardTarget alloc] initWithTextInput:self.base];
        objc_setAssociatedObject(self.base, _cmd, target, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return target;
}

#pragma mark - Return

- (BOOL)returnResign
{
    return self.base.innerReturnResign;
}

- (void)setReturnResign:(BOOL)returnResign
{
    self.base.innerReturnResign = returnResign;
}

- (UIResponder *)returnResponder
{
    return self.innerKeyboardTarget.returnResponder;
}

- (void)setReturnResponder:(UIResponder *)returnResponder
{
    self.innerKeyboardTarget.returnResponder = returnResponder;
    self.delegateProxyEnabled = YES;
}

- (void (^)(UITextView *textView))returnBlock
{
    return self.innerKeyboardTarget.returnBlock;
}

- (void)setReturnBlock:(void (^)(UITextView *textView))returnBlock
{
    self.innerKeyboardTarget.returnBlock = returnBlock;
    self.delegateProxyEnabled = YES;
}

#pragma mark - Delegate

- (id<UITextViewDelegate>)delegate
{
    if (!self.delegateProxyEnabled) {
        return self.base.delegate;
    } else {
        return self.delegateProxy.delegate;
    }
}

- (void)setDelegate:(id<UITextViewDelegate>)delegate
{
    if (!self.delegateProxyEnabled) {
        self.base.delegate = delegate;
    } else {
        self.delegateProxy.delegate = delegate;
    }
}

- (BOOL)delegateProxyEnabled
{
    return self.base.delegate == self.delegateProxy;
}

- (void)setDelegateProxyEnabled:(BOOL)enabled
{
    if (enabled != self.delegateProxyEnabled) {
        if (enabled) {
            self.delegateProxy.delegate = self.base.delegate;
            self.base.delegate = self.delegateProxy;
        } else {
            self.base.delegate = self.delegateProxy.delegate;
            self.delegateProxy.delegate = nil;
        }
    }
}

- (__kindof FWDelegateProxy *)delegateProxy
{
    FWDelegateProxy *proxy = objc_getAssociatedObject(self.base, _cmd);
    if (!proxy) {
        proxy = [[FWTextViewDelegateProxy alloc] init];
        objc_setAssociatedObject(self.base, _cmd, proxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return proxy;
}

#pragma mark - Toolbar

- (UIToolbar *)keyboardToolbar
{
    return self.innerKeyboardTarget.keyboardToolbar;
}

- (void)setKeyboardToolbar:(UIToolbar *)keyboardToolbar
{
    self.innerKeyboardTarget.keyboardToolbar = keyboardToolbar;
}

- (UIResponder *)previousResponder
{
    return self.innerKeyboardTarget.previousResponder;
}

- (void)setPreviousResponder:(UIResponder *)previousResponder
{
    self.innerKeyboardTarget.previousResponder = previousResponder;
}

- (UIResponder *)nextResponder
{
    return self.innerKeyboardTarget.nextResponder;
}

- (void)setNextResponder:(UIResponder *)nextResponder
{
    self.innerKeyboardTarget.nextResponder = nextResponder;
}

- (void)addToolbarWithTitle:(id)title
             previousButton:(id)previousButton
                 nextButton:(id)nextButton
                rightButton:(id)rightButton
                      block:(void (^)(id))block
{
    [self.innerKeyboardTarget addToolbarWithTitle:title previousButton:previousButton nextButton:nextButton rightButton:rightButton block:block];
}

- (void)addToolbarWithTitleItem:(UIBarButtonItem *)titleItem
                   previousItem:(UIBarButtonItem *)previousItem
                       nextItem:(UIBarButtonItem *)nextItem
                      rightItem:(UIBarButtonItem *)rightItem
{
    [self.innerKeyboardTarget addToolbarWithTitleItem:titleItem previousItem:previousItem nextItem:nextItem rightItem:rightItem];
}

@end

#pragma mark - FWTextViewWrapper+FWPlaceholder

@interface FWInnerPlaceholderTarget : NSObject

@property (nonatomic, weak, readonly) UITextView *textView;
@property (nonatomic, assign) CGFloat lastHeight;

- (instancetype)initWithTextView:(UITextView *)textView;

- (void)setNeedsUpdatePlaceholder;
- (void)setNeedsUpdateText;

@end

@implementation FWTextViewWrapper (FWPlaceholder)

- (UILabel *)placeholderLabel
{
    UILabel *label = objc_getAssociatedObject(self.base, @selector(placeholderLabel));
    if (!label) {
        static UIColor *defaultPlaceholderColor = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            UITextField *textField = [[UITextField alloc] init];
            textField.placeholder = @" ";
            UILabel *placeholderLabel = [textField.fw invokeGetter:@"_placeholderLabel"];
            defaultPlaceholderColor = placeholderLabel.textColor;
        });
        
        NSAttributedString *originalText = self.base.attributedText;
        self.base.text = @" ";
        self.base.attributedText = originalText;
        
        label = [[UILabel alloc] init];
        label.textColor = defaultPlaceholderColor;
        label.numberOfLines = 0;
        label.userInteractionEnabled = NO;
        label.font = self.base.font;
        objc_setAssociatedObject(self.base, @selector(placeholderLabel), label, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [self.innerPlaceholderTarget setNeedsUpdatePlaceholder];
        [self.base insertSubview:label atIndex:0];
        
        [self.base.fw observeNotification:UITextViewTextDidChangeNotification object:self.base target:self.innerPlaceholderTarget action:@selector(setNeedsUpdateText)];

        [self.base.fw observeProperty:@"attributedText" target:self.innerPlaceholderTarget action:@selector(setNeedsUpdateText)];
        [self.base.fw observeProperty:@"text" target:self.innerPlaceholderTarget action:@selector(setNeedsUpdateText)];
        [self.base.fw observeProperty:@"bounds" target:self.innerPlaceholderTarget action:@selector(setNeedsUpdatePlaceholder)];
        [self.base.fw observeProperty:@"frame" target:self.innerPlaceholderTarget action:@selector(setNeedsUpdatePlaceholder)];
        [self.base.fw observeProperty:@"textAlignment" target:self.innerPlaceholderTarget action:@selector(setNeedsUpdatePlaceholder)];
        [self.base.fw observeProperty:@"textContainerInset" target:self.innerPlaceholderTarget action:@selector(setNeedsUpdatePlaceholder)];
        
        [self.base.fw observeProperty:@"font" block:^(UITextView *textView, NSDictionary *change) {
            if (change[NSKeyValueChangeNewKey] != nil) textView.fw.placeholderLabel.font = textView.font;
            [textView.fw.innerPlaceholderTarget setNeedsUpdatePlaceholder];
        }];
    }
    return label;
}

- (FWInnerPlaceholderTarget *)innerPlaceholderTarget
{
    FWInnerPlaceholderTarget *target = objc_getAssociatedObject(self.base, _cmd);
    if (!target) {
        target = [[FWInnerPlaceholderTarget alloc] initWithTextView:self.base];
        objc_setAssociatedObject(self.base, _cmd, target, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return target;
}

- (NSString *)placeholder
{
    return self.placeholderLabel.text;
}

- (void)setPlaceholder:(NSString *)placeholder
{
    self.placeholderLabel.text = placeholder;
    [self.innerPlaceholderTarget setNeedsUpdatePlaceholder];
}

- (NSAttributedString *)attributedPlaceholder
{
    return self.placeholderLabel.attributedText;
}

- (void)setAttributedPlaceholder:(NSAttributedString *)attributedPlaceholder
{
    self.placeholderLabel.attributedText = attributedPlaceholder;
    [self.innerPlaceholderTarget setNeedsUpdatePlaceholder];
}

- (UIColor *)placeholderColor
{
    return self.placeholderLabel.textColor;
}

- (void)setPlaceholderColor:(UIColor *)placeholderColor
{
    self.placeholderLabel.textColor = placeholderColor;
}

- (UIEdgeInsets)placeholderInset
{
    NSValue *value = objc_getAssociatedObject(self.base, @selector(placeholderInset));
    return value ? value.UIEdgeInsetsValue : UIEdgeInsetsZero;
}

- (void)setPlaceholderInset:(UIEdgeInsets)inset
{
    objc_setAssociatedObject(self.base, @selector(placeholderInset), [NSValue valueWithUIEdgeInsets:inset], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self.innerPlaceholderTarget setNeedsUpdatePlaceholder];
}

- (UIControlContentVerticalAlignment)verticalAlignment
{
    NSNumber *value = objc_getAssociatedObject(self.base, @selector(verticalAlignment));
    return value ? value.integerValue : UIControlContentVerticalAlignmentTop;
}

- (void)setVerticalAlignment:(UIControlContentVerticalAlignment)verticalAlignment
{
    objc_setAssociatedObject(self.base, @selector(verticalAlignment), @(verticalAlignment), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self.innerPlaceholderTarget setNeedsUpdatePlaceholder];
}

- (BOOL)autoHeightEnabled
{
    return [objc_getAssociatedObject(self.base, @selector(autoHeightEnabled)) boolValue];
}

- (void)setAutoHeightEnabled:(BOOL)enabled
{
    objc_setAssociatedObject(self.base, @selector(autoHeightEnabled), @(enabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self.innerPlaceholderTarget setNeedsUpdateText];
}

- (CGFloat)maxHeight
{
    NSNumber *value = objc_getAssociatedObject(self.base, @selector(maxHeight));
    return value ? value.doubleValue : CGFLOAT_MAX;
}

- (void)setMaxHeight:(CGFloat)height
{
    objc_setAssociatedObject(self.base, @selector(maxHeight), @(height), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self.innerPlaceholderTarget setNeedsUpdateText];
}

- (CGFloat)minHeight
{
    return [objc_getAssociatedObject(self.base, @selector(minHeight)) doubleValue];
}

- (void)setMinHeight:(CGFloat)height
{
    objc_setAssociatedObject(self.base, @selector(minHeight), @(height), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self.innerPlaceholderTarget setNeedsUpdateText];
}

- (void (^)(CGFloat))heightDidChange
{
    return objc_getAssociatedObject(self.base, @selector(heightDidChange));
}

- (void)setHeightDidChange:(void (^)(CGFloat))block
{
    objc_setAssociatedObject(self.base, @selector(heightDidChange), block, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)autoHeightWithMaxHeight:(CGFloat)maxHeight didChange:(void (^)(CGFloat))didChange
{
    self.maxHeight = maxHeight;
    if (didChange) self.heightDidChange = didChange;
    self.autoHeightEnabled = YES;
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
        switch (self.textView.fw.verticalAlignment) {
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
        self.textView.fw.placeholderLabel.hidden = YES;
    } else {
        CGRect targetFrame;
        UIEdgeInsets inset = [self.textView.fw placeholderInset];
        if (!UIEdgeInsetsEqualToEdgeInsets(inset, UIEdgeInsetsZero)) {
            targetFrame = CGRectMake(inset.left, inset.top, CGRectGetWidth(self.textView.bounds) - inset.left - inset.right, CGRectGetHeight(self.textView.bounds) - inset.top - inset.bottom);
        } else {
            CGFloat x = self.textView.textContainer.lineFragmentPadding + self.textView.textContainerInset.left;
            CGFloat width = CGRectGetWidth(self.textView.bounds) - x - self.textView.textContainer.lineFragmentPadding - self.textView.textContainerInset.right;
            CGFloat height = ceil([self.textView.fw.placeholderLabel sizeThatFits:CGSizeMake(width, 0)].height);
            height = MIN(height, self.textView.bounds.size.height - self.textView.textContainerInset.top - self.textView.textContainerInset.bottom);
            
            CGFloat y = self.textView.textContainerInset.top;
            switch (self.textView.fw.verticalAlignment) {
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
        
        self.textView.fw.placeholderLabel.hidden = NO;
        self.textView.fw.placeholderLabel.textAlignment = self.textView.textAlignment;
        self.textView.fw.placeholderLabel.frame = targetFrame;
    }
}

- (void)updateText
{
    [self updatePlaceholder];
    if (!self.textView.fw.autoHeightEnabled) return;
    
    CGFloat height = ceil([self.textView sizeThatFits:CGSizeMake(self.textView.bounds.size.width, CGFLOAT_MAX)].height);
    height = MAX(self.textView.fw.minHeight, MIN(height, self.textView.fw.maxHeight));
    if (height == self.lastHeight) return;
    
    CGRect targetFrame = self.textView.frame;
    targetFrame.size.height = height;
    self.textView.frame = targetFrame;
    if (self.textView.fw.heightDidChange) self.textView.fw.heightDidChange(height);
    self.lastHeight = height;
}

@end
