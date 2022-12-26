//
//  BarrageView.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class __FWBarrageDescriptor;
@class __FWBarrageCell;

FOUNDATION_EXPORT NSString *const __FWBarrageAnimation NS_SWIFT_NAME(BarrageAnimation);

typedef void(^__FWBarrageTouchAction)(__weak __FWBarrageDescriptor *descriptor) NS_SWIFT_NAME(BarrageTouchAction);
typedef void(^__FWBarrageCellTouchedAction)(__weak __FWBarrageDescriptor *descriptor, __weak __FWBarrageCell *cell) NS_SWIFT_NAME(BarrageCellTouchedAction);

typedef NS_ENUM(NSInteger, __FWBarragePositionPriority) {
    __FWBarragePositionLow = 0,
    __FWBarragePositionMiddle,
    __FWBarragePositionHigh,
    __FWBarragePositionVeryHigh
} NS_SWIFT_NAME(BarragePositionPriority);

typedef NS_ENUM(NSInteger, __FWBarrageRenderPositionStyle) {//新加的cell的y坐标的类型
    __FWBarrageRenderPositionRandomTracks = 0, //将__FWBarrageRenderView分成几条轨道, 随机选一条展示
    __FWBarrageRenderPositionRandom, // y坐标随机
    __FWBarrageRenderPositionIncrease, //y坐标递增, 循环
} NS_SWIFT_NAME(BarrageRenderPositionStyle);

#pragma mark - __FWBarrageRenderView

typedef NS_ENUM(NSInteger, __FWBarrageRenderStatus) {
    __FWBarrageRenderStoped = 0,
    __FWBarrageRenderStarted,
    __FWBarrageRenderPaused
} NS_SWIFT_NAME(BarrageRenderStatus);

NS_SWIFT_NAME(BarrageRenderView)
@interface __FWBarrageRenderView : UIView <CAAnimationDelegate> {
    NSMutableArray<__FWBarrageCell *> *_animatingCells;
    NSMutableArray<__FWBarrageCell *> *_idleCells;
    dispatch_semaphore_t _animatingCellsLock;
    dispatch_semaphore_t _idleCellsLock;
    dispatch_semaphore_t _trackInfoLock;
    __FWBarrageCell *_lastestCell;
    UIView *_lowPositionView;
    UIView *_middlePositionView;
    UIView *_highPositionView;
    UIView *_veryHighPositionView;
    BOOL _autoClear;
    __FWBarrageRenderStatus _renderStatus;
    NSMutableDictionary *_trackNextAvailableTime;
}

@property (nonatomic, strong, readonly) NSMutableArray<__FWBarrageCell *> *animatingCells;
@property (nonatomic, strong, readonly) NSMutableArray<__FWBarrageCell *> *idleCells;
@property (nonatomic, assign) __FWBarrageRenderPositionStyle renderPositionStyle;
@property (nonatomic, assign, readonly) __FWBarrageRenderStatus renderStatus;

- (nullable __FWBarrageCell *)dequeueReusableCellWithClass:(Class)barrageCellClass;
- (void)fireBarrageCell:(__FWBarrageCell *)barrageCell;
- (BOOL)trigerActionWithPoint:(CGPoint)touchPoint;

- (void)start;
- (void)pause;
- (void)resume;
- (void)stop;

@end

#pragma mark - __FWBarrageManager

/**
 弹幕管理器
 
 @see https://github.com/w1531724247/OCBarrage
 */
NS_SWIFT_NAME(BarrageManager)
@interface __FWBarrageManager : NSObject {
    __FWBarrageRenderView *_renderView;
}

@property (nonatomic, strong, readonly) __FWBarrageRenderView *renderView;
@property (nonatomic, assign, readonly) __FWBarrageRenderStatus renderStatus;

- (void)start;
- (void)pause;
- (void)resume;
- (void)stop;

- (void)renderBarrageDescriptor:(__FWBarrageDescriptor *)barrageDescriptor;

@end

#pragma mark - __FWBarrageDescriptor

NS_SWIFT_NAME(BarrageDescriptor)
@interface __FWBarrageDescriptor : NSObject

@property (nonatomic, assign, nullable) Class barrageCellClass;
@property (nonatomic, assign) __FWBarragePositionPriority positionPriority;//显示位置normal型的渲染在low型的上面, height型的渲染在normal上面
@property (nonatomic, assign) CGFloat animationDuration;//动画时间, 时间越长速度越慢, 时间越短速度越快
@property (nonatomic, assign) CGFloat fixedSpeed;//固定速度, 可以防止弹幕在有空闲轨道的情况下重叠, 取值0.0~100.0, animationDuration与fixedSpeed只能选择一个, fixedSpeed设置之后可以不用设置animationDuration

@property (nonatomic, copy, nullable) __FWBarrageCellTouchedAction cellTouchedAction;//新属性里回传了被点击的cell, 可以在代码块里更改被点击的cell的属性, 比如之前有用户需要在弹幕被点击的时候修改被点击的弹幕的文字颜色等等. 用来替代旧版本的touchAction
@property (nonatomic, strong, nullable) UIColor *borderColor; // Default is no border
@property (nonatomic, assign) CGFloat borderWidth; // Default is 0
@property (nonatomic, assign) CGFloat cornerRadius; // Default is 8

@property (nonatomic, assign) NSRange renderRange;//渲染范围, 最终渲染出来的弹幕的Y坐标最小不小于renderRange.location, 最大不超过renderRange.length-barrageCell.height

@end

#pragma mark - __FWBarrageCell

@protocol __FWBarrageCellDelegate;

NS_SWIFT_NAME(BarrageCell)
@interface __FWBarrageCell : UIView
@property (nonatomic, assign, getter=isIdle) BOOL idle;//是否是空闲状态
@property (nonatomic, assign) NSTimeInterval idleTime;//开始闲置的时间, 闲置超过5秒的, 自动回收内存
@property (nonatomic, strong, nullable) __FWBarrageDescriptor *barrageDescriptor;
@property (nonatomic, strong, readonly, nullable) CAAnimation *barrageAnimation;
@property (nonatomic, assign) int trackIndex;

- (void)addBarrageAnimationWithDelegate:(id<CAAnimationDelegate>)animationDelegate;
- (void)prepareForReuse;
- (void)clearContents;

- (void)updateSubviewsData;
- (void)layoutContentSubviews;
- (void)convertContentToImage;
- (void)sizeToFit;//设置好数据之后调用一下自动计算bounds
- (void)removeSubViewsAndSublayers;//默认删除所有的subview和sublayer; 如果需要选择性的删除可以重写这个方法.
- (void)addBorderAttributes;

@end

NS_SWIFT_NAME(BarrageCellDelegate)
@protocol __FWBarrageCellDelegate <NSObject, CAAnimationDelegate>

@end

#pragma mark - __FWBarrageTextDescriptor

NS_SWIFT_NAME(BarrageTextDescriptor)
@interface __FWBarrageTextDescriptor : __FWBarrageDescriptor {
    NSMutableDictionary *_textAttribute;
}

@property (nonatomic, strong, nullable) UIFont *textFont;
@property (nonatomic, strong, nullable) UIColor *textColor;

/*
 * 关闭文字阴影可大幅提升性能, 推荐使用strokeColor, 与shadowColor相比strokeColor性能更强悍
 */
@property (nonatomic, assign) BOOL textShadowOpened;//默认NO
@property (nonatomic, strong, nullable) UIColor *shadowColor;//默认黑色
@property (nonatomic, assign) CGSize shadowOffset;//默认CGSizeZero
@property (nonatomic, assign) CGFloat shadowRadius;//默认2.0
@property (nonatomic, assign) CGFloat shadowOpacity;//默认0.5

@property (nonatomic, strong, nullable) UIColor *strokeColor;
@property (nonatomic, assign) int strokeWidth;//笔画宽度(粗细)，取值为 NSNumber 对象（整数），负值填充效果，正值中空效果

@property (nonatomic, copy, nullable) NSString *text;
@property (nonatomic, copy, nullable) NSAttributedString *attributedText;

@end

#pragma mark - __FWBarrageTextCell

NS_SWIFT_NAME(BarrageTextCell)
@interface __FWBarrageTextCell : __FWBarrageCell

@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong, nullable) __FWBarrageTextDescriptor *textDescriptor;

@end

#pragma mark - __FWBarrageTrackInfo

NS_SWIFT_NAME(BarrageTrackInfo)
@interface __FWBarrageTrackInfo : NSObject

@property (nonatomic, assign) int trackIndex;
@property (nonatomic, copy, nullable) NSString *trackIdentifier;
@property (nonatomic, assign) CFTimeInterval nextAvailableTime;//下次可用的时间
@property (nonatomic, assign) NSInteger barrageCount;//当前行的弹幕数量
@property (nonatomic, assign) CGFloat trackHeight;//轨道高度

@end

NS_ASSUME_NONNULL_END
