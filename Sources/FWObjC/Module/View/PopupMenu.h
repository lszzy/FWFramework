//
//  PopupMenu.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - __FWPopupMenuPath

typedef NS_ENUM(NSInteger, __FWPopupMenuArrowDirection) {
    __FWPopupMenuArrowDirectionTop = 0,  //箭头朝上
    __FWPopupMenuArrowDirectionBottom,   //箭头朝下
    __FWPopupMenuArrowDirectionLeft,     //箭头朝左
    __FWPopupMenuArrowDirectionRight,    //箭头朝右
    __FWPopupMenuArrowDirectionNone      //没有箭头
} NS_SWIFT_NAME(PopupMenuArrowDirection);

NS_SWIFT_NAME(PopupMenuPath)
@interface __FWPopupMenuPath : NSObject

+ (CAShapeLayer *)maskLayerWithRect:(CGRect)rect
                         rectCorner:(UIRectCorner)rectCorner
                       cornerRadius:(CGFloat)cornerRadius
                         arrowWidth:(CGFloat)arrowWidth
                        arrowHeight:(CGFloat)arrowHeight
                      arrowPosition:(CGFloat)arrowPosition
                     arrowDirection:(__FWPopupMenuArrowDirection)arrowDirection;

+ (UIBezierPath *)bezierPathWithRect:(CGRect)rect
                          rectCorner:(UIRectCorner)rectCorner
                        cornerRadius:(CGFloat)cornerRadius
                         borderWidth:(CGFloat)borderWidth
                         borderColor:(nullable UIColor *)borderColor
                     backgroundColor:(nullable UIColor *)backgroundColor
                          arrowWidth:(CGFloat)arrowWidth
                         arrowHeight:(CGFloat)arrowHeight
                       arrowPosition:(CGFloat)arrowPosition
                      arrowDirection:(__FWPopupMenuArrowDirection)arrowDirection;
@end

#pragma mark - __FWPopupMenuDeviceOrientationManager

NS_SWIFT_NAME(PopupMenuDeviceOrientationManager)
@protocol __FWPopupMenuDeviceOrientationManager <NSObject>

/**
 根据屏幕旋转方向自动旋转 Default is YES
 */
@property (nonatomic, assign) BOOL autoRotateWhenDeviceOrientationChanged;

@property (nonatomic, copy, nullable) void (^deviceOrientDidChangeHandle) (UIInterfaceOrientation orientation);

+ (id <__FWPopupMenuDeviceOrientationManager>)manager;

/**
 开始监听
 */
- (void)startMonitorDeviceOrientation;

/**
 结束监听
 */
- (void)endMonitorDeviceOrientation;

@end

NS_SWIFT_NAME(PopupMenuDeviceOrientationManager)
@interface __FWPopupMenuDeviceOrientationManager : NSObject <__FWPopupMenuDeviceOrientationManager>

@end

#pragma mark - __FWPopupMenuAnimationManager

typedef NS_ENUM(NSInteger,__FWPopupMenuAnimationStyle) {
    __FWPopupMenuAnimationStyleScale = 0,       //scale动画 Default
    __FWPopupMenuAnimationStyleFade,            //alpha 0~1
    __FWPopupMenuAnimationStyleNone,            //没有动画
    __FWPopupMenuAnimationStyleCustom           //自定义
} NS_SWIFT_NAME(PopupMenuAnimationStyle);

NS_SWIFT_NAME(PopupMenuAnimationManager)
@protocol __FWPopupMenuAnimationManager <NSObject>

/**
 动画类型，默认__FWPopupMenuAnimationStyleScale
 */
@property (nonatomic, assign) __FWPopupMenuAnimationStyle style;

/**
 显示动画，自定义可用
 */
@property (nonatomic, strong, nullable) CAAnimation * showAnimation;

/**
 隐藏动画，自定义可用
 */
@property (nonatomic, strong, nullable) CAAnimation * dismissAnimation;

/**
 弹出和隐藏动画的时间，Default is 0.25
 */
@property CFTimeInterval duration;

@property (nonatomic, weak, nullable) UIView * animationView;

+ (id <__FWPopupMenuAnimationManager>)manager;

- (void)displayShowAnimationCompletion:(nullable void (^) (void))completion;

- (void)displayDismissAnimationCompletion:(nullable void (^) (void))completion;

@end

NS_SWIFT_NAME(PopupMenuAnimationManager)
@interface __FWPopupMenuAnimationManager : NSObject<__FWPopupMenuAnimationManager>

@end

#pragma mark - __FWPopupMenu

/**
 箭头方向优先级

 当控件超出屏幕时会自动调整成反方向
 */
typedef NS_ENUM(NSInteger , __FWPopupMenuPriorityDirection) {
    __FWPopupMenuPriorityDirectionTop = 0,  //Default
    __FWPopupMenuPriorityDirectionBottom,
    __FWPopupMenuPriorityDirectionLeft,
    __FWPopupMenuPriorityDirectionRight,
    __FWPopupMenuPriorityDirectionNone      //不自动调整
} NS_SWIFT_NAME(PopupMenuPriorityDirection);

@class __FWPopupMenu;
NS_SWIFT_NAME(PopupMenuDelegate)
@protocol __FWPopupMenuDelegate <NSObject>

@optional

- (void)popupMenuBeganDismiss:(__FWPopupMenu *)popupMenu;
- (void)popupMenuDidDismiss:(__FWPopupMenu *)popupMenu;
- (void)popupMenuBeganShow:(__FWPopupMenu *)popupMenu;
- (void)popupMenuDidShow:(__FWPopupMenu *)popupMenu;

/**
 点击事件回调
 */
- (void)popupMenu:(__FWPopupMenu *)popupMenu didSelectedAtIndex:(NSInteger)index;

/**
 自定义cell
 
 可以自定义cell，设置后会忽略 fontSize textColor backColor type 属性
 cell 的高度是根据 itemHeight 的，直接设置无效
 建议cell 背景色设置为透明色，不然切的圆角显示不出来
 */
- (nullable UITableViewCell *)popupMenu:(__FWPopupMenu *)popupMenu cellForRowAtIndex:(NSInteger)index;

@end

/**
__FWPopupMenu

@see https://github.com/lyb5834/YBPopupMenu
*/
NS_SWIFT_NAME(PopupMenu)
@interface __FWPopupMenu : UIView

/**
 标题数组 只读属性
 */
@property (nonatomic, strong, readonly, nullable) NSArray  * titles;

/**
 图片数组 只读属性
 */
@property (nonatomic, strong, readonly, nullable) NSArray  * images;

/**
 tableView  Default separatorStyle is UITableViewCellSeparatorStyleNone
 */
@property (nonatomic, strong) UITableView * tableView;

/**
 圆角半径 Default is 5.0
 */
@property (nonatomic, assign) CGFloat cornerRadius;

/**
 自定义圆角 Default is UIRectCornerAllCorners
 
 当自动调整方向时corner会自动转换至镜像方向
 */
@property (nonatomic, assign) UIRectCorner rectCorner;

/**
 是否显示阴影 Default is YES
 */
@property (nonatomic, assign) BOOL showsShadow;

/**
 是否显示灰色覆盖层 Default is YES
 */
@property (nonatomic, assign) BOOL showsMaskView;

/**
 自定义灰色覆盖层颜色，默认黑色、透明度0.1
 */
@property (nonatomic, strong, nullable) UIColor *maskViewColor;

/**
 选择菜单项后消失 Default is YES
 */
@property (nonatomic, assign) BOOL dismissOnSelected;

/**
 点击菜单外消失  Default is YES
 */
@property (nonatomic, assign) BOOL dismissOnTouchOutside;

/**
 设置字体大小 自定义cell时忽略 Default is 15
 */
@property (nonatomic, assign) CGFloat fontSize;

/**
 设置字体 设置时忽略fontSize Default is nil
 */
@property (nonatomic, strong) UIFont * font;

/**
 设置字体颜色 自定义cell时忽略 Default is [UIColor blackColor]
 */
@property (nonatomic, strong) UIColor * textColor;

/**
 设置偏移距离 (>= 0) Default is 0.0
 */
@property (nonatomic, assign) CGFloat offset;

/**
 边框宽度 Default is 0.0
 
 设置边框需 > 0
 */
@property (nonatomic, assign) CGFloat borderWidth;

/**
 边框颜色 Default is LightGrayColor
 
 borderWidth <= 0 无效
 */
@property (nonatomic, strong) UIColor * borderColor;

/**
 箭头宽度 Default is 15
 */
@property (nonatomic, assign) CGFloat arrowWidth;

/**
 箭头高度 Default is 10
 */
@property (nonatomic, assign) CGFloat arrowHeight;

/**
 箭头位置 Default is center
 
 只有箭头优先级是__FWPopupMenuPriorityDirectionLeft/__FWPopupMenuPriorityDirectionRight/__FWPopupMenuPriorityDirectionNone时需要设置
 */
@property (nonatomic, assign) CGFloat arrowPosition;

/**
 箭头方向 Default is __FWPopupMenuArrowDirectionTop
 */
@property (nonatomic, assign) __FWPopupMenuArrowDirection arrowDirection;

/**
 箭头优先方向 Default is __FWPopupMenuPriorityDirectionTop
 
 当控件超出屏幕时会自动调整箭头位置
 */
@property (nonatomic, assign) __FWPopupMenuPriorityDirection priorityDirection;

/**
 可见的最大行数 Default is 5;
 */
@property (nonatomic, assign) NSInteger maxVisibleCount;

/**
 menu背景色 自定义cell时忽略 Default is WhiteColor
 */
@property (nonatomic, strong) UIColor * backColor;

/**
 item的高度 Default is 44;
 */
@property (nonatomic, assign) CGFloat itemHeight;

/**
 popupMenu距离最近的Screen的距离 Default is 10
 */
@property (nonatomic, assign) CGFloat minSpace;

/**
 是否显示分割线，默认YES. 自定义cell时忽略
 */
@property (nonatomic, assign) BOOL showsSeparator;

/**
 自定义分割线高度，默认0.5. 自定义cell时忽略
 */
@property (nonatomic, assign) CGFloat separatorHeight;

/**
 设置分割线颜色，默认lightGrayColor. 自定义cell时忽略
 */
@property (nonatomic, strong) UIColor *separatorColor;

/**
 设置分割线偏移，默认zero. 自定义cell时忽略
 */
@property (nonatomic, assign) UIEdgeInsets separatorInsets;

/**
 自定义imageView的位置偏移，默认zero不生效. 自定义cell时忽略
 */
@property (nonatomic, assign) UIEdgeInsets imageEdgeInsets;

/**
 自定义textLabel的位置偏移，默认zero不生效. 自定义cell时忽略
 */
@property (nonatomic, assign) UIEdgeInsets titleEdgeInsets;

/**
 点击事件回调句柄
 */
@property (nonatomic, copy, nullable) void (^didSelectItemBlock)(NSInteger index);

/**
 自定义cell句柄，优先级低于delegate
 */
@property (nonatomic, copy, nullable) UITableViewCell * _Nullable (^customCellBlock)(__FWPopupMenu *popupMenu, NSInteger index);

/**
 屏幕旋转管理
 */
@property (nonatomic, strong) id <__FWPopupMenuDeviceOrientationManager> orientationManager;

/**
 动画管理
 */
@property (nonatomic, strong) id <__FWPopupMenuAnimationManager> animationManager;

/**
 代理
 */
@property (nonatomic, weak, nullable) id <__FWPopupMenuDelegate> delegate;

/**
 在指定位置弹出
 
 @param point          弹出的位置
 @param titles         标题数组  数组里是NSString/NSAttributedString
 @param icons          图标数组  数组里是NSString/UIImage
 @param itemWidth      菜单宽度
 @param otherSetting   其他设置
 */
+ (__FWPopupMenu *)showAtPoint:(CGPoint)point
                      titles:(nullable NSArray *)titles
                       icons:(nullable NSArray *)icons
                   menuWidth:(CGFloat)itemWidth
               otherSettings:(nullable void (^) (__FWPopupMenu * popupMenu))otherSetting;

/**
 依赖指定view弹出

 @param view           依赖的视图
 @param titles         标题数组  数组里是NSString/NSAttributedString
 @param icons          图标数组  数组里是NSString/UIImage
 @param itemWidth      菜单宽度
 @param otherSetting   其他设置
 */
+ (__FWPopupMenu *)showRelyOnView:(UIView *)view
                         titles:(nullable NSArray *)titles
                          icons:(nullable NSArray *)icons
                      menuWidth:(CGFloat)itemWidth
                  otherSettings:(nullable void (^) (__FWPopupMenu * popupMenu))otherSetting;

/**
 消失
 */
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END
