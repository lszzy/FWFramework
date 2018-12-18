//
//  FWView.m
//  FWFramework
//
//  Created by wuyong on 2018/12/18.
//  Copyright © 2018 wuyong.site. All rights reserved.
//

#import "FWView.h"

@interface FWView ()

// 赋值数据字典
@property (nonatomic, strong) NSMutableDictionary *assignData;

@end

@implementation FWView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.assignData = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)assign:(NSString *)key value:(id)value
{
    if (value != nil) {
        [self.assignData setObject:value forKey:key];
    } else {
        [self.assignData removeObjectForKey:key];
    }
}

- (void)assign:(NSDictionary *)data
{
    [self.assignData addEntriesFromDictionary:data];
}

- (id)fetch:(NSString *)key
{
    return [self.assignData objectForKey:key];
}

- (NSDictionary *)fetchAll
{
    return [NSDictionary dictionaryWithDictionary:self.assignData];
}

- (void)render
{
    // 子类重写
}

@end
