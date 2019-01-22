//
//  TestQrcodeViewController.m
//  Example
//
//  Created by wuyong on 2019/1/21.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

#import "TestQrcodeViewController.h"

@interface TestQrcodeViewController ()

@property (nonatomic, strong) FWQrcodeScanManager *manager;
@property (nonatomic, strong) FWQrcodeScanView *scanView;
@property (nonatomic, strong) UIButton *flashlightBtn;
@property (nonatomic, strong) UILabel *promptLabel;
@property (nonatomic, assign) BOOL isSelectedFlashlightBtn;
@property (nonatomic, strong) UIView *bottomView;

@end

@implementation TestQrcodeViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.manager startRunning];
    [self.scanView addTimer];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.scanView removeTimer];
    [self removeFlashlightBtn];
    [self.manager stopRunning];
}

- (void)dealloc
{
    [self removeScanningView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.view.backgroundColor = [UIColor blackColor];
    self.navigationItem.title = @"扫一扫";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"相册" style:(UIBarButtonItemStyleDone) target:self action:@selector(openPhotoLibrary)];
    
    [[FWAuthorizeManager managerWithType:FWAuthorizeTypeCamera] authorize:^(FWAuthorizeStatus status) {
        if (status != FWAuthorizeStatusAuthorized) {
            [self fwShowAlertWithTitle:(status == FWAuthorizeStatusRestricted ? @"未检测到您的摄像头" : @"未打开摄像头权限") message:nil cancel:@"确定" cancelBlock:NULL];
        } else {
            [self setupQRCodeScan];
            [self.view addSubview:self.scanView];
            [self.view addSubview:self.promptLabel];
            [self.view addSubview:self.bottomView];
        }
    }];
}

- (void)setupQRCodeScan
{
    __weak typeof(self) weakSelf = self;
    
    self.manager = [FWQrcodeScanManager new];
    self.manager.sampleBufferDelegate = YES;
    [self.manager scanQrcodeWithView:self.view];
    [self.manager setScanResultBlock:^(NSString *result) {
        if (result) {
            [weakSelf.manager stopRunning];
            [UIApplication fwPlayAlert:@"QrcodeSound.caf"];
            
            [weakSelf showResult:result];
        }
    }];
    [self.manager setScanBrightnessBlock:^(CGFloat brightness) {
        if (brightness < - 1) {
            [weakSelf.view addSubview:weakSelf.flashlightBtn];
        } else {
            if (weakSelf.isSelectedFlashlightBtn == NO) {
                [weakSelf removeFlashlightBtn];
            }
        }
    }];
}

- (void)openPhotoLibrary
{
    [self.scanView removeTimer];
    __weak typeof(self) weakSelf = self;
    UIImagePickerController *pickerController = [UIImagePickerController fwPickerControllerWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary completion:^(NSDictionary *info, BOOL cancel) {
        if (cancel) {
            [weakSelf.view addSubview:weakSelf.scanView];
        } else {
            UIImage *image = info[UIImagePickerControllerOriginalImage];
            NSString *result = [FWQrcodeScanManager scanQrcodeWithImage:image];
            [weakSelf showResult:result];
        }
    }];
    [self presentViewController:pickerController animated:YES completion:nil];
}

- (FWQrcodeScanView *)scanView {
    if (!_scanView) {
        _scanView = [[FWQrcodeScanView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 0.9 * self.view.frame.size.height)];
        _scanView.scanImageName = @"qrcode_line";
    }
    return _scanView;
}

- (void)removeScanningView {
    [self.scanView removeTimer];
    [self.scanView removeFromSuperview];
    self.scanView = nil;
}

- (UILabel *)promptLabel {
    if (!_promptLabel) {
        _promptLabel = [[UILabel alloc] init];
        _promptLabel.backgroundColor = [UIColor clearColor];
        CGFloat promptLabelX = 0;
        CGFloat promptLabelY = 0.73 * self.view.frame.size.height;
        CGFloat promptLabelW = self.view.frame.size.width;
        CGFloat promptLabelH = 25;
        _promptLabel.frame = CGRectMake(promptLabelX, promptLabelY, promptLabelW, promptLabelH);
        _promptLabel.textAlignment = NSTextAlignmentCenter;
        _promptLabel.font = [UIFont boldSystemFontOfSize:13.0];
        _promptLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.6];
        _promptLabel.text = @"将二维码/条码放入框内, 即可自动扫描";
    }
    return _promptLabel;
}

- (UIView *)bottomView {
    if (!_bottomView) {
        _bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.scanView.frame), self.view.frame.size.width, self.view.frame.size.height - CGRectGetMaxY(self.scanView.frame))];
        _bottomView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    }
    return _bottomView;
}

#pragma mark - - - 闪光灯按钮
- (UIButton *)flashlightBtn {
    if (!_flashlightBtn) {
        // 添加闪光灯按钮
        _flashlightBtn = [UIButton buttonWithType:(UIButtonTypeCustom)];
        CGFloat flashlightBtnW = 30;
        CGFloat flashlightBtnH = 30;
        CGFloat flashlightBtnX = 0.5 * (self.view.frame.size.width - flashlightBtnW);
        CGFloat flashlightBtnY = 0.55 * self.view.frame.size.height;
        _flashlightBtn.frame = CGRectMake(flashlightBtnX, flashlightBtnY, flashlightBtnW, flashlightBtnH);
        [_flashlightBtn setBackgroundImage:[UIImage imageNamed:@"flashlight_open"] forState:(UIControlStateNormal)];
        [_flashlightBtn setBackgroundImage:[UIImage imageNamed:@"flashlight_close"] forState:(UIControlStateSelected)];
        [_flashlightBtn addTarget:self action:@selector(flashlightBtn_action:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _flashlightBtn;
}

- (void)flashlightBtn_action:(UIButton *)button {
    if (button.selected == NO) {
        [FWQrcodeScanManager openFlashlight];
        self.isSelectedFlashlightBtn = YES;
        button.selected = YES;
    } else {
        [self removeFlashlightBtn];
    }
}

- (void)removeFlashlightBtn {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [FWQrcodeScanManager closeFlashlight];
        self.isSelectedFlashlightBtn = NO;
        self.flashlightBtn.selected = NO;
        [self.flashlightBtn removeFromSuperview];
    });
}

#pragma mark - Result

- (void)showResult:(NSString *)result
{
    [self.scanView removeTimer];
    [self removeFlashlightBtn];
    [self.manager stopRunning];
    [self fwShowAlertWithTitle:@"扫描结果" message:result cancel:@"确定" cancelBlock:^{
        [self.manager startRunning];
        [self.scanView addTimer];
    }];
}

@end
