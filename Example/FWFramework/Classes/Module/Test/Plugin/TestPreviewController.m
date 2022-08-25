//
//  TestPreviewController.m
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/25.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

#import "TestPreviewController.h"
#import "AppSwift.h"
@import FWFramework;

@interface TestPreviewController () <FWViewController, FWImagePreviewViewDelegate>

@property(nonatomic, assign) BOOL usePlugin;
@property(nonatomic, strong) FWImagePreviewController *imagePreviewViewController;
@property(nonatomic, strong) NSArray *images;
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

@implementation TestPreviewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.images = @[
            [UIImage fw_appIconImage],
            [FWModuleBundle imageNamed:@"Animation.png"],
            @"http://via.placeholder.com/100x2000.jpg",
            @"http://via.placeholder.com/2000x100.jpg",
            @"http://via.placeholder.com/2000x2000.jpg",
            @"http://via.placeholder.com/100x100.jpg",
            @"http://vfx.mtime.cn/Video/2019/02/04/mp4/190204084208765161.mp4"
        ];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.dismissTappedImage = YES;
    self.dismissTappedVideo = YES;
    
    FWWeakifySelf();
    [self fw_setRightBarItem:@(UIBarButtonSystemItemRefresh) block:^(id  _Nonnull sender) {
        FWStrongifySelf();
        NSString *pluginText = self.usePlugin ? @"不使用插件" : @"使用插件";
        NSString *progressText = self.mockProgress ? @"关闭进度" : @"开启进度";
        NSString *fadeText = self.previewFade ? @"关闭渐变效果" : @"开启渐变效果";
        NSString *toolbarText = self.showsToolbar ? @"隐藏视频工具栏" : @"开启视频工具栏";
        NSString *autoText = self.autoplayVideo ? @"关闭自动播放" : @"开启自动播放";
        NSString *dismissImageText = self.dismissTappedImage ? @"单击图片时不关闭" : @"单击图片时自动关闭";
        NSString *dismissVideoText = self.dismissTappedVideo ? @"单击视频时不关闭" : @"单击视频时自动关闭";
        NSString *closeText = self.showsClose ? @"隐藏视频关闭按钮" : @"开启视频关闭按钮";
        [self fw_showSheetWithTitle:nil message:nil cancel:@"取消" actions:@[pluginText, progressText, fadeText, toolbarText, autoText, dismissImageText, dismissVideoText, closeText] actionBlock:^(NSInteger index) {
            FWStrongifySelf();
            if (index == 0) {
                self.usePlugin = !self.usePlugin;
            } else if (index == 1) {
                self.mockProgress = !self.mockProgress;
            } else if (index == 2) {
                self.previewFade = !self.previewFade;
            } else if (index == 3) {
                self.showsToolbar = !self.showsToolbar;
            } else if (index == 4) {
                self.autoplayVideo = !self.autoplayVideo;
            } else if (index == 5) {
                self.dismissTappedImage = !self.dismissTappedImage;
            } else if (index == 6) {
                self.dismissTappedVideo = !self.dismissTappedVideo;
            } else if (index == 7) {
                self.showsClose = !self.showsClose;
            }
        }];
    }];
    
    self.floatLayoutView = [[FWFloatLayoutView alloc] init];
    self.floatLayoutView.itemMargins = UIEdgeInsetsMake(UIScreen.fw_pixelOne, UIScreen.fw_pixelOne, 0, 0);
    for (id image in self.images) {
        UIButton *button = [[UIButton alloc] init];
        button.imageView.contentMode = UIViewContentModeScaleAspectFill;
        if ([image isKindOfClass:[UIImage class]]) {
            [button setImage:image forState:UIControlStateNormal];
        } else if ([image isKindOfClass:[NSString class]]) {
            NSString *imageUrl = (NSString *)image;
            if ([image hasSuffix:@".mp4"]) {
                [button setImage:[UIImage fw_appIconImage] forState:UIControlStateNormal];
            } else {
                [UIImage fw_downloadImage:imageUrl completion:^(UIImage * _Nullable image, NSError * _Nullable error) {
                    [button setImage:image ?: [UIImage fw_appIconImage] forState:UIControlStateNormal];
                } progress:nil];
            }
        }
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
    
    UIEdgeInsets margins = UIEdgeInsetsMake(24 + self.fw_topBarHeight, 24 + self.view.safeAreaInsets.left, 24, 24 + self.view.safeAreaInsets.right);
    CGFloat contentWidth = self.view.fw_width - (margins.left + margins.right);
    NSInteger column = FWIsIpad || FWIsLandscape ? self.images.count : 3;
    CGFloat imageWidth = contentWidth / column - (column - 1) * (self.floatLayoutView.itemMargins.left + self.floatLayoutView.itemMargins.right);
    self.floatLayoutView.minimumItemSize = CGSizeMake(imageWidth, imageWidth);
    self.floatLayoutView.maximumItemSize = self.floatLayoutView.minimumItemSize;
    self.floatLayoutView.frame = CGRectMake(margins.left, margins.top, contentWidth, [self.floatLayoutView sizeThatFits:CGSizeMake(contentWidth, CGFLOAT_MAX)].height);
    
    self.tipsLabel.frame = CGRectMake(margins.left, CGRectGetMaxY(self.floatLayoutView.frame) + 16, contentWidth, [self.tipsLabel sizeThatFits:CGSizeMake(contentWidth, CGFLOAT_MAX)].height);
}

- (void)handleImageButtonEvent:(UIButton *)button {
    if (self.usePlugin) {
        NSInteger buttonIndex = [self.floatLayoutView.subviews indexOfObject:button];
        __weak __typeof(self) weakSelf = self;
        [self fw_showImagePreviewWithImageURLs:self.images imageInfos:nil currentIndex:buttonIndex sourceView:^id _Nullable(NSInteger index) {
            return weakSelf.floatLayoutView.subviews[index];
        }];
        return;
    }
    
    if (!self.imagePreviewViewController) {
        self.imagePreviewViewController = [[FWImagePreviewController alloc] init];
        self.imagePreviewViewController.showsPageLabel = YES;
        self.imagePreviewViewController.imagePreviewView.delegate = self;
        __weak __typeof(self) weakSelf = self;
        self.imagePreviewViewController.sourceImageView = ^UIView *(NSInteger index) {
            return weakSelf.floatLayoutView.subviews[index];
        };
        self.imagePreviewViewController.imagePreviewView.customZoomContentView = ^(FWZoomImageView * _Nonnull zoomImageView, __kindof UIView * _Nonnull contentView) {
            UIImageView *imageView = (UIImageView *)contentView;
            if (![imageView isKindOfClass:[UIImageView class]]) return;
            
            UILabel *tipLabel = [imageView viewWithTag:102];
            if (!tipLabel) {
                tipLabel = [UILabel new];
                tipLabel.tag = 102;
                tipLabel.fw_contentInset = UIEdgeInsetsMake(2, 8, 2, 8);
                [tipLabel fw_setCornerRadius:FWFontRegular(12).lineHeight / 2 + 2];
                tipLabel.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.5];
                tipLabel.text = @"图片仅供参考";
                tipLabel.font = FWFontRegular(12);
                tipLabel.textColor = [UIColor whiteColor];
                [imageView addSubview:tipLabel];
                
                // 图片仅供参考缩放后始终在图片右下角显示，显示不下就隐藏
                [tipLabel sizeToFit];
                CGFloat labelScale = 1.0 / zoomImageView.scrollView.zoomScale;
                tipLabel.transform = CGAffineTransformMakeScale(labelScale, labelScale);
                CGSize imageSize = zoomImageView.image.size;
                CGSize labelSize = tipLabel.frame.size;
                tipLabel.fw_origin = CGPointMake(imageSize.width - 16 * labelScale - labelSize.width, imageSize.height - 16 * labelScale - labelSize.height);
                tipLabel.hidden = tipLabel.fw_y < 0;
            }
        };
        
        self.imagePreviewViewController.fw_visibleStateChanged = ^(FWImagePreviewController *viewController, FWViewControllerVisibleState visibleState) {
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
    // 强制宽度缩放模式
    zoomImageView.contentMode = UIViewContentModeScaleToFill;
    zoomImageView.reusedIdentifier = @(index);
    zoomImageView.showsVideoToolbar = self.showsToolbar;
    zoomImageView.showsVideoCloseButton = self.showsClose;
    
    if (self.mockProgress) {
        FWWeakifySelf();
        [TestController mockProgress:^(double progress, BOOL finished) {
            FWStrongifySelf();
            if (zoomImageView.reusedIdentifier.fw_safeInteger != index) return;
            
            zoomImageView.progress = progress;
            if (finished) {
                [zoomImageView setImageURL:self.images[index]];
            }
        }];
    } else {
        [zoomImageView setImageURL:self.images[index]];
    }
}

- (FWImagePreviewMediaType)imagePreviewView:(FWImagePreviewView *)imagePreviewView assetTypeAtIndex:(NSInteger)index {
    return FWImagePreviewMediaTypeImage;
}

@end
