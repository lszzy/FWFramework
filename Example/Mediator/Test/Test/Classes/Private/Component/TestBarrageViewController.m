//
//  TestBarrageViewController.m
//  Example
//
//  Created by wuyong on 2020/6/6.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

#import "TestBarrageViewController.h"

@interface FWBarrageGradientBackgroundColorDescriptor : FWBarrageTextDescriptor

@property (nonatomic, strong, nullable) UIColor *gradientColor;

@end

@implementation FWBarrageGradientBackgroundColorDescriptor

@end

@interface FWBarrageGradientBackgroundColorCell : FWBarrageTextCell {
    CAGradientLayer *_gradientLayer;
}

@property (nonatomic, strong, nullable) FWBarrageGradientBackgroundColorDescriptor *gradientDescriptor;

@end

@implementation FWBarrageGradientBackgroundColorCell

- (void)updateSubviewsData {
    [super updateSubviewsData];
    
}

-(void)prepareForReuse {
    [super prepareForReuse];
    
    [self.textLabel setAttributedText:nil];
    [self addSubview:self.textLabel];
}

- (void)layoutContentSubviews {
    [super layoutContentSubviews];
    [self addGradientLayer];
}

- (void)convertContentToImage {
    UIImage *contentImage = [self.layer fwConvertContentToImageWithSize:_gradientLayer.frame.size];
    [self.layer setContents:(__bridge id)contentImage.CGImage];
}

- (void)removeSubViewsAndSublayers {
    [super removeSubViewsAndSublayers];
    
    _gradientLayer = nil;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.textLabel.center = _gradientLayer.position;
}

- (void)addGradientLayer {
    if (!self.gradientDescriptor.gradientColor) {
        return;
    }
    
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.colors = @[(__bridge id)[self.gradientDescriptor.gradientColor colorWithAlphaComponent:0.8].CGColor, (__bridge id)[self.gradientDescriptor.gradientColor colorWithAlphaComponent:0.0].CGColor];
    gradientLayer.locations = @[@0.2, @1.0];
    gradientLayer.startPoint = CGPointMake(0, 0);
    gradientLayer.endPoint = CGPointMake(1.0, 0);
    gradientLayer.frame = CGRectMake(0.0, 0.0, self.textLabel.frame.size.width + 20.0, self.textLabel.frame.size.height);
    
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:gradientLayer.bounds byRoundingCorners:UIRectCornerBottomLeft | UIRectCornerTopLeft cornerRadii:gradientLayer.bounds.size];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = gradientLayer.bounds;
    maskLayer.path = maskPath.CGPath;
    gradientLayer.mask = maskLayer;
    _gradientLayer = gradientLayer;
    [self.layer insertSublayer:gradientLayer atIndex:0];
}

- (void)setBarrageDescriptor:(FWBarrageDescriptor *)barrageDescriptor {
    [super setBarrageDescriptor:barrageDescriptor];
    self.gradientDescriptor = (FWBarrageGradientBackgroundColorDescriptor *)barrageDescriptor;
}

@end

@interface FWBarrageWalkBannerDescriptor : FWBarrageTextDescriptor

@property (nonatomic, copy) NSString *bannerLeftImageSrc;
@property (nonatomic, strong) UIColor *bannerMiddleColor;
@property (nonatomic, copy) NSString *bannerRightImageSrc;

@end

@implementation FWBarrageWalkBannerDescriptor

@end

@interface FWBarrageWalkBannerCell : FWBarrageTextCell {
    CGRect _contentRect;
}

@property (nonatomic, strong) UIImageView *leftImageView;
@property (nonatomic, strong) UIImageView *middleImageView;
@property (nonatomic, strong) UIImageView *rightImageView;

@property (nonatomic, strong) FWBarrageWalkBannerDescriptor *walkBannerDescriptor;

@end

#define ImageWidth 89.0
#define ImageHeight 57.0

@implementation FWBarrageWalkBannerCell

- (instancetype)init {
    self = [super init];
    if (self) {
        [self addSubviews];
    }
    
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    //因为在点击的时候被改为了红色, 所以在重用的时候, 要重置一下颜色
    self.textLabel.backgroundColor = [UIColor clearColor];
}

- (void)addSubviews {
    [self addSubview:self.leftImageView];
    [self addSubview:self.middleImageView];
    [self addSubview:self.rightImageView];
}

- (void)updateSubviewsData {
    [super updateSubviewsData];
    
    [self.leftImageView setImage:[UIImage imageNamed:@"frame1"]];
    [self.middleImageView setBackgroundColor:[UIColor colorWithRed:1.00 green:0.83 blue:0.26 alpha:1.00]];
    [self.rightImageView setImage:[UIImage imageNamed:@"frame2"]];
}

- (void)layoutContentSubviews {
    [super layoutContentSubviews];
    
    CGFloat leftImageViewX = 0.0;
    CGFloat leftImageViewY = 0.0;
    CGFloat leftImageViewW = ImageWidth;
    CGFloat leftImageViewH = ImageHeight;
    self.leftImageView.frame = CGRectMake(leftImageViewX, leftImageViewY, leftImageViewW, leftImageViewH);
    
    CGFloat middleImageViewW = CGRectGetWidth(self.textLabel.bounds);
    CGFloat middleImageViewH = 19;
    CGFloat middleImageViewX = CGRectGetMaxX(self.leftImageView.bounds) - 1.0;
    CGFloat middleImageViewY = (leftImageViewH - middleImageViewH)/2;
    self.middleImageView.frame = CGRectMake(middleImageViewX, middleImageViewY, middleImageViewW, middleImageViewH);
    self.textLabel.center = self.middleImageView.center;
    
    CGFloat rightImageViewX = CGRectGetMaxX(self.textLabel.frame) - 1.0;
    CGFloat rightImageViewY = leftImageViewY;
    CGFloat rightImageViewW = CGRectGetWidth(self.rightImageView.frame) > 2?CGRectGetWidth(self.rightImageView.frame):22.0;
    CGFloat rightImageViewH = ImageHeight;
    self.rightImageView.frame = CGRectMake(rightImageViewX, rightImageViewY, rightImageViewW, rightImageViewH);
}

- (void)convertContentToImage {
    UIImage *contentImage = [self.layer fwConvertContentToImageWithSize:CGSizeMake(CGRectGetMaxX(self.rightImageView.frame), CGRectGetMaxY(self.rightImageView.frame))];
    [self.layer setContents:(__bridge id)contentImage.CGImage];
}

- (void)removeSubViewsAndSublayers {
    //如果不要删除leftImageView, middleImageView, rightImageView, textLabel, 只需重写这个方法并留空就可以了.
    //比如: 你想在这个cell被点击的时候, 修改文本颜色
}

#pragma mark ---- setter
- (void)setBarrageDescriptor:(FWBarrageDescriptor *)barrageDescriptor {
    [super setBarrageDescriptor:barrageDescriptor];
    self.walkBannerDescriptor = (FWBarrageWalkBannerDescriptor *)barrageDescriptor;
}

#pragma mark ---- getter
- (UIImageView *)leftImageView {
    if (!_leftImageView) {
        _leftImageView = [[UIImageView alloc] init];
        _leftImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _leftImageView;
}

- (UIImageView *)middleImageView {
    if (!_middleImageView) {
        _middleImageView = [[UIImageView alloc] init];
        _middleImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _middleImageView;
}

- (UIImageView *)rightImageView {
    if (!_rightImageView) {
        _rightImageView = [[UIImageView alloc] init];
        _rightImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    
    return _rightImageView;
}

@end

@interface FWBarrageBecomeNobleDescriptor : FWBarrageTextDescriptor

@property (nonatomic, strong) UIImage *backgroundImage;

@end

@implementation FWBarrageBecomeNobleDescriptor

@end

@interface FWBarrageBecomeNobleCell : FWBarrageTextCell

@property (nonatomic, strong) FWBarrageBecomeNobleDescriptor *nobleDescriptor;
@property (nonatomic, strong) CALayer *backgroundImageLayer;

@end

@implementation FWBarrageBecomeNobleCell

- (instancetype)init {
    self = [super init];
    if (self) {
        [self addsublayers];
    }
    
    return self;
}

- (void)addsublayers {
    [self.layer insertSublayer:self.backgroundImageLayer atIndex:0];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    [self addsublayers];
}

- (void)updateSubviewsData {
    [super updateSubviewsData];
    
    [self.backgroundImageLayer setContents:(__bridge id)self.nobleDescriptor.backgroundImage.CGImage];
}

- (void)layoutContentSubviews {
    [super layoutContentSubviews];
 
    self.backgroundImageLayer.frame = CGRectMake(0.0, 0.0, self.nobleDescriptor.backgroundImage.size.width, self.nobleDescriptor.backgroundImage.size.height);
    CGPoint center = self.backgroundImageLayer.position;
    center.y += 17.0;
    self.textLabel.center = center;
}

- (void)convertContentToImage {
    UIImage *image = [self.layer fwConvertContentToImageWithSize:CGSizeMake(self.nobleDescriptor.backgroundImage.size.width, self.nobleDescriptor.backgroundImage.size.height)];
    [self.layer setContents:(__bridge id)image.CGImage];
}

- (void)addBarrageAnimationWithDelegate:(id<CAAnimationDelegate>)animationDelegate {
    if (!self.superview) {
        return;
    }
    
    CGPoint startCenter = CGPointMake(CGRectGetMaxX(self.superview.bounds) + CGRectGetWidth(self.bounds)/2, self.center.y);
    CGPoint stopCenter = CGPointMake(CGRectGetMidX(self.superview.bounds), self.center.y);
    CGPoint endCenter = CGPointMake(-(CGRectGetWidth(self.bounds)/2), self.center.y);
    
    CAKeyframeAnimation *walkAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    walkAnimation.values = @[[NSValue valueWithCGPoint:startCenter], [NSValue valueWithCGPoint:stopCenter], [NSValue valueWithCGPoint:stopCenter], [NSValue valueWithCGPoint:endCenter]];
    walkAnimation.keyTimes = @[@(0.0), @(0.25), @(0.75), @(1.0)];
    walkAnimation.duration = self.barrageDescriptor.animationDuration;
    walkAnimation.repeatCount = 1;
    walkAnimation.delegate =  animationDelegate;
    walkAnimation.removedOnCompletion = NO;
    walkAnimation.fillMode = kCAFillModeForwards;
    
    [self.layer addAnimation:walkAnimation forKey:FWBarrageAnimation];
}

#pragma mark ---- setter
- (void)setBarrageDescriptor:(FWBarrageDescriptor *)barrageDescriptor {
    [super setBarrageDescriptor:barrageDescriptor];
    self.nobleDescriptor = (FWBarrageBecomeNobleDescriptor *)barrageDescriptor;
}

#pragma mark ---- getter
- (CALayer *)backgroundImageLayer {
    if (!_backgroundImageLayer) {
        _backgroundImageLayer = [[CALayer alloc] init];
    }
    
    return _backgroundImageLayer;
}

@end

@interface FWBarrageMixedImageAndTextCell : FWBarrageTextCell

@property (nonatomic, strong) FWAttributedLabel *miaxedImageAndTextLabel;

@end

@implementation FWBarrageMixedImageAndTextCell

- (instancetype)init {
    self = [super init];
    if (self) {
        [self addSubviews];
    }
    
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.miaxedImageAndTextLabel.attributedText = nil;
}

- (void)addSubviews {
    [self addSubview:self.miaxedImageAndTextLabel];
}

- (void)updateSubviewsData {
    self.miaxedImageAndTextLabel.attributedText = self.textDescriptor.attributedText;
}

- (void)layoutContentSubviews {
    CGSize cellSize = [self.miaxedImageAndTextLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
    self.miaxedImageAndTextLabel.frame = CGRectMake(0.0, 0.0, cellSize.width, cellSize.height);
}

- (void)removeSubViewsAndSublayers {

}

#pragma mark --- getter

- (FWAttributedLabel *)miaxedImageAndTextLabel {
    if (!_miaxedImageAndTextLabel) {
        _miaxedImageAndTextLabel = [[FWAttributedLabel alloc] init];
    }
    
    return _miaxedImageAndTextLabel;
}

@end

@interface FWBarrageGifDescriptor : FWBarrageDescriptor

@property (nonatomic, strong) UIImage *image;

@end

@implementation FWBarrageGifDescriptor

@end

@interface FWBarrageGifCell : FWBarrageCell

@property (nonatomic, strong) FWBarrageGifDescriptor *gifDescriptor;
@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation FWBarrageGifCell

- (instancetype)init {
    self = [super init];
    if (self) {
        [self addSubviews];
    }
    
    return self;
}

- (void)addSubviews {
    [self addSubview:self.imageView];
}

- (void)updateSubviewsData {
    self.imageView.image = self.gifDescriptor.image;
}

- (void)layoutContentSubviews {
    self.imageView.frame = CGRectMake(0.0, 0.0, 100.0, 100.0);
}

- (void)addBarrageAnimationWithDelegate:(id<CAAnimationDelegate>)animationDelegate {
    if (!self.superview) {
        return;
    }
    
    CGPoint startCenter = CGPointMake(CGRectGetMaxX(self.superview.bounds) + CGRectGetWidth(self.bounds)/2, self.center.y);
    CGPoint endCenter = CGPointMake(-(CGRectGetWidth(self.bounds)/2), self.center.y);
    
    CAKeyframeAnimation *walkAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    walkAnimation.values = @[[NSValue valueWithCGPoint:startCenter], [NSValue valueWithCGPoint:endCenter]];
    walkAnimation.keyTimes = @[@(0.0), @(1.0)];
    walkAnimation.duration = self.barrageDescriptor.animationDuration;
    walkAnimation.repeatCount = 1;
    walkAnimation.delegate =  animationDelegate;
    walkAnimation.removedOnCompletion = NO;
    walkAnimation.fillMode = kCAFillModeForwards;
    
    [self.layer addAnimation:walkAnimation forKey:FWBarrageAnimation];
}

- (void)removeSubViewsAndSublayers {

}

#pragma mark ---- setter
- (void)setBarrageDescriptor:(FWBarrageDescriptor *)barrageDescriptor {
    [super setBarrageDescriptor:barrageDescriptor];
    self.gifDescriptor = (FWBarrageGifDescriptor *)barrageDescriptor;
}

#pragma mark ---- getter

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
    }
    return _imageView;
}

@end

@interface FWBarrageVerticalTextDescriptor : FWBarrageTextDescriptor

@end

@implementation FWBarrageVerticalTextDescriptor

@end

@interface FWBarrageVerticalAnimationCell : FWBarrageTextCell

@property (nonatomic, strong) FWBarrageVerticalTextDescriptor *verticalTextDescriptor;
@end

@implementation FWBarrageVerticalAnimationCell

- (void)addBarrageAnimationWithDelegate:(id<CAAnimationDelegate>)animationDelegate {
    if (!self.superview) {
        return;
    }
    
    CGPoint startCenter = CGPointMake(CGRectGetMidX(self.superview.bounds), -(CGRectGetHeight(self.bounds)/2));
    CGPoint endCenter = CGPointMake(CGRectGetMidX(self.superview.bounds), CGRectGetHeight(self.superview.bounds) + CGRectGetHeight(self.bounds)/2);
    
    CAKeyframeAnimation *walkAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    walkAnimation.values = @[[NSValue valueWithCGPoint:startCenter], [NSValue valueWithCGPoint:endCenter]];
    walkAnimation.keyTimes = @[@(0.0), @(1.0)];
    walkAnimation.duration = self.barrageDescriptor.animationDuration;
    walkAnimation.repeatCount = 1;
    walkAnimation.delegate =  animationDelegate;
    walkAnimation.removedOnCompletion = NO;
    walkAnimation.fillMode = kCAFillModeForwards;
    
    [self.layer addAnimation:walkAnimation forKey:FWBarrageAnimation];
}

#pragma mark ---- setter
- (void)setBarrageDescriptor:(FWBarrageDescriptor *)barrageDescriptor {
    [super setBarrageDescriptor:barrageDescriptor];
    self.verticalTextDescriptor = (FWBarrageVerticalTextDescriptor *)barrageDescriptor;
}

@end

@interface TestBarrageViewController ()

@property (nonatomic, strong) CATextLayer *textlayer;
@property (nonatomic, strong) FWBarrageManager *barrageManager;
@property (nonatomic, assign) int times;
@property (nonatomic, assign) int stopY;

@end

@implementation TestBarrageViewController

- (void)dealloc {
    NSLog(@"%s", __func__);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
    self.view.fwHeight = FWScreenHeight - FWTopBarHeight;
    self.barrageManager = [[FWBarrageManager alloc] init];
    [self.fwView addSubview:self.barrageManager.renderView];
    self.barrageManager.renderView.frame = CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height);
//    self.barrageManager.renderView.center = self.view.center;
    self.barrageManager.renderView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    self.view.backgroundColor = [Theme backgroundColor];
    
    CGFloat originY = CGRectGetHeight(self.view.frame) - 50.0;
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:@"开始" forState:UIControlStateNormal];
    [button setTitleColor:[Theme textColor] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(startBarrage) forControlEvents:UIControlEventTouchUpInside];
    button.frame= CGRectMake(0.0, originY, 50.0, 50.0);
    button.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.2];
    [self.fwView addSubview:button];
    
    UIButton *button2 = [UIButton buttonWithType:UIButtonTypeCustom];
    [button2 setTitle:@"暂停" forState:UIControlStateNormal];
    [button2 setTitleColor:[Theme textColor] forState:UIControlStateNormal];
    [button2 addTarget:self action:@selector(pasueBarrage) forControlEvents:UIControlEventTouchUpInside];
    button2.frame= CGRectMake(55.0, originY, 50.0, 50.0);
    button2.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.2];
    [self.fwView addSubview:button2];
    
    UIButton *button3 = [UIButton buttonWithType:UIButtonTypeCustom];
    [button3 setTitle:@"继续" forState:UIControlStateNormal];
    [button3 setTitleColor:[Theme textColor] forState:UIControlStateNormal];
    [button3 addTarget:self action:@selector(resumeBarrage) forControlEvents:UIControlEventTouchUpInside];
    button3.frame= CGRectMake(110.0, originY, 50.0, 50.0);
    button3.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.2];
    [self.fwView addSubview:button3];
    
    UIButton *button4 = [UIButton buttonWithType:UIButtonTypeCustom];
    [button4 setTitle:@"停止" forState:UIControlStateNormal];
    [button4 setTitleColor:[Theme textColor] forState:UIControlStateNormal];
    [button4 addTarget:self action:@selector(stopBarrage) forControlEvents:UIControlEventTouchUpInside];
    button4.frame= CGRectMake(165.0, originY, 50.0, 50.0);
    button4.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.2];
    [self.fwView addSubview:button4];
    
    [self.barrageManager start];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(addNormalBarrage) object:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(addFixedSpeedAnimationCell) object:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(addWalkBannerBarrage) object:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(addGifBarrage) object:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(addStopoverBarrage) object:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(addVerticalAnimationCell) object:nil];
}

- (void)addBarrage {
    [self performSelector:@selector(addNormalBarrage) withObject:nil afterDelay:0.5];
    [self performSelector:@selector(addFixedSpeedAnimationCell) withObject:nil afterDelay:0.5];//添加等速的弹幕, 等速弹幕速度相同不会重叠
    [self performSelector:@selector(addWalkBannerBarrage) withObject:nil afterDelay:0.5];
    [self performSelector:@selector(addStopoverBarrage) withObject:nil afterDelay:0.5];
    [self performSelector:@selector(addGifBarrage) withObject:nil afterDelay:0.5];
    [self performSelector:@selector(addVerticalAnimationCell) withObject:nil afterDelay:0.5];
}

- (void)addNormalBarrage {
    [self updateTitle];
    
    FWBarrageTextDescriptor *textDescriptor = [[FWBarrageTextDescriptor alloc] init];
    textDescriptor.text = [NSString stringWithFormat:@"~FWBarrage~"];
    textDescriptor.textColor = [Theme textColor];
    textDescriptor.positionPriority = FWBarragePositionLow;
    textDescriptor.textFont = [UIFont systemFontOfSize:17.0];
    textDescriptor.strokeColor = [[Theme textColor] colorWithAlphaComponent:0.3];
    textDescriptor.strokeWidth = -1;
    textDescriptor.animationDuration = arc4random()%5 + 5;
    textDescriptor.barrageCellClass = [FWBarrageTextCell class];
    
    [self.barrageManager renderBarrageDescriptor:textDescriptor];
    
    [self performSelector:@selector(addNormalBarrage) withObject:nil afterDelay:0.25];
}

- (void)addFixedSpeedAnimationCell {
    FWBarrageGradientBackgroundColorDescriptor *gradientBackgroundDescriptor = [[FWBarrageGradientBackgroundColorDescriptor alloc] init];
    gradientBackgroundDescriptor.text = [NSString stringWithFormat:@"~等速弹幕~"];
    gradientBackgroundDescriptor.textColor = [Theme textColor];
    gradientBackgroundDescriptor.positionPriority = FWBarragePositionLow;
    gradientBackgroundDescriptor.textFont = [UIFont systemFontOfSize:17.0];
    gradientBackgroundDescriptor.strokeColor = [[Theme textColor] colorWithAlphaComponent:0.3];
    gradientBackgroundDescriptor.strokeWidth = -1;
    gradientBackgroundDescriptor.fixedSpeed = 50.0;//用fixedSpeed属性设定速度
    gradientBackgroundDescriptor.barrageCellClass = [FWBarrageGradientBackgroundColorCell class];
    gradientBackgroundDescriptor.gradientColor = [UIColor fwRandomColor];
    
    [self.barrageManager renderBarrageDescriptor:gradientBackgroundDescriptor];
    
    [self performSelector:@selector(addFixedSpeedAnimationCell) withObject:nil afterDelay:0.5];
}

- (void)addWalkBannerBarrage {
    FWBarrageWalkBannerDescriptor *bannerDescriptor = [[FWBarrageWalkBannerDescriptor alloc] init];
    bannerDescriptor.cellTouchedAction = ^(FWBarrageDescriptor *__weak descriptor, FWBarrageCell *__weak cell) {
        FWIgnoredBegin();
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"FWBarrage" message:@"全民超人为您服务" delegate:nil cancelButtonTitle:@"朕知道了" otherButtonTitles:nil];
        [alertView show];
        FWIgnoredEnd();
        
        FWBarrageWalkBannerCell *walkBannerCell = (FWBarrageWalkBannerCell *)cell;
        walkBannerCell.textLabel.backgroundColor = [UIColor redColor];
    };
    
    bannerDescriptor.text = [NSString stringWithFormat:@"~欢迎全民超人大驾光临~"];
    bannerDescriptor.textColor = [Theme textColor];
    bannerDescriptor.textFont = [UIFont systemFontOfSize:17.0];
    bannerDescriptor.positionPriority = FWBarragePositionMiddle;
    bannerDescriptor.strokeColor = [[Theme textColor] colorWithAlphaComponent:0.3];
    bannerDescriptor.strokeWidth = -1;
    bannerDescriptor.animationDuration = arc4random()%5 + 5;
    bannerDescriptor.barrageCellClass = [FWBarrageWalkBannerCell class];
    [self.barrageManager renderBarrageDescriptor:bannerDescriptor];
    
    [self performSelector:@selector(addWalkBannerBarrage) withObject:nil afterDelay:1.0];
}

- (void)addStopoverBarrage {
    FWBarrageBecomeNobleDescriptor *becomeNobleDescriptor = [[FWBarrageBecomeNobleDescriptor alloc] init];
    NSMutableAttributedString *mAttributedString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"~FWBarrage~全民直播~荣誉出品~"]];
    [mAttributedString addAttribute:NSForegroundColorAttributeName value:[Theme textColor] range:NSMakeRange(0, mAttributedString.length)];
    [mAttributedString addAttribute:NSForegroundColorAttributeName value:[UIColor greenColor] range:NSMakeRange(1, 9)];
    [mAttributedString addAttribute:NSForegroundColorAttributeName value:[UIColor cyanColor] range:NSMakeRange(11, 4)];
    [mAttributedString addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:NSMakeRange(16, 4)];
    [mAttributedString addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:17.0] range:NSMakeRange(0, mAttributedString.length)];
    becomeNobleDescriptor.attributedText = mAttributedString;
    CGFloat bannerHeight = 185.0/2.0;
    CGFloat minOriginY = CGRectGetMidY(self.view.frame) - bannerHeight;
    CGFloat maxOriginY = CGRectGetMidY(self.view.frame) + bannerHeight;
    becomeNobleDescriptor.renderRange = NSMakeRange(minOriginY, maxOriginY);
    becomeNobleDescriptor.positionPriority = FWBarragePositionVeryHigh;
    becomeNobleDescriptor.animationDuration = 4.0;
    becomeNobleDescriptor.barrageCellClass = [FWBarrageBecomeNobleCell class];
    becomeNobleDescriptor.backgroundImage = [TestBundle imageNamed:@"qrcode_grid"];
    [self.barrageManager renderBarrageDescriptor:becomeNobleDescriptor];
    
    [self performSelector:@selector(addStopoverBarrage) withObject:nil afterDelay:4.0];
    
    if (self.stopY == 0) {
        self.stopY = bannerHeight;
    } else {
        self.stopY = 0;
    }
}

- (void)addVerticalAnimationCell {
    FWBarrageVerticalTextDescriptor *verticalTextDescriptor = [[FWBarrageVerticalTextDescriptor alloc] init];
    verticalTextDescriptor.text = [NSString stringWithFormat:@"~从上往下的动画~"];
    verticalTextDescriptor.textColor = [Theme textColor];
    verticalTextDescriptor.positionPriority = FWBarragePositionLow;
    verticalTextDescriptor.textFont = [UIFont systemFontOfSize:17.0];
    verticalTextDescriptor.strokeColor = [[Theme textColor] colorWithAlphaComponent:0.3];
    verticalTextDescriptor.strokeWidth = -1;
    verticalTextDescriptor.animationDuration = 5;
    verticalTextDescriptor.barrageCellClass = [FWBarrageVerticalAnimationCell class];
    
    [self.barrageManager renderBarrageDescriptor:verticalTextDescriptor];
    
    [self performSelector:@selector(addVerticalAnimationCell) withObject:nil afterDelay:0.5];
}

- (void)addGifBarrage {
    FWBarrageGifDescriptor *gifDescriptor = [[FWBarrageGifDescriptor alloc] init];
    
    UIImage *image = [TestBundle imageNamed:@"test.gif"];
    gifDescriptor.image = image;
    gifDescriptor.positionPriority = FWBarragePositionHigh;
    gifDescriptor.animationDuration = arc4random()%5 + 5;
    gifDescriptor.barrageCellClass = [FWBarrageGifCell class];
    [self.barrageManager renderBarrageDescriptor:gifDescriptor];
    
    [self performSelector:@selector(addGifBarrage) withObject:nil afterDelay:3.0];
}

- (void)startBarrage {
    [self.barrageManager start];
    [self addBarrage];
}

- (void)updateTitle {
    NSInteger barrageCount = self.barrageManager.renderView.animatingCells.count;
    self.fwNavigationItem.title = [NSString stringWithFormat:@"现在有 %ld 条弹幕", (unsigned long)barrageCount];
}

- (void)pasueBarrage {
    [self.barrageManager pause];
}

- (void)resumeBarrage {
    [self.barrageManager resume];
}

- (void)stopBarrage {
    [self.barrageManager stop];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(addBarrage) object:nil];
}

@end
