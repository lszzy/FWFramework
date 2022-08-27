//
//  TestDrawerController.m
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/25.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

#import "TestDrawerController.h"
#import "AppSwift.h"
@import FWFramework;
@import Vision;

@interface TestDrawerController () <FWViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation TestDrawerController

- (void)didInitialize
{
    self.fw_extendedLayoutEdge = UIRectEdgeTop;
    self.fw_navigationBarStyle = 2;
}

- (BOOL)shouldPopController
{
    FWDrawerView *drawerView = self.contentView.fw_drawerView;
    [drawerView setPosition:drawerView.openPosition animated:YES];
    return NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    FWWeakifySelf();
    [self fw_setLeftBarItem:FWIconImage(@"zmdi-var-menu", 24) block:^(id sender) {
        FWStrongifySelf();
        FWDrawerView *drawerView = self.contentView.fw_drawerView;
        CGFloat position = (drawerView.position == drawerView.openPosition) ? drawerView.closePosition : drawerView.openPosition;
        [drawerView setPosition:position animated:YES];
    }];
    
    [self fw_addRightBarItem:@"相册" target:self action:@selector(onPhotoSheet:)];
}

- (void)setupSubviews
{
    self.view.backgroundColor = [AppTheme tableColor];
    
    UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(-FWScreenWidth / 2.0, 0, FWScreenWidth / 2.0, self.view.fw_height)];
    _contentView = contentView;
    contentView.backgroundColor = [UIColor brownColor];
    UILabel *topLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 200, 100, 30)];
    topLabel.text = @"Menu 1";
    [contentView addSubview:topLabel];
    UILabel *middleLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 250, 100, 30)];
    middleLabel.text = @"Menu 2";
    [contentView addSubview:middleLabel];
    UILabel *bottomLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 300, 100, 30)];
    bottomLabel.text = @"Menu 3";
    [contentView addSubview:bottomLabel];
    UILabel *closeLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 400, 100, 30)];
    closeLabel.text = @"Back";
    FWWeakifySelf();
    closeLabel.userInteractionEnabled = YES;
    [closeLabel fw_addTapGestureWithBlock:^(id sender) {
        FWStrongifySelf();
        [self fw_closeViewControllerAnimated:YES];
    }];
    [contentView addSubview:closeLabel];
    [self.view addSubview:contentView];
    
    [contentView fw_drawerView:UISwipeGestureRecognizerDirectionRight
                    positions:@[@(-FWScreenWidth / 2.0), @(0)]
               kickbackHeight:25
                     callback:nil];
    
    UIImageView *imageView = [UIImageView new];
    _imageView = imageView;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:imageView];
    imageView.fw_layoutChain.center().size(CGSizeMake(200, 200));
}

- (void)onPhotoSheet:(UIBarButtonItem *)sender
{
    FWWeakifySelf();
    [self fw_showSheetWithTitle:nil message:nil cancel:@"取消" actions:@[@"拍照", @"选取相册"] actionBlock:^(NSInteger index) {
        FWStrongifySelf();
        if (index == 0) {
            if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
                [self fw_showAlertWithTitle:@"未检测到您的摄像头" message:nil cancel:nil cancelBlock:nil];
                return;
            }
            
            [self fw_showImageCameraWithAllowsEditing:YES completion:^(UIImage * _Nullable image, BOOL cancel) {
                FWStrongifySelf();
                [self onPickerResult:image cancelled:cancel];
            }];
        } else {
            [self fw_showImagePickerWithAllowsEditing:YES completion:^(UIImage * _Nullable image, BOOL cancel) {
                FWStrongifySelf();
                [self onPickerResult:image cancelled:cancel];
            }];
        }
    }];
}

- (void)onPickerResult:(UIImage *)image cancelled:(BOOL)cancelled
{
    self.imageView.image = cancelled ? nil : image;
    if (!self.imageView.image.CGImage) return;
    
    if (@available(iOS 13.0, *)) {
        [UIWindow fw_showLoading];
        [FWDetector recognizeTextIn:self.imageView.image.CGImage configuration:^(VNRecognizeTextRequest *request) {
            request.recognitionLanguages = @[@"zh-CN", @"en-US"];
            request.usesLanguageCorrection = YES;
        } completion:^(NSArray<FWOcrResult *> *results) {
            [UIWindow fw_hideLoading];
            NSMutableString *string = [NSMutableString string];
            for (FWOcrResult *result in results) {
                [string appendFormat:@"text: %@\nconfidence: %@\n", result.text, @(result.confidence)];
            }
            NSString *message = string.length > 0 ? string.copy : @"识别结果为空";
            [UIWindow.fw_mainWindow fw_showAlertWithTitle:@"扫描结果" message:message];
        }];
    }
}

@end
