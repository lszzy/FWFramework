/*!
 @header     FWPasscodeView.h
 @indexgroup FWFramework
 @brief      FWPasscodeView
 @author     wuyong
 @copyright  Copyright © 2021 wuyong.site. All rights reserved.
 @updated    2021/1/31
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FWPasscodeFlowLayout : UICollectionViewFlowLayout

@property (assign, nonatomic) BOOL equalGap;

@property (assign, nonatomic) NSInteger itemNum;

@property (assign, nonatomic) NSInteger minLineSpacing;

- (void)updateLineSpacing;

@end

@interface FWPasscodeLineView : UIView

@property (strong, nonatomic) UIView    *lineView;
@property (assign, nonatomic) BOOL      selected;

/**
 下划线颜色，未选中状态，且没有填充文字时。默认：[UIColor colorWithRed:49/255.0 green:51/255.0 blue:64/255.0 alpha:1]
 */
@property (copy, nonatomic) UIColor *underlineColorNormal;

/**
 下划线颜色，选中状态时。默认：[UIColor colorWithRed:49/255.0 green:51/255.0 blue:64/255.0 alpha:1]
 */
@property (copy, nonatomic) UIColor *underlineColorSelected;

/**
 下划线颜色，未选中状态，且有填充文字时。默认：[UIColor colorWithRed:49/255.0 green:51/255.0 blue:64/255.0 alpha:1]
 */
@property (copy, nonatomic) UIColor *underlineColorFilled;

/**
 选择状态改变时回调
 */
@property (nullable, copy, nonatomic) void(^selectChangeBlock)(FWPasscodeLineView *lineView, BOOL selected);

- (instancetype)initWithFrame:(CGRect)frame UNAVAILABLE_ATTRIBUTE;

@end

@interface FWPasscodeSecrectImageView : UIView

@property (strong, nonatomic) UIImage   *image;
@property (assign, nonatomic) CGFloat   imageWidth;
@property (assign, nonatomic) CGFloat   imageHeight;

@end

typedef NS_ENUM(NSInteger, FWPasscodeSecurityType) {
    FWPasscodeSecurityTypeSymbol,
    FWPasscodeSecurityTypeView,
};

@interface FWPasscodeCellProperty : NSObject <NSCopying>

#pragma mark - UI
/**
 cell边框宽度，默认：0.5
 */
@property (assign, nonatomic) CGFloat borderWidth;

/**
 cell边框颜色，未选中状态时。默认：[UIColor colorWithRed:228/255.0 green:228/255.0 blue:228/255.0 alpha:1]
 */
@property (copy, nonatomic) UIColor *cellBorderColorNormal;

/**
 cell边框颜色，选中状态时。默认：[UIColor colorWithRed:255/255.0 green:70/255.0 blue:62/255.0 alpha:1]
 */
@property (copy, nonatomic) UIColor *cellBorderColorSelected;

/**
 cell边框颜色，无填充文字，未选中状态时。默认：与cellBorderColorFilled相同
 */
@property (copy, nonatomic) UIColor *__nullable cellBorderColorFilled;

/**
 cell背景颜色，无填充文字，未选中状态时。默认：[UIColor whiteColor]
 */
@property (copy, nonatomic) UIColor *cellBgColorNormal;

/**
 cell背景颜色，选中状态时。默认：[UIColor whiteColor]
 */
@property (copy, nonatomic) UIColor *cellBgColorSelected;

/**
 cell背景颜色，填充文字后，未选中状态时。默认：与cellBgColorFilled相同
 */
@property (copy, nonatomic) UIColor *__nullable cellBgColorFilled;

/**
 光标颜色。默认： [UIColor colorWithRed:255/255.0 green:70/255.0 blue:62/255.0 alpha:1]
 */
@property (copy, nonatomic) UIColor *cellCursorColor;

/**
 光标宽度。默认： 2
 */
@property (assign, nonatomic) CGFloat cellCursorWidth;

/**
 光标高度。默认： 32
 */
@property (assign, nonatomic) CGFloat cellCursorHeight;

/**
 圆角。默认： 4
 */
@property (assign, nonatomic) CGFloat cornerRadius;



#pragma mark - line
/**
 显示下划线。默认： NO
 */
@property (assign, nonatomic) BOOL showLine;



#pragma mark - label
/**
 字体/字号。默认：[UIFont systemFontOfSize:20];
 */
@property (copy, nonatomic) UIFont *cellFont;

/**
 字体颜色。默认：[UIColor blackColor];
 */
@property (copy, nonatomic) UIColor *cellTextColor;



#pragma mark - Security
/**
 是否密文显示。默认：NO
 */
@property (assign, nonatomic) BOOL showSecurity;

/**
 密文符号。默认：✱
 说明：只有showSecurity=YES时，有效
 */
@property (copy, nonatomic) NSString *securitySymbol;

/**
 保存当前显示的字符，若想一次性修改所有输入值，请使用reloadInputString方法
 禁止修改该值！！！（除非你知道该怎么使用它。）
 */
@property (copy, nonatomic, readonly) NSString *originValue;
- (void)customOriginValue:(NSString *)originValue;

/**
 密文类型，默认：FWPasscodeSecurityTypeSymbol
 类型说明：
 FWPasscodeSecurityTypeSymbol 符号类型，根据securitySymbol，originValue的内容来显示
 FWPasscodeSecurityTypeView 自定义View类型，可以自定义密文状态下的图片，View
 */
@property (assign, nonatomic) FWPasscodeSecurityType securityType;



#pragma mark - Placeholder
/**
 占位符默认填充值
 禁止修改该值！！！（除非你知道该怎么使用它。）
 */
@property (strong, nonatomic) NSString  *__nullable cellPlaceholderText;

/**
 占位符字体颜色，默认：[UIColor colorWithRed:114/255.0 green:126/255.0 blue:124/255.0 alpha:0.3];
 */
@property (copy, nonatomic) UIColor *cellPlaceholderTextColor;

/**
 占位符字体/字号，默认：[UIFont systemFontOfSize:20];
 */
@property (copy, nonatomic) UIFont *cellPlaceholderFont;



#pragma mark - Block
/**
 自定义密文View回调
 */
@property (copy, nonatomic) UIView *_Nonnull(^customSecurityViewBlock)(void);
/**
 自定义下划线回调
 */
@property (copy, nonatomic) FWPasscodeLineView *_Nonnull(^customLineViewBlock)(void);
/**
 自定义阴影回调
 */
@property (copy, nonatomic, nullable) void(^configCellShadowBlock)(CALayer *layer);

@property (assign, nonatomic) NSInteger index;

@end

@interface FWPasscodeCell : UICollectionViewCell

/**
 cursor, You should not use these properties, unless you know what you are doing.
 */
@property (strong, nonatomic) UIView *cursorView;
@property (assign, nonatomic) BOOL showCursor;

/**
 cellProperty, You should not use these properties, unless you know what you are doing.
 */
@property (strong, nonatomic) FWPasscodeCellProperty *cellProperty;

@end

typedef NS_ENUM(NSInteger, FWPasscodeEditStatus) {
    FWPasscodeEditStatusIdle,
    FWPasscodeEditStatusBeginEdit,
    FWPasscodeEditStatusEndEdit,
};

typedef NS_ENUM(NSInteger, FWPasscodeInputType) {
    /// 数字
    FWPasscodeInputTypeNumber,
    /// 普通（不作任何处理）
    FWPasscodeInputTypeNormal,
    /// 自定义正则（此时需要设置customInputRegex）
    FWPasscodeInputTypeRegex,
};

/*!
 @brief FWPasscodeView
 
 @see https://github.com/CRAnimation/CRBoxInputView
 */
@interface FWPasscodeView : UIView

/**
 是否需要光标，默认: YES
 */
@property (assign, nonatomic) BOOL showCursor;

/**
 验证码长度，默认: 4
 */
@property (nonatomic, assign, readonly) NSInteger codeLength;

/**
 是否开启密文模式，默认: NO，描述：你可以在任何时候修改该属性，并且已经存在的文字会自动刷新。
 */
@property (assign, nonatomic) BOOL needSecurity;

/**
 显示密文的延时时间，默认0防止录屏时录下明文
 */
@property (assign, nonatomic) CGFloat securityDelay;

/**
 键盘类型，默认: UIKeyboardTypeNumberPad
 */
@property (assign, nonatomic) UIKeyboardType keyboardType;

/**
 输入样式，默认: FWPasscodeInputTypeNumber
 */
@property (assign, nonatomic) FWPasscodeInputType inputType;

/**
自定义正则匹配输入内容，默认: @""，当inputType == FWPasscodeInputTypeRegex时才会生效
*/
@property (copy, nonatomic) NSString * _Nullable customInputRegex;

/**
 textContentType，描述: 你可以设置为 'nil' 或者 'UITextContentTypeOneTimeCode' 来自动获取短信验证码，默认: nil
 */
@property (null_unspecified,nonatomic,copy) UITextContentType textContentType NS_AVAILABLE_IOS(10_0);

/**
 占位字符填充值，在对应的输入框没有内容时，会显示该值。默认：nil
 */
@property (strong, nonatomic) NSString  * _Nullable placeholderText;

/**
 弹出键盘时，是否清空所有输入，只有在输入的字数等于codeLength时，生效。默认: NO
 */
@property (assign, nonatomic) BOOL clearAllWhenEditingBegin;

/**
 输入完成时，是否自动结束编辑模式，收起键盘。默认: YES
 */
@property (assign, nonatomic) BOOL endEditWhenEditingFinished;

@property (copy, nonatomic, nullable) void(^textDidChangeBlock)(NSString * _Nullable text, BOOL isFinished);
@property (copy, nonatomic, nullable) void(^editStatusChangeBlock)(FWPasscodeEditStatus editStatus);
@property (strong, nonatomic) FWPasscodeFlowLayout * _Nullable flowLayout;
@property (strong, nonatomic) FWPasscodeCellProperty * _Nullable cellProperty;
@property (strong, nonatomic, readonly) NSString  * _Nullable textValue;
@property (strong, nonatomic) UIView * _Nullable inputAccessoryView;

/**
 装载数据和准备界面，beginEdit: 自动开启编辑模式。默认: YES
 */
- (void)prepareView;
- (void)prepareViewWithBeginEdit:(BOOL)beginEdit;

/**
 重载输入的数据（用来设置预设数据）
 */
- (void)reloadInputString:(NSString *_Nullable)value;

/**
 开始或者结束编辑模式
 */
- (void)beginEdit;
- (void)endEdit;

/**
 清空输入，beginEdit: 自动开启编辑模式。默认: YES
 */
- (void)clearAll;
- (void)clearAllWithBeginEdit:(BOOL)beginEdit;

// 主collectionView
- (UICollectionView *_Nullable)collectionView;

// 快速设置
- (void)setSecuritySymbol:(NSString *_Nullable)securitySymbol;

// 你可以在继承的子类中调用父类方法
- (void)initDefaultValue;

// 你可以在继承的子类中重写父类方法
- (UICollectionViewCell *_Nullable)collectionView:(UICollectionView *_Nullable)collectionView customCellForItemAtIndexPath:(NSIndexPath *_Nullable)indexPath;

// code Length 调整
- (void)resetCodeLength:(NSInteger)codeLength beginEdit:(BOOL)beginEdit;

// Init
- (instancetype)initWithCodeLength:(NSInteger)codeLength;

@end

NS_ASSUME_NONNULL_END
