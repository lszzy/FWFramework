//
//  TestImageViewController.m
//  Example
//
//  Created by wuyong on 2020/2/24.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

#import "TestImageViewController.h"

@interface TestImageCell : UITableViewCell

@property (nonatomic, strong, readonly) UIImageView *systemView;

@property (nonatomic, strong, readonly) FWAnimatedImageView *animatedView;

@end

@implementation TestImageCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _systemView = [UIImageView new];
        [self.contentView addSubview:_systemView];
        _systemView.fwLayoutChain.leftWithInset(10).topWithInset(10).bottomWithInset(10).width(100);
        
        _animatedView = [FWAnimatedImageView new];
        [self.contentView addSubview:_animatedView];
        _animatedView.fwLayoutChain.leftToRightOfViewWithOffset(_systemView, 60).topWithInset(10).bottomWithInset(10).width(100);
    }
    return self;
}

@end

@interface TestImageViewController ()

@end

@implementation TestImageViewController

- (NSDictionary<NSString *,Class> *)renderCellClass
{
    return @{ @"cell" : [TestImageCell class] };
}

- (void)renderData
{
    [self addImageWithName:@"progressive.jpg"];
    [self addImageWithName:@"animation.png"];
    [self addFrameImage];
    [self addImageWithName:@"test.gif"];
    [self addImageWithName:@"test.webp"];
    [self addSpriteSheetImage];
}

- (void)addImageWithName:(NSString *)name
{
    UIImage *image = [FWImage imageNamed:name];
    [self.tableData fwAddObject:image];
}

- (void)addFrameImage
{
    NSString *basePath = [NSBundle mainBundle].bundlePath;
    NSMutableArray *paths = [NSMutableArray new];
    [paths addObject:[basePath stringByAppendingPathComponent:@"frame1.png"]];
    [paths addObject:[basePath stringByAppendingPathComponent:@"frame2.png"]];
    [paths addObject:[basePath stringByAppendingPathComponent:@"frame3.png"]];
    UIImage *image = [[FWFrameImage alloc] initWithImagePaths:paths oneFrameDuration:0.1 loopCount:0];
    [self.tableData fwAddObject:image];
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
    FWSpriteSheetImage *image = [[FWSpriteSheetImage alloc] initWithSpriteSheetImage:sheet
                                                     contentRects:contentRects
                                                   frameDurations:durations
                                                        loopCount:0];
    [self.tableData fwAddObject:image];
}

#pragma mark - TableView

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 120;
}

- (void)renderCellData:(TestImageCell *)cell indexPath:(NSIndexPath *)indexPath
{
    UIImage *image = [self.tableData objectAtIndex:indexPath.row];
    cell.systemView.image = image;
    cell.animatedView.image = image;
}

@end
