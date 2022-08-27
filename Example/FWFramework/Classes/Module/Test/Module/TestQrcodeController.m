//
//  TestQrcodeController.m
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/25.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

#import "TestQrcodeController.h"
#import "AppSwift.h"
@import FWFramework;

@interface TestQrcodeController () <FWViewController>

@property (nonatomic, strong) FWQrcodeScanManager *scanManager;
@property (nonatomic, strong) FWQrcodeScanView *scanView;

@property (nonatomic, strong) UIButton *flashlightBtn;
@property (nonatomic, assign) BOOL flashlightSelected;
@property (nonatomic, strong) UILabel *promptLabel;

@end

@implementation TestQrcodeController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.fw_navigationBarStyle = 2;
    self.fw_extendedLayoutEdge = UIRectEdgeTop;
    self.navigationItem.title = @"扫一扫";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"相册" style:UIBarButtonItemStyleDone target:self action:@selector(onPhotoLibrary)];
    
    // 相机授权
    [[FWAuthorizeManager managerWithType:FWAuthorizeTypeCamera] authorize:^(FWAuthorizeStatus status) {
        if (status != FWAuthorizeStatusAuthorized) {
            [self fw_showAlertWithTitle:(status == FWAuthorizeStatusRestricted ? @"未检测到您的摄像头" : @"未打开摄像头权限") message:nil cancel:nil cancelBlock:NULL];
        } else {
            [self setupScanManager];
            [self.view addSubview:self.scanView];
            [self.view addSubview:self.promptLabel];
            
            // 由于异步授权，viewWillAppear时可能未完成，此处调用start
            [self startScanManager];
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self startScanManager];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self stopScanManager];
}

- (void)dealloc
{
    [self removeScanView];
}

#pragma mark - Accessor

- (FWQrcodeScanView *)scanView
{
    if (!_scanView) {
        _scanView = [[FWQrcodeScanView alloc] initWithFrame:CGRectMake(0, 0, FWScreenWidth, FWScreenHeight)];
        _scanView.scanImageName = [FWModuleBundle imageNamed:@"qrcodeLine"];
    }
    return _scanView;
}

- (UIButton *)flashlightBtn
{
    if (!_flashlightBtn) {
        _flashlightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        CGFloat flashlightBtnW = 30;
        CGFloat flashlightBtnH = 30;
        CGFloat flashlightBtnX = 0.5 * (self.view.frame.size.width - flashlightBtnW);
        CGFloat flashlightBtnY = 0.5 * FWScreenHeight + 0.35 * self.view.frame.size.width - flashlightBtnH - 25;
        _flashlightBtn.frame = CGRectMake(flashlightBtnX, flashlightBtnY, flashlightBtnW, flashlightBtnH);
        [_flashlightBtn setBackgroundImage:[FWModuleBundle imageNamed:@"qrcodeFlashlightOpen"] forState:(UIControlStateNormal)];
        [_flashlightBtn setBackgroundImage:[FWModuleBundle imageNamed:@"qrcodeFlashlightClose"] forState:(UIControlStateSelected)];
        [_flashlightBtn addTarget:self action:@selector(toggleFlashlightBtn:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _flashlightBtn;
}

- (UILabel *)promptLabel
{
    if (!_promptLabel) {
        CGFloat tipLabelY = 0.5 * FWScreenHeight + 0.35 * self.view.frame.size.width + 12;
        _promptLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, tipLabelY, FWScreenWidth, 20)];
        _promptLabel.font = [UIFont systemFontOfSize:13];
        _promptLabel.textColor = [AppTheme textColor];
        _promptLabel.textAlignment = NSTextAlignmentCenter;
        _promptLabel.text = @"将二维码/条码放入框内, 即可自动扫描";
    }
    return _promptLabel;
}

#pragma mark - Private

- (void)setupScanManager
{
    self.scanManager = [[FWQrcodeScanManager alloc] init];
    self.scanManager.sampleBufferDelegate = YES;
    [self.scanManager scanQrcodeWithView:self.view];
    
    FWWeakifySelf();
    self.scanManager.scanResultBlock = ^(NSString *result) {
        FWStrongifySelf();
        if (result) {
            [UIApplication fw_playSystemSound:[FWModuleBundle resourcePath:@"Qrcode.caf"]];
            [self stopScanManager];
            
            [self onScanResult:result];
        }
    };
    self.scanManager.scanBrightnessBlock = ^(CGFloat brightness) {
        FWStrongifySelf();
        if (brightness < -1) {
            [self.view addSubview:self.flashlightBtn];
        } else {
            if (self.flashlightSelected == NO) {
                [self removeFlashlightBtn];
            }
        }
    };
}

- (void)startScanManager
{
    [self.scanManager startRunning];
    [self.scanView addTimer];
}

- (void)stopScanManager
{
    [self.scanView removeTimer];
    [self removeFlashlightBtn];
    [self.scanManager stopRunning];
}

- (void)toggleFlashlightBtn:(UIButton *)button
{
    if (button.selected == NO) {
        [FWQrcodeScanManager openFlashlight];
        
        self.flashlightSelected = YES;
        button.selected = YES;
    } else {
        [self removeFlashlightBtn];
    }
}

- (void)removeFlashlightBtn
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [FWQrcodeScanManager closeFlashlight];
        
        self.flashlightSelected = NO;
        self.flashlightBtn.selected = NO;
        [self.flashlightBtn removeFromSuperview];
    });
}

- (void)removeScanView
{
    [self.scanView removeTimer];
    [self.scanView removeFromSuperview];
    self.scanView = nil;
}

#pragma mark - Action

- (void)onPhotoLibrary
{
    [self stopScanManager];
    
    FWWeakifySelf();
    [self fw_showImagePickerWithFilterType:FWImagePickerFilterTypeImage selectionLimit:1 allowsEditing:NO customBlock:^(UIViewController *imagePicker) {
        FWStrongifySelf();
        if ([imagePicker isKindOfClass:[UIViewController class]]) {
            imagePicker.fw_presentationDidDismiss = ^{
                FWStrongifySelf();
                [self startScanManager];
            };
        }
    } completion:^(NSArray * _Nonnull objects, NSArray * _Nonnull results, BOOL cancel) {
        FWStrongifySelf();
        if (cancel) {
            [self startScanManager];
        } else {
            UIImage *image = objects.firstObject;
            image = [image fw_compressImageWithMaxWidth:1200];
            image = [image fw_compressImageWithMaxLength:300 * 1024];
            NSString *result = [FWQrcodeScanManager scanQrcodeWithImage:image];
            
            [self onScanResult:result];
        }
    }];
}

- (void)onScanResult:(NSString *)result
{
    FWWeakifySelf();
    [self fw_showAlertWithTitle:@"扫描结果" message:FWSafeString(result) cancel:nil cancelBlock:^{
        FWStrongifySelf();
        [self startScanManager];
    }];
}

@end
