//
//  PopupMenu.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "PopupMenu.h"
#import <FWFramework/FWFramework-Swift.h>

#pragma mark - __FWPopupMenuPath

@implementation __FWPopupMenuPath

+ (CAShapeLayer *)maskLayerWithRect:(CGRect)rect
                         rectCorner:(UIRectCorner)rectCorner
                       cornerRadius:(CGFloat)cornerRadius
                         arrowWidth:(CGFloat)arrowWidth
                        arrowHeight:(CGFloat)arrowHeight
                      arrowPosition:(CGFloat)arrowPosition
                     arrowDirection:(__FWPopupMenuArrowDirection)arrowDirection
{
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.path = [self bezierPathWithRect:rect rectCorner:rectCorner cornerRadius:cornerRadius borderWidth:0 borderColor:nil backgroundColor:nil arrowWidth:arrowWidth arrowHeight:arrowHeight arrowPosition:arrowPosition arrowDirection:arrowDirection].CGPath;
    return shapeLayer;
}

+ (UIBezierPath *)bezierPathWithRect:(CGRect)rect
                          rectCorner:(UIRectCorner)rectCorner
                        cornerRadius:(CGFloat)cornerRadius
                         borderWidth:(CGFloat)borderWidth
                         borderColor:(UIColor *)borderColor
                     backgroundColor:(UIColor *)backgroundColor
                          arrowWidth:(CGFloat)arrowWidth
                         arrowHeight:(CGFloat)arrowHeight
                       arrowPosition:(CGFloat)arrowPosition
                      arrowDirection:(__FWPopupMenuArrowDirection)arrowDirection
{
    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    if (borderColor) {
        [borderColor setStroke];
    }
    if (backgroundColor) {
        [backgroundColor setFill];
    }
    bezierPath.lineWidth = borderWidth;
    rect = CGRectMake(borderWidth / 2, borderWidth / 2, rect.size.width - borderWidth, rect.size.height - borderWidth);
    CGFloat topRightRadius = 0,topLeftRadius = 0,bottomRightRadius = 0,bottomLeftRadius = 0;
    CGPoint topRightArcCenter,topLeftArcCenter,bottomRightArcCenter,bottomLeftArcCenter;
    
    if (rectCorner & UIRectCornerTopLeft) {
        topLeftRadius = cornerRadius;
    }
    if (rectCorner & UIRectCornerTopRight) {
        topRightRadius = cornerRadius;
    }
    if (rectCorner & UIRectCornerBottomLeft) {
        bottomLeftRadius = cornerRadius;
    }
    if (rectCorner & UIRectCornerBottomRight) {
        bottomRightRadius = cornerRadius;
    }
    
    if (arrowDirection == __FWPopupMenuArrowDirectionTop) {
        topLeftArcCenter = CGPointMake(topLeftRadius + rect.origin.x, arrowHeight + topLeftRadius + rect.origin.x);
        topRightArcCenter = CGPointMake(rect.size.width - topRightRadius + rect.origin.x, arrowHeight + topRightRadius + rect.origin.x);
        bottomLeftArcCenter = CGPointMake(bottomLeftRadius + rect.origin.x, rect.size.height - bottomLeftRadius + rect.origin.x);
        bottomRightArcCenter = CGPointMake(rect.size.width - bottomRightRadius + rect.origin.x, rect.size.height - bottomRightRadius + rect.origin.x);
        if (arrowPosition < topLeftRadius + arrowWidth / 2) {
            arrowPosition = topLeftRadius + arrowWidth / 2;
        }else if (arrowPosition > rect.size.width - topRightRadius - arrowWidth / 2) {
            arrowPosition = rect.size.width - topRightRadius - arrowWidth / 2;
        }
        [bezierPath moveToPoint:CGPointMake(arrowPosition - arrowWidth / 2, arrowHeight + rect.origin.x)];
        [bezierPath addLineToPoint:CGPointMake(arrowPosition, rect.origin.y + rect.origin.x)];
        [bezierPath addLineToPoint:CGPointMake(arrowPosition + arrowWidth / 2, arrowHeight + rect.origin.x)];
        [bezierPath addLineToPoint:CGPointMake(rect.size.width - topRightRadius, arrowHeight + rect.origin.x)];
        [bezierPath addArcWithCenter:topRightArcCenter radius:topRightRadius startAngle:M_PI * 3 / 2 endAngle:2 * M_PI clockwise:YES];
        [bezierPath addLineToPoint:CGPointMake(rect.size.width + rect.origin.x, rect.size.height - bottomRightRadius - rect.origin.x)];
        [bezierPath addArcWithCenter:bottomRightArcCenter radius:bottomRightRadius startAngle:0 endAngle:M_PI_2 clockwise:YES];
        [bezierPath addLineToPoint:CGPointMake(bottomLeftRadius + rect.origin.x, rect.size.height + rect.origin.x)];
        [bezierPath addArcWithCenter:bottomLeftArcCenter radius:bottomLeftRadius startAngle:M_PI_2 endAngle:M_PI clockwise:YES];
        [bezierPath addLineToPoint:CGPointMake(rect.origin.x, arrowHeight + topLeftRadius + rect.origin.x)];
        [bezierPath addArcWithCenter:topLeftArcCenter radius:topLeftRadius startAngle:M_PI endAngle:M_PI * 3 / 2 clockwise:YES];
        
    }else if (arrowDirection == __FWPopupMenuArrowDirectionBottom) {
        topLeftArcCenter = CGPointMake(topLeftRadius + rect.origin.x,topLeftRadius + rect.origin.x);
        topRightArcCenter = CGPointMake(rect.size.width - topRightRadius + rect.origin.x, topRightRadius + rect.origin.x);
        bottomLeftArcCenter = CGPointMake(bottomLeftRadius + rect.origin.x, rect.size.height - bottomLeftRadius + rect.origin.x - arrowHeight);
        bottomRightArcCenter = CGPointMake(rect.size.width - bottomRightRadius + rect.origin.x, rect.size.height - bottomRightRadius + rect.origin.x - arrowHeight);
        if (arrowPosition < bottomLeftRadius + arrowWidth / 2) {
            arrowPosition = bottomLeftRadius + arrowWidth / 2;
        }else if (arrowPosition > rect.size.width - bottomRightRadius - arrowWidth / 2) {
            arrowPosition = rect.size.width - bottomRightRadius - arrowWidth / 2;
        }
        [bezierPath moveToPoint:CGPointMake(arrowPosition + arrowWidth / 2, rect.size.height - arrowHeight + rect.origin.x)];
        [bezierPath addLineToPoint:CGPointMake(arrowPosition, rect.size.height + rect.origin.x)];
        [bezierPath addLineToPoint:CGPointMake(arrowPosition - arrowWidth / 2, rect.size.height - arrowHeight + rect.origin.x)];
        [bezierPath addLineToPoint:CGPointMake(bottomLeftRadius + rect.origin.x, rect.size.height - arrowHeight + rect.origin.x)];
        [bezierPath addArcWithCenter:bottomLeftArcCenter radius:bottomLeftRadius startAngle:M_PI_2 endAngle:M_PI clockwise:YES];
        [bezierPath addLineToPoint:CGPointMake(rect.origin.x, topLeftRadius + rect.origin.x)];
        [bezierPath addArcWithCenter:topLeftArcCenter radius:topLeftRadius startAngle:M_PI endAngle:M_PI * 3 / 2 clockwise:YES];
        [bezierPath addLineToPoint:CGPointMake(rect.size.width - topRightRadius + rect.origin.x, rect.origin.x)];
        [bezierPath addArcWithCenter:topRightArcCenter radius:topRightRadius startAngle:M_PI * 3 / 2 endAngle:2 * M_PI clockwise:YES];
        [bezierPath addLineToPoint:CGPointMake(rect.size.width + rect.origin.x, rect.size.height - bottomRightRadius - rect.origin.x - arrowHeight)];
        [bezierPath addArcWithCenter:bottomRightArcCenter radius:bottomRightRadius startAngle:0 endAngle:M_PI_2 clockwise:YES];
        
    }else if (arrowDirection == __FWPopupMenuArrowDirectionLeft) {
        topLeftArcCenter = CGPointMake(topLeftRadius + rect.origin.x + arrowHeight,topLeftRadius + rect.origin.x);
        topRightArcCenter = CGPointMake(rect.size.width - topRightRadius + rect.origin.x, topRightRadius + rect.origin.x);
        bottomLeftArcCenter = CGPointMake(bottomLeftRadius + rect.origin.x + arrowHeight, rect.size.height - bottomLeftRadius + rect.origin.x);
        bottomRightArcCenter = CGPointMake(rect.size.width - bottomRightRadius + rect.origin.x, rect.size.height - bottomRightRadius + rect.origin.x);
        if (arrowPosition < topLeftRadius + arrowWidth / 2) {
            arrowPosition = topLeftRadius + arrowWidth / 2;
        }else if (arrowPosition > rect.size.height - bottomLeftRadius - arrowWidth / 2) {
            arrowPosition = rect.size.height - bottomLeftRadius - arrowWidth / 2;
        }
        [bezierPath moveToPoint:CGPointMake(arrowHeight + rect.origin.x, arrowPosition + arrowWidth / 2)];
        [bezierPath addLineToPoint:CGPointMake(rect.origin.x, arrowPosition)];
        [bezierPath addLineToPoint:CGPointMake(arrowHeight + rect.origin.x, arrowPosition - arrowWidth / 2)];
        [bezierPath addLineToPoint:CGPointMake(arrowHeight + rect.origin.x, topLeftRadius + rect.origin.x)];
        [bezierPath addArcWithCenter:topLeftArcCenter radius:topLeftRadius startAngle:M_PI endAngle:M_PI * 3 / 2 clockwise:YES];
        [bezierPath addLineToPoint:CGPointMake(rect.size.width - topRightRadius, rect.origin.x)];
        [bezierPath addArcWithCenter:topRightArcCenter radius:topRightRadius startAngle:M_PI * 3 / 2 endAngle:2 * M_PI clockwise:YES];
        [bezierPath addLineToPoint:CGPointMake(rect.size.width + rect.origin.x, rect.size.height - bottomRightRadius - rect.origin.x)];
        [bezierPath addArcWithCenter:bottomRightArcCenter radius:bottomRightRadius startAngle:0 endAngle:M_PI_2 clockwise:YES];
        [bezierPath addLineToPoint:CGPointMake(arrowHeight + bottomLeftRadius + rect.origin.x, rect.size.height + rect.origin.x)];
        [bezierPath addArcWithCenter:bottomLeftArcCenter radius:bottomLeftRadius startAngle:M_PI_2 endAngle:M_PI clockwise:YES];
        
    }else if (arrowDirection == __FWPopupMenuArrowDirectionRight) {
        topLeftArcCenter = CGPointMake(topLeftRadius + rect.origin.x,topLeftRadius + rect.origin.x);
        topRightArcCenter = CGPointMake(rect.size.width - topRightRadius + rect.origin.x - arrowHeight, topRightRadius + rect.origin.x);
        bottomLeftArcCenter = CGPointMake(bottomLeftRadius + rect.origin.x, rect.size.height - bottomLeftRadius + rect.origin.x);
        bottomRightArcCenter = CGPointMake(rect.size.width - bottomRightRadius + rect.origin.x - arrowHeight, rect.size.height - bottomRightRadius + rect.origin.x);
        if (arrowPosition < topRightRadius + arrowWidth / 2) {
            arrowPosition = topRightRadius + arrowWidth / 2;
        }else if (arrowPosition > rect.size.height - bottomRightRadius - arrowWidth / 2) {
            arrowPosition = rect.size.height - bottomRightRadius - arrowWidth / 2;
        }
        [bezierPath moveToPoint:CGPointMake(rect.size.width - arrowHeight + rect.origin.x, arrowPosition - arrowWidth / 2)];
        [bezierPath addLineToPoint:CGPointMake(rect.size.width + rect.origin.x, arrowPosition)];
        [bezierPath addLineToPoint:CGPointMake(rect.size.width - arrowHeight + rect.origin.x, arrowPosition + arrowWidth / 2)];
        [bezierPath addLineToPoint:CGPointMake(rect.size.width - arrowHeight + rect.origin.x, rect.size.height - bottomRightRadius - rect.origin.x)];
        [bezierPath addArcWithCenter:bottomRightArcCenter radius:bottomRightRadius startAngle:0 endAngle:M_PI_2 clockwise:YES];
        [bezierPath addLineToPoint:CGPointMake(bottomLeftRadius + rect.origin.x, rect.size.height + rect.origin.x)];
        [bezierPath addArcWithCenter:bottomLeftArcCenter radius:bottomLeftRadius startAngle:M_PI_2 endAngle:M_PI clockwise:YES];
        [bezierPath addLineToPoint:CGPointMake(rect.origin.x, arrowHeight + topLeftRadius + rect.origin.x)];
        [bezierPath addArcWithCenter:topLeftArcCenter radius:topLeftRadius startAngle:M_PI endAngle:M_PI * 3 / 2 clockwise:YES];
        [bezierPath addLineToPoint:CGPointMake(rect.size.width - topRightRadius + rect.origin.x - arrowHeight, rect.origin.x)];
        [bezierPath addArcWithCenter:topRightArcCenter radius:topRightRadius startAngle:M_PI * 3 / 2 endAngle:2 * M_PI clockwise:YES];
        
    }else if (arrowDirection == __FWPopupMenuArrowDirectionNone) {
        topLeftArcCenter = CGPointMake(topLeftRadius + rect.origin.x,  topLeftRadius + rect.origin.x);
        topRightArcCenter = CGPointMake(rect.size.width - topRightRadius + rect.origin.x,  topRightRadius + rect.origin.x);
        bottomLeftArcCenter = CGPointMake(bottomLeftRadius + rect.origin.x, rect.size.height - bottomLeftRadius + rect.origin.x);
        bottomRightArcCenter = CGPointMake(rect.size.width - bottomRightRadius + rect.origin.x, rect.size.height - bottomRightRadius + rect.origin.x);
        [bezierPath moveToPoint:CGPointMake(topLeftRadius + rect.origin.x, rect.origin.x)];
        [bezierPath addLineToPoint:CGPointMake(rect.size.width - topRightRadius, rect.origin.x)];
        [bezierPath addArcWithCenter:topRightArcCenter radius:topRightRadius startAngle:M_PI * 3 / 2 endAngle:2 * M_PI clockwise:YES];
        [bezierPath addLineToPoint:CGPointMake(rect.size.width + rect.origin.x, rect.size.height - bottomRightRadius - rect.origin.x)];
        [bezierPath addArcWithCenter:bottomRightArcCenter radius:bottomRightRadius startAngle:0 endAngle:M_PI_2 clockwise:YES];
        [bezierPath addLineToPoint:CGPointMake(bottomLeftRadius + rect.origin.x, rect.size.height + rect.origin.x)];
        [bezierPath addArcWithCenter:bottomLeftArcCenter radius:bottomLeftRadius startAngle:M_PI_2 endAngle:M_PI clockwise:YES];
        [bezierPath addLineToPoint:CGPointMake(rect.origin.x, arrowHeight + topLeftRadius + rect.origin.x)];
        [bezierPath addArcWithCenter:topLeftArcCenter radius:topLeftRadius startAngle:M_PI endAngle:M_PI * 3 / 2 clockwise:YES];
    }
    
    [bezierPath closePath];
    return bezierPath;
}

@end

#pragma mark - __FWPopupMenuDeviceOrientationManager

@implementation __FWPopupMenuDeviceOrientationManager
@synthesize autoRotateWhenDeviceOrientationChanged = _autoRotateWhenDeviceOrientationChanged;
@synthesize deviceOrientDidChangeHandle = _deviceOrientDidChangeHandle;

+ (id<__FWPopupMenuDeviceOrientationManager>)manager
{
    __FWPopupMenuDeviceOrientationManager * manager = [[__FWPopupMenuDeviceOrientationManager alloc] init];
    manager.autoRotateWhenDeviceOrientationChanged = YES;
    return manager;
}

- (void)startMonitorDeviceOrientation
{
    if (!self.autoRotateWhenDeviceOrientationChanged) return;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDeviceOrientationDidChangedNotification:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}

- (void)endMonitorDeviceOrientation
{
    if (!self.autoRotateWhenDeviceOrientationChanged) return;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}

#pragma mark - notify
- (void)onDeviceOrientationDidChangedNotification:(NSNotification *)notify
{
    if (!self.autoRotateWhenDeviceOrientationChanged) return;
    UIInterfaceOrientation orientation = [notify.userInfo[UIApplicationStatusBarOrientationUserInfoKey] integerValue];
    if (_deviceOrientDidChangeHandle) {
        _deviceOrientDidChangeHandle(orientation);
    }
}

@end

#pragma mark - __FWPopupMenuAnimationManager

static NSString * const FWPopupShowAnimationKey = @"showAnimation";
static NSString * const FWPopupDismissAnimationKey = @"dismissAnimation";
@interface __FWPopupMenuAnimationManager () <CAAnimationDelegate>

@property (nonatomic, copy) void (^showAnimationHandle) (void);

@property (nonatomic, copy) void (^dismissAnimationHandle) (void);

@end

@implementation __FWPopupMenuAnimationManager
@synthesize style = _style;
@synthesize showAnimation = _showAnimation;
@synthesize dismissAnimation = _dismissAnimation;
@synthesize duration = _duration;
@synthesize animationView = _animationView;

+ (id<__FWPopupMenuAnimationManager>)manager
{
    __FWPopupMenuAnimationManager * manager = [[__FWPopupMenuAnimationManager alloc] init];
    manager.style = __FWPopupMenuAnimationStyleScale;
    manager.duration = 0.25;
    return manager;
}

- (void)configAnimation
{
    CABasicAnimation * showAnimation;
    CABasicAnimation * dismissAnimation;
    switch (_style) {
        case __FWPopupMenuAnimationStyleFade:
        {
            _showAnimation = _dismissAnimation = nil;
            //show
            showAnimation = [self getBasicAnimationWithKeyPath:@"opacity"];
            showAnimation.fillMode = kCAFillModeBackwards;
            showAnimation.fromValue = @(0);
            showAnimation.toValue = @(1);
            _showAnimation = showAnimation;
            //dismiss
            dismissAnimation = [self getBasicAnimationWithKeyPath:@"opacity"];
            dismissAnimation.fillMode = kCAFillModeForwards;
            dismissAnimation.fromValue = @(1);
            dismissAnimation.toValue = @(0);
            _dismissAnimation = dismissAnimation;
        }
            break;
        case __FWPopupMenuAnimationStyleCustom:
            break;
        case __FWPopupMenuAnimationStyleNone:
        {
            _showAnimation = _dismissAnimation = nil;
        }
            break;
        default:
        {
            _showAnimation = _dismissAnimation = nil;
            //show
            showAnimation = [self getBasicAnimationWithKeyPath:@"transform.scale"];
            showAnimation.fillMode = kCAFillModeBackwards;
            showAnimation.fromValue = @(0.1);
            showAnimation.toValue = @(1);
            _showAnimation = showAnimation;
            //dismiss
            dismissAnimation = [self getBasicAnimationWithKeyPath:@"transform.scale"];
            dismissAnimation.fillMode = kCAFillModeForwards;
            dismissAnimation.fromValue = @(1);
            dismissAnimation.toValue = @(0.1);
            _dismissAnimation = dismissAnimation;
        }
            break;
    }
}

- (void)setStyle:(__FWPopupMenuAnimationStyle)style
{
    _style = style;
    [self configAnimation];
}

- (void)setDuration:(CFTimeInterval)duration
{
    _duration = duration;
    [self configAnimation];
}

- (void)setShowAnimation:(CAAnimation *)showAnimation
{
    _showAnimation = showAnimation;
    [self configAnimation];
}

- (void)setDismissAnimation:(CAAnimation *)dismissAnimation
{
    _dismissAnimation = dismissAnimation;
    [self configAnimation];
}

- (CABasicAnimation *)getBasicAnimationWithKeyPath:(NSString *)keyPath
{
    CABasicAnimation * animation = [CABasicAnimation animationWithKeyPath:keyPath];
    animation.removedOnCompletion = NO;
    animation.duration = _duration;
    return animation;
}

- (void)displayShowAnimationCompletion:(void (^)(void))completion
{
    _showAnimationHandle = completion;
    if (!_showAnimation) {
        if (_showAnimationHandle) {
            _showAnimationHandle();
        }
        return;
    }
    _showAnimation.delegate = self;
    [_animationView.layer addAnimation:_showAnimation forKey:FWPopupShowAnimationKey];
}

- (void)displayDismissAnimationCompletion:(void (^)(void))completion
{
    _dismissAnimationHandle = completion;
    if (!_dismissAnimation) {
        if (_dismissAnimationHandle) {
            _dismissAnimationHandle();
        }
        return;
    }
    _dismissAnimation.delegate = self;
    [_animationView.layer addAnimation:_dismissAnimation forKey:FWPopupDismissAnimationKey];
}

#pragma mark - CAAnimationDelegate
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    if ([_animationView.layer animationForKey:FWPopupShowAnimationKey] == anim) {
        [_animationView.layer removeAnimationForKey:FWPopupShowAnimationKey];
        _showAnimation.delegate = nil;
        _showAnimation = nil;
        if (_showAnimationHandle) {
            _showAnimationHandle();
        }
    }else if ([_animationView.layer animationForKey:FWPopupDismissAnimationKey] == anim) {
        [_animationView.layer removeAnimationForKey:FWPopupDismissAnimationKey];
        _dismissAnimation.delegate = nil;
        _dismissAnimation = nil;
        if (_dismissAnimationHandle) {
            _dismissAnimationHandle();
        }
    }
}

@end

#pragma mark - __FWPopupMenu

@interface __FWPopupMenuCell : UITableViewCell
@property (nonatomic, assign) BOOL showsCustomSeparator;
@property (nonatomic, strong) UIColor *customSeparatorColor;
@property (nonatomic, assign) CGFloat customSeparatorHeight;
@property (nonatomic, assign) UIEdgeInsets customSeparatorInsets;
@property (nonatomic, assign) UIEdgeInsets imageEdgeInsets;
@property (nonatomic, assign) UIEdgeInsets textEdgeInsets;
@end

@implementation __FWPopupMenuCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _showsCustomSeparator = YES;
        _customSeparatorHeight = 0.5;
        _customSeparatorColor = [UIColor lightGrayColor];
    }
    return self;
}

- (void)setShowsCustomSeparator:(BOOL)showsCustomSeparator
{
    _showsCustomSeparator = showsCustomSeparator;
    [self setNeedsDisplay];
}

- (void)setCustomSeparatorColor:(UIColor *)customSeparatorColor
{
    _customSeparatorColor = customSeparatorColor;
    [self setNeedsDisplay];
}

- (void)setCustomSeparatorInsets:(UIEdgeInsets)customSeparatorInsets
{
    _customSeparatorInsets = customSeparatorInsets;
    [self setNeedsDisplay];
}

- (void)setCustomSeparatorHeight:(CGFloat)customSeparatorHeight
{
    _customSeparatorHeight = customSeparatorHeight;
    [self setNeedsDisplay];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.contentView.frame = self.bounds;
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    BOOL hasImageInset = self.imageView.image && !UIEdgeInsetsEqualToEdgeInsets(self.imageEdgeInsets, UIEdgeInsetsZero);
    BOOL hasTextInset = self.textLabel.text.length > 0 && !UIEdgeInsetsEqualToEdgeInsets(self.textEdgeInsets, UIEdgeInsetsZero);
    if (!hasImageInset && !hasTextInset) return;
    
    CGRect imageViewFrame = self.imageView.frame;
    CGRect textLabelFrame = self.textLabel.frame;
    
    if (hasImageInset) {
        imageViewFrame.origin.x += self.imageEdgeInsets.left - self.imageEdgeInsets.right;
        imageViewFrame.origin.y += self.imageEdgeInsets.top - self.imageEdgeInsets.bottom;
        
        textLabelFrame.origin.x += self.imageEdgeInsets.left;
        textLabelFrame.size.width = fmin(CGRectGetWidth(textLabelFrame), CGRectGetWidth(self.contentView.bounds) - CGRectGetMinX(textLabelFrame));
    }
    if (hasTextInset) {
        textLabelFrame.origin.x += self.textEdgeInsets.left - self.textEdgeInsets.right;
        textLabelFrame.origin.y += self.textEdgeInsets.top - self.textEdgeInsets.bottom;
        textLabelFrame.size.width = fmin(CGRectGetWidth(textLabelFrame), CGRectGetWidth(self.contentView.bounds) - CGRectGetMinX(textLabelFrame));
    }
    
    self.imageView.frame = imageViewFrame;
    self.textLabel.frame = textLabelFrame;
}

- (void)drawRect:(CGRect)rect
{
    if (!_showsCustomSeparator) return;
    UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRect:CGRectMake(_customSeparatorInsets.left, rect.size.height - _customSeparatorHeight + _customSeparatorInsets.top - _customSeparatorInsets.bottom, rect.size.width - _customSeparatorInsets.left - _customSeparatorInsets.right, _customSeparatorHeight)];
    [_customSeparatorColor setFill];
    [bezierPath fillWithBlendMode:kCGBlendModeNormal alpha:1];
    [bezierPath closePath];
}

@end

@interface __FWPopupMenu ()
<
UITableViewDelegate,
UITableViewDataSource
>

@property (nonatomic, strong) UIView      * menuBackView;
@property (nonatomic) CGRect                relyRect;
@property (nonatomic, assign) CGFloat       itemWidth;
@property (nonatomic) CGPoint               point;
@property (nonatomic, assign) BOOL          isCornerChanged;
@property (nonatomic, assign) BOOL          isChangeDirection;
@property (nonatomic, strong) UIView      * relyView;
@end

@implementation __FWPopupMenu

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setDefaultSettings];
    }
    return self;
}

#pragma mark - publics
+ (__FWPopupMenu *)showAtPoint:(CGPoint)point titles:(NSArray *)titles icons:(NSArray *)icons menuWidth:(CGFloat)itemWidth otherSettings:(void (^) (__FWPopupMenu * popupMenu))otherSetting
{
    __FWPopupMenu *popupMenu = [[__FWPopupMenu alloc] init];
    popupMenu.point = point;
    popupMenu.titles = titles;
    popupMenu.images = icons;
    popupMenu.itemWidth = itemWidth;
    if (otherSetting) otherSetting(popupMenu);
    [popupMenu show];
    return popupMenu;
}

+ (__FWPopupMenu *)showRelyOnView:(UIView *)view titles:(NSArray *)titles icons:(NSArray *)icons menuWidth:(CGFloat)itemWidth otherSettings:(void (^) (__FWPopupMenu * popupMenu))otherSetting
{
    __FWPopupMenu *popupMenu = [[__FWPopupMenu alloc] init];
    popupMenu.relyView = view;
    popupMenu.titles = titles;
    popupMenu.images = icons;
    popupMenu.itemWidth = itemWidth;
    if (otherSetting) otherSetting(popupMenu);
    [popupMenu show];
    return popupMenu;
}

- (void)dismiss
{
    [self.orientationManager endMonitorDeviceOrientation];
    if (self.delegate && [self.delegate respondsToSelector:@selector(popupMenuBeganDismiss:)]) {
        [self.delegate popupMenuBeganDismiss:self];
    }
    __weak typeof(self) weakSelf = self;
    [self.animationManager displayDismissAnimationCompletion:^{
        __strong typeof(weakSelf)self = weakSelf;
        if (self.delegate && [self.delegate respondsToSelector:@selector(popupMenuDidDismiss:)]) {
            [self.delegate popupMenuDidDismiss:self];
        }
        self.delegate = nil;
        [self removeFromSuperview];
        [self.menuBackView removeFromSuperview];
    }];
}

#pragma mark tableViewDelegate & dataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _titles.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * tableViewCell = nil;
    if (self.delegate && [self.delegate respondsToSelector:@selector(popupMenu:cellForRowAtIndex:)]) {
        tableViewCell = [self.delegate popupMenu:self cellForRowAtIndex:indexPath.row];
        if (tableViewCell) return tableViewCell;
    }
    if (self.customCellBlock) {
        tableViewCell = self.customCellBlock(self, indexPath.row);
        if (tableViewCell) return tableViewCell;
    }
    
    static NSString * identifier = @"FWPopupMenu";
    __FWPopupMenuCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[__FWPopupMenuCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.textLabel.numberOfLines = 0;
    }
    cell.backgroundColor = [UIColor clearColor];
    cell.textLabel.textColor = _textColor;
    if (_font) {
        cell.textLabel.font = _font;
    }else {
        cell.textLabel.font = [UIFont systemFontOfSize:_fontSize];
    }
    if ([_titles[indexPath.row] isKindOfClass:[NSAttributedString class]]) {
        cell.textLabel.attributedText = _titles[indexPath.row];
    }else if ([_titles[indexPath.row] isKindOfClass:[NSString class]]) {
        cell.textLabel.text = _titles[indexPath.row];
    }else {
        cell.textLabel.text = nil;
    }
    if (_images.count >= indexPath.row + 1) {
        if ([_images[indexPath.row] isKindOfClass:[NSString class]]) {
            cell.imageView.image = [UIImage imageNamed:_images[indexPath.row]];
        }else if ([_images[indexPath.row] isKindOfClass:[UIImage class]]){
            cell.imageView.image = _images[indexPath.row];
        }else {
            cell.imageView.image = nil;
        }
    } else {
        cell.imageView.image = nil;
    }
    cell.customSeparatorColor = _separatorColor;
    cell.customSeparatorInsets = _separatorInsets;
    cell.customSeparatorHeight = _separatorHeight;
    cell.showsCustomSeparator = indexPath.row < (_titles.count - 1) ? _showsSeparator : NO;
    cell.imageEdgeInsets = _imageEdgeInsets;
    cell.textEdgeInsets = _titleEdgeInsets;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return _itemHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (_dismissOnSelected) [self dismiss];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(popupMenu:didSelectedAtIndex:)]) {
        [self.delegate popupMenu:self didSelectedAtIndex:indexPath.row];
    }
    if (self.didSelectItemBlock) {
        self.didSelectItemBlock(indexPath.row);
    }
}

#pragma mark - privates
- (void)show
{
    [self.orientationManager startMonitorDeviceOrientation];
    [self updateUI];
    [UIWindow.__fw_mainWindow addSubview:_menuBackView];
    [UIWindow.__fw_mainWindow addSubview:self];
    if (self.delegate && [self.delegate respondsToSelector:@selector(popupMenuBeganShow:)]) {
        [self.delegate popupMenuBeganShow:self];
    }
    __weak typeof(self) weakSelf = self;
    [self.animationManager displayShowAnimationCompletion:^{
        __strong typeof(weakSelf)self = weakSelf;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(popupMenuDidShow:)]) {
            [self.delegate popupMenuDidShow:self];
        }
    }];
}

- (void)setDefaultSettings
{
    _cornerRadius = 5.0;
    _rectCorner = UIRectCornerAllCorners;
    self.showsShadow = YES;
    _dismissOnSelected = YES;
    _dismissOnTouchOutside = YES;
    _fontSize = 15;
    _textColor = [UIColor blackColor];
    _offset = 0.0;
    _relyRect = CGRectZero;
    _point = CGPointZero;
    _borderWidth = 0.0;
    _borderColor = [UIColor lightGrayColor];
    _arrowWidth = 15.0;
    _arrowHeight = 10.0;
    _backColor = [UIColor whiteColor];
    _showsSeparator = YES;
    _separatorColor = [UIColor lightGrayColor];
    _separatorHeight = 0.5;
    _arrowDirection = __FWPopupMenuArrowDirectionTop;
    _priorityDirection = __FWPopupMenuPriorityDirectionTop;
    _minSpace = 10.0;
    _maxVisibleCount = 5;
    _itemHeight = 44;
    _isCornerChanged = NO;
    _showsMaskView = YES;
    _maskViewColor = [[UIColor blackColor] colorWithAlphaComponent:0.1];
    _orientationManager = [__FWPopupMenuDeviceOrientationManager manager];
    _animationManager = [__FWPopupMenuAnimationManager manager];
    _animationManager.animationView = self;
    _menuBackView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height)];
    _menuBackView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.1];
    _menuBackView.alpha = 1;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget: self action: @selector(touchOutSide)];
    [_menuBackView addGestureRecognizer: tap];
    self.alpha = 1;
    self.backgroundColor = [UIColor clearColor];
    [self addSubview:self.tableView];
    
    __weak typeof(self) weakSelf = self;
    [_orientationManager setDeviceOrientDidChangeHandle:^(UIInterfaceOrientation orientation) {
        __strong typeof(weakSelf)self = weakSelf;
        if (orientation == UIInterfaceOrientationPortrait ||
            orientation == UIInterfaceOrientationLandscapeLeft ||
            orientation == UIInterfaceOrientationLandscapeRight)
        {
            if (self.relyView) {
                //依赖view
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    //需要延迟加载才可以获取真实的frame，这里先做个标记，若有更合适的方法再替换
                    [self calculateRealPointIfNeed];
                    [self updateUI];
                });
            }else {
                //依赖point
                [self updateUI];
            }
        }
    }];
}

- (UITableView *)tableView
{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.tableFooterView = [UIView new];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        if (@available(iOS 15.0, *)) {
            _tableView.sectionHeaderTopPadding = 0;
        }
    }
    return _tableView;
}

- (void)touchOutSide
{
    if (_dismissOnTouchOutside) {
        [self dismiss];
    }
}

- (void)setShowsShadow:(BOOL)showsShadow
{
    _showsShadow = showsShadow;
    self.layer.shadowOpacity = showsShadow ? 0.5 : 0;
    self.layer.shadowOffset = CGSizeMake(0, 0);
    self.layer.shadowRadius = showsShadow ? 2.0 : 0;
}

- (void)setRelyView:(UIView *)relyView
{
    _relyView = relyView;
    [self calculateRealPointIfNeed];
}

- (void)calculateRealPointIfNeed
{
    CGRect absoluteRect = [_relyView convertRect:_relyView.bounds toView:UIWindow.__fw_mainWindow];
    CGPoint relyPoint = CGPointMake(absoluteRect.origin.x + absoluteRect.size.width / 2, absoluteRect.origin.y + absoluteRect.size.height);
    self.relyRect = absoluteRect;
    self.point = relyPoint;
}

- (void)setShowsMaskView:(BOOL)showsMaskView
{
    _showsMaskView = showsMaskView;
    _menuBackView.backgroundColor = showsMaskView ? self.maskViewColor : [UIColor clearColor];
}

- (void)setMaskViewColor:(UIColor *)maskViewColor
{
    _maskViewColor = maskViewColor;
    _menuBackView.backgroundColor = self.showsMaskView ? maskViewColor : [UIColor clearColor];
}

- (void)setTitles:(NSArray *)titles
{
    _titles = titles;
}

- (void)setImages:(NSArray *)images
{
    _images = images;
}

- (void)updateUI
{
    _menuBackView.frame = CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height);
    CGFloat height;
    if (_titles.count > _maxVisibleCount) {
        height = _itemHeight * _maxVisibleCount + _borderWidth * 2;
        self.tableView.bounces = YES;
    }else {
        height = _itemHeight * _titles.count + _borderWidth * 2;
        self.tableView.bounces = NO;
    }
     _isChangeDirection = NO;
    if (_priorityDirection == __FWPopupMenuPriorityDirectionTop) {
        if (_point.y + height + _arrowHeight > UIScreen.mainScreen.bounds.size.height - _minSpace) {
            _arrowDirection = __FWPopupMenuArrowDirectionBottom;
            _isChangeDirection = YES;
        }else {
            _arrowDirection = __FWPopupMenuArrowDirectionTop;
            _isChangeDirection = NO;
        }
    }else if (_priorityDirection == __FWPopupMenuPriorityDirectionBottom) {
        if (_point.y - height - _arrowHeight < _minSpace) {
            _arrowDirection = __FWPopupMenuArrowDirectionTop;
            _isChangeDirection = YES;
        }else {
            _arrowDirection = __FWPopupMenuArrowDirectionBottom;
            _isChangeDirection = NO;
        }
    }else if (_priorityDirection == __FWPopupMenuPriorityDirectionLeft) {
        if (_point.x + _itemWidth + _arrowHeight > UIScreen.mainScreen.bounds.size.width - _minSpace) {
            _arrowDirection = __FWPopupMenuArrowDirectionRight;
            _isChangeDirection = YES;
        }else {
            _arrowDirection = __FWPopupMenuArrowDirectionLeft;
            _isChangeDirection = NO;
        }
    }else if (_priorityDirection == __FWPopupMenuPriorityDirectionRight) {
        if (_point.x - _itemWidth - _arrowHeight < _minSpace) {
            _arrowDirection = __FWPopupMenuArrowDirectionLeft;
            _isChangeDirection = YES;
        }else {
            _arrowDirection = __FWPopupMenuArrowDirectionRight;
            _isChangeDirection = NO;
        }
    }
    [self setArrowPosition];
    [self setRelyRect];
    if (_arrowDirection == __FWPopupMenuArrowDirectionTop) {
        CGFloat y = _isChangeDirection ? _point.y  : _point.y;
        if (_arrowPosition > _itemWidth / 2) {
            self.frame = CGRectMake(UIScreen.mainScreen.bounds.size.width - _minSpace - _itemWidth, y, _itemWidth, height + _arrowHeight);
        }else if (_arrowPosition < _itemWidth / 2) {
            self.frame = CGRectMake(_minSpace, y, _itemWidth, height + _arrowHeight);
        }else {
            self.frame = CGRectMake(_point.x - _itemWidth / 2, y, _itemWidth, height + _arrowHeight);
        }
    }else if (_arrowDirection == __FWPopupMenuArrowDirectionBottom) {
        CGFloat y = _isChangeDirection ? _point.y - _arrowHeight - height : _point.y - _arrowHeight - height;
        if (_arrowPosition > _itemWidth / 2) {
            self.frame = CGRectMake(UIScreen.mainScreen.bounds.size.width - _minSpace - _itemWidth, y, _itemWidth, height + _arrowHeight);
        }else if (_arrowPosition < _itemWidth / 2) {
            self.frame = CGRectMake(_minSpace, y, _itemWidth, height + _arrowHeight);
        }else {
            self.frame = CGRectMake(_point.x - _itemWidth / 2, y, _itemWidth, height + _arrowHeight);
        }
    }else if (_arrowDirection == __FWPopupMenuArrowDirectionLeft) {
        CGFloat x = _isChangeDirection ? _point.x : _point.x;
        if (_arrowPosition < _itemHeight / 2) {
            self.frame = CGRectMake(x, _point.y - _arrowPosition, _itemWidth + _arrowHeight, height);
        }else if (_arrowPosition > _itemHeight / 2) {
            self.frame = CGRectMake(x, _point.y - _arrowPosition, _itemWidth + _arrowHeight, height);
        }else {
            self.frame = CGRectMake(x, _point.y - _arrowPosition, _itemWidth + _arrowHeight, height);
        }
    }else if (_arrowDirection == __FWPopupMenuArrowDirectionRight) {
        CGFloat x = _isChangeDirection ? _point.x - _itemWidth - _arrowHeight : _point.x - _itemWidth - _arrowHeight;
        if (_arrowPosition < _itemHeight / 2) {
            self.frame = CGRectMake(x, _point.y - _arrowPosition, _itemWidth + _arrowHeight, height);
        }else if (_arrowPosition > _itemHeight / 2) {
            self.frame = CGRectMake(x, _point.y - _arrowPosition, _itemWidth + _arrowHeight, height);
        }else {
            self.frame = CGRectMake(x, _point.y - _arrowPosition, _itemWidth + _arrowHeight, height);
        }
    }
    
    if (_isChangeDirection) {
        [self changeRectCorner];
    }
    [self setAnchorPoint];
    [self setOffset];
    [self.tableView reloadData];
    [self setNeedsDisplay];
}

- (void)setRelyRect
{
    if (CGRectEqualToRect(_relyRect, CGRectZero)) {
        return;
    }
    if (_arrowDirection == __FWPopupMenuArrowDirectionTop) {
        _point.y = _relyRect.size.height + _relyRect.origin.y;
    }else if (_arrowDirection == __FWPopupMenuArrowDirectionBottom) {
        _point.y = _relyRect.origin.y;
    }else if (_arrowDirection == __FWPopupMenuArrowDirectionLeft) {
        _point = CGPointMake(_relyRect.origin.x + _relyRect.size.width, _relyRect.origin.y + _relyRect.size.height / 2);
    }else {
        _point = CGPointMake(_relyRect.origin.x, _relyRect.origin.y + _relyRect.size.height / 2);
    }
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    if (_arrowDirection == __FWPopupMenuArrowDirectionTop) {
        self.tableView.frame = CGRectMake(_borderWidth, _borderWidth + _arrowHeight, frame.size.width - _borderWidth * 2, frame.size.height - _arrowHeight);
    }else if (_arrowDirection == __FWPopupMenuArrowDirectionBottom) {
        self.tableView.frame = CGRectMake(_borderWidth, _borderWidth, frame.size.width - _borderWidth * 2, frame.size.height - _arrowHeight);
    }else if (_arrowDirection == __FWPopupMenuArrowDirectionLeft) {
        self.tableView.frame = CGRectMake(_borderWidth + _arrowHeight, _borderWidth , frame.size.width - _borderWidth * 2 - _arrowHeight, frame.size.height);
    }else if (_arrowDirection == __FWPopupMenuArrowDirectionRight) {
        self.tableView.frame = CGRectMake(_borderWidth , _borderWidth , frame.size.width - _borderWidth * 2 - _arrowHeight, frame.size.height);
    }
}

- (void)changeRectCorner
{
    if (_isCornerChanged || _rectCorner == UIRectCornerAllCorners) {
        return;
    }
    BOOL haveTopLeftCorner = NO, haveTopRightCorner = NO, haveBottomLeftCorner = NO, haveBottomRightCorner = NO;
    if (_rectCorner & UIRectCornerTopLeft) {
        haveTopLeftCorner = YES;
    }
    if (_rectCorner & UIRectCornerTopRight) {
        haveTopRightCorner = YES;
    }
    if (_rectCorner & UIRectCornerBottomLeft) {
        haveBottomLeftCorner = YES;
    }
    if (_rectCorner & UIRectCornerBottomRight) {
        haveBottomRightCorner = YES;
    }
    
    if (_arrowDirection == __FWPopupMenuArrowDirectionTop || _arrowDirection == __FWPopupMenuArrowDirectionBottom) {
        
        if (haveTopLeftCorner) {
            _rectCorner = _rectCorner | UIRectCornerBottomLeft;
        }else {
            _rectCorner = _rectCorner & (~UIRectCornerBottomLeft);
        }
        if (haveTopRightCorner) {
            _rectCorner = _rectCorner | UIRectCornerBottomRight;
        }else {
            _rectCorner = _rectCorner & (~UIRectCornerBottomRight);
        }
        if (haveBottomLeftCorner) {
            _rectCorner = _rectCorner | UIRectCornerTopLeft;
        }else {
            _rectCorner = _rectCorner & (~UIRectCornerTopLeft);
        }
        if (haveBottomRightCorner) {
            _rectCorner = _rectCorner | UIRectCornerTopRight;
        }else {
            _rectCorner = _rectCorner & (~UIRectCornerTopRight);
        }
        
    }else if (_arrowDirection == __FWPopupMenuArrowDirectionLeft || _arrowDirection == __FWPopupMenuArrowDirectionRight) {
        if (haveTopLeftCorner) {
            _rectCorner = _rectCorner | UIRectCornerTopRight;
        }else {
            _rectCorner = _rectCorner & (~UIRectCornerTopRight);
        }
        if (haveTopRightCorner) {
            _rectCorner = _rectCorner | UIRectCornerTopLeft;
        }else {
            _rectCorner = _rectCorner & (~UIRectCornerTopLeft);
        }
        if (haveBottomLeftCorner) {
            _rectCorner = _rectCorner | UIRectCornerBottomRight;
        }else {
            _rectCorner = _rectCorner & (~UIRectCornerBottomRight);
        }
        if (haveBottomRightCorner) {
            _rectCorner = _rectCorner | UIRectCornerBottomLeft;
        }else {
            _rectCorner = _rectCorner & (~UIRectCornerBottomLeft);
        }
    }
    
    _isCornerChanged = YES;
}

- (void)setOffset
{
    if (_itemWidth == 0) return;
    
    CGRect originRect = self.frame;
    
    if (_arrowDirection == __FWPopupMenuArrowDirectionTop) {
        originRect.origin.y += _offset;
    }else if (_arrowDirection == __FWPopupMenuArrowDirectionBottom) {
        originRect.origin.y -= _offset;
    }else if (_arrowDirection == __FWPopupMenuArrowDirectionLeft) {
        originRect.origin.x += _offset;
    }else if (_arrowDirection == __FWPopupMenuArrowDirectionRight) {
        originRect.origin.x -= _offset;
    }
    self.frame = originRect;
}

- (void)setAnchorPoint
{
    if (_itemWidth == 0) return;
    
    CGFloat menuHeight = [self getMenuTotalHeight];
    
    CGPoint point = CGPointMake(0.5, 0.5);
    if (_arrowDirection == __FWPopupMenuArrowDirectionTop) {
        point = CGPointMake(_arrowPosition / _itemWidth, 0);
    }else if (_arrowDirection == __FWPopupMenuArrowDirectionBottom) {
        point = CGPointMake(_arrowPosition / _itemWidth, 1);
    }else if (_arrowDirection == __FWPopupMenuArrowDirectionLeft) {
        point = CGPointMake(0, _arrowPosition / menuHeight);
    }else if (_arrowDirection == __FWPopupMenuArrowDirectionRight) {
        point = CGPointMake(1, _arrowPosition / menuHeight);
    }
    CGRect originRect = self.frame;
    self.layer.anchorPoint = point;
    self.frame = originRect;
}

- (void)setArrowPosition
{
    if (_priorityDirection == __FWPopupMenuPriorityDirectionNone) {
        return;
    }
    
    if (_arrowDirection == __FWPopupMenuArrowDirectionTop || _arrowDirection == __FWPopupMenuArrowDirectionBottom) {
        if (_point.x + _itemWidth / 2 > UIScreen.mainScreen.bounds.size.width - _minSpace) {
            _arrowPosition = _itemWidth - (UIScreen.mainScreen.bounds.size.width - _minSpace - _point.x);
        }else if (_point.x < _itemWidth / 2 + _minSpace) {
            _arrowPosition = _point.x - _minSpace;
        }else {
            _arrowPosition = _itemWidth / 2;
        }
        
    }else if (_arrowDirection == __FWPopupMenuArrowDirectionLeft || _arrowDirection == __FWPopupMenuArrowDirectionRight) {
    }
}

- (CGFloat)getMenuTotalHeight
{
    CGFloat menuHeight = 0;
    if (_titles.count > _maxVisibleCount) {
        menuHeight = _itemHeight * _maxVisibleCount + _borderWidth * 2;
    }else {
        menuHeight = _itemHeight * _titles.count + _borderWidth * 2;
    }
    return menuHeight;
}

- (void)drawRect:(CGRect)rect
{
    UIBezierPath *bezierPath = [__FWPopupMenuPath bezierPathWithRect:rect rectCorner:_rectCorner cornerRadius:_cornerRadius borderWidth:_borderWidth borderColor:_borderColor backgroundColor:_backColor arrowWidth:_arrowWidth arrowHeight:_arrowHeight arrowPosition:_arrowPosition arrowDirection:_arrowDirection];
    [bezierPath fill];
    [bezierPath stroke];
}

@end
