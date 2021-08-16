//
//  TestKeyboardViewController.m
//  Example
//
//  Created by wuyong on 2017/4/6.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import "TestKeyboardViewController.h"

static BOOL keyboardScrollView = NO;

@interface TestKeyboardViewController () <FWScrollViewController, UITextFieldDelegate, UITextViewDelegate>

FWPropertyStrong(UITextField *, mobileField);

FWPropertyStrong(UITextField *, passwordField);

FWPropertyStrong(UITextView *, textView);

FWPropertyStrong(UITextView *, inputView);

FWPropertyStrong(UIButton *, submitButton);

FWPropertyStrong(FWPopupMenu *, popupMenu);

FWPropertyAssign(BOOL, canScroll);

@end

@implementation TestKeyboardViewController

- (void)renderView
{
    self.scrollView.backgroundColor = [Theme tableColor];
    self.scrollView.fwKeyboardDismissOnDrag = YES;
    
    UITextField *textFieldAppearance = [UITextField appearanceWhenContainedInInstancesOfClasses:@[[TestKeyboardViewController class]]];
    UITextView *textViewAppearance = [UITextView appearanceWhenContainedInInstancesOfClasses:@[[TestKeyboardViewController class]]];
    textFieldAppearance.fwKeyboardManager = YES;
    textFieldAppearance.fwTouchResign = YES;
    textFieldAppearance.fwKeyboardResign = YES;
    textViewAppearance.fwKeyboardManager = YES;
    textViewAppearance.fwTouchResign = YES;
    textViewAppearance.fwKeyboardResign = YES;
    textFieldAppearance.fwKeyboardScrollView = keyboardScrollView ? self.scrollView : nil;
    textViewAppearance.fwKeyboardScrollView = keyboardScrollView ? self.scrollView : nil;
    if (keyboardScrollView) {
        self.fwNavigationItem.title = @"UIScrollView+FWKeyboard";
    }
    keyboardScrollView = !keyboardScrollView;
    
    UITextField *mobileField = [self createTextField];
    self.mobileField = mobileField;
    mobileField.delegate = self;
    mobileField.fwMaxUnicodeLength = 10;
    mobileField.placeholder = @"昵称，最多10个中文";
    mobileField.keyboardType = UIKeyboardTypeDefault;
    mobileField.returnKeyType = UIReturnKeyNext;
    [self.contentView addSubview:mobileField];
    [mobileField fwPinEdgeToSuperview:NSLayoutAttributeLeft withInset:15];
    [mobileField fwPinEdgeToSuperview:NSLayoutAttributeRight withInset:15];
    [mobileField fwAlignAxisToSuperview:NSLayoutAttributeCenterX];
    
    UITextField *passwordField = [self createTextField];
    self.passwordField = passwordField;
    passwordField.delegate = self;
    passwordField.fwMaxLength = 20;
    passwordField.fwMenuDisabled = YES;
    passwordField.placeholder = @"密码，最多20个英文";
    passwordField.keyboardType = UIKeyboardTypeDefault;
    passwordField.returnKeyType = UIReturnKeyNext;
    mobileField.fwReturnResponder = passwordField;
    passwordField.secureTextEntry = YES;
    passwordField.delegate = self;
    FWWeakifySelf();
    [passwordField fwAddToolbar:UIBarStyleDefault title:@"Next" block:^(id sender) {
        FWStrongifySelf();
        [self.textView becomeFirstResponder];
    }];
    [self.contentView addSubview:passwordField];
    [passwordField fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:mobileField];
    [passwordField fwAlignAxisToSuperview:NSLayoutAttributeCenterX];
    
    UITextView *textView = [self createTextView];
    self.textView = textView;
    textView.delegate = self;
    textView.backgroundColor = [Theme backgroundColor];
    textView.fwMaxUnicodeLength = 10;
    textView.fwPlaceholder = @"问题，最多10个中文";
    textView.returnKeyType = UIReturnKeyNext;
    passwordField.fwReturnResponder = textView;
    [self.contentView addSubview:textView];
    [textView fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:passwordField withOffset:15];
    [textView fwAlignAxisToSuperview:NSLayoutAttributeCenterX];
    
    UITextView *inputView = [self createTextView];
    self.inputView = inputView;
    inputView.backgroundColor = [Theme backgroundColor];
    inputView.fwMaxLength = 20;
    inputView.fwMenuDisabled = YES;
    inputView.fwPlaceholder = @"建议，最多20个英文";
    inputView.returnKeyType = UIReturnKeyDone;
    inputView.fwReturnResign = YES;
    inputView.fwKeyboardSpacing = 80;
    textView.fwReturnResponder = inputView;
    inputView.fwDelegate = self;
    [inputView fwAddToolbar:UIBarStyleDefault title:nil block:nil];
    [self.contentView addSubview:inputView];
    [inputView fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:textView withOffset:15];
    [inputView fwAlignAxisToSuperview:NSLayoutAttributeCenterX];
    
    UIButton *submitButton = [Theme largeButton];
    self.submitButton = submitButton;
    [submitButton setTitle:@"提交" forState:UIControlStateNormal];
    [submitButton fwAddTouchTarget:self action:@selector(onSubmit)];
    [self.contentView addSubview:submitButton];
    [submitButton fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:inputView withOffset:15];
    [submitButton fwPinEdgeToSuperview:NSLayoutAttributeBottom withInset:15];
    [submitButton fwAlignAxisToSuperview:NSLayoutAttributeCenterX];
}

- (void)renderModel
{
    FWWeakifySelf();
    self.mobileField.fwAutoCompleteBlock = ^(NSString * _Nonnull text) {
        FWStrongifySelf();
        if (text.length < 1) {
            [self.popupMenu dismiss];
        } else {
            [self.popupMenu dismiss];
            self.popupMenu = [FWPopupMenu showRelyOnView:self.mobileField
                                                  titles:@[text]
                                                   icons:nil
                                               menuWidth:self.mobileField.fwWidth
                                           otherSettings:^(FWPopupMenu * _Nonnull popupMenu) {
                popupMenu.showMaskView = NO;
            }];
        }
    };
    
    self.inputView.fwAutoCompleteBlock = ^(NSString * _Nonnull text) {
        FWStrongifySelf();
        if (text.length < 1) {
            [self.popupMenu dismiss];
        } else {
            [self.popupMenu dismiss];
            self.popupMenu = [FWPopupMenu showRelyOnView:self.inputView
                                                  titles:@[text]
                                                   icons:nil
                                               menuWidth:self.inputView.fwWidth
                                           otherSettings:^(FWPopupMenu * _Nonnull popupMenu) {
                popupMenu.showMaskView = NO;
            }];
        }
    };
    
    [self fwSetRightBarItem:@"切换滚动" block:^(id sender) {
        FWStrongifySelf();
        [self.view endEditing:YES];
        self.canScroll = !self.canScroll;
        [self renderData];
    }];
}

- (void)renderData
{
    CGFloat marginTop = FWScreenHeight - (390 + 15 + FWTopBarHeight + UIScreen.fwSafeAreaInsets.bottom);
    CGFloat topInset = self.canScroll ? FWScreenHeight : marginTop;
    [self.mobileField fwPinEdgeToSuperview:NSLayoutAttributeTop withInset:topInset];
}

- (UITextView *)createTextView
{
    UITextView *textView = [UITextView fwAutoLayoutView];
    textView.font = [UIFont fwFontOfSize:15];
    textView.textColor = [Theme textColor];
    textView.fwCursorColor = Theme.textColor;
    textView.fwCursorRect = CGRectMake(0, 0, 2, 0);
    [textView fwSetBorderColor:[Theme borderColor] width:0.5 cornerRadius:5];
    [textView fwSetDimension:NSLayoutAttributeWidth toSize:FWScreenWidth - 15 * 2];
    [textView fwSetDimension:NSLayoutAttributeHeight toSize:100];
    return textView;
}

- (UITextField *)createTextField
{
    UITextField *textField = [UITextField fwAutoLayoutView];
    textField.font = [UIFont fwFontOfSize:15];
    textField.textColor = [Theme textColor];
    textField.fwCursorColor = Theme.textColor;
    textField.fwCursorRect = CGRectMake(0, 0, 2, 0);
    textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [textField fwSetBorderView:UIRectEdgeBottom color:[Theme borderColor] width:0.5];
    [textField fwSetDimension:NSLayoutAttributeWidth toSize:FWScreenWidth - 15 * 2];
    [textField fwSetDimension:NSLayoutAttributeHeight toSize:50];
    return textField;
}

#pragma mark - Action

- (void)onSubmit
{
    NSLog(@"点击了提交");
}

@end
