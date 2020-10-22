/*!
 @header     UIApplication+FWFramework.m
 @indexgroup FWFramework
 @brief      UIApplication+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/17
 */

#import "UIApplication+FWFramework.h"
#import "FWEncode.h"
#import "FWAdaptive.h"
#import <StoreKit/StoreKit.h>

#pragma mark - UIApplication+FWFramework

@implementation UIApplication (FWFramework)

#pragma mark - App

+ (id)fwAppInfo:(NSString *)key
{
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:key];
}

+ (NSString *)fwAppName
{
    return [self fwAppInfo:@"CFBundleName"];
}

+ (NSString *)fwAppDisplayName
{
    NSString *displayName = [self fwAppInfo:@"CFBundleDisplayName"];
    if (!displayName) {
        displayName = [self fwAppName];
    }
    return displayName;
}

+ (NSString *)fwAppVersion
{
    return [self fwAppInfo:@"CFBundleShortVersionString"];
}

+ (NSString *)fwAppBuildVersion
{
    return [self fwAppInfo:@"CFBundleVersion"];
}

+ (NSString *)fwAppIdentifier
{
    return [self fwAppInfo:@"CFBundleIdentifier"];
}

#pragma mark - Debug

+ (BOOL)fwIsPirated
{
#if TARGET_OS_SIMULATOR
    return YES;
#else
    // root权限
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

+ (BOOL)fwIsTestflight
{
    return [[NSBundle mainBundle].appStoreReceiptURL.path containsString:@"sandboxReceipt"];
}

#pragma mark - URL

+ (void)fwOpenSafari:(id)url
{
    [self fwOpenURL:url];
}

+ (void)fwOpenAppSettings
{
    [self fwOpenURL:UIApplicationOpenSettingsURLString];
}

+ (void)fwRequestAppReview
{
    if (@available(iOS 10.3, *)) {
        if ([SKStoreReviewController respondsToSelector:@selector(requestReview)]) {
            [SKStoreReviewController requestReview];
        }
    }
}

+ (void)fwOpenAppReview:(NSString *)appId
{
    if (@available(iOS 11.0, *)) {
        [self fwOpenURL:[NSString stringWithFormat:@"itms-apps://itunes.apple.com/app/id%@?action=write-review", appId]];
    } else {
        [self fwOpenURL:[NSString stringWithFormat:@"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=%@", appId]];
    }
}

+ (void)fwSendEmail:(NSString *)email
{
    [self fwOpenURL:[NSString stringWithFormat:@"mailto:%@", email]];
}

+ (void)fwSendSms:(NSString *)phone
{
    [self fwOpenURL:[NSString stringWithFormat:@"sms:%@", phone]];
}

+ (void)fwMakeCall:(NSString *)phone
{
    // tel:为直接拨打电话
    [self fwOpenURL:[NSString stringWithFormat:@"telprompt:%@", phone]];
}

+ (AVAudioPlayer *)fwPlaySound:(NSString *)file
{
    // 设置播放模式
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];
    
    // 获取文件URL，支持绝对和相对路径
    NSURL *soundUrl = nil;
    if ([file isAbsolutePath]) {
        soundUrl = [NSURL fileURLWithPath:file];
    } else {
        soundUrl = [[NSBundle mainBundle] URLForResource:file withExtension:nil];
    }
    
    // 初始化播放器和音频
    AVAudioPlayer *audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundUrl error:NULL];
    if (![audioPlayer prepareToPlay]) {
        return nil;
    }
    
    // 自动播放
    [audioPlayer play];
    return audioPlayer;
}

+ (SystemSoundID)fwPlayAlert:(NSString *)file
{
    // 参数是否正确
    if (file.length < 1) {
        return 0;
    }
    
    // 文件是否存在
    NSString *soundFile = [[NSBundle mainBundle] pathForResource:file ofType:nil];
    if (![[NSFileManager defaultManager] fileExistsAtPath:soundFile]) {
        return 0;
    }
    
    // 播放内置声音
    NSURL *soundUrl = [NSURL fileURLWithPath:soundFile];
    SystemSoundID soundId = 0;
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)soundUrl, &soundId);
    AudioServicesPlaySystemSound(soundId);
    // 播放震动
    // AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    // 兼容9.0
    // AudioServicesPlayAlertSoundWithCompletion(soundId, ^{});
    // AudioServicesRemoveSystemSoundCompletion(soundId, ^{});
    return soundId;
}

+ (void)fwStopAlert:(SystemSoundID)soundId
{
    if (soundId == 0) {
        return;
    }
    
    // 注销播放完成回调函数
    AudioServicesRemoveSystemSoundCompletion(soundId);
    // 释放SystemSoundID
    AudioServicesDisposeSystemSoundID(soundId);
}

+ (void)fwReadText:(NSString *)text
{
    AVSpeechUtterance *speechUtterance = [[AVSpeechUtterance alloc] initWithString:text];
    speechUtterance.rate = AVSpeechUtteranceDefaultSpeechRate;
    speechUtterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"zh-CN"];
    AVSpeechSynthesizer *speechSynthesizer = [[AVSpeechSynthesizer alloc] init];
    [speechSynthesizer speakUtterance:speechUtterance];
}

@end
