/*!
 @header     UIView+FWAutoLayout.h
 @indexgroup FWFramework
 @brief      UIView自动布局分类
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-05-15
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief UIView自动布局分类，兼容UIView和UILayoutGuide(iOS9)
 @discussion 如果约束条件完全相同，会自动更新约束而不是重新添加
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
 @brief 执行子视图自动布局，自动计算子视图尺寸。需先将视图添加到界面(如设置为tableHeaderView)，再调用即可(iOS8+)
 */
- (void)fwAutoLayoutSubviews;

/*!
 @brief 是否启用自动布局RTL，启用后自动将Left|Right转换为Leading|Trailing，默认NO
 @discussion 如果项目兼容阿拉伯语等，需要启用RTL从右向左布局，开启此开关即可，无需修改布局代码
 手工切换视图左右布局方法：[UIView appearance].semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
 
 @param enabled 是否启用自动布局RTL
 */
+ (void)fwAutoLayoutRTL:(BOOL)enabled;

#pragma mark - Compression

/*!
 @brief 设置水平方向抗压缩优先级
 
 @param priority 布局优先级
 */
- (void)fwSetCompressionHorizontal:(UILayoutPriority)priority;

/*!
 @brief 设置垂直方向抗压缩优先级
 
 @param priority 布局优先级
 */
- (void)fwSetCompressionVertical:(UILayoutPriority)priority;

#pragma mark - Axis

/*!
 @brief 父视图居中
 
 @return 约束数组
 */
- (NSArray<NSLayoutConstraint *> *)fwAlignCenterToSuperview;

/*!
 @brief 父视图居中偏移指定距离
 
 @param offset 偏移距离
 @return 约束数组
 */
- (NSArray<NSLayoutConstraint *> *)fwAlignCenterToSuperviewWithOffset:(CGPoint)offset;

/*!
 @brief 父视图属性居中
 
 @param axis 居中属性
 @return 布局约束
 */
- (NSLayoutConstraint *)fwAlignAxisToSuperview:(NSLayoutAttribute)axis;

/*!
 @brief 父视图属性居中偏移指定距离
 
 @param axis 居中属性
 @param offset 偏移距离
 @return 布局约束
 */
- (NSLayoutConstraint *)fwAlignAxisToSuperview:(NSLayoutAttribute)axis withOffset:(CGFloat)offset;

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
 @brief 与父视图水平方向两条边属性相同
 
 @return 约束数组
 */
- (NSArray<NSLayoutConstraint *> *)fwPinEdgesToSuperviewHorizontal;

/*!
 @brief 与父视图垂直方向两条边属性相同
 
 @return 约束数组
 */
- (NSArray<NSLayoutConstraint *> *)fwPinEdgesToSuperviewVertical;

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
 @brief 父视图安全区域居中偏移指定距离。iOS11以下使用Superview实现，下同
 
 @param offset 偏移距离
 @return 约束数组
 */
- (NSArray<NSLayoutConstraint *> *)fwAlignCenterToSuperviewSafeAreaWithOffset:(CGPoint)offset;

/*!
 @brief 父视图安全区域属性居中
 
 @param axis 居中属性
 @return 布局约束
 */
- (NSLayoutConstraint *)fwAlignAxisToSuperviewSafeArea:(NSLayoutAttribute)axis;

/*!
 @brief 父视图安全区域属性居中偏移指定距离
 
 @param axis 居中属性
 @param offset 偏移距离
 @return 布局约束
 */
- (NSLayoutConstraint *)fwAlignAxisToSuperviewSafeArea:(NSLayoutAttribute)axis withOffset:(CGFloat)offset;

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
 @brief 与父视图安全区域水平方向两条边属性相同
 
 @return 约束数组
 */
- (NSArray<NSLayoutConstraint *> *)fwPinEdgesToSuperviewSafeAreaHorizontal;

/*!
 @brief 与父视图安全区域垂直方向两条边属性相同
 
 @return 约束数组
 */
- (NSArray<NSLayoutConstraint *> *)fwPinEdgesToSuperviewSafeAreaVertical;

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
- (NSLayoutConstraint *)fwConstrainAttribute:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(nullable id)otherView;

/*!
 @brief 与指定视图属性偏移指定距离
 
 @param attribute 指定属性
 @param toAttribute 目标视图属性
 @param otherView 目标视图
 @param offset 偏移距离
 @return 布局约束
 */
- (NSLayoutConstraint *)fwConstrainAttribute:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(nullable id)otherView withOffset:(CGFloat)offset;

/*!
 @brief 与指定视图属性偏移指定距离，指定关系
 
 @param attribute 指定属性
 @param toAttribute 目标视图属性
 @param otherView 目标视图
 @param offset 偏移距离
 @param relation 约束关系
 @return 布局约束
 */
- (NSLayoutConstraint *)fwConstrainAttribute:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(nullable id)otherView withOffset:(CGFloat)offset relation:(NSLayoutRelation)relation;

/*!
 @brief 与指定视图属性指定比例
 
 @param attribute 指定属性
 @param toAttribute 目标视图属性
 @param otherView 目标视图
 @param multiplier 指定比例
 @return 布局约束
 */
- (NSLayoutConstraint *)fwConstrainAttribute:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(nullable id)otherView withMultiplier:(CGFloat)multiplier;

/*!
 @brief 与指定视图属性指定比例，指定关系
 
 @param attribute 指定属性
 @param toAttribute 目标视图属性
 @param otherView 目标视图
 @param multiplier 指定比例
 @param relation 约束关系
 @return 布局约束
 */
- (NSLayoutConstraint *)fwConstrainAttribute:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(nullable id)otherView withMultiplier:(CGFloat)multiplier relation:(NSLayoutRelation)relation;

#pragma mark - Key

/*!
 @brief 设置约束保存键名，方便更新约束常量
 
 @param constraint 布局约束
 @param key 保存key
 */
- (void)fwSetConstraint:(nullable NSLayoutConstraint *)constraint forKey:(id<NSCopying>)key;

/*!
 @brief 获取键名对应约束
 
 @param key 保存key
 @return 布局约束
 */
- (nullable NSLayoutConstraint *)fwConstraintForKey:(id<NSCopying>)key;

#pragma mark - All

/*!
 @brief 获取当前所有约束，不包含Key
 
 @return 约束列表
 */
- (NSArray<NSLayoutConstraint *> *)fwAllConstraints;

/*!
 @brief 移除当前指定约束，不包含Key
 */
- (void)fwRemoveConstraint:(NSLayoutConstraint *)constraint;

/*!
 @brief 移除当前所有约束，不包含Key
 */
- (void)fwRemoveAllConstraints;

@end

NS_ASSUME_NONNULL_END
