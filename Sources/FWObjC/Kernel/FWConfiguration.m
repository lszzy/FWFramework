//
//  FWConfiguration.m
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import "FWConfiguration.h"
#import <objc/runtime.h>

@interface FWConfiguration ()

@property (nonatomic, assign) BOOL configurationInitialized;

@end

@implementation FWConfiguration

+ (instancetype)sharedInstance {
    FWConfiguration *instance = objc_getAssociatedObject([self class], @selector(sharedInstance));
    if (instance) return instance;
    
    @synchronized ([self class]) {
        instance = objc_getAssociatedObject([self class], @selector(sharedInstance));
        if (!instance) {
            instance = [[self alloc] init];
            objc_setAssociatedObject([self class], @selector(sharedInstance), instance, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [instance initializeConfiguration];
        }
        return instance;
    }
}

- (void)initializeConfiguration {
    if (self.configurationInitialized) return;
    self.configurationInitialized = YES;
    
    // 1. 当前模块.[配置类]+Template
    NSString *className = NSStringFromClass([self class]);
    NSString *applicationName = [NSBundle.mainBundle objectForInfoDictionaryKey:(__bridge NSString *)kCFBundleExecutableKey];
    Class templateClass = NSClassFromString([className stringByAppendingString:@"Template"]);
    // 2. 主项目.[配置类]+Template
    if (!templateClass) templateClass = NSClassFromString([NSString stringWithFormat:@"%@.%@Template", applicationName, [className componentsSeparatedByString:@"."].lastObject]);
    // 3. 当前模块.[配置类]+DefaultTemplate
    if (!templateClass) templateClass = NSClassFromString([className stringByAppendingString:@"DefaultTemplate"]);
    
    if (templateClass) {
        self.configurationTemplate = [[templateClass alloc] init];
    }
}

- (void)setConfigurationTemplate:(id<FWConfigurationTemplateProtocol>)configurationTemplate {
    _configurationTemplate = configurationTemplate;
    
    if ([configurationTemplate respondsToSelector:@selector(applyConfiguration)]) {
        [configurationTemplate applyConfiguration];
    }
}

@end
