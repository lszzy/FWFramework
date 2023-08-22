//
//  FWToolkit.m
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import "FWToolkit.h"
#import "FWUIKit.h"
#import "FWAdaptive.h"
#import "FWNavigator.h"
#import "FWProxy.h"
#import "FWSwizzle.h"
#import <SafariServices/SafariServices.h>
#import <Accelerate/Accelerate.h>
#import <StoreKit/StoreKit.h>
#import <objc/runtime.h>

#pragma mark - UIApplication+FWToolkit

@interface FWSafariViewControllerDelegate : NSObject <SFSafariViewControllerDelegate, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate, SKStoreProductViewControllerDelegate>

@end

@implementation FWSafariViewControllerDelegate

+ (FWSafariViewControllerDelegate *)sharedInstance
{
    static FWSafariViewControllerDelegate *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FWSafariViewControllerDelegate alloc] init];
    });
    return instance;
}

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller
{
    void (^completion)(void) = objc_getAssociatedObject(controller, @selector(safariViewControllerDidFinish:));
    if (completion) {
        completion();
    }
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    void (^completion)(BOOL) = objc_getAssociatedObject(controller, @selector(messageComposeViewController:didFinishWithResult:));
    [controller dismissViewControllerAnimated:YES completion:^{
        if (completion) completion(result == MessageComposeResultSent);
    }];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    void (^completion)(BOOL) = objc_getAssociatedObject(controller, @selector(mailComposeController:didFinishWithResult:error:));
    [controller dismissViewControllerAnimated:YES completion:^{
        if (completion) completion(result == MFMailComposeResultSent);
    }];
}

- (void)productViewControllerDidFinish:(SKStoreProductViewController *)controller
{
    void (^completion)(BOOL) = objc_getAssociatedObject(controller, @selector(productViewControllerDidFinish:));
    [controller dismissViewControllerAnimated:YES completion:^{
        if (completion) completion(YES);
    }];
}

@end

@implementation UIApplication (FWToolkit)

+ (NSString *)fw_appName
{
    NSString *appName = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleName"];
    return [appName isKindOfClass:[NSString class]] ? appName : @"";
}

+ (NSString *)fw_appDisplayName
{
    NSString *displayName = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    if (![displayName isKindOfClass:[NSString class]]) {
        displayName = [self fw_appName];
    }
    return displayName;
}

+ (NSString *)fw_appVersion
{
    NSString *appVersion = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    return [appVersion isKindOfClass:[NSString class]] ? appVersion : @"";
}

+ (NSString *)fw_appBuildVersion
{
    NSString *buildVersion = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"];
    return [buildVersion isKindOfClass:[NSString class]] ? buildVersion : @"";
}

+ (NSString *)fw_appIdentifier
{
    NSString *appIdentifier = [NSBundle.mainBundle objectForInfoDictionaryKey:(__bridge NSString *)kCFBundleIdentifierKey];
    return [appIdentifier isKindOfClass:[NSString class]] ? appIdentifier : @"";
}

+ (NSString *)fw_appExecutable
{
    NSString *appExecutable = [NSBundle.mainBundle objectForInfoDictionaryKey:(__bridge NSString *)kCFBundleExecutableKey];
    if (![appExecutable isKindOfClass:[NSString class]]) {
        appExecutable = [self fw_appIdentifier];
    }
    return appExecutable;
}

+ (id)fw_appInfo:(NSString *)key
{
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:key];
}

+ (NSURL *)fw_appLaunchURL:(NSDictionary<UIApplicationLaunchOptionsKey,id> *)options
{
    NSURL *url = options[UIApplicationLaunchOptionsURLKey];
    if (url) return [url isKindOfClass:[NSURL class]] ? url : nil;
    NSDictionary *dict = options[UIApplicationLaunchOptionsUserActivityDictionaryKey];
    if (![dict isKindOfClass:[NSDictionary class]]) return nil;
    NSUserActivity *userActivity = dict[@"UIApplicationLaunchOptionsUserActivityKey"];
    if (![userActivity isKindOfClass:[NSUserActivity class]]) return nil;
    if (![userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) return nil;
    return userActivity.webpageURL;
}

+ (BOOL)fw_canOpenURL:(id)url
{
    NSURL *nsurl = [self fw_urlWithString:url];
    return [[UIApplication sharedApplication] canOpenURL:nsurl];
}

+ (void)fw_openURL:(id)url
{
    [self fw_openURL:url completionHandler:nil];
}

+ (void)fw_openURL:(id)url completionHandler:(void (^)(BOOL success))completion
{
    NSURL *nsurl = [self fw_urlWithString:url];
    [[UIApplication sharedApplication] openURL:nsurl options:@{} completionHandler:completion];
}

+ (void)fw_openUniversalLinks:(id)url completionHandler:(void (^)(BOOL))completion
{
    NSURL *nsurl = [self fw_urlWithString:url];
    [[UIApplication sharedApplication] openURL:nsurl options:@{UIApplicationOpenURLOptionUniversalLinksOnly: @YES} completionHandler:completion];
}

+ (BOOL)fw_isSystemURL:(id)url
{
    NSURL *nsurl = [self fw_urlWithString:url];
    if (nsurl.scheme.lowercaseString && [@[@"tel", @"telprompt", @"sms", @"mailto"] containsObject:nsurl.scheme.lowercaseString]) {
        return YES;
    }
    if ([self fw_isAppStoreURL:nsurl]) {
        return YES;
    }
    if (nsurl.absoluteString && [nsurl.absoluteString isEqualToString:UIApplicationOpenSettingsURLString]) {
        return YES;
    }
    return NO;
}

+ (BOOL)fw_isSchemeURL:(id)url
{
    NSURL *nsurl = [self fw_urlWithString:url];
    if (nsurl.scheme.length < 1) return NO;
    if (nsurl.isFileURL || [self fw_isHttpURL:url]) return NO;
    return YES;
}

+ (BOOL)fw_isHttpURL:(id)url
{
    NSString *urlString = [url isKindOfClass:[NSURL class]] ? [(NSURL *)url absoluteString] : url;
    return [urlString.lowercaseString hasPrefix:@"http://"] || [urlString.lowercaseString hasPrefix:@"https://"];
}

+ (BOOL)fw_isAppStoreURL:(id)url
{
    // itms-apps等
    NSURL *nsurl = [self fw_urlWithString:url];
    if ([nsurl.scheme.lowercaseString hasPrefix:@"itms"]) {
        return YES;
    // https://apps.apple.com/等
    } else if ([nsurl.host.lowercaseString isEqualToString:@"itunes.apple.com"] ||
               [nsurl.host.lowercaseString isEqualToString:@"apps.apple.com"]) {
        return YES;
    }
    return NO;
}

+ (void)fw_openAppStore:(NSString *)appId completionHandler:(void (^)(BOOL))completion
{
    // SKStoreProductViewController可以内部打开
    [self fw_openURL:[NSString stringWithFormat:@"https://apps.apple.com/app/id%@", appId] completionHandler:completion];
}

+ (void)fw_openAppStoreReview:(NSString *)appId completionHandler:(void (^)(BOOL))completion
{
    [self fw_openURL:[NSString stringWithFormat:@"https://apps.apple.com/app/id%@?action=write-review", appId] completionHandler:completion];
}

+ (void)fw_openAppReview
{
    [SKStoreReviewController requestReview];
}

+ (void)fw_openAppSettings:(void (^)(BOOL))completion
{
    [self fw_openURL:UIApplicationOpenSettingsURLString completionHandler:completion];
}

+ (void)fw_openMailApp:(NSString *)email completionHandler:(void (^)(BOOL))completion
{
    [self fw_openURL:[NSString stringWithFormat:@"mailto:%@", email] completionHandler:completion];
}

+ (void)fw_openMessageApp:(NSString *)phone completionHandler:(void (^)(BOOL))completion
{
    [self fw_openURL:[NSString stringWithFormat:@"sms:%@", phone] completionHandler:completion];
}

+ (void)fw_openPhoneApp:(NSString *)phone completionHandler:(void (^)(BOOL))completion
{
    // tel:为直接拨打电话
    [self fw_openURL:[NSString stringWithFormat:@"telprompt:%@", phone] completionHandler:completion];
}

+ (void)fw_openActivityItems:(NSArray *)activityItems excludedTypes:(NSArray<UIActivityType> *)excludedTypes customBlock:(void (^)(UIActivityViewController *))customBlock
{
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    activityController.excludedActivityTypes = excludedTypes;
    // 兼容iPad，默认居中显示
    UIViewController *viewController = [FWNavigator topPresentedController];
    if ([UIDevice fw_isIpad] && activityController.popoverPresentationController) {
        UIView *ancestorView = [viewController fw_ancestorView];
        UIPopoverPresentationController *popoverController = activityController.popoverPresentationController;
        popoverController.sourceView = ancestorView;
        popoverController.sourceRect = CGRectMake(ancestorView.center.x, ancestorView.center.y, 0, 0);
        popoverController.permittedArrowDirections = 0;
    }
    if (customBlock) customBlock(activityController);
    [viewController presentViewController:activityController animated:YES completion:nil];
}

+ (void)fw_openSafariController:(id)url
{
    [self fw_openSafariController:url completionHandler:nil];
}

+ (void)fw_openSafariController:(id)url completionHandler:(nullable void (^)(void))completion
{
    if (![self fw_isHttpURL:url]) return;
    
    NSURL *nsurl = [self fw_urlWithString:url];
    SFSafariViewController *safariController = [[SFSafariViewController alloc] initWithURL:nsurl];
    if (completion) {
        objc_setAssociatedObject(safariController, @selector(safariViewControllerDidFinish:), completion, OBJC_ASSOCIATION_COPY_NONATOMIC);
        safariController.delegate = [FWSafariViewControllerDelegate sharedInstance];
    }
    [FWNavigator presentViewController:safariController animated:YES completion:nil];
}

+ (void)fw_openMessageController:(MFMessageComposeViewController *)controller completionHandler:(void (^)(BOOL))completion
{
    if (!controller || ![MFMessageComposeViewController canSendText]) {
        if (completion) completion(NO);
        return;
    }
    
    if (completion) {
        objc_setAssociatedObject(controller, @selector(messageComposeViewController:didFinishWithResult:), completion, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
    controller.messageComposeDelegate = [FWSafariViewControllerDelegate sharedInstance];
    [FWNavigator presentViewController:controller animated:YES completion:nil];
}

+ (void)fw_openMailController:(MFMailComposeViewController *)controller completionHandler:(void (^)(BOOL))completion
{
    if (!controller || ![MFMailComposeViewController canSendMail]) {
        if (completion) completion(NO);
        return;
    }
    
    if (completion) {
        objc_setAssociatedObject(controller, @selector(mailComposeController:didFinishWithResult:error:), completion, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
    controller.mailComposeDelegate = [FWSafariViewControllerDelegate sharedInstance];
    [FWNavigator presentViewController:controller animated:YES completion:nil];
}

+ (void)fw_openStoreController:(NSDictionary<NSString *,id> *)parameters completionHandler:(void (^)(BOOL))completion
{
    SKStoreProductViewController *viewController = [[SKStoreProductViewController alloc] init];
    viewController.delegate = [FWSafariViewControllerDelegate sharedInstance];
    [viewController loadProductWithParameters:parameters completionBlock:^(BOOL result, NSError * _Nullable error) {
        if (!result) {
            if (completion) completion(NO);
            return;
        }
        
        objc_setAssociatedObject(viewController, @selector(productViewControllerDidFinish:), completion, OBJC_ASSOCIATION_COPY_NONATOMIC);
        [FWNavigator presentViewController:viewController animated:YES completion:nil];
    }];
}

+ (AVPlayerViewController *)fw_openVideoPlayer:(id)url
{
    AVPlayer *player = nil;
    if ([url isKindOfClass:[AVPlayerItem class]]) {
        player = [AVPlayer playerWithPlayerItem:(AVPlayerItem *)url];
    } else if ([url isKindOfClass:[NSURL class]]) {
        player = [AVPlayer playerWithURL:(NSURL *)url];
    } else if ([url isKindOfClass:[NSString class]]) {
        NSURL *videoURL = [self fw_urlWithString:url];
        if (videoURL) player = [AVPlayer playerWithURL:videoURL];
    }
    if (!player) return nil;
    
    AVPlayerViewController *viewController = [[AVPlayerViewController alloc] init];
    viewController.player = player;
    return viewController;
}

+ (AVAudioPlayer *)fw_openAudioPlayer:(id)url
{
    // 设置播放模式示例
    // [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];
    
    NSURL *audioURL = nil;
    if ([url isKindOfClass:[NSURL class]]) {
        audioURL = (NSURL *)url;
    } else if ([url isKindOfClass:[NSString class]]) {
        if ([url isAbsolutePath]) {
            audioURL = [NSURL fileURLWithPath:url];
        } else {
            audioURL = [[NSBundle mainBundle] URLForResource:url withExtension:nil];
        }
    }
    if (!audioURL) return nil;
    
    AVAudioPlayer *audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioURL error:NULL];
    if (![audioPlayer prepareToPlay]) return nil;
    
    [audioPlayer play];
    return audioPlayer;
}

+ (NSURL *)fw_urlWithString:(id)url
{
    if (![url isKindOfClass:[NSString class]]) return url;
    
    NSURL *nsurl = [NSURL URLWithString:url];
    if (!nsurl && [url length] > 0) {
        nsurl = [NSURL URLWithString:[url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    }
    return nsurl;
}

+ (SystemSoundID)fw_playSystemSound:(NSString *)file completionHandler:(void (^)(void))completionHandler
{
    if (file.length < 1) return 0;
    
    NSString *soundFile = file;
    if (![file isAbsolutePath]) {
        soundFile = [[NSBundle mainBundle] pathForResource:file ofType:nil];
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:soundFile]) {
        return 0;
    }
    
    NSURL *soundUrl = [NSURL fileURLWithPath:soundFile];
    SystemSoundID soundId = 0;
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)soundUrl, &soundId);
    AudioServicesPlaySystemSoundWithCompletion(soundId, completionHandler);
    return soundId;
}

+ (void)fw_stopSystemSound:(SystemSoundID)soundId
{
    if (soundId == 0) return;
    
    AudioServicesRemoveSystemSoundCompletion(soundId);
    AudioServicesDisposeSystemSoundID(soundId);
}

+ (void)fw_playSystemVibrate:(void (^)(void))completionHandler
{
    AudioServicesPlaySystemSoundWithCompletion(kSystemSoundID_Vibrate, completionHandler);
}

+ (void)fw_playImpactFeedback:(UIImpactFeedbackStyle)style
{
    UIImpactFeedbackGenerator *feedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:style];
    [feedbackGenerator impactOccurred];
}

+ (void)fw_playSpeechUtterance:(NSString *)string language:(nullable NSString *)languageCode
{
    AVSpeechUtterance *speechUtterance = [[AVSpeechUtterance alloc] initWithString:string];
    speechUtterance.rate = AVSpeechUtteranceDefaultSpeechRate;
    speechUtterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:languageCode];
    AVSpeechSynthesizer *speechSynthesizer = [[AVSpeechSynthesizer alloc] init];
    [speechSynthesizer speakUtterance:speechUtterance];
}

+ (BOOL)fw_isPirated
{
#if TARGET_OS_SIMULATOR
    return YES;
#else
    if (getgid() <= 10) {
        return YES;
    }
    
    if ([[[NSBundle mainBundle] infoDictionary] objectForKey:@"SignerIdentity"]) {
        return YES;
    }
    
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    NSString *path = [bundlePath stringByAppendingPathComponent:@"_CodeSignature"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return YES;
    }
    
    path = [bundlePath stringByAppendingPathComponent:@"SC_Info"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return YES;
    }
    
    // 这方法可以运行时被替换掉，可以通过加密代码、修改方法名等提升检察性
    return NO;
#endif
}

+ (BOOL)fw_isTestflight
{
    return [[NSBundle mainBundle].appStoreReceiptURL.path containsString:@"sandboxReceipt"];
}

+ (void)fw_beginBackgroundTask:(void (NS_NOESCAPE ^)(void (^ _Nonnull)(void)))task expirationHandler:(void (^)(void))expirationHandler
{
    UIApplication *application = UIApplication.sharedApplication;
    __block UIBackgroundTaskIdentifier bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
        if (expirationHandler) expirationHandler();
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];

    task(^{
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    });
}

@end

#pragma mark - UIColor+FWToolkit

static BOOL fwStaticColorARGB = NO;

@implementation UIColor (FWToolkit)

- (UIColor *)fw_colorWithAlpha:(CGFloat)alpha
{
    return [self colorWithAlphaComponent:alpha];
}

- (long)fw_hexValue
{
    CGFloat r = 0, g = 0, b = 0, a = 0;
    if (![self getRed:&r green:&g blue:&b alpha:&a]) {
        if ([self getWhite:&r alpha:&a]) { g = r; b = r; }
    }
    
    int8_t red = r * 255;
    uint8_t green = g * 255;
    uint8_t blue = b * 255;
    return (red << 16) + (green << 8) + blue;
}

- (CGFloat)fw_alphaValue
{
    return CGColorGetAlpha(self.CGColor);
}

- (NSString *)fw_hexString
{
    CGFloat r = 0, g = 0, b = 0, a = 0;
    if (![self getRed:&r green:&g blue:&b alpha:&a]) {
        if ([self getWhite:&r alpha:&a]) { g = r; b = r; }
    }
    
    return [NSString stringWithFormat:@"#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255)];
}

- (NSString *)fw_hexAlphaString
{
    CGFloat r = 0, g = 0, b = 0, a = 0;
    if (![self getRed:&r green:&g blue:&b alpha:&a]) {
        if ([self getWhite:&r alpha:&a]) { g = r; b = r; }
    }
    
    if (a >= 1.0) {
        return [NSString stringWithFormat:@"#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255)];
    } else if (fwStaticColorARGB) {
        return [NSString stringWithFormat:@"#%02lX%02lX%02lX%02lX", lround(a * 255), lroundf(r * 255), lroundf(g * 255), lroundf(b * 255)];
    } else {
        return [NSString stringWithFormat:@"#%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lround(a * 255)];
    }
}

+ (BOOL)fw_colorStandardARGB
{
    return fwStaticColorARGB;
}

+ (void)setFw_colorStandardARGB:(BOOL)enabled
{
    fwStaticColorARGB = enabled;
}

+ (UIColor *)fw_randomColor
{
    NSInteger red = arc4random() % 255;
    NSInteger green = arc4random() % 255;
    NSInteger blue = arc4random() % 255;
    return [UIColor colorWithRed:red / 255.0 green:green / 255.0 blue:blue / 255.0 alpha:1.0f];
}

+ (UIColor *)fw_colorWithHex:(long)hex
{
    return [self fw_colorWithHex:hex alpha:1.0f];
}

+ (UIColor *)fw_colorWithHex:(long)hex alpha:(CGFloat)alpha
{
    float red = ((float)((hex & 0xFF0000) >> 16)) / 255.0;
    float green = ((float)((hex & 0xFF00) >> 8)) / 255.0;
    float blue = ((float)(hex & 0xFF)) / 255.0;
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

+ (UIColor *)fw_colorWithHexString:(NSString *)hexString
{
    return [self fw_colorWithHexString:hexString alpha:1.0f];
}

+ (UIColor *)fw_colorWithHexString:(NSString *)hexString alpha:(CGFloat)alpha
{
    // 处理参数
    NSString *string = hexString ? hexString.uppercaseString : @"";
    if ([string hasPrefix:@"0X"]) {
        string = [string substringFromIndex:2];
    }
    if ([string hasPrefix:@"#"]) {
        string = [string substringFromIndex:1];
    }
    
    // 检查长度
    NSUInteger length = string.length;
    if (length != 3 && length != 4 && length != 6 && length != 8) {
        return [UIColor clearColor];
    }
    
    // 解析颜色
    NSString *strR = nil, *strG = nil, *strB = nil, *strA = nil;
    if (length < 5) {
        // ARGB
        if (fwStaticColorARGB && length == 4) {
            string = [NSString stringWithFormat:@"%@%@", [string substringWithRange:NSMakeRange(1, 3)], [string substringWithRange:NSMakeRange(0, 1)]];
        }
        // RGB|RGBA
        NSString *tmpR = [string substringWithRange:NSMakeRange(0, 1)];
        NSString *tmpG = [string substringWithRange:NSMakeRange(1, 1)];
        NSString *tmpB = [string substringWithRange:NSMakeRange(2, 1)];
        strR = [NSString stringWithFormat:@"%@%@", tmpR, tmpR];
        strG = [NSString stringWithFormat:@"%@%@", tmpG, tmpG];
        strB = [NSString stringWithFormat:@"%@%@", tmpB, tmpB];
        if (length == 4) {
            NSString *tmpA = [string substringWithRange:NSMakeRange(3, 1)];
            strA = [NSString stringWithFormat:@"%@%@", tmpA, tmpA];
        }
    } else {
        // AARRGGBB
        if (fwStaticColorARGB && length == 8) {
            string = [NSString stringWithFormat:@"%@%@", [string substringWithRange:NSMakeRange(2, 6)], [string substringWithRange:NSMakeRange(0, 2)]];
        }
        // RRGGBB|RRGGBBAA
        strR = [string substringWithRange:NSMakeRange(0, 2)];
        strG = [string substringWithRange:NSMakeRange(2, 2)];
        strB = [string substringWithRange:NSMakeRange(4, 2)];
        if (length == 8) {
            strA = [string substringWithRange:NSMakeRange(6, 2)];
        }
    }
    
    // 解析颜色
    unsigned int r, g, b;
    [[NSScanner scannerWithString:strR] scanHexInt:&r];
    [[NSScanner scannerWithString:strG] scanHexInt:&g];
    [[NSScanner scannerWithString:strB] scanHexInt:&b];
    float fr = (r * 1.0f) / 255.0f;
    float fg = (g * 1.0f) / 255.0f;
    float fb = (b * 1.0f) / 255.0f;
    
    // 解析透明度，字符串的透明度优先级高于alpha参数
    if (strA) {
        unsigned int a;
        [[NSScanner scannerWithString:strA] scanHexInt:&a];
        // 计算十六进制对应透明度
        alpha = (a * 1.0f) / 255.0f;
    }
    
    return [UIColor colorWithRed:fr green:fg blue:fb alpha:alpha];
}

- (UIColor *)fw_addColor:(UIColor *)color blendMode:(CGBlendMode)blendMode
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big;
    uint8_t pixel[4] = { 0 };
    CGContextRef context = CGBitmapContextCreate(&pixel, 1, 1, 8, 4, colorSpace, bitmapInfo);
    CGContextSetFillColorWithColor(context, self.CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, 1, 1));
    CGContextSetBlendMode(context, blendMode);
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, 1, 1));
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    return [UIColor colorWithRed:pixel[0] / 255.0f green:pixel[1] / 255.0f blue:pixel[2] / 255.0f alpha:pixel[3] / 255.0f];
}

- (UIColor *)fw_brightnessColor:(CGFloat)ratio
{
    CGFloat h, s, b, a;
    [self getHue:&h saturation:&s brightness:&b alpha:&a];
    return [UIColor colorWithHue:h saturation:s brightness:b * ratio alpha:a];
}

- (BOOL)fw_isDarkColor
{
    CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha = 0.0;
    if (![self getRed:&red green:&green blue:&blue alpha:&alpha]) {
        if ([self getWhite:&red alpha:&alpha]) { green = red; blue = red; }
    }
    
    float referenceValue = 0.411;
    float colorDelta = ((red * 0.299) + (green * 0.587) + (blue * 0.114));
    
    return 1.0 - colorDelta > referenceValue;
}

+ (UIColor *)fw_gradientColorWithSize:(CGSize)size
                              colors:(NSArray *)colors
                           locations:(const CGFloat *)locations
                           direction:(UISwipeGestureRecognizerDirection)direction
{
    NSArray<NSValue *> *linePoints = [UIBezierPath fw_linePointsWithRect:CGRectMake(0, 0, size.width, size.height) direction:direction];
    CGPoint startPoint = [linePoints.firstObject CGPointValue];
    CGPoint endPoint = [linePoints.lastObject CGPointValue];
    return [self fw_gradientColorWithSize:size colors:colors locations:locations startPoint:startPoint endPoint:endPoint];
}

+ (UIColor *)fw_gradientColorWithSize:(CGSize)size
                              colors:(NSArray *)colors
                           locations:(const CGFloat *)locations
                          startPoint:(CGPoint)startPoint
                            endPoint:(CGPoint)endPoint
{
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    
    CGGradientRef gradient = CGGradientCreateWithColors(colorspace, (__bridge CFArrayRef)colors, locations);
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorspace);
    UIGraphicsEndImageContext();
    
    return [UIColor colorWithPatternImage:image];
}

@end

#pragma mark - UIFont+FWToolkit

UIFont * FWFontThin(CGFloat size) { return [UIFont fw_thinFontOfSize:size]; }
UIFont * FWFontLight(CGFloat size) { return [UIFont fw_lightFontOfSize:size]; }
UIFont * FWFontRegular(CGFloat size) { return [UIFont fw_fontOfSize:size]; }
UIFont * FWFontMedium(CGFloat size) { return [UIFont fw_mediumFontOfSize:size]; }
UIFont * FWFontSemibold(CGFloat size) { return [UIFont fw_semiboldFontOfSize:size]; }
UIFont * FWFontBold(CGFloat size) { return [UIFont fw_boldFontOfSize:size]; }

static BOOL fwStaticAutoScaleFont = NO;
static BOOL fwStaticAutoFlatFont = NO;

@implementation UIFont (FWToolkit)

+ (BOOL)fw_autoScale
{
    return fwStaticAutoScaleFont;
}

+ (void)setFw_autoScale:(BOOL)autoScale
{
    fwStaticAutoScaleFont = autoScale;
}

+ (BOOL)fw_autoFlat
{
    return fwStaticAutoFlatFont;
}

+ (void)setFw_autoFlat:(BOOL)autoFlat
{
    fwStaticAutoFlatFont = autoFlat;
}

+ (UIFont *)fw_thinFontOfSize:(CGFloat)size
{
    return [self fw_fontOfSize:size weight:UIFontWeightThin];
}

+ (UIFont *)fw_lightFontOfSize:(CGFloat)size
{
    return [self fw_fontOfSize:size weight:UIFontWeightLight];
}

+ (UIFont *)fw_fontOfSize:(CGFloat)size
{
    return [self fw_fontOfSize:size weight:UIFontWeightRegular];
}

+ (UIFont *)fw_mediumFontOfSize:(CGFloat)size
{
    return [self fw_fontOfSize:size weight:UIFontWeightMedium];
}

+ (UIFont *)fw_semiboldFontOfSize:(CGFloat)size
{
    return [self fw_fontOfSize:size weight:UIFontWeightSemibold];
}

+ (UIFont *)fw_boldFontOfSize:(CGFloat)size
{
    return [self fw_fontOfSize:size weight:UIFontWeightBold];
}

+ (UIFont * _Nullable (^)(CGFloat, UIFontWeight))fw_fontBlock
{
    return objc_getAssociatedObject([UIFont class], @selector(fw_fontBlock));
}

+ (void)setFw_fontBlock:(UIFont * _Nullable (^)(CGFloat, UIFontWeight))fontBlock
{
    objc_setAssociatedObject([UIFont class], @selector(fw_fontBlock), fontBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

+ (UIFont *)fw_fontOfSize:(CGFloat)size weight:(UIFontWeight)weight
{
    if (fwStaticAutoScaleFont) {
        size = [UIScreen fw_relativeValue:size];
        if (fwStaticAutoFlatFont) size = [UIScreen fw_flatValue:size];
    }
    UIFont * _Nullable (^fontBlock)(CGFloat, UIFontWeight) = self.fw_fontBlock;
    if (fontBlock) {
        UIFont *font = fontBlock(size, weight);
        if (font) return font;
    }
    return [UIFont systemFontOfSize:size weight:weight];
}

+ (NSString *)fw_fontName:(NSString *)name weight:(UIFontWeight)weight italic:(BOOL)italic
{
    static NSDictionary<NSNumber *, NSString *> *weightSuffixes = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        weightSuffixes = @{
            @(UIFontWeightUltraLight): @"-Ultralight",
            @(UIFontWeightThin): @"-Thin",
            @(UIFontWeightLight): @"-Light",
            @(UIFontWeightRegular): @"-Regular",
            @(UIFontWeightMedium): @"-Medium",
            @(UIFontWeightSemibold): @"-Semibold",
            @(UIFontWeightBold): @"-Bold",
            @(UIFontWeightHeavy): @"-Heavy",
            @(UIFontWeightBlack): @"-Black",
        };
    });
    
    NSString *fontName = name;
    NSString *weightSuffix = [weightSuffixes objectForKey:@(weight)];
    if (weightSuffix) {
        fontName = [fontName stringByAppendingFormat:@"%@%@", weightSuffix, italic ? @"Italic" : @""];
    }
    return fontName;
}

- (BOOL)fw_isBold
{
    return (self.fontDescriptor.symbolicTraits & UIFontDescriptorTraitBold) > 0;
}

- (BOOL)fw_isItalic
{
    return (self.fontDescriptor.symbolicTraits & UIFontDescriptorTraitItalic) > 0;
}

- (UIFont *)fw_boldFont
{
    UIFontDescriptorSymbolicTraits symbolicTraits = self.fontDescriptor.symbolicTraits | UIFontDescriptorTraitBold;
    return [UIFont fontWithDescriptor:[self.fontDescriptor fontDescriptorWithSymbolicTraits:symbolicTraits] size:self.pointSize];
}

- (UIFont *)fw_nonBoldFont
{
    UIFontDescriptorSymbolicTraits symbolicTraits = self.fontDescriptor.symbolicTraits ^ UIFontDescriptorTraitBold;
    return [UIFont fontWithDescriptor:[self.fontDescriptor fontDescriptorWithSymbolicTraits:symbolicTraits] size:self.pointSize];
}

- (UIFont *)fw_italicFont
{
    UIFontDescriptorSymbolicTraits symbolicTraits = self.fontDescriptor.symbolicTraits | UIFontDescriptorTraitItalic;
    return [UIFont fontWithDescriptor:[self.fontDescriptor fontDescriptorWithSymbolicTraits:symbolicTraits] size:self.pointSize];
}

- (UIFont *)fw_nonItalicFont
{
    UIFontDescriptorSymbolicTraits symbolicTraits = self.fontDescriptor.symbolicTraits ^ UIFontDescriptorTraitItalic;
    return [UIFont fontWithDescriptor:[self.fontDescriptor fontDescriptorWithSymbolicTraits:symbolicTraits] size:self.pointSize];
}

- (CGFloat)fw_spaceHeight
{
    return self.lineHeight - self.pointSize;
}

- (CGFloat)fw_lineSpacingWithMultiplier:(CGFloat)multiplier
{
    return self.pointSize * multiplier - (self.lineHeight - self.pointSize);
}

- (CGFloat)fw_lineHeightWithMultiplier:(CGFloat)multiplier
{
    return self.pointSize * multiplier;
}

- (CGFloat)fw_lineHeightWithExpected:(CGFloat)expected
{
    return MAX(self.lineHeight, expected);
}

- (CGFloat)fw_pointHeightWithExpected:(CGFloat)expected
{
    return MAX(self.pointSize, expected);
}

- (CGFloat)fw_baselineOffset:(UIFont *)font
{
    return (self.lineHeight - font.lineHeight) / 2 + (self.descender - font.descender);
}

- (CGFloat)fw_baselineOffsetWithLineHeight:(CGFloat)lineHeight
{
    return (lineHeight - self.lineHeight) / 4;
}

@end

#pragma mark - UIImage+FWToolkit

@implementation UIImage (FWToolkit)

- (UIImage *)fw_imageWithAlpha:(CGFloat)alpha
{
    UIGraphicsBeginImageContextWithOptions(self.size, NO, self.scale);
    [self drawInRect:CGRectMake(0, 0, self.size.width, self.size.height) blendMode:kCGBlendModeNormal alpha:alpha];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)fw_imageWithTintColor:(UIColor *)tintColor
{
    return [self fw_imageWithTintColor:tintColor blendMode:kCGBlendModeDestinationIn];
}

- (UIImage *)fw_imageWithTintColor:(UIColor *)tintColor blendMode:(CGBlendMode)blendMode
{
    UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0f);
    [tintColor setFill];
    CGRect bounds = CGRectMake(0, 0, self.size.width, self.size.height);
    UIRectFill(bounds);
    [self drawInRect:bounds blendMode:blendMode alpha:1.0f];
    UIImage *tintedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return tintedImage;
}

- (UIImage *)fw_imageWithScaleSize:(CGSize)size
{
    if (size.width <= 0 || size.height <= 0) return nil;
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)fw_imageWithScaleSize:(CGSize)size contentMode:(UIViewContentMode)contentMode
{
    if (size.width <= 0 || size.height <= 0) return nil;
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    [self fw_drawInRect:CGRectMake(0, 0, size.width, size.height) withContentMode:contentMode clipsToBounds:NO];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)fw_drawInRect:(CGRect)rect withContentMode:(UIViewContentMode)contentMode clipsToBounds:(BOOL)clipsToBounds
{
    CGRect drawRect = [self fw_innerRectWithContentMode:contentMode rect:rect size:self.size];
    if (drawRect.size.width == 0 || drawRect.size.height == 0) return;
    if (clipsToBounds) {
        CGContextRef context = UIGraphicsGetCurrentContext();
        if (context) {
            CGContextSaveGState(context);
            CGContextAddRect(context, rect);
            CGContextClip(context);
            [self drawInRect:drawRect];
            CGContextRestoreGState(context);
        }
    } else {
        [self drawInRect:drawRect];
    }
}

- (CGRect)fw_innerRectWithContentMode:(UIViewContentMode)mode rect:(CGRect)rect size:(CGSize)size
{
    rect = CGRectStandardize(rect);
    size.width = size.width < 0 ? -size.width : size.width;
    size.height = size.height < 0 ? -size.height : size.height;
    CGPoint center = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
    switch (mode) {
        case UIViewContentModeScaleAspectFit:
        case UIViewContentModeScaleAspectFill: {
            if (rect.size.width < 0.01 || rect.size.height < 0.01 ||
                size.width < 0.01 || size.height < 0.01) {
                rect.origin = center;
                rect.size = CGSizeZero;
            } else {
                CGFloat scale;
                if (mode == UIViewContentModeScaleAspectFit) {
                    if (size.width / size.height < rect.size.width / rect.size.height) {
                        scale = rect.size.height / size.height;
                    } else {
                        scale = rect.size.width / size.width;
                    }
                } else {
                    if (size.width / size.height < rect.size.width / rect.size.height) {
                        scale = rect.size.width / size.width;
                    } else {
                        scale = rect.size.height / size.height;
                    }
                }
                size.width *= scale;
                size.height *= scale;
                rect.size = size;
                rect.origin = CGPointMake(center.x - size.width * 0.5, center.y - size.height * 0.5);
            }
        } break;
        case UIViewContentModeCenter: {
            rect.size = size;
            rect.origin = CGPointMake(center.x - size.width * 0.5, center.y - size.height * 0.5);
        } break;
        case UIViewContentModeTop: {
            rect.origin.x = center.x - size.width * 0.5;
            rect.size = size;
        } break;
        case UIViewContentModeBottom: {
            rect.origin.x = center.x - size.width * 0.5;
            rect.origin.y += rect.size.height - size.height;
            rect.size = size;
        } break;
        case UIViewContentModeLeft: {
            rect.origin.y = center.y - size.height * 0.5;
            rect.size = size;
        } break;
        case UIViewContentModeRight: {
            rect.origin.y = center.y - size.height * 0.5;
            rect.origin.x += rect.size.width - size.width;
            rect.size = size;
        } break;
        case UIViewContentModeTopLeft: {
            rect.size = size;
        } break;
        case UIViewContentModeTopRight: {
            rect.origin.x += rect.size.width - size.width;
            rect.size = size;
        } break;
        case UIViewContentModeBottomLeft: {
            rect.origin.y += rect.size.height - size.height;
            rect.size = size;
        } break;
        case UIViewContentModeBottomRight: {
            rect.origin.x += rect.size.width - size.width;
            rect.origin.y += rect.size.height - size.height;
            rect.size = size;
        } break;
        case UIViewContentModeScaleToFill:
        case UIViewContentModeRedraw:
        default: {
            rect = rect;
        }
    }
    return rect;
}

- (UIImage *)fw_imageWithCropRect:(CGRect)rect
{
    rect.origin.x *= self.scale;
    rect.origin.y *= self.scale;
    rect.size.width *= self.scale;
    rect.size.height *= self.scale;
    if (rect.size.width <= 0 || rect.size.height <= 0) return nil;
    CGImageRef imageRef = CGImageCreateWithImageInRect(self.CGImage, rect);
    UIImage *image = [UIImage imageWithCGImage:imageRef scale:self.scale orientation:self.imageOrientation];
    CGImageRelease(imageRef);
    return image;
}

- (UIImage *)fw_imageWithInsets:(UIEdgeInsets)insets color:(UIColor *)color
{
    CGSize size = self.size;
    size.width -= insets.left + insets.right;
    size.height -= insets.top + insets.bottom;
    if (size.width <= 0 || size.height <= 0) return nil;
    CGRect rect = CGRectMake(-insets.left, -insets.top, self.size.width, self.size.height);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (color) {
        CGContextSetFillColorWithColor(context, color.CGColor);
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathAddRect(path, NULL, CGRectMake(0, 0, size.width, size.height));
        CGPathAddRect(path, NULL, rect);
        CGContextAddPath(context, path);
        CGContextEOFillPath(context);
        CGPathRelease(path);
    }
    [self drawInRect:rect];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)fw_imageWithCapInsets:(UIEdgeInsets)insets
{
    return [self resizableImageWithCapInsets:insets];
}

- (UIImage *)fw_imageWithCapInsets:(UIEdgeInsets)insets resizingMode:(UIImageResizingMode)resizingMode
{
    return [self resizableImageWithCapInsets:insets resizingMode:resizingMode];
}

- (UIImage *)fw_imageWithCornerRadius:(CGFloat)radius
{
    UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0f);
    CGRect rect = CGRectMake(0, 0, self.size.width, self.size.height);
    [[UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:radius] addClip];
    
    [self drawInRect:rect];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)fw_imageWithRotateDegree:(CGFloat)degree
{
    return [self fw_imageWithRotateDegree:degree fitSize:YES];
}

- (UIImage *)fw_imageWithRotateDegree:(CGFloat)degree fitSize:(BOOL)fitSize
{
    CGFloat radians = degree * M_PI / 180.0;
    size_t width = (size_t)CGImageGetWidth(self.CGImage);
    size_t height = (size_t)CGImageGetHeight(self.CGImage);
    CGRect newRect = CGRectApplyAffineTransform(CGRectMake(0., 0., width, height),
                                                fitSize ? CGAffineTransformMakeRotation(radians) : CGAffineTransformIdentity);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 (size_t)newRect.size.width,
                                                 (size_t)newRect.size.height,
                                                 8,
                                                 (size_t)newRect.size.width * 4,
                                                 colorSpace,
                                                 kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    if (!context) return nil;
    
    CGContextSetShouldAntialias(context, true);
    CGContextSetAllowsAntialiasing(context, true);
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGContextTranslateCTM(context, +(newRect.size.width * 0.5), +(newRect.size.height * 0.5));
    CGContextRotateCTM(context, radians);
    
    CGContextDrawImage(context, CGRectMake(-(width * 0.5), -(height * 0.5), width, height), self.CGImage);
    CGImageRef imgRef = CGBitmapContextCreateImage(context);
    UIImage *img = [UIImage imageWithCGImage:imgRef scale:self.scale orientation:self.imageOrientation];
    CGImageRelease(imgRef);
    CGContextRelease(context);
    return img;
}

- (UIImage *)fw_imageWithMaskImage:(UIImage *)maskImage
{
    UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClipToMask(context, CGRectMake(0.0f, 0.0f, self.size.width, self.size.height), maskImage.CGImage);
    
    [self drawAtPoint:CGPointZero];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)fw_imageWithMergeImage:(UIImage *)mergeImage atPoint:(CGPoint)point
{
    UIGraphicsBeginImageContextWithOptions(self.size, NO, 0);
    [self drawInRect:CGRectMake(0, 0, self.size.width, self.size.height)];
    [mergeImage drawAtPoint:point];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)fw_imageWithFilter:(CIFilter *)filter
{
    CIImage *inputImage;
    if (self.CIImage) {
        inputImage = self.CIImage;
    } else {
        CGImageRef imageRef = self.CGImage;
        if (!imageRef) return nil;
        inputImage = [CIImage imageWithCGImage:imageRef];
    }
    if (!inputImage) return nil;
    
    CIContext *context = [CIContext context];
    [filter setValue:inputImage forKey:kCIInputImageKey];
    CIImage *outputImage = filter.outputImage;
    if (!outputImage) return nil;
    
    CGImageRef imageRef = [context createCGImage:outputImage fromRect:outputImage.extent];
    if (!imageRef) return nil;
    UIImage *image = [UIImage imageWithCGImage:imageRef scale:self.scale orientation:self.imageOrientation];
    CGImageRelease(imageRef);
    return image;
}

- (UIImage *)fw_compressImageWithMaxLength:(NSInteger)maxLength
{
    NSData *data = [self fw_compressDataWithMaxLength:maxLength compressRatio:0];
    return [[UIImage alloc] initWithData:data];
}

- (NSData *)fw_compressDataWithMaxLength:(NSInteger)maxLength compressRatio:(CGFloat)compressRatio
{
    CGFloat compress = 1.f;
    CGFloat stepCompress = compressRatio > 0 ? compressRatio : 0.1f;
    NSData *data = self.fw_hasAlpha
        ? UIImagePNGRepresentation(self)
        : UIImageJPEGRepresentation(self, compress);
    while (data.length > maxLength && compress > stepCompress) {
        compress -= stepCompress;
        data = UIImageJPEGRepresentation(self, compress);
    }
    return data;
}

- (UIImage *)fw_compressImageWithMaxWidth:(NSInteger)maxWidth
{
    CGSize newSize = [self fw_scaleSizeWithMaxWidth:maxWidth];
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0);
    [self drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (CGSize)fw_scaleSizeWithMaxWidth:(CGFloat)maxWidth
{
    if (maxWidth <= 0) {
        return self.size;
    }
    
    CGFloat width = self.size.width;
    CGFloat height = self.size.height;
    if (width > maxWidth || height > maxWidth) {
        CGFloat newWidth = 0.0f;
        CGFloat newHeight = 0.0f;
        if (width > height) {
            newWidth = maxWidth;
            newHeight = newWidth * height / width;
        } else if (height > width) {
            newHeight = maxWidth;
            newWidth = newHeight * width / height;
        } else {
            newWidth = maxWidth;
            newHeight = maxWidth;
        }
        return CGSizeMake(newWidth, newHeight);
    } else {
        return CGSizeMake(width, height);
    }
}

- (UIImage *)fw_originalImage
{
    return [self imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

- (UIImage *)fw_templateImage
{
    return [self imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

- (BOOL)fw_hasAlpha
{
    if (self.CGImage == NULL) return NO;
    CGImageAlphaInfo alpha = CGImageGetAlphaInfo(self.CGImage) & kCGBitmapAlphaInfoMask;
    return (alpha == kCGImageAlphaFirst ||
            alpha == kCGImageAlphaLast ||
            alpha == kCGImageAlphaPremultipliedFirst ||
            alpha == kCGImageAlphaPremultipliedLast);
}

- (CGSize)fw_pixelSize
{
    return CGSizeMake(self.size.width * self.scale, self.size.height * self.scale);
}

+ (UIImage *)fw_imageWithView:(UIView *)view
{
    if (!view) return nil;
    
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, 0);
    if (view.window) {
        [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
    } else {
        [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    }
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (UIImage *)fw_imageWithColor:(UIColor *)color
{
    return [self fw_imageWithColor:color size:CGSizeMake(1.0f, 1.0f)];
}

+ (UIImage *)fw_imageWithColor:(UIColor *)color size:(CGSize)size
{
    return [self fw_imageWithColor:color size:size cornerRadius:0];
}

+ (UIImage *)fw_imageWithColor:(UIColor *)color size:(CGSize)size cornerRadius:(CGFloat)radius
{
    if (!color || size.width <= 0 || size.height <= 0) return nil;
    
    CGRect rect = CGRectMake(0.0f, 0.0f, size.width, size.height);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    if (radius > 0) {
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:radius];
        [path addClip];
        [path fill];
    } else {
        CGContextFillRect(context, rect);
    }
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (UIImage *)fw_imageWithSize:(CGSize)size block:(void (NS_NOESCAPE ^)(CGContextRef))block
{
    if (!block) return nil;
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context) return nil;
    block(context);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)fw_saveImageWithCompletion:(void (^)(NSError * _Nullable))completion
{
    objc_setAssociatedObject(self, @selector(fw_saveImageWithCompletion:), completion, OBJC_ASSOCIATION_COPY_NONATOMIC);
    UIImageWriteToSavedPhotosAlbum(self, self, @selector(fw_innerImage:didFinishSavingWithError:contextInfo:), NULL);
}

+ (void)fw_saveVideo:(NSString *)videoPath withCompletion:(nullable void (^)(NSError * _Nullable))completion
{
    objc_setAssociatedObject(self, @selector(fw_saveVideo:withCompletion:), completion, OBJC_ASSOCIATION_COPY_NONATOMIC);
    if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(videoPath)) {
        UISaveVideoAtPathToSavedPhotosAlbum(videoPath, self, @selector(fw_innerVideo:didFinishSavingWithError:contextInfo:), NULL);
    }
}

- (void)fw_innerImage:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    void (^block)(NSError *error) = objc_getAssociatedObject(self, @selector(fw_saveImageWithCompletion:));
    objc_setAssociatedObject(self, @selector(fw_saveImageWithCompletion:), nil, OBJC_ASSOCIATION_COPY_NONATOMIC);
    if (block) {
        block(error);
    }
}

+ (void)fw_innerVideo:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    void (^block)(NSError *error) = objc_getAssociatedObject(self, @selector(fw_saveVideo:withCompletion:));
    objc_setAssociatedObject(self, @selector(fw_saveVideo:withCompletion:), nil, OBJC_ASSOCIATION_COPY_NONATOMIC);
    if (block) {
        block(error);
    }
}

- (UIImage *)fw_grayImage
{
    int width = self.size.width;
    int height = self.size.height;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    CGContextRef context = CGBitmapContextCreate(nil, width, height, 8, 0, colorSpace, kCGImageAlphaNone);
    CGColorSpaceRelease(colorSpace);
    if (context == NULL) {
        return nil;
    }
    
    CGContextDrawImage(context,CGRectMake(0, 0, width, height), self.CGImage);
    CGImageRef contextRef = CGBitmapContextCreateImage(context);
    UIImage *grayImage = [UIImage imageWithCGImage:contextRef];
    CGContextRelease(context);
    CGImageRelease(contextRef);
    
    return grayImage;
}

- (UIColor *)fw_averageColor
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char rgba[4];
    CGContextRef context = CGBitmapContextCreate(rgba, 1, 1, 8, 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    CGContextDrawImage(context, CGRectMake(0, 0, 1, 1), self.CGImage);
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    
    if (rgba[3] > 0) {
        CGFloat alpha = ((CGFloat)rgba[3]) / 255.0;
        CGFloat multiplier = alpha / 255.0;
        return [UIColor colorWithRed:((CGFloat)rgba[0]) * multiplier
                               green:((CGFloat)rgba[1]) * multiplier
                                blue:((CGFloat)rgba[2]) * multiplier
                               alpha:alpha];
    } else {
        return [UIColor colorWithRed:((CGFloat)rgba[0]) / 255.0
                               green:((CGFloat)rgba[1]) / 255.0
                                blue:((CGFloat)rgba[2]) / 255.0
                               alpha:((CGFloat)rgba[3]) / 255.0];
    }
}

- (UIImage *)fw_imageWithReflectScale:(CGFloat)scale
{
    static CGImageRef sharedMask = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(1, 256), YES, 0.0);
        CGContextRef gradientContext = UIGraphicsGetCurrentContext();
        CGFloat colors[] = {0.0, 1.0, 1.0, 1.0};
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
        CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, colors, NULL, 2);
        CGPoint gradientStartPoint = CGPointMake(0, 0);
        CGPoint gradientEndPoint = CGPointMake(0, 256);
        CGContextDrawLinearGradient(gradientContext, gradient, gradientStartPoint,
                                    gradientEndPoint, kCGGradientDrawsAfterEndLocation);
        sharedMask = CGBitmapContextCreateImage(gradientContext);
        CGGradientRelease(gradient);
        CGColorSpaceRelease(colorSpace);
        UIGraphicsEndImageContext();
    });
    
    CGFloat height = ceil(self.size.height * scale);
    CGSize size = CGSizeMake(self.size.width, height);
    CGRect bounds = CGRectMake(0.0f, 0.0f, size.width, size.height);
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextClipToMask(context, bounds, sharedMask);
    
    CGContextScaleCTM(context, 1.0f, -1.0f);
    CGContextTranslateCTM(context, 0.0f, -self.size.height);
    [self drawInRect:CGRectMake(0.0f, 0.0f, self.size.width, self.size.height)];
    
    UIImage *reflection = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return reflection;
}

- (UIImage *)fw_imageWithReflectScale:(CGFloat)scale gap:(CGFloat)gap alpha:(CGFloat)alpha
{
    UIImage *reflection = [self fw_imageWithReflectScale:scale];
    CGFloat reflectionOffset = reflection.size.height + gap;
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(self.size.width, self.size.height + reflectionOffset * 2.0f), NO, 0.0f);
    
    [reflection drawAtPoint:CGPointMake(0.0f, reflectionOffset + self.size.height + gap) blendMode:kCGBlendModeNormal alpha:alpha];
    
    [self drawAtPoint:CGPointMake(0.0f, reflectionOffset)];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)fw_imageWithShadowColor:(UIColor *)color offset:(CGSize)offset blur:(CGFloat)blur
{
    CGSize border = CGSizeMake(fabs(offset.width) + blur, fabs(offset.height) + blur);
    CGSize size = CGSizeMake(self.size.width + border.width * 2.0f, self.size.height + border.height * 2.0f);
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetShadowWithColor(context, offset, blur, color.CGColor);
    [self drawAtPoint:CGPointMake(border.width, border.height)];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)fw_maskImage
{
    NSInteger width = CGImageGetWidth(self.CGImage);
    NSInteger height = CGImageGetHeight(self.CGImage);
    
    NSInteger bytesPerRow = ((width + 3) / 4) * 4;
    void *data = calloc(bytesPerRow * height, sizeof(unsigned char *));
    CGContextRef context = CGBitmapContextCreate(data, width, height, 8, bytesPerRow, NULL, kCGImageAlphaOnly);
    CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, width, height), self.CGImage);
    
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            NSInteger index = y * bytesPerRow + x;
            ((unsigned char *)data)[index] = 255 - ((unsigned char *)data)[index];
        }
    }
    
    CGImageRef maskRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    UIImage *mask = [UIImage imageWithCGImage:maskRef];
    CGImageRelease(maskRef);
    free(data);
    
    return mask;
}

- (UIImage *)fw_imageWithBlurRadius:(CGFloat)blurRadius saturationDelta:(CGFloat)saturationDelta tintColor:(UIColor *)tintColor maskImage:(UIImage *)maskImage
{
    if (self.size.width < 1 || self.size.height < 1) {
        return nil;
    }
    if (!self.CGImage) {
        return nil;
    }
    if (maskImage && !maskImage.CGImage) {
        return nil;
    }
    
    CGRect imageRect = { CGPointZero, self.size };
    UIImage *effectImage = self;
    
    BOOL hasBlur = blurRadius > __FLT_EPSILON__;
    BOOL hasSaturationChange = fabs(saturationDelta - 1.) > __FLT_EPSILON__;
    if (hasBlur || hasSaturationChange) {
        UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0f);
        CGContextRef effectInContext = UIGraphicsGetCurrentContext();
        CGContextScaleCTM(effectInContext, 1.0, -1.0);
        CGContextTranslateCTM(effectInContext, 0, -self.size.height);
        CGContextDrawImage(effectInContext, imageRect, self.CGImage);
        
        vImage_Buffer effectInBuffer;
        effectInBuffer.data     = CGBitmapContextGetData(effectInContext);
        effectInBuffer.width    = CGBitmapContextGetWidth(effectInContext);
        effectInBuffer.height   = CGBitmapContextGetHeight(effectInContext);
        effectInBuffer.rowBytes = CGBitmapContextGetBytesPerRow(effectInContext);
        
        UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0f);
        CGContextRef effectOutContext = UIGraphicsGetCurrentContext();
        vImage_Buffer effectOutBuffer;
        effectOutBuffer.data     = CGBitmapContextGetData(effectOutContext);
        effectOutBuffer.width    = CGBitmapContextGetWidth(effectOutContext);
        effectOutBuffer.height   = CGBitmapContextGetHeight(effectOutContext);
        effectOutBuffer.rowBytes = CGBitmapContextGetBytesPerRow(effectOutContext);
        
        if (hasBlur) {
            // http://www.w3.org/TR/SVG/filters.html#feGaussianBlurElement
            CGFloat inputRadius = blurRadius * [[UIScreen mainScreen] scale];
            uint32_t radius = floor(inputRadius * 3. * sqrt(2 * M_PI) / 4 + 0.5);
            if (radius % 2 != 1) {
                radius += 1;
            }
            vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, NULL, 0, 0, radius, radius, 0, kvImageEdgeExtend);
            vImageBoxConvolve_ARGB8888(&effectOutBuffer, &effectInBuffer, NULL, 0, 0, radius, radius, 0, kvImageEdgeExtend);
            vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, NULL, 0, 0, radius, radius, 0, kvImageEdgeExtend);
        }
        BOOL effectImageBuffersAreSwapped = NO;
        if (hasSaturationChange) {
            CGFloat s = saturationDelta;
            CGFloat floatingPointSaturationMatrix[] = {
                0.0722 + 0.9278 * s,  0.0722 - 0.0722 * s,  0.0722 - 0.0722 * s,  0,
                0.7152 - 0.7152 * s,  0.7152 + 0.2848 * s,  0.7152 - 0.7152 * s,  0,
                0.2126 - 0.2126 * s,  0.2126 - 0.2126 * s,  0.2126 + 0.7873 * s,  0,
                0,                    0,                    0,  1,
            };
            const int32_t divisor = 256;
            NSUInteger matrixSize = sizeof(floatingPointSaturationMatrix)/sizeof(floatingPointSaturationMatrix[0]);
            int16_t saturationMatrix[matrixSize];
            for (NSUInteger i = 0; i < matrixSize; ++i) {
                saturationMatrix[i] = (int16_t)roundf(floatingPointSaturationMatrix[i] * divisor);
            }
            if (hasBlur) {
                vImageMatrixMultiply_ARGB8888(&effectOutBuffer, &effectInBuffer, saturationMatrix, divisor, NULL, NULL, kvImageNoFlags);
                effectImageBuffersAreSwapped = YES;
            }
            else {
                vImageMatrixMultiply_ARGB8888(&effectInBuffer, &effectOutBuffer, saturationMatrix, divisor, NULL, NULL, kvImageNoFlags);
            }
        }
        if (!effectImageBuffersAreSwapped)
            effectImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        if (effectImageBuffersAreSwapped)
            effectImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0f);
    CGContextRef outputContext = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(outputContext, 1.0, -1.0);
    CGContextTranslateCTM(outputContext, 0, -self.size.height);
    CGContextDrawImage(outputContext, imageRect, self.CGImage);
    
    if (hasBlur) {
        CGContextSaveGState(outputContext);
        if (maskImage) {
            CGContextClipToMask(outputContext, imageRect, maskImage.CGImage);
        }
        CGContextDrawImage(outputContext, imageRect, effectImage.CGImage);
        CGContextRestoreGState(outputContext);
    }
    
    if (tintColor) {
        CGContextSaveGState(outputContext);
        CGContextSetFillColorWithColor(outputContext, tintColor.CGColor);
        CGContextFillRect(outputContext, imageRect);
        CGContextRestoreGState(outputContext);
    }
    
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return outputImage;
}

- (UIImage *)fw_alphaImage
{
    if ([self fw_hasAlpha]) {
        return self;
    }
    
    CGImageRef imageRef = self.CGImage;
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    
    CGContextRef offscreenContext = CGBitmapContextCreate(NULL,
                                                          width,
                                                          height,
                                                          8,
                                                          0,
                                                          CGImageGetColorSpace(imageRef),
                                                          kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    
    CGContextDrawImage(offscreenContext, CGRectMake(0, 0, width, height), imageRef);
    CGImageRef imageRefWithAlpha = CGBitmapContextCreateImage(offscreenContext);
    UIImage *imageWithAlpha = [UIImage imageWithCGImage:imageRefWithAlpha];
    
    CGContextRelease(offscreenContext);
    CGImageRelease(imageRefWithAlpha);
    return imageWithAlpha;
}

+ (UIImage *)fw_imageWithView:(UIView *)view limitWidth:(CGFloat)limitWidth
{
    if (!view) return nil;
    
    CGAffineTransform oldTransform = view.transform;
    CGAffineTransform scaleTransform = CGAffineTransformIdentity;
    if (!isnan(limitWidth) && limitWidth > 0 && CGRectGetWidth(view.frame) > 0) {
        CGFloat maxScale = limitWidth / CGRectGetWidth(view.frame);
        CGAffineTransform transformScale = CGAffineTransformMakeScale(maxScale, maxScale);
        scaleTransform = CGAffineTransformConcat(oldTransform, transformScale);
    }
    if(!CGAffineTransformEqualToTransform(scaleTransform, CGAffineTransformIdentity)){
        view.transform = scaleTransform;
    }
    
    CGRect actureFrame = view.frame;
    // CGRectApplyAffineTransform();
    CGRect actureBounds= view.bounds;
    
    UIGraphicsBeginImageContextWithOptions(actureFrame.size, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    // CGContextScaleCTM(UIGraphicsGetCurrentContext(), 1, -1);
    CGContextTranslateCTM(context, actureFrame.size.width / 2, actureFrame.size.height / 2);
    CGContextConcatCTM(context, view.transform);
    CGPoint anchorPoint = view.layer.anchorPoint;
    CGContextTranslateCTM(context, -actureBounds.size.width * anchorPoint.x, -actureBounds.size.height * anchorPoint.y);
    if (view.window) {
        // iOS7+：更新屏幕后再截图，防止刚添加还未显示时截图失败，效率高
        [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
    } else {
        // iOS6+：截取当前状态，未添加到界面时也可截图，效率偏低
        [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    }
    UIImage *screenshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    view.transform = oldTransform;
    
    return screenshot;
}

+ (UIImage *)fw_appIconImage
{
    NSDictionary *infoPlist = [[NSBundle mainBundle] infoDictionary];
    NSString *iconName = [[infoPlist valueForKeyPath:@"CFBundleIcons.CFBundlePrimaryIcon.CFBundleIconFiles"] lastObject];
    return [UIImage imageNamed:iconName];
}

+ (UIImage *)fw_appIconImage:(CGSize)size
{
    NSString *iconName = [NSString stringWithFormat:@"AppIcon%.0fx%.0f", size.width, size.height];
    return [UIImage imageNamed:iconName];
}

+ (UIImage *)fw_imageWithPdf:(id)path
{
    return [self fw_imageWithPdf:path size:CGSizeZero];
}

+ (UIImage *)fw_imageWithPdf:(id)path size:(CGSize)size
{
    CGPDFDocumentRef pdf = NULL;
    if ([path isKindOfClass:[NSData class]]) {
        CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)path);
        pdf = CGPDFDocumentCreateWithProvider(provider);
        CGDataProviderRelease(provider);
    } else if ([path isKindOfClass:[NSString class]]) {
        pdf = CGPDFDocumentCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:path]);
    }
    if (!pdf) return nil;
    
    CGPDFPageRef page = CGPDFDocumentGetPage(pdf, 1);
    if (!page) {
        CGPDFDocumentRelease(pdf);
        return nil;
    }
    
    CGRect pdfRect = CGPDFPageGetBoxRect(page, kCGPDFCropBox);
    CGSize pdfSize = CGSizeEqualToSize(size, CGSizeZero) ? pdfRect.size : size;
    CGFloat scale = [UIScreen mainScreen].scale;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(NULL, pdfSize.width * scale, pdfSize.height * scale, 8, 0, colorSpace, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    if (!ctx) {
        CGColorSpaceRelease(colorSpace);
        CGPDFDocumentRelease(pdf);
        return nil;
    }
    
    CGContextScaleCTM(ctx, scale, scale);
    CGContextTranslateCTM(ctx, -pdfRect.origin.x, -pdfRect.origin.y);
    CGContextDrawPDFPage(ctx, page);
    CGPDFDocumentRelease(pdf);
    
    CGImageRef image = CGBitmapContextCreateImage(ctx);
    UIImage *pdfImage = [[UIImage alloc] initWithCGImage:image scale:scale orientation:UIImageOrientationUp];
    CGImageRelease(image);
    CGContextRelease(ctx);
    CGColorSpaceRelease(colorSpace);
    
    return pdfImage;
}

+ (UIImage *)fw_gradientImageWithSize:(CGSize)size
                              colors:(NSArray *)colors
                           locations:(const CGFloat *)locations
                           direction:(UISwipeGestureRecognizerDirection)direction
{
    NSArray<NSValue *> *linePoints = [UIBezierPath fw_linePointsWithRect:CGRectMake(0, 0, size.width, size.height) direction:direction];
    CGPoint startPoint = [linePoints.firstObject CGPointValue];
    CGPoint endPoint = [linePoints.lastObject CGPointValue];
    return [self fw_gradientImageWithSize:size colors:colors locations:locations startPoint:startPoint endPoint:endPoint];
}

+ (UIImage *)fw_gradientImageWithSize:(CGSize)size
                              colors:(NSArray *)colors
                           locations:(const CGFloat *)locations
                          startPoint:(CGPoint)startPoint
                            endPoint:(CGPoint)endPoint
{
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (!ctx) return nil;
    
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    CGContextAddRect(ctx, rect);
    CGContextClip(ctx);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)colors, locations);
    CGContextDrawLinearGradient(ctx, gradient, startPoint, endPoint, 0);
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end

#pragma mark - UIView+FWToolkit

@implementation UIView (FWToolkit)

- (CGFloat)fw_top
{
    return self.frame.origin.y;
}

- (void)setFw_top:(CGFloat)top
{
    CGRect frame = self.frame;
    frame.origin.y = top;
    self.frame = frame;
}

- (CGFloat)fw_bottom
{
    return self.fw_top + self.fw_height;
}

- (void)setFw_bottom:(CGFloat)bottom
{
    self.fw_top = bottom - self.fw_height;
}

- (CGFloat)fw_left
{
    return self.frame.origin.x;
}

- (void)setFw_left:(CGFloat)left
{
    CGRect frame = self.frame;
    frame.origin.x = left;
    self.frame = frame;
}

- (CGFloat)fw_right
{
    return self.fw_left + self.fw_width;
}

- (void)setFw_right:(CGFloat)right
{
    self.fw_left = right - self.fw_width;
}

- (CGFloat)fw_width
{
    return self.frame.size.width;
}

- (void)setFw_width:(CGFloat)width
{
    CGRect frame = self.frame;
    frame.size.width = width;
    self.frame = frame;
}

- (CGFloat)fw_height
{
    return self.frame.size.height;
}

- (void)setFw_height:(CGFloat)height
{
    CGRect frame = self.frame;
    frame.size.height = height;
    self.frame = frame;
}

- (CGFloat)fw_centerX
{
    return self.center.x;
}

- (void)setFw_centerX:(CGFloat)centerX
{
    self.center = CGPointMake(centerX, self.fw_centerY);
}

- (CGFloat)fw_centerY
{
    return self.center.y;
}

- (void)setFw_centerY:(CGFloat)centerY
{
    self.center = CGPointMake(self.fw_centerX, centerY);
}

- (CGFloat)fw_x
{
    return self.frame.origin.x;
}

- (void)setFw_x:(CGFloat)x
{
    CGRect frame = self.frame;
    frame.origin.x = x;
    self.frame = frame;
}

- (CGFloat)fw_y
{
    return self.frame.origin.y;
}

- (void)setFw_y:(CGFloat)y
{
    CGRect frame = self.frame;
    frame.origin.y = y;
    self.frame = frame;
}

- (CGPoint)fw_origin
{
    return self.frame.origin;
}

- (void)setFw_origin:(CGPoint)origin
{
    CGRect frame = self.frame;
    frame.origin = origin;
    self.frame = frame;
}

- (CGSize)fw_size
{
    return self.frame.size;
}

- (void)setFw_size:(CGSize)size
{
    CGRect frame = self.frame;
    frame.size = size;
    self.frame = frame;
}

@end

#pragma mark - UIViewController+FWToolkit

@implementation UIViewController (FWToolkit)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWSwizzleClass(UIViewController, @selector(viewDidLoad), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            FWSwizzleOriginal();
            selfObject.fw_visibleState = FWViewControllerVisibleStateDidLoad;
        }));
        
        FWSwizzleClass(UIViewController, @selector(viewWillAppear:), FWSwizzleReturn(void), FWSwizzleArgs(BOOL animated), FWSwizzleCode({
            FWSwizzleOriginal(animated);
            selfObject.fw_visibleState = FWViewControllerVisibleStateWillAppear;
        }));
        
        FWSwizzleClass(UIViewController, @selector(viewDidAppear:), FWSwizzleReturn(void), FWSwizzleArgs(BOOL animated), FWSwizzleCode({
            FWSwizzleOriginal(animated);
            selfObject.fw_visibleState = FWViewControllerVisibleStateDidAppear;
        }));
        
        FWSwizzleClass(UIViewController, @selector(viewWillDisappear:), FWSwizzleReturn(void), FWSwizzleArgs(BOOL animated), FWSwizzleCode({
            FWSwizzleOriginal(animated);
            selfObject.fw_visibleState = FWViewControllerVisibleStateWillDisappear;
        }));
        
        FWSwizzleClass(UIViewController, @selector(viewDidDisappear:), FWSwizzleReturn(void), FWSwizzleArgs(BOOL animated), FWSwizzleCode({
            FWSwizzleOriginal(animated);
            selfObject.fw_visibleState = FWViewControllerVisibleStateDidDisappear;
        }));
        
        FWSwizzleClass(UIViewController, NSSelectorFromString(@"dealloc"), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            // dealloc时不调用fw，防止释放时动态创建包装器对象
            void (^completionHandler)(id) = objc_getAssociatedObject(selfObject, @selector(fw_completionHandler));
            if (completionHandler != nil) {
                id completionResult = objc_getAssociatedObject(selfObject, @selector(fw_completionResult));
                completionHandler(completionResult);
            }
            
            FWSwizzleOriginal();
        }));
    });
}

- (FWViewControllerVisibleState)fw_visibleState
{
    return [objc_getAssociatedObject(self, @selector(fw_visibleState)) unsignedIntegerValue];
}

- (void)setFw_visibleState:(FWViewControllerVisibleState)visibleState
{
    BOOL valueChanged = self.fw_visibleState != visibleState;
    objc_setAssociatedObject(self, @selector(fw_visibleState), @(visibleState), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (valueChanged && self.fw_visibleStateChanged) {
        self.fw_visibleStateChanged(self, visibleState);
    }
}

- (void (^)(__kindof UIViewController *, FWViewControllerVisibleState))fw_visibleStateChanged
{
    return objc_getAssociatedObject(self, @selector(fw_visibleStateChanged));
}

- (void)setFw_visibleStateChanged:(void (^)(__kindof UIViewController *, FWViewControllerVisibleState))visibleStateChanged
{
    objc_setAssociatedObject(self, @selector(fw_visibleStateChanged), visibleStateChanged, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (id)fw_completionResult
{
    return objc_getAssociatedObject(self, @selector(fw_completionResult));
}

- (void)setFw_completionResult:(id)completionResult
{
    objc_setAssociatedObject(self, @selector(fw_completionResult), completionResult, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void (^)(id _Nullable))fw_completionHandler
{
    return objc_getAssociatedObject(self, @selector(fw_completionHandler));
}

- (void)setFw_completionHandler:(void (^)(id _Nullable))completionHandler
{
    objc_setAssociatedObject(self, @selector(fw_completionHandler), completionHandler, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (BOOL (^)(void))fw_allowsPopGesture
{
    return objc_getAssociatedObject(self, @selector(fw_allowsPopGesture));
}

- (void)setFw_allowsPopGesture:(BOOL (^)(void))allowsPopGesture
{
    objc_setAssociatedObject(self, @selector(fw_allowsPopGesture), allowsPopGesture, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (BOOL (^)(void))fw_shouldPopController
{
    return objc_getAssociatedObject(self, @selector(fw_shouldPopController));
}

- (void)setFw_shouldPopController:(BOOL (^)(void))shouldPopController
{
    objc_setAssociatedObject(self, @selector(fw_shouldPopController), shouldPopController, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (BOOL)allowsPopGesture
{
    BOOL (^block)(void) = objc_getAssociatedObject(self, @selector(fw_allowsPopGesture));
    if (block) return block();
    return YES;
}

- (BOOL)shouldPopController
{
    BOOL (^block)(void) = objc_getAssociatedObject(self, @selector(fw_shouldPopController));
    if (block) return block();
    return YES;
}

@end

#pragma mark - UINavigationController+FWToolkit

@interface FWInnerPopProxyTarget : NSObject <UIGestureRecognizerDelegate>

@property (nonatomic, weak) UINavigationController *navigationController;

@end

@implementation FWInnerPopProxyTarget

- (instancetype)initWithNavigationController:(UINavigationController *)navigationController
{
    self = [super init];
    if (self) {
        _navigationController = navigationController;
    }
    return self;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    UIViewController *topController = self.navigationController.topViewController;
    return topController.shouldPopController && topController.allowsPopGesture;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return [gestureRecognizer isKindOfClass:[UIScreenEdgePanGestureRecognizer class]];
}

@end

@interface FWGestureRecognizerDelegateProxy : FWDelegateProxy <UIGestureRecognizerDelegate>

@property (nonatomic, weak) UINavigationController *navigationController;

@end

@implementation FWGestureRecognizerDelegateProxy

- (BOOL)shouldForceReceive
{
    if (self.navigationController.presentedViewController != nil) return NO;
    if (self.navigationController.viewControllers.count <= 1) return NO;
    if (!self.navigationController.interactivePopGestureRecognizer.enabled) return NO;
    return self.navigationController.topViewController.allowsPopGesture;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer == self.navigationController.interactivePopGestureRecognizer) {
        // 调用钩子。如果返回NO，则不开始手势；如果返回YES，则使用系统方式
        BOOL shouldPop = self.navigationController.topViewController.shouldPopController;
        if (shouldPop) {
            if ([self.delegate respondsToSelector:@selector(gestureRecognizerShouldBegin:)]) {
                return [self.delegate gestureRecognizerShouldBegin:gestureRecognizer];
            }
        }
        return NO;
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (gestureRecognizer == self.navigationController.interactivePopGestureRecognizer) {
        if ([self.delegate respondsToSelector:@selector(gestureRecognizer:shouldReceiveTouch:)]) {
            BOOL shouldReceive = [self.delegate gestureRecognizer:gestureRecognizer shouldReceiveTouch:touch];
            if (!shouldReceive && [self shouldForceReceive]) {
                return YES;
            }
            return shouldReceive;
        }
    }
    return YES;
}

- (BOOL)_gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveEvent:(UIEvent *)event
{
    // 修复iOS13.4拦截返回失效问题，返回YES才会走后续流程
    if (gestureRecognizer == self.navigationController.interactivePopGestureRecognizer) {
        if ([self.delegate respondsToSelector:@selector(_gestureRecognizer:shouldReceiveEvent:)]) {
            BOOL shouldReceive = [self.delegate _gestureRecognizer:gestureRecognizer shouldReceiveEvent:event];
            if (!shouldReceive && [self shouldForceReceive]) {
                return YES;
            }
            return shouldReceive;
        }
    }
    return YES;
}

@end

static BOOL fwStaticPopProxyEnabled = NO;

@implementation UINavigationController (FWToolkit)

+ (void)fw_swizzlePopProxy
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWSwizzleClass(UINavigationController, @selector(navigationBar:shouldPopItem:), FWSwizzleReturn(BOOL), FWSwizzleArgs(UINavigationBar *navigationBar, UINavigationItem *item), FWSwizzleCode({
            if (fwStaticPopProxyEnabled || [selfObject fw_popProxyEnabled]) {
                // 检查并调用返回按钮钩子。如果返回NO，则不pop当前页面；如果返回YES，则使用默认方式
                if (selfObject.viewControllers.count >= navigationBar.items.count &&
                    !selfObject.topViewController.shouldPopController) {
                    return NO;
                }
            }
            
            return FWSwizzleOriginal(navigationBar, item);
        }));
        
        FWSwizzleClass(UINavigationController, @selector(viewDidLoad), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            FWSwizzleOriginal();
            if (!fwStaticPopProxyEnabled || [selfObject fw_popProxyEnabled]) return;
            
            // 拦截系统返回手势事件代理，加载自定义代理方法
            if (selfObject.interactivePopGestureRecognizer.delegate != selfObject.fw_delegateProxy) {
                selfObject.fw_delegateProxy.delegate = selfObject.interactivePopGestureRecognizer.delegate;
                selfObject.fw_delegateProxy.navigationController = selfObject;
                selfObject.interactivePopGestureRecognizer.delegate = selfObject.fw_delegateProxy;
            }
        }));
        
        FWSwizzleClass(UINavigationController, @selector(childViewControllerForStatusBarHidden), FWSwizzleReturn(UIViewController *), FWSwizzleArgs(), FWSwizzleCode({
            if (fwStaticPopProxyEnabled && selfObject.topViewController) {
                return selfObject.topViewController;
            } else {
                return FWSwizzleOriginal();
            }
        }));
        FWSwizzleClass(UINavigationController, @selector(childViewControllerForStatusBarStyle), FWSwizzleReturn(UIViewController *), FWSwizzleArgs(), FWSwizzleCode({
            if (fwStaticPopProxyEnabled && selfObject.topViewController) {
                return selfObject.topViewController;
            } else {
                return FWSwizzleOriginal();
            }
        }));
    });
}

- (BOOL)fw_popProxyEnabled
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)fw_enablePopProxy
{
    self.interactivePopGestureRecognizer.delegate = self.fw_innerPopProxyTarget;
    objc_setAssociatedObject(self, @selector(fw_popProxyEnabled), @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [UINavigationController fw_swizzlePopProxy];
}

- (FWInnerPopProxyTarget *)fw_innerPopProxyTarget
{
    FWInnerPopProxyTarget *target = objc_getAssociatedObject(self, _cmd);
    if (!target) {
        target = [[FWInnerPopProxyTarget alloc] initWithNavigationController:self];
        objc_setAssociatedObject(self, _cmd, target, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return target;
}

- (FWGestureRecognizerDelegateProxy *)fw_delegateProxy
{
    FWGestureRecognizerDelegateProxy *proxy = objc_getAssociatedObject(self, _cmd);
    if (!proxy) {
        proxy = [[FWGestureRecognizerDelegateProxy alloc] init];
        objc_setAssociatedObject(self, _cmd, proxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return proxy;
}

+ (void)fw_enablePopProxy
{
    fwStaticPopProxyEnabled = YES;
    [UINavigationController fw_swizzlePopProxy];
}

@end
