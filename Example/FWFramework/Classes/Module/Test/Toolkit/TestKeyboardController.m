//
//  TestKeyboardController.m
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/25.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

#import "TestKeyboardController.h"
#import "AppSwift.h"
@import FWFramework;

@interface TestKeyboardController () <FWScrollViewController, UITextFieldDelegate, UITextViewDelegate>

FWPropertyStrong(UITextField *, mobileField);

FWPropertyStrong(UITextField *, passwordField);

FWPropertyStrong(UITextView *, textView);

FWPropertyStrong(UITextView *, inputView);

FWPropertyStrong(UIButton *, submitButton);

FWPropertyStrong(FWPopupMenu *, popupMenu);

FWPropertyAssign(BOOL, canScroll);
FWPropertyAssign(BOOL, dismissOnDrag);
FWPropertyAssign(BOOL, useScrollView);
FWPropertyCopy(NSString *, appendString);

@end

@implementation TestKeyboardController

- (void)setCanScroll:(BOOL)canScroll
{
    _canScroll = canScroll;
    [self.view endEditing:YES];
    [self renderData];
}

- (void)setDismissOnDrag:(BOOL)dismissOnDrag
{
    _dismissOnDrag = dismissOnDrag;
    [self.view endEditing:YES];
    self.scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
}

- (void)setUseScrollView:(BOOL)useScrollView
{
    _useScrollView = useScrollView;
    [self.view endEditing:YES];
    self.navigationItem.title = useScrollView ? @"UIScrollView+FWKeyboard" : @"UITextField+FWKeyboard";
    NSArray<UIView *> *textInputs = @[self.mobileField, self.passwordField, self.textView, self.inputView];
    for (UIView *textInput in textInputs) {
        ((UITextField *)textInput).fw_keyboardScrollView = useScrollView ? self.scrollView : nil;
    }
}

- (void)setupSubviews
{
    self.scrollView.backgroundColor = [AppTheme tableColor];
    
    UITextField *textFieldAppearance = [UITextField appearanceWhenContainedInInstancesOfClasses:@[[TestKeyboardController class]]];
    UITextView *textViewAppearance = [UITextView appearanceWhenContainedInInstancesOfClasses:@[[TestKeyboardController class]]];
    textFieldAppearance.fw_keyboardManager = YES;
    textFieldAppearance.fw_touchResign = YES;
    textFieldAppearance.fw_keyboardResign = YES;
    textFieldAppearance.fw_reboundDistance = 200;
    textViewAppearance.fw_keyboardManager = YES;
    textViewAppearance.fw_touchResign = YES;
    textViewAppearance.fw_keyboardResign = YES;
    textViewAppearance.fw_reboundDistance = 200;
    
    UITextField *mobileField = [self createTextField];
    mobileField.tag = 1;
    self.mobileField = mobileField;
    mobileField.fw_maxUnicodeLength = 10;
    mobileField.fw_menuDisabled = YES;
    mobileField.placeholder = @"禁止粘贴，最多10个中文";
    mobileField.keyboardType = UIKeyboardTypeDefault;
    mobileField.returnKeyType = UIReturnKeyNext;
    [self.contentView addSubview:mobileField];
    [mobileField fw_pinEdgeToSuperview:NSLayoutAttributeLeft withInset:15];
    [mobileField fw_pinEdgeToSuperview:NSLayoutAttributeRight withInset:15];
    [mobileField fw_alignAxisToSuperview:NSLayoutAttributeCenterX];
    
    UITextField *passwordField = [self createTextField];
    passwordField.tag = 2;
    self.passwordField = passwordField;
    passwordField.delegate = self;
    passwordField.fw_maxLength = 20;
    passwordField.placeholder = @"仅数字和字母转大写，最多20个英文";
    passwordField.keyboardType = UIKeyboardTypeDefault;
    passwordField.returnKeyType = UIReturnKeyNext;
    mobileField.fw_returnNext = YES;
    FWWeakifySelf();
    mobileField.fw_nextResponder = ^(UITextField *textField){
        FWStrongifySelf();
        return self.passwordField;
    };
    [mobileField fw_addToolbarWithTitle:[NSAttributedString fw_attributedString:mobileField.placeholder withFont:[UIFont systemFontOfSize:13.0]] doneBlock:nil];
    [self.contentView addSubview:passwordField];
    [passwordField fw_pinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:mobileField];
    [passwordField fw_alignAxisToSuperview:NSLayoutAttributeCenterX];
    
    UITextView *textView = [self createTextView];
    textView.tag = 3;
    self.textView = textView;
    textView.delegate = self;
    textView.backgroundColor = [AppTheme backgroundColor];
    textView.fw_maxUnicodeLength = 10;
    textView.fw_placeholder = @"问题，最多10个中文";
    textView.returnKeyType = UIReturnKeyNext;
    passwordField.fw_returnNext = YES;
    passwordField.fw_previousResponderTag = 1;
    passwordField.fw_nextResponderTag = 3;
    [passwordField fw_addToolbarWithTitle:[NSAttributedString fw_attributedString:passwordField.placeholder withFont:[UIFont systemFontOfSize:13.0]] doneBlock:nil];
    [self.contentView addSubview:textView];
    [textView fw_pinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:passwordField withOffset:15];
    [textView fw_alignAxisToSuperview:NSLayoutAttributeCenterX];
    
    UITextView *inputView = [self createTextView];
    inputView.tag = 4;
    self.inputView = inputView;
    inputView.backgroundColor = [AppTheme backgroundColor];
    inputView.fw_maxLength = 20;
    inputView.fw_menuDisabled = YES;
    inputView.fw_placeholder = @"建议，最多20个英文";
    inputView.returnKeyType = UIReturnKeyDone;
    inputView.fw_returnResign = YES;
    inputView.fw_keyboardDistance = 80;
    textView.fw_returnNext = YES;
    textView.fw_previousResponderTag = 2;
    textView.fw_nextResponderTag = 4;
    [textView fw_addToolbarWithTitle:[NSAttributedString fw_attributedString:textView.fw_placeholder withFont:[UIFont systemFontOfSize:13.0]] doneBlock:nil];
    inputView.fw_delegate = self;
    inputView.fw_previousResponderTag = 3;
    [inputView fw_addToolbarWithTitle:[NSAttributedString fw_attributedString:inputView.fw_placeholder withFont:[UIFont systemFontOfSize:13.0]] doneBlock:nil];
    [self.contentView addSubview:inputView];
    [inputView fw_pinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:textView withOffset:15];
    [inputView fw_alignAxisToSuperview:NSLayoutAttributeCenterX];
    
    UIButton *submitButton = [AppTheme largeButton];
    self.submitButton = submitButton;
    [submitButton setTitle:@"提交" forState:UIControlStateNormal];
    [submitButton fw_addTouchTarget:self action:@selector(onSubmit)];
    [self.contentView addSubview:submitButton];
    [submitButton fw_pinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:inputView withOffset:15];
    [submitButton fw_pinEdgeToSuperview:NSLayoutAttributeBottom withInset:15];
    [submitButton fw_alignAxisToSuperview:NSLayoutAttributeCenterX];
}

- (void)setupLayout
{
    FWWeakifySelf();
    self.mobileField.fw_autoCompleteBlock = ^(NSString * _Nonnull text) {
        FWStrongifySelf();
        if (text.length < 1) {
            [self.popupMenu dismiss];
        } else {
            [self.popupMenu dismiss];
            self.popupMenu = [FWPopupMenu showRelyOnView:self.mobileField
                                                  titles:@[text]
                                                   icons:nil
                                               menuWidth:self.mobileField.fw_width
                                           otherSettings:^(FWPopupMenu * _Nonnull popupMenu) {
                popupMenu.showMaskView = NO;
            }];
        }
    };
    
    self.inputView.fw_autoCompleteBlock = ^(NSString * _Nonnull text) {
        FWStrongifySelf();
        if (text.length < 1) {
            [self.popupMenu dismiss];
        } else {
            [self.popupMenu dismiss];
            self.popupMenu = [FWPopupMenu showRelyOnView:self.inputView
                                                  titles:@[text]
                                                   icons:nil
                                               menuWidth:self.inputView.fw_width
                                           otherSettings:^(FWPopupMenu * _Nonnull popupMenu) {
                popupMenu.showMaskView = NO;
            }];
        }
    };
    
    [self fw_setRightBarItem:@"切换" block:^(id sender) {
        FWStrongifySelf();
        [self fw_showSheetWithTitle:nil message:nil cancel:@"取消" actions:@[@"切换滚动", @"切换滚动时收起键盘", @"切换滚动视图", @"自动添加-"] actionBlock:^(NSInteger index) {
            FWStrongifySelf();
            if (index == 0) {
                self.canScroll = !self.canScroll;
            } else if (index == 1) {
                self.dismissOnDrag = !self.dismissOnDrag;
            } else if (index == 2) {
                self.useScrollView = !self.useScrollView;
            } else {
                self.appendString = self.appendString ? nil : @"-";
            }
        }];
    }];
    
    [self renderData];
}

- (void)renderData
{
    CGFloat marginTop = FWScreenHeight - (390 + 15 + FWTopBarHeight + UIScreen.fw_safeAreaInsets.bottom);
    CGFloat topInset = self.canScroll ? FWScreenHeight : marginTop;
    [self.mobileField fw_pinEdgeToSuperview:NSLayoutAttributeTop withInset:topInset];
}

- (UITextView *)createTextView
{
    UITextView *textView = [UITextView new];
    textView.font = [UIFont fw_fontOfSize:15];
    textView.textColor = [AppTheme textColor];
    textView.tintColor = AppTheme.textColor;
    textView.fw_cursorRect = CGRectMake(0, 0, 2, 0);
    [textView fw_setBorderColor:[AppTheme borderColor] width:0.5 cornerRadius:5];
    [textView fw_setDimension:NSLayoutAttributeWidth toSize:FWScreenWidth - 15 * 2];
    [textView fw_setDimension:NSLayoutAttributeHeight toSize:100];
    return textView;
}

- (UITextField *)createTextField
{
    UITextField *textField = [UITextField new];
    textField.font = [UIFont fw_fontOfSize:15];
    textField.textColor = [AppTheme textColor];
    textField.tintColor = AppTheme.textColor;
    textField.fw_cursorRect = CGRectMake(0, 0, 2, 0);
    textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [textField fw_setBorderView:UIRectEdgeBottom color:[AppTheme borderColor] width:0.5];
    [textField fw_setDimension:NSLayoutAttributeWidth toSize:FWScreenWidth - 15 * 2];
    [textField fw_setDimension:NSLayoutAttributeHeight toSize:50];
    return textField;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if ([string isEqualToString:@"\n"]) {
        return YES;
    }
    
    NSString *allowedChars = @"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    NSCharacterSet *characterSet = [[NSCharacterSet characterSetWithCharactersInString:allowedChars] invertedSet];
    NSString *filterString = [[string componentsSeparatedByCharactersInSet:characterSet] componentsJoinedByString:@""];
    if (![string isEqualToString:filterString]) {
        return NO;
    }
    
    if (string.length > 0) {
        NSString *replaceString = string.uppercaseString;
        if (self.appendString) replaceString = [replaceString stringByAppendingString:self.appendString];
        NSString *filterText = [textField.text stringByReplacingCharactersInRange:range withString:replaceString];
        textField.text = [textField fw_filterText:filterText];
        
        NSInteger offset = range.location + replaceString.length;
        if (offset > textField.fw_maxLength) offset = textField.fw_maxLength;
        [textField fw_moveCursor:offset];
        return NO;
    }
    
    return YES;
}

#pragma mark - Action

- (void)onSubmit
{
    NSLog(@"点击了提交");
}

@end
