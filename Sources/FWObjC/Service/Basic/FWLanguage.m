//
//  FWLanguage.m
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import "FWLanguage.h"

NSNotificationName const FWLanguageChangedNotification = @"FWLanguageChangedNotification";

#if FWMacroSPM



#else

#import <FWFramework/FWFramework-Swift.h>

#endif

#pragma mark - NSString+FWLanguage

@implementation NSString (FWLanguage)

- (NSString *)fw_localized
{
    return [NSBundle fw_localizedString:self table:nil];
}

@end
