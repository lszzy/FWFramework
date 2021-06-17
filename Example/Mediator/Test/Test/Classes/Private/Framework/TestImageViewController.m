//
//  TestImageViewController.m
//  Example
//
//  Created by wuyong on 2020/2/24.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

#import "TestImageViewController.h"
@import SDWebImage;

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
        _nameLabel.fwLayoutChain.leftWithInset(10).topWithInset(10).height(20);
        
        _systemView = [UIImageView new];
        [self.contentView addSubview:_systemView];
        _systemView.fwLayoutChain.leftWithInset(10).topToBottomOfViewWithOffset(_nameLabel, 10).bottomWithInset(10).width(100);
        
        _animatedView = [[UIImageView fwImageViewAnimatedClass] new];
        [self.contentView addSubview:_animatedView];
        _animatedView.fwLayoutChain.leftToRightOfViewWithOffset(_systemView, 60).topToView(_systemView).bottomToView(_systemView).widthToView(_systemView);
    }
    return self;
}

@end

@interface TestImageViewController () <FWTableViewController>

@property (nonatomic, assign) BOOL isSDWebImage;

@end

@implementation TestImageViewController

- (UITableViewStyle)renderTableStyle
{
    return UITableViewStyleGrouped;
}

- (void)renderModel
{
    FWWeakifySelf();
    [self fwSetRightBarItem:@"Change" block:^(id  _Nonnull sender) {
        FWStrongifySelf();
        self.isSDWebImage = !self.isSDWebImage;
        [FWPluginManager unloadPlugin:@protocol(FWImagePlugin)];
        [FWPluginManager registerPlugin:@protocol(FWImagePlugin) withObject:self.isSDWebImage ? [FWSDWebImagePlugin class] : [FWImagePluginImpl class]];
        if (self.isSDWebImage) {
            [[SDImageCache sharedImageCache] clearWithCacheType:SDImageCacheTypeAll completion:nil];
        }
        
        [self.tableData removeAllObjects];
        [self.tableView reloadData];
        [self.tableView layoutIfNeeded];
        [self.tableView setContentOffset:CGPointZero animated:NO];
        [self renderData];
    }];
}

- (void)renderData
{
    self.isSDWebImage = [[FWPluginManager loadPlugin:@protocol(FWImagePlugin)] isKindOfClass:[FWSDWebImagePlugin class]];
    self.fwBarTitle = self.isSDWebImage ? @"FWImage - SDWebImage" : @"FWImage - FWWebImage";
    FWSDWebImagePlugin.sharedInstance.fadeAnimated = YES;
    FWImagePluginImpl.sharedInstance.fadeAnimated = YES;
    
    [self.tableData setArray:@[
        @"test.svg",
        @"close.svg",
        @"progressive.jpg",
        @"animation.png",
        @"test.gif",
        @"test.webp",
        @"test.heic",
        @"test.heif",
        @"animation.heic",
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
    TestImageCell *cell = [TestImageCell fwCellWithTableView:tableView style:UITableViewCellStyleDefault reuseIdentifier:self.isSDWebImage ? @"SDWebImage" : @"FWWebImage"];
    NSString *fileName = [self.tableData objectAtIndex:indexPath.row];
    cell.nameLabel.text = [fileName lastPathComponent];
    if (!fileName.fwIsFormatUrl) {
        UIImage *image = [TestBundle imageNamed:fileName];
        [cell.systemView fwSetImageWithURL:nil placeholderImage:image];
        [cell.animatedView fwSetImageWithURL:nil placeholderImage:image];
    } else {
        NSString *url = fileName;
        if ([url hasPrefix:@"http://kvm.wuyong.site"]) {
            url = [url stringByAppendingFormat:@"?t=%@", @(NSDate.fwCurrentTime)];
        }
        [cell.systemView fwSetImageWithURL:url];
        [cell.animatedView fwSetImageWithURL:url placeholderImage:[TestBundle imageNamed:@"public_icon"]];
    }
    return cell;
}

@end
