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

@interface FWViewClassWrapper (FWAutoLayout)

/**
 是否启用自动布局适配RTL，启用后自动将Left|Right转换为Leading|Trailing，默认NO
 @note 如果项目兼容阿拉伯语等，需要启用RTL从右向左布局，开启此开关即可，无需修改布局代码
 手工切换视图左右布局方法：[UIView appearance].semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
 */
@property (nonatomic, assign) BOOL autoLayoutRTL;

/**
 是否全局自动等比例缩放布局，默认NO
 @note 启用后所有offset值都会自动*relativeScale，注意可能产生的影响。
 启用后注意事项：
 1. 屏幕宽度约束不能使用screenWidth约束，需要使用375设计标准
 2. 尽量不使用screenWidth固定屏幕宽度方式布局，推荐相对于父视图布局
 2. 只会对offset值生效，其他属性不受影响
 3. 如需特殊处理，可以指定某个视图关闭该功能
 */
@property (nonatomic, assign) BOOL autoScale;

@end

/**
 UIView自动布局分类，兼容UIView和UILayoutGuide(iOS9)
 @note 如果约束条件完全相同，会自动更新约束而不是重新添加。
 另外，默认布局方式使用LTR，如果需要RTL布局，可通过fwAutoLayoutRTL统一启用
 */
@interface FWViewWrapper (FWAutoLayout)

#pragma mark - AutoLayout

/// 视图是否自动等比例缩放布局，默认返回全局开关
@property (nonatomic, assign) BOOL autoScale;

/// 是否启用自动布局
@property (nonatomic, assign) BOOL autoLayout;

/**
 执行子视图自动布局，自动计算子视图尺寸。需先将视图添加到界面(如设置为tableHeaderView)，再调用即可(iOS8+)
 */
- (void)autoLayoutSubviews;

/**
 计算动态布局视图指定宽度时的高度。使用AutoLayout必须约束完整，不使用AutoLayout会调用view的sizeThatFits:方法
 */
- (CGFloat)layoutHeightWithWidth:(CGFloat)width;

/**
 计算动态布局视图指定高度时的宽度。使用AutoLayout必须约束完整，不使用AutoLayout会调用view的sizeThatFits:方法
 */
- (CGFloat)layoutWidthWithHeight:(CGFloat)height;

#pragma mark - Compression

/**
 设置水平方向抗压缩优先级
 */
@property (nonatomic, assign) UILayoutPriority compressionHorizontal;

/**
 设置垂直方向抗压缩优先级
 */
@property (nonatomic, assign) UILayoutPriority compressionVertical;

/**
 设置水平方向抗拉伸优先级
 */
@property (nonatomic, assign) UILayoutPriority huggingHorizontal;

/**
 设置垂直方向抗拉伸优先级
 */
@property (nonatomic, assign) UILayoutPriority huggingVertical;

#pragma mark - Collapse

/**
 设置视图是否收缩，默认NO，YES时常量值为0，NO时常量值为原始值
 */
@property (nonatomic, assign) BOOL collapsed;

/**
 设置视图是否自动收缩，如image为nil，text为nil、@""时自动收缩，默认NO
 */
@property (nonatomic, assign) BOOL autoCollapse;

/**
 设置视图是否隐藏时自动收缩、显示时自动展开，默认NO
 */
@property (nonatomic, assign) BOOL hiddenCollapse;

/**
 添加视图的收缩常量，必须先添加才能生效
 
 @see https://github.com/forkingdog/UIView-FDCollapsibleConstraints
 */
- (void)addCollapseConstraint:(NSLayoutConstraint *)constraint;

#pragma mark - Axis

/**
 父视图居中
 
 @return 约束数组
 */
- (NSArray<NSLayoutConstraint *> *)alignCenterToSuperview;

/**
 父视图居中偏移指定距离
 
 @param offset 偏移距离
 @return 约束数组
 */
- (NSArray<NSLayoutConstraint *> *)alignCenterToSuperviewWithOffset:(CGPoint)offset;

/**
 父视图属性居中
 
 @param axis 居中属性
 @return 布局约束
 */
- (NSLayoutConstraint *)alignAxisToSuperview:(NSLayoutAttribute)axis;

/**
 父视图属性居中偏移指定距离
 
 @param axis 居中属性
 @param offset 偏移距离
 @return 布局约束
 */
- (NSLayoutConstraint *)alignAxisToSuperview:(NSLayoutAttribute)axis withOffset:(CGFloat)offset;

/**
 与另一视图居中相同
 
 @param axis 居中属性
 @param otherView 另一视图或UILayoutGuide，下同
 @return 布局约束
 */
- (NSLayoutConstraint *)alignAxis:(NSLayoutAttribute)axis toView:(id)otherView;

/**
 与另一视图居中偏移指定距离
 
 @param axis 居中属性
 @param otherView 另一视图
 @param offset 偏移距离
 @return 布局约束
 */
- (NSLayoutConstraint *)alignAxis:(NSLayoutAttribute)axis toView:(id)otherView withOffset:(CGFloat)offset;

/**
 与另一视图居中指定比例
 
 @param axis 居中属性
 @param otherView 另一视图
 @param multiplier 指定比例
 @return 布局约束
 */
- (NSLayoutConstraint *)alignAxis:(NSLayoutAttribute)axis toView:(id)otherView withMultiplier:(CGFloat)multiplier;

#pragma mark - Edge

/**
 与父视图四条边属性相同
 
 @return 约束数组
 */
- (NSArray<NSLayoutConstraint *> *)pinEdgesToSuperview;

/**
 与父视图四条边属性距离指定距离
 
 @param insets 指定距离insets
 @return 约束数组
 */
- (NSArray<NSLayoutConstraint *> *)pinEdgesToSuperviewWithInsets:(UIEdgeInsets)insets;

/**
 与父视图三条边属性距离指定距离
 
 @param insets 指定距离insets
 @param edge 排除的边
 @return 约束数组
 */
- (NSArray<NSLayoutConstraint *> *)pinEdgesToSuperviewWithInsets:(UIEdgeInsets)insets excludingEdge:(NSLayoutAttribute)edge;

/**
 与父视图水平方向两条边属性相同
 
 @return 约束数组
 */
- (NSArray<NSLayoutConstraint *> *)pinHorizontalToSuperview;

/**
 与父视图水平方向两条边属性偏移指定距离
 
 @param inset 偏移距离
 @return 约束数组
 */
- (NSArray<NSLayoutConstraint *> *)pinHorizontalToSuperviewWithInset:(CGFloat)inset;

/**
 与父视图垂直方向两条边属性相同
 
 @return 约束数组
 */
- (NSArray<NSLayoutConstraint *> *)pinVerticalToSuperview;

/**
 与父视图垂直方向两条边属性偏移指定距离
 
 @param inset 偏移距离
 @return 约束数组
 */
- (NSArray<NSLayoutConstraint *> *)pinVerticalToSuperviewWithInset:(CGFloat)inset;

/**
 与父视图边属性相同
 
 @param edge 指定边属性
 @return 布局约束
 */
- (NSLayoutConstraint *)pinEdgeToSuperview:(NSLayoutAttribute)edge;

/**
 与父视图边属性偏移指定距离
 
 @param edge 指定边属性
 @param inset 偏移距离
 @return 布局约束
 */
- (NSLayoutConstraint *)pinEdgeToSuperview:(NSLayoutAttribute)edge withInset:(CGFloat)inset;

/**
 与父视图边属性偏移指定距离，指定关系
 
 @param edge 指定边属性
 @param inset 偏移距离
 @param relation 约束关系
 @return 布局约束
 */
- (NSLayoutConstraint *)pinEdgeToSuperview:(NSLayoutAttribute)edge withInset:(CGFloat)inset relation:(NSLayoutRelation)relation;

/**
 与指定视图边属性相同
 
 @param edge 指定边属性
 @param toEdge 另一视图边属性
 @param otherView 另一视图
 @return 布局约束
 */
- (NSLayoutConstraint *)pinEdge:(NSLayoutAttribute)edge toEdge:(NSLayoutAttribute)toEdge ofView:(id)otherView;

/**
 与指定视图边属性偏移指定距离
 
 @param edge 指定边属性
 @param toEdge 另一视图边属性
 @param otherView 另一视图
 @param offset 偏移距离
 @return 布局约束
 */
- (NSLayoutConstraint *)pinEdge:(NSLayoutAttribute)edge toEdge:(NSLayoutAttribute)toEdge ofView:(id)otherView withOffset:(CGFloat)offset;

/**
 与指定视图边属性偏移指定距离，指定关系
 
 @param edge 指定边属性
 @param toEdge 另一视图边属性
 @param otherView 另一视图
 @param offset 偏移距离
 @param relation 约束关系
 @return 布局约束
 */
- (NSLayoutConstraint *)pinEdge:(NSLayoutAttribute)edge toEdge:(NSLayoutAttribute)toEdge ofView:(id)otherView withOffset:(CGFloat)offset relation:(NSLayoutRelation)relation;

#pragma mark - SafeArea

/**
 父视图安全区域居中。iOS11以下使用Superview实现，下同
 
 @return 约束数组
 */
- (NSArray<NSLayoutConstraint *> *)alignCenterToSafeArea;

/**
 父视图安全区域居中偏移指定距离。iOS11以下使用Superview实现，下同
 
 @param offset 偏移距离
 @return 约束数组
 */
- (NSArray<NSLayoutConstraint *> *)alignCenterToSafeAreaWithOffset:(CGPoint)offset;

/**
 父视图安全区域属性居中
 
 @param axis 居中属性
 @return 布局约束
 */
- (NSLayoutConstraint *)alignAxisToSafeArea:(NSLayoutAttribute)axis;

/**
 父视图安全区域属性居中偏移指定距离
 
 @param axis 居中属性
 @param offset 偏移距离
 @return 布局约束
 */
- (NSLayoutConstraint *)alignAxisToSafeArea:(NSLayoutAttribute)axis withOffset:(CGFloat)offset;

/**
 与父视图安全区域四条边属性相同
 
 @return 约束数组
 */
- (NSArray<NSLayoutConstraint *> *)pinEdgesToSafeArea;

/**
 与父视图安全区域四条边属性距离指定距离
 
 @param insets 指定距离insets
 @return 约束数组
 */
- (NSArray<NSLayoutConstraint *> *)pinEdgesToSafeAreaWithInsets:(UIEdgeInsets)insets;

/**
 与父视图安全区域三条边属性距离指定距离
 
 @param insets 指定距离insets
 @param edge 排除的边
 @return 约束数组
 */
- (NSArray<NSLayoutConstraint *> *)pinEdgesToSafeAreaWithInsets:(UIEdgeInsets)insets excludingEdge:(NSLayoutAttribute)edge;

/**
 与父视图安全区域水平方向两条边属性相同
 
 @return 约束数组
 */
- (NSArray<NSLayoutConstraint *> *)pinHorizontalToSafeArea;

/**
 与父视图安全区域水平方向两条边属性偏移指定距离
 
 @param inset 偏移距离
 @return 约束数组
 */
- (NSArray<NSLayoutConstraint *> *)pinHorizontalToSafeAreaWithInset:(CGFloat)inset;

/**
 与父视图安全区域垂直方向两条边属性相同
 
 @return 约束数组
 */
- (NSArray<NSLayoutConstraint *> *)pinVerticalToSafeArea;

/**
 与父视图安全区域垂直方向两条边属性偏移指定距离
 
 @param inset 偏移距离
 @return 约束数组
 */
- (NSArray<NSLayoutConstraint *> *)pinVerticalToSafeAreaWithInset:(CGFloat)inset;

/**
 与父视图安全区域边属性相同
 
 @param edge 指定边属性
 @return 布局约束
 */
- (NSLayoutConstraint *)pinEdgeToSafeArea:(NSLayoutAttribute)edge;

/**
 与父视图安全区域边属性偏移指定距离
 
 @param edge 指定边属性
 @param inset 偏移距离
 @return 布局约束
 */
- (NSLayoutConstraint *)pinEdgeToSafeArea:(NSLayoutAttribute)edge withInset:(CGFloat)inset;

/**
 与父视图安全区域边属性偏移指定距离，指定关系
 
 @param edge 指定边属性
 @param inset 偏移距离
 @param relation 约束关系
 @return 布局约束
 */
- (NSLayoutConstraint *)pinEdgeToSafeArea:(NSLayoutAttribute)edge withInset:(CGFloat)inset relation:(NSLayoutRelation)relation;

#pragma mark - Dimension

/**
 设置宽高尺寸
 
 @param size 尺寸大小
 @return 约束数组
 */
- (NSArray<NSLayoutConstraint *> *)setDimensionsToSize:(CGSize)size;

/**
 设置某个尺寸
 
 @param dimension 尺寸属性
 @param size 尺寸大小
 @return 布局约束
 */
- (NSLayoutConstraint *)setDimension:(NSLayoutAttribute)dimension toSize:(CGFloat)size;

/**
 设置某个尺寸，指定关系
 
 @param dimension 尺寸属性
 @param size 尺寸大小
 @param relation 约束关系
 @return 布局约束
 */
- (NSLayoutConstraint *)setDimension:(NSLayoutAttribute)dimension toSize:(CGFloat)size relation:(NSLayoutRelation)relation;

/**
 与视图自身尺寸属性指定比例
 
 @param dimension 尺寸属性
 @param toDimension 目标尺寸属性
 @param multiplier 指定比例
 @return 布局约束
 */
- (NSLayoutConstraint *)matchDimension:(NSLayoutAttribute)dimension toDimension:(NSLayoutAttribute)toDimension withMultiplier:(CGFloat)multiplier;

/**
 与视图自身尺寸属性指定比例，指定关系
 
 @param dimension 尺寸属性
 @param toDimension 目标尺寸属性
 @param multiplier 指定比例
 @param relation 约束关系
 @return 布局约束
 */
- (NSLayoutConstraint *)matchDimension:(NSLayoutAttribute)dimension toDimension:(NSLayoutAttribute)toDimension withMultiplier:(CGFloat)multiplier relation:(NSLayoutRelation)relation;

/**
 与指定视图尺寸属性相同
 
 @param dimension 尺寸属性
 @param toDimension 目标尺寸属性
 @param otherView 目标视图
 @return 布局约束
 */
- (NSLayoutConstraint *)matchDimension:(NSLayoutAttribute)dimension toDimension:(NSLayoutAttribute)toDimension ofView:(id)otherView;

/**
 与指定视图尺寸属性相差指定大小
 
 @param dimension 尺寸属性
 @param toDimension 目标尺寸属性
 @param otherView 目标视图
 @param offset 相差大小
 @return 布局约束
 */
- (NSLayoutConstraint *)matchDimension:(NSLayoutAttribute)dimension toDimension:(NSLayoutAttribute)toDimension ofView:(id)otherView withOffset:(CGFloat)offset;

/**
 与指定视图尺寸属性相差指定大小，指定关系
 
 @param dimension 尺寸属性
 @param toDimension 目标尺寸属性
 @param otherView 目标视图
 @param offset 相差大小
 @param relation 约束关系
 @return 布局约束
 */
- (NSLayoutConstraint *)matchDimension:(NSLayoutAttribute)dimension toDimension:(NSLayoutAttribute)toDimension ofView:(id)otherView withOffset:(CGFloat)offset relation:(NSLayoutRelation)relation;

/**
 与指定视图尺寸属性指定比例
 
 @param dimension 尺寸属性
 @param toDimension 目标尺寸属性
 @param otherView 目标视图
 @param multiplier 指定比例
 @return 布局约束
 */
- (NSLayoutConstraint *)matchDimension:(NSLayoutAttribute)dimension toDimension:(NSLayoutAttribute)toDimension ofView:(id)otherView withMultiplier:(CGFloat)multiplier;

/**
 与指定视图尺寸属性指定比例，指定关系
 
 @param dimension 尺寸属性
 @param toDimension 目标尺寸属性
 @param otherView 目标视图
 @param multiplier 指定比例
 @param relation 约束关系
 @return 布局约束
 */
- (NSLayoutConstraint *)matchDimension:(NSLayoutAttribute)dimension toDimension:(NSLayoutAttribute)toDimension ofView:(id)otherView withMultiplier:(CGFloat)multiplier relation:(NSLayoutRelation)relation;

#pragma mark - Constrain

/**
 与指定视图属性相同
 
 @param attribute 指定属性
 @param toAttribute 目标视图属性
 @param otherView 目标视图
 @return 布局约束
 */
- (NSLayoutConstraint *)constrainAttribute:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(nullable id)otherView;

/**
 与指定视图属性偏移指定距离
 
 @param attribute 指定属性
 @param toAttribute 目标视图属性
 @param otherView 目标视图
 @param offset 偏移距离
 @return 布局约束
 */
- (NSLayoutConstraint *)constrainAttribute:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(nullable id)otherView withOffset:(CGFloat)offset;

/**
 与指定视图属性偏移指定距离，指定关系
 
 @param attribute 指定属性
 @param toAttribute 目标视图属性
 @param otherView 目标视图
 @param offset 偏移距离
 @param relation 约束关系
 @return 布局约束
 */
- (NSLayoutConstraint *)constrainAttribute:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(nullable id)otherView withOffset:(CGFloat)offset relation:(NSLayoutRelation)relation;

/**
 与指定视图属性指定比例
 
 @param attribute 指定属性
 @param toAttribute 目标视图属性
 @param otherView 目标视图
 @param multiplier 指定比例
 @return 布局约束
 */
- (NSLayoutConstraint *)constrainAttribute:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(nullable id)otherView withMultiplier:(CGFloat)multiplier;

/**
 与指定视图属性指定比例，指定关系
 
 @param attribute 指定属性
 @param toAttribute 目标视图属性
 @param otherView 目标视图
 @param multiplier 指定比例
 @param relation 约束关系
 @return 布局约束
 */
- (NSLayoutConstraint *)constrainAttribute:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(nullable id)otherView withMultiplier:(CGFloat)multiplier relation:(NSLayoutRelation)relation;

#pragma mark - Offset

/// 修改最近一批添加或更新的布局约束偏移值
- (NSArray<NSLayoutConstraint *> *)setOffset:(CGFloat)offset;

/// 修改最近一批添加或更新的布局约束内间距值
- (NSArray<NSLayoutConstraint *> *)setInset:(CGFloat)inset;

/// 修改最近一批添加或更新的布局约束优先级
- (NSArray<NSLayoutConstraint *> *)setPriority:(UILayoutPriority)priority;

#pragma mark - Constraint

/**
 获取添加的与父视图属性的约束
 
 @param attribute 指定属性
 @return 布局约束
 */
- (nullable NSLayoutConstraint *)constraintToSuperview:(NSLayoutAttribute)attribute;

/**
 获取添加的与父视图属性的约束，指定关系
 
 @param attribute 指定属性
 @param relation 约束关系
 @return 布局约束
 */
- (nullable NSLayoutConstraint *)constraintToSuperview:(NSLayoutAttribute)attribute relation:(NSLayoutRelation)relation;

/**
 获取添加的与父视图安全区域属性的约束
 
 @param attribute 指定属性
 @return 布局约束
 */
- (nullable NSLayoutConstraint *)constraintToSafeArea:(NSLayoutAttribute)attribute;

/**
 获取添加的与父视图安全区域属性的约束，指定关系
 
 @param attribute 指定属性
 @param relation 约束关系
 @return 布局约束
 */
- (nullable NSLayoutConstraint *)constraintToSafeArea:(NSLayoutAttribute)attribute relation:(NSLayoutRelation)relation;

/**
 获取添加的与指定视图属性的约束
 
 @param attribute 指定属性
 @param toAttribute 目标视图属性
 @param otherView 目标视图
 @return 布局约束
 */
- (nullable NSLayoutConstraint *)constraint:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(nullable id)otherView;

/**
 获取添加的与指定视图属性的约束，指定关系
 
 @param attribute 指定属性
 @param toAttribute 目标视图属性
 @param otherView 目标视图
 @param relation 约束关系
 @return 布局约束
 */
- (nullable NSLayoutConstraint *)constraint:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(nullable id)otherView relation:(NSLayoutRelation)relation;

/**
 获取添加的与指定视图属性指定比例的约束
 
 @param attribute 指定属性
 @param toAttribute 目标视图属性
 @param otherView 目标视图
 @param multiplier 指定比例
 @return 布局约束
 */
- (nullable NSLayoutConstraint *)constraint:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(nullable id)otherView withMultiplier:(CGFloat)multiplier;

/**
 获取添加的与指定视图属性指定比例的约束，指定关系
 
 @param attribute 指定属性
 @param toAttribute 目标视图属性
 @param otherView 目标视图
 @param multiplier 指定比例
 @param relation 约束关系
 @return 布局约束
 */
- (nullable NSLayoutConstraint *)constraint:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(nullable id)otherView withMultiplier:(CGFloat)multiplier relation:(NSLayoutRelation)relation;

/**
 设置约束保存键名，方便更新约束常量
 
 @param constraint 布局约束
 @param key 保存key
 */
- (void)setConstraint:(nullable NSLayoutConstraint *)constraint forKey:(id<NSCopying>)key;

/**
 获取键名对应约束
 
 @param key 保存key
 @return 布局约束
 */
- (nullable NSLayoutConstraint *)constraintForKey:(id<NSCopying>)key;

/**
 最近一批添加或更新的布局约束
 */
@property (nonatomic, copy, readonly) NSArray<NSLayoutConstraint *> *lastConstraints;

/**
 最近一条添加或更新的布局约束
 */
@property (nullable, nonatomic, readonly) NSLayoutConstraint *lastConstraint;

/**
 获取当前所有约束，不包含Key
 
 @return 约束列表
 */
@property (nonatomic, copy, readonly) NSArray<NSLayoutConstraint *> *allConstraints;

/**
 移除当前指定约束，不包含Key
 */
- (void)removeConstraint:(NSLayoutConstraint *)constraint;

/**
 移除当前所有约束，不包含Key
 */
- (void)removeAllConstraints;

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
@property (nonatomic, copy, readonly) FWLayoutChain * (^horizontal)(void);
@property (nonatomic, copy, readonly) FWLayoutChain * (^vertical)(void);
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
@property (nonatomic, copy, readonly) FWLayoutChain * (^topToViewBottom)(id view);
@property (nonatomic, copy, readonly) FWLayoutChain * (^bottomToViewTop)(id view);
@property (nonatomic, copy, readonly) FWLayoutChain * (^leftToViewRight)(id view);
@property (nonatomic, copy, readonly) FWLayoutChain * (^rightToViewLeft)(id view);
@property (nonatomic, copy, readonly) FWLayoutChain * (^topToViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^bottomToViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^leftToViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^rightToViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^topToViewBottomWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^bottomToViewTopWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^leftToViewRightWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^rightToViewLeftWithOffset)(id view, CGFloat offset);

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
@property (nonatomic, copy, readonly) FWLayoutChain * (^horizontalToSafeArea)(void);
@property (nonatomic, copy, readonly) FWLayoutChain * (^verticalToSafeArea)(void);
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

@property (nonatomic, copy, readonly) FWLayoutChain * (^offset)(CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^inset)(CGFloat inset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^priority)(UILayoutPriority priority);

@property (nonatomic, copy, readonly) NSArray<NSLayoutConstraint *> *constraints;
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

#pragma mark - FWViewWrapper+FWLayoutChain

/**
 视图链式布局分类
 */
@interface FWViewWrapper (FWLayoutChain)

/// 链式布局对象
@property (nonatomic, strong, readonly) FWLayoutChain *layoutChain NS_SWIFT_UNAVAILABLE("");

/// 链式布局句柄
- (void)layoutMaker:(void (NS_NOESCAPE ^)(FWLayoutChain *make))block NS_SWIFT_UNAVAILABLE("");

@end

NS_ASSUME_NONNULL_END