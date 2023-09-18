//
//  FWScanView.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "FWScanView.h"
#import "FWProxy.h"
#import "FWToolkit.h"

#pragma mark - FWScanCode

static NSArray<AVMetadataObjectType> *fwStaticObjectTypesQRCode = nil;
static NSArray<AVMetadataObjectType> *fwStaticObjectTypesBarcode = nil;

@interface FWScanCode () <AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureDevice *device;
@property (nonatomic, strong) AVCaptureDeviceInput *deviceInput;
@property (nonatomic, strong) AVCaptureMetadataOutput *metadataOutput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic, assign) BOOL issetMetadataOutput;
@property (nonatomic, assign) BOOL issetVideoDataOutput;
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;

@end

@implementation FWScanCode

+ (NSArray<AVMetadataObjectType> *)metadataObjectTypesQRCode {
    if (!fwStaticObjectTypesQRCode) {
        fwStaticObjectTypesQRCode = @[
            AVMetadataObjectTypeQRCode,
        ];
    }
    return fwStaticObjectTypesQRCode;
}

+ (void)setMetadataObjectTypesQRCode:(NSArray<AVMetadataObjectType> *)objectTypes {
    fwStaticObjectTypesQRCode = objectTypes;
}

+ (NSArray<AVMetadataObjectType> *)metadataObjectTypesBarcode {
    if (!fwStaticObjectTypesBarcode) {
        fwStaticObjectTypesBarcode = @[
            AVMetadataObjectTypeCode39Code,
            AVMetadataObjectTypeCode39Mod43Code,
            AVMetadataObjectTypeCode93Code,
            AVMetadataObjectTypeCode128Code,
            AVMetadataObjectTypeEAN8Code,
            AVMetadataObjectTypeEAN13Code,
            AVMetadataObjectTypeUPCECode,
            AVMetadataObjectTypeInterleaved2of5Code,
        ];
    }
    return fwStaticObjectTypesBarcode;
}

+ (void)setMetadataObjectTypesBarcode:(NSArray<AVMetadataObjectType> *)objectTypes {
    fwStaticObjectTypesBarcode = objectTypes;
}

- (instancetype)init {
    if ([super init]) {
        _metadataObjectTypes = [FWScanCode metadataObjectTypesQRCode];
        
        /// 将设备输入对象添加到会话对象中
        if ([self.session canAddInput:self.deviceInput]) {
            [self.session addInput:self.deviceInput];
        }
    }
    return self;
}

- (void)dealloc {
    NSLog(@"FWScanCode did dealloc");
}

#pragma mark - Accessor

- (AVCaptureSession *)session {
    if (!_session) {
        _session = [[AVCaptureSession alloc] init];
        _session.sessionPreset = [self sessionPreset];
    }
    return _session;
}

- (AVCaptureDevice *)device {
    if (!_device) {
        _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    return _device;
}

- (AVCaptureDeviceInput *)deviceInput {
    if (!_deviceInput) {
        _deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
    }
    return _deviceInput;
}

- (AVCaptureMetadataOutput *)metadataOutput {
    if (!_metadataOutput) {
        _metadataOutput = [[AVCaptureMetadataOutput alloc] init];
        [_metadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    }
    return _metadataOutput;
}

- (AVCaptureVideoDataOutput *)videoDataOutput {
    if (!_videoDataOutput) {
        _videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
        [_videoDataOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    }
    return _videoDataOutput;
}

- (AVCaptureVideoPreviewLayer *)videoPreviewLayer {
    if (!_videoPreviewLayer) {
        _videoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
        _videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        _videoPreviewLayer.frame = self.preview.frame;
    }
    return _videoPreviewLayer;
}

- (NSString *)sessionPreset {
    if ([self.device supportsAVCaptureSessionPreset:AVCaptureSessionPreset3840x2160]) {
        return AVCaptureSessionPreset3840x2160;
    }
    if ([self.device supportsAVCaptureSessionPreset:AVCaptureSessionPreset1920x1080]) {
        return AVCaptureSessionPreset1920x1080;
    }
    if ([self.device supportsAVCaptureSessionPreset:AVCaptureSessionPreset1280x720]) {
        return AVCaptureSessionPreset1280x720;
    }
    if ([self.device supportsAVCaptureSessionPreset:AVCaptureSessionPreset640x480]) {
        return AVCaptureSessionPreset640x480;
    }
    if ([self.device supportsAVCaptureSessionPreset:AVCaptureSessionPreset352x288]) {
        return AVCaptureSessionPreset352x288;
    }
    if ([self.device supportsAVCaptureSessionPreset:AVCaptureSessionPresetHigh]) {
        return AVCaptureSessionPresetHigh;
    }
    if ([self.device supportsAVCaptureSessionPreset:AVCaptureSessionPresetMedium]) {
        return AVCaptureSessionPresetMedium;
    }
    return AVCaptureSessionPresetLow;
}

- (void)setPreview:(UIView *)preview {
    _preview = preview;
    [preview.layer insertSublayer:self.videoPreviewLayer atIndex:0];
}

- (void)setMetadataObjectTypes:(NSArray<AVMetadataObjectType> *)metadataObjectTypes {
    _metadataObjectTypes = metadataObjectTypes;
    [self setupMetadataObjectTypes];
}

- (void)setDelegate:(id<FWScanCodeDelegate>)delegate {
    _delegate = delegate;
    
    [self setupMetadataOutput];
}

- (void)setSampleBufferDelegate:(id<FWScanCodeSampleBufferDelegate>)sampleBufferDelegate {
    _sampleBufferDelegate = sampleBufferDelegate;
    
    [self setupVideoDataOutput];
}

- (void)setScanResultBlock:(void (^)(NSString * _Nullable))scanResultBlock {
    _scanResultBlock = scanResultBlock;
    
    [self setupMetadataOutput];
}

- (void)setScanBrightnessBlock:(void (^)(CGFloat))scanBrightnessBlock {
    _scanBrightnessBlock = scanBrightnessBlock;

    [self setupVideoDataOutput];
}

- (void)setRectOfInterest:(CGRect)rectOfInterest {
    _rectOfInterest = rectOfInterest;
    _metadataOutput.rectOfInterest = rectOfInterest;
}

- (CGFloat)videoZoomFactor {
    return self.device.videoZoomFactor;
}

- (void)setVideoZoomFactor:(CGFloat)factor {
    factor = MIN(MAX(self.device.minAvailableVideoZoomFactor, factor), self.device.maxAvailableVideoZoomFactor);
    if ([self.device lockForConfiguration:nil]) {
        self.device.videoZoomFactor = factor;
        [self.device unlockForConfiguration];
    }
}

- (void)setupMetadataOutput {
    if (self.issetMetadataOutput) return;
    self.issetMetadataOutput = YES;
    
    /// 将元数据输出对象添加到会话对象中
    if ([_session canAddOutput:self.metadataOutput]) {
        [_session addOutput:self.metadataOutput];
    }
    
    /// 元数据输出对象的二维码识数据别类型
    [self setupMetadataObjectTypes];
}

- (void)setupVideoDataOutput {
    if (self.issetVideoDataOutput) return;
    self.issetVideoDataOutput = YES;
    
    /// 添加捕获输出流到会话对象；构成识了别光线强弱
    if ([_session canAddOutput:self.videoDataOutput]) {
        [_session addOutput:self.videoDataOutput];
    }
}

- (void)setupMetadataObjectTypes {
    if (!self.issetMetadataOutput) return;
    
    NSMutableArray *objectTypes = [NSMutableArray array];
    for (AVMetadataObjectType objectType in self.metadataObjectTypes) {
        if ([_metadataOutput.availableMetadataObjectTypes containsObject:objectType]) {
            [objectTypes addObject:objectType];
        }
    }
    _metadataOutput.metadataObjectTypes = [objectTypes copy];
}

#pragma mark - Public

- (void)configCaptureDevice:(void (^)(AVCaptureDevice *))block
{
    if ([self.device lockForConfiguration:nil]) {
        if (block) block(self.device);
        [self.device unlockForConfiguration];
    }
}

- (void)startRunning {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        #if TARGET_OS_SIMULATOR
        #else
        if (![self.session isRunning]) {
            [self.session startRunning];
        }
        #endif
    });
}

- (void)stopRunning {
    #if TARGET_OS_SIMULATOR
    #else
    if ([self.session isRunning]) {
        [self.session stopRunning];
    }
    #endif
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    if (metadataObjects != nil && metadataObjects.count > 0) {
        AVMetadataMachineReadableCodeObject *obj = metadataObjects[0];
        NSString *resultString = obj.stringValue;

        if (self.delegate && [self.delegate respondsToSelector:@selector(scanCode:result:)]) {
            [self.delegate scanCode:self result:resultString];
        }
        if (self.scanResultBlock) {
            self.scanResultBlock(resultString);
        }
    }
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    CFDictionaryRef metadataDict = CMCopyDictionaryOfAttachments(NULL, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
    NSDictionary *metadata = [[NSMutableDictionary alloc] initWithDictionary:(__bridge NSDictionary*)metadataDict];
    CFRelease(metadataDict);
    NSDictionary *exifMetadata = [[metadata objectForKey:(NSString *)kCGImagePropertyExifDictionary] mutableCopy];
    CGFloat brightnessValue = [[exifMetadata objectForKey:(NSString *)kCGImagePropertyExifBrightnessValue] floatValue];
    
    if (self.sampleBufferDelegate && [self.sampleBufferDelegate respondsToSelector:@selector(scanCode:brightness:)]) {
        [self.sampleBufferDelegate scanCode:self brightness:brightnessValue];
    }
    if (self.scanBrightnessBlock) {
        self.scanBrightnessBlock(brightnessValue);
    }
}

#pragma mark - Torch

+ (BOOL)isTorchActive {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([device hasTorch]) {
        return device.isTorchActive;
    }
    return NO;
}

+ (void)turnOnTorch {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([device hasTorch]) {
        BOOL locked = [device lockForConfiguration:nil];
        if (locked) {
            [device setTorchMode:AVCaptureTorchModeOn];
            [device unlockForConfiguration];
        }
    }
}

+ (void)turnOffTorch {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([device hasTorch]) {
        [device lockForConfiguration:nil];
        [device setTorchMode:AVCaptureTorchModeOff];
        [device unlockForConfiguration];
    }
}

+ (BOOL)isCameraRearAvailable {
    BOOL isAvailable = [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear];
    return isAvailable;
}

+ (void)playSoundEffect:(NSString *)file {
    [UIApplication fw_playSystemSound:file completionHandler:nil];
}

#pragma mark - Read

+ (void)readQRCode:(UIImage *)image compress:(BOOL)compress completion:(void (^)(NSString * _Nullable))completion {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        UIImage *compressImage = image;
        if (compress && compressImage) {
            compressImage = [compressImage fw_compressImageWithMaxWidth:1080];
            compressImage = [compressImage fw_compressImageWithMaxLength:512 * 1024 compressRatio:0];
        }
        
        CIImage *ciImage = compressImage.CIImage ?: [CIImage imageWithCGImage:compressImage.CGImage];
        if (!ciImage) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(nil);
            });
            return;
        }
        
        CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy: CIDetectorAccuracyHigh}];
        NSArray *features = [detector featuresInImage:ciImage];
        
        NSString *messageString = nil;
        if (features.count > 0) {
            CIQRCodeFeature *feature = features[0];
            messageString = feature.messageString;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(messageString);
        });
    });
}

#pragma mark - Generate

+ (UIImage *)generateQRCodeWithData:(NSString *)data size:(CGFloat)size {
    return [self generateQRCodeWithData:data size:size color:[UIColor blackColor] backgroundColor:[UIColor whiteColor]];
}

+ (UIImage *)generateQRCodeWithData:(NSString *)data size:(CGFloat)size color:(UIColor *)color backgroundColor:(UIColor *)backgroundColor {
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
    CGFloat scale = outWidth > 0 ? (size / outWidth) : 1;
    outImage = [outImage imageByApplyingTransform:CGAffineTransformMakeScale(scale, scale)];
    return [UIImage imageWithCIImage:outImage];
}

+ (UIImage *)generateQRCodeWithData:(NSString *)data size:(CGFloat)size logoImage:(UIImage *)logoImage ratio:(CGFloat)ratio {
    return [self generateQRCodeWithData:data size:size logoImage:logoImage ratio:ratio logoImageCornerRadius:5 logoImageBorderWidth:5 logoImageBorderColor:[UIColor whiteColor]];
}

+ (UIImage *)generateQRCodeWithData:(NSString *)data size:(CGFloat)size logoImage:(UIImage *)logoImage ratio:(CGFloat)ratio logoImageCornerRadius:(CGFloat)logoImageCornerRadius logoImageBorderWidth:(CGFloat)logoImageBorderWidth logoImageBorderColor:(UIColor *)logoImageBorderColor {
    UIImage *image = [self generateQRCodeWithData:data size:size color:[UIColor blackColor] backgroundColor:[UIColor whiteColor]];
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

#pragma mark - FWScanView

@implementation FWScanViewConfiguration

- (instancetype)init {
    if (self = [super init]) {
        _isShowBorder = NO;
    }
    return self;
}

- (CGFloat)scanlineStep {
    if (!_scanlineStep) {
        return 3.5;
    }
    return _scanlineStep;
}

- (UIColor *)color {
    if (!_color) {
        return [[UIColor blackColor] colorWithAlphaComponent:0.5];
    }
    return _color;
}

- (UIColor *)borderColor {
    if (!_borderColor) {
        return [UIColor whiteColor];
    }
    return _borderColor;
}

- (CGFloat)borderWidth {
    if (!_borderWidth) {
        return 0.2;
    }
    return _borderWidth;
}

- (FWScanCornerLoaction)cornerLocation {
    if (!_cornerLocation) {
        return FWScanCornerLoactionDefault;
    }
    return _cornerLocation;
}

- (UIColor *)cornerColor {
    if (!_cornerColor) {
        _cornerColor = [UIColor greenColor];
    }
    return _cornerColor;
}

- (CGFloat)cornerWidth {
    if (!_cornerWidth) {
        return 2.0;
    }
    return _cornerWidth;
}

- (CGFloat)cornerLength {
    if (!_cornerLength) {
        return 20.0;
    }
    return _cornerLength;
}

@end

@interface FWScanView ()

@property (nonatomic, strong) FWScanViewConfiguration *configuration;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIImageView *scanlineImgView;
@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;
@property (nonatomic, strong) UIPinchGestureRecognizer *pinchGesture;
@property (nonatomic, strong) CADisplayLink *link;
@property (nonatomic, assign) BOOL isTop;
@property (nonatomic, assign) BOOL isSelected;

@end

@implementation FWScanView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.configuration = [[FWScanViewConfiguration alloc] init];
        
        [self didInitialization];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame configuration:(FWScanViewConfiguration *)configuration {
    if (self = [super initWithFrame:frame]) {
        self.configuration = configuration;
        
        [self didInitialization];
    }
    return self;
}

- (void)didInitialization {
    CGFloat w = 0.7 * self.frame.size.width;
    CGFloat h = w;
    CGFloat x = 0.5 * (self.frame.size.width - w);
    CGFloat y = 0.5 * (self.frame.size.height - h);
    _borderFrame = CGRectMake(x, y, w, h);
    _scanFrame = CGRectMake(x, y, w, h);
    
    self.backgroundColor = [UIColor clearColor];
    self.isTop = YES;
    [self addSubview:self.contentView];
    
    [self addGestureRecognizer:self.tapGesture];
    [self addGestureRecognizer:self.pinchGesture];
}

- (UIView *)contentView {
    if (!_contentView) {
        CGFloat x = _scanFrame.origin.x;
        CGFloat y = _scanFrame.origin.y;
        CGFloat w = _scanFrame.size.width;
        CGFloat h = _scanFrame.size.height;
        _contentView = [[UIView alloc] initWithFrame:CGRectMake(x, y, w, h)];
        _contentView.backgroundColor = [UIColor clearColor];
        _contentView.clipsToBounds = YES;
    }
    return _contentView;
}

- (UIImageView *)scanlineImgView {
    if (!_scanlineImgView) {
        _scanlineImgView = [[UIImageView alloc] init];
        
        UIImage *image = nil;
        if (self.configuration.scanlineImage) {
            image = self.configuration.scanlineImage;
        } else if (self.configuration.scanline) {
            image = [UIImage imageNamed:self.configuration.scanline];
        }
        _scanlineImgView.image = image;
        
        if (image) {
            [self updateScanLineFrame];
        }
    }
    return _scanlineImgView;
}

- (UITapGestureRecognizer *)tapGesture {
    if (!_tapGesture) {
        _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapAction)];
        _tapGesture.numberOfTapsRequired = 2;
        _tapGesture.enabled = NO;
    }
    return _tapGesture;
}

- (UIPinchGestureRecognizer *)pinchGesture {
    if (!_pinchGesture) {
        _pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchAction:)];
        _pinchGesture.enabled = NO;
    }
    return _pinchGesture;
}

- (void)doubleTapAction {
    self.isSelected = !self.isSelected;
    
    if (self.doubleTapBlock) {
        self.doubleTapBlock(self.isSelected);
    }
}

- (void)pinchAction:(UIPinchGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        if (self.pinchScaleBlock) self.pinchScaleBlock(0);
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        if (self.pinchScaleBlock) self.pinchScaleBlock(gesture.scale);
    }
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    if (self.configuration.isShowBorder == NO) {
        return;
    }
    
    /// 边框 frame
    CGFloat borderW = self.borderFrame.size.width;
    CGFloat borderH = self.borderFrame.size.height;
    CGFloat borderX = self.borderFrame.origin.x;
    CGFloat borderY = self.borderFrame.origin.y;
    CGFloat borderLineW = self.configuration.borderWidth;

    /// 空白区域设置
    [self.configuration.color setFill];
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
    [self.configuration.borderColor set];
    [borderPath stroke];
    
    CGFloat cornerLength = self.configuration.cornerLength;
    CGFloat insideExcess = fabs(0.5 * (self.configuration.cornerWidth - borderLineW));
    CGFloat outsideExcess = 0.5 * (borderLineW + self.configuration.cornerWidth);
    
    /// 左上角小图标
    [self leftTop:borderX borderY:borderY cornerLength:cornerLength insideExcess:insideExcess outsideExcess:outsideExcess];
    
    /// 左下角小图标
    [self leftBottom:borderX borderY:borderY borderH:borderH cornerLength:cornerLength insideExcess:insideExcess outsideExcess:outsideExcess];
    
    /// 右上角小图标
    [self rightTop:borderX borderY:borderY borderW:borderW cornerLength:cornerLength insideExcess:insideExcess outsideExcess:outsideExcess];
    
    /// 右下角小图标
    [self rightBottom:borderX borderY:borderY borderW:borderW borderH:borderH cornerLength:cornerLength insideExcess:insideExcess outsideExcess:outsideExcess];
}

- (void)leftTop:(CGFloat)borderX borderY:(CGFloat)borderY cornerLength:(CGFloat)cornerLength insideExcess:(CGFloat) insideExcess outsideExcess:(CGFloat)outsideExcess {
    UIBezierPath *leftTopPath = [UIBezierPath bezierPath];
    leftTopPath.lineWidth = self.configuration.cornerWidth;
    [self.configuration.cornerColor set];

    if (self.configuration.cornerLocation == FWScanCornerLoactionInside) {
        [leftTopPath moveToPoint:CGPointMake(borderX + insideExcess, borderY + cornerLength + insideExcess)];
        [leftTopPath addLineToPoint:CGPointMake(borderX + insideExcess, borderY + insideExcess)];
        [leftTopPath addLineToPoint:CGPointMake(borderX + cornerLength + insideExcess, borderY + insideExcess)];
    } else if (self.configuration.cornerLocation == FWScanCornerLoactionOutside) {
        [leftTopPath moveToPoint:CGPointMake(borderX - outsideExcess, borderY + cornerLength - outsideExcess)];
        [leftTopPath addLineToPoint:CGPointMake(borderX - outsideExcess, borderY - outsideExcess)];
        [leftTopPath addLineToPoint:CGPointMake(borderX + cornerLength - outsideExcess, borderY - outsideExcess)];
    } else {
        [leftTopPath moveToPoint:CGPointMake(borderX, borderY + cornerLength)];
        [leftTopPath addLineToPoint:CGPointMake(borderX, borderY)];
        [leftTopPath addLineToPoint:CGPointMake(borderX + cornerLength, borderY)];
    }

    [leftTopPath stroke];
}

- (void)rightTop:(CGFloat)borderX borderY:(CGFloat)borderY borderW:(CGFloat)borderW cornerLength:(CGFloat)cornerLength insideExcess:(CGFloat) insideExcess outsideExcess:(CGFloat)outsideExcess {
    UIBezierPath *rightTopPath = [UIBezierPath bezierPath];
    rightTopPath.lineWidth = self.configuration.cornerWidth;
    [self.configuration.cornerColor set];
    
    if (self.configuration.cornerLocation == FWScanCornerLoactionInside) {
        [rightTopPath moveToPoint:CGPointMake(borderX + borderW - cornerLength - insideExcess, borderY + insideExcess)];
        [rightTopPath addLineToPoint:CGPointMake(borderX + borderW - insideExcess, borderY + insideExcess)];
        [rightTopPath addLineToPoint:CGPointMake(borderX + borderW - insideExcess, borderY + cornerLength + insideExcess)];
    } else if (self.configuration.cornerLocation == FWScanCornerLoactionOutside) {
        [rightTopPath moveToPoint:CGPointMake(borderX + borderW - cornerLength + outsideExcess, borderY - outsideExcess)];
        [rightTopPath addLineToPoint:CGPointMake(borderX + borderW + outsideExcess, borderY - outsideExcess)];
        [rightTopPath addLineToPoint:CGPointMake(borderX + borderW + outsideExcess, borderY + cornerLength - outsideExcess)];
    } else {
        [rightTopPath moveToPoint:CGPointMake(borderX + borderW - cornerLength, borderY)];
        [rightTopPath addLineToPoint:CGPointMake(borderX + borderW, borderY)];
        [rightTopPath addLineToPoint:CGPointMake(borderX + borderW, borderY + cornerLength)];
    }

    [rightTopPath stroke];
}

- (void)leftBottom:(CGFloat)borderX borderY:(CGFloat)borderY borderH:(CGFloat)borderH cornerLength:(CGFloat)cornerLength insideExcess:(CGFloat) insideExcess outsideExcess:(CGFloat)outsideExcess {
    UIBezierPath *leftBottomPath = [UIBezierPath bezierPath];
    leftBottomPath.lineWidth = self.configuration.cornerWidth;
    [self.configuration.cornerColor set];
    
    if (self.configuration.cornerLocation == FWScanCornerLoactionInside) {
        [leftBottomPath moveToPoint:CGPointMake(borderX + cornerLength + insideExcess, borderY + borderH - insideExcess)];
        [leftBottomPath addLineToPoint:CGPointMake(borderX + insideExcess, borderY + borderH - insideExcess)];
        [leftBottomPath addLineToPoint:CGPointMake(borderX + insideExcess, borderY + borderH - cornerLength - insideExcess)];
    } else if (self.configuration.cornerLocation == FWScanCornerLoactionOutside) {
        [leftBottomPath moveToPoint:CGPointMake(borderX + cornerLength - outsideExcess, borderY + borderH + outsideExcess)];
        [leftBottomPath addLineToPoint:CGPointMake(borderX - outsideExcess, borderY + borderH + outsideExcess)];
        [leftBottomPath addLineToPoint:CGPointMake(borderX - outsideExcess, borderY + borderH - cornerLength + outsideExcess)];
    } else {
        [leftBottomPath moveToPoint:CGPointMake(borderX + cornerLength, borderY + borderH)];
        [leftBottomPath addLineToPoint:CGPointMake(borderX, borderY + borderH)];
        [leftBottomPath addLineToPoint:CGPointMake(borderX, borderY + borderH - cornerLength)];
    }

    [leftBottomPath stroke];
}

- (void)rightBottom:(CGFloat)borderX borderY:(CGFloat)borderY borderW:(CGFloat)borderW borderH:(CGFloat)borderH cornerLength:(CGFloat)cornerLength insideExcess:(CGFloat) insideExcess outsideExcess:(CGFloat)outsideExcess {
    UIBezierPath *rightBottomPath = [UIBezierPath bezierPath];
    rightBottomPath.lineWidth = self.configuration.cornerWidth;
    [self.configuration.cornerColor set];
    
    if (self.configuration.cornerLocation == FWScanCornerLoactionInside) {
        [rightBottomPath moveToPoint:CGPointMake(borderX + borderW - insideExcess, borderY + borderH - cornerLength - insideExcess)];
        [rightBottomPath addLineToPoint:CGPointMake(borderX + borderW - insideExcess, borderY + borderH - insideExcess)];
        [rightBottomPath addLineToPoint:CGPointMake(borderX + borderW - cornerLength - insideExcess, borderY + borderH - insideExcess)];
    } else if (self.configuration.cornerLocation == FWScanCornerLoactionOutside) {
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

- (void)setBorderFrame:(CGRect)borderFrame {
    _borderFrame = borderFrame;
}

- (void)setScanFrame:(CGRect)scanFrame {
    _scanFrame = scanFrame;
    
    self.contentView.frame = scanFrame;
    
    if (self.scanlineImgView.image) {
        [self updateScanLineFrame];
    }
}

- (void)setDoubleTapBlock:(void (^)(BOOL))doubleTapBlock {
    _doubleTapBlock = doubleTapBlock;
    
    self.tapGesture.enabled = doubleTapBlock ? YES : NO;
}

- (void)setPinchScaleBlock:(void (^)(CGFloat))pinchScaleBlock {
    _pinchScaleBlock = pinchScaleBlock;
    
    self.pinchGesture.enabled = pinchScaleBlock ? YES : NO;
}
    
- (void)updateScanLineFrame {
    CGFloat w = _contentView.frame.size.width;
    CGFloat h = (w * self.scanlineImgView.image.size.height) / self.scanlineImgView.image.size.width;
    CGFloat x = 0;
    CGFloat y = self.configuration.isFromTop ? -h : 0;
    self.scanlineImgView.frame = CGRectMake(x, y, w, h);
}

- (void)startScanning {
    if (self.scanlineImgView.image == nil) {
        return;
    }
    
    [self.contentView addSubview:self.scanlineImgView];
    
    if (self.link == nil) {
        self.link = [CADisplayLink displayLinkWithTarget:[FWWeakProxy proxyWithTarget:self] selector:@selector(updateUI)];
        [self.link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
}

- (void)stopScanning {
    if (self.scanlineImgView.image == nil) {
        return;
    }
    
    // 此代码防止由于外界逻辑，可能会导致多次停止
    if (self.link == nil) {
        return;
    }
    
    [self.scanlineImgView removeFromSuperview];
    self.scanlineImgView = nil;
    
    [self.link invalidate];
    self.link = nil;
}

- (void)updateUI {
    CGRect frame = self.scanlineImgView.frame;
    CGFloat contentViewHeight = CGRectGetHeight(self.contentView.frame);
    
    CGFloat scanlineY = self.scanlineImgView.frame.origin.y + (self.configuration.isFromTop ? 0 : self.scanlineImgView.frame.size.height);
    
    if (self.configuration.autoreverses) {
        if (self.isTop) {
            frame.origin.y += self.configuration.scanlineStep;
            self.scanlineImgView.frame = frame;
            
            if (contentViewHeight <= scanlineY) {
                self.isTop = NO;
            }
        } else {
            frame.origin.y -= self.configuration.scanlineStep;
            self.scanlineImgView.frame = frame;
            
            if (scanlineY <= self.scanlineImgView.frame.size.height) {
                self.isTop = YES;
            }
        }
    } else {
        if (contentViewHeight <= scanlineY) {
            CGFloat scanlineH = self.scanlineImgView.frame.size.height;
            frame.origin.y = -scanlineH + (self.configuration.isFromTop ? 0 : scanlineH);
            self.scanlineImgView.frame = frame;
        } else {
            frame.origin.y += self.configuration.scanlineStep;
            self.scanlineImgView.frame = frame;
        }
    }
}

@end
