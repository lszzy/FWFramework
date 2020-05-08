//
//  FWAlertController.h
//  FWFramework
//
//  Created by wuyong on 2020/4/25.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, FWAlertControllerStyle) {
    FWAlertControllerStyleActionSheet = 0, // 从单侧弹出(顶/左/底/右)
    FWAlertControllerStyleAlert,           // 从中间弹出
};

typedef NS_ENUM(NSInteger, FWAlertAnimationType) {
    FWAlertAnimationTypeDefault = 0, // 默认动画，如果是FWAlertControllerStyleActionSheet样式,默认动画等效于FWAlertAnimationTypeFromBottom，如果是FWAlertControllerStyleAlert样式,默认动画等效于FWAlertAnimationTypeShrink
    FWAlertAnimationTypeFromBottom,  // 从底部弹出
    FWAlertAnimationTypeFromTop,     // 从顶部弹出
    FWAlertAnimationTypeFromRight,   // 从右边弹出
    FWAlertAnimationTypeFromLeft,    // 从左边弹出
    
    FWAlertAnimationTypeShrink,      // 收缩动画
    FWAlertAnimationTypeExpand,      // 发散动画
    FWAlertAnimationTypeFade,        // 渐变动画

    FWAlertAnimationTypeNone,        // 无动画
};

typedef NS_ENUM(NSInteger, FWAlertActionStyle) {
    FWAlertActionStyleDefault = 0,  // 默认样式
    FWAlertActionStyleCancel,       // 取消样式,字体加粗
    FWAlertActionStyleDestructive   // 红色字体样式
};

typedef NS_ENUM(NSInteger, FWBackgroundViewAppearanceStyle) {
    FWBackgroundViewAppearanceStyleTranslucent = 0,  // 无毛玻璃效果,黑色透明(默认是0.5透明)
    FWBackgroundViewAppearanceStyleBlurDark,
    FWBackgroundViewAppearanceStyleBlurExtraLight,
    FWBackgroundViewAppearanceStyleBlurLight,
};

#pragma mark - FWAlertAction

@interface FWAlertAction : NSObject <NSCopying>

/** 创建一个action */
+ (instancetype)actionWithTitle:(nullable NSString *)title style:(FWAlertActionStyle)style handler:(void (^ __nullable)(FWAlertAction *action))handler;

/** action的标题 */
@property(nullable, nonatomic, copy) NSString *title;
/** action的富文本标题 */
@property(nullable, nonatomic, copy) NSAttributedString *attributedTitle;
/** action的图标，位于title的左边 */
@property(nullable, nonatomic, copy) UIImage *image;
/** title跟image之间的间距 */
@property (nonatomic, assign) CGFloat imageTitleSpacing;
/** 样式 */
@property(nonatomic, readonly) FWAlertActionStyle style;
/** 是否能点击,默认为YES */
@property(nonatomic, getter=isEnabled) BOOL enabled;
/** action的标题颜色,这个颜色只是普通文本的颜色，富文本颜色需要用NSForegroundColorAttributeName */
@property(nonatomic, strong) UIColor *titleColor;
/** action的标题字体,如果文字太长显示不全，会自动改变字体自适应按钮宽度，最多压缩文字为原来的0.5倍封顶 */
@property(nonatomic, strong) UIFont *titleFont;
/** action的标题的内边距，如果在不改变字体的情况下想增大action的高度，可以设置该属性的top和bottom值,默认UIEdgeInsetsMake(0, 15, 0, 15) */
@property(nonatomic, assign) UIEdgeInsets titleEdgeInsets;

@end

#pragma mark - FWAlertController

@protocol FWAlertControllerDelegate;

/*!
 @brief FWAlertController
 
 @see https://github.com/SPStore/SPAlertController
 */
@interface FWAlertController : UIViewController

+ (instancetype)alertControllerWithTitle:(nullable NSString *)title message:(nullable NSString *)message preferredStyle:(FWAlertControllerStyle)preferredStyle;
+ (instancetype)alertControllerWithTitle:(nullable NSString *)title message:(nullable NSString *)message preferredStyle:(FWAlertControllerStyle)preferredStyle animationType:(FWAlertAnimationType)animationType; // animationType传FWAlertAnimationTypeDefault则跟第一个类方法等效

- (void)addAction:(FWAlertAction *)action;
@property (nonatomic, readonly) NSArray<FWAlertAction *> *actions;

@property (nullable, nonatomic, strong) FWAlertAction *preferredAction;

/* 添加文本输入框
 * 一旦添加后就会回调一次(仅回调一次,因此可以在这个block块里面自由定制textFiled,如设置textField的属性,设置代理,添加addTarget,监听通知等);
 */
- (void)addTextFieldWithConfigurationHandler:(void (^ __nullable)(UITextField *textField))configurationHandler;
@property(nullable, nonatomic, readonly) NSArray<UITextField *> *textFields;

/** 主标题 */
@property(nullable, nonatomic, copy) NSString *title;
/** 副标题 */
@property(nullable, nonatomic, copy) NSString *message;
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

/** FWAlertControllerStyleAlert样式下默认6.0f，FWAlertControllerStyleActionSheet样式下默认13.0f，去除半径设置为0即可 */
@property(nonatomic, assign) CGFloat cornerRadius;

/** 对话框的偏移量，y值为正向下偏移，为负向上偏移；x值为正向右偏移，为负向左偏移，该属性只对FWAlertControllerStyleAlert样式有效,键盘的frame改变会自动偏移，如果手动设置偏移只会取手动设置的 */
@property(nonatomic, assign) CGPoint offsetForAlert;
/** 设置alert样式下的偏移量,动画为NO则跟属性offsetForAlert等效 */
- (void)setOffsetForAlert:(CGPoint)offsetForAlert animated:(BOOL)animated;

/** 是否需要对话框拥有毛玻璃,默认为YES */
@property(nonatomic, assign) BOOL needDialogBlur;

/** 是否单击背景退出对话框,默认为YES */
@property(nonatomic, assign) BOOL tapBackgroundViewDismiss;

@property(nonatomic, weak) id<FWAlertControllerDelegate> delegate;

@property(nonatomic, readonly) FWAlertControllerStyle preferredStyle;
@property(nonatomic, readonly) FWAlertAnimationType animationType;

/** 设置action与下一个action之间的间距, action仅限于非取消样式，必须在'-addAction:'之后设置，iOS11或iOS11以上才能使用 */
- (void)setCustomSpacing:(CGFloat)spacing afterAction:(FWAlertAction *)action API_AVAILABLE(ios(11.0));
- (CGFloat)customSpacingAfterAction:(FWAlertAction *)action API_AVAILABLE(ios(11.0));

/** 设置蒙层的外观样式,可通过alpha调整透明度 */
- (void)setBackgroundViewAppearanceStyle:(FWBackgroundViewAppearanceStyle)style alpha:(CGFloat)alpha;

// 插入一个组件view，位置处于头部和action部分之间，要求头部和action部分同时存在
- (void)insertComponentView:(nonnull UIView *)componentView;

/**
 创建控制器(自定义整个对话框)
 
 @param customAlertView 整个对话框的自定义view
 @param preferredStyle 对话框样式
 @param animationType 动画类型
 @return 控制器对象
 */
+ (instancetype)alertControllerWithCustomAlertView:(nonnull UIView *)customAlertView preferredStyle:(FWAlertControllerStyle)preferredStyle animationType:(FWAlertAnimationType)animationType;
/**
 创建控制器(自定义对话框的头部)
 
 @param customHeaderView 头部自定义view
 @param preferredStyle 对话框样式
 @param animationType 动画类型
 @return 控制器对象
 */
+ (instancetype)alertControllerWithCustomHeaderView:(nonnull UIView *)customHeaderView preferredStyle:(FWAlertControllerStyle)preferredStyle animationType:(FWAlertAnimationType)animationType;
/**
 创建控制器(自定义对话框的action部分)
 
 @param customActionSequenceView action部分的自定义view
 @param title 大标题
 @param message 副标题
 @param preferredStyle 对话框样式
 @param animationType 动画类型
 @return 控制器对象
 */
+ (instancetype)alertControllerWithCustomActionSequenceView:(nonnull UIView *)customActionSequenceView title:(nullable NSString *)title message:(nullable NSString *)message preferredStyle:(FWAlertControllerStyle)preferredStyle animationType:(FWAlertAnimationType)animationType;

/** 更新自定义view的size，比如屏幕旋转，自定义view的大小发生了改变，可通过该方法更新size */
- (void)updateCustomViewSize:(CGSize)size;

@end

@protocol FWAlertControllerDelegate <NSObject>

@optional;
- (void)willPresentAlertController:(FWAlertController *)alertController; // 将要present
- (void)didPresentAlertController:(FWAlertController *)alertController;  // 已经present
- (void)willDismissAlertController:(FWAlertController *)alertController; // 将要dismiss
- (void)didDismissAlertController:(FWAlertController *)alertController;  // 已经dismiss

@end

@interface FWAlertPresentationController : UIPresentationController
@end

@interface FWAlertAnimation : NSObject <UIViewControllerAnimatedTransitioning>
+ (instancetype)animationIsPresenting:(BOOL)presenting;
@end

NS_ASSUME_NONNULL_END
