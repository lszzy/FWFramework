/*!
 @header     TestModelViewController.m
 @indexgroup Example
 @brief      TestModelViewController
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/9/26
 */

#import "TestModelViewController.h"

@interface TestModelUser : NSObject <FWModel>

@property (nonatomic, assign) NSInteger userId;
@property (nonatomic, strong) NSNumber *userAge;
@property (nonatomic, strong) NSString *userName;

@end

@implementation TestModelUser

+ (NSDictionary<NSString *,id> *)fwModelPropertyMapper
{
    return @{
             @"userId": @[@"userId", @"user_id"],
             @"userAge": @[@"userAge", @"user_age"],
             @"userName": @[@"userName", @"user_name"],
             };
}

@end

FWModelArray(TestModelUser);

@interface TestModelObj : NSObject <FWModel>

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) TestModelUser *user;
// 非协议方式配置，需实现fwModelClassMapper
@property (nonatomic, strong) NSArray<TestModelUser *> *users;
// 协议方式配置，无需实现fwModelClassMapper
@property (nonatomic, strong) NSArray<TestModelUser *><TestModelUser> *users2;

@end

@implementation TestModelObj

+ (NSDictionary<NSString *,id> *)fwModelClassMapper
{
    return @{
             @"users": [TestModelUser class],
             };
}

@end

@interface TestModelViewController ()

FWPropertyStrong(UITextView *, textView);

@end

@implementation TestModelViewController

- (void)renderView
{
    self.textView = [[UITextView alloc] initWithFrame:self.view.bounds];
    self.textView.editable = NO;
    [self.view addSubview:self.textView];
}

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
                                           @"user_id": @3,
                                           @"user_age": @20,
                                           @"user_name": @"userName",
                                           },
                                       ],
                               @"users2": @[
                                       @{
                                           @"userId": @4,
                                           @"userAge": @20,
                                           @"userName": @"userName",
                                           },
                                       @{
                                           @"user_id": @5,
                                           @"user_age": @20,
                                           @"user_name": @"userName",
                                           },
                                       ],
                               };
    TestModelObj *obj = [TestModelObj fwModelWithJson:jsonDict];
    self.textView.text = [NSString stringWithFormat:@"obj: %@\ndict: %@", obj, [obj fwModelToJsonObject]];
}

@end
