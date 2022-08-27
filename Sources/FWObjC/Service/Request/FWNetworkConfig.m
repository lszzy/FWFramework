//
//  FWNetworkConfig.m
//
//  Copyright (c) 2012-2016 FWNetwork https://github.com/yuantiku
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "FWNetworkConfig.h"
#import "FWSecurityPolicy.h"

@implementation FWNetworkConfig {
    NSMutableArray<id<FWUrlFilterProtocol>> *_urlFilters;
    NSMutableArray<id<FWCacheDirPathFilterProtocol>> *_cacheDirPathFilters;
}

+ (FWNetworkConfig *)sharedConfig {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _baseUrl = @"";
        _cdnUrl = @"";
        _urlFilters = [NSMutableArray array];
        _cacheDirPathFilters = [NSMutableArray array];
        _securityPolicy = [FWSecurityPolicy defaultPolicy];
        _removeNullValues = YES;
        _debugLogEnabled = NO;
        _debugMockEnabled = NO;
    }
    return self;
}

- (void)addUrlFilter:(id<FWUrlFilterProtocol>)filter {
    [_urlFilters addObject:filter];
}

- (void)clearUrlFilter {
    [_urlFilters removeAllObjects];
}

- (void)addCacheDirPathFilter:(id<FWCacheDirPathFilterProtocol>)filter {
    [_cacheDirPathFilters addObject:filter];
}

- (void)clearCacheDirPathFilter {
    [_cacheDirPathFilters removeAllObjects];
}

- (NSArray<id<FWUrlFilterProtocol>> *)urlFilters {
    return [_urlFilters copy];
}

- (NSArray<id<FWCacheDirPathFilterProtocol>> *)cacheDirPathFilters {
    return [_cacheDirPathFilters copy];
}

#pragma mark - NSObject

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p>{ baseURL: %@ } { cdnURL: %@ }", NSStringFromClass([self class]), self, self.baseUrl, self.cdnUrl];
}

@end
