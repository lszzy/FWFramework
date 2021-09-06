/*!
 @header     TestViewController.m
 @indexgroup Example
 @brief      TestViewController
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/21
 */

#import "TestViewController.h"

@implementation TestViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([self conformsToProtocol:@protocol(FWScrollViewController)]) {
        UIViewController<FWScrollViewController> *scrollController = (UIViewController<FWScrollViewController> *)self;
        self.fwNavigationView.scrollView = scrollController.scrollView;
    } else if ([self conformsToProtocol:@protocol(FWTableViewController)]) {
        UIViewController<FWTableViewController> *tableController = (UIViewController<FWTableViewController> *)self;
        self.fwNavigationView.scrollView = tableController.tableView;
    } else if ([self conformsToProtocol:@protocol(FWCollectionViewController)]) {
        UIViewController<FWCollectionViewController> *collectionController = (UIViewController<FWCollectionViewController> *)self;
        self.fwNavigationView.scrollView = collectionController.collectionView;
    } else if ([self conformsToProtocol:@protocol(FWWebViewController)]) {
        UIViewController<FWWebViewController> *webController = (UIViewController<FWWebViewController> *)self;
        self.fwNavigationView.scrollView = webController.webView.scrollView;
    }
}

FWDealloc();

- (void)mockProgress:(void (^)(double, BOOL))block
{
    block(0, NO);
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        double progress = 0.0f;
        while (progress < 1.0f) {
            usleep(50000);
            progress += 0.02f;
            dispatch_async(dispatch_get_main_queue(), ^{
                block(MIN(progress, 1), progress >= 1);
            });
        }
    });
}

@end
