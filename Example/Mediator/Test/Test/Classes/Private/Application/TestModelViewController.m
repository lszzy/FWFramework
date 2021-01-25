/*!
 @header     TestModelViewController.m
 @indexgroup Example
 @brief      TestModelViewController
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/9/26
 */

#import "TestModelViewController.h"

@interface TestModelRequest: FWRequest

@property (nonatomic, copy, readonly) NSString *responseName;

@end

@implementation TestModelRequest

- (NSString *)requestUrl
{
    return @"http://kvm.wuyong.site/test.json";
}

- (FWResponseSerializerType)responseSerializerType
{
    return FWResponseSerializerTypeJSON;
}

- (NSTimeInterval)requestTimeoutInterval
{
    return 30;
}

- (void)requestCompleteFilter
{
    NSDictionary *dict = [self.responseJSONObject fwAsNSDictionary];
    _responseName = [dict[@"name"] fwAsNSString];
}

@end

@interface TestModelUser : NSObject <FWModel>

@property (nonatomic, assign) NSInteger userId;
@property (nonatomic, strong) NSNumber *userAge;
@property (nonatomic, strong) NSString *userName;
@property (nonatomic, strong) NSURL *userLink;

@end

@implementation TestModelUser

+ (NSDictionary<NSString *,id> *)fwModelPropertyMapper
{
    return @{
             @"userId": @[@"userId", @"user_id"],
             @"userAge": @[@"userAge", @"user_age"],
             @"userName": @[@"userName", @"user_name"],
             @"userLink": @[@"userLink", @"user_link"],
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
FWPropertyWeak(UIViewController *, weakController);

@end

@implementation TestModelViewController

FWDefDynamicWeak(UIViewController *, weakController, setWeakController);

- (void)renderView
{
    self.weakController = self;
    
    self.textView = [[UITextView alloc] initWithFrame:self.view.bounds];
    self.textView.editable = NO;
    [self.view addSubview:self.textView];
}

- (void)renderModel
{
    TestModelRequest *request = [TestModelRequest new];
    [request startWithCompletionBlockWithSuccess:^(TestModelRequest *request) {
        [self.view fwShowMessageWithText:[NSString stringWithFormat:@"json请求成功: \n%@", request.responseName]];
    } failure:^(TestModelRequest *request) {
        [self fwShowAlertWithTitle:@"json请求失败" message:[NSString stringWithFormat:@"%@", request.error] cancel:FWLocalizedString(@"关闭") cancelBlock:nil];
    }];
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
                                       @"userLink": @"http://www.baidu.com/中文?id=中文",
                                       },
                               @"users": @[
                                       @{
                                           @"userId": @2,
                                           @"userAge": @20,
                                           @"userName": @"userName",
                                           @"userLink": @"http://www.baidu.com/中文?id=中文",
                                           },
                                       @{
                                           @"user_id": @3,
                                           @"user_age": @20,
                                           @"user_name": @"userName",
                                           @"user_link": @"http://www.baidu.com/中文?id=中文",
                                           },
                                       ],
                               @"users2": @[
                                       @{
                                           @"userId": @4,
                                           @"userAge": @20,
                                           @"userName": @"userName",
                                           @"userLink": @"http://www.baidu.com/中文?id=中文",
                                           },
                                       @{
                                           @"user_id": @5,
                                           @"user_age": @20,
                                           @"user_name": @"userName",
                                           @"user_link": @"http://www.baidu.com/中文?id=中文",
                                           },
                                       ],
                               };
    TestModelObj *obj = [TestModelObj fwModelWithJson:jsonDict];
    // FWLogDebug(@"test long log:\n%@\n%@\n%@", self.textView.text, self.textView.text, self.textView.text);
    
    // 测试\udf36字符会导致json解码失败问题
    NSString *jsonFile = [TestBundle.bundle pathForResource:@"jsonDecode" ofType:@"json"];
    NSString *jsonString = [NSString stringWithContentsOfFile:jsonFile encoding:NSUTF8StringEncoding error:nil];
    id jsonObject = [jsonString fwJsonDecode];
    FWLogDebug(@"jsonString: %@ => json: %@", jsonString, jsonObject);
    self.textView.text = [NSString stringWithFormat:@"obj: %@\ndict: %@\njson: %@\nstring: %@", obj, [obj fwModelToJsonObject], jsonObject, [NSString fwJsonEncode:jsonObject]];
}

@end
