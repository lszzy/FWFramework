/*!
 @header     TestModelViewController.m
 @indexgroup Example
 @brief      TestModelViewController
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/9/26
 */

#import "TestModelViewController.h"

@interface TestModelUser : NSObject

@property (nonatomic, assign) NSInteger userId;
@property (nonatomic, strong) NSNumber *userAge;
@property (nonatomic, strong) NSString *userName;

@end

@implementation TestModelUser

@end

@interface TestModelObj : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) TestModelUser *user;
@property (nonatomic, strong) NSArray *users;

@end

@implementation TestModelObj

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setValue:@"TestModelUser" forKeyPath:@"propertyArrayMap.users"];
    }
    return self;
}

@end

@implementation TestModelViewController

- (void)renderData
{
    NSDictionary *jsonDict = @{
                               @"name": @"name",
                               @"date": @"2018-09-26 11:12:13",
                               @"user": @{
                                       @"userId": @1,
                                       @"userAge": @20,
                                       @"userName": @"userName",
                                       },
                               @"users": @[
                                       @{
                                           @"userId": @2,
                                           @"userAge": @20,
                                           @"userName": @"userName",
                                           },
                                       @{
                                           @"userId": @3,
                                           @"userAge": @20,
                                           @"userName": @"userName",
                                           },
                                       @{
                                           @"userId": @4,
                                           @"userAge": @20,
                                           @"userName": @"userName",
                                           },
                                       ],
                               };
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:0 error:nil];
    TestModelObj *obj = [[TestModelObj alloc] initWithJSONData:jsonData];
    NSLog(@"obj: %@", obj);
    NSLog(@"dict: %@", [obj objectDictionary]);
    NSLog(@"string: %@", [obj JSONString]);
}

@end
