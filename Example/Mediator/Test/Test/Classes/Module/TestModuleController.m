//
//  TestModuleController.m
//  Pods
//
//  Created by wuyong on 2021/1/2.
//

#import "TestModuleController.h"
#import "TestModule.h"
@import FWFramework;

@interface TestModuleController () <FWViewController>

@end

@implementation TestModuleController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = [TestBundle localizedString:@"testModule"];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:[TestBundle localizedString:@"closeButton"] forState:UIControlStateNormal];
    [button setImage:[[TestBundle imageNamed:@"test"] fwCompressImageWithMaxWidth:25] forState:UIControlStateNormal];
    [button fwAddTouchBlock:^(id  _Nonnull sender) {
        [FWRouter closeViewControllerAnimated:YES];
    }];
    [self.view addSubview:button];
    button.fwLayoutChain.center();
}

@end
