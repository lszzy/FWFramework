/*!
 @header     UIView+FWAutoLayout.h
 @indexgroup FWFramework
 @brief      UIView自动布局分类
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-05-15
 */

#import <UIKit/UIKit.h>

/*!
 @brief UIView自动布局分类，兼容UIView和UILayoutGuide(iOS9)
 */
@interface UIView (FWAutoLayout)

#pragma mark - AutoLayout

/*!
 @brief 创建自动布局视图
 
 @return 自动布局视图
 */
+ (instancetype)fwAutoLayoutView;

/*!
 @brief 设置自动布局开关
 
 @param enabled 是否启用AutoLayout
 */
- (void)fwSetAutoLayout:(BOOL)enabled;

/*!
 @brief 执行子视图自动布局，自动计算子视图尺寸。iOS8需要将视图添加到界面后才能调用
 */
- (void)fwAutoLayoutSubviews;

/*!
 @brief 设置约束保存键名，方便更新约束常量
 
 @param constraint 布局约束
 @param key 保存key
 */
- (void)fwSetConstraint:(NSLayoutConstraint *)constraint forKey:(id<NSCopying>)key;

/*!
 @brief 获取键名对应约束
 
 @param key 保存key
 @return 布局约束
 */
- (NSLayoutConstraint *)fwConstraintForKey:(id<NSCopying>)key;

#pragma mark - Axis

/*!
 @brief 父视图居中
 
 @return 约束数组
 */
- (NSArray<NSLayoutConstraint *> *)fwAlignCenterToSuperview;

/*!
 @brief 父视图属性居中
 
 @param axis 居中属性
 @return 布局约束
 */
- (NSLayoutConstraint *)fwAlignAxisToSuperview:(NSLayoutAttribute)axis;

/*!
 @brief 与另一视图居中相同
 
 @param axis 居中属性
 @param otherView 另一视图或UILayoutGuide，下同
 @return 布局约束
 */
- (NSLayoutConstraint *)fwAlignAxis:(NSLayoutAttribute)axis toView:(id)otherView;

/*!
 @brief 与另一视图居中偏移指定距离
 
 @param axis 居中属性
 @param otherView 另一视图
 @param offset 偏移距离
 @return 布局约束
 */
- (NSLayoutConstraint *)fwAlignAxis:(NSLayoutAttribute)axis toView:(id)otherView withOffset:(CGFloat)offset;

/*!
 @brief 与另一视图居中指定比例
 
 @param axis 居中属性
 @param otherView 另一视图
 @param multiplier 指定比例
 @return 布局约束
 */
- (NSLayoutConstraint *)fwAlignAxis:(NSLayoutAttribute)axis toView:(id)otherView withMultiplier:(CGFloat)multiplier;

#pragma mark - Edge

/*!
 @brief 与父视图四条边属性相同
 
 @return 约束数组
 */
- (NSArray<NSLayoutConstraint *> *)fwPinEdgesToSuperview;

/*!
 @brief 与父视图四条边属性距离指定距离
 
 @param insets 指定距离insets
 @return 约束数组
 */
- (NSArray<NSLayoutConstraint *> *)fwPinEdgesToSuperviewWithInsets:(UIEdgeInsets)insets;

/*!
 @brief 与父视图三条边属性距离指定距离
 
 @param insets 指定距离insets
 @param edge 排除的边
 @return 约束数组
 */
- (NSArray<NSLayoutConstraint *> *)fwPinEdgesToSuperviewWithInsets:(UIEdgeInsets)insets excludingEdge:(NSLayoutAttribute)edge;

/*!
 @brief 与父视图边属性相同
 
 @param edge 指定边属性
 @return 布局约束
 */
- (NSLayoutConstraint *)fwPinEdgeToSuperview:(NSLayoutAttribute)edge;

/*!
 @brief 与父视图边属性偏移指定距离
 
 @param edge 指定边属性
 @param inset 偏移距离
 @return 布局约束
 */
- (NSLayoutConstraint *)fwPinEdgeToSuperview:(NSLayoutAttribute)edge withInset:(CGFloat)inset;

/*!
 @brief 与父视图边属性偏移指定距离，指定关系
 
 @param edge 指定边属性
 @param inset 偏移距离
 @param relation 约束关系
 @return 布局约束
 */
- (NSLayoutConstraint *)fwPinEdgeToSuperview:(NSLayoutAttribute)edge withInset:(CGFloat)inset relation:(NSLayoutRelation)relation;

/*!
 @brief 与指定视图边属性相同
 
 @param edge 指定边属性
 @param toEdge 另一视图边属性
 @param otherView 另一视图
 @return 布局约束
 */
- (NSLayoutConstraint *)fwPinEdge:(NSLayoutAttribute)edge toEdge:(NSLayoutAttribute)toEdge ofView:(id)otherView;

/*!
 @brief 与指定视图边属性偏移指定距离
 
 @param edge 指定边属性
 @param toEdge 另一视图边属性
 @param otherView 另一视图
 @param offset 偏移距离
 @return 布局约束
 */
- (NSLayoutConstraint *)fwPinEdge:(NSLayoutAttribute)edge toEdge:(NSLayoutAttribute)toEdge ofView:(id)otherView withOffset:(CGFloat)offset;

/*!
 @brief 与指定视图边属性偏移指定距离，指定关系
 
 @param edge 指定边属性
 @param toEdge 另一视图边属性
 @param otherView 另一视图
 @param offset 偏移距离
 @param relation 约束关系
 @return 布局约束
 */
- (NSLayoutConstraint *)fwPinEdge:(NSLayoutAttribute)edge toEdge:(NSLayoutAttribute)toEdge ofView:(id)otherView withOffset:(CGFloat)offset relation:(NSLayoutRelation)relation;

#pragma mark - SafeArea

/*!
 @brief 父视图安全区域居中。iOS11以下使用Superview实现，下同
 
 @return 约束数组
 */
- (NSArray<NSLayoutConstraint *> *)fwAlignCenterToSuperviewSafeArea;

/*!
 @brief 父视图安全区域属性居中
 
 @param axis 居中属性
 @return 布局约束
 */
- (NSLayoutConstraint *)fwAlignAxisToSuperviewSafeArea:(NSLayoutAttribute)axis;

/*!
 @brief 与父视图安全区域四条边属性相同
 
 @return 约束数组
 */
- (NSArray<NSLayoutConstraint *> *)fwPinEdgesToSuperviewSafeArea;

/*!
 @brief 与父视图安全区域四条边属性距离指定距离
 
 @param insets 指定距离insets
 @return 约束数组
 */
- (NSArray<NSLayoutConstraint *> *)fwPinEdgesToSuperviewSafeAreaWithInsets:(UIEdgeInsets)insets;

/*!
 @brief 与父视图安全区域三条边属性距离指定距离
 
 @param insets 指定距离insets
 @param edge 排除的边
 @return 约束数组
 */
- (NSArray<NSLayoutConstraint *> *)fwPinEdgesToSuperviewSafeAreaWithInsets:(UIEdgeInsets)insets excludingEdge:(NSLayoutAttribute)edge;

/*!
 @brief 与父视图安全区域边属性相同
 
 @param edge 指定边属性
 @return 布局约束
 */
- (NSLayoutConstraint *)fwPinEdgeToSuperviewSafeArea:(NSLayoutAttribute)edge;

/*!
 @brief 与父视图安全区域边属性偏移指定距离
 
 @param edge 指定边属性
 @param inset 偏移距离
 @return 布局约束
 */
- (NSLayoutConstraint *)fwPinEdgeToSuperviewSafeArea:(NSLayoutAttribute)edge withInset:(CGFloat)inset;

/*!
 @brief 与父视图安全区域边属性偏移指定距离，指定关系
 
 @param edge 指定边属性
 @param inset 偏移距离
 @param relation 约束关系
 @return 布局约束
 */
- (NSLayoutConstraint *)fwPinEdgeToSuperviewSafeArea:(NSLayoutAttribute)edge withInset:(CGFloat)inset relation:(NSLayoutRelation)relation;

#pragma mark - Dimension

/*!
 @brief 与指定视图尺寸属性相同
 
 @param dimension 尺寸属性
 @param toDimension 目标尺寸属性
 @param otherView 目标视图
 @return 布局约束
 */
- (NSLayoutConstraint *)fwMatchDimension:(NSLayoutAttribute)dimension toDimension:(NSLayoutAttribute)toDimension ofView:(id)otherView;

/*!
 @brief 与指定视图尺寸属性相差指定大小
 
 @param dimension 尺寸属性
 @param toDimension 目标尺寸属性
 @param otherView 目标视图
 @param offset 相差大小
 @return 布局约束
 */
- (NSLayoutConstraint *)fwMatchDimension:(NSLayoutAttribute)dimension toDimension:(NSLayoutAttribute)toDimension ofView:(id)otherView withOffset:(CGFloat)offset;

/*!
 @brief 与指定视图尺寸属性相差指定大小，指定关系
 
 @param dimension 尺寸属性
 @param toDimension 目标尺寸属性
 @param otherView 目标视图
 @param offset 相差大小
 @param relation 约束关系
 @return 布局约束
 */
- (NSLayoutConstraint *)fwMatchDimension:(NSLayoutAttribute)dimension toDimension:(NSLayoutAttribute)toDimension ofView:(id)otherView withOffset:(CGFloat)offset relation:(NSLayoutRelation)relation;

/*!
 @brief 与指定视图尺寸属性指定比例
 
 @param dimension 尺寸属性
 @param toDimension 目标尺寸属性
 @param otherView 目标视图
 @param multiplier 指定比例
 @return 布局约束
 */
- (NSLayoutConstraint *)fwMatchDimension:(NSLayoutAttribute)dimension toDimension:(NSLayoutAttribute)toDimension ofView:(id)otherView withMultiplier:(CGFloat)multiplier;

/*!
 @brief 与指定视图尺寸属性指定比例，指定关系
 
 @param dimension 尺寸属性
 @param toDimension 目标尺寸属性
 @param otherView 目标视图
 @param multiplier 指定比例
 @param relation 约束关系
 @return 布局约束
 */
- (NSLayoutConstraint *)fwMatchDimension:(NSLayoutAttribute)dimension toDimension:(NSLayoutAttribute)toDimension ofView:(id)otherView withMultiplier:(CGFloat)multiplier relation:(NSLayoutRelation)relation;

/*!
 @brief 设置宽高尺寸
 
 @param size 尺寸大小
 @return 约束数组
 */
- (NSArray<NSLayoutConstraint *> *)fwSetDimensionsToSize:(CGSize)size;

/*!
 @brief 设置某个尺寸
 
 @param dimension 尺寸属性
 @param size 尺寸大小
 @return 布局约束
 */
- (NSLayoutConstraint *)fwSetDimension:(NSLayoutAttribute)dimension toSize:(CGFloat)size;

/*!
 @brief 设置某个尺寸，指定关系
 
 @param dimension 尺寸属性
 @param size 尺寸大小
 @param relation 约束关系
 @return 布局约束
 */
- (NSLayoutConstraint *)fwSetDimension:(NSLayoutAttribute)dimension toSize:(CGFloat)size relation:(NSLayoutRelation)relation;

#pragma mark - Constrain

/*!
 @brief 与指定视图属性相同
 
 @param attribute 指定属性
 @param toAttribute 目标视图属性
 @param otherView 目标视图
 @return 布局约束
 */
- (NSLayoutConstraint *)fwConstrainAttribute:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(id)otherView;

/*!
 @brief 与指定视图属性偏移指定距离
 
 @param attribute 指定属性
 @param toAttribute 目标视图属性
 @param otherView 目标视图
 @param offset 偏移距离
 @return 布局约束
 */
- (NSLayoutConstraint *)fwConstrainAttribute:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(id)otherView withOffset:(CGFloat)offset;

/*!
 @brief 与指定视图属性偏移指定距离，指定关系
 
 @param attribute 指定属性
 @param toAttribute 目标视图属性
 @param otherView 目标视图
 @param offset 偏移距离
 @param relation 约束关系
 @return 布局约束
 */
- (NSLayoutConstraint *)fwConstrainAttribute:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(id)otherView withOffset:(CGFloat)offset relation:(NSLayoutRelation)relation;

/*!
 @brief 与指定视图属性指定比例
 
 @param attribute 指定属性
 @param toAttribute 目标视图属性
 @param otherView 目标视图
 @param multiplier 指定比例
 @return 布局约束
 */
- (NSLayoutConstraint *)fwConstrainAttribute:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(id)otherView withMultiplier:(CGFloat)multiplier;

/*!
 @brief 与指定视图属性指定比例，指定关系
 
 @param attribute 指定属性
 @param toAttribute 目标视图属性
 @param otherView 目标视图
 @param multiplier 指定比例
 @param relation 约束关系
 @return 布局约束
 */
- (NSLayoutConstraint *)fwConstrainAttribute:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(id)otherView withMultiplier:(CGFloat)multiplier relation:(NSLayoutRelation)relation;

@end
