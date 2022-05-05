/**
 @header     FWLoader.m
 @indexgroup FWFramework
      FWLoader
 @author     wuyong
 @copyright  Copyright © 2021 wuyong.site. All rights reserved.
 @updated    2021/1/15
 */

#import "FWLoader.h"

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

@end

@implementation FWLoader

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
