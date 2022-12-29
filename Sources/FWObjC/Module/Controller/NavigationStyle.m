//
//  NavigationStyle.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "NavigationStyle.h"

#pragma mark - __FWNavigationBarAppearance

@implementation __FWNavigationBarAppearance

+ (NSMutableDictionary *)styleAppearances
{
    static NSMutableDictionary *appearances = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        appearances = [[NSMutableDictionary alloc] init];
    });
    return appearances;
}

+ (__FWNavigationBarAppearance *)appearanceForStyle:(__FWNavigationBarStyle)style
{
    return [[self styleAppearances] objectForKey:@(style)];
}

+ (void)setAppearance:(__FWNavigationBarAppearance *)appearance forStyle:(__FWNavigationBarStyle)style
{
    if (appearance) {
        [[self styleAppearances] setObject:appearance forKey:@(style)];
    } else {
        [[self styleAppearances] removeObjectForKey:@(style)];
    }
}

@end
