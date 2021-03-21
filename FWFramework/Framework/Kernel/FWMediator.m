/*!
 @header     FWMediator.m
 @indexgroup FWFramework
 @brief      FWMediator
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/12/31
 */

#import "FWMediator.h"
#import "FWLoader.h"
#import "FWLog.h"
#import <objc/message.h>
#import <objc/runtime.h>

@interface FWMediator ()

@property (nonatomic, strong) FWLoader<Protocol *, id> *moduleLoader;
@property (nonatomic, strong) NSMutableDictionary *moduleDict;
@property (nonatomic, strong) NSMutableDictionary *moduleInvokeDict;

@end

@implementation FWMediator

+ (instancetype)sharedInstance
{
    static FWMediator *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
        instance.moduleLoader = [[FWLoader<Protocol *, id> alloc] init];
        instance.moduleDict = [NSMutableDictionary dictionary];
        instance.moduleInvokeDict = [NSMutableDictionary dictionary];
    });
    return instance;
}

- (NSString *)description
{
    NSMutableString *mutableDescription = [[NSMutableString alloc] init];
    for (NSString *protocolName in self.moduleDict) {
        [mutableDescription appendFormat:@"%@ : %@\n", protocolName, NSStringFromClass([self.moduleDict objectForKey:protocolName])];
    }
    
    return [NSString stringWithFormat:@"\n========== MEDIATOR ==========\n%@========== MEDIATOR ==========", mutableDescription];
}

+ (FWLoader<Protocol *,id> *)sharedLoader
{
    return [FWMediator sharedInstance].moduleLoader;
}

+ (BOOL)registerService:(Protocol *)serviceProtocol withModule:(Class<FWModuleProtocol>)moduleClass
{
    NSString *protocolName = NSStringFromProtocol(serviceProtocol);
    if (protocolName.length == 0 || !moduleClass ||
        ![moduleClass conformsToProtocol:serviceProtocol]) {
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
        NSUInteger priority1 = FWModulePriorityDefault;
        NSUInteger priority2 = FWModulePriorityDefault;
        if ([class1 respondsToSelector:@selector(priority)]) {
            priority1 = [class1 priority];
        }
        if ([class2 respondsToSelector:@selector(priority)]) {
            priority2 = [class2 priority];
        }
        if (priority1 == priority2) {
            return NSOrderedSame;
        } else if (priority1 < priority2) {
            return NSOrderedDescending;
        } else {
            return NSOrderedAscending;
        }
    }];
    return sortedModules;
}

+ (void)setupAllModules
{
    NSArray *modules = [self allRegisteredModules];
    for (Class<FWModuleProtocol> moduleClass in modules) {
        @try {
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
    FWLogDebug(@"%@", [FWMediator sharedInstance]);
    FWLogDebug(@"%@", [NSClassFromString(@"FWPluginManager") sharedInstance]);
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

@implementation FWModuleBundle

+ (NSBundle *)bundle
{
    return [NSBundle mainBundle];
}

+ (UIImage *)imageNamed:(NSString *)imageName
{
    return [UIImage imageNamed:imageName inBundle:[self bundle] compatibleWithTraitCollection:nil];
}

+ (NSString *)localizedString:(NSString *)key
{
    return [self localizedString:key table:nil];
}

+ (NSString *)localizedString:(NSString *)key table:(NSString *)table
{
    return [[self bundle] localizedStringForKey:key value:nil table:table];
}

@end
