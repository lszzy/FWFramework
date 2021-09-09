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
    [self.fwView addSubview:self.textView];
}

- (void)renderModel
{
    TestModelRequest *request = [TestModelRequest new];
    [request startWithCompletionBlockWithSuccess:^(TestModelRequest *request) {
        [self fwShowMessageWithText:[NSString stringWithFormat:@"json请求成功: \n%@", request.responseName]];
    } failure:^(TestModelRequest *request) {
        [self fwShowAlertWithTitle:@"json请求失败" message:[NSString stringWithFormat:@"%@", request.error] cancel:nil cancelBlock:nil];
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
                                           @"user_name": @"userName",
                                           @"user_link": @"http://www.baidu.com/中文?id=中文",
                                           }
                                       ],
                               @"users2": @[
                                       @{
                                           @"user_id": @3,
                                           @"user_age": @20,
                                           @"userName": @"userName",
                                           @"userLink": @"http://www.baidu.com/中文?id=中文",
                                           }
                                       ],
                               };
    TestModelObj *obj = [TestModelObj fwModelWithJson:jsonDict];
    self.textView.text = [NSString stringWithFormat:@"obj: %@\ndict: %@", obj, [obj fwModelToJsonObject]];
    
    // 测试\udf36|\udd75等字符会导致json解码失败问题
    NSString *jsonString = @"{\"name\": \"\\u8499\\u81ea\\u7f8e\\u5473\\u6ce1\\u6912\\u7b0b\\ud83d\\ude04\\\\udf36\\ufe0f\"}";
    id jsonObject = [jsonString fwJsonDecode];
    self.textView.text = [NSString stringWithFormat:@"%@\nname: %@\njson: %@", self.textView.text, [jsonObject objectForKey:@"name"], [NSString fwJsonEncode:jsonObject]];
    
    jsonString = @"{\"name\": \"Test1\\udd75Test2\\ud83dTest3\\u8499\\u81ea\\u7f8e\\u5473\\u6ce1\\u6912\\u7b0b\\ud83d\\ude04\\udf36\\ufe0f\"}";
    jsonObject = [jsonString fwJsonDecode];
    self.textView.text = [NSString stringWithFormat:@"%@\nname2: %@\njson2: %@", self.textView.text, [jsonObject objectForKey:@"name"], [NSString fwJsonEncode:jsonObject]];
    
    // 测试%导致stringByRemovingPercentEncoding返回nil问题
    NSString *queryValue = @"我是字符串100%测试";
    self.textView.text = [NSString stringWithFormat:@"%@\nquery: %@", self.textView.text, [queryValue stringByRemovingPercentEncoding]];
    queryValue = @"%E6%88%91%E6%98%AF%E5%AD%97%E7%AC%A6%E4%B8%B2100%25%E6%B5%8B%E8%AF%95";
    self.textView.text = [NSString stringWithFormat:@"%@\nquery2: %@", self.textView.text, [queryValue stringByRemovingPercentEncoding]];
}

@end
