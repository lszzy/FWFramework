//
//  AlertPlugin.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "AlertPlugin.h"

#pragma mark - __FWAlertAppearance

@implementation __FWAlertAppearance

+ (__FWAlertAppearance *)appearance
{
    static __FWAlertAppearance *appearance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        appearance = [[__FWAlertAppearance alloc] init];
    });
    return appearance;
}

- (BOOL)controllerEnabled
{
    return self.titleColor || self.titleFont || self.messageColor || self.messageFont;
}

- (BOOL)actionEnabled
{
    return self.actionColor || self.preferredActionColor || self.cancelActionColor || self.destructiveActionColor || self.disabledActionColor;
}

@end
