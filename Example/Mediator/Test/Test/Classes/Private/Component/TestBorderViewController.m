//
//  TestBorderViewController.m
//  Example
//
//  Created by wuyong on 16/11/14.
//  Copyright © 2016年 ocphp.com. All rights reserved.
//

#import "TestBorderViewController.h"

@interface TestBorderViewController ()

@end

@implementation TestBorderViewController

- (void)renderView
{
    UIColor *bgColor = [UIColor yellowColor];
    
    // All
    UIView *frameView = [[UIView alloc] initWithFrame:CGRectMake(20, 20, 50, 50)];
    frameView.backgroundColor = bgColor;
    [self.fwView addSubview:frameView];
    [frameView fwSetBorderColor:[UIColor redColor] width:0.5];
    
    frameView = [[UIView alloc] initWithFrame:CGRectMake(90, 20, 50, 50)];
    frameView.backgroundColor = bgColor;
    [self.fwView addSubview:frameView];
    [frameView fwSetCornerRadius:5];
    
    frameView = [[UIView alloc] initWithFrame:CGRectMake(160, 20, 50, 50)];
    frameView.backgroundColor = bgColor;
    [self.fwView addSubview:frameView];
    [frameView fwSetBorderColor:[UIColor redColor] width:0.5 cornerRadius:5];
    
    // Corener
    frameView = [[UIView alloc] initWithFrame:CGRectMake(20, 300, 80, 36)];
    frameView.backgroundColor = bgColor;
    [frameView fwSetBorderColor:[UIColor redColor] width:0.5 cornerRadius:18];
    [self.fwView addSubview:frameView];
    
    frameView = [[UIView alloc] initWithFrame:CGRectMake(120, 300, 80, 36)];
    frameView.backgroundColor = bgColor;
    [frameView fwSetBorderColor:[UIColor redColor] width:0.5 cornerRadius:36];
    [self.fwView addSubview:frameView];
    
    frameView = [[UIView alloc] initWithFrame:CGRectMake(220, 300, 80, 36)];
    frameView.backgroundColor = bgColor;
    [frameView fwSetBorderColor:[UIColor redColor] width:0.5 cornerRadius:9];
    [self.fwView addSubview:frameView];
    
    frameView = [[UIView alloc] initWithFrame:CGRectMake(20, 370, 80, 36)];
    frameView.backgroundColor = bgColor;
    [frameView fwSetCornerLayer:UIRectCornerAllCorners radius:18 borderColor:[UIColor redColor] width:0.5];
    [self.fwView addSubview:frameView];
    
    frameView = [[UIView alloc] initWithFrame:CGRectMake(120, 370, 80, 36)];
    frameView.backgroundColor = bgColor;
    [frameView fwSetCornerLayer:UIRectCornerAllCorners radius:36 borderColor:[UIColor redColor] width:0.5];
    [self.fwView addSubview:frameView];
    
    frameView = [[UIView alloc] initWithFrame:CGRectMake(220, 370, 80, 36)];
    frameView.backgroundColor = bgColor;
    [frameView fwSetCornerLayer:UIRectCornerAllCorners radius:9 borderColor:[UIColor redColor] width:0.5];
    [self.fwView addSubview:frameView];
    
    // Layer
    frameView = [[UIView alloc] initWithFrame:CGRectMake(20, 90, 50, 50)];
    frameView.backgroundColor = bgColor;
    [self.fwView addSubview:frameView];
    [frameView fwSetBorderLayer:(UIRectEdgeTop | UIRectEdgeBottom) color:[UIColor redColor] width:0.5];
    
    frameView = [[UIView alloc] initWithFrame:CGRectMake(90, 90, 50, 50)];
    frameView.backgroundColor = bgColor;
    [self.fwView addSubview:frameView];
    [frameView fwSetBorderLayer:(UIRectEdgeLeft | UIRectEdgeRight) color:[UIColor redColor] width:0.5];
    [frameView fwSetBorderLayer:(UIRectEdgeLeft | UIRectEdgeRight) color:[UIColor redColor] width:0.5 leftInset:5.0 rightInset:5.0];
    
    frameView = [[UIView alloc] initWithFrame:CGRectMake(160, 90, 50, 50)];
    frameView.backgroundColor = bgColor;
    [self.fwView addSubview:frameView];
    [frameView fwSetCornerLayer:(UIRectCornerTopLeft | UIRectCornerTopRight) radius:0];
    [frameView fwSetCornerLayer:(UIRectCornerTopLeft | UIRectCornerTopRight) radius:5];
    
    frameView = [[UIView alloc] initWithFrame:CGRectMake(230, 90, 50, 50)];
    frameView.backgroundColor = bgColor;
    [self.fwView addSubview:frameView];
    [frameView fwSetCornerLayer:(UIRectCornerTopLeft | UIRectCornerTopRight) radius:0 borderColor:[UIColor blueColor] width:1];
    [frameView fwSetCornerLayer:(UIRectCornerTopLeft | UIRectCornerTopRight) radius:5 borderColor:[UIColor redColor] width:0.5];
    
    // Layer
    UIView *layoutView = [UIView fwAutoLayoutView];
    layoutView.backgroundColor = bgColor;
    [self.fwView addSubview:layoutView];
    [layoutView fwSetDimensionsToSize:CGSizeMake(50, 50)];
    [layoutView fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:frameView withOffset:20];
    [layoutView fwPinEdgeToSuperview:NSLayoutAttributeLeft withInset:20];
    [layoutView layoutIfNeeded];
    [layoutView fwSetBorderLayer:(UIRectEdgeTop | UIRectEdgeBottom) color:[UIColor redColor] width:0.5];
    
    layoutView = [UIView fwAutoLayoutView];
    layoutView.backgroundColor = bgColor;
    [self.fwView addSubview:layoutView];
    [layoutView fwSetDimensionsToSize:CGSizeMake(50, 50)];
    [layoutView fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:frameView withOffset:20];
    [layoutView fwPinEdgeToSuperview:NSLayoutAttributeLeft withInset:90];
    [layoutView layoutIfNeeded];
    [layoutView fwSetBorderLayer:(UIRectEdgeLeft | UIRectEdgeRight) color:[UIColor redColor] width:0.5];
    [layoutView fwSetBorderLayer:(UIRectEdgeLeft | UIRectEdgeRight) color:[UIColor redColor] width:0.5 leftInset:5.0 rightInset:5.0];
    
    layoutView = [UIView fwAutoLayoutView];
    layoutView.backgroundColor = bgColor;
    [self.fwView addSubview:layoutView];
    [layoutView fwSetDimensionsToSize:CGSizeMake(50, 50)];
    [layoutView fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:frameView withOffset:20];
    [layoutView fwPinEdgeToSuperview:NSLayoutAttributeLeft withInset:160];
    [layoutView layoutIfNeeded];
    [layoutView fwSetCornerLayer:(UIRectCornerTopLeft | UIRectCornerTopRight) radius:0];
    [layoutView fwSetCornerLayer:(UIRectCornerTopLeft | UIRectCornerTopRight) radius:5];
    
    layoutView = [UIView fwAutoLayoutView];
    layoutView.backgroundColor = bgColor;
    [self.fwView addSubview:layoutView];
    [layoutView fwSetDimensionsToSize:CGSizeMake(50, 50)];
    [layoutView fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:frameView withOffset:20];
    [layoutView fwPinEdgeToSuperview:NSLayoutAttributeLeft withInset:230];
    [layoutView layoutIfNeeded];
    [layoutView fwSetCornerLayer:(UIRectCornerTopLeft | UIRectCornerTopRight) radius:0 borderColor:[UIColor blueColor] width:1];
    [layoutView fwSetCornerLayer:(UIRectCornerTopLeft | UIRectCornerTopRight) radius:5 borderColor:[UIColor redColor] width:0.5];
    
    // View
    UIView *autoView = [UIView fwAutoLayoutView];
    autoView.backgroundColor = bgColor;
    [self.fwView addSubview:autoView];
    [autoView fwSetDimensionsToSize:CGSizeMake(50, 50)];
    [autoView fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:layoutView withOffset:20];
    [autoView fwPinEdgeToSuperview:NSLayoutAttributeLeft withInset:20];
    [autoView fwSetBorderView:(UIRectEdgeTop | UIRectEdgeBottom) color:[UIColor redColor] width:0.5];
    
    autoView = [UIView fwAutoLayoutView];
    autoView.backgroundColor = bgColor;
    [self.fwView addSubview:autoView];
    [autoView fwSetDimensionsToSize:CGSizeMake(50, 50)];
    [autoView fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:layoutView withOffset:20];
    [autoView fwPinEdgeToSuperview:NSLayoutAttributeLeft withInset:90];
    [autoView fwSetBorderView:(UIRectEdgeLeft | UIRectEdgeRight) color:[UIColor redColor] width:0.5];
    [autoView fwSetBorderView:(UIRectEdgeLeft | UIRectEdgeRight) color:[UIColor redColor] width:0.5 leftInset:5.0 rightInset:5.0];
}

@end
