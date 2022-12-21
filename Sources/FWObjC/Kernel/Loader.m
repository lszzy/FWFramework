//
//  Loader.m
//  FWFramework
//
//  Created by wuyong on 2022/8/20.
//

#import "Loader.h"

#pragma mark - __FWLoaderTarget

@interface __FWLoaderTarget : NSObject

@property (nonatomic, copy) NSString *identifier;

@property (nonatomic, copy) id (^block)(id input);

@property (nonatomic, weak) id target;

@property (nonatomic) SEL action;

- (id)invoke:(id)input;

@end

@implementation __FWLoaderTarget

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

#pragma mark - __FWLoader

@interface __FWLoader ()

@property (nonatomic, strong) NSMutableArray *allLoaders;

@end

@implementation __FWLoader

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
    __FWLoaderTarget *loader = [[__FWLoaderTarget alloc] init];
    loader.block = block;
    [self.allLoaders addObject:loader];
    return loader.identifier;
}

- (NSString *)addTarget:(id)target action:(SEL)action
{
    __FWLoaderTarget *loader = [[__FWLoaderTarget alloc] init];
    loader.target = target;
    loader.action = action;
    [self.allLoaders addObject:loader];
    return loader.identifier;
}

- (void)remove:(NSString *)identifier
{
    NSMutableArray *loaders = self.allLoaders;
    [loaders enumerateObjectsUsingBlock:^(__FWLoaderTarget *loader, NSUInteger idx, BOOL *stop) {
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
    [self.allLoaders enumerateObjectsUsingBlock:^(__FWLoaderTarget *loader, NSUInteger idx, BOOL *stop) {
        output = [loader invoke:input];
        if (output) *stop = YES;
    }];
    return output;
}

@end
