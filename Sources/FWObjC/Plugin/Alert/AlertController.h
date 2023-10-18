//
//  AlertController.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(AlertController)
@interface __FWAlertController : UIViewController

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

@end

NS_ASSUME_NONNULL_END
