/*!
 @header     FWBarrageView.h
 @indexgroup FWFramework
 @brief      FWBarrageView
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/6/6
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class FWBarrageDescriptor;
@class FWBarrageCell;

FOUNDATION_EXPORT NSString *const FWBarrageAnimation;

typedef void(^FWBarrageTouchAction)(__weak FWBarrageDescriptor *descriptor);
typedef void(^FWBarrageCellTouchedAction)(__weak FWBarrageDescriptor *descriptor, __weak FWBarrageCell *cell);

typedef NS_ENUM(NSInteger, FWBarragePositionPriority) {
    FWBarragePositionLow = 0,
    FWBarragePositionMiddle,
    FWBarragePositionHigh,
    FWBarragePositionVeryHigh
};

typedef NS_ENUM(NSInteger, FWBarrageRenderPositionStyle) {//新加的cell的y坐标的类型
    FWBarrageRenderPositionRandomTracks = 0, //将FWBarrageRenderView分成几条轨道, 随机选一条展示
    FWBarrageRenderPositionRandom, // y坐标随机
    FWBarrageRenderPositionIncrease, //y坐标递增, 循环
};

#pragma mark - FWBarrageRenderView

typedef NS_ENUM(NSInteger, FWBarrageRenderStatus) {
    FWBarrageRenderStoped = 0,
    FWBarrageRenderStarted,
    FWBarrageRenderPaused
};

@interface FWBarrageRenderView : UIView <CAAnimationDelegate> {
    NSMutableArray<FWBarrageCell *> *_animatingCells;
    NSMutableArray<FWBarrageCell *> *_idleCells;
    dispatch_semaphore_t _animatingCellsLock;
    dispatch_semaphore_t _idleCellsLock;
    dispatch_semaphore_t _trackInfoLock;
    FWBarrageCell *_lastestCell;
    UIView *_lowPositionView;
    UIView *_middlePositionView;
    UIView *_highPositionView;
    UIView *_veryHighPositionView;
    BOOL _autoClear;
    FWBarrageRenderStatus _renderStatus;
    NSMutableDictionary *_trackNextAvailableTime;
}

@property (nonatomic, strong, readonly) NSMutableArray<FWBarrageCell *> *animatingCells;
@property (nonatomic, strong, readonly) NSMutableArray<FWBarrageCell *> *idleCells;
@property (nonatomic, assign) FWBarrageRenderPositionStyle renderPositionStyle;
@property (nonatomic, assign, readonly) FWBarrageRenderStatus renderStatus;

- (nullable FWBarrageCell *)dequeueReusableCellWithClass:(Class)barrageCellClass;
- (void)fireBarrageCell:(FWBarrageCell *)barrageCell;

- (void)start;
- (void)pause;
- (void)resume;
- (void)stop;

@end

#pragma mark - FWBarrageManager

/*!
 @brief 弹幕管理器
 
 @see https://github.com/w1531724247/OCBarrage
 */
@interface FWBarrageManager : NSObject {
    FWBarrageRenderView *_renderView;
}

@property (nonatomic, strong, readonly) FWBarrageRenderView *renderView;
@property (nonatomic, assign, readonly) FWBarrageRenderStatus renderStatus;

- (void)start;
- (void)pause;
- (void)resume;
- (void)stop;

- (void)renderBarrageDescriptor:(FWBarrageDescriptor *)barrageDescriptor;

@end

#pragma mark - FWBarrageDescriptor

@interface FWBarrageDescriptor : NSObject

@property (nonatomic, assign, nullable) Class barrageCellClass;
@property (nonatomic, assign) FWBarragePositionPriority positionPriority;//显示位置normal型的渲染在low型的上面, height型的渲染在normal上面
@property (nonatomic, assign) CGFloat animationDuration;//动画时间, 时间越长速度越慢, 时间越短速度越快
@property (nonatomic, assign) CGFloat fixedSpeed;//固定速度, 可以防止弹幕在有空闲轨道的情况下重叠, 取值0.0~100.0, animationDuration与fixedSpeed只能选择一个, fixedSpeed设置之后可以不用设置animationDuration

@property (nonatomic, copy, nullable) FWBarrageCellTouchedAction cellTouchedAction;//新属性里回传了被点击的cell, 可以在代码块里更改被点击的cell的属性, 比如之前有用户需要在弹幕被点击的时候修改被点击的弹幕的文字颜色等等. 用来替代旧版本的touchAction
@property (nonatomic, strong, nullable) UIColor *borderColor; // Default is no border
@property (nonatomic, assign) CGFloat borderWidth; // Default is 0
@property (nonatomic, assign) CGFloat cornerRadius; // Default is 8

@property (nonatomic, assign) NSRange renderRange;//渲染范围, 最终渲染出来的弹幕的Y坐标最小不小于renderRange.location, 最大不超过renderRange.length-barrageCell.height

@end

#pragma mark - FWBarrageCell

@protocol FWBarrageCellDelegate;

@interface FWBarrageCell : UIView
@property (nonatomic, assign, getter=isIdle) BOOL idle;//是否是空闲状态
@property (nonatomic, assign) NSTimeInterval idleTime;//开始闲置的时间, 闲置超过5秒的, 自动回收内存
@property (nonatomic, strong, nullable) FWBarrageDescriptor *barrageDescriptor;
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

@protocol FWBarrageCellDelegate <NSObject, CAAnimationDelegate>

@end

#pragma mark - FWBarrageTextDescriptor

@interface FWBarrageTextDescriptor : FWBarrageDescriptor {
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

#pragma mark - FWBarrageTextCell

@interface FWBarrageTextCell : FWBarrageCell

@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong, nullable) FWBarrageTextDescriptor *textDescriptor;

@end

#pragma mark - FWBarrageTrackInfo

@interface FWBarrageTrackInfo : NSObject

@property (nonatomic, assign) int trackIndex;
@property (nonatomic, copy, nullable) NSString *trackIdentifier;
@property (nonatomic, assign) CFTimeInterval nextAvailableTime;//下次可用的时间
@property (nonatomic, assign) NSInteger barrageCount;//当前行的弹幕数量
@property (nonatomic, assign) CGFloat trackHeight;//轨道高度

@end

@interface CALayer (FWBarrage)

- (nullable UIImage *)fwConvertContentToImageWithSize:(CGSize)contentSize;

@end

NS_ASSUME_NONNULL_END
