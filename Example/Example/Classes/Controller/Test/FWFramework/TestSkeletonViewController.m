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
    imageView.image = [UIImage imageNamed:@"test_scale"];
    [imageView fwSetContentModeAspectFill];
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

- (void)renderModel
{
    FWWeakifySelf();
    [self fwSetRightBarItem:@(UIBarButtonSystemItemRefresh) block:^(id sender) {
        FWStrongifySelf();
        [self fwShowSheetWithTitle:nil message:nil cancel:@"取消" actions:@[@"shimmer", @"solid", @"scale", @"none"] actionBlock:^(NSInteger index) {
            FWSkeletonAnimation *animation = nil;
            if (index == 0) {
                animation = FWSkeletonAnimation.shimmer;
            } else if (index == 1) {
                animation = FWSkeletonAnimation.solid;
            } else if (index == 2) {
                animation = FWSkeletonAnimation.scale;
            }
            FWSkeletonAppearance.appearance.animation = animation;
            [self renderData];
        }];
    }];
}

- (void)renderData
{
    [self fwShowSkeleton];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self fwHideSkeleton];
    });
}

#pragma mark - FWSkeletonLayoutDelegate

- (void)skeletonViewLayout:(FWSkeletonLayout *)layout
{
    [layout addSkeletonView:self.testView];
    FWSkeletonView *childView = [layout addSkeletonView:self.childView];
    FWSkeletonView *imageView = [layout addSkeletonView:self.imageView block:^(FWSkeletonView *skeletonView) {
        skeletonView.image = [UIImage fwThemeNamed:@"theme_image"];
    }];
    [layout addSkeletonView:[UIView new] block:^(FWSkeletonView *skeletonView) {
        skeletonView.fwLayoutChain.centerXToView(childView).centerYToView(imageView).sizeToView(childView);
    }];
    
    NSArray<FWSkeletonView *> *skeletonViews = [layout addSkeletonViews:@[self.label1, self.label2, self.textView1, self.textView2]];
    [layout addSkeletonView:[FWSkeletonLabel new] block:^(FWSkeletonView *skeletonView) {
        skeletonView.fwLayoutChain.centerXToView(imageView).topToBottomOfViewWithOffset(skeletonViews.lastObject, 20).sizeToView(skeletonViews.lastObject);
    }];
}

@end
