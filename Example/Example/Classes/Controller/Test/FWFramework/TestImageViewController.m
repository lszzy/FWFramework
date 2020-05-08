//
//  TestImageViewController.m
//  Example
//
//  Created by wuyong on 2020/2/24.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

#import "TestImageViewController.h"

@interface TestImageCell : UITableViewCell

@property (nonatomic, strong, readonly) UILabel *nameLabel;

@property (nonatomic, strong, readonly) UIImageView *systemView;

@property (nonatomic, strong, readonly) FWAnimatedImageView *animatedView;

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
        
        _animatedView = [FWAnimatedImageView new];
        [self.contentView addSubview:_animatedView];
        _animatedView.fwLayoutChain.leftToRightOfViewWithOffset(_systemView, 60).topToView(_systemView).bottomToView(_systemView).widthToView(_systemView);
    }
    return self;
}

@end

@interface TestImageViewController ()

@property (nonatomic, assign) BOOL isWebImage;

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
        self.isWebImage = !self.isWebImage;
        [self.tableView reloadData];
    }];
}

- (void)renderData
{
    [self.tableData addObjectsFromArray:@[
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
    [self.tableView reloadData];
    
    /*
    [self addFrameImage];
    [self addSpriteSheetImage];
    [self addProgressiveImage];
    */
}

- (void)addFrameImage
{
    NSString *basePath = [NSBundle mainBundle].bundlePath;
    NSMutableArray *paths = [NSMutableArray new];
    [paths addObject:[basePath stringByAppendingPathComponent:@"frame1.png"]];
    [paths addObject:[basePath stringByAppendingPathComponent:@"frame2.png"]];
    [paths addObject:[basePath stringByAppendingPathComponent:@"frame3.png"]];
    //UIImage *image = [[FWFrameImage alloc] initWithImagePaths:paths oneFrameDuration:0.1 loopCount:0];
    //[self.tableData fwAddObject:image];
}

- (void)addSpriteSheetImage
{
    NSString *path = [[NSBundle mainBundle].bundlePath stringByAppendingPathComponent:@"sheet.png"];
    UIImage *sheet = [[UIImage alloc] initWithData:[NSData dataWithContentsOfFile:path] scale:2];
    NSMutableArray *contentRects = [NSMutableArray new];
    NSMutableArray *durations = [NSMutableArray new];
    CGSize size = CGSizeMake(sheet.size.width / 8, sheet.size.height / 12);
    for (int j = 0; j < 12; j++) {
        for (int i = 0; i < 8; i++) {
            CGRect rect;
            rect.size = size;
            rect.origin.x = sheet.size.width / 8 * i;
            rect.origin.y = sheet.size.height / 12 * j;
            [contentRects addObject:[NSValue valueWithCGRect:rect]];
            [durations addObject:@(1 / 60.0)];
        }
    }
    //FWSpriteSheetImage *image = [[FWSpriteSheetImage alloc] initWithSpriteSheetImage:sheet
     //                                                contentRects:contentRects
      //                                             frameDurations:durations
        //                                                loopCount:0];
    //[self.tableData fwAddObject:image];
}

- (void)addProgressiveImage
{
    NSString *name = @"progressive.jpg";
    
    NSData *data = [[NSData alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:name ofType:nil]];
    float progress = 0.5;
    if (progress > 1) progress = 1;
    /*
    NSData *subData = [data subdataWithRange:NSMakeRange(0, data.length * progress)];
    FWImageDecoder *decoder = [[FWImageDecoder alloc] initWithScale:[UIScreen mainScreen].scale];
    [decoder updateData:subData final:NO];
    FWImageFrame *frame = [decoder frameAtIndex:0 decodeForDisplay:YES];
    imageView.image = frame.image;
     */
}

#pragma mark - TableView

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 150;
}

- (void)renderCellData:(TestImageCell *)cell indexPath:(NSIndexPath *)indexPath
{
    NSString *fileName = [self.tableData objectAtIndex:indexPath.row];
    cell.nameLabel.text = fileName;
    if (self.isWebImage) {
        NSString *url = [NSString stringWithFormat:@"http://kvm.wuyong.site/images/%@", fileName];
        cell.systemView.image = nil;
        cell.animatedView.image = nil;
        [cell.systemView fwSetImageWithURL:url];
        [cell.animatedView fwSetImageWithURL:url];
    } else {
        UIImage *image = [FWAnimatedImage imageNamed:fileName];
        cell.systemView.image = image;
        cell.animatedView.image = image;
    }
}

@end
