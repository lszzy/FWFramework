//
//  BadgeView.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "BadgeView.h"
#import "Swizzle.h"
#import <objc/runtime.h>

#if FWMacroSPM

@interface UIView ()

- (NSArray<NSLayoutConstraint *> *)__fw_alignCenterToSuperview:(CGPoint)offset;
- (NSArray<NSLayoutConstraint *> *)__fw_setDimensions:(CGSize)size;
- (NSLayoutConstraint *)__fw_setDimension:(NSLayoutAttribute)dimension size:(CGFloat)size relation:(NSLayoutRelation)relation priority:(UILayoutPriority)priority;
- (NSLayoutConstraint *)__fw_pinEdgeToSuperview:(NSLayoutAttribute)edge inset:(CGFloat)inset relation:(NSLayoutRelation)relation priority:(UILayoutPriority)priority;
- (NSLayoutConstraint *)__fw_pinEdge:(NSLayoutAttribute)edge toEdge:(NSLayoutAttribute)toEdge ofView:(id)otherView offset:(CGFloat)offset relation:(NSLayoutRelation)relation priority:(UILayoutPriority)priority;

@end

#else

#import <FWFramework/FWFramework-Swift.h>

#endif

#pragma mark - __FWBadgeView

@implementation __FWBadgeView

- (instancetype)initWithBadgeStyle:(__FWBadgeStyle)badgeStyle
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        // 根据样式处理
        _badgeStyle = badgeStyle;
        switch (badgeStyle) {
            case __FWBadgeStyleSmall: {
                [self setupWithBadgeHeight:18.f badgeOffset:CGPointMake(7.f, 7.f) textInset:5.f fontSize:12.f];
                break;
            }
            case __FWBadgeStyleBig: {
                [self setupWithBadgeHeight:24.f badgeOffset:CGPointMake(9.f, 9.f) textInset:6.f fontSize:14.f];
                break;
            }
            case __FWBadgeStyleDot:
            default: {
                CGFloat badgeHeight = 10.f;
                _badgeOffset = CGPointMake(3.f, 3.f);
                
                self.userInteractionEnabled = NO;
                self.backgroundColor = [UIColor redColor];
                self.layer.cornerRadius = badgeHeight / 2.0;
                [self __fw_setDimensions:CGSizeMake(badgeHeight, badgeHeight)];
                break;
            }
        }
    }
    return self;
}

- (instancetype)initWithBadgeHeight:(CGFloat)badgeHeight badgeOffset:(CGPoint)badgeOffset textInset:(CGFloat)textInset fontSize:(CGFloat)fontSize
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self setupWithBadgeHeight:badgeHeight badgeOffset:badgeOffset textInset:textInset fontSize:fontSize];
    }
    return self;
}

- (void)setupWithBadgeHeight:(CGFloat)badgeHeight badgeOffset:(CGPoint)badgeOffset textInset:(CGFloat)textInset fontSize:(CGFloat)fontSize
{
    _badgeOffset = badgeOffset;
    
    self.userInteractionEnabled = NO;
    self.backgroundColor = [UIColor redColor];
    self.layer.cornerRadius = badgeHeight / 2.0;
    [self __fw_setDimension:NSLayoutAttributeHeight size:badgeHeight relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
    [self __fw_setDimension:NSLayoutAttributeWidth size:badgeHeight relation:NSLayoutRelationGreaterThanOrEqual priority:UILayoutPriorityRequired];
    
    _badgeLabel = [[UILabel alloc] init];
    _badgeLabel.textColor = [UIColor whiteColor];
    _badgeLabel.font = [UIFont systemFontOfSize:fontSize];
    _badgeLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_badgeLabel];
    [_badgeLabel __fw_alignCenterToSuperview:CGPointZero];
    [_badgeLabel __fw_pinEdgeToSuperview:NSLayoutAttributeRight inset:textInset relation:NSLayoutRelationGreaterThanOrEqual priority:UILayoutPriorityRequired];
    [_badgeLabel __fw_pinEdgeToSuperview:NSLayoutAttributeLeft inset:textInset relation:NSLayoutRelationGreaterThanOrEqual priority:UILayoutPriorityRequired];
}

@end
