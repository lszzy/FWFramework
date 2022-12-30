//
//  DrawerView.h
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
@interface __FWDrawerView : NSObject

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

NS_ASSUME_NONNULL_END
