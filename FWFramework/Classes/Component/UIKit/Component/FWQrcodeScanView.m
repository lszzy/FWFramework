/*!
 @header     FWQrcodeScanView.m
 @indexgroup FWFramework
 @brief      FWQrcodeScanView
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/1/21
 */

#import "FWQrcodeScanView.h"

@interface FWQrcodeScanManager () <AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureSession *captureSession;

@end

@implementation FWQrcodeScanManager

#pragma mark - Scan

- (NSString *)sessionPreset
{
    if (!_sessionPreset) {
        _sessionPreset = AVCaptureSessionPreset1920x1080;
    }
    return _sessionPreset;
}

- (NSArray *)metadataObjectTypes
{
    if (!_metadataObjectTypes) {
        _metadataObjectTypes = @[AVMetadataObjectTypeQRCode];
    }
    return _metadataObjectTypes;
}

- (AVCaptureSession *)captureSession
{
    if (!_captureSession) {
        _captureSession = [[AVCaptureSession alloc] init];
    }
    return _captureSession;
}

- (void)scanQrcodeWithView:(UIView *)view
{
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    // 1、捕获设备输入流
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    // 2、捕获元数据输出流
    AVCaptureMetadataOutput *metadataOutput = [[AVCaptureMetadataOutput alloc] init];
    [metadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    // 设置扫描范围（每一个取值 0 ～ 1，以屏幕右上角为坐标原点）
    // 注：微信二维码的扫描范围是整个屏幕，这里并没有做处理（可不用设置）
    if (!CGRectEqualToRect(self.rectOfInterest, CGRectZero)) {
        metadataOutput.rectOfInterest = self.rectOfInterest;
    }
    
    // 3、设置会话采集率
    self.captureSession.sessionPreset = self.sessionPreset;
    
    // 4(1)、添加捕获元数据输出流到会话对象
    [_captureSession addOutput:metadataOutput];
    // 4(2)、添加捕获输出流到会话对象；构成识了别光线强弱
    if (self.sampleBufferDelegate == YES) {
        AVCaptureVideoDataOutput *videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
        [videoDataOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
        [_captureSession addOutput:videoDataOutput];
    }
    // 4(3)、添加捕获设备输入流到会话对象
    if (deviceInput) {
        [_captureSession addInput:deviceInput];
    }
    
    // 5、设置数据输出类型，需要将数据输出添加到会话后，才能指定元数据类型，否则会报错
    NSMutableArray *objectTypes = [NSMutableArray array];
    for (AVMetadataObjectType objectType in self.metadataObjectTypes) {
        if ([metadataOutput.availableMetadataObjectTypes containsObject:objectType]) {
            [objectTypes addObject:objectType];
        }
    }
    metadataOutput.metadataObjectTypes = [objectTypes copy];
    
    // 6、预览图层
    AVCaptureVideoPreviewLayer *videoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_captureSession];
    // 保持纵横比，填充层边界
    videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    videoPreviewLayer.frame = view.frame;
    [view.layer insertSublayer:videoPreviewLayer atIndex:0];
}

- (void)startRunning
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if (!self.captureSession.isRunning) {
            [self.captureSession startRunning];
        }
    });
}

- (void)stopRunning
{
    if (self.captureSession.isRunning) {
        [self.captureSession stopRunning];
    }
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    NSString *resultString = nil;
    if (metadataObjects != nil && metadataObjects.count > 0) {
        AVMetadataMachineReadableCodeObject *obj = metadataObjects[0];
        resultString = [obj stringValue];
        if (_scanResultBlock) {
            _scanResultBlock(resultString);
        }
    }
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CFDictionaryRef metadataDict = CMCopyDictionaryOfAttachments(NULL, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
    NSDictionary *metadata = [[NSMutableDictionary alloc] initWithDictionary:(__bridge NSDictionary*)metadataDict];
    CFRelease(metadataDict);
    NSDictionary *exifMetadata = [[metadata objectForKey:(NSString *)kCGImagePropertyExifDictionary] mutableCopy];
    CGFloat brightnessValue = [[exifMetadata objectForKey:(NSString *)kCGImagePropertyExifBrightnessValue] floatValue];
    if (_scanBrightnessBlock) {
        _scanBrightnessBlock(brightnessValue);
    }
}

+ (void)openFlashlight
{
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error = nil;
    if ([captureDevice hasTorch]) {
        BOOL locked = [captureDevice lockForConfiguration:&error];
        if (locked) {
            [captureDevice setTorchMode:AVCaptureTorchModeOn];
            [captureDevice unlockForConfiguration];
        }
    }
}

+ (void)closeFlashlight
{
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([captureDevice hasTorch]) {
        [captureDevice lockForConfiguration:nil];
        [captureDevice setTorchMode:AVCaptureTorchModeOff];
        [captureDevice unlockForConfiguration];
    }
}

+ (void)configCaptureDevice:(void (^)(AVCaptureDevice *))block
{
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (captureDevice) {
        [captureDevice lockForConfiguration:nil];
        if (block) block(captureDevice);
        [captureDevice unlockForConfiguration];
    }
}

#pragma mark - Image

+ (NSString *)scanQrcodeWithImage:(UIImage *)image
{
    // 创建 CIDetector，并设定识别类型：CIDetectorTypeQRCode
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy: CIDetectorAccuracyHigh}];
    
    // 识别结果为空
    CIImage *ciImage = [[CIImage alloc] initWithImage:image];
    NSArray *features = [detector featuresInImage:ciImage];
    if (features.count == 0) {
        return nil;
    }
    
    // 获取识别结果
    NSString *qrcodeString = nil;
    for (int index = 0; index < [features count]; index ++) {
        CIQRCodeFeature *feature = [features objectAtIndex:index];
        qrcodeString = feature.messageString;
    }
    return qrcodeString;
}

#pragma mark - Generate

+ (UIImage *)generateQrcodeWithData:(NSString *)data
                               size:(CGFloat)size
{
    return [self generateQrcodeWithData:data
                                   size:size
                                  color:[UIColor blackColor]
                        backgroundColor:[UIColor whiteColor]];
}

+ (UIImage *)generateQrcodeWithData:(NSString *)data
                               size:(CGFloat)size
                              color:(UIColor *)color
                    backgroundColor:(UIColor *)backgroundColor
{
    NSData *string_data = [data dataUsingEncoding:NSUTF8StringEncoding];
    // 1、二维码滤镜
    CIFilter *fileter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    [fileter setValue:string_data forKey:@"inputMessage"];
    [fileter setValue:@"H" forKey:@"inputCorrectionLevel"];
    CIImage *ciImage = fileter.outputImage;
    // 2、颜色滤镜
    CIFilter *color_filter = [CIFilter filterWithName:@"CIFalseColor"];
    [color_filter setValue:ciImage forKey:@"inputImage"];
    [color_filter setValue:[CIColor colorWithCGColor:color.CGColor] forKey:@"inputColor0"];
    [color_filter setValue:[CIColor colorWithCGColor:backgroundColor.CGColor] forKey:@"inputColor1"];
    // 3、生成处理
    CIImage *outImage = color_filter.outputImage;
    CGFloat outWidth = outImage.extent.size.width;
    CGFloat scale = outWidth > 0 ? (size / outWidth) : 0;
    outImage = [outImage imageByApplyingTransform:CGAffineTransformMakeScale(scale, scale)];
    return [UIImage imageWithCIImage:outImage];
}

+ (UIImage *)generateQrcodeWithData:(NSString *)data
                               size:(CGFloat)size
                          logoImage:(UIImage *)logoImage
                              ratio:(CGFloat)ratio
{
    return [self generateQrcodeWithData:data
                                   size:size
                              logoImage:logoImage
                                  ratio:ratio
                  logoImageCornerRadius:5
                   logoImageBorderWidth:5
                   logoImageBorderColor:[UIColor whiteColor]];
}

+ (UIImage *)generateQrcodeWithData:(NSString *)data
                               size:(CGFloat)size
                          logoImage:(UIImage *)logoImage
                              ratio:(CGFloat)ratio
              logoImageCornerRadius:(CGFloat)logoImageCornerRadius
               logoImageBorderWidth:(CGFloat)logoImageBorderWidth
               logoImageBorderColor:(UIColor *)logoImageBorderColor
{
    UIImage *image = [self generateQrcodeWithData:data size:size color:[UIColor blackColor] backgroundColor:[UIColor whiteColor]];
    if (logoImage == nil) return image;
    if (ratio < 0.0 || ratio > 0.5) {
        ratio = 0.25;
    }
    CGFloat logoImageW = ratio * size;
    CGFloat logoImageH = logoImageW;
    CGFloat logoImageX = 0.5 * (image.size.width - logoImageW);
    CGFloat logoImageY = 0.5 * (image.size.height - logoImageH);
    CGRect logoImageRect = CGRectMake(logoImageX, logoImageY, logoImageW, logoImageH);
    // 绘制logo
    UIGraphicsBeginImageContextWithOptions(image.size, false, [UIScreen mainScreen].scale);
    [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
    if (logoImageCornerRadius < 0.0 || logoImageCornerRadius > 10) {
        logoImageCornerRadius = 5;
    }
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:logoImageRect cornerRadius:logoImageCornerRadius];
    if (logoImageBorderWidth < 0.0 || logoImageBorderWidth > 10) {
        logoImageBorderWidth = 5;
    }
    path.lineWidth = logoImageBorderWidth;
    [logoImageBorderColor setStroke];
    [path stroke];
    [path addClip];
    [logoImage drawInRect:logoImageRect];
    UIImage *QRCodeImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return QRCodeImage;
}

@end

@interface FWQrcodeScanView ()

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) UIImageView *scanningline;

@end

@implementation FWQrcodeScanView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        
        [self initialization];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self initialization];
}

- (void)initialization
{
    _scanAnimationStyle = FWQrcodeScanAnimationStyleDefault;
    _borderColor = [UIColor whiteColor];
    _borderFrame = CGRectMake(0.15 * self.frame.size.width, 0.5 * (self.frame.size.height - 0.7 * self.frame.size.width), 0.7 * self.frame.size.width, 0.7 * self.frame.size.width);
    _borderWidth = 0.2;
    _cornerLocation = FWQrcodeCornerLocationDefault;
    _cornerColor = [UIColor colorWithRed:85/255.0f green:183/255.0 blue:55/255.0 alpha:1.0];
    _cornerWidth = 2.0;
    _cornerLength = 20;
    _backgroundAlpha = 0.5;
    _animationTimeInterval = 0.02;
    _scanImageName = nil;
}

- (UIView *)contentView
{
    if (!_contentView) {
        _contentView = [[UIView alloc] init];
        _contentView.frame = self.borderFrame;
        _contentView.clipsToBounds = YES;
        _contentView.backgroundColor = [UIColor clearColor];
    }
    return _contentView;
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    /// 边框 frame
    CGFloat borderW = self.borderFrame.size.width;
    CGFloat borderH = self.borderFrame.size.height;
    CGFloat borderX = self.borderFrame.origin.x;
    CGFloat borderY = self.borderFrame.origin.y;
    CGFloat borderLineW = self.borderWidth;
    
    /// 空白区域设置
    [[[UIColor blackColor] colorWithAlphaComponent:self.backgroundAlpha] setFill];
    UIRectFill(rect);
    // 获取上下文，并设置混合模式 -> kCGBlendModeDestinationOut
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetBlendMode(context, kCGBlendModeDestinationOut);
    // 设置空白区
    UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRect:CGRectMake(borderX + 0.5 * borderLineW, borderY + 0.5 *borderLineW, borderW - borderLineW, borderH - borderLineW)];
    [bezierPath fill];
    // 执行混合模式
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    
    /// 边框设置
    UIBezierPath *borderPath = [UIBezierPath bezierPathWithRect:CGRectMake(borderX, borderY, borderW, borderH)];
    borderPath.lineCapStyle = kCGLineCapButt;
    borderPath.lineWidth = borderLineW;
    [self.borderColor set];
    [borderPath stroke];
    
    
    CGFloat cornerLength = self.cornerLength;
    /// 左上角小图标
    UIBezierPath *leftTopPath = [UIBezierPath bezierPath];
    leftTopPath.lineWidth = self.cornerWidth;
    [self.cornerColor set];
    
    CGFloat insideExcess = fabs(0.5 * (self.cornerWidth - borderLineW));
    CGFloat outsideExcess = 0.5 * (borderLineW + self.cornerWidth);
    if (self.cornerLocation == FWQrcodeCornerLocationInside) {
        [leftTopPath moveToPoint:CGPointMake(borderX + insideExcess, borderY + cornerLength + insideExcess)];
        [leftTopPath addLineToPoint:CGPointMake(borderX + insideExcess, borderY + insideExcess)];
        [leftTopPath addLineToPoint:CGPointMake(borderX + cornerLength + insideExcess, borderY + insideExcess)];
    } else if (self.cornerLocation == FWQrcodeCornerLocationOutside) {
        [leftTopPath moveToPoint:CGPointMake(borderX - outsideExcess, borderY + cornerLength - outsideExcess)];
        [leftTopPath addLineToPoint:CGPointMake(borderX - outsideExcess, borderY - outsideExcess)];
        [leftTopPath addLineToPoint:CGPointMake(borderX + cornerLength - outsideExcess, borderY - outsideExcess)];
    } else {
        [leftTopPath moveToPoint:CGPointMake(borderX, borderY + cornerLength)];
        [leftTopPath addLineToPoint:CGPointMake(borderX, borderY)];
        [leftTopPath addLineToPoint:CGPointMake(borderX + cornerLength, borderY)];
    }
    
    [leftTopPath stroke];
    
    /// 左下角小图标
    UIBezierPath *leftBottomPath = [UIBezierPath bezierPath];
    leftBottomPath.lineWidth = self.cornerWidth;
    [self.cornerColor set];
    
    if (self.cornerLocation == FWQrcodeCornerLocationInside) {
        [leftBottomPath moveToPoint:CGPointMake(borderX + cornerLength + insideExcess, borderY + borderH - insideExcess)];
        [leftBottomPath addLineToPoint:CGPointMake(borderX + insideExcess, borderY + borderH - insideExcess)];
        [leftBottomPath addLineToPoint:CGPointMake(borderX + insideExcess, borderY + borderH - cornerLength - insideExcess)];
    } else if (self.cornerLocation == FWQrcodeCornerLocationOutside) {
        [leftBottomPath moveToPoint:CGPointMake(borderX + cornerLength - outsideExcess, borderY + borderH + outsideExcess)];
        [leftBottomPath addLineToPoint:CGPointMake(borderX - outsideExcess, borderY + borderH + outsideExcess)];
        [leftBottomPath addLineToPoint:CGPointMake(borderX - outsideExcess, borderY + borderH - cornerLength + outsideExcess)];
    } else {
        [leftBottomPath moveToPoint:CGPointMake(borderX + cornerLength, borderY + borderH)];
        [leftBottomPath addLineToPoint:CGPointMake(borderX, borderY + borderH)];
        [leftBottomPath addLineToPoint:CGPointMake(borderX, borderY + borderH - cornerLength)];
    }
    
    [leftBottomPath stroke];
    
    /// 右上角小图标
    UIBezierPath *rightTopPath = [UIBezierPath bezierPath];
    rightTopPath.lineWidth = self.cornerWidth;
    [self.cornerColor set];
    
    if (self.cornerLocation == FWQrcodeCornerLocationInside) {
        [rightTopPath moveToPoint:CGPointMake(borderX + borderW - cornerLength - insideExcess, borderY + insideExcess)];
        [rightTopPath addLineToPoint:CGPointMake(borderX + borderW - insideExcess, borderY + insideExcess)];
        [rightTopPath addLineToPoint:CGPointMake(borderX + borderW - insideExcess, borderY + cornerLength + insideExcess)];
    } else if (self.cornerLocation == FWQrcodeCornerLocationOutside) {
        [rightTopPath moveToPoint:CGPointMake(borderX + borderW - cornerLength + outsideExcess, borderY - outsideExcess)];
        [rightTopPath addLineToPoint:CGPointMake(borderX + borderW + outsideExcess, borderY - outsideExcess)];
        [rightTopPath addLineToPoint:CGPointMake(borderX + borderW + outsideExcess, borderY + cornerLength - outsideExcess)];
    } else {
        [rightTopPath moveToPoint:CGPointMake(borderX + borderW - cornerLength, borderY)];
        [rightTopPath addLineToPoint:CGPointMake(borderX + borderW, borderY)];
        [rightTopPath addLineToPoint:CGPointMake(borderX + borderW, borderY + cornerLength)];
    }
    
    [rightTopPath stroke];
    
    /// 右下角小图标
    UIBezierPath *rightBottomPath = [UIBezierPath bezierPath];
    rightBottomPath.lineWidth = self.cornerWidth;
    [self.cornerColor set];
    
    if (self.cornerLocation == FWQrcodeCornerLocationInside) {
        [rightBottomPath moveToPoint:CGPointMake(borderX + borderW - insideExcess, borderY + borderH - cornerLength - insideExcess)];
        [rightBottomPath addLineToPoint:CGPointMake(borderX + borderW - insideExcess, borderY + borderH - insideExcess)];
        [rightBottomPath addLineToPoint:CGPointMake(borderX + borderW - cornerLength - insideExcess, borderY + borderH - insideExcess)];
    } else if (self.cornerLocation == FWQrcodeCornerLocationOutside) {
        [rightBottomPath moveToPoint:CGPointMake(borderX + borderW + outsideExcess, borderY + borderH - cornerLength + outsideExcess)];
        [rightBottomPath addLineToPoint:CGPointMake(borderX + borderW + outsideExcess, borderY + borderH + outsideExcess)];
        [rightBottomPath addLineToPoint:CGPointMake(borderX + borderW - cornerLength + outsideExcess, borderY + borderH + outsideExcess)];
    } else {
        [rightBottomPath moveToPoint:CGPointMake(borderX + borderW, borderY + borderH - cornerLength)];
        [rightBottomPath addLineToPoint:CGPointMake(borderX + borderW, borderY + borderH)];
        [rightBottomPath addLineToPoint:CGPointMake(borderX + borderW - cornerLength, borderY + borderH)];
    }
    
    [rightBottomPath stroke];
}

#pragma mark - Timer

- (void)addTimer
{
    [self removeTimer];
    
    CGFloat scanninglineX = 0;
    CGFloat scanninglineY = 0;
    CGFloat scanninglineW = 0;
    CGFloat scanninglineH = 0;
    if (self.scanAnimationStyle == FWQrcodeScanAnimationStyleGrid) {
        [self addSubview:self.contentView];
        [_contentView addSubview:self.scanningline];
        scanninglineW = self.borderFrame.size.width;
        scanninglineH = self.borderFrame.size.height;
        scanninglineX = 0;
        scanninglineY = - self.borderFrame.size.height;
        _scanningline.frame = CGRectMake(scanninglineX, scanninglineY, scanninglineW, scanninglineH);
    } else {
        [self addSubview:self.scanningline];
        scanninglineW = self.borderFrame.size.width;
        scanninglineH = self.scanningline.image.size.height;
        scanninglineX = self.borderFrame.origin.x;
        scanninglineY = self.borderFrame.origin.y;
        _scanningline.frame = CGRectMake(scanninglineX, scanninglineY, scanninglineW, scanninglineH);
    }
    self.timer = [NSTimer timerWithTimeInterval:self.animationTimeInterval target:self selector:@selector(beginRefreshUI) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
}

- (void)removeTimer
{
    [self.timer invalidate];
    self.timer = nil;
    [_scanningline removeFromSuperview];
    _scanningline = nil;
}

- (void)beginRefreshUI
{
    __block CGRect frame = _scanningline.frame;
    static BOOL flag = YES;
    
    __weak typeof(self) weakSelf = self;
    if (self.scanAnimationStyle == FWQrcodeScanAnimationStyleGrid) {
        if (flag) {
            frame.origin.y = - self.borderFrame.size.height;
            flag = NO;
            [UIView animateWithDuration:self.animationTimeInterval animations:^{
                frame.origin.y += 2;
                weakSelf.scanningline.frame = frame;
            } completion:nil];
        } else {
            if (_scanningline.frame.origin.y >= - self.borderFrame.size.height) {
                CGFloat scanMaxY = 0;
                if (_scanningline.frame.origin.y >= scanMaxY) {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        frame.origin.y = - self.borderFrame.size.height;
                        weakSelf.scanningline.frame = frame;
                        flag = YES;
                    });
                } else {
                    [UIView animateWithDuration:self.animationTimeInterval animations:^{
                        frame.origin.y += 2;
                        weakSelf.scanningline.frame = frame;
                    } completion:nil];
                }
            } else {
                flag = !flag;
            }
        }
    } else {
        if (flag) {
            frame.origin.y = self.borderFrame.origin.y;
            flag = NO;
            [UIView animateWithDuration:self.animationTimeInterval animations:^{
                frame.origin.y += 2;
                weakSelf.scanningline.frame = frame;
            } completion:nil];
        } else {
            if (_scanningline.frame.origin.y >= self.borderFrame.origin.y) {
                CGFloat scanMaxY = self.borderFrame.origin.y + self.borderFrame.size.height;
                if (_scanningline.frame.origin.y >= scanMaxY - self.scanningline.image.size.height) {
                    frame.origin.y = self.borderFrame.origin.y;
                    weakSelf.scanningline.frame = frame;
                    flag = YES;
                } else {
                    [UIView animateWithDuration:self.animationTimeInterval animations:^{
                        frame.origin.y += 2;
                        weakSelf.scanningline.frame = frame;
                    } completion:nil];
                }
            } else {
                flag = !flag;
            }
        }
    }
}

- (UIImageView *)scanningline
{
    if (!_scanningline) {
        _scanningline = [[UIImageView alloc] init];
        if ([self.scanImageName isKindOfClass:[UIImage class]]) {
            _scanningline.image = (UIImage *)self.scanImageName;
        } else if ([self.scanImageName isKindOfClass:[NSString class]]) {
            _scanningline.image = [UIImage imageNamed:self.scanImageName];
        } else {
            _scanningline.image = nil;
        }
    }
    return _scanningline;
}

@end
