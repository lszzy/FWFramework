//
//  TestImagePreviewViewController.m
//  Example
//
//  Created by wuyong on 2018/11/29.
//  Copyright © 2018 wuyong.site. All rights reserved.
//

#import "TestImagePreviewViewController.h"

@interface TestImagePreviewViewController () <FWImagePreviewViewDelegate>

@property(nonatomic, strong) FWImagePreviewController *imagePreviewViewController;
@property(nonatomic, strong) NSArray<UIImage *> *images;
@property(nonatomic, strong) FWFloatLayoutView *floatLayoutView;
@property(nonatomic, strong) UILabel *tipsLabel;
@property(nonatomic, assign) BOOL mockProgress;
@property(nonatomic, assign) BOOL previewFade;
@property(nonatomic, assign) BOOL showsToolbar;
@property(nonatomic, assign) BOOL showsClose;
@property(nonatomic, assign) BOOL autoplayVideo;
@property(nonatomic, assign) BOOL dismissTappedImage;
@property(nonatomic, assign) BOOL dismissTappedVideo;

@end

@implementation TestImagePreviewViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        
        self.images = @[[TestBundle imageNamed:@"public_face"],
                        [TestBundle imageNamed:@"animation.png"],
                        [TestBundle imageNamed:@"public_picture"],
                        [TestBundle imageNamed:@"public_sunset"],
                        [TestBundle imageNamed:@"public_test"],
                        [TestBundle imageNamed:@"progressive.jpg"]];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.dismissTappedImage = YES;
    self.dismissTappedVideo = YES;
    
    FWWeakifySelf();
    [self fwSetRightBarItem:FWIcon.refreshImage block:^(id  _Nonnull sender) {
        FWStrongifySelf();
        NSString *progressText = self.mockProgress ? @"关闭进度" : @"开启进度";
        NSString *fadeText = self.previewFade ? @"关闭渐变效果" : @"开启渐变效果";
        NSString *toolbarText = self.showsToolbar ? @"隐藏视频工具栏" : @"开启视频工具栏";
        NSString *autoText = self.autoplayVideo ? @"关闭自动播放" : @"开启自动播放";
        NSString *dismissImageText = self.dismissTappedImage ? @"单击图片时不关闭" : @"单击图片时自动关闭";
        NSString *dismissVideoText = self.dismissTappedVideo ? @"单击视频时不关闭" : @"单击视频时自动关闭";
        NSString *closeText = self.showsClose ? @"隐藏视频关闭按钮" : @"开启视频关闭按钮";
        [self fwShowSheetWithTitle:nil message:nil cancel:@"取消" actions:@[progressText, fadeText, toolbarText, autoText, dismissImageText, dismissVideoText, closeText] actionBlock:^(NSInteger index) {
            FWStrongifySelf();
            if (index == 0) {
                self.mockProgress = !self.mockProgress;
            } else if (index == 1) {
                self.previewFade = !self.previewFade;
            } else if (index == 2) {
                self.showsToolbar = !self.showsToolbar;
            } else if (index == 3) {
                self.autoplayVideo = !self.autoplayVideo;
            } else if (index == 4) {
                self.dismissTappedImage = !self.dismissTappedImage;
            } else if (index == 5) {
                self.dismissTappedVideo = !self.dismissTappedVideo;
            } else if (index == 6) {
                self.showsClose = !self.showsClose;
            }
        }];
    }];
    
    self.floatLayoutView = [[FWFloatLayoutView alloc] init];
    self.floatLayoutView.itemMargins = UIEdgeInsetsMake(UIScreen.fwPixelOne, UIScreen.fwPixelOne, 0, 0);
    for (UIImage *image in self.images) {
        UIButton *button = [[UIButton alloc] init];
        button.imageView.contentMode = UIViewContentModeScaleAspectFill;
        [button setImage:image forState:UIControlStateNormal];
        [button addTarget:self action:@selector(handleImageButtonEvent:) forControlEvents:UIControlEventTouchUpInside];
        [self.floatLayoutView addSubview:button];
    }
    [self.view addSubview:self.floatLayoutView];
    
    self.tipsLabel = [[UILabel alloc] init];
    self.tipsLabel.font = FWFontRegular(12);
    self.tipsLabel.textColor = UIColor.darkTextColor;
    self.tipsLabel.textAlignment = NSTextAlignmentCenter;
    self.tipsLabel.numberOfLines = 0;
    self.tipsLabel.text = @"点击图片后可左右滑动，期间也可尝试横竖屏";
    [self.view addSubview:self.tipsLabel];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    UIEdgeInsets margins = UIEdgeInsetsMake(24 + self.fwTopBarHeight, 24 + self.view.fwSafeAreaInsets.left, 24, 24 + self.view.fwSafeAreaInsets.right);
    CGFloat contentWidth = self.view.fwWidth - (margins.left + margins.right);
    NSInteger column = FWIsIpad || FWIsLandscape ? self.images.count : 3;
    CGFloat imageWidth = contentWidth / column - (column - 1) * (self.floatLayoutView.itemMargins.left + self.floatLayoutView.itemMargins.right);
    self.floatLayoutView.minimumItemSize = CGSizeMake(imageWidth, imageWidth);
    self.floatLayoutView.maximumItemSize = self.floatLayoutView.minimumItemSize;
    self.floatLayoutView.frame = CGRectMake(margins.left, margins.top, contentWidth, [self.floatLayoutView sizeThatFits:CGSizeMake(contentWidth, CGFLOAT_MAX)].height);
    
    self.tipsLabel.frame = CGRectMake(margins.left, CGRectGetMaxY(self.floatLayoutView.frame) + 16, contentWidth, [self.tipsLabel sizeThatFits:CGSizeMake(contentWidth, CGFLOAT_MAX)].height);
}

- (void)handleImageButtonEvent:(UIButton *)button {
    if (!self.imagePreviewViewController) {
        self.imagePreviewViewController = [[FWImagePreviewController alloc] init];
        self.imagePreviewViewController.showsPageLabel = YES;
        self.imagePreviewViewController.imagePreviewView.delegate = self;
        __weak __typeof(self) weakSelf = self;
        self.imagePreviewViewController.sourceImageView = ^UIView *(NSInteger index) {
            return weakSelf.floatLayoutView.subviews[index];
        };
        
        self.imagePreviewViewController.fwVisibleStateChanged = ^(FWImagePreviewController *viewController, FWViewControllerVisibleState visibleState) {
            if (visibleState == FWViewControllerVisibleStateWillDisappear) {
                NSInteger exitAtIndex = viewController.imagePreviewView.currentImageIndex;
                weakSelf.tipsLabel.text = [NSString stringWithFormat:@"浏览到第%@张就退出了", @(exitAtIndex + 1)];
            }
        };
    }
    
    self.imagePreviewViewController.dismissingWhenTappedImage = self.dismissTappedImage;
    self.imagePreviewViewController.dismissingWhenTappedVideo = self.dismissTappedVideo;
    self.imagePreviewViewController.imagePreviewView.autoplayVideo = self.autoplayVideo;
    self.imagePreviewViewController.presentingStyle = self.previewFade ? FWImagePreviewTransitioningStyleFade : FWImagePreviewTransitioningStyleZoom;
    NSInteger buttonIndex = [self.floatLayoutView.subviews indexOfObject:button];
    self.imagePreviewViewController.imagePreviewView.currentImageIndex = buttonIndex;// 默认展示的图片 index
    [self presentViewController:self.imagePreviewViewController animated:YES completion:nil];
}

#pragma mark - <FWImagePreviewViewDelegate>

- (NSInteger)numberOfImagesInImagePreviewView:(FWImagePreviewView *)imagePreviewView {
    return self.images.count;
}

- (void)imagePreviewView:(FWImagePreviewView *)imagePreviewView renderZoomImageView:(FWZoomImageView *)zoomImageView atIndex:(NSInteger)index {
    zoomImageView.reusedIdentifier = @(index);
    zoomImageView.showsVideoToolbar = self.showsToolbar;
    zoomImageView.showsVideoCloseButton = self.showsClose;
    
    if (self.mockProgress) {
        FWWeakifySelf();
        [self mockProgress:^(double progress, BOOL finished) {
            FWStrongifySelf();
            if (zoomImageView.reusedIdentifier.fwAsInteger != index) return;
            
            zoomImageView.progress = progress;
            if (finished) {
                if (index == 5) {
                    NSURL *url = [NSURL fwURLWithString:@"http://vfx.mtime.cn/Video/2019/02/04/mp4/190204084208765161.mp4"];
                    zoomImageView.videoPlayerItem = [AVPlayerItem playerItemWithURL:url];
                } else {
                    zoomImageView.image = self.images[index];
                }
            }
        }];
    } else {
        if (index == 5) {
            NSURL *url = [NSURL fwURLWithString:@"http://vfx.mtime.cn/Video/2019/02/04/mp4/190204084208765161.mp4"];
            zoomImageView.videoPlayerItem = [AVPlayerItem playerItemWithURL:url];
        } else {
            zoomImageView.image = self.images[index];
        }
    }
}

- (FWImagePreviewMediaType)imagePreviewView:(FWImagePreviewView *)imagePreviewView assetTypeAtIndex:(NSInteger)index {
    return FWImagePreviewMediaTypeImage;
}

@end
