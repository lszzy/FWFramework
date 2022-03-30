/**
 @header     FWAutoLayout.h
 @indexgroup FWFramework
      UIView自动布局
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/6/22
 */

#import <UIKit/UIKit.h>
#import "FWWrapper.h"

NS_ASSUME_NONNULL_BEGIN

/**
 UIView自动布局分类，兼容UIView和UILayoutGuide(iOS9)
 @note 如果约束条件完全相同，会自动更新约束而不是重新添加。
 另外，默认布局方式使用LTR，如果需要RTL布局，可通过fwAutoLayoutRTL统一启用
 */
@interface UIView (FWAutoLayout)

#pragma mark - AutoLayout

/**
 是否启用自动布局适配RTL，启用后自动将Left|Right转换为Leading|Trailing，默认NO
 @note 如果项目兼容阿拉伯语等，需要启用RTL从右向左布局，开启此开关即可，无需修改布局代码
 手工切换视图左右布局方法：[UIView appearance].semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
 */
@property (class, nonatomic, assign) BOOL fwAutoLayoutRTL;

/**
 是否启用自动布局
 */
@property (nonatomic, assign) BOOL fwAutoLayout;

/**
 创建自动布局视图
 
 @return 自动布局视图
 */
+ (instancetype)fwAutoLayoutView;

/**
 执行子视图自动布局，自动计算子视图尺寸。需先将视图添加到界面(如设置为tableHeaderView)，再调用即可(iOS8+)
 */
- (void)fwAutoLayoutSubviews;

/**
 计算动态布局视图指定宽度时的高度。使用AutoLayout必须约束完整，不使用AutoLayout会调用view的sizeThatFits:方法
 */
- (CGFloat)fwLayoutHeightWithWidth:(CGFloat)width;

/**
 计算动态布局视图指定高度时的宽度。使用AutoLayout必须约束完整，不使用AutoLayout会调用view的sizeThatFits:方法
 */
- (CGFloat)fwLayoutWidthWithHeight:(CGFloat)height;

#pragma mark - Compression

/**
 设置水平方向抗压缩优先级
 */
@property (nonatomic, assign) UILayoutPriority fwCompressionHorizontal;

/**
 设置垂直方向抗压缩优先级
 */
@property (nonatomic, assign) UILayoutPriority fwCompressionVertical;

/**
 设置水平方向抗拉伸优先级
 */
@property (nonatomic, assign) UILayoutPriority fwHuggingHorizontal;

/**
 设置垂直方向抗拉伸优先级
 */
@property (nonatomic, assign) UILayoutPriority fwHuggingVertical;

#pragma mark - Collapse

/**
 设置视图是否收缩，默认NO，YES时常量值为0，NO时常量值为原始值
 */
@property (nonatomic, assign) BOOL fwCollapsed;

/**
 设置视图是否自动收缩，如image为nil，text为nil、@""时自动收缩，默认NO
 */
@property (nonatomic, assign) BOOL fwAutoCollapse;

/**
 设置视图是否隐藏时自动收缩、显示时自动展开，默认NO
 */
@property (nonatomic, assign) BOOL fwHiddenCollapse;

/**
 添加视图的收缩常量，必须先添加才能生效
 
 @see https://github.com/forkingdog/UIView-FDCollapsibleConstraints
 */
- (void)fwAddCollapseConstraint:(NSLayoutConstraint *)constraint;

#pragma mark - Axis

/**
 父视图居中
 
 @return 约束数组
 */
- (NSArray<NSLayoutConstraint *> *)fwAlignCenterToSuperview;

/**
 父视图居中偏移指定距离
 
 @param offset 偏移距离
 @return 约束数组
 */
- (NSArray<NSLayoutConstraint *> *)fwAlignCenterToSuperviewWithOffset:(CGPoint)offset;

/**
 父视图属性居中
 
 @param axis 居中属性
 @return 布局约束
 */
- (NSLayoutConstraint *)fwAlignAxisToSuperview:(NSLayoutAttribute)axis;

/**
 父视图属性居中偏移指定距离
 
 @param axis 居中属性
 @param offset 偏移距离
 @return 布局约束
 */
- (NSLayoutConstraint *)fwAlignAxisToSuperview:(NSLayoutAttribute)axis withOffset:(CGFloat)offset;

/**
 与另一视图居中相同
 
 @param axis 居中属性
 @param otherView 另一视图或UILayoutGuide，下同
 @return 布局约束
 */
- (NSLayoutConstraint *)fwAlignAxis:(NSLayoutAttribute)axis toView:(id)otherView;

/**
 与另一视图居中偏移指定距离
 
 @param axis 居中属性
 @param otherView 另一视图
 @param offset 偏移距离
 @return 布局约束
 */
- (NSLayoutConstraint *)fwAlignAxis:(NSLayoutAttribute)axis toView:(id)otherView withOffset:(CGFloat)offset;

/**
 与另一视图居中指定比例
 
 @param axis 居中属性
 @param otherView 另一视图
 @param multiplier 指定比例
 @return 布局约束
 */
- (NSLayoutConstraint *)fwAlignAxis:(NSLayoutAttribute)axis toView:(id)otherView withMultiplier:(CGFloat)multiplier;

#pragma mark - Edge

/**
 与父视图四条边属性相同
 
 @return 约束数组
 */
- (NSArray<NSLayoutConstraint *> *)fwPinEdgesToSuperview;

/**
 与父视图四条边属性距离指定距离
 
 @param insets 指定距离insets
 @return 约束数组
 */
- (NSArray<NSLayoutConstraint *> *)fwPinEdgesToSuperviewWithInsets:(UIEdgeInsets)insets;

/**
 与父视图三条边属性距离指定距离
 
 @param insets 指定距离insets
 @param edge 排除的边
 @return 约束数组
 */
- (NSArray<NSLayoutConstraint *> *)fwPinEdgesToSuperviewWithInsets:(UIEdgeInsets)insets excludingEdge:(NSLayoutAttribute)edge;

/**
 与父视图水平方向两条边属性相同
 
 @return 约束数组
 */
- (NSArray<NSLayoutConstraint *> *)fwPinEdgesToSuperviewHorizontal;

/**
 与父视图垂直方向两条边属性相同
 
 @return 约束数组
 */
- (NSArray<NSLayoutConstraint *> *)fwPinEdgesToSuperviewVertical;

/**
 与父视图边属性相同
 
 @param edge 指定边属性
 @return 布局约束
 */
- (NSLayoutConstraint *)fwPinEdgeToSuperview:(NSLayoutAttribute)edge;

/**
 与父视图边属性偏移指定距离
 
 @param edge 指定边属性
 @param inset 偏移距离
 @return 布局约束
 */
- (NSLayoutConstraint *)fwPinEdgeToSuperview:(NSLayoutAttribute)edge withInset:(CGFloat)inset;

/**
 与父视图边属性偏移指定距离，指定关系
 
 @param edge 指定边属性
 @param inset 偏移距离
 @param relation 约束关系
 @return 布局约束
 */
- (NSLayoutConstraint *)fwPinEdgeToSuperview:(NSLayoutAttribute)edge withInset:(CGFloat)inset relation:(NSLayoutRelation)relation;

/**
 与指定视图边属性相同
 
 @param edge 指定边属性
 @param toEdge 另一视图边属性
 @param otherView 另一视图
 @return 布局约束
 */
- (NSLayoutConstraint *)fwPinEdge:(NSLayoutAttribute)edge toEdge:(NSLayoutAttribute)toEdge ofView:(id)otherView;

/**
 与指定视图边属性偏移指定距离
 
 @param edge 指定边属性
 @param toEdge 另一视图边属性
 @param otherView 另一视图
 @param offset 偏移距离
 @return 布局约束
 */
- (NSLayoutConstraint *)fwPinEdge:(NSLayoutAttribute)edge toEdge:(NSLayoutAttribute)toEdge ofView:(id)otherView withOffset:(CGFloat)offset;

/**
 与指定视图边属性偏移指定距离，指定关系
 
 @param edge 指定边属性
 @param toEdge 另一视图边属性
 @param otherView 另一视图
 @param offset 偏移距离
 @param relation 约束关系
 @return 布局约束
 */
- (NSLayoutConstraint *)fwPinEdge:(NSLayoutAttribute)edge toEdge:(NSLayoutAttribute)toEdge ofView:(id)otherView withOffset:(CGFloat)offset relation:(NSLayoutRelation)relation;

#pragma mark - SafeArea

/**
 父视图安全区域居中。iOS11以下使用Superview实现，下同
 
 @return 约束数组
 */
- (NSArray<NSLayoutConstraint *> *)fwAlignCenterToSuperviewSafeArea;

/**
 父视图安全区域居中偏移指定距离。iOS11以下使用Superview实现，下同
 
 @param offset 偏移距离
 @return 约束数组
 */
- (NSArray<NSLayoutConstraint *> *)fwAlignCenterToSuperviewSafeAreaWithOffset:(CGPoint)offset;

/**
 父视图安全区域属性居中
 
 @param axis 居中属性
 @return 布局约束
 */
- (NSLayoutConstraint *)fwAlignAxisToSuperviewSafeArea:(NSLayoutAttribute)axis;

/**
 父视图安全区域属性居中偏移指定距离
 
 @param axis 居中属性
 @param offset 偏移距离
 @return 布局约束
 */
- (NSLayoutConstraint *)fwAlignAxisToSuperviewSafeArea:(NSLayoutAttribute)axis withOffset:(CGFloat)offset;

/**
 与父视图安全区域四条边属性相同
 
 @return 约束数组
 */
- (NSArray<NSLayoutConstraint *> *)fwPinEdgesToSuperviewSafeArea;

/**
 与父视图安全区域四条边属性距离指定距离
 
 @param insets 指定距离insets
 @return 约束数组
 */
- (NSArray<NSLayoutConstraint *> *)fwPinEdgesToSuperviewSafeAreaWithInsets:(UIEdgeInsets)insets;

/**
 与父视图安全区域三条边属性距离指定距离
 
 @param insets 指定距离insets
 @param edge 排除的边
 @return 约束数组
 */
- (NSArray<NSLayoutConstraint *> *)fwPinEdgesToSuperviewSafeAreaWithInsets:(UIEdgeInsets)insets excludingEdge:(NSLayoutAttribute)edge;

/**
 与父视图安全区域水平方向两条边属性相同
 
 @return 约束数组
 */
- (NSArray<NSLayoutConstraint *> *)fwPinEdgesToSuperviewSafeAreaHorizontal;

/**
 与父视图安全区域垂直方向两条边属性相同
 
 @return 约束数组
 */
- (NSArray<NSLayoutConstraint *> *)fwPinEdgesToSuperviewSafeAreaVertical;

/**
 与父视图安全区域边属性相同
 
 @param edge 指定边属性
 @return 布局约束
 */
- (NSLayoutConstraint *)fwPinEdgeToSuperviewSafeArea:(NSLayoutAttribute)edge;

/**
 与父视图安全区域边属性偏移指定距离
 
 @param edge 指定边属性
 @param inset 偏移距离
 @return 布局约束
 */
- (NSLayoutConstraint *)fwPinEdgeToSuperviewSafeArea:(NSLayoutAttribute)edge withInset:(CGFloat)inset;

/**
 与父视图安全区域边属性偏移指定距离，指定关系
 
 @param edge 指定边属性
 @param inset 偏移距离
 @param relation 约束关系
 @return 布局约束
 */
- (NSLayoutConstraint *)fwPinEdgeToSuperviewSafeArea:(NSLayoutAttribute)edge withInset:(CGFloat)inset relation:(NSLayoutRelation)relation;

#pragma mark - Dimension

/**
 设置宽高尺寸
 
 @param size 尺寸大小
 @return 约束数组
 */
- (NSArray<NSLayoutConstraint *> *)fwSetDimensionsToSize:(CGSize)size;

/**
 设置某个尺寸
 
 @param dimension 尺寸属性
 @param size 尺寸大小
 @return 布局约束
 */
- (NSLayoutConstraint *)fwSetDimension:(NSLayoutAttribute)dimension toSize:(CGFloat)size;

/**
 设置某个尺寸，指定关系
 
 @param dimension 尺寸属性
 @param size 尺寸大小
 @param relation 约束关系
 @return 布局约束
 */
- (NSLayoutConstraint *)fwSetDimension:(NSLayoutAttribute)dimension toSize:(CGFloat)size relation:(NSLayoutRelation)relation;

/**
 与视图自身尺寸属性指定比例
 
 @param dimension 尺寸属性
 @param toDimension 目标尺寸属性
 @param multiplier 指定比例
 @return 布局约束
 */
- (NSLayoutConstraint *)fwMatchDimension:(NSLayoutAttribute)dimension toDimension:(NSLayoutAttribute)toDimension withMultiplier:(CGFloat)multiplier;

/**
 与视图自身尺寸属性指定比例，指定关系
 
 @param dimension 尺寸属性
 @param toDimension 目标尺寸属性
 @param multiplier 指定比例
 @param relation 约束关系
 @return 布局约束
 */
- (NSLayoutConstraint *)fwMatchDimension:(NSLayoutAttribute)dimension toDimension:(NSLayoutAttribute)toDimension withMultiplier:(CGFloat)multiplier relation:(NSLayoutRelation)relation;

/**
 与指定视图尺寸属性相同
 
 @param dimension 尺寸属性
 @param toDimension 目标尺寸属性
 @param otherView 目标视图
 @return 布局约束
 */
- (NSLayoutConstraint *)fwMatchDimension:(NSLayoutAttribute)dimension toDimension:(NSLayoutAttribute)toDimension ofView:(id)otherView;

/**
 与指定视图尺寸属性相差指定大小
 
 @param dimension 尺寸属性
 @param toDimension 目标尺寸属性
 @param otherView 目标视图
 @param offset 相差大小
 @return 布局约束
 */
- (NSLayoutConstraint *)fwMatchDimension:(NSLayoutAttribute)dimension toDimension:(NSLayoutAttribute)toDimension ofView:(id)otherView withOffset:(CGFloat)offset;

/**
 与指定视图尺寸属性相差指定大小，指定关系
 
 @param dimension 尺寸属性
 @param toDimension 目标尺寸属性
 @param otherView 目标视图
 @param offset 相差大小
 @param relation 约束关系
 @return 布局约束
 */
- (NSLayoutConstraint *)fwMatchDimension:(NSLayoutAttribute)dimension toDimension:(NSLayoutAttribute)toDimension ofView:(id)otherView withOffset:(CGFloat)offset relation:(NSLayoutRelation)relation;

/**
 与指定视图尺寸属性指定比例
 
 @param dimension 尺寸属性
 @param toDimension 目标尺寸属性
 @param otherView 目标视图
 @param multiplier 指定比例
 @return 布局约束
 */
- (NSLayoutConstraint *)fwMatchDimension:(NSLayoutAttribute)dimension toDimension:(NSLayoutAttribute)toDimension ofView:(id)otherView withMultiplier:(CGFloat)multiplier;

/**
 与指定视图尺寸属性指定比例，指定关系
 
 @param dimension 尺寸属性
 @param toDimension 目标尺寸属性
 @param otherView 目标视图
 @param multiplier 指定比例
 @param relation 约束关系
 @return 布局约束
 */
- (NSLayoutConstraint *)fwMatchDimension:(NSLayoutAttribute)dimension toDimension:(NSLayoutAttribute)toDimension ofView:(id)otherView withMultiplier:(CGFloat)multiplier relation:(NSLayoutRelation)relation;

#pragma mark - Constrain

/**
 与指定视图属性相同
 
 @param attribute 指定属性
 @param toAttribute 目标视图属性
 @param otherView 目标视图
 @return 布局约束
 */
- (NSLayoutConstraint *)fwConstrainAttribute:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(nullable id)otherView;

/**
 与指定视图属性偏移指定距离
 
 @param attribute 指定属性
 @param toAttribute 目标视图属性
 @param otherView 目标视图
 @param offset 偏移距离
 @return 布局约束
 */
- (NSLayoutConstraint *)fwConstrainAttribute:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(nullable id)otherView withOffset:(CGFloat)offset;

/**
 与指定视图属性偏移指定距离，指定关系
 
 @param attribute 指定属性
 @param toAttribute 目标视图属性
 @param otherView 目标视图
 @param offset 偏移距离
 @param relation 约束关系
 @return 布局约束
 */
- (NSLayoutConstraint *)fwConstrainAttribute:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(nullable id)otherView withOffset:(CGFloat)offset relation:(NSLayoutRelation)relation;

/**
 与指定视图属性指定比例
 
 @param attribute 指定属性
 @param toAttribute 目标视图属性
 @param otherView 目标视图
 @param multiplier 指定比例
 @return 布局约束
 */
- (NSLayoutConstraint *)fwConstrainAttribute:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(nullable id)otherView withMultiplier:(CGFloat)multiplier;

/**
 与指定视图属性指定比例，指定关系
 
 @param attribute 指定属性
 @param toAttribute 目标视图属性
 @param otherView 目标视图
 @param multiplier 指定比例
 @param relation 约束关系
 @return 布局约束
 */
- (NSLayoutConstraint *)fwConstrainAttribute:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(nullable id)otherView withMultiplier:(CGFloat)multiplier relation:(NSLayoutRelation)relation;

#pragma mark - Constraint

/**
 最近一条添加或更新的布局约束
 */
@property (nullable, nonatomic, readonly) NSLayoutConstraint *fwLastConstraint;

/**
 获取添加的与父视图属性的约束
 
 @param attribute 指定属性
 @return 布局约束
 */
- (nullable NSLayoutConstraint *)fwConstraintToSuperview:(NSLayoutAttribute)attribute;

/**
 获取添加的与父视图属性的约束，指定关系
 
 @param attribute 指定属性
 @param relation 约束关系
 @return 布局约束
 */
- (nullable NSLayoutConstraint *)fwConstraintToSuperview:(NSLayoutAttribute)attribute relation:(NSLayoutRelation)relation;

/**
 获取添加的与父视图安全区域属性的约束
 
 @param attribute 指定属性
 @return 布局约束
 */
- (nullable NSLayoutConstraint *)fwConstraintToSuperviewSafeArea:(NSLayoutAttribute)attribute;

/**
 获取添加的与父视图安全区域属性的约束，指定关系
 
 @param attribute 指定属性
 @param relation 约束关系
 @return 布局约束
 */
- (nullable NSLayoutConstraint *)fwConstraintToSuperviewSafeArea:(NSLayoutAttribute)attribute relation:(NSLayoutRelation)relation;

/**
 获取添加的与指定视图属性的约束
 
 @param attribute 指定属性
 @param toAttribute 目标视图属性
 @param otherView 目标视图
 @return 布局约束
 */
- (nullable NSLayoutConstraint *)fwConstraint:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(nullable id)otherView;

/**
 获取添加的与指定视图属性的约束，指定关系
 
 @param attribute 指定属性
 @param toAttribute 目标视图属性
 @param otherView 目标视图
 @param relation 约束关系
 @return 布局约束
 */
- (nullable NSLayoutConstraint *)fwConstraint:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(nullable id)otherView relation:(NSLayoutRelation)relation;

/**
 获取添加的与指定视图属性指定比例的约束
 
 @param attribute 指定属性
 @param toAttribute 目标视图属性
 @param otherView 目标视图
 @param multiplier 指定比例
 @return 布局约束
 */
- (nullable NSLayoutConstraint *)fwConstraint:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(nullable id)otherView withMultiplier:(CGFloat)multiplier;

/**
 获取添加的与指定视图属性指定比例的约束，指定关系
 
 @param attribute 指定属性
 @param toAttribute 目标视图属性
 @param otherView 目标视图
 @param multiplier 指定比例
 @param relation 约束关系
 @return 布局约束
 */
- (nullable NSLayoutConstraint *)fwConstraint:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(nullable id)otherView withMultiplier:(CGFloat)multiplier relation:(NSLayoutRelation)relation;

#pragma mark - Key

/**
 设置约束保存键名，方便更新约束常量
 
 @param constraint 布局约束
 @param key 保存key
 */
- (void)fwSetConstraint:(nullable NSLayoutConstraint *)constraint forKey:(id<NSCopying>)key;

/**
 获取键名对应约束
 
 @param key 保存key
 @return 布局约束
 */
- (nullable NSLayoutConstraint *)fwConstraintForKey:(id<NSCopying>)key;

#pragma mark - All

/**
 获取当前所有约束，不包含Key
 
 @return 约束列表
 */
@property (nonatomic, copy, readonly) NSArray<NSLayoutConstraint *> *fwAllConstraints;

/**
 移除当前指定约束，不包含Key
 */
- (void)fwRemoveConstraint:(NSLayoutConstraint *)constraint;

/**
 移除当前所有约束，不包含Key
 */
- (void)fwRemoveAllConstraints;

@end

#pragma mark - FWLayoutChain

/**
 视图链式布局类
 @note 如果约束条件完全相同，会自动更新约束而不是重新添加。
 另外，默认布局方式使用LTR，如果需要RTL布局，可通过fwAutoLayoutRTL统一启用
 */
NS_SWIFT_UNAVAILABLE("")
@interface FWLayoutChain : NSObject

@property (nonatomic, weak, nullable, readonly) UIView *view;

- (instancetype)initWithView:(UIView *)view;

#pragma mark - Install

@property (nonatomic, copy, readonly) FWLayoutChain * (^remake)(void);

#pragma mark - Compression

@property (nonatomic, copy, readonly) FWLayoutChain * (^compressionHorizontal)(UILayoutPriority priority);
@property (nonatomic, copy, readonly) FWLayoutChain * (^compressionVertical)(UILayoutPriority priority);
@property (nonatomic, copy, readonly) FWLayoutChain * (^huggingHorizontal)(UILayoutPriority priority);
@property (nonatomic, copy, readonly) FWLayoutChain * (^huggingVertical)(UILayoutPriority priority);

#pragma mark - Collapse

@property (nonatomic, copy, readonly) FWLayoutChain * (^collapsed)(BOOL collapsed);
@property (nonatomic, copy, readonly) FWLayoutChain * (^autoCollapse)(BOOL autoCollapse);
@property (nonatomic, copy, readonly) FWLayoutChain * (^hiddenCollapse)(BOOL hiddenCollapse);

#pragma mark - Axis

@property (nonatomic, copy, readonly) FWLayoutChain * (^center)(void);
@property (nonatomic, copy, readonly) FWLayoutChain * (^centerX)(void);
@property (nonatomic, copy, readonly) FWLayoutChain * (^centerY)(void);
@property (nonatomic, copy, readonly) FWLayoutChain * (^centerWithOffset)(CGPoint offset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^centerXWithOffset)(CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^centerYWithOffset)(CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^centerToView)(id view);
@property (nonatomic, copy, readonly) FWLayoutChain * (^centerXToView)(id view);
@property (nonatomic, copy, readonly) FWLayoutChain * (^centerYToView)(id view);
@property (nonatomic, copy, readonly) FWLayoutChain * (^centerXToViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^centerYToViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^centerXToViewWithMultiplier)(id view, CGFloat multiplier);
@property (nonatomic, copy, readonly) FWLayoutChain * (^centerYToViewWithMultiplier)(id view, CGFloat multiplier);

#pragma mark - Edge

@property (nonatomic, copy, readonly) FWLayoutChain * (^edges)(void);
@property (nonatomic, copy, readonly) FWLayoutChain * (^edgesWithInsets)(UIEdgeInsets insets);
@property (nonatomic, copy, readonly) FWLayoutChain * (^edgesWithInsetsExcludingEdge)(UIEdgeInsets insets, NSLayoutAttribute edge);
@property (nonatomic, copy, readonly) FWLayoutChain * (^edgesHorizontal)(void);
@property (nonatomic, copy, readonly) FWLayoutChain * (^edgesVertical)(void);
@property (nonatomic, copy, readonly) FWLayoutChain * (^top)(void);
@property (nonatomic, copy, readonly) FWLayoutChain * (^bottom)(void);
@property (nonatomic, copy, readonly) FWLayoutChain * (^left)(void);
@property (nonatomic, copy, readonly) FWLayoutChain * (^right)(void);
@property (nonatomic, copy, readonly) FWLayoutChain * (^topWithInset)(CGFloat inset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^bottomWithInset)(CGFloat inset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^leftWithInset)(CGFloat inset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^rightWithInset)(CGFloat inset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^topToView)(id view);
@property (nonatomic, copy, readonly) FWLayoutChain * (^bottomToView)(id view);
@property (nonatomic, copy, readonly) FWLayoutChain * (^leftToView)(id view);
@property (nonatomic, copy, readonly) FWLayoutChain * (^rightToView)(id view);
@property (nonatomic, copy, readonly) FWLayoutChain * (^topToBottomOfView)(id view);
@property (nonatomic, copy, readonly) FWLayoutChain * (^bottomToTopOfView)(id view);
@property (nonatomic, copy, readonly) FWLayoutChain * (^leftToRightOfView)(id view);
@property (nonatomic, copy, readonly) FWLayoutChain * (^rightToLeftOfView)(id view);
@property (nonatomic, copy, readonly) FWLayoutChain * (^topToViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^bottomToViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^leftToViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^rightToViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^topToBottomOfViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^bottomToTopOfViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^leftToRightOfViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^rightToLeftOfViewWithOffset)(id view, CGFloat offset);

#pragma mark - SafeArea

@property (nonatomic, copy, readonly) FWLayoutChain * (^centerToSafeArea)(void);
@property (nonatomic, copy, readonly) FWLayoutChain * (^centerXToSafeArea)(void);
@property (nonatomic, copy, readonly) FWLayoutChain * (^centerYToSafeArea)(void);
@property (nonatomic, copy, readonly) FWLayoutChain * (^centerToSafeAreaWithOffset)(CGPoint offset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^centerXToSafeAreaWithOffset)(CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^centerYToSafeAreaWithOffset)(CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^edgesToSafeArea)(void);
@property (nonatomic, copy, readonly) FWLayoutChain * (^edgesToSafeAreaWithInsets)(UIEdgeInsets insets);
@property (nonatomic, copy, readonly) FWLayoutChain * (^edgesToSafeAreaWithInsetsExcludingEdge)(UIEdgeInsets insets, NSLayoutAttribute edge);
@property (nonatomic, copy, readonly) FWLayoutChain * (^edgesToSafeAreaHorizontal)(void);
@property (nonatomic, copy, readonly) FWLayoutChain * (^edgesToSafeAreaVertical)(void);
@property (nonatomic, copy, readonly) FWLayoutChain * (^topToSafeArea)(void);
@property (nonatomic, copy, readonly) FWLayoutChain * (^bottomToSafeArea)(void);
@property (nonatomic, copy, readonly) FWLayoutChain * (^leftToSafeArea)(void);
@property (nonatomic, copy, readonly) FWLayoutChain * (^rightToSafeArea)(void);
@property (nonatomic, copy, readonly) FWLayoutChain * (^topToSafeAreaWithInset)(CGFloat inset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^bottomToSafeAreaWithInset)(CGFloat inset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^leftToSafeAreaWithInset)(CGFloat inset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^rightToSafeAreaWithInset)(CGFloat inset);

#pragma mark - Dimension

@property (nonatomic, copy, readonly) FWLayoutChain * (^size)(CGSize size);
@property (nonatomic, copy, readonly) FWLayoutChain * (^width)(CGFloat width);
@property (nonatomic, copy, readonly) FWLayoutChain * (^height)(CGFloat height);
@property (nonatomic, copy, readonly) FWLayoutChain * (^widthToHeight)(CGFloat multiplier);
@property (nonatomic, copy, readonly) FWLayoutChain * (^heightToWidth)(CGFloat multiplier);
@property (nonatomic, copy, readonly) FWLayoutChain * (^sizeToView)(id view);
@property (nonatomic, copy, readonly) FWLayoutChain * (^widthToView)(id view);
@property (nonatomic, copy, readonly) FWLayoutChain * (^heightToView)(id view);
@property (nonatomic, copy, readonly) FWLayoutChain * (^widthToViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^heightToViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^widthToViewWithMultiplier)(id view, CGFloat multiplier);
@property (nonatomic, copy, readonly) FWLayoutChain * (^heightToViewWithMultiplier)(id view, CGFloat multiplier);

#pragma mark - Attribute

@property (nonatomic, copy, readonly) FWLayoutChain * (^attribute)(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id _Nullable ofView);
@property (nonatomic, copy, readonly) FWLayoutChain * (^attributeWithOffset)(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id _Nullable ofView, CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^attributeWithOffsetAndRelation)(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id _Nullable ofView, CGFloat offset, NSLayoutRelation relation);
@property (nonatomic, copy, readonly) FWLayoutChain * (^attributeWithMultiplier)(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id _Nullable ofView, CGFloat multiplier);
@property (nonatomic, copy, readonly) FWLayoutChain * (^attributeWithMultiplierAndRelation)(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id _Nullable ofView, CGFloat multiplier, NSLayoutRelation relation);

#pragma mark - Constraint

@property (nonatomic, nullable, readonly) NSLayoutConstraint *constraint;
@property (nonatomic, copy, readonly) NSLayoutConstraint * _Nullable (^constraintToSuperview)(NSLayoutAttribute attribute);
@property (nonatomic, copy, readonly) NSLayoutConstraint * _Nullable (^constraintToSuperviewWithRelation)(NSLayoutAttribute attribute, NSLayoutRelation relation);
@property (nonatomic, copy, readonly) NSLayoutConstraint * _Nullable (^constraintToSafeArea)(NSLayoutAttribute attribute);
@property (nonatomic, copy, readonly) NSLayoutConstraint * _Nullable (^constraintToSafeAreaWithRelation)(NSLayoutAttribute attribute, NSLayoutRelation relation);
@property (nonatomic, copy, readonly) NSLayoutConstraint * _Nullable (^constraintToView)(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id _Nullable ofView);
@property (nonatomic, copy, readonly) NSLayoutConstraint * _Nullable (^constraintToViewWithRelation)(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id _Nullable ofView, NSLayoutRelation relation);
@property (nonatomic, copy, readonly) NSLayoutConstraint * _Nullable (^constraintToViewWithMultiplier)(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id _Nullable ofView, CGFloat multiplier);
@property (nonatomic, copy, readonly) NSLayoutConstraint * _Nullable (^constraintToViewWithMultiplierAndRelation)(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id _Nullable ofView, CGFloat multiplier, NSLayoutRelation relation);

@end

#pragma mark - UIView+FWLayoutChain

/**
 视图链式布局分类
 */
@interface UIView (FWLayoutChain)

/// 链式布局对象
@property (nonatomic, strong, readonly) FWLayoutChain *fwLayoutChain NS_REFINED_FOR_SWIFT;

/// 链式布局句柄
- (void)fwLayoutMaker:(void (NS_NOESCAPE ^)(FWLayoutChain *make))block NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
