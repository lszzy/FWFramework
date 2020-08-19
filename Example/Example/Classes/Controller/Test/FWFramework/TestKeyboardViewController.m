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

FWPropertyStrong(FWPopupMenu *, popupMenu);

FWPropertyAssign(BOOL, canScroll);

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
    [self.contentView addSubview:mobileField];
    [mobileField fwPinEdgeToSuperview:NSLayoutAttributeTop withInset:kAppMarginLarge];
    [mobileField fwPinEdgeToSuperview:NSLayoutAttributeLeft withInset:kAppPaddingLarge];
    [mobileField fwPinEdgeToSuperview:NSLayoutAttributeRight withInset:kAppPaddingLarge];
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
    [self.contentView addSubview:passwordField];
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
    [self.contentView addSubview:textView];
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
    inputView.fwKeyboardSpacing = 80;
    textView.fwReturnResponder = inputView;
    inputView.fwDelegate = self;
    [inputView fwAddDoneButton:UIBarStyleDefault title:nil];
    [self.contentView addSubview:inputView];
    [inputView fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:textView withOffset:kAppPaddingLarge];
    [inputView fwAlignAxisToSuperview:NSLayoutAttributeCenterX];
    
    UIButton *submitButton = [AppStandard buttonWithStyle:kAppButtonStyleDefault];
    self.submitButton = submitButton;
    [submitButton setTitle:@"提交" forState:UIControlStateNormal];
    [submitButton fwAddTouchTarget:self action:@selector(onSubmit)];
    [self.contentView addSubview:submitButton];
    [submitButton fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:inputView withOffset:kAppPaddingLarge];
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
        CGFloat topInset = self.canScroll ? kAppMarginLarge + 400 : kAppMarginLarge;
        [self.mobileField fwPinEdgeToSuperview:NSLayoutAttributeTop withInset:topInset];
    }];
}

#pragma mark - Action

- (void)onSubmit
{
    NSLog(@"点击了提交");
}

@end
