//
//  FWMediator.m
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import "FWMediator.h"
#import "Loader.h"
#import "FWPlugin.h"
#import "Logger.h"
#import <objc/message.h>
#import <objc/runtime.h>

#pragma mark - FWMediator

@interface FWMediator ()

@property (nonatomic, strong) NSMutableDictionary *moduleDict;
@property (nonatomic, strong) NSMutableDictionary *moduleInvokeDict;
@property (nonatomic, strong) __FWLoader<Protocol *, id> *moduleLoader;

@end

@implementation FWMediator

+ (instancetype)sharedInstance
{
    static FWMediator *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
        instance.moduleDict = [NSMutableDictionary dictionary];
        instance.moduleInvokeDict = [NSMutableDictionary dictionary];
        instance.moduleLoader = [[__FWLoader<Protocol *, id> alloc] init];
    });
    return instance;
}

+ (NSString *)debugDescription
{
    NSMutableString *debugDescription = [[NSMutableString alloc] init];
    NSArray *sortedKeys = [FWMediator.sharedInstance.moduleDict keysSortedByValueUsingComparator:^NSComparisonResult(Class class1, Class class2) {
        NSUInteger priority1 = [class1 respondsToSelector:@selector(priority)] ? [class1 priority] : FWModulePriorityDefault;
        NSUInteger priority2 = [class2 respondsToSelector:@selector(priority)] ? [class2 priority] : FWModulePriorityDefault;
        if (priority1 == priority2) return NSOrderedSame;
        return priority1 < priority2 ? NSOrderedDescending : NSOrderedAscending;
    }];
    NSInteger debugCount = 0;
    for (NSString *protocolName in sortedKeys) {
        [debugDescription appendFormat:@"%@. %@ : %@\n", @(++debugCount), protocolName, NSStringFromClass([FWMediator.sharedInstance.moduleDict objectForKey:protocolName])];
    }
    return [NSString stringWithFormat:@"\n========== MEDIATOR ==========\n%@========== MEDIATOR ==========", debugDescription];
}

+ (__FWLoader<Protocol *,id> *)sharedLoader
{
    return [FWMediator sharedInstance].moduleLoader;
}

+ (BOOL)registerService:(Protocol *)serviceProtocol withModule:(Class<FWModuleProtocol>)moduleClass
{
    return [self registerService:serviceProtocol withModule:moduleClass isPreset:NO];
}

+ (BOOL)presetService:(Protocol *)serviceProtocol withModule:(Class<FWModuleProtocol>)moduleClass
{
    return [self registerService:serviceProtocol withModule:moduleClass isPreset:YES];
}

+ (BOOL)registerService:(Protocol *)serviceProtocol withModule:(Class<FWModuleProtocol>)moduleClass isPreset:(BOOL)isPreset
{
    NSString *protocolName = NSStringFromProtocol(serviceProtocol);
    if (protocolName.length == 0 || !moduleClass ||
        ![moduleClass conformsToProtocol:serviceProtocol]) {
        return NO;
    }
    
    if (isPreset && ([[FWMediator sharedInstance].moduleDict objectForKey:protocolName] != nil)) {
        return NO;
    }
    
    [[FWMediator sharedInstance].moduleDict setObject:moduleClass forKey:protocolName];
    return YES;
}

+ (void)unregisterService:(Protocol *)serviceProtocol
{
    NSString *protocolName = NSStringFromProtocol(serviceProtocol);
    if (protocolName.length > 0) {
        [[FWMediator sharedInstance].moduleDict removeObjectForKey:protocolName];
    }
}

+ (id<FWModuleProtocol>)loadModule:(Protocol *)serviceProtocol
{
    NSString *protocolName = NSStringFromProtocol(serviceProtocol);
    if (protocolName.length == 0) {
        return nil;
    }
    
    Class moduleClass = [FWMediator sharedInstance].moduleDict[protocolName];
    if (!moduleClass) {
        id object = [[FWMediator sharedLoader] load:serviceProtocol];
        if (!object) return nil;
        
        [FWMediator registerService:serviceProtocol withModule:object];
        moduleClass = [FWMediator sharedInstance].moduleDict[protocolName];
        if (!moduleClass) return nil;
    }
    
    if (![moduleClass conformsToProtocol:@protocol(FWModuleProtocol)]) {
        return nil;
    }
    
    @try {
        return [moduleClass sharedInstance];
    } @catch (NSException *exception) {
        return nil;
    }
}

+ (NSArray<Class<FWModuleProtocol>> *)allRegisteredModules
{
    NSArray *modules = [FWMediator sharedInstance].moduleDict.allValues;
    NSArray *sortedModules = [modules sortedArrayUsingComparator:^NSComparisonResult(Class class1, Class class2) {
        NSUInteger priority1 = [class1 respondsToSelector:@selector(priority)] ? [class1 priority] : FWModulePriorityDefault;
        NSUInteger priority2 = [class2 respondsToSelector:@selector(priority)] ? [class2 priority] : FWModulePriorityDefault;
        if (priority1 == priority2) return NSOrderedSame;
        return priority1 < priority2 ? NSOrderedDescending : NSOrderedAscending;
    }];
    return sortedModules;
}

+ (void)setupAllModules
{
    NSArray *modules = [self allRegisteredModules];
    for (Class<FWModuleProtocol> moduleClass in modules) {
        @try {
            if (![[moduleClass sharedInstance] respondsToSelector:@selector(setup)]) continue;
            BOOL setupSync = NO;
            if ([moduleClass respondsToSelector:@selector(setupSynchronously)]) {
                setupSync = [moduleClass setupSynchronously];
            }
            if (setupSync) {
                [[moduleClass sharedInstance] setup];
            } else {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [[moduleClass sharedInstance] setup];
                });
            }
        } @catch (NSException *exception) {}
    }
    
#ifdef DEBUG
    __FWLogGroup(@"FWFramework", __FWLogTypeDebug, @"%@", FWMediator.debugDescription);
    __FWLogGroup(@"FWFramework", __FWLogTypeDebug, @"%@", FWPluginManager.debugDescription);
#endif
}

+ (BOOL)checkAllModulesWithSelector:(SEL)selector arguments:(NSArray *)arguments
{
    BOOL result = NO;
    NSArray *modules = [self allRegisteredModules];
    for (Class<FWModuleProtocol> class in modules) {
        id<FWModuleProtocol> moduleItem = [class sharedInstance];
        if ([moduleItem respondsToSelector:selector]) {
            __block BOOL shouldInvoke = YES;
            if (![[FWMediator sharedInstance].moduleInvokeDict objectForKey:NSStringFromClass([moduleItem class])]) {
                [modules enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    if ([NSStringFromClass([obj superclass]) isEqualToString:NSStringFromClass([moduleItem class])]) {
                        shouldInvoke = NO;
                        *stop = YES;
                    }
                }];
            }
            
            if (shouldInvoke) {
                if (![[FWMediator sharedInstance].moduleInvokeDict objectForKey:NSStringFromClass([moduleItem class])]) {
                    [[FWMediator sharedInstance].moduleInvokeDict setObject:moduleItem forKey:NSStringFromClass([moduleItem class])];
                }
                
                BOOL returnValue = NO;
                [self invokeTarget:moduleItem action:selector arguments:arguments returnValue:&returnValue];
                if (!result) {
                    result = returnValue;
                }
            }
        }
    }
    return result;
}

+ (BOOL)invokeTarget:(id)target action:(SEL)selector arguments:(NSArray *)arguments returnValue:(void *)result
{
    if (!target || ![target respondsToSelector:selector]) return NO;
    
    NSMethodSignature *sig = [target methodSignatureForSelector:selector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
    [invocation setTarget:target];
    [invocation setSelector:selector];
    for (NSUInteger i = 0; i< arguments.count; i++) {
        NSUInteger argIndex = i + 2;
        id argument = arguments[i];
        if ([argument isKindOfClass:NSNumber.class]) {
            BOOL shouldContinue = NO;
            NSNumber *num = (NSNumber *)argument;
            const char *type = [sig getArgumentTypeAtIndex:argIndex];
            if (strcmp(type, @encode(BOOL)) == 0) {
                BOOL rawNum = [num boolValue];
                [invocation setArgument:&rawNum atIndex:argIndex];
                shouldContinue = YES;
            } else if (strcmp(type, @encode(int)) == 0
                       || strcmp(type, @encode(short)) == 0
                       || strcmp(type, @encode(long)) == 0) {
                NSInteger rawNum = [num integerValue];
                [invocation setArgument:&rawNum atIndex:argIndex];
                shouldContinue = YES;
            } else if(strcmp(type, @encode(long long)) == 0) {
                long long rawNum = [num longLongValue];
                [invocation setArgument:&rawNum atIndex:argIndex];
                shouldContinue = YES;
            } else if (strcmp(type, @encode(unsigned int)) == 0
                       || strcmp(type, @encode(unsigned short)) == 0
                       || strcmp(type, @encode(unsigned long)) == 0) {
                NSUInteger rawNum = [num unsignedIntegerValue];
                [invocation setArgument:&rawNum atIndex:argIndex];
                shouldContinue = YES;
            } else if(strcmp(type, @encode(unsigned long long)) == 0) {
                unsigned long long rawNum = [num unsignedLongLongValue];
                [invocation setArgument:&rawNum atIndex:argIndex];
                shouldContinue = YES;
            } else if (strcmp(type, @encode(float)) == 0) {
                float rawNum = [num floatValue];
                [invocation setArgument:&rawNum atIndex:argIndex];
                shouldContinue = YES;
            } else if (strcmp(type, @encode(double)) == 0) {
                double rawNum = [num doubleValue];
                [invocation setArgument:&rawNum atIndex:argIndex];
                shouldContinue = YES;
            }
            if (shouldContinue) {
                continue;
            }
        }
        if ([argument isKindOfClass:[NSNull class]]) {
            argument = nil;
        }
        [invocation setArgument:&argument atIndex:argIndex];
    }
    [invocation invoke];
    
    NSString *methodReturnType = [NSString stringWithUTF8String:sig.methodReturnType];
    if (result && ![methodReturnType isEqualToString:@"v"]) {
        if ([methodReturnType isEqualToString:@"@"]) {
            CFTypeRef cfResult = nil;
            [invocation getReturnValue:&cfResult];
            if (cfResult) {
                CFRetain(cfResult);
                *(void**)result = (__bridge_retained void *)((__bridge_transfer id)cfResult);
            }
        } else {
            [invocation getReturnValue:result];
        }
    }
    return YES;
}

@end

#pragma mark - FWModuleBundle

@interface UIImage ()

+ (UIImage *)fw_imageNamed:(NSString *)name bundle:(NSBundle *)bundle;

@end

@implementation FWModuleBundle

+ (NSBundle *)bundle
{
    return [NSBundle mainBundle];
}

+ (UIImage *)imageNamed:(NSString *)name
{
    UIImage *image;
    if ([UIImage respondsToSelector:@selector(fw_imageNamed:bundle:)]) {
        image = [UIImage fw_imageNamed:name bundle:[self bundle]];
    } else {
        image = [UIImage imageNamed:name inBundle:[self bundle] compatibleWithTraitCollection:nil];
    }
    
    if (!image) {
        NSMutableDictionary *nameImages = objc_getAssociatedObject([self class], @selector(imageNamed:));
        if (nameImages) image = [nameImages objectForKey:name];
    }
    return image;
}

+ (void)setImage:(UIImage *)image forName:(NSString *)name
{
    NSMutableDictionary *nameImages = objc_getAssociatedObject([self class], @selector(imageNamed:));
    if (!nameImages) {
        nameImages = [[NSMutableDictionary alloc] init];
        objc_setAssociatedObject([self class], @selector(imageNamed:), nameImages, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    if (image) {
        [nameImages setObject:image forKey:name];
    } else {
        [nameImages removeObjectForKey:name];
    }
}

+ (NSString *)localizedString:(NSString *)key
{
    return [self localizedString:key table:nil];
}

+ (NSString *)localizedString:(NSString *)key table:(NSString *)table
{
    return [[self bundle] localizedStringForKey:key value:nil table:table];
}

+ (NSString *)resourcePath:(NSString *)name
{
    return [[self bundle] pathForResource:name ofType:nil];
}

+ (NSURL *)resourceURL:(NSString *)name
{
    return [[self bundle] URLForResource:name withExtension:nil];
}

@end
