//
//  TestImagePreviewViewController.m
//  Example
//
//  Created by wuyong on 2018/11/29.
//  Copyright © 2018 wuyong.site. All rights reserved.
//

#import "TestImagePreviewViewController.h"

@interface TestImagePreviewViewController () <FWImagePreviewViewDelegate>

@property(nonatomic, strong) FWImagePreviewViewController *imagePreviewViewController;
@property(nonatomic, strong) NSArray<UIImage *> *images;
@property(nonatomic, strong) FWFloatLayoutView *floatLayoutView;
@property(nonatomic, strong) UILabel *tipsLabel;

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
        self.imagePreviewViewController = [[FWImagePreviewViewController alloc] init];
        self.imagePreviewViewController.imagePreviewView.loadingColor = UIColor.whiteColor;
        self.imagePreviewViewController.presentingStyle = FWImagePreviewTransitioningStyleZoom;// 将 present 动画改为 zoom，也即从某个位置放大到屏幕中央。默认样式为 fade。
        self.imagePreviewViewController.imagePreviewView.delegate = self;// 将内部的图片查看器 delegate 指向当前 viewController，以获取要查看的图片数据
        
        // 当需要在退出大图预览时做一些事情的时候，可配合 UIViewController (FW) 的 qmui_visibleStateDidChangeBlock 来实现。
        __weak __typeof(self)weakSelf = self;
        self.imagePreviewViewController.fwVisibleStateChanged = ^(FWImagePreviewViewController *viewController, FWViewControllerVisibleState visibleState) {
            if (visibleState == FWViewControllerVisibleStateWillDisappear) {
                NSInteger exitAtIndex = viewController.imagePreviewView.currentImageIndex;
                weakSelf.tipsLabel.text = [NSString stringWithFormat:@"浏览到第%@张就退出了", @(exitAtIndex + 1)];
            }
        };
    }
    
    NSInteger buttonIndex = [self.floatLayoutView.subviews indexOfObject:button];
    self.imagePreviewViewController.imagePreviewView.currentImageIndex = buttonIndex;// 默认展示的图片 index
    
    // 如果使用 zoom 动画，则需要在 sourceImageView 里返回一个 UIView，由这个 UIView 的布局位置决定动画的起点/终点，如果用 fade 则不需要使用 sourceImageView。
    // 另外当 sourceImageView 返回 nil 时会强制使用 fade 动画，常见的使用场景是 present 时 sourceImageView 还在屏幕内，但 dismiss 时 sourceImageView 已经不在可视区域，即可通过返回 nil 来改用 fade 动画。
    self.imagePreviewViewController.sourceImageView = ^UIView *{
        return button;
    };
    
    [self presentViewController:self.imagePreviewViewController animated:YES completion:nil];
}

#pragma mark - <FWImagePreviewViewDelegate>

- (NSUInteger)numberOfImagesInImagePreviewView:(FWImagePreviewView *)imagePreviewView {
    return self.images.count;
}

- (void)imagePreviewView:(FWImagePreviewView *)imagePreviewView renderZoomImageView:(FWZoomImageView *)zoomImageView atIndex:(NSUInteger)index {
    zoomImageView.reusedIdentifier = @(index);
    
    // 模拟异步加载的情况
    if (index == 2) {
        [zoomImageView fwShowEmptyViewLoading];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if ([zoomImageView.reusedIdentifier isEqual:@(index)]) {
                [zoomImageView fwHideEmptyView];
                zoomImageView.image = self.images[index];
            }
        });
    // 模拟进度的情况
    } else if (index == 3) {
        FWWeakifySelf();
        [self mockProgress:^(double progress, BOOL finished) {
            FWStrongifySelf();
            zoomImageView.progress = progress;
            if (finished) {
                zoomImageView.image = self.images[index];
            }
        }];
    } else if (index == 5) {
        NSURL *url = [NSURL fwURLWithString:@"http://vfx.mtime.cn/Video/2019/02/04/mp4/190204084208765161.mp4"];
        zoomImageView.videoPlayerItem = [AVPlayerItem playerItemWithURL:url];
    } else {
        zoomImageView.image = self.images[index];
    }
}

- (FWImagePreviewMediaType)imagePreviewView:(FWImagePreviewView *)imagePreviewView assetTypeAtIndex:(NSUInteger)index {
    return FWImagePreviewMediaTypeImage;
}

- (void)imagePreviewView:(FWImagePreviewView *)imagePreviewView didScrollToIndex:(NSUInteger)index {
    // 由于进入大图查看模式后可以左右滚动切换图片，最终退出时要退出到当前大图所对应的小图那，所以需要在适当的时机（这里选择 imagePreviewView:didScrollToIndex:）更新 sourceImageView 的值
    __weak __typeof(self)weakSelf = self;
    self.imagePreviewViewController.sourceImageView = ^UIView *{
        return weakSelf.floatLayoutView.subviews[index];
    };
}

#pragma mark - <FWZoomImageViewDelegate>

- (void)singleTouchInZoomingImageView:(FWZoomImageView *)zoomImageView location:(CGPoint)location {
    if (zoomImageView.videoPlayerItem != nil) return;
    // 退出图片预览
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)doubleTouchInZoomingImageView:(FWZoomImageView *)zoomImageView location:(CGPoint)location {
    if (zoomImageView.videoPlayerItem == nil) return;
    // 退出图片预览
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
