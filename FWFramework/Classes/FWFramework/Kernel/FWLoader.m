/**
 @header     FWLoader.m
 @indexgroup FWFramework
      FWLoader
 @author     wuyong
 @copyright  Copyright © 2021 wuyong.site. All rights reserved.
 @updated    2021/1/15
 */

#import "FWLoader.h"
#import "FWLog.h"
#import <objc/runtime.h>

#pragma mark - FWInnerLoaderTarget

@interface FWInnerLoaderTarget : NSObject

@property (nonatomic, copy) NSString *identifier;

@property (nonatomic, copy) id (^block)(id input);

@property (nonatomic, weak) id target;

@property (nonatomic) SEL action;

- (id)invoke:(id)input;

@end

@implementation FWInnerLoaderTarget

- (instancetype)init
{
    self = [super init];
    if (self) {
        _identifier = NSUUID.UUID.UUIDString;
    }
    return self;
}

- (id)invoke:(id)input
{
    if (self.block) {
        return self.block(input);
    }
    
    if (self.target && self.action && [self.target respondsToSelector:self.action]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        return [self.target performSelector:self.action withObject:input];
#pragma clang diagnostic pop
    }
    
    return nil;
}

@end

#pragma mark - FWLoader

@interface FWLoader ()

@property (nonatomic, strong) NSMutableArray *allLoaders;
@property (nonatomic, copy) NSString *autoloadLogs;

@end

@implementation FWLoader

#pragma mark - Autoload

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[FWLoader sharedInstance] autoload];
    });
}

+ (FWLoader *)sharedInstance
{
    static FWLoader *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FWLoader alloc] init];
    });
    return instance;
}

- (NSString *)description
{
    if (self.autoloadLogs) return self.autoloadLogs;
    return [super description];
}

- (void)autoload
{
    NSMutableArray<NSString *> *methodNames = [NSMutableArray array];
    unsigned int methodCount = 0;
    Method *methods = class_copyMethodList([FWLoader class], &methodCount);
    for (unsigned int i = 0; i < methodCount; ++i) {
        const char *methodChar = sel_getName(method_getName(methods[i]));
        if (!methodChar) continue;
        NSString *methodName = [NSString stringWithUTF8String:methodChar];
        if (![methodName hasPrefix:@"load"]) continue;
        if ([methodName containsString:@":"]) continue;
        [methodNames addObject:methodName];
    }
    free(methods);
    
    [methodNames sortUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        return [obj1 compare:obj2];
    }];
    
    for (NSString *methodName in methodNames) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self performSelector:NSSelectorFromString(methodName)];
#pragma clang diagnostic pop
    }
    
    NSMutableString *debugDescription = [[NSMutableString alloc] init];
    NSInteger debugCount = 0;
    for (NSString *methodName in methodNames) {
        [debugDescription appendFormat:@"%@. %@\n", @(++debugCount), methodName];
    }
    self.autoloadLogs = [NSString stringWithFormat:@"\n========== LOADER ==========\n%@========== LOADER ==========", debugDescription];
}

#pragma mark - Lifecycle

- (instancetype)init
{
    self = [super init];
    if (self) {
        _allLoaders = [[NSMutableArray alloc] init];
    }
    return self;
}

- (NSString *)addBlock:(id (^)(id))block
{
    FWInnerLoaderTarget *loader = [[FWInnerLoaderTarget alloc] init];
    loader.block = block;
    [self.allLoaders addObject:loader];
    return loader.identifier;
}

- (NSString *)addTarget:(id)target action:(SEL)action
{
    FWInnerLoaderTarget *loader = [[FWInnerLoaderTarget alloc] init];
    loader.target = target;
    loader.action = action;
    [self.allLoaders addObject:loader];
    return loader.identifier;
}

- (void)remove:(NSString *)identifier
{
    NSMutableArray *loaders = self.allLoaders;
    [loaders enumerateObjectsUsingBlock:^(FWInnerLoaderTarget *loader, NSUInteger idx, BOOL *stop) {
        if ([loader.identifier isEqualToString:identifier]) {
            [loaders removeObject:loader];
        }
    }];
}

- (void)removeAll
{
    [self.allLoaders removeAllObjects];
}

- (id)load:(id)input
{
    __block id output = nil;
    [self.allLoaders enumerateObjectsUsingBlock:^(FWInnerLoaderTarget *loader, NSUInteger idx, BOOL *stop) {
        output = [loader invoke:input];
        if (output) *stop = YES;
    }];
    return output;
}

@end
