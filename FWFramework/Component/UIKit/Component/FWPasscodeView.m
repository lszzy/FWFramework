/*!
 @header     FWPasscodeView.m
 @indexgroup FWFramework
 @brief      FWPasscodeView
 @author     wuyong
 @copyright  Copyright © 2021 wuyong.site. All rights reserved.
 @updated    2021/1/31
 */

#import "FWPasscodeView.h"
#import "FWAutoLayout.h"
#import "UITextField+FWFramework.h"

@implementation FWPasscodeFlowLayout

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        [self initPara];
    }
    
    return self;
}

- (void)initPara
{
    self.equalGap = YES;
    self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    self.minLineSpacing = 10;
    self.minimumLineSpacing = 0;
    self.minimumInteritemSpacing = 0;
    self.sectionInset = UIEdgeInsetsZero;
    self.itemNum = 1;
}

- (void)prepareLayout
{
    if (_equalGap) {
        [self updateLineSpacing];
    }
    
    [super prepareLayout];
}

- (void)updateLineSpacing
{
    if (self.itemNum > 1) {
        CGFloat width = CGRectGetWidth(self.collectionView.frame);
        self.minimumLineSpacing = floor(1.0 * (width - self.itemNum * self.itemSize.width - self.collectionView.contentInset.left - self.collectionView.contentInset.right) / (self.itemNum - 1));
        
        if (self.minimumLineSpacing < self.minLineSpacing) {
            self.minimumLineSpacing = self.minLineSpacing;
        }
    }else{
        self.minimumLineSpacing = 0;
    }
}

@end

@interface FWPasscodeLineView()
{
    
}
@end

@implementation FWPasscodeLineView

- (instancetype)init
{
    self = [super init];
    if (self) {
        _underlineColorNormal = [UIColor colorWithRed:49/255.0 green:51/255.0 blue:64/255.0 alpha:1];
        _underlineColorSelected = [UIColor colorWithRed:49/255.0 green:51/255.0 blue:64/255.0 alpha:1];
        _underlineColorFilled = [UIColor colorWithRed:49/255.0 green:51/255.0 blue:64/255.0 alpha:1];
        [self createUI];
    }
    return self;
}

- (void)createUI
{
    static CGFloat sepLineViewHeight = 4;
    
    _lineView = [UIView new];
    [self addSubview:_lineView];
    _lineView.backgroundColor = _underlineColorNormal;
    _lineView.layer.cornerRadius = sepLineViewHeight / 2.0;
    [_lineView fwPinEdgesToSuperviewWithInsets:UIEdgeInsetsZero excludingEdge:NSLayoutAttributeTop];
    [_lineView fwSetDimension:NSLayoutAttributeHeight toSize:sepLineViewHeight];
    
    _lineView.layer.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.2].CGColor;
    _lineView.layer.shadowOpacity = 1;
    _lineView.layer.shadowOffset = CGSizeMake(0, 2);
    _lineView.layer.shadowRadius = 4;
}

- (void)setSelected:(BOOL)selected {
    _selected = selected;
    
    if (self.selectChangeBlock) {
        __weak __typeof(self)weakSelf = self;
        self.selectChangeBlock(weakSelf, selected);
    }
}

@end

@interface FWPasscodeSecrectImageView()
{
    UIImageView *_lockImgView;
}
@end

@implementation FWPasscodeSecrectImageView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self createUI];
    }
    return self;
}

- (void)createUI
{
    _lockImgView = [UIImageView new];
    [self addSubview:_lockImgView];
    [_lockImgView fwAlignCenterToSuperview];
}

#pragma mark - Setter & Getter
- (void)setImage:(UIImage *)image
{
    _image = image;
    _lockImgView.image = image;
}

- (void)setImageWidth:(CGFloat)imageWidth
{
    _imageWidth = imageWidth;
    [_lockImgView fwSetDimension:NSLayoutAttributeWidth toSize:imageWidth];
}

- (void)setImageHeight:(CGFloat)imageHeight
{
    _imageHeight = imageHeight;
    [_lockImgView fwSetDimension:NSLayoutAttributeHeight toSize:imageHeight];
}

@end

@interface FWPasscodeCellProperty ()

@property (copy, nonatomic, readwrite) NSString *originValue;

@end


@implementation FWPasscodeCellProperty

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        
        __weak typeof(self) weakSelf = self;
        
        // UI
        self.borderWidth = (0.5);
        self.cellBorderColorNormal = [UIColor colorWithRed:228/255.0 green:228/255.0 blue:228/255.0 alpha:1];
        self.cellBorderColorSelected = [UIColor colorWithRed:255/255.0 green:70/255.0 blue:62/255.0 alpha:1];
        self.cellBorderColorFilled = nil;
        self.cellBgColorNormal = [UIColor whiteColor];
        self.cellBgColorSelected = [UIColor whiteColor];
        self.cellBgColorFilled = nil;
        self.cellCursorColor = [UIColor colorWithRed:255/255.0 green:70/255.0 blue:62/255.0 alpha:1];
        self.cellCursorWidth = 2;
        self.cellCursorHeight = 32;
        self.cornerRadius = 4;
        
        // line
        self.showLine = NO;
        
        // label
        self.cellFont = [UIFont systemFontOfSize:20];
        self.cellTextColor = [UIColor blackColor];
        
        // Security
        self.showSecurity = NO;
        self.securitySymbol = @"✱";
        self.originValue = @"";
        self.securityType = FWPasscodeSecurityTypeSymbol;
        
        // Placeholder
        self.cellPlaceholderText = nil;
        self.cellPlaceholderTextColor = [UIColor colorWithRed:114/255.0 green:116/255.0 blue:124/255.0 alpha:0.3];
        self.cellPlaceholderFont = [UIFont systemFontOfSize:20];
        
        // Block
        self.customSecurityViewBlock = ^UIView * _Nonnull{
            return [weakSelf defaultCustomSecurityView];
        };
        self.customLineViewBlock = ^FWPasscodeLineView * _Nonnull{
            return [FWPasscodeLineView new];
        };
        self.configCellShadowBlock = nil;
        
        // Test
        self.index = 0;
    }
    
    return self;
}

#pragma mark - Copy
- (id)copyWithZone:(NSZone *)zone
{
    FWPasscodeCellProperty *copy = [[self class] allocWithZone:zone];
    
    // UI
    copy.borderWidth = _borderWidth;
    copy.cellBorderColorNormal = [_cellBorderColorNormal copy];
    copy.cellBorderColorSelected = [_cellBorderColorSelected copy];
    if (_cellBorderColorFilled) {
        copy.cellBorderColorFilled = [_cellBorderColorFilled copy];
    }
    copy.cellBgColorNormal = [_cellBgColorNormal copy];
    copy.cellBgColorSelected = [_cellBgColorSelected copy];
    if (_cellBgColorFilled) {
        copy.cellBgColorFilled = [_cellBgColorFilled copy];
    }
    copy.cellCursorColor = [_cellCursorColor copy];
    copy.cellCursorWidth = _cellCursorWidth;
    copy.cellCursorHeight = _cellCursorHeight;
    copy.cornerRadius = _cornerRadius;
    
    // line
    copy.showLine = _showLine;
    
    // label
    copy.cellFont = [_cellFont copy];
    copy.cellTextColor = [_cellTextColor copy];
    
    // Security
    copy.showSecurity = _showSecurity;
    copy.securitySymbol = [_securitySymbol copy];
    copy.originValue = [_originValue copy];
    copy.securityType = _securityType;
    
    // Placeholder
    if (_cellPlaceholderText) {
        copy.cellPlaceholderText = [_cellPlaceholderText copy];
    }
    copy.cellPlaceholderTextColor = [_cellPlaceholderTextColor copy];
    copy.cellPlaceholderFont = [_cellPlaceholderFont copy];
    
    // Block
    copy.customSecurityViewBlock = [_customSecurityViewBlock copy];
    copy.customLineViewBlock = [_customLineViewBlock copy];
    if (_configCellShadowBlock) {
        copy.configCellShadowBlock = [_configCellShadowBlock copy];
    }
    
    // Test
    copy.index = _index;
    
    return copy;
}

#pragma mark - Getter
- (UIView *)defaultCustomSecurityView
{
    UIView *customSecurityView = [UIView new];
    customSecurityView.backgroundColor = [UIColor clearColor];
    
    // circleView
    static CGFloat circleViewWidth = 20;
    UIView *circleView = [UIView new];
    circleView.backgroundColor = [UIColor blackColor];
    circleView.layer.cornerRadius = 4;
    [customSecurityView addSubview:circleView];
    [circleView fwSetDimensionsToSize:CGSizeMake(circleViewWidth, circleViewWidth)];
    [circleView fwAlignCenterToSuperview];
    return customSecurityView;
}

#pragma mark - Setter
- (void)customOriginValue:(NSString *)originValue {
    _originValue = originValue;
}

@end

@interface FWPasscodeCell ()
{
    
}

@property (strong, nonatomic) UILabel *valueLabel;
@property (strong, nonatomic) CABasicAnimation *opacityAnimation;
@property (strong, nonatomic) UIView *customSecurityView;

@property (strong, nonatomic) FWPasscodeLineView *lineView;

@end

@implementation FWPasscodeCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        [self createUIBase];
    }
    
    return self;
}

- (void)initPara
{
    self.showCursor = YES;
    self.userInteractionEnabled = NO;
}

- (void)createUIBase
{
    [self initPara];
    
    _valueLabel = [UILabel new];
    _valueLabel.font = [UIFont systemFontOfSize:38];
    [self.contentView addSubview:_valueLabel];
    [_valueLabel fwAlignCenterToSuperview];
    
    _cursorView = [UIView new];
    [self.contentView addSubview:_cursorView];
    [_cursorView fwAlignCenterToSuperview];
    
    [self initCellProperty];
}

- (void)initCellProperty
{
    FWPasscodeCellProperty *cellProperty = [FWPasscodeCellProperty new];
    self.cellProperty = cellProperty;
}

- (void)valueLabelLoadData
{
    _valueLabel.hidden = NO;
    [self hideCustomSecurityView];
    
    // 默认字体配置
    __weak typeof(self) weakSelf = self;
    void (^defaultTextConfig)(void) = ^{
        if (weakSelf.cellProperty.cellFont) {
            weakSelf.valueLabel.font = weakSelf.cellProperty.cellFont;
        }
        
        if (weakSelf.cellProperty.cellTextColor) {
            weakSelf.valueLabel.textColor = weakSelf.cellProperty.cellTextColor;
        }
    };
    
    // 占位字符字体配置
    void (^placeholderTextConfig)(void) = ^{
        if (weakSelf.cellProperty.cellFont) {
            weakSelf.valueLabel.font = weakSelf.cellProperty.cellPlaceholderFont;
        }
        
        if (weakSelf.cellProperty.cellTextColor) {
            weakSelf.valueLabel.textColor = weakSelf.cellProperty.cellPlaceholderTextColor;
        }
    };
    
    BOOL hasOriginValue = self.cellProperty.originValue && self.cellProperty.originValue.length > 0;
    if (hasOriginValue) {
        if (self.cellProperty.showSecurity) {
            if (self.cellProperty.securityType == FWPasscodeSecurityTypeSymbol) {
                _valueLabel.text = self.cellProperty.securitySymbol;
            }else if (self.cellProperty.securityType == FWPasscodeSecurityTypeView) {
                _valueLabel.hidden = YES;
                [self showCustomSecurityView];
            }
            
        }else{
            _valueLabel.text = self.cellProperty.originValue;
        }
        defaultTextConfig();
    }else{
        BOOL hasPlaceholderText = self.cellProperty.cellPlaceholderText && self.cellProperty.cellPlaceholderText.length > 0;
        // 有占位字符
        if (hasPlaceholderText) {
            _valueLabel.text = self.cellProperty.cellPlaceholderText;
            placeholderTextConfig();
        }
        // 空
        else{
            _valueLabel.text = @"";
            defaultTextConfig();
        }
    }
    
    
}

#pragma mark - Custom security view
- (void)showCustomSecurityView
{
    if (!self.customSecurityView.superview) {
        [self.contentView addSubview:self.customSecurityView];
        [self.customSecurityView fwPinEdgesToSuperview];
    }
    
    self.customSecurityView.alpha = 1;
}

- (void)hideCustomSecurityView
{
    // Must add this judge. Otherwise _customSecurityView maybe null, and cause error.
    if (_customSecurityView) {
        self.customSecurityView.alpha = 0;
    }
}

#pragma mark - Setter & Getter
- (CABasicAnimation *)opacityAnimation
{
    if (!_opacityAnimation) {
        _opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        _opacityAnimation.fromValue = @(1.0);
        _opacityAnimation.toValue = @(0.0);
        _opacityAnimation.duration = 0.9;
        _opacityAnimation.repeatCount = HUGE_VALF;
        _opacityAnimation.removedOnCompletion = YES;
        _opacityAnimation.fillMode = kCAFillModeForwards;
        _opacityAnimation.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    }
    
    return _opacityAnimation;
}

- (void)setSelected:(BOOL)selected
{
    if (selected) {
        self.layer.borderColor = self.cellProperty.cellBorderColorSelected.CGColor;
        self.backgroundColor = self.cellProperty.cellBgColorSelected;
    }else{
        BOOL hasFill = _valueLabel.text.length > 0 ? YES : NO;
        UIColor *cellBorderColor = self.cellProperty.cellBorderColorNormal;
        UIColor *cellBackgroundColor = self.cellProperty.cellBgColorNormal;
        if (hasFill) {
            if (self.cellProperty.cellBorderColorFilled) {
                cellBorderColor = self.cellProperty.cellBorderColorFilled;
            }
            if (self.cellProperty.cellBgColorFilled) {
                cellBackgroundColor = self.cellProperty.cellBgColorFilled;
            }
        }
        self.layer.borderColor = cellBorderColor.CGColor;
        self.backgroundColor = cellBackgroundColor;
    }
    
    if (_lineView) {
        // 未选中
        if (!selected) {
            if (self.cellProperty.originValue.length > 0 && _lineView.underlineColorFilled) {
                // 有内容
                _lineView.lineView.backgroundColor = _lineView.underlineColorFilled;
            }else if (_lineView.underlineColorNormal) {
                // 无内容
                _lineView.lineView.backgroundColor = _lineView.underlineColorNormal;
            }else{
                // 默认
                _lineView.lineView.backgroundColor = [UIColor colorWithRed:49/255.0 green:51/255.0 blue:64/255.0 alpha:1];
            }
        }
        // 已选中
        else if (selected && _lineView.underlineColorSelected){
            _lineView.lineView.backgroundColor = _lineView.underlineColorSelected;
        }
        // 默认
        else{
            _lineView.lineView.backgroundColor = [UIColor colorWithRed:49/255.0 green:51/255.0 blue:64/255.0 alpha:1];
        }
        
        _lineView.selected = selected;
    }
    
    if (_showCursor) {
        if (selected) {
            _cursorView.hidden= NO;
            [_cursorView.layer addAnimation:self.opacityAnimation forKey:@"FWPasscodeCursorAnimationKey"];
        }else{
            _cursorView.hidden= YES;
            [_cursorView.layer removeAnimationForKey:@"FWPasscodeCursorAnimationKey"];
        }
    }else{
        _cursorView.hidden= YES;
    }
}

- (void)setCellProperty:(FWPasscodeCellProperty *)cellProperty
{
    _cellProperty = cellProperty;
    
    _cursorView.backgroundColor = cellProperty.cellCursorColor;
    [_cursorView fwSetDimension:NSLayoutAttributeWidth toSize:cellProperty.cellCursorWidth];
    [_cursorView fwSetDimension:NSLayoutAttributeHeight toSize:cellProperty.cellCursorHeight];
    self.layer.cornerRadius = cellProperty.cornerRadius;
    self.layer.borderWidth = cellProperty.borderWidth;
    
    [self valueLabelLoadData];
}

- (UIView *)customSecurityView
{
    if (!_customSecurityView) {
        if (_cellProperty.customSecurityViewBlock) {
            _customSecurityView = _cellProperty.customSecurityViewBlock();
        }
    }
    
    return _customSecurityView;
}

- (void)layoutSubviews
{
    __weak typeof(self) weakSelf = self;
    
    if (_cellProperty.showLine && !_lineView) {
        NSAssert(_cellProperty.customLineViewBlock, @"customLineViewBlock can not be null！");
        _lineView = _cellProperty.customLineViewBlock();
        [self.contentView addSubview:_lineView];
        [_lineView fwPinEdgesToSuperview];
    }
    
    if (_cellProperty.configCellShadowBlock) {
        _cellProperty.configCellShadowBlock(weakSelf.layer);
    }
    
    [super layoutSubviews];
}

@end

typedef NS_ENUM(NSInteger, FWPasscodeTextChangeType) {
    FWPasscodeTextChangeTypeNoChange,
    FWPasscodeTextChangeTypeInsert,
    FWPasscodeTextChangeTypeDelete,
};

@interface FWPasscodeView () <UICollectionViewDataSource, UICollectionViewDelegate, UITextFieldDelegate>
{
    NSInteger _oldLength;
    BOOL _needBeginEdit;
}

@property (nonatomic, assign) NSInteger codeLength;
@property (nonatomic, strong) UITapGestureRecognizer *tapGR;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray <NSString *> *valueArr;
@property (nonatomic, strong) NSMutableArray <FWPasscodeCellProperty *> *cellPropertyArr;

@end

@implementation FWPasscodeView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initDefaultValue];
        [self addNotificationObserver];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self initDefaultValue];
        [self addNotificationObserver];
    }
    
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initDefaultValue];
        [self addNotificationObserver];
    }
    
    return self;
}

- (instancetype _Nullable )initWithCodeLength:(NSInteger)codeLength
{
    self = [super init];
    if (self) {
        [self initDefaultValue];
        [self addNotificationObserver];
        self.codeLength = codeLength;
    }
    
    return self;
}

- (void)dealloc
{
    [self removeNotificationObserver];
}

#pragma mark - Notification Observer
- (void)addNotificationObserver
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)removeNotificationObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)applicationWillResignActive:(NSNotification *)notification
{
    // 触发home按下，光标动画移除
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    // 重新进来后响应，光标动画重新开始
    [self reloadAllCell];
}

#pragma mark - You can inherit
- (void)initDefaultValue
{
    _oldLength = 0;
    self.needSecurity = NO;
    self.securityDelay = 0;
    self.codeLength = 4;
    self.showCursor = YES;
    self.keyboardType = UIKeyboardTypeNumberPad;
    self.inputType = FWPasscodeInputTypeNumber;
    self.customInputRegex = @"";
    self.backgroundColor = [UIColor clearColor];
    _valueArr = [NSMutableArray new];
    _needBeginEdit = NO;
}

#pragma mark - LoadAndPrepareView
- (void)prepareView
{
    [self prepareViewWithBeginEdit:YES];
}

- (void)prepareViewWithBeginEdit:(BOOL)beginEdit
{
    if (_codeLength<=0) {
        NSAssert(NO, @"请输入大于0的验证码位数");
        return;
    }
    
    [self generateCellPropertyArr];
    
    // collectionView
    if (!self.collectionView || ![self.subviews containsObject:self.collectionView]) {
        [self addSubview:self.collectionView];
        [self.collectionView fwPinEdgesToSuperview];
    }
    
    // textField
    if (!self.textField || ![self.subviews containsObject:self.textField]) {
        [self addSubview:self.textField];
        [self.textField fwSetDimensionsToSize:CGSizeZero];
        [self.textField fwPinEdgeToSuperview:NSLayoutAttributeLeft];
        [self.textField fwPinEdgeToSuperview:NSLayoutAttributeTop];
    }
    
    // tap
    if (self.tapGR.view != self) {
        [self addGestureRecognizer:self.tapGR];
    }
    
    if (![self.textField.text isEqualToString:self.cellProperty.originValue]) {
        self.textField.text = self.cellProperty.originValue;
        [self textDidChange:self.textField];
    }
    
    if (beginEdit) {
        [self beginEdit];
    }
}

- (void)generateCellPropertyArr
{
    [self.cellPropertyArr removeAllObjects];
    for (int i = 0; i < self.codeLength; i++) {
        [self.cellPropertyArr addObject:[self.cellProperty copy]];
    }
}

#pragma mark - code Length 调整
- (void)resetCodeLength:(NSInteger)codeLength beginEdit:(BOOL)beginEdit
{
    if (codeLength<=0) {
        NSAssert(NO, @"请输入大于0的验证码位数");
        return;
    }
    
    self.codeLength = codeLength;
    [self generateCellPropertyArr];
    [self clearAllWithBeginEdit:beginEdit];
}

#pragma mark - Reload Input View
- (void)reloadInputString:(NSString *_Nullable)value
{
    if (![self.textField.text isEqualToString:value]) {
        self.textField.text = value;
        [self baseTextDidChange:self.textField manualInvoke:YES];
    }
}

#pragma mark - UITextFieldDelegate
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    _needBeginEdit = YES;
    
    if (self.clearAllWhenEditingBegin && self.textValue.length == self.codeLength) {
        [self clearAll];
    }
    
    if (self.editStatusChangeBlock) {
        self.editStatusChangeBlock(FWPasscodeEditStatusBeginEdit);
    }
    
    [self reloadAllCell];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    _needBeginEdit = NO;
    
    if (self.editStatusChangeBlock) {
        self.editStatusChangeBlock(FWPasscodeEditStatusEndEdit);
    }
    
    [self reloadAllCell];
}

#pragma mark - TextViewEdit
- (void)beginEdit{
    if (![self.textField isFirstResponder]) {
        [self.textField becomeFirstResponder];
    }
}

- (void)endEdit{
    if ([self.textField isFirstResponder]) {
        [self.textField resignFirstResponder];
    }
}

- (void)clearAll
{
    [self clearAllWithBeginEdit:YES];
}

- (void)clearAllWithBeginEdit:(BOOL)beginEdit
{
    _oldLength = 0;
    [_valueArr removeAllObjects];
    self.textField.text = @"";
    [self allSecurityClose];
    [self reloadAllCell];
    [self triggerBlock];
    
    if (beginEdit) {
        [self beginEdit];
    }
}

#pragma mark - UITextFieldDidChange
- (void)textDidChange:(UITextField *)textField {
    [self baseTextDidChange:textField manualInvoke:NO];
}

/**
 * 过滤输入内容
*/
- (NSString *)filterInputContent:(NSString *)inputStr {
    
    NSMutableString *mutableStr = [[NSMutableString alloc] initWithString:inputStr];
    if (self.inputType == FWPasscodeInputTypeNumber) {
        
        /// 纯数字
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[^0-9]" options:0 error:nil];
        [regex replaceMatchesInString:mutableStr options:0 range:NSMakeRange(0, [mutableStr length]) withTemplate:@""];
    } else if (self.inputType == FWPasscodeInputTypeNormal) {
        
        /// 不处理
        nil;
    } else if (self.inputType == FWPasscodeInputTypeRegex) {
        
        /// 自定义正则
        if (self.customInputRegex.length > 0) {
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:self.customInputRegex options:0 error:nil];
            [regex replaceMatchesInString:mutableStr options:0 range:NSMakeRange(0, [mutableStr length]) withTemplate:@""];
        }
    }
    
    return [mutableStr copy];
}

/**
 * textDidChange基操作
 * manualInvoke：是否为手动调用
 */
- (void)baseTextDidChange:(UITextField *)textField manualInvoke:(BOOL)manualInvoke  {
    
    __weak typeof(self) weakSelf = self;
    NSString *verStr = textField.text;
    
    //有空格去掉空格
    verStr = [verStr stringByReplacingOccurrencesOfString:@" " withString:@""];
    verStr = [self filterInputContent:verStr];
    
    if (verStr.length >= _codeLength) {
        verStr = [verStr substringToIndex:_codeLength];
        [self endEdit];
    }
    textField.text = verStr;
    
    // 判断删除/增加
    FWPasscodeTextChangeType textChangeType = FWPasscodeTextChangeTypeNoChange;
    if (verStr.length > _oldLength) {
        textChangeType = FWPasscodeTextChangeTypeInsert;
    }else if (verStr.length < _oldLength){
        textChangeType = FWPasscodeTextChangeTypeDelete;
    }
    
    // _valueArr
    if (textChangeType == FWPasscodeTextChangeTypeDelete) {
        [self setSecurityShow:NO index:_valueArr.count-1];
        [_valueArr removeLastObject];
        
    }else if (textChangeType == FWPasscodeTextChangeTypeInsert){
        if (verStr.length > 0) {
            if (_valueArr.count > 0) {
                [self replaceValueArrToAsteriskWithIndex:_valueArr.count - 1 needEqualToCount:NO];
            }
            [_valueArr removeAllObjects];
            
            [verStr enumerateSubstringsInRange:NSMakeRange(0, verStr.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                __strong __typeof(weakSelf)strongSelf = weakSelf;
                [strongSelf.valueArr addObject:substring];
            }];
            
            if (self.needSecurity) {
                if (manualInvoke) {
                    // 处理所有秘文
                    [self delaySecurityProcessAll];
                }else {
                    // 只处理最后一个秘文
                    [self delaySecurityProcessLastOne];
                }
            }
        }
    }
    [self reloadAllCell];
    
    _oldLength = verStr.length;
    
    if (textChangeType != FWPasscodeTextChangeTypeNoChange) {
        [self triggerBlock];
    }
}

#pragma mark - Control security show
- (void)setSecurityShow:(BOOL)isShow index:(NSInteger)index
{
    if (index < 0) {
        NSAssert(NO, @"index必须大于等于0");
        return;
    }
    
    FWPasscodeCellProperty *cellProperty = self.cellPropertyArr[index];
    cellProperty.showSecurity = isShow;
}

- (void)allSecurityClose
{
    [self.cellPropertyArr enumerateObjectsUsingBlock:^(FWPasscodeCellProperty * _Nonnull cellProperty, NSUInteger idx, BOOL * _Nonnull stop) {
        if (cellProperty.showSecurity == YES) {
            cellProperty.showSecurity = NO;
        }
    }];
}

- (void)allSecurityOpen
{
    [self.cellPropertyArr enumerateObjectsUsingBlock:^(FWPasscodeCellProperty * _Nonnull cellProperty, NSUInteger idx, BOOL * _Nonnull stop) {
        if (cellProperty.showSecurity == NO) {
            cellProperty.showSecurity = YES;
        }
    }];
}


#pragma mark - Trigger block
- (void)triggerBlock
{
    if (self.textDidChangeBlock) {
        BOOL isFinished = _valueArr.count == _codeLength ? YES : NO;
        self.textDidChangeBlock(_textField.text, isFinished);
    }
}

#pragma mark - Asterisk 替换密文
/**
 * 替换密文
 * needEqualToCount：是否只替换最后一个
 */
- (void)replaceValueArrToAsteriskWithIndex:(NSInteger)index needEqualToCount:(BOOL)needEqualToCount
{
    if (!self.needSecurity) {
        return;
    }
    
    if (needEqualToCount && index != _valueArr.count - 1) {
        return;
    }
    
    [self setSecurityShow:YES index:index];
}

#pragma mark 延时替换最后一个密文
- (void)delaySecurityProcessLastOne
{
    __weak __typeof(self)weakSelf = self;
    [self delayAfter:self.securityDelay dealBlock:^{
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        if (strongSelf.valueArr.count > 0) {
            [strongSelf replaceValueArrToAsteriskWithIndex:strongSelf.valueArr.count-1 needEqualToCount:YES];
            dispatch_async(dispatch_get_main_queue(), ^{
                [strongSelf reloadAllCell];
            });
        }
    }];
}

#pragma mark 延时替换所有一个密文
- (void)delaySecurityProcessAll
{
    __weak __typeof(self)weakSelf = self;
    [self.valueArr enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        [strongSelf replaceValueArrToAsteriskWithIndex:idx needEqualToCount:NO];
    }];
    
    [self reloadAllCell];
}

#pragma mark - DelayBlock
- (void)delayAfter:(CGFloat)delayTime dealBlock:(void (^)(void))dealBlock
{
    dispatch_time_t timer = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayTime *NSEC_PER_SEC));
    dispatch_after(timer, dispatch_get_main_queue(), ^{
        if (dealBlock) {
            dealBlock();
        }
    });
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _codeLength;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    id tempCell = [self collectionView:collectionView customCellForItemAtIndexPath:indexPath];
    
    if ([tempCell isKindOfClass:[FWPasscodeCell class]]) {
        
        FWPasscodeCell *cell = (FWPasscodeCell *)tempCell;
        cell.showCursor = self.showCursor;
        
        // CellProperty
        FWPasscodeCellProperty *cellProperty = self.cellPropertyArr[indexPath.row];
        cellProperty.index = indexPath.row;
        
        NSString *currentPlaceholderStr = nil;
        if (_placeholderText.length > indexPath.row) {
            currentPlaceholderStr = [_placeholderText substringWithRange:NSMakeRange(indexPath.row, 1)];
            cellProperty.cellPlaceholderText = currentPlaceholderStr;
        }
        
        // setOriginValue
        NSUInteger focusIndex = _valueArr.count;
        if (_valueArr.count > 0 && indexPath.row <= focusIndex - 1) {
            [cellProperty customOriginValue:_valueArr[indexPath.row]];
        }else{
            [cellProperty customOriginValue:@""];
        }
        
        cell.cellProperty = cellProperty;
        
        if (_needBeginEdit) {
            cell.selected = indexPath.row == focusIndex ? YES : NO;
        }else{
            cell.selected = NO;
        }
    }
    
    return tempCell;
}

- (void)reloadAllCell
{
    [self.collectionView reloadData];

    NSUInteger focusIndex = _valueArr.count;
    /// 最后一个
    if (focusIndex == self.codeLength) {
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:focusIndex - 1 inSection:0] atScrollPosition:UICollectionViewScrollPositionRight animated:YES];
    } else {
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:focusIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    }
}

#pragma mark - Qiuck set
- (void)setSecuritySymbol:(NSString *)securitySymbol
{
    if (securitySymbol.length != 1) {
        securitySymbol = @"✱";
    }
    
    self.cellProperty.securitySymbol = securitySymbol;
}

#pragma mark - You can rewrite
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView customCellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    FWPasscodeCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"FWPasscodeCellID" forIndexPath:indexPath];
    return cell;
}

#pragma mark - Setter & Getter
- (UITapGestureRecognizer *)tapGR
{
    if (!_tapGR) {
        _tapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(beginEdit)];
    }
    
    return _tapGR;
}

- (UICollectionView *)collectionView
{
    if (!_collectionView) {
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:self.flowLayout];
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.layer.masksToBounds = YES;
        _collectionView.clipsToBounds = YES;
        [_collectionView registerClass:[FWPasscodeCell class] forCellWithReuseIdentifier:@"FWPasscodeCellID"];
    }
    
    return _collectionView;
}

- (FWPasscodeFlowLayout *)flowLayout
{
    if (!_flowLayout) {
        _flowLayout = [FWPasscodeFlowLayout new];
        _flowLayout.itemSize = CGSizeMake(42, 47);
    }
    
    return _flowLayout;
}

- (void)setCodeLength:(NSInteger)codeLength
{
    _codeLength = codeLength;
    self.flowLayout.itemNum = codeLength;
}

- (void)setKeyboardType:(UIKeyboardType)keyboardType
{
    _keyboardType = keyboardType;
    self.textField.keyboardType = keyboardType;
}

- (UITextField *)textField
{
    if (!_textField) {
        _textField = [UITextField new];
        _textField.fwMenuDisabled = YES;
        _textField.delegate = self;
        [_textField addTarget:self action:@selector(textDidChange:) forControlEvents:UIControlEventEditingChanged];
    }
    return _textField;
}

- (void)setTextContentType:(UITextContentType)textContentType
{
    _textContentType = textContentType;
    
    _textField.textContentType = textContentType;
}

- (FWPasscodeCellProperty *)cellProperty
{
    if (!_cellProperty) {
        _cellProperty = [FWPasscodeCellProperty new];
    }
    
    return _cellProperty;
}

- (NSMutableArray <FWPasscodeCellProperty *> *)cellPropertyArr
{
    if (!_cellPropertyArr) {
        _cellPropertyArr = [NSMutableArray new];
    }
    
    return _cellPropertyArr;
}

- (NSString *)textValue
{
    return _textField.text;
}

@synthesize inputAccessoryView = _inputAccessoryView;
- (void)setInputAccessoryView:(UIView *)inputAccessoryView
{
    _inputAccessoryView = inputAccessoryView;
    self.textField.inputAccessoryView = _inputAccessoryView;
}

- (UIView *)inputAccessoryView
{
    return _inputAccessoryView;
}

- (void)setNeedSecurity:(BOOL)needSecurity
{
    _needSecurity = needSecurity;
    
    if (needSecurity == YES) {
        [self allSecurityOpen];
    }else{
        [self allSecurityClose];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self reloadAllCell];
    });
}

@end
