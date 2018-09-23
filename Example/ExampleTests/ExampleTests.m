//
//  ExampleTests.m
//  ExampleTests
//
//  Created by wuyong on 2018/9/23.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <FWFramework/FWFramework.h>

@interface ExampleTests : XCTestCase

@end

@implementation ExampleTests

- (void)setUp
{
    
}

- (void)tearDown
{
    
}

- (void)testExample
{
    XCTAssertTrue([FWUnitTest class] != NULL);
}

- (void)testPerformanceExample
{
    [self measureBlock:^{
        
    }];
}

@end
