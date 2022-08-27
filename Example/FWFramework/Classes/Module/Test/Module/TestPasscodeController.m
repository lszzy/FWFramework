//
//  TestPasscodeController.m
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/25.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

#import "TestPasscodeController.h"
#import "AppSwift.h"
@import FWFramework;

typedef NS_ENUM(NSInteger, CRBoxInputModelType) {
    CRBoxInputModelNormalType,
    CRBoxInputModelPlaceholderType,
    CRBoxInputModelCustomBoxType,
    CRBoxInputModelLineType,
    CRBoxInputModelSecretSymbolType,
    CRBoxInputModelSecretImageType,
    CRBoxInputModelSecretViewType,
};

@interface TestPasscodeController () <FWViewController>

@property (nonatomic, strong) NSMutableArray *dataArr;
@property (assign, nonatomic) CRBoxInputModelType boxInputModelType;

@property (nonatomic, strong) UIView *boxContainerView;
@property (nonatomic, strong) FWPasscodeView *boxInputView;
@property (nonatomic, strong) UIButton *securityButton;
@property (nonatomic, strong) UIButton *clearButton;
@property (strong, nonatomic) UILabel *valueLabel;

@end

@implementation TestPasscodeController

- (void)setupSubviews
{
    _valueLabel = [UILabel new];
    _valueLabel.textColor = AppTheme.textColor;
    _valueLabel.font = [UIFont boldSystemFontOfSize:24];
    _valueLabel.text = @"Empty";
    [self.view addSubview:_valueLabel];
    _valueLabel.fw_layoutChain.centerX().topToSafeAreaWithInset(30);
    
    _boxContainerView = [UIView new];
    [self.view addSubview:_boxContainerView];
    _boxContainerView.fw_layoutChain.leftWithInset(35).rightWithInset(35)
        .height(52).topToViewBottomWithOffset(_valueLabel, 30);
    
    _clearButton = [AppTheme largeButton];
    [_clearButton setTitle:@"Clear" forState:UIControlStateNormal];
    [_clearButton addTarget:self action:@selector(clearBtnEvent) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_clearButton];
    _clearButton.fw_layoutChain.centerX().topToViewBottomWithOffset(_boxContainerView, 30);
    
    _securityButton = [AppTheme largeButton];
    [_securityButton setTitle:@"Security" forState:UIControlStateNormal];
    [_securityButton addTarget:self action:@selector(securityBtnEvent) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_securityButton];
    _securityButton.fw_layoutChain.centerX().topToViewBottomWithOffset(_clearButton, 30);
}

- (void)setupNavbar
{
    FWWeakifySelf();
    [self fw_setRightBarItem:@"Toggle" block:^(id  _Nonnull sender) {
        FWStrongifySelf();
        NSArray *titles = [self.dataArr fw_mapWithBlock:^id _Nullable(NSArray *obj) {
            return obj.firstObject;
        }];
        [self fw_showSheetWithTitle:nil message:nil cancel:@"Cancel" actions:titles actionBlock:^(NSInteger index) {
            FWStrongifySelf();
            self.boxInputModelType = index;
        }];
    }];
}

- (void)setupLayout
{
    _dataArr = [NSMutableArray new];
    [_dataArr addObjectsFromArray:@[
        @[@"Normal", @(CRBoxInputModelNormalType)],
        @[@"Placeholder", @(CRBoxInputModelPlaceholderType)],
        @[@"Custom Box", @(CRBoxInputModelCustomBoxType)],
        @[@"Line", @(CRBoxInputModelLineType)],
        @[@"Secret Symbol", @(CRBoxInputModelSecretSymbolType)],
        @[@"Secret Image", @(CRBoxInputModelSecretImageType)],
        @[@"Secret View", @(CRBoxInputModelSecretViewType)],
    ]];
    
    self.boxInputModelType = CRBoxInputModelNormalType;
}

- (void)clearBtnEvent
{
    [_boxInputView clearAll];
}

- (void)securityBtnEvent
{
    _boxInputView.needSecurity = !_boxInputView.needSecurity;
}

#pragma mark - Setter & Getter

- (void)setBoxInputModelType:(CRBoxInputModelType)boxInputModelType
{
    _boxInputModelType = boxInputModelType;
    
    if (_boxInputView) {
        [_boxInputView removeFromSuperview];
        self.valueLabel.text = @"Empty";
    }
    
    switch (boxInputModelType) {
        case CRBoxInputModelNormalType:
            {
                _boxInputView = [self generateBoxInputView_normal];
            }
            break;
            
        case CRBoxInputModelPlaceholderType:
            {
                _boxInputView = [self generateBoxInputView_placeholder];
            }
            break;
            
        case CRBoxInputModelCustomBoxType:
            {
                _boxInputView = [self generateBoxInputView_customBox];
            }
            break;
            
        case CRBoxInputModelLineType:
            {
                _boxInputView = [self generateBoxInputView_line];
            }
            break;
            
        case CRBoxInputModelSecretSymbolType:
            {
                _boxInputView = [self generateBoxInputView_secretSymbol];
            }
            break;
            
        case CRBoxInputModelSecretImageType:
            {
                _boxInputView = [self generateBoxInputView_secretImage];
            }
            break;
            
        case CRBoxInputModelSecretViewType:
            {
                _boxInputView = [self generateBoxInputView_secretView];
            }
            break;
            
        default:
            {
                _boxInputView = [self generateBoxInputView_normal];
            }
            break;
    }
    
    __weak __typeof(self)weakSelf = self;
    if (!_boxInputView.textDidChangeBlock) {
        _boxInputView.textDidChangeBlock = ^(NSString *text, BOOL isFinished) {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            if (text.length > 0) {
                strongSelf.valueLabel.text = text;
            }else{
                strongSelf.valueLabel.text = @"Empty";
            }
        };
    }
    
    [self.boxContainerView addSubview:_boxInputView];
    _boxInputView.fw_layoutChain.edges();
}

#pragma mark - Normal
- (FWPasscodeView *)generateBoxInputView_normal
{
    FWPasscodeView *_boxInputView = [[FWPasscodeView alloc] initWithCodeLength:4];
    _boxInputView.collectionView.contentInset = UIEdgeInsetsMake(0, 20, 0, 20);
    _boxInputView.collectionView.contentOffset = CGPointMake(-40, 0);
    [_boxInputView prepareViewWithBeginEdit:YES];
    _boxInputView.inputType = FWPasscodeInputTypeNumber;
    
    _boxInputView.inputType = FWPasscodeInputTypeRegex;
    _boxInputView.customInputRegex = @"[^0-9]";
    
    if (@available(iOS 12.0, *)) {
        _boxInputView.textContentType = UITextContentTypeOneTimeCode;
    } else {
        _boxInputView.textContentType = @"one-time-code";
    }
    
    return _boxInputView;
}

- (FWPasscodeView *)generateBoxInputView_placeholder
{
    FWPasscodeCellProperty *cellProperty = [FWPasscodeCellProperty new];
    cellProperty.cellPlaceholderTextColor = [UIColor colorWithRed:114/255.0 green:116/255.0 blue:124/255.0 alpha:0.3];
    cellProperty.cellPlaceholderFont = [UIFont systemFontOfSize:20];
    
    FWPasscodeView *_boxInputView = [[FWPasscodeView alloc] initWithCodeLength:4];
    _boxInputView.collectionView.contentInset = UIEdgeInsetsMake(0, 20, 0, 20);
    _boxInputView.collectionView.contentOffset = CGPointMake(-40, 0);
    _boxInputView.showCursor = NO;
    _boxInputView.placeholderText = @"露可娜娜";
    _boxInputView.cellProperty = cellProperty;
    [_boxInputView prepareViewWithBeginEdit:YES];
    
    return _boxInputView;
}

#pragma mark - CustomBox
- (FWPasscodeView *)generateBoxInputView_customBox
{
    FWPasscodeCellProperty *cellProperty = [FWPasscodeCellProperty new];
    cellProperty.cellBgColorNormal = AppTheme.cellColor;
    cellProperty.cellBgColorSelected = [UIColor whiteColor];
    cellProperty.cellCursorColor = AppTheme.textColor;
    cellProperty.cellCursorWidth = 2;
    cellProperty.cellCursorHeight = (27);
    cellProperty.cornerRadius = 4;
    cellProperty.borderWidth = 0;
    cellProperty.cellFont = [UIFont boldSystemFontOfSize:24];
    cellProperty.cellTextColor = AppTheme.textColor;
    cellProperty.configCellShadowBlock = ^(CALayer * _Nonnull layer) {
        layer.shadowColor = [AppTheme.textColor colorWithAlphaComponent:0.2].CGColor;
        layer.shadowOpacity = 1;
        layer.shadowOffset = CGSizeMake(0, 2);
        layer.shadowRadius = 4;
    };

    FWPasscodeView *_boxInputView = [[FWPasscodeView alloc] initWithCodeLength:4];
    _boxInputView.collectionView.contentInset = UIEdgeInsetsMake(0, 10, 0, 10);
    _boxInputView.collectionView.contentOffset = CGPointMake(-20, 0);
    _boxInputView.flowLayout.itemSize = CGSizeMake((52), (52));
    _boxInputView.cellProperty = cellProperty;
    [_boxInputView prepareViewWithBeginEdit:YES];

    return _boxInputView;
}

#pragma mark - Line
- (FWPasscodeView *)generateBoxInputView_line
{
    FWPasscodeCellProperty *cellProperty = [FWPasscodeCellProperty new];
    cellProperty.cellCursorColor = AppTheme.textColor;
    cellProperty.cellCursorWidth = 2;
    cellProperty.cellCursorHeight = (27);
    cellProperty.cornerRadius = 0;
    cellProperty.borderWidth = 0;
    cellProperty.cellFont = [UIFont boldSystemFontOfSize:24];
    cellProperty.cellTextColor = AppTheme.textColor;
    cellProperty.showLine = YES;
    cellProperty.customLineViewBlock = ^FWPasscodeLineView * _Nonnull{
        FWPasscodeLineView *lineView = [FWPasscodeLineView new];
        lineView.underlineColorNormal = [AppTheme.textColor colorWithAlphaComponent:0.3];
        lineView.underlineColorSelected = [AppTheme.textColor colorWithAlphaComponent:0.7];
        lineView.underlineColorFilled = AppTheme.textColor;
        lineView.lineView.fw_layoutChain.remake().height(4).edgesWithInsetsExcludingEdge(UIEdgeInsetsZero, NSLayoutAttributeTop);
        
        lineView.selectChangeBlock = ^(FWPasscodeLineView * _Nonnull lineView, BOOL selected) {
            if (selected) {
                lineView.lineView.fw_layoutChain.height(6);
            } else {
                lineView.lineView.fw_layoutChain.height(4);
            }
        };

        return lineView;
    };

    FWPasscodeView *_boxInputView = [[FWPasscodeView alloc] initWithCodeLength:4];
    _boxInputView.collectionView.contentInset = UIEdgeInsetsMake(0, 10, 0, 10);
    _boxInputView.collectionView.contentOffset = CGPointMake(-20, 0);
    _boxInputView.flowLayout.itemSize = CGSizeMake((52), (52));
    _boxInputView.cellProperty = cellProperty;
    [_boxInputView prepareViewWithBeginEdit:YES];

    return _boxInputView;
}

#pragma mark - SecretSymbol
- (FWPasscodeView *)generateBoxInputView_secretSymbol
{
    FWPasscodeCellProperty *cellProperty = [FWPasscodeCellProperty new];
    cellProperty.cellCursorColor = AppTheme.textColor;
    cellProperty.cellCursorWidth = 2;
    cellProperty.cellCursorHeight = (27);
    cellProperty.cornerRadius = 0;
    cellProperty.borderWidth = 0;
    cellProperty.cellFont = [UIFont boldSystemFontOfSize:24];
    cellProperty.cellTextColor = AppTheme.textColor;
    cellProperty.showLine = YES;
    cellProperty.securitySymbol = @"*";//need

    FWPasscodeView *_boxInputView = [[FWPasscodeView alloc] initWithCodeLength:4];
    _boxInputView.collectionView.contentInset = UIEdgeInsetsMake(0, 10, 0, 10);
    _boxInputView.collectionView.contentOffset = CGPointMake(-20, 0);
    _boxInputView.needSecurity = YES;//need
    _boxInputView.flowLayout.itemSize = CGSizeMake((52), (52));
    _boxInputView.cellProperty = cellProperty;
    [_boxInputView prepareViewWithBeginEdit:NO];
    
    __weak __typeof(self)weakSelf = self;
    _boxInputView.textDidChangeBlock = ^(NSString *text, BOOL isFinished) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        if (text.length > 0) {
            strongSelf.valueLabel.text = text;
        }else{
            strongSelf.valueLabel.text = @"Empty";
        }
    };
    
    _boxInputView.clearAllWhenEditingBegin = YES;
    [_boxInputView reloadInputString:@"5678"];
    
    return _boxInputView;
}

#pragma mark - SecretImage
- (FWPasscodeView *)generateBoxInputView_secretImage
{
    FWPasscodeCellProperty *cellProperty = [FWPasscodeCellProperty new];
    cellProperty.cellCursorColor = AppTheme.textColor;
    cellProperty.cellCursorWidth = 2;
    cellProperty.cellCursorHeight = (27);
    cellProperty.cornerRadius = 0;
    cellProperty.borderWidth = 0;
    cellProperty.cellFont = [UIFont boldSystemFontOfSize:24];
    cellProperty.cellTextColor = AppTheme.textColor;
    cellProperty.showLine = YES;
    cellProperty.securityType = FWPasscodeSecurityTypeView;//need
    cellProperty.customSecurityViewBlock = ^UIView * _Nonnull{
        FWPasscodeSecrectImageView *secrectImageView = [FWPasscodeSecrectImageView new];
        secrectImageView.image = FWIconImage(@"zmdi-var-settings", 24);
        secrectImageView.imageWidth = 23;
        secrectImageView.imageHeight = 23;
        return secrectImageView;
    };

    FWPasscodeView *_boxInputView = [[FWPasscodeView alloc] initWithCodeLength:4];
    _boxInputView.collectionView.contentInset = UIEdgeInsetsMake(0, 10, 0, 10);
    _boxInputView.collectionView.contentOffset = CGPointMake(-20, 0);
    _boxInputView.needSecurity = YES;//need
    _boxInputView.flowLayout.itemSize = CGSizeMake((52), (52));
    _boxInputView.cellProperty = cellProperty;
    [_boxInputView prepareViewWithBeginEdit:YES];

    return _boxInputView;
}

#pragma mark - SecretView
- (FWPasscodeView *)generateBoxInputView_secretView
{
    FWPasscodeCellProperty *cellProperty = [FWPasscodeCellProperty new];
    cellProperty.cellCursorColor = AppTheme.textColor;
    cellProperty.cellCursorWidth = 2;
    cellProperty.cellCursorHeight = (27);
    cellProperty.cornerRadius = 0;
    cellProperty.borderWidth = 0;
    cellProperty.cellFont = [UIFont boldSystemFontOfSize:24];
    cellProperty.cellTextColor = AppTheme.textColor;
    cellProperty.showLine = YES;
    cellProperty.securityType = FWPasscodeSecurityTypeView;//need
    cellProperty.customSecurityViewBlock = ^UIView * _Nonnull{
        UIView *customSecurityView = [UIView new];
        customSecurityView.backgroundColor = [UIColor clearColor];

        // circleView
        static CGFloat circleViewWidth = 20;
        UIView *circleView = [UIView new];
        circleView.backgroundColor = AppTheme.textColor;
        circleView.layer.cornerRadius = 4;
        [customSecurityView addSubview:circleView];
        circleView.fw_layoutChain.center().width(circleViewWidth).height(circleViewWidth);

        return customSecurityView;
    };

    FWPasscodeView *_boxInputView = [[FWPasscodeView alloc] initWithCodeLength:4];
    _boxInputView.collectionView.contentInset = UIEdgeInsetsMake(0, 10, 0, 10);
    _boxInputView.collectionView.contentOffset = CGPointMake(-20, 0);
    _boxInputView.needSecurity = YES;
    _boxInputView.flowLayout.itemSize = CGSizeMake((52), (52));
    _boxInputView.cellProperty = cellProperty;
    [_boxInputView prepareViewWithBeginEdit:YES];

    return _boxInputView;
}

@end
