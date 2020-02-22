//
//  TestThreadViewController.m
//  Example
//
//  Created by wuyong on 2020/2/22.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

#import "TestThreadViewController.h"

@interface TestThreadViewController ()

@end

@implementation TestThreadViewController

- (void)renderData
{
    [self.tableData addObjectsFromArray:@[
                                         @[@"Associated不加锁", @"onLock1"],
                                         @[@"Associated加锁", @"onLock2"],
                                         @[@"NSMutableArray", @"onArray1"],
                                         @[@"FWMutableArray", @"onArray2"],
                                         @[@"NSMutableArray加锁", @"onArray3"],
                                         @[@"NSMutableDictionary", @"onDictionary1"],
                                         @[@"FWMutableDictionary", @"onDictionary2"],
                                         @[@"NSMutableDictionary加锁", @"onDictionary3"],
                                         @[@"字典随机", @"onRandom1"],
                                         ]];
}

#pragma mark - TableView

- (void)renderCellData:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath
{
    NSArray *rowData = [self.tableData objectAtIndex:indexPath.row];
    cell.textLabel.text = [rowData objectAtIndex:0];
}

- (void)onCellSelect:(NSIndexPath *)indexPath
{
    NSArray *rowData = [self.tableData objectAtIndex:indexPath.row];
    SEL selector = NSSelectorFromString([rowData objectAtIndex:1]);
    if ([self respondsToSelector:selector]) {
        FWIgnoredBegin();
        [self performSelector:selector];
        FWIgnoredEnd();
    }
}

#pragma mark - Action

- (NSInteger)queueCount
{
    return 10000;
}

- (void)onQueue:(FWBlockVoid)block completion:(FWBlockVoid)completion;
{
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 10;
    for (int i = 0; i < [self queueCount]; i++) {
        NSOperation *operation = [NSBlockOperation blockOperationWithBlock:block];
        [queue addOperation:operation];
    }
    [queue waitUntilAllOperationsAreFinished];
    completion();
}

- (void)onResult:(NSInteger)count
{
    [self fwShowAlertWithTitle:@"结果" message:[NSString stringWithFormat:@"期望：%@\n实际：%@", @([self queueCount]), @(count)] cancel:@"关闭" cancelBlock:nil];
}

- (void)onLock1
{
    // 清空
    objc_setAssociatedObject(self, _cmd, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    FWWeakifySelf();
    [self onQueue:^{
        FWStrongifySelf();
        
        // 操作
        NSInteger value = [objc_getAssociatedObject(self, _cmd) integerValue];
        value++;
        objc_setAssociatedObject(self, _cmd, @(value), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
    } completion:^{
        FWStrongifySelf();
        
        // 结果
        NSInteger value = [objc_getAssociatedObject(self, _cmd) integerValue];
        [self onResult:value];
    }];
}

- (void)onLock2
{
    // 清空
    objc_setAssociatedObject(self, _cmd, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    FWWeakifySelf();
    [self onQueue:^{
        FWStrongifySelf();
        
        // 操作
        [self fwLock];
        NSInteger value = [objc_getAssociatedObject(self, _cmd) integerValue];
        value++;
        objc_setAssociatedObject(self, _cmd, @(value), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [self fwUnlock];
        
    } completion:^{
        FWStrongifySelf();
        
        // 结果
        NSInteger value = [objc_getAssociatedObject(self, _cmd) integerValue];
        [self onResult:value];
    }];
}

- (void)onArray1
{
    // 清空
    NSMutableArray *array = [NSMutableArray new];
    [array addObject:[NSObject new]];
    
    FWWeakifySelf();
    [self onQueue:^{
        
        // 操作
        [array enumerateObjectsUsingBlock:^(NSObject * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.fwTempObject = @([obj.fwTempObject integerValue] + 1);
        }];
        
    } completion:^{
        FWStrongifySelf();
        
        // 结果
        NSInteger value = [[array.firstObject fwTempObject] integerValue];
        [self onResult:value];
    }];
}

- (void)onArray2
{
    // 清空
    FWMutableArray *array = [FWMutableArray new];
    [array addObject:[NSObject new]];
    
    FWWeakifySelf();
    [self onQueue:^{
        
        // 操作
        [array enumerateObjectsUsingBlock:^(NSObject * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.fwTempObject = @([obj.fwTempObject integerValue] + 1);
        }];
        
    } completion:^{
        FWStrongifySelf();
        
        // 结果
        NSInteger value = [[array.firstObject fwTempObject] integerValue];
        [self onResult:value];
    }];
}

- (void)onArray3
{
    // 清空
    NSMutableArray *array = [NSMutableArray new];
    [array addObject:[UIView new]];
    
    FWWeakifySelf();
    [self onQueue:^{
        FWStrongifySelf();
        
        // 操作
        [self fwLock];
        [array enumerateObjectsUsingBlock:^(NSObject * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.fwTempObject = @([obj.fwTempObject integerValue] + 1);
        }];
        [self fwUnlock];
        
    } completion:^{
        FWStrongifySelf();
        
        // 结果
        NSInteger value = [[array.firstObject fwTempObject] integerValue];
        [self onResult:value];
    }];
}

- (void)onDictionary1
{
    // 清空
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict setObject:[NSObject new] forKey:@"object"];
    
    FWWeakifySelf();
    [self onQueue:^{
        
        // 操作
        [dict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, NSObject *  _Nonnull obj, BOOL * _Nonnull stop) {
            obj.fwTempObject = @([obj.fwTempObject integerValue] + 1);
        }];
        
    } completion:^{
        FWStrongifySelf();
        
        // 结果
        NSInteger value = [[dict[@"object"] fwTempObject] integerValue];
        [self onResult:value];
    }];
}

- (void)onDictionary2
{
    // 清空
    FWMutableDictionary *dict = [FWMutableDictionary new];
    [dict setObject:[NSObject new] forKey:@"object"];
    
    FWWeakifySelf();
    [self onQueue:^{
        
        // 操作
        [dict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, NSObject *  _Nonnull obj, BOOL * _Nonnull stop) {
            obj.fwTempObject = @([obj.fwTempObject integerValue] + 1);
        }];
        
    } completion:^{
        FWStrongifySelf();
        
        // 结果
        NSInteger value = [[dict[@"object"] fwTempObject] integerValue];
        [self onResult:value];
    }];
}

- (void)onDictionary3
{
    // 清空
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict setObject:[NSObject new] forKey:@"object"];
    
    FWWeakifySelf();
    [self onQueue:^{
        FWStrongifySelf();
        
        // 操作
        [self fwLock];
        [dict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, NSObject *  _Nonnull obj, BOOL * _Nonnull stop) {
            obj.fwTempObject = @([obj.fwTempObject integerValue] + 1);
        }];
        [self fwUnlock];
        
    } completion:^{
        FWStrongifySelf();
        
        // 结果
        NSInteger value = [[dict[@"object"] fwTempObject] integerValue];
        [self onResult:value];
    }];
}

- (void)onRandom1
{
    // 清空
    NSDictionary *dict = @{
        @1: @1,
        @2: @2,
        @3: @"7",
        @4: [NSObject new],
    };
    __block NSInteger count1 = 0, count2 = 0, count3 = 0, count4 = 0;
    
    FWWeakifySelf();
    [self onQueue:^{
        FWStrongifySelf();
        
        // 操作
        [self fwLock];
        NSInteger value = [[dict fwRandomWeightKey] integerValue];
        if (value == 1) {
            count1 += 1;
        } else if (value == 2) {
            count2 += 1;
        } else if (value == 3) {
            count3 += 1;
        } else {
            count4 += 1;
        }
        [self fwUnlock];
        
    } completion:^{
        FWStrongifySelf();
        
        // 结果
        NSLog(@"1 => %@, 2 => %@, 3 => %@, 4 => %@", @(count1), @(count2), @(count3), @(count4));
        NSInteger value = count1 + count2 + count3;
        [self onResult:value];
    }];
}

@end
