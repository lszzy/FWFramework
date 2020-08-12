//
//  TestSkeletonViewController.m
//  Example
//
//  Created by wuyong on 2020/7/29.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

#import "TestSkeletonViewController.h"

@interface TestSkeletonViewController () <FWSkeletonLayoutDelegate>

@property (nonatomic, strong) UIView *testView;
@property (nonatomic, strong) UIView *childView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *label1;
@property (nonatomic, strong) UILabel *label2;
@property (nonatomic, strong) UITextView *textView1;
@property (nonatomic, strong) UITextView *textView2;

@end

@implementation TestSkeletonViewController

- (void)renderView
{
    UIView *testView = [UIView new];
    _testView = testView;
    testView.backgroundColor = [UIColor redColor];
    [testView fwSetCornerRadius:5];
    [self.view addSubview:testView];
    testView.fwLayoutChain.leftWithInset(20).topWithInset(20).size(CGSizeMake(FWScreenWidth / 2 - 40, 50));
    
    UIView *rightView = [UIView new];
    rightView.backgroundColor = [UIColor redColor];
    [rightView fwSetCornerRadius:5];
    [self.view addSubview:rightView];
    rightView.fwLayoutChain.rightWithInset(20).topWithInset(20).size(CGSizeMake(FWScreenWidth / 2 - 40, 50));
    
    UIView *childView = [UIView new];
    _childView = childView;
    childView.backgroundColor = [UIColor blueColor];
    [rightView addSubview:childView];
    childView.fwLayoutChain.edgesWithInsets(UIEdgeInsetsMake(10, 10, 10, 10));
    
    UIImageView *imageView = [UIImageView new];
    _imageView = imageView;
    imageView.image = [UIImage fwImageWithAppIcon];
    [imageView fwSetCornerRadius:5];
    [self.view addSubview:imageView];
    imageView.fwLayoutChain.centerXToView(testView).topToBottomOfViewWithOffset(testView, 20).size(CGSizeMake(50, 50));
    
    UIView *childView2 = [UIView new];
    childView2.backgroundColor = [UIColor blueColor];
    [self.view addSubview:childView2];
    childView2.fwLayoutChain.centerXToView(childView).centerYToView(imageView).sizeToView(childView);
    
    UILabel *label1 = [UILabel new];
    _label1 = label1;
    label1.textColor = [UIColor blueColor];
    label1.text = @"我是Label1";
    [self.view addSubview:label1];
    label1.fwLayoutChain.leftToView(testView).topToBottomOfViewWithOffset(imageView, 20);
    
    UILabel *label2 = [UILabel new];
    _label2 = label2;
    label2.font = [UIFont systemFontOfSize:12];
    label2.textColor = [UIColor blueColor];
    label2.numberOfLines = 0;
    label2.text = @"我是Label2222222222\n我是Label22222\n我是Label2";
    [self.view addSubview:label2];
    label2.fwLayoutChain.leftToView(rightView).topToBottomOfViewWithOffset(imageView, 20);
    
    UITextView *textView1 = [UITextView new];
    _textView1 = textView1;
    textView1.editable = NO;
    textView1.textColor = [UIColor blueColor];
    textView1.text = @"我是TextView1";
    [self.view addSubview:textView1];
    textView1.fwLayoutChain.leftToView(testView).topToBottomOfViewWithOffset(label1, 20).size(CGSizeMake(FWScreenWidth / 2 - 40, 50));
    
    UITextView *textView2 = [UITextView new];
    _textView2 = textView2;
    textView2.font = [UIFont systemFontOfSize:12];
    textView2.editable = NO;
    textView2.textColor = [UIColor blueColor];
    textView2.text = @"我是TextView2222\n我是TextView2\n我是TextView";
    [self.view addSubview:textView2];
    textView2.fwLayoutChain.leftToView(rightView).topToBottomOfViewWithOffset(label2, 20).size(CGSizeMake(FWScreenWidth / 2 - 40, 50));
}

- (void)renderData
{
    [self fwShowSkeleton];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self fwHideSkeleton];
    });
}

#pragma mark - FWSkeletonLayoutDelegate

- (void)skeletonViewLayout:(FWSkeletonLayout *)layout
{
    [layout addSkeletonView:self.testView];
    FWSkeletonView *childView = [layout addSkeletonView:self.childView];
    FWSkeletonView *imageView = [layout addSkeletonView:self.imageView block:^(FWSkeletonView *skeletonView) {
        skeletonView.animation = nil;
        skeletonView.image = [[UIImage imageNamed:@"tabbar_home"] fwImageWithTintColor:FWSkeletonAppearance.appearance.color];
    }];
    [layout addSkeletonView:[UIView new] block:^(FWSkeletonView *view) {
        view.fwLayoutChain.centerXToView(childView).centerYToView(imageView).sizeToView(childView);
    }];
    
    [layout addSkeletonViews:@[self.label1, self.label2, self.textView1, self.textView2]];
}

@end
