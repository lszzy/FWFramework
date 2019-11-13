/*!
 @header     UIGestureRecognizer+FWDrawerView.h
 @indexgroup FWFramework
 @brief      UIGestureRecognizer+FWDrawerView
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/11/4
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief 抽屉拖拽效果分类
 */
@interface UIPanGestureRecognizer (FWDrawerView)

/*!
 @brief 二级抽屉拖拽效果(简单版)。如果view为滚动视图，自动设置delegate处理与滚动视图pan手势冲突的问题
 
 @param view 抽屉视图，默认为self.view
 @param direction 拖拽方向，如向上拖动视图时为Up，向下为Down，向右为Right，向左为Left
 @param fromPosition 相对于view父视图的起点originY位置
 @param toPosition 相对于view父视图的终点originY位置
 @param kickbackHeight 回弹高度，拖拽小于该高度执行回弹
 @param callback 抽屉视图位移回调，参数为相对view父视图的origin位置和是否拖拽完成的标记
 */
- (void)fwDrawerView:(nullable UIView *)view
           direction:(UISwipeGestureRecognizerDirection)direction
        fromPosition:(CGFloat)fromPosition
          toPosition:(CGFloat)toPosition
      kickbackHeight:(CGFloat)kickbackHeight
            callback:(nullable void (^)(CGFloat position, BOOL finished))callback;

/*!
 @brief 多级抽屉拖拽效果(详细版)。如果view为滚动视图，自动设置delegate处理与滚动视图pan手势冲突的问题
 
 @param view 抽屉视图，默认为self.view
 @param direction 拖拽方向，如向上拖动视图时为Up，向下为Down，向右为Right，向左为Left
 @param positions 抽屉位置，至少两级，相对于view父视图的originY位置
 @param kickbackHeight 回弹高度，拖拽小于该高度执行回弹
 @param callback 抽屉视图位移回调，参数为相对view父视图的origin位置和是否拖拽完成的标记
 */
- (void)fwDrawerView:(nullable UIView *)view
           direction:(UISwipeGestureRecognizerDirection)direction
           positions:(NSArray<NSNumber *> *)positions
      kickbackHeight:(CGFloat)kickbackHeight
            callback:(nullable void (^)(CGFloat position, BOOL finished))callback;

// 判断二级或多级抽屉效果视图是否位于打开位置
- (BOOL)fwDrawerViewIsOpen;

// 设置二级抽屉效果视图到打开位置或关闭位置，如果位置发生改变，会触发抽屉callback回调
- (void)fwDrawerViewToggleOpen:(BOOL)open;

// 判断多级抽屉效果视图是否位于指定位置
- (BOOL)fwDrawerViewIsPosition:(CGFloat)position;

// 设置多级抽屉效果视图到指定位置，如果位置发生改变，会触发抽屉callback回调
- (void)fwDrawerViewTogglePosition:(CGFloat)position;

@end

/*!
 @brief 视图抽屉拖拽效果分类
 */
@interface UIView (FWDrawerView)

/*!
 @brief 设置二级抽屉拖拽效果。如果view为滚动视图，自动设置delegate处理与滚动视图pan手势冲突的问题
 
 @param direction 拖拽方向，如向上拖动视图时为Up
 @param fromPosition 相对于父视图的起点originY位置
 @param toPosition 相对于父视图的终点originY位置
 @param kickbackHeight 回弹高度，拖拽小于该高度执行回弹
 @param callback 抽屉视图位移回调，参数为相对父视图的origin位置和是否拖拽完成的标记
 @return 自动添加的pan手势对象
 */
- (UIPanGestureRecognizer *)fwDrawerView:(UISwipeGestureRecognizerDirection)direction
                            fromPosition:(CGFloat)fromPosition
                              toPosition:(CGFloat)toPosition
                          kickbackHeight:(CGFloat)kickbackHeight
                                callback:(nullable void (^)(CGFloat position, BOOL finished))callback;

@end

/*!
@brief 滚动视图纵向手势冲突无缝滑动分类，需允许同时识别多个手势
*/
@interface UIScrollView (FWDrawerView)

// 外部滚动视图是否位于顶部固定位置，在顶部时不能滚动
@property (nonatomic, assign) BOOL fwDrawerSuperviewFixed;

// 外部滚动视图scrollViewDidScroll调用，参数为固定的位置
- (void)fwDrawerSuperviewDidScroll:(CGFloat)position;

// 内嵌滚动视图scrollViewDidScroll调用，参数为外部滚动视图
- (void)fwDrawerSubviewDidScroll:(UIScrollView *)superview;

@end

NS_ASSUME_NONNULL_END
