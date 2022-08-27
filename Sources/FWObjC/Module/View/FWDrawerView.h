//
//  FWDrawerView.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
抽屉拖拽视图
*/
NS_SWIFT_NAME(DrawerView)
@interface FWDrawerView : NSObject

// 创建抽屉拖拽视图，view会强引用之。view为滚动视图时，详见scrollView属性
- (instancetype)initWithView:(UIView *)view;

// 请使用initWithView
- (instancetype)init NS_UNAVAILABLE;

// 拖拽方向，如向上拖动视图时为Up，向下为Down，向右为Right，向左为Left。默认向上
@property (nonatomic, assign) UISwipeGestureRecognizerDirection direction;

// 抽屉位置，至少两级，相对于view父视图的originY位置
@property (nullable, nonatomic, strong) NSArray<NSNumber *> *positions;

// 回弹高度，拖拽小于该高度执行回弹，默认为0
@property (nonatomic, assign) CGFloat kickbackHeight;

// 抽屉视图位移回调，参数为相对view父视图的origin位置和是否拖拽完成的标记
@property (nullable, nonatomic, copy) void (^callback)(CGFloat position, BOOL finished);

// 是否启用拖拽，默认YES。其实就是设置手势的enabled
@property (nonatomic, assign) BOOL enabled;

// 是否自动检测滚动视图，默认YES。如需手工指定，请禁用之
@property (nonatomic, assign) BOOL autoDetected;

// 指定滚动视图，自动处理与滚动视图pan手势在指定方向的冲突。先尝试设置delegate为自身，尝试失败请手工调用scrollViewDidScroll
@property (nullable, nonatomic, weak) UIScrollView *scrollView;

// 抽屉视图，自动添加pan手势
@property (nonatomic, weak, readonly) UIView *view;

// 抽屉拖拽手势，默认设置delegate为自身
@property (nonatomic, weak, readonly) UIPanGestureRecognizer *gestureRecognizer;

// 抽屉视图当前位置
@property (nonatomic, assign, readonly) CGFloat position;

// 抽屉视图打开位置
@property (nonatomic, assign, readonly) CGFloat openPosition;

// 抽屉视图关闭位置
@property (nonatomic, assign, readonly) CGFloat closePosition;

// 设置抽屉效果视图到指定位置，如果位置发生改变，会触发抽屉callback回调
- (void)setPosition:(CGFloat)position animated:(BOOL)animated;

// 如果scrollView已自定义delegate，需在scrollViewDidScroll手工调用本方法
- (void)scrollViewDidScroll:(UIScrollView *)scrollView;

@end

/**
 视图抽屉拖拽效果分类
 */
@interface UIView (FWDrawerView)

// 抽屉拖拽视图，绑定抽屉拖拽效果后才存在
@property (nullable, nonatomic, strong) FWDrawerView *fw_drawerView NS_REFINED_FOR_SWIFT;

/**
 设置抽屉拖拽效果。如果view为滚动视图，自动处理与滚动视图pan手势冲突的问题
 
 @param direction 拖拽方向，如向上拖动视图时为Up，默认向上
 @param positions 抽屉位置，至少两级，相对于view父视图的originY位置
 @param kickbackHeight 回弹高度，拖拽小于该高度执行回弹
 @param callback 抽屉视图位移回调，参数为相对父视图的origin位置和是否拖拽完成的标记
 @return 抽屉拖拽视图
 */
- (FWDrawerView *)fw_drawerView:(UISwipeGestureRecognizerDirection)direction
                     positions:(NSArray<NSNumber *> *)positions
                kickbackHeight:(CGFloat)kickbackHeight
                      callback:(nullable void (^)(CGFloat position, BOOL finished))callback NS_REFINED_FOR_SWIFT;

@end

/**
滚动视图纵向手势冲突无缝滑动分类，需允许同时识别多个手势
*/
@interface UIScrollView (FWDrawerView)

// 外部滚动视图是否位于顶部固定位置，在顶部时不能滚动
@property (nonatomic, assign) BOOL fw_drawerSuperviewFixed NS_REFINED_FOR_SWIFT;

// 外部滚动视图scrollViewDidScroll调用，参数为固定的位置
- (void)fw_drawerSuperviewDidScroll:(CGFloat)position NS_REFINED_FOR_SWIFT;

// 内嵌滚动视图scrollViewDidScroll调用，参数为外部滚动视图
- (void)fw_drawerSubviewDidScroll:(UIScrollView *)superview NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
