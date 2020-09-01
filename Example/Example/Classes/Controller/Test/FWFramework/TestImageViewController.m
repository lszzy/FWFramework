//
//  TestImageViewController.m
//  Example
//
//  Created by wuyong on 2020/2/24.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

#import "TestImageViewController.h"
#import "UIImage+MultiFormat.h"

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
        
        _animatedView = [UIImageView new];
        [self.contentView addSubview:_animatedView];
        _animatedView.fwLayoutChain.leftToRightOfViewWithOffset(_systemView, 60).topToView(_systemView).bottomToView(_systemView).widthToView(_systemView);
    }
    return self;
}

@end

@interface TestImagePlugin : NSObject<FWImagePlugin>

FWSingleton(TestImagePlugin);

@end

@implementation TestImagePlugin

FWDefSingleton(TestImagePlugin);

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[FWPluginManager sharedInstance] registerDefault:@protocol(FWImagePlugin) withObject:[TestImagePlugin class]];
    });
}

- (UIImage *)fwImageDecodeWithData:(NSData *)data scale:(CGFloat)scale
{
    return [UIImage sd_imageWithData:data scale:scale];
}

@end

@interface TestImageViewController ()

@property (nonatomic, assign) NSInteger imageType;

@end

@implementation TestImageViewController

- (NSDictionary<NSString *,Class> *)renderCellClass
{
    return @{ @"cell" : [TestImageCell class] };
}

- (void)renderModel
{
    FWWeakifySelf();
    [self fwSetRightBarItem:@"Toggle" block:^(id  _Nonnull sender) {
        FWStrongifySelf();
        self.imageType = (self.imageType + 1) > 2 ? 0 : (self.imageType + 1);
        [self renderData];
    }];
}

- (void)renderData
{
    if (self.imageType == 2) {
        [self.tableData setArray:@[
            @"http://www.httpwatch.com/httpgallery/authentication/authenticatedimage/default.aspx?0.35786508303135633",     // requires HTTP auth, used to demo the NTLM auth
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
            @"http://via.placeholder.com/200x200.jpg",
        ]];
    } else {
        [self.tableData setArray:@[
            @"progressive.jpg",
            @"animation.png",
            @"test.gif",
            @"test.webp",
            @"test.heic",
            @"test.heif",
            @"animation.heic",
            @"public_icon",
            @"public_gif",
        ]];
    }
    [self.tableView reloadData];
}

#pragma mark - TableView

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 150;
}

- (void)renderCellData:(TestImageCell *)cell indexPath:(NSIndexPath *)indexPath
{
    NSString *fileName = [self.tableData objectAtIndex:indexPath.row];
    cell.nameLabel.text = [fileName lastPathComponent];
    if (self.imageType == 0) {
        UIImage *image = [UIImage imageNamed:fileName];
        cell.systemView.image = image;
        cell.animatedView.image = image;
    } else {
        NSString *url = fileName;
        if (self.imageType == 1) {
            url = [NSString stringWithFormat:@"http://kvm.wuyong.site/images/images/%@", fileName];
        }
        cell.systemView.image = nil;
        cell.animatedView.image = nil;
        [cell.systemView fwSetImageWithURL:url];
        [cell.animatedView fwSetImageWithURL:url];
    }
}

@end
