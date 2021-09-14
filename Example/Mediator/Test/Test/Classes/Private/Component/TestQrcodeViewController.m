//
//  TestQrcodeViewController.m
//  Example
//
//  Created by wuyong on 2019/1/21.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

#import "TestQrcodeViewController.h"

@interface TestQrcodeViewController ()

@property (nonatomic, strong) FWQrcodeScanManager *scanManager;
@property (nonatomic, strong) FWQrcodeScanView *scanView;

@property (nonatomic, strong) UIButton *flashlightBtn;
@property (nonatomic, assign) BOOL flashlightSelected;
@property (nonatomic, strong) UILabel *promptLabel;

@end

@implementation TestQrcodeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.fwNavigationBarStyle = FWNavigationBarStyleTransparent;
    self.fwExtendedLayoutEdge = UIRectEdgeTop;
    self.fwNavigationItem.title = @"扫一扫";
    self.fwNavigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"相册" style:UIBarButtonItemStyleDone target:self action:@selector(onPhotoLibrary)];
    
    // 相机授权
    [[FWAuthorizeManager managerWithType:FWAuthorizeTypeCamera] authorize:^(FWAuthorizeStatus status) {
        if (status != FWAuthorizeStatusAuthorized) {
            [self fwShowAlertWithTitle:(status == FWAuthorizeStatusRestricted ? @"未检测到您的摄像头" : @"未打开摄像头权限") message:nil cancel:nil cancelBlock:NULL];
        } else {
            [self setupScanManager];
            [self.fwView addSubview:self.scanView];
            [self.fwView addSubview:self.promptLabel];
            
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
        _scanView.scanImageName = [TestBundle imageNamed:@"qrcode_line"];
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
        [_flashlightBtn setBackgroundImage:[TestBundle imageNamed:@"flashlight_open"] forState:(UIControlStateNormal)];
        [_flashlightBtn setBackgroundImage:[TestBundle imageNamed:@"flashlight_close"] forState:(UIControlStateSelected)];
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
        _promptLabel.textColor = [Theme textColor];
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
            [UIApplication fwPlayAlert:[TestBundle.bundle pathForResource:@"QrcodeSound" ofType:@"caf"]];
            [self stopScanManager];
            
            [self onScanResult:result];
        }
    };
    self.scanManager.scanBrightnessBlock = ^(CGFloat brightness) {
        FWStrongifySelf();
        if (brightness < -1) {
            [self.fwView addSubview:self.flashlightBtn];
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
    [self fwShowImagePickerWithFilterType:FWImagePickerFilterTypeImage selectionLimit:1 allowsEditing:NO customBlock:^(UIViewController *imagePicker) {
        FWStrongifySelf();
        if ([imagePicker isKindOfClass:[UIViewController class]]) {
            imagePicker.fwPresentationDidDismiss = ^{
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
            image = [image fwCompressImageWithMaxWidth:1200];
            image = [image fwCompressImageWithMaxLength:300 * 1024];
            NSString *result = [FWQrcodeScanManager scanQrcodeWithImage:image];
            
            [self onScanResult:result];
        }
    }];
}

- (void)onScanResult:(NSString *)result
{
    FWWeakifySelf();
    [self fwShowAlertWithTitle:@"扫描结果" message:FWSafeString(result) cancel:nil cancelBlock:^{
        FWStrongifySelf();
        [self startScanManager];
    }];
}

@end
