//
//  TestKeyboardViewController.m
//  Example
//
//  Created by wuyong on 2017/4/6.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import "TestKeyboardViewController.h"

@interface TestKeyboardViewController () <UITextFieldDelegate, UITextViewDelegate>

FWPropertyStrong(UITextField *, mobileField);

FWPropertyStrong(UITextField *, passwordField);

FWPropertyStrong(UITextView *, textView);

FWPropertyStrong(UITextView *, inputView);

FWPropertyStrong(UIButton *, submitButton);

@end

@implementation TestKeyboardViewController

- (void)renderView
{
    UITextField *textFieldAppearance = [UITextField appearanceWhenContainedInInstancesOfClasses:@[[TestKeyboardViewController class]]];
    UITextView *textViewAppearance = [UITextView appearanceWhenContainedInInstancesOfClasses:@[[TestKeyboardViewController class]]];
    textFieldAppearance.fwKeyboardManager = YES;
    textFieldAppearance.fwTouchResign = YES;
    textViewAppearance.fwKeyboardManager = YES;
    textViewAppearance.fwTouchResign = YES;
    
    UITextField *mobileField = [AppStandard textFieldWithStyle:kAppTextFieldStyleDefault];
    self.mobileField = mobileField;
    mobileField.delegate = self;
    mobileField.fwMaxUnicodeLength = 10;
    mobileField.placeholder = @"昵称，最多10个中文";
    mobileField.keyboardType = UIKeyboardTypeDefault;
    mobileField.returnKeyType = UIReturnKeyNext;
    [self.view addSubview:mobileField];
    [mobileField fwPinEdgeToSuperview:NSLayoutAttributeTop withInset:kAppMarginLarge];
    [mobileField fwAlignAxisToSuperview:NSLayoutAttributeCenterX];
    
    UITextField *passwordField = [AppStandard textFieldWithStyle:kAppTextFieldStyleDefault];
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
    [self.view addSubview:passwordField];
    [passwordField fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:mobileField];
    [passwordField fwAlignAxisToSuperview:NSLayoutAttributeCenterX];
    
    UITextView *textView = [AppStandard textViewWithStyle:kAppTextViewStyleDefault];
    self.textView = textView;
    textView.delegate = self;
    textView.backgroundColor = [UIColor appColorBg];
    textView.fwMaxUnicodeLength = 10;
    textView.fwPlaceholder = @"问题，最多10个中文";
    textView.returnKeyType = UIReturnKeyNext;
    passwordField.fwReturnResponder = textView;
    [self.view addSubview:textView];
    [textView fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:passwordField withOffset:kAppPaddingLarge];
    [textView fwAlignAxisToSuperview:NSLayoutAttributeCenterX];
    
    UITextView *inputView = [AppStandard textViewWithStyle:kAppTextViewStyleDefault];
    self.inputView = inputView;
    inputView.backgroundColor = [UIColor appColorBg];
    inputView.fwMaxLength = 20;
    inputView.fwMenuDisabled = YES;
    inputView.fwPlaceholder = @"建议，最多20个英文";
    inputView.returnKeyType = UIReturnKeyDone;
    inputView.fwReturnResign = YES;
    textView.fwReturnResponder = inputView;
    inputView.fwDelegate = self;
    [inputView fwAddDoneButton:UIBarStyleDefault title:@"完成"];
    [self.view addSubview:inputView];
    [inputView fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:textView withOffset:kAppPaddingLarge];
    [inputView fwAlignAxisToSuperview:NSLayoutAttributeCenterX];
    
    UIButton *submitButton = [AppStandard buttonWithStyle:kAppButtonStyleDefault];
    self.submitButton = submitButton;
    [submitButton setTitle:@"提交" forState:UIControlStateNormal];
    [submitButton fwAddTouchTarget:self action:@selector(onSubmit)];
    [self.view addSubview:submitButton];
    [submitButton fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:inputView withOffset:kAppPaddingLarge];
    [submitButton fwAlignAxisToSuperview:NSLayoutAttributeCenterX];
}

#pragma mark - Action

- (void)onSubmit
{
    NSLog(@"点击了提交");
}

@end
