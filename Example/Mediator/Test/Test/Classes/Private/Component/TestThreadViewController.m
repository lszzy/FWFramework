//
//  TestThreadViewController.m
//  Example
//
//  Created by wuyong on 2020/2/22.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

#import "TestThreadViewController.h"

@interface TestThreadViewController () <FWTableViewController>

@end

@implementation TestThreadViewController

- (UITableViewStyle)renderTableStyle
{
    return UITableViewStyleGrouped;
}

- (void)renderModel
{
    NSString *publicKey = @"-----BEGIN PUBLIC KEY-----\nMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDDI2bvVLVYrb4B0raZgFP60VXY\ncvRmk9q56QiTmEm9HXlSPq1zyhyPQHGti5FokYJMzNcKm0bwL1q6ioJuD4EFI56D\na+70XdRz1CjQPQE3yXrXXVvOsmq9LsdxTFWsVBTehdCmrapKZVVx6PKl7myh0cfX\nQmyveT/eqyZK1gYjvQIDAQAB\n-----END PUBLIC KEY-----";
    NSString *privateKey = @"-----BEGIN PRIVATE KEY-----\nMIICdwIBADANBgkqhkiG9w0BAQEFAASCAmEwggJdAgEAAoGBAMMjZu9UtVitvgHS\ntpmAU/rRVdhy9GaT2rnpCJOYSb0deVI+rXPKHI9Aca2LkWiRgkzM1wqbRvAvWrqK\ngm4PgQUjnoNr7vRd1HPUKNA9ATfJetddW86yar0ux3FMVaxUFN6F0KatqkplVXHo\n8qXubKHRx9dCbK95P96rJkrWBiO9AgMBAAECgYBO1UKEdYg9pxMX0XSLVtiWf3Na\n2jX6Ksk2Sfp5BhDkIcAdhcy09nXLOZGzNqsrv30QYcCOPGTQK5FPwx0mMYVBRAdo\nOLYp7NzxW/File//169O3ZFpkZ7MF0I2oQcNGTpMCUpaY6xMmxqN22INgi8SHp3w\nVU+2bRMLDXEc/MOmAQJBAP+Sv6JdkrY+7WGuQN5O5PjsB15lOGcr4vcfz4vAQ/uy\nEGYZh6IO2Eu0lW6sw2x6uRg0c6hMiFEJcO89qlH/B10CQQDDdtGrzXWVG457vA27\nkpduDpM6BQWTX6wYV9zRlcYYMFHwAQkE0BTvIYde2il6DKGyzokgI6zQyhgtRJ1x\nL6fhAkB9NvvW4/uWeLw7CHHVuVersZBmqjb5LWJU62v3L2rfbT1lmIqAVr+YT9CK\n2fAhPPtkpYYo5d4/vd1sCY1iAQ4tAkEAm2yPrJzjMn2G/ry57rzRzKGqUChOFrGs\nlm7HF6CQtAs4HC+2jC0peDyg97th37rLmPLB9txnPl50ewpkZuwOAQJBAM/eJnFw\nF5QAcL4CYDbfBKocx82VX/pFXng50T7FODiWbbL4UnxICE0UBFInNNiWJxNEb6jL\n5xd0pcy9O2DOeso=\n-----END PRIVATE KEY-----";
    NSString *encodeString = @"CKiZsP8wfKlELNfWNC2G4iLv0RtwmGeHgzHec6aor4HnuOMcYVkxRovNj2r0Iu3ybPxKwiH2EswgBWsi65FOzQJa01uDVcJImU5vLrx1ihJ/PADUVxAMFjVzA3+Clbr2fwyJXW6dbbbymupYpkxRSfF5Gq9KyT+tsAhiSNfU6akgNGh4DENoA2AoKoWhpMEawyIubBSsTdFXtsHK0Ze0Cyde7oI2oh8ePOVHRuce6xYELYzmZY5yhSUoEb4+/44fbVouOCTl66ppUgnR5KjmIvBVEJLBq0SgoZfrGiA3cB08q4hb5EJRW72yPPQNqJxcQTPs8SxXa9js8ZryeSxyrw==";
    NSString *originString = @"FWFramework";
    
    FWLogDebug(@"Original: %@", originString);
    NSString *publicEncode = [originString.fwUTF8Data fwRSAEncryptWithPublicKey:publicKey].fwUTF8String;
    FWLogDebug(@"Encrypted Public: %@", publicEncode);
    NSString *privateDecode = [publicEncode.fwUTF8Data fwRSADecryptWithPrivateKey:privateKey].fwUTF8String;
    FWLogDebug(@"Decrypted Private: %@", privateDecode);
    
    privateDecode = [encodeString.fwUTF8Data fwRSADecryptWithPrivateKey:privateKey].fwUTF8String;
    FWLogDebug(@"Decrypted Server: %@", privateDecode);
    
    NSString *privateEncode = [originString.fwUTF8Data fwRSASignWithPrivateKey:privateKey].fwUTF8String;
    FWLogDebug(@"Sign Private: %@", privateEncode);
    NSString *publicDecode = [privateEncode.fwUTF8Data fwRSAVerifyWithPublicKey:publicKey].fwUTF8String;
    FWLogDebug(@"Verify Public: %@", publicDecode);
}

- (void)renderData
{
    self.tableView.backgroundColor = Theme.tableColor;
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
                                         @[@"FWCacheMemory", @"onCache1"],
                                         @[@"FWCacheMemory加锁", @"onCache2"],
                                         ]];
}

#pragma mark - TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [UITableViewCell fwCellWithTableView:tableView];
    NSArray *rowData = [self.tableData objectAtIndex:indexPath.row];
    cell.textLabel.text = [rowData objectAtIndex:0];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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

- (void)onCache1
{
    // 清空
    [[FWCacheMemory sharedInstance] setObject:@(0) forKey:@"cache"];
    
    FWWeakifySelf();
    [self onQueue:^{

        // 操作
        NSInteger value = [[[FWCacheMemory sharedInstance] objectForKey:@"cache"] integerValue];
        value++;
        [[FWCacheMemory sharedInstance] setObject:@(value) forKey:@"cache"];
        
    } completion:^{
        FWStrongifySelf();
        
        // 结果
        NSInteger value = [[[FWCacheMemory sharedInstance] objectForKey:@"cache"] integerValue];
        [self onResult:value];
    }];
}

- (void)onCache2
{
    // 清空
    [[FWCacheMemory sharedInstance] setObject:@(0) forKey:@"cache"];
    
    FWWeakifySelf();
    [self onQueue:^{

        // 操作
        [self fwLock];
        NSInteger value = [[[FWCacheMemory sharedInstance] objectForKey:@"cache"] integerValue];
        value++;
        [[FWCacheMemory sharedInstance] setObject:@(value) forKey:@"cache"];
        [self fwUnlock];
        
    } completion:^{
        FWStrongifySelf();
        
        // 结果
        NSInteger value = [[[FWCacheMemory sharedInstance] objectForKey:@"cache"] integerValue];
        [self onResult:value];
    }];
}

@end
