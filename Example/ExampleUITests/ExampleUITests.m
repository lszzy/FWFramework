//
//  ExampleUITests.m
//  ExampleUITests
//
//  Created by wuyong on 2018/9/23.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface ExampleUITests : XCTestCase

@end

@implementation ExampleUITests

- (void)setUp
{
    self.continueAfterFailure = NO;
    
    [[[XCUIApplication alloc] init] launch];
}

- (void)tearDown
{
    
}

- (void)testExample
{
    
}

@end
