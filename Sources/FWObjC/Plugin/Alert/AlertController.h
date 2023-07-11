//
//  AlertController.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import <UIKit/UIKit.h>
#import "AlertPlugin.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, __FWAlertControllerStyle) {
    __FWAlertControllerStyleActionSheet = 0, // 从单侧弹出(顶/左/底/右)
    __FWAlertControllerStyleAlert,           // 从中间弹出
} NS_SWIFT_NAME(AlertControllerStyle);

typedef NS_ENUM(NSInteger, __FWAlertAnimationType) {
    __FWAlertAnimationTypeDefault = 0, // 默认动画，如果是__FWAlertControllerStyleActionSheet样式,默认动画等效于__FWAlertAnimationTypeFromBottom，如果是__FWAlertControllerStyleAlert样式,默认动画等效于__FWAlertAnimationTypeShrink
    __FWAlertAnimationTypeFromBottom,  // 从底部弹出
    __FWAlertAnimationTypeFromTop,     // 从顶部弹出
    __FWAlertAnimationTypeFromRight,   // 从右边弹出
    __FWAlertAnimationTypeFromLeft,    // 从左边弹出
    
    __FWAlertAnimationTypeShrink,      // 收缩动画
    __FWAlertAnimationTypeExpand,      // 发散动画
    __FWAlertAnimationTypeFade,        // 渐变动画

    __FWAlertAnimationTypeNone,        // 无动画
} NS_SWIFT_NAME(AlertAnimationType);

typedef NS_ENUM(NSInteger, __FWAlertActionStyle) {
    __FWAlertActionStyleDefault = 0,  // 默认样式
    __FWAlertActionStyleCancel,       // 取消样式,字体加粗
    __FWAlertActionStyleDestructive   // 红色字体样式
} NS_SWIFT_NAME(AlertActionStyle);

/** __FWAlertController样式，继承自__FWAlertAppearance */
NS_SWIFT_NAME(AlertControllerAppearance)
@interface __FWAlertControllerAppearance : __FWAlertAppearance
@property (class, nonatomic, readonly) __FWAlertControllerAppearance *appearance;

@property (nonatomic, assign) CGFloat lineWidth;
@property (nonatomic, assign) CGFloat cancelLineWidth;
@property (nonatomic, assign) UIEdgeInsets contentInsets;
@property (nonatomic, assign) CGFloat actionHeight;
@property (nonatomic, strong) UIFont *actionFont;
@property (nonatomic, strong) UIFont *actionBoldFont;
@property (nonatomic, assign) CGFloat imageTitleSpacing;
@property (nonatomic, assign) CGFloat titleMessageSpacing;
@property (nonatomic, assign) CGFloat textFieldHeight;
@property (nonatomic, assign) CGFloat textFieldTopMargin;
@property (nonatomic, assign) CGFloat textFieldSpacing;
@property (nonatomic, assign) CGFloat alertCornerRadius;
@property (nonatomic, assign) CGFloat alertEdgeDistance;
@property (nonatomic, assign) CGFloat sheetCornerRadius;
@property (nonatomic, assign) CGFloat sheetEdgeDistance;

@property (nonatomic, strong) UIColor *normalColor;
@property (nonatomic, strong) UIColor *selectedColor;
@property (nonatomic, strong) UIColor *lineColor;
@property (nonatomic, strong) UIColor *cancelLineColor;
@property (nonatomic, strong) UIColor *lightLineColor;
@property (nonatomic, strong) UIColor *darkLineColor;
@property (nonatomic, strong) UIColor *containerBackgroundColor;
@property (nonatomic, strong) UIColor *titleDynamicColor;
@property (nonatomic, strong) UIColor *textFieldBackgroundColor;
@property (nonatomic, assign) CGFloat textFieldCornerRadius;
@property (nonatomic, copy, nullable) void (^textFieldCustomBlock)(UITextField *textField);
@property (nonatomic, strong) UIColor *alertRedColor;
@property (nonatomic, strong) UIColor *grayColor;

@property (nonatomic, assign) BOOL sheetContainerTransparent;
@property (nonatomic, assign) UIEdgeInsets sheetContainerInsets;

@end

// ===================================================== __FWAlertAction =====================================================
NS_SWIFT_NAME(AlertAction)
@interface __FWAlertAction : NSObject <NSCopying>

+ (instancetype)actionWithTitle:(nullable NSString *)title style:(__FWAlertActionStyle)style handler:(void (^ __nullable)(__FWAlertAction *action))handler;
+ (instancetype)actionWithTitle:(nullable NSString *)title style:(__FWAlertActionStyle)style appearance:(nullable __FWAlertControllerAppearance *)appearance handler:(void (^ __nullable)(__FWAlertAction *action))handler;

/** action的标题 */
@property(nullable, nonatomic, copy) NSString *title;
/** action的富文本标题 */
@property(nullable, nonatomic, copy) NSAttributedString *attributedTitle;
/** action的图标，位于title的左边 */
@property(nullable, nonatomic, copy) UIImage *image;
/** title跟image之间的间距 */
@property (nonatomic, assign) CGFloat imageTitleSpacing;
/** 渲染颜色,当外部的图片使用了UIImageRenderingModeAlwaysTemplate时,使用该属性可改变图片的颜色 */
@property (nonatomic, strong) UIColor *tintColor;
/** 是否能点击,默认为YES */
@property(nonatomic, getter=isEnabled) BOOL enabled;
/** 是否是首选动作,默认为NO */
@property(nonatomic, assign) BOOL isPreferred;
/** action的标题颜色,这个颜色只是普通文本的颜色，富文本颜色需要用NSForegroundColorAttributeName */
@property(nonatomic, strong) UIColor *titleColor;
/** action的标题字体,如果文字太长显示不全，会自动改变字体自适应按钮宽度，最多压缩文字为原来的0.5倍封顶 */
@property(nonatomic, strong) UIFont *titleFont;
/** action的标题的内边距，如果在不改变字体的情况下想增大action的高度，可以设置该属性的top和bottom值,默认UIEdgeInsetsMake(0, 15, 0, 15) */
@property(nonatomic, assign) UIEdgeInsets titleEdgeInsets;

/** 样式 */
@property(nonatomic, readonly) __FWAlertActionStyle style;
/** 自定义样式，默认为样式单例 */
@property (nonatomic, strong, readonly) __FWAlertControllerAppearance *alertAppearance;

@end

// ===================================================== __FWAlertController =====================================================

@protocol __FWAlertControllerDelegate;

/**
 __FWAlertController

 @see https://github.com/SPStore/SPAlertController
 */
NS_SWIFT_NAME(AlertController)
@interface __FWAlertController : UIViewController

+ (instancetype)alertControllerWithTitle:(nullable NSString *)title message:(nullable NSString *)message preferredStyle:(__FWAlertControllerStyle)preferredStyle;
+ (instancetype)alertControllerWithTitle:(nullable NSString *)title message:(nullable NSString *)message preferredStyle:(__FWAlertControllerStyle)preferredStyle animationType:(__FWAlertAnimationType)animationType;
+ (instancetype)alertControllerWithTitle:(nullable NSString *)title message:(nullable NSString *)message preferredStyle:(__FWAlertControllerStyle)preferredStyle animationType:(__FWAlertAnimationType)animationType appearance:(nullable __FWAlertControllerAppearance *)appearance;

- (void)addAction:(__FWAlertAction *)action;
@property (nonatomic, readonly) NSArray<__FWAlertAction *> *actions;

@property (nullable, nonatomic, strong) __FWAlertAction *preferredAction;

/* 添加文本输入框
 * 一旦添加后就会回调一次(仅回调一次,因此可以在这个block块里面自由定制textFiled,如设置textField的属性,设置代理,添加addTarget,监听通知等);
 */
- (void)addTextFieldWithConfigurationHandler:(void (^ __nullable)(UITextField *textField))configurationHandler;
@property(nullable, nonatomic, readonly) NSArray<UITextField *> *textFields;

/** 主标题 */
@property(nullable, nonatomic, copy) NSString *title;
/** 副标题 */
@property(nullable, nonatomic, copy) NSString *message;
/** 弹窗样式，默认Default */
@property(nonatomic, assign) __FWAlertStyle alertStyle;
/** 主标题(富文本) */
@property(nullable, nonatomic, copy) NSAttributedString *attributedTitle;
/** 副标题(富文本) */
@property(nullable, nonatomic, copy) NSAttributedString *attributedMessage;
/** 头部图标，位置处于title之上,大小取决于图片本身大小 */
@property(nullable,nonatomic, copy) UIImage *image;

/** 主标题颜色 */
@property(nonatomic, strong) UIColor *titleColor;
/** 主标题字体,默认18,加粗 */
@property(nonatomic, strong) UIFont *titleFont;
/** 副标题颜色 */
@property(nonatomic, strong) UIColor *messageColor;
/** 副标题字体,默认16,未加粗 */
@property(nonatomic, strong) UIFont *messageFont;
/** 对齐方式(包括主标题和副标题) */
@property(nonatomic, assign) NSTextAlignment textAlignment;
/** 头部图标的限制大小,默认无穷大 */
@property (nonatomic, assign) CGSize imageLimitSize;
/** 图片的tintColor,当外部的图片使用了UIImageRenderingModeAlwaysTemplate时,该属性可起到作用 */
@property (nonatomic, strong) UIColor *imageTintColor;

/*
 * action水平排列还是垂直排列
 * actionSheet样式下:默认为UILayoutConstraintAxisVertical(垂直排列), 如果设置为UILayoutConstraintAxisHorizontal(水平排列)，则除去取消样式action之外的其余action将水平排列
 * alert样式下:当actions的个数大于2，或者某个action的title显示不全时为UILayoutConstraintAxisVertical(垂直排列)，否则默认为UILayoutConstraintAxisHorizontal(水平排列)，此样式下设置该属性可以修改所有action的排列方式
 * 不论哪种样式，只要外界设置了该属性，永远以外界设置的优先
 */
@property(nonatomic) UILayoutConstraintAxis actionAxis;

/* 距离屏幕边缘的最小间距
 * alert样式下该属性是指对话框四边与屏幕边缘之间的距离，此样式下默认值随设备变化，actionSheet样式下是指弹出边的对立边与屏幕之间的距离，比如如果从右边弹出，那么该属性指的就是对话框左边与屏幕之间的距离，此样式下默认值为70
 */
@property(nonatomic, assign) CGFloat minDistanceToEdges;

/** __FWAlertControllerStyleAlert样式下默认6.0f，__FWAlertControllerStyleActionSheet样式下默认13.0f，去除半径设置为0即可 */
@property(nonatomic, assign) CGFloat cornerRadius;

/** 对话框的偏移量，y值为正向下偏移，为负向上偏移；x值为正向右偏移，为负向左偏移，该属性只对__FWAlertControllerStyleAlert样式有效,键盘的frame改变会自动偏移，如果手动设置偏移只会取手动设置的 */
@property(nonatomic, assign) CGPoint offsetForAlert;
/** 设置alert样式下的偏移量,动画为NO则跟属性offsetForAlert等效 */
- (void)setOffsetForAlert:(CGPoint)offsetForAlert animated:(BOOL)animated;

/** 是否需要对话框拥有毛玻璃,默认为YES */
@property(nonatomic, assign) BOOL needDialogBlur;

/** 是否含有自定义TextField,键盘的frame改变会自动偏移,默认为NO */
@property(nonatomic, assign) BOOL customTextField;

/** 是否单击背景退出对话框,默认为YES */
@property(nonatomic, assign) BOOL tapBackgroundViewDismiss;
/** 是否点击动作按钮退出动画框,默认为YES */
@property(nonatomic, assign) BOOL tapActionDismiss;

/** 单击背景dismiss完成回调，默认nil */
@property (nullable, nonatomic, copy) void(^dismissCompletion)(void);

@property(nonatomic, weak) id<__FWAlertControllerDelegate> delegate;

@property(nonatomic, readonly) __FWAlertControllerStyle preferredStyle;
@property(nonatomic, assign) __FWAlertAnimationType animationType;
/** 自定义样式，默认为样式单例 */
@property (nonatomic, strong, readonly) __FWAlertControllerAppearance *alertAppearance;

/** 设置action与下一个action之间的间距, action仅限于非取消样式，必须在'-addAction:'之后设置，nil时设置header与action间距 */
- (void)setCustomSpacing:(CGFloat)spacing afterAction:(nullable __FWAlertAction *)action;
- (CGFloat)customSpacingAfterAction:(nullable __FWAlertAction *)action;

/** 设置蒙层的外观样式,可通过alpha调整透明度 */
- (void)setBackgroundViewAppearanceStyle:(UIBlurEffectStyle)style alpha:(CGFloat)alpha;

// 插入一个组件view，位置处于头部和action部分之间，要求头部和action部分同时存在
- (void)insertComponentView:(nonnull UIView *)componentView;


// ---------------------------------------------- custom -----------------------------------------------------
/**
 创建控制器(自定义整个对话框)
 
 @param customAlertView 整个对话框的自定义view
 @param preferredStyle 对话框样式
 @param animationType 动画类型
 @return 控制器对象
 */
+ (instancetype)alertControllerWithCustomAlertView:(nonnull UIView *)customAlertView preferredStyle:(__FWAlertControllerStyle)preferredStyle animationType:(__FWAlertAnimationType)animationType;
/**
 创建控制器(自定义对话框的头部)
 
 @param customHeaderView 头部自定义view
 @param preferredStyle 对话框样式
 @param animationType 动画类型
 @return 控制器对象
 */
+ (instancetype)alertControllerWithCustomHeaderView:(nonnull UIView *)customHeaderView preferredStyle:(__FWAlertControllerStyle)preferredStyle animationType:(__FWAlertAnimationType)animationType;

/**
 创建控制器(自定义对话框的头部)
 
 @param customHeaderView 头部自定义view
 @param preferredStyle 对话框样式
 @param animationType 动画类型
 @param appearance 自定义样式
 @return 控制器对象
 */
+ (instancetype)alertControllerWithCustomHeaderView:(nonnull UIView *)customHeaderView preferredStyle:(__FWAlertControllerStyle)preferredStyle animationType:(__FWAlertAnimationType)animationType appearance:(nullable __FWAlertControllerAppearance *)appearance;

/**
 创建控制器(自定义对话框的action部分)
 
 @param customActionSequenceView action部分的自定义view
 @param title 大标题
 @param message 副标题
 @param preferredStyle 对话框样式
 @param animationType 动画类型
 @return 控制器对象
 */
+ (instancetype)alertControllerWithCustomActionSequenceView:(nonnull UIView *)customActionSequenceView title:(nullable NSString *)title message:(nullable NSString *)message preferredStyle:(__FWAlertControllerStyle)preferredStyle animationType:(__FWAlertAnimationType)animationType;

/** 更新自定义view的size，比如屏幕旋转，自定义view的大小发生了改变，可通过该方法更新size */
- (void)updateCustomViewSize:(CGSize)size;

@end

NS_SWIFT_NAME(AlertControllerDelegate)
@protocol __FWAlertControllerDelegate <NSObject>
@optional;
- (void)willPresentAlertController:(__FWAlertController *)alertController; // 将要present
- (void)didPresentAlertController:(__FWAlertController *)alertController;  // 已经present
- (void)willDismissAlertController:(__FWAlertController *)alertController; // 将要dismiss
- (void)didDismissAlertController:(__FWAlertController *)alertController;  // 已经dismiss
@end

NS_SWIFT_NAME(AlertPresentationController)
@interface __FWAlertPresentationController : UIPresentationController
@end

NS_SWIFT_NAME(AlertAnimation)
@interface __FWAlertAnimation : NSObject <UIViewControllerAnimatedTransitioning>
+ (instancetype)animationIsPresenting:(BOOL)presenting;
@end

NS_ASSUME_NONNULL_END
