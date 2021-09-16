//
//  TestImagePickerViewController.m
//  Example
//
//  Created by wuyong on 2018/11/29.
//  Copyright © 2018 wuyong.site. All rights reserved.
//

#import "TestImagePickerViewController.h"

@class QDMultipleImagePickerPreviewViewController;

@protocol QDMultipleImagePickerPreviewViewControllerDelegate <FWImagePickerPreviewControllerDelegate>

@required
- (void)imagePickerPreviewController:(QDMultipleImagePickerPreviewViewController *)imagePickerPreviewController sendImageWithImagesAssetArray:(NSMutableArray<FWAsset *> *)imagesAssetArray;

@end

@interface QDMultipleImagePickerPreviewViewController : FWImagePickerPreviewController

@property(nonatomic, weak) id<QDMultipleImagePickerPreviewViewControllerDelegate> delegate;
@property(nonatomic, strong) UILabel *imageCountLabel;
@property(nonatomic, strong) FWAssetGroup *assetsGroup;
@property(nonatomic, assign) BOOL shouldUseOriginImage;

@end

#define ImageCountLabelSize CGSizeMake(18, 18)

@interface QDMultipleImagePickerPreviewViewController ()

@property(nonatomic, strong) UIButton *sendButton;
@property(nonatomic, strong) UIButton *originImageCheckboxButton;
@property(nonatomic, strong) UIView *bottomToolBarView;

@end

@implementation QDMultipleImagePickerPreviewViewController

@dynamic delegate;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.bottomToolBarView = [[UIView alloc] init];
    self.bottomToolBarView.backgroundColor = self.toolBarBackgroundColor;
    [self.view addSubview:self.bottomToolBarView];
    
    self.sendButton = [[UIButton alloc] init];
    self.sendButton.fwTouchInsets = UIEdgeInsetsMake(6, 6, 6, 6);
    [self.sendButton setTitle:@"发送" forState:UIControlStateNormal];
    self.sendButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [self.sendButton sizeToFit];
    [self.sendButton addTarget:self action:@selector(handleSendButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomToolBarView addSubview:self.sendButton];
    
    _imageCountLabel = [[UILabel alloc] init];
    _imageCountLabel.backgroundColor = self.toolBarTintColor;
    _imageCountLabel.textColor = UIColor.redColor;
    _imageCountLabel.font = [UIFont systemFontOfSize:12];
    _imageCountLabel.textAlignment = NSTextAlignmentCenter;
    _imageCountLabel.lineBreakMode = NSLineBreakByCharWrapping;
    _imageCountLabel.layer.masksToBounds = YES;
    _imageCountLabel.layer.cornerRadius = ImageCountLabelSize.width / 2;
    _imageCountLabel.hidden = YES;
    [self.bottomToolBarView addSubview:_imageCountLabel];
    
    self.originImageCheckboxButton = [[UIButton alloc] init];
    self.originImageCheckboxButton.titleLabel.font = [UIFont systemFontOfSize:14];
    [self.originImageCheckboxButton setImage:[UIImage fwImageWithColor:[UIColor redColor] size:CGSizeMake(20, 20)] forState:UIControlStateNormal];
    [self.originImageCheckboxButton setImage:[UIImage fwImageWithColor:[UIColor brownColor] size:CGSizeMake(20, 20)] forState:UIControlStateSelected];
    [self.originImageCheckboxButton setImage:[UIImage fwImageWithColor:[UIColor brownColor] size:CGSizeMake(20, 20)] forState:UIControlStateSelected|UIControlStateHighlighted];
    [self.originImageCheckboxButton setTitle:@"原图" forState:UIControlStateNormal];
    [self.originImageCheckboxButton setImageEdgeInsets:UIEdgeInsetsMake(0, -5.0f, 0, 5.0f)];
    [self.originImageCheckboxButton setContentEdgeInsets:UIEdgeInsetsMake(0, 5.0f, 0, 0)];
    [self.originImageCheckboxButton sizeToFit];
    self.originImageCheckboxButton.fwTouchInsets = UIEdgeInsetsMake(6.0f, 6.0f, 6.0f, 6.0f);
    [self.originImageCheckboxButton addTarget:self action:@selector(handleOriginImageCheckboxButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomToolBarView addSubview:self.originImageCheckboxButton];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateOriginImageCheckboxButtonWithIndex:self.imagePreviewView.currentImageIndex];
    if ([self.selectedImageAssetArray count] > 0) {
        NSUInteger selectedCount = [self.selectedImageAssetArray count];
        _imageCountLabel.text = [[NSString alloc] initWithFormat:@"%@", @(selectedCount)];
        _imageCountLabel.hidden = NO;
    } else {
        _imageCountLabel.hidden = YES;
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat bottomToolBarPaddingHorizontal = 12.0f;
    CGFloat bottomToolBarContentHeight = 44;
    CGFloat bottomToolBarHeight = bottomToolBarContentHeight + self.view.fwSafeAreaInsets.bottom;
    self.bottomToolBarView.frame = CGRectMake(0, CGRectGetHeight(self.view.bounds) - bottomToolBarHeight, CGRectGetWidth(self.view.bounds), bottomToolBarHeight);
    self.sendButton.fwOrigin = CGPointMake(CGRectGetWidth(self.bottomToolBarView.frame) - bottomToolBarPaddingHorizontal - CGRectGetWidth(self.sendButton.frame), (bottomToolBarContentHeight - CGRectGetHeight(self.sendButton.frame)) / 2.0);
    _imageCountLabel.frame = CGRectMake(CGRectGetMinX(self.sendButton.frame) - 5 - ImageCountLabelSize.width, CGRectGetMinY(self.sendButton.frame) + (CGRectGetHeight(self.sendButton.frame) - ImageCountLabelSize.height) / 2.0, ImageCountLabelSize.width, ImageCountLabelSize.height);
    self.originImageCheckboxButton.fwOrigin = CGPointMake(bottomToolBarPaddingHorizontal, (bottomToolBarContentHeight - CGRectGetHeight(self.originImageCheckboxButton.frame)) / 2.0);
}

- (void)setToolBarTintColor:(UIColor *)toolBarTintColor {
    [super setToolBarTintColor:toolBarTintColor];
    self.bottomToolBarView.tintColor = toolBarTintColor;
    _imageCountLabel.backgroundColor = toolBarTintColor;
    _imageCountLabel.textColor = [UIColor redColor];
}

- (void)singleTouchInZoomingImageView:(FWZoomImageView *)zoomImageView location:(CGPoint)location {
    [super singleTouchInZoomingImageView:zoomImageView location:location];
    self.bottomToolBarView.hidden = !self.bottomToolBarView.hidden;
}

- (void)zoomImageView:(FWZoomImageView *)imageView didHideVideoToolbar:(BOOL)didHide {
    [super zoomImageView:imageView didHideVideoToolbar:didHide];
    self.bottomToolBarView.hidden = didHide;
}

- (void)handleSendButtonClick:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:^(void) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(imagePickerPreviewController:sendImageWithImagesAssetArray:)]) {
            if (self.selectedImageAssetArray.count == 0) {
                // 如果没选中任何一张，则点击发送按钮直接发送当前这张大图
                FWAsset *currentAsset = self.imagesAssetArray[self.imagePreviewView.currentImageIndex];
                [self.selectedImageAssetArray addObject:currentAsset];
            }
            [self.delegate imagePickerPreviewController:self sendImageWithImagesAssetArray:self.selectedImageAssetArray];
        }
    }];
}

- (void)handleOriginImageCheckboxButtonClick:(UIButton *)button {
    if (button.selected) {
        button.selected = NO;
        [button setTitle:@"原图" forState:UIControlStateNormal];
        [button sizeToFit];
        [self.bottomToolBarView setNeedsLayout];
    } else {
        button.selected = YES;
        [self updateOriginImageCheckboxButtonWithIndex:self.imagePreviewView.currentImageIndex];
        if (!self.checkboxButton.selected) {
            [self.checkboxButton sendActionsForControlEvents:UIControlEventTouchUpInside];
        }

    }
    self.shouldUseOriginImage = button.selected;
}

- (void)updateOriginImageCheckboxButtonWithIndex:(NSInteger)index {
    FWAsset *asset = self.imagesAssetArray[index];
    if (asset.assetType == FWAssetTypeAudio || asset.assetType == FWAssetTypeVideo) {
        self.originImageCheckboxButton.hidden = YES;
    } else {
        self.originImageCheckboxButton.hidden = NO;
        if (self.originImageCheckboxButton.selected) {
            [asset assetSize:^(long long size) {
                [self.originImageCheckboxButton setTitle:[NSString stringWithFormat:@"原图(%@)", [NSString fwSizeString:size]] forState:UIControlStateNormal];
                [self.originImageCheckboxButton sizeToFit];
                [self.bottomToolBarView setNeedsLayout];
            }];
        }
    }
}

#pragma mark - <FWImagePreviewViewDelegate>

- (void)imagePreviewView:(FWImagePreviewView *)imagePreviewView renderZoomImageView:(FWZoomImageView *)zoomImageView atIndex:(NSInteger)index {
    [super imagePreviewView:imagePreviewView renderZoomImageView:zoomImageView atIndex:index];
    UIEdgeInsets insets = zoomImageView.videoToolbarMargins;
    insets.bottom = [FWZoomImageView appearance].videoToolbarMargins.bottom + CGRectGetHeight(self.bottomToolBarView.frame) - imagePreviewView.fwSafeAreaInsets.bottom;
    zoomImageView.videoToolbarMargins = insets;// videToolbarMargins 是利用 UIAppearance 赋值的，也即意味着要在 addSubview 之后才会被赋值，而在 renderZoomImageView 里，zoomImageView 可能尚未被添加到 view 层级里，所以无法通过 zoomImageView.videoToolbarMargins 获取到原来的值，因此只能通过 [FWZoomImageView appearance] 的方式获取
}

- (void)imagePreviewView:(FWImagePreviewView *)imagePreviewView willScrollHalfToIndex:(NSInteger)index {
    [super imagePreviewView:imagePreviewView willScrollHalfToIndex:index];
    [self updateOriginImageCheckboxButtonWithIndex:index];
}

@end

#define MaxSelectedImageCount 9
#define NormalImagePickingTag 1045
#define ModifiedImagePickingTag 1046
#define MultipleImagePickingTag 1047

static FWAlbumContentType const kAlbumContentType = FWAlbumContentTypeAll;

@interface TestImagePickerViewController () <FWTableViewController, FWImageAlbumControllerDelegate, FWImagePickerControllerDelegate, QDMultipleImagePickerPreviewViewControllerDelegate>

@property(nonatomic, strong) UIImage *selectedAvatarImage;

@end

@implementation TestImagePickerViewController

- (void)renderData {
    [self.tableData addObjectsFromArray:@[
        @"选择多张图片",
        @"调整界面",
        @"测试",
    ]];
}

- (void)authorizationPresentAlbumViewControllerWithTitle:(NSString *)title {
    if ([FWAssetManager authorizationStatus] == FWAssetAuthorizationStatusNotDetermined) {
        [FWAssetManager requestAuthorization:^(FWAssetAuthorizationStatus status) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self presentAlbumViewControllerWithTitle:title];
            });
        }];
    } else {
        [self presentAlbumViewControllerWithTitle:title];
    }
}

- (void)presentAlbumViewControllerWithTitle:(NSString *)title {
    
    // 创建一个 QMUIAlbumViewController 实例用于呈现相簿列表
    FWImageAlbumController *albumController = [[FWImageAlbumController alloc] init];
    albumController.fwNavigationBarStyle = FWNavigationBarStyleDefault;
    albumController.fwBackBarItem = FWIcon.backImage;
    albumController.albumControllerDelegate = self;
    albumController.contentType = kAlbumContentType;
    albumController.title = title;
    if ([title isEqualToString:@"选择多张图片"]) {
        albumController.view.tag = MultipleImagePickingTag;
    } else if ([title isEqualToString:@"调整界面"]) {
        albumController.view.tag = ModifiedImagePickingTag;
        albumController.albumTableViewCellHeight = 70;
    } else {
        albumController.view.tag = NormalImagePickingTag;
    }
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:albumController];
    
    // 获取最近发送图片时使用过的相簿，如果有则直接进入该相簿
    [albumController pickLastAlbumGroup];
    
    [self presentViewController:navigationController animated:YES completion:NULL];
}

#pragma mark - <QMUITableViewDataSource,QMUITableViewDelegate>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.tableData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [UITableViewCell fwCellWithTableView:tableView];
    cell.textLabel.text = [self.tableData objectAtIndex:indexPath.row];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *title = [self.tableData objectAtIndex:indexPath.row];
    [self authorizationPresentAlbumViewControllerWithTitle:title];
}

#pragma mark - <QMUIAlbumViewControllerDelegate>

- (FWImagePickerController *)imagePickerControllerForAlbumController:(FWImageAlbumController *)albumController {
    FWImagePickerController *imagePickerController = [[FWImagePickerController alloc] init];
    imagePickerController.imagePickerControllerDelegate = self;
    imagePickerController.maximumSelectImageCount = MaxSelectedImageCount;
    imagePickerController.view.tag = albumController.view.tag;
    if (albumController.view.tag == ModifiedImagePickingTag) {
        imagePickerController.minimumImageWidth = 65;
    }
    return imagePickerController;
}

#pragma mark - <QMUIImagePickerViewControllerDelegate>

- (void)imagePickerController:(FWImagePickerController *)imagePickerController didFinishPickingImageWithImagesAssetArray:(NSMutableArray<FWAsset *> *)imagesAssetArray {
    // 储存最近选择了图片的相册，方便下次直接进入该相册
    [FWImagePickerHelper updateLastestAlbumWithAssetsGroup:imagePickerController.assetsGroup ablumContentType:kAlbumContentType userIdentify:nil];
    
    [self sendImageWithImagesAssetArray:imagesAssetArray];
}

- (FWImagePickerPreviewController *)imagePickerPreviewControllerForImagePickerController:(FWImagePickerController *)imagePickerController {
    if (imagePickerController.view.tag == MultipleImagePickingTag) {
        QDMultipleImagePickerPreviewViewController *imagePickerPreviewController = [[QDMultipleImagePickerPreviewViewController alloc] init];
        imagePickerPreviewController.delegate = self;
        imagePickerPreviewController.maximumSelectImageCount = MaxSelectedImageCount;
        imagePickerPreviewController.assetsGroup = imagePickerController.assetsGroup;
        imagePickerPreviewController.view.tag = imagePickerController.view.tag;
        return imagePickerPreviewController;
    } else if (imagePickerController.view.tag == ModifiedImagePickingTag) {
        FWImagePickerPreviewController *imagePickerPreviewController = [[FWImagePickerPreviewController alloc] init];
        imagePickerPreviewController.delegate = self;
        imagePickerPreviewController.view.tag = imagePickerController.view.tag;
        imagePickerPreviewController.toolBarBackgroundColor = FWColorRgb(66, 66, 66);
        return imagePickerPreviewController;
    } else {
        FWImagePickerPreviewController *imagePickerPreviewController = [[FWImagePickerPreviewController alloc] init];
        imagePickerPreviewController.delegate = self;
        imagePickerPreviewController.view.tag = imagePickerController.view.tag;
        return imagePickerPreviewController;
    }
}

#pragma mark - <QMUIImagePickerPreviewViewControllerDelegate>

- (void)imagePickerPreviewController:(FWImagePickerPreviewController *)imagePickerPreviewController didCheckImageAtIndex:(NSInteger)index {
    [self updateImageCountLabelForPreviewView:imagePickerPreviewController];
}

- (void)imagePickerPreviewController:(FWImagePickerPreviewController *)imagePickerPreviewController didUncheckImageAtIndex:(NSInteger)index {
    [self updateImageCountLabelForPreviewView:imagePickerPreviewController];
}

// 更新选中的图片数量
- (void)updateImageCountLabelForPreviewView:(FWImagePickerPreviewController *)imagePickerPreviewController {
    if (imagePickerPreviewController.view.tag == MultipleImagePickingTag) {
        QDMultipleImagePickerPreviewViewController *customImagePickerPreviewViewController = (QDMultipleImagePickerPreviewViewController *)imagePickerPreviewController;
        NSUInteger selectedCount = [imagePickerPreviewController.selectedImageAssetArray count];
        if (selectedCount > 0) {
            customImagePickerPreviewViewController.imageCountLabel.text = [[NSString alloc] initWithFormat:@"%@", @(selectedCount)];
            customImagePickerPreviewViewController.imageCountLabel.hidden = NO;
            [FWImagePickerHelper springAnimationOfImageSelectedCountChangeWithCountLabel:customImagePickerPreviewViewController.imageCountLabel];
        } else {
            customImagePickerPreviewViewController.imageCountLabel.hidden = YES;
        }
    }
}

#pragma mark - <QDMultipleImagePickerPreviewViewControllerDelegate>

- (void)imagePickerPreviewController:(QDMultipleImagePickerPreviewViewController *)imagePickerPreviewController sendImageWithImagesAssetArray:(NSMutableArray<FWAsset *> *)imagesAssetArray {
    // 储存最近选择了图片的相册，方便下次直接进入该相册
    [FWImagePickerHelper updateLastestAlbumWithAssetsGroup:imagePickerPreviewController.assetsGroup ablumContentType:kAlbumContentType userIdentify:nil];
    
    [self sendImageWithImagesAssetArray:imagesAssetArray];
}

#pragma mark - 业务方法

- (void)startLoading {
    [self fwShowLoading];
}

- (void)startLoadingWithText:(NSString *)text {
    [self fwShowLoadingWithText:text];
}

- (void)stopLoading {
    [self fwHideLoading];
}

- (void)showTipLabelWithText:(NSString *)text {
    [self stopLoading];
    [self fwShowMessageWithText:text];
}

- (void)hideTipLabel {
    [self fwHideMessage];
}

- (void)sendImageWithImagesAssetArrayIfDownloadStatusSucceed:(NSMutableArray<FWAsset *> *)imagesAssetArray {
    if ([FWImagePickerHelper imageAssetsDownloaded:imagesAssetArray]) {
        // 所有资源从 iCloud 下载成功，模拟发送图片到服务器
        // 显示发送中
        [self showTipLabelWithText:@"发送中"];
        // 使用 delay 模拟网络请求时长
        [self performSelector:@selector(showTipLabelWithText:) withObject:[NSString stringWithFormat:@"成功发送%@个资源", @([imagesAssetArray count])] afterDelay:1.5];
    }
}

- (void)sendImageWithImagesAssetArray:(NSMutableArray<FWAsset *> *)imagesAssetArray {
    __weak __typeof(self)weakSelf = self;
    
    for (FWAsset *asset in imagesAssetArray) {
        [FWImagePickerHelper requestImageAssetIfNeeded:asset completion:^(FWAssetDownloadStatus downloadStatus, NSError *error) {
            if (downloadStatus == FWAssetDownloadStatusDownloading) {
                [weakSelf startLoadingWithText:@"从 iCloud 加载中"];
            } else if (downloadStatus == FWAssetDownloadStatusSucceed) {
                [weakSelf sendImageWithImagesAssetArrayIfDownloadStatusSucceed:imagesAssetArray];
            } else {
                [weakSelf showTipLabelWithText:@"iCloud 下载错误，请重新选图"];
            }
        }];
    }
}

- (void)setAvatarWithAvatarImage:(UIImage *)avatarImage {
    [self stopLoading];
    self.selectedAvatarImage = avatarImage;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:1 inSection:1];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

@end
