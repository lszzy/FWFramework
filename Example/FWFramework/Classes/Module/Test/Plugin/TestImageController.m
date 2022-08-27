//
//  TestImageController.m
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/25.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

#import "TestImageController.h"
@import SDWebImage;
@import FWFramework;

@interface TestImageCell : UITableViewCell

@property (nonatomic, strong, readonly) UILabel *nameLabel;

@property (nonatomic, strong, readonly) UIImageView *systemView;

@property (nonatomic, strong, readonly) UIImageView *animatedView;

@end

@implementation TestImageCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _nameLabel = [UILabel new];
        [self.contentView addSubview:_nameLabel];
        _nameLabel.fw_layoutChain.leftWithInset(10).topWithInset(10).height(20);
        
        _systemView = [UIImageView new];
        [self.contentView addSubview:_systemView];
        _systemView.fw_layoutChain.leftWithInset(10).topToViewBottomWithOffset(_nameLabel, 10).bottomWithInset(10).width(100);
        
        _animatedView = [UIImageView fw_animatedImageView];
        [self.contentView addSubview:_animatedView];
        _animatedView.fw_layoutChain.leftToViewRightWithOffset(_systemView, 60).topToView(_systemView).bottomToView(_systemView).widthToView(_systemView);
    }
    return self;
}

@end

@interface TestImageController () <FWTableViewController>

@property (nonatomic, assign) BOOL isSDWebImage;

@end

@implementation TestImageController

- (UITableViewStyle)setupTableStyle
{
    return UITableViewStyleGrouped;
}

- (void)setupNavbar
{
    FWWeakifySelf();
    [self fw_setRightBarItem:@"Change" block:^(id  _Nonnull sender) {
        FWStrongifySelf();
        self.isSDWebImage = !self.isSDWebImage;
        [FWPluginManager unloadPlugin:@protocol(FWImagePlugin)];
        [FWPluginManager registerPlugin:@protocol(FWImagePlugin) withObject:self.isSDWebImage ? [FWSDWebImageImpl class] : [FWImagePluginImpl class]];
        if (self.isSDWebImage) {
            [[SDImageCache sharedImageCache] clearWithCacheType:SDImageCacheTypeAll completion:nil];
        }
        
        [self.tableData removeAllObjects];
        [self.tableView reloadData];
        [self.tableView layoutIfNeeded];
        [self.tableView setContentOffset:CGPointZero animated:NO];
        [self setupSubviews];
    }];
}

- (void)setupSubviews
{
    self.isSDWebImage = [[FWPluginManager loadPlugin:@protocol(FWImagePlugin)] isKindOfClass:[FWSDWebImageImpl class]];
    self.fw_title = self.isSDWebImage ? @"FWImage - SDWebImage" : @"FWImage - FWWebImage";
    FWSDWebImageImpl.sharedInstance.fadeAnimated = YES;
    FWImagePluginImpl.sharedInstance.fadeAnimated = YES;
    
    [self.tableData setArray:@[
        @"Animation.png",
        @"Loading.gif",
        @"http://kvm.wuyong.site/images/images/progressive.jpg",
        @"http://kvm.wuyong.site/images/images/animation.png",
        @"http://kvm.wuyong.site/images/images/test.gif",
        @"http://kvm.wuyong.site/images/images/test.webp",
        @"http://kvm.wuyong.site/images/images/test.heic",
        @"http://kvm.wuyong.site/images/images/test.heif",
        @"http://kvm.wuyong.site/images/images/animation.heic",
        @"http://assets.sbnation.com/assets/2512203/dogflops.gif",
        @"https://raw.githubusercontent.com/liyong03/YLGIFImage/master/YLGIFImageDemo/YLGIFImageDemo/joy.gif",
        @"http://apng.onevcat.com/assets/elephant.png",
        @"http://www.ioncannon.net/wp-content/uploads/2011/06/test2.webp",
        @"http://www.ioncannon.net/wp-content/uploads/2011/06/test9.webp",
        @"http://littlesvr.ca/apng/images/SteamEngine.webp",
        @"http://littlesvr.ca/apng/images/world-cup-2014-42.webp",
        @"https://isparta.github.io/compare-webp/image/gif_webp/webp/2.webp",
        @"https://nokiatech.github.io/heif/content/images/ski_jump_1440x960.heic",
        @"https://nokiatech.github.io/heif/content/image_sequences/starfield_animation.heic",
        @"https://s2.ax1x.com/2019/11/01/KHYIgJ.gif",
        @"https://raw.githubusercontent.com/icons8/flat-color-icons/master/pdf/stack_of_photos.pdf",
        @"https://nr-platform.s3.amazonaws.com/uploads/platform/published_extension/branding_icon/275/AmazonS3.png",
        @"https://upload.wikimedia.org/wikipedia/commons/1/14/Mahuri.svg",
        @"https://simpleicons.org/icons/github.svg",
        @"http://via.placeholder.com/200x200.jpg",
    ]];
    [self.tableView reloadData];
}

#pragma mark - TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableData.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 150;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TestImageCell *cell = [TestImageCell fw_cellWithTableView:tableView style:UITableViewCellStyleDefault reuseIdentifier:self.isSDWebImage ? @"SDWebImage" : @"FWWebImage"];
    NSString *fileName = [self.tableData objectAtIndex:indexPath.row];
    cell.nameLabel.text = [[fileName lastPathComponent] stringByAppendingFormat:@"(%@)", [NSData fw_mimeTypeFromExtension:[fileName pathExtension]]];
    if (!fileName.fw_isFormatUrl) {
        cell.fw_tempObject = fileName;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            UIImage *image = [FWModuleBundle imageNamed:fileName];
            UIImage *decodeImage = [UIImage fw_imageWithData:[UIImage fw_dataWithImage:image]];
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([cell.fw_tempObject isEqualToString:fileName]) {
                    [cell.systemView fw_setImageWithURL:nil placeholderImage:image];
                    [cell.animatedView fw_setImageWithURL:nil placeholderImage:decodeImage];
                }
            });
        });
    } else {
        cell.fw_tempObject = nil;
        NSString *url = fileName;
        if ([url hasPrefix:@"http://kvm.wuyong.site"]) {
            url = [url stringByAppendingFormat:@"?t=%@", @(NSDate.fw_currentTime)];
        }
        [cell.systemView fw_setImageWithURL:url];
        [cell.animatedView fw_setImageWithURL:url placeholderImage:[UIImage fw_appIconImage]];
    }
    return cell;
}

@end
