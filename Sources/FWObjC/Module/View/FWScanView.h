//
//  FWScanView.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWScanCode

@class FWScanCode;

NS_SWIFT_NAME(ScanCodeDelegate)
@protocol FWScanCodeDelegate <NSObject>

/// 扫描二维码结果函数
///
/// @param scanCode     FWScanCode 对象
/// @param result       扫描二维码数据
- (void)scanCode:(FWScanCode *)scanCode result:(nullable NSString *)result;

@end

NS_SWIFT_NAME(ScanCodeSampleBufferDelegate)
@protocol FWScanCodeSampleBufferDelegate <NSObject>

/// 扫描时捕获外界光线强弱函数
///
/// @param scanCode     FWScanCode 对象
/// @param brightness   光线强弱值
- (void)scanCode:(FWScanCode *)scanCode brightness:(CGFloat)brightness;

@end

/**
 二维码、条形码扫描
 
 @see https://github.com/kingsic/SGQRCode
 */
NS_SWIFT_NAME(ScanCode)
@interface FWScanCode : NSObject

/// 预览视图，必须设置（传外界控制器视图）
@property (nonatomic, strong, nullable) UIView *preview;

/// 扫描区域，以屏幕右上角为坐标原点，取值范围：0～1，默认为整个屏幕
@property (nonatomic, assign) CGRect rectOfInterest;

/// 视频缩放因子，默认1（捕获内容）
@property (nonatomic, assign) CGFloat videoZoomFactor;

/// 扫描二维码数据代理
@property (nonatomic, weak, nullable) id<FWScanCodeDelegate> delegate;

/// 采样缓冲区代理
@property (nonatomic, weak, nullable) id<FWScanCodeSampleBufferDelegate> sampleBufferDelegate;

/// 扫描二维码回调句柄
@property (nonatomic, copy, nullable) void(^scanResultBlock)(NSString * _Nullable result);

/// 扫描二维码光线强弱回调句柄
@property (nonatomic, copy, nullable) void(^scanBrightnessBlock)(CGFloat brightness);

/// 开启扫描
- (void)startRunning;
/// 停止扫描
- (void)stopRunning;

#pragma mark - Util

/// 打开手电筒
+ (void)turnOnTorch;

/// 关闭手电筒
+ (void)turnOffTorch;

/// 配置扫描设备，比如自动聚焦等
+ (void)configCaptureDevice:(void (^)(AVCaptureDevice *device))block;

/// 检测后置摄像头是否可用
+ (BOOL)isCameraRearAvailable;

/// 播放音效
+ (void)playSoundEffect:(NSString *)file;

#pragma mark - Read

/// 读取图片中的二维码。图片过大可能导致闪退，建议先压缩再识别
///
/// @param image            图片
/// @param completion       回调方法，读取成功时，回调参数 result 等于二维码数据，否则等于 nil
+ (void)readQRCode:(UIImage *)image completion:(void (^)(NSString * _Nullable result))completion;

#pragma mark - Generate

/// 生成二维码
+ (UIImage *)generateQRCodeWithData:(NSString *)data size:(CGFloat)size;

/// 生成二维码（自定义颜色）
///
/// @param data     二维码数据
/// @param size     二维码大小
/// @param color    二维码颜色
/// @param backgroundColor    二维码背景颜色
+ (UIImage *)generateQRCodeWithData:(NSString *)data size:(CGFloat)size color:(UIColor *)color backgroundColor:(UIColor *)backgroundColor;

/// 生成带 logo 的二维码（推荐使用）
///
/// @param data     二维码数据
/// @param size     二维码大小
/// @param logoImage    logo
/// @param ratio        logo 相对二维码的比例（取值范围 0.0 ～ 0.5f）
+ (UIImage *)generateQRCodeWithData:(NSString *)data size:(CGFloat)size logoImage:(nullable UIImage *)logoImage ratio:(CGFloat)ratio;

/// 生成带 logo 的二维码（拓展）
///
/// @param data     二维码数据
/// @param size     二维码大小
/// @param logoImage    logo
/// @param ratio        logo 相对二维码的比例（取值范围 0.0 ～ 0.5f）
/// @param logoImageCornerRadius    logo 外边框圆角（取值范围 0.0 ～ 10.0f）
/// @param logoImageBorderWidth     logo 外边框宽度（取值范围 0.0 ～ 10.0f）
/// @param logoImageBorderColor     logo 外边框颜色
+ (UIImage *)generateQRCodeWithData:(NSString *)data size:(CGFloat)size logoImage:(nullable UIImage *)logoImage ratio:(CGFloat)ratio logoImageCornerRadius:(CGFloat)logoImageCornerRadius logoImageBorderWidth:(CGFloat)logoImageBorderWidth logoImageBorderColor:(nullable UIColor *)logoImageBorderColor;

@end

#pragma mark - FWScanView

typedef NS_ENUM(NSUInteger, FWScanCornerLoaction) {
    /// 默认与边框线同中心点
    FWScanCornerLoactionDefault,
    /// 在边框线内部
    FWScanCornerLoactionInside,
    /// 在边框线外部
    FWScanCornerLoactionOutside
} NS_SWIFT_NAME(ScanCornerLoaction);

NS_SWIFT_NAME(ScanViewConfigure)
@interface FWScanViewConfigure : NSObject

/// 扫描线，默认为：nil
@property (nonatomic, copy, nullable) NSString *scanline;

/// 扫描线图片，默认为：nil
@property (nonatomic, strong, nullable) UIImage *scanlineImage;

/// 扫描线每次移动的步长，默认为：3.5f
@property (nonatomic, assign) CGFloat scanlineStep;

/// 扫描线是否执行逆动画，默认为：NO
@property (nonatomic, assign) BOOL autoreverses;

/// 扫描线是否从扫描框顶部开始扫描，默认为：NO
@property (nonatomic, assign) BOOL isFromTop;

/// FWScanView 背景色，默认为：[[UIColor blackColor] colorWithAlphaComponent:0.5]
@property (nonatomic, strong) UIColor *color;

/// 是否需要辅助扫描框，默认为：NO
@property (nonatomic, assign) BOOL isShowBorder;

/// 辅助扫描框的颜色，默认为：[UIColor whiteColor]
@property (nonatomic, strong) UIColor *borderColor;

/// 辅助扫描框的宽度，默认为：0.2f
@property (nonatomic, assign) CGFloat borderWidth;

/// 辅助扫描边角位置，默认为：FWScanCornerLoactionDefault
@property (nonatomic, assign) FWScanCornerLoaction cornerLocation;

/// 辅助扫描边角颜色，默认为：[UIColor greenColor]
@property (nonatomic, strong) UIColor *cornerColor;

/// 辅助扫描边角宽度，默认为：2.0f
@property (nonatomic, assign) CGFloat cornerWidth;

/// 辅助扫描边角长度，默认为：20.0f
@property (nonatomic, assign) CGFloat cornerLength;

@end

NS_SWIFT_NAME(ScanView)
@interface FWScanView : UIView

/// 对象方法创建 FWScanView
///
/// @param frame           FWScanView 的 frame
/// @param configure       FWScanView 的配置类 FWScanViewConfigure
- (instancetype)initWithFrame:(CGRect)frame configure:(FWScanViewConfigure *)configure;

/// 当前配置
@property (nonatomic, strong, readonly) FWScanViewConfigure *configure;

/// 辅助扫描边框区域的frame
///
/// 默认x为：0.5 * (self.frame.size.width - w)
/// 默认y为：0.5 * (self.frame.size.height - w)
/// 默认width和height为：0.7 * self.frame.size.width
@property (nonatomic, assign) CGRect borderFrame;

/// 扫描区域的frame
@property (nonatomic, assign) CGRect scanFrame;

/// 双击回调方法
@property (nonatomic, copy, nullable) void (^doubleTapBlock)(BOOL selected);

/// 开始扫描
- (void)startScanning;

/// 停止扫描
- (void)stopScanning;

@end

NS_ASSUME_NONNULL_END
