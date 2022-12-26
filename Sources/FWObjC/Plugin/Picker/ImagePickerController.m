//
//  ImagePickerController.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "ImagePickerController.h"
#import "ImagePickerPluginImpl.h"
#import "ImageCropController.h"
#import "ToolbarView.h"
#import "EmptyPlugin.h"
#import "ToastPlugin.h"
#import "AlertPlugin.h"
#import "ViewPlugin.h"
#import "ImagePlugin.h"
#import "AppBundle.h"
#import <objc/runtime.h>
#import <CommonCrypto/CommonDigest.h>

#if FWMacroSPM

@interface NSObject ()

- (void)fw_applyAppearance;

@end

@interface UIView ()

@property (nonatomic, assign) CGPoint fw_origin;
@property (nonatomic, assign) CGFloat fw_width;

@end

@interface UINavigationBar ()

@property (nonatomic, strong, nullable) UIColor *fw_backgroundColor;
@property (nonatomic, strong, nullable) UIColor *fw_foregroundColor;
@property (nonatomic, strong, nullable) UIImage *fw_backImage;
@property (nonatomic, assign) BOOL fw_isTranslucent;
@property (nonatomic, strong, nullable) UIColor *fw_shadowColor;

@end

@interface UIScreen ()

@property (class, nonatomic, assign, readonly) CGFloat fw_pixelOne;
@property (class, nonatomic, assign, readonly) CGFloat fw_topBarHeight;
@property (class, nonatomic, assign, readonly) CGFloat fw_toolBarHeight;
@property (class, nonatomic, assign, readonly) CGFloat fw_screenHeight;

@end

@interface UIImage ()

- (nullable UIImage *)fw_imageWithScaleSize:(CGSize)size;

@end

#else

#import <FWFramework/FWFramework-Swift.h>

#endif

#pragma mark - FWImageAlbumTableCell

@implementation FWImageAlbumTableCell

@synthesize maskView = _maskView;

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self setDefaultAppearance];
    });
}

+ (void)setDefaultAppearance {
    [FWImageAlbumTableCell appearance].albumImageSize = 60;
    [FWImageAlbumTableCell appearance].albumImageMarginLeft = 16;
    [FWImageAlbumTableCell appearance].albumNameInsets = UIEdgeInsetsMake(0, 12, 0, 4);
    [FWImageAlbumTableCell appearance].albumNameFont = [UIFont systemFontOfSize:17];
    [FWImageAlbumTableCell appearance].albumNameColor = UIColor.whiteColor;
    [FWImageAlbumTableCell appearance].albumAssetsNumberFont = [UIFont systemFontOfSize:17];
    [FWImageAlbumTableCell appearance].albumAssetsNumberColor = UIColor.whiteColor;
    [FWImageAlbumTableCell appearance].checkedMaskColor = nil;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self didInitializeWithStyle:style];
        [self fw_applyAppearance];
    }
    return self;
}

- (void)didInitializeWithStyle:(UITableViewCellStyle)style {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.backgroundColor = [UIColor clearColor];
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.clipsToBounds = YES;
    self.imageView.layer.borderWidth = [UIScreen fw_pixelOne];
    self.imageView.layer.borderColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.1].CGColor;
    
    _maskView = [[UIView alloc] init];
    [self.contentView addSubview:self.maskView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.maskView.frame = CGRectMake(0, 0, MAX(CGRectGetWidth(self.contentView.bounds), CGRectGetWidth(self.bounds)), CGRectGetHeight(self.contentView.bounds));
    CGFloat imageEdgeTop = (CGRectGetHeight(self.contentView.bounds) - self.albumImageSize) / 2.0;
    CGFloat imageEdgeLeft = self.albumImageMarginLeft == -1 ? imageEdgeTop : self.albumImageMarginLeft;
    self.imageView.frame = CGRectMake(imageEdgeLeft, imageEdgeTop, self.albumImageSize, self.albumImageSize);
    
    self.textLabel.fw_origin = CGPointMake(CGRectGetMaxX(self.imageView.frame) + self.albumNameInsets.left, (CGRectGetHeight(self.textLabel.superview.bounds) - CGRectGetHeight(self.textLabel.frame)) / 2.0);
    
    CGFloat textLabelMaxWidth = CGRectGetWidth(self.contentView.bounds) - CGRectGetMinX(self.textLabel.frame) - CGRectGetWidth(self.detailTextLabel.bounds) - self.albumNameInsets.right;
    if (CGRectGetWidth(self.textLabel.bounds) > textLabelMaxWidth) {
        self.textLabel.fw_width = textLabelMaxWidth;
    }
    
    self.detailTextLabel.fw_origin = CGPointMake(CGRectGetMaxX(self.textLabel.frame) + self.albumNameInsets.right, (CGRectGetHeight(self.detailTextLabel.superview.bounds) - CGRectGetHeight(self.detailTextLabel.frame)) / 2.0);
}

- (void)setAlbumNameFont:(UIFont *)albumNameFont {
    _albumNameFont = albumNameFont;
    self.textLabel.font = albumNameFont;
}

- (void)setAlbumNameColor:(UIColor *)albumNameColor {
    _albumNameColor = albumNameColor;
    self.textLabel.textColor = albumNameColor;
}

- (void)setAlbumAssetsNumberFont:(UIFont *)albumAssetsNumberFont {
    _albumAssetsNumberFont = albumAssetsNumberFont;
    self.detailTextLabel.font = albumAssetsNumberFont;
}

- (void)setAlbumAssetsNumberColor:(UIColor *)albumAssetsNumberColor {
    _albumAssetsNumberColor = albumAssetsNumberColor;
    self.detailTextLabel.textColor = albumAssetsNumberColor;
}

- (void)setCheckedMaskColor:(UIColor *)checkedMaskColor {
    _checkedMaskColor = checkedMaskColor;
    self.maskView.backgroundColor = self.checked ? checkedMaskColor : nil;
}

- (void)setChecked:(BOOL)checked {
    _checked = checked;
    self.maskView.backgroundColor = checked ? self.checkedMaskColor : nil;
}

@end

#pragma mark - FWImageAlbumController

@interface FWImageAlbumController ()

@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong) NSMutableArray<FWAssetGroup *> *albumsArray;
@property(nonatomic, strong) FWAssetGroup *assetsGroup;
@property(nonatomic, weak) FWImagePickerController *imagePickerController;
@property(nonatomic, copy) void (^assetsGroupSelected)(FWAssetGroup *assetsGroup);
@property(nonatomic, copy) void (^albumArrayLoaded)(void);

@end

@implementation FWImageAlbumController

@synthesize backgroundView = _backgroundView;

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self didInitialize];
    }
    return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self didInitialize];
    }
    return self;
}

- (void)didInitialize {
    _albumsArray = [[NSMutableArray alloc] init];
    _albumTableViewCellHeight = 76;
    _toolBarBackgroundColor = [UIColor colorWithRed:27/255.f green:27/255.f blue:27/255.f alpha:1.f];
    _toolBarTintColor = UIColor.whiteColor;
    _showsDefaultLoading = YES;
    
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:FWAppBundle.navCloseImage style:UIBarButtonItemStylePlain target:self action:@selector(handleCancelButtonClick:)];
}

- (UIView *)backgroundView {
    if (!_backgroundView) {
        _backgroundView = [[UIView alloc] init];
    }
    return _backgroundView;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.isViewLoaded ? self.view.bounds : CGRectZero style:UITableViewStylePlain];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.showsHorizontalScrollIndicator = NO;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.backgroundColor = UIColor.blackColor;
        _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        if (@available(iOS 15.0, *)) {
            _tableView.sectionHeaderTopPadding = 0;
        }
    }
    return _tableView;
}

- (void)setToolBarBackgroundColor:(UIColor *)toolBarBackgroundColor {
    _toolBarBackgroundColor = toolBarBackgroundColor;
    self.navigationController.navigationBar.fw_backgroundColor = toolBarBackgroundColor;
}

- (void)setToolBarTintColor:(UIColor *)toolBarTintColor {
    _toolBarTintColor = toolBarTintColor;
    self.navigationController.navigationBar.fw_foregroundColor = toolBarTintColor;
}

- (void)setAssetsGroup:(FWAssetGroup *)assetsGroup {
    if (self.assetsGroup) {
        FWImageAlbumTableCell *cell = (FWImageAlbumTableCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.albumsArray indexOfObject:self.assetsGroup] inSection:0]];
        cell.checked = NO;
    }
    _assetsGroup = assetsGroup;
    FWImageAlbumTableCell *cell = (FWImageAlbumTableCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.albumsArray indexOfObject:assetsGroup] inSection:0]];
    cell.checked = YES;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage new] style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationController.navigationBar.fw_backImage = FWAppBundle.navBackImage;
    if (!self.title) self.title = FWAppBundle.pickerAlbumTitle;
    [self.view addSubview:self.backgroundView];
    [self.view addSubview:self.tableView];
    
    FWAssetAuthorizationStatus authorizationStatus = [FWAssetManager authorizationStatus];
    if (authorizationStatus == FWAssetAuthorizationStatusNotDetermined) {
        [FWAssetManager requestAuthorization:^(FWAssetAuthorizationStatus status) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (status == FWAssetAuthorizationStatusNotAuthorized) {
                    [self showDeniedView];
                } else {
                    [self loadAlbumArray];
                }
            });
        }];
    } else if (authorizationStatus == FWAssetAuthorizationStatusNotAuthorized) {
        [self showDeniedView];
    } else {
        [self loadAlbumArray];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.navigationController.navigationBarHidden != NO) {
        [self.navigationController setNavigationBarHidden:NO animated:animated];
    }
    self.navigationController.navigationBar.fw_isTranslucent = NO;
    self.navigationController.navigationBar.fw_shadowColor = nil;
    self.navigationController.navigationBar.fw_backgroundColor = self.toolBarBackgroundColor;
    self.navigationController.navigationBar.fw_foregroundColor = self.toolBarTintColor;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    self.backgroundView.frame = self.view.bounds;
    UIEdgeInsets contentInset = UIEdgeInsetsMake(UIScreen.fw_topBarHeight, self.tableView.safeAreaInsets.left, self.tableView.safeAreaInsets.bottom, self.tableView.safeAreaInsets.right);
    if (!UIEdgeInsetsEqualToEdgeInsets(self.tableView.contentInset, contentInset)) {
        self.tableView.contentInset = contentInset;
    }
}

- (void)loadAlbumArray {
    if ([self.albumControllerDelegate respondsToSelector:@selector(albumControllerWillStartLoading:)]) {
        [self.albumControllerDelegate albumControllerWillStartLoading:self];
    } else if (self.showsDefaultLoading) {
        [self fw_showLoadingWithText:nil cancel:nil];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[FWAssetManager sharedInstance] enumerateAllAlbumsWithAlbumContentType:self.contentType usingBlock:^(FWAssetGroup *resultAssetsGroup) {
            if (resultAssetsGroup) {
                [self.albumsArray addObject:resultAssetsGroup];
            } else {
                // 意味着遍历完所有的相簿了
                [self sortAlbumArray];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self refreshAlbumGroups];
                });
            }
        }];
    });
}

- (void)sortAlbumArray {
    // 把隐藏相册排序强制放到最后
    __block FWAssetGroup *hiddenGroup = nil;
    [self.albumsArray enumerateObjectsUsingBlock:^(FWAssetGroup * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.phAssetCollection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumAllHidden) {
            hiddenGroup = obj;
            *stop = YES;
        }
    }];
    if (hiddenGroup) {
        [self.albumsArray removeObject:hiddenGroup];
        [self.albumsArray addObject:hiddenGroup];
    }
}

- (void)refreshAlbumGroups {
    if ([self.albumControllerDelegate respondsToSelector:@selector(albumControllerDidFinishLoading:)]) {
        [self.albumControllerDelegate albumControllerDidFinishLoading:self];
    } else if (self.showsDefaultLoading) {
        [self fw_hideLoading];
    }
    
    if (self.maximumTableViewHeight > 0) {
        CGRect tableFrame = self.tableView.frame;
        tableFrame.size.height = self.tableViewHeight + UIScreen.fw_topBarHeight;
        self.tableView.frame = tableFrame;
    }
    
    if ([self.albumsArray count] > 0) {
        if (self.pickDefaultAlbumGroup) {
            [self pickAlbumsGroup:self.albumsArray.firstObject animated:NO];
        }
        [self.tableView reloadData];
    } else {
        if ([self.albumControllerDelegate respondsToSelector:@selector(albumControllerWillShowEmpty:)]) {
            [self.albumControllerDelegate albumControllerWillShowEmpty:self];
        } else {
            [self fw_showEmptyViewWithText:FWAppBundle.pickerEmptyTitle];
        }
    }
    
    if (self.albumArrayLoaded) {
        self.albumArrayLoaded();
    }
}

- (void)showDeniedView {
    if (self.maximumTableViewHeight > 0) {
        CGRect tableFrame = self.tableView.frame;
        tableFrame.size.height = self.tableViewHeight + UIScreen.fw_topBarHeight;
        self.tableView.frame = tableFrame;
    }
    
    if ([self.albumControllerDelegate respondsToSelector:@selector(albumControllerWillShowDenied:)]) {
        [self.albumControllerDelegate albumControllerWillShowDenied:self];
    } else {
        NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
        NSString *appName = infoDictionary[@"CFBundleDisplayName"] ?: infoDictionary[(NSString *)kCFBundleNameKey];
        NSString *tipText = [NSString stringWithFormat:FWAppBundle.pickerDeniedTitle, appName];
        [self fw_showEmptyViewWithText:tipText];
    }
    
    if (self.albumArrayLoaded) {
        self.albumArrayLoaded();
    }
}

- (CGFloat)tableViewHeight {
    if (self.maximumTableViewHeight <= 0) {
        return self.view.bounds.size.height;
    }
    
    CGFloat albumsHeight = self.albumsArray.count * self.albumTableViewCellHeight;
    return MIN(self.maximumTableViewHeight, albumsHeight + self.additionalTableViewHeight);
}

- (void)pickAlbumsGroup:(FWAssetGroup *)assetsGroup animated:(BOOL)animated {
    if (!assetsGroup) return;
    self.assetsGroup = assetsGroup;
    
    [self initImagePickerControllerIfNeeded];
    if (self.assetsGroupSelected) {
        self.assetsGroupSelected(assetsGroup);
    } else if ([self.albumControllerDelegate respondsToSelector:@selector(albumController:didSelectAssetsGroup:)]) {
        [self.albumControllerDelegate albumController:self didSelectAssetsGroup:assetsGroup];
    } else if (self.imagePickerController) {
        self.imagePickerController.title = [assetsGroup name];
        [self.imagePickerController refreshWithAssetsGroup:assetsGroup];
        [self.navigationController pushViewController:self.imagePickerController animated:animated];
    }
}

- (void)initImagePickerControllerIfNeeded {
    if (self.imagePickerController) return;
    
    FWImagePickerController *imagePickerController;
    if ([self.albumControllerDelegate respondsToSelector:@selector(imagePickerControllerForAlbumController:)]) {
        imagePickerController = [self.albumControllerDelegate imagePickerControllerForAlbumController:self];
    } else if (self.pickerControllerBlock) {
        imagePickerController = self.pickerControllerBlock();
    }
    if (imagePickerController) {
        // 清空imagePickerController导航栏左侧按钮并添加默认按钮
        if (imagePickerController.navigationItem.leftBarButtonItem) {
            imagePickerController.navigationItem.leftBarButtonItem = nil;
            imagePickerController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:FWAppBundle.cancelButton style:UIBarButtonItemStylePlain target:imagePickerController action:@selector(handleCancelButtonClick:)];
        }
        // 此处需要强引用imagePickerController，防止weak属性释放imagePickerController
        objc_setAssociatedObject(self, @selector(imagePickerController), imagePickerController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        self.imagePickerController = imagePickerController;
    }
}

#pragma mark - <UITableViewDelegate,UITableViewDataSource>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.albumsArray count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.albumTableViewCellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *kCellIdentifer = @"cell";
    FWImageAlbumTableCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifer];
    if (!cell) {
        cell = [[FWImageAlbumTableCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kCellIdentifer];
    }
    FWAssetGroup *assetsGroup = self.albumsArray[indexPath.row];
    cell.imageView.image = [assetsGroup posterImageWithSize:CGSizeMake(cell.albumImageSize, cell.albumImageSize)] ?: self.defaultPosterImage;
    cell.textLabel.font = cell.albumNameFont;
    cell.textLabel.text = [assetsGroup name];
    cell.detailTextLabel.font = cell.albumAssetsNumberFont;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"· %@", @(assetsGroup.numberOfAssets)];
    cell.checked = self.assetsGroup && self.assetsGroup == assetsGroup;
    
    if ([self.albumControllerDelegate respondsToSelector:@selector(albumController:customCell:atIndexPath:)]) {
        [self.albumControllerDelegate albumController:self customCell:cell atIndexPath:indexPath];
    } else if (self.customCellBlock) {
        self.customCellBlock(cell, indexPath);
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self pickAlbumsGroup:self.albumsArray[indexPath.row] animated:YES];
}

- (void)handleCancelButtonClick:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^(void) {
        if (self.albumControllerDelegate && [self.albumControllerDelegate respondsToSelector:@selector(albumControllerDidCancel:)]) {
            [self.albumControllerDelegate albumControllerDidCancel:self];
        } else {
            [self initImagePickerControllerIfNeeded];
            if (self.imagePickerController.imagePickerControllerDelegate && [self.imagePickerController.imagePickerControllerDelegate respondsToSelector:@selector(imagePickerControllerDidCancel:)]) {
                [self.imagePickerController.imagePickerControllerDelegate imagePickerControllerDidCancel:self.imagePickerController];
            } else if (self.imagePickerController.didCancelPicking) {
                self.imagePickerController.didCancelPicking();
            }
        }
        [self.imagePickerController.selectedImageAssetArray removeAllObjects];
    }];
}

@end

#pragma mark - FWImagePickerPreviewCollectionCell

@interface FWAsset (FWImagePickerPreviewController)

@property(nonatomic, assign) CGRect pickerCroppedRect;
@property(nonatomic, assign) NSInteger pickerCroppedAngle;

@end

@implementation FWAsset (FWImagePickerPreviewController)

- (CGRect)pickerCroppedRect {
    NSValue *value = objc_getAssociatedObject(self, @selector(pickerCroppedRect));
    return [value CGRectValue];
}

- (void)setPickerCroppedRect:(CGRect)pickerCroppedRect {
    objc_setAssociatedObject(self, @selector(pickerCroppedRect), [NSValue valueWithCGRect:pickerCroppedRect], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSInteger)pickerCroppedAngle {
    NSNumber *value = objc_getAssociatedObject(self, @selector(pickerCroppedAngle));
    return [value integerValue];
}

- (void)setPickerCroppedAngle:(NSInteger)pickerCroppedAngle {
    objc_setAssociatedObject(self, @selector(pickerCroppedAngle), @(pickerCroppedAngle), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation FWImagePickerPreviewCollectionCell {
    BOOL _showsEditedIcon;
    BOOL _showsVideoIcon;
}

@synthesize videoDurationLabel = _videoDurationLabel;
@synthesize maskView = _maskView;
@synthesize iconImageView = _iconImageView;

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self setDefaultAppearance];
    });
}

+ (void)setDefaultAppearance {
    [FWImagePickerPreviewCollectionCell appearance].imageViewInsets = UIEdgeInsetsZero;
    [FWImagePickerPreviewCollectionCell appearance].checkedBorderColor = [UIColor colorWithRed:7/255.f green:193/255.f blue:96/255.f alpha:1.0];
    [FWImagePickerPreviewCollectionCell appearance].checkedBorderWidth = 3;
    [FWImagePickerPreviewCollectionCell appearance].disabledMaskColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
    [FWImagePickerPreviewCollectionCell appearance].videoDurationLabelFont = [UIFont systemFontOfSize:12];
    [FWImagePickerPreviewCollectionCell appearance].videoDurationLabelTextColor = UIColor.whiteColor;
    [FWImagePickerPreviewCollectionCell appearance].videoDurationLabelMargins = UIEdgeInsetsMake(5, 5, 5, 7);
    [FWImagePickerPreviewCollectionCell appearance].iconImageViewMargins = UIEdgeInsetsMake(5, 7, 5, 5);
    [FWImagePickerPreviewCollectionCell appearance].showsVideoDurationLabel = YES;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self didInitialize];
        [self fw_applyAppearance];
    }
    return self;
}

- (void)didInitialize {
    _imageView = [[UIImageView alloc] init];
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.clipsToBounds = YES;
    [self.contentView addSubview:self.imageView];
    
    _iconImageView = [[UIImageView alloc] init];
    self.iconImageView.hidden = YES;
    [self.contentView addSubview:self.iconImageView];
    
    _maskView = [[UIView alloc] init];
    [self.contentView addSubview:self.maskView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.imageView.frame = CGRectMake(self.imageViewInsets.left, self.imageViewInsets.top, CGRectGetWidth(self.contentView.bounds) - self.imageViewInsets.left - self.imageViewInsets.right, CGRectGetHeight(self.contentView.bounds) - self.imageViewInsets.top - self.imageViewInsets.bottom);
    self.maskView.frame = self.contentView.bounds;
    
    if (self.videoDurationLabel && !self.videoDurationLabel.hidden) {
        [self.videoDurationLabel sizeToFit];
        self.videoDurationLabel.fw_origin = CGPointMake(CGRectGetWidth(self.contentView.bounds) - self.videoDurationLabelMargins.right - CGRectGetWidth(self.videoDurationLabel.frame), CGRectGetHeight(self.contentView.bounds) - self.videoDurationLabelMargins.bottom - CGRectGetHeight(self.videoDurationLabel.frame));
    }
    
    if (!self.iconImageView.hidden) {
        [self.iconImageView sizeToFit];
        self.iconImageView.fw_origin = CGPointMake(self.iconImageViewMargins.left, CGRectGetHeight(self.contentView.bounds) - self.iconImageViewMargins.bottom - CGRectGetHeight(self.iconImageView.frame));
    }
}

- (void)setChecked:(BOOL)checked {
    _checked = checked;
    if (checked) {
        self.maskView.layer.borderWidth = self.checkedBorderWidth;
        self.maskView.layer.borderColor = self.checkedBorderColor.CGColor;
    } else {
        self.maskView.layer.borderWidth = 0;
        self.maskView.layer.borderColor = nil;
    }
}

- (void)setDisabled:(BOOL)disabled {
    _disabled = disabled;
    self.maskView.backgroundColor = disabled ? self.disabledMaskColor : nil;
}

- (void)setCheckedBorderColor:(UIColor *)checkedBorderColor {
    _checkedBorderColor = checkedBorderColor;
    self.maskView.layer.borderColor = self.checked ? checkedBorderColor.CGColor : nil;
}

- (void)setCheckedBorderWidth:(CGFloat)checkedBorderWidth {
    _checkedBorderWidth = checkedBorderWidth;
    self.maskView.layer.borderWidth = self.checked ? checkedBorderWidth : 0;
}

- (void)setDisabledMaskColor:(UIColor *)disabledMaskColor {
    _disabledMaskColor = disabledMaskColor;
    self.maskView.backgroundColor = self.disabled ? disabledMaskColor : nil;
}

- (void)setVideoDurationLabelFont:(UIFont *)videoDurationLabelFont {
    _videoDurationLabelFont = videoDurationLabelFont;
    self.videoDurationLabel.font = videoDurationLabelFont;
}

- (void)setVideoDurationLabelTextColor:(UIColor *)videoDurationLabelTextColor {
    _videoDurationLabelTextColor = videoDurationLabelTextColor;
    self.videoDurationLabel.textColor = videoDurationLabelTextColor;
}

- (void)setShowsVideoDurationLabel:(BOOL)showsVideoDurationLabel {
    _showsVideoDurationLabel = showsVideoDurationLabel;
    self.videoDurationLabel.hidden = !showsVideoDurationLabel || !_showsVideoIcon;
}

- (void)setEditedIconImage:(UIImage *)editedIconImage {
    _editedIconImage = editedIconImage;
    [self updateIconImageView];
}

- (void)setVideoIconImage:(UIImage *)videoIconImage {
    _videoIconImage = videoIconImage;
    [self updateIconImageView];
}

- (void)initVideoDurationLabelIfNeeded {
    if (!self.videoDurationLabel) {
        _videoDurationLabel = [[UILabel alloc] init];
        _videoDurationLabel.font = self.videoDurationLabelFont;
        _videoDurationLabel.textColor = self.videoDurationLabelTextColor;
        [self.contentView insertSubview:_videoDurationLabel belowSubview:self.maskView];
        [self setNeedsLayout];
    }
}

- (void)renderWithAsset:(FWAsset *)asset referenceSize:(CGSize)referenceSize {
    self.assetIdentifier = asset.identifier;
    if (asset.editedImage) {
        self.imageView.image = asset.editedImage;
    } else {
        [asset requestThumbnailImageWithSize:referenceSize completion:^(UIImage *result, NSDictionary *info, BOOL finished) {
            if ([self.assetIdentifier isEqualToString:asset.identifier]) {
                self.imageView.image = result;
            }
        }];
    }
    
    if (asset.assetType == FWAssetTypeVideo && self.showsVideoDurationLabel) {
        [self initVideoDurationLabelIfNeeded];
        NSUInteger min = floor(asset.duration / 60);
        NSUInteger sec = floor(asset.duration - min * 60);
        self.videoDurationLabel.text = [NSString stringWithFormat:@"%02ld:%02ld", (long)min, (long)sec];
        self.videoDurationLabel.hidden = NO;
    } else {
        self.videoDurationLabel.hidden = YES;
    }
    
    _showsEditedIcon = asset.editedImage != nil;
    _showsVideoIcon = asset.assetType == FWAssetTypeVideo;
    [self updateIconImageView];
}

- (void)updateIconImageView {
    UIImage *iconImage = nil;
    if (_showsEditedIcon && self.editedIconImage) {
        iconImage = self.editedIconImage;
    } else if (_showsVideoIcon && self.videoIconImage) {
        iconImage = self.videoIconImage;
    }
    self.iconImageView.image = iconImage;
    self.iconImageView.hidden = !iconImage;
    [self setNeedsLayout];
}

@end

#pragma mark - FWImagePickerPreviewController

@interface FWImagePickerPreviewController ()

@property(nonatomic, weak) FWImagePickerController *imagePickerController;
@property(nonatomic, assign) NSInteger editCheckedIndex;
@property(nonatomic, assign) BOOL shouldResetPreviewView;

@end

@implementation FWImagePickerPreviewController {
    BOOL _singleCheckMode;
    BOOL _previewMode;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        _showsEditButton = YES;
        _showsEditCollectionView = YES;
        _shouldUseOriginImage = YES;
        _editCheckedIndex = NSNotFound;
        self.extendedLayoutIncludesOpaqueBars = YES;
        self.editCollectionViewHeight = 80;
        self.editCollectionCellSize = CGSizeMake(60, 60);
        self.maximumSelectImageCount = 9;
        self.minimumSelectImageCount = 0;
        _toolBarPaddingHorizontal = 16;
        _showsDefaultLoading = YES;
        
        _toolBarBackgroundColor = [UIColor colorWithRed:27/255.f green:27/255.f blue:27/255.f alpha:1.f];
        _toolBarTintColor = UIColor.whiteColor;
        
        _checkboxImage = FWAppBundle.pickerCheckImage;
        _checkboxCheckedImage = FWAppBundle.pickerCheckedImage;
        _originImageCheckboxImage = [FWAppBundle.pickerCheckImage fw_imageWithScaleSize:CGSizeMake(18, 18)];
        _originImageCheckboxCheckedImage = [FWAppBundle.pickerCheckedImage fw_imageWithScaleSize:CGSizeMake(18, 18)];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.imagePreviewView.delegate = self;
    [self.view addSubview:self.topToolBarView];
    [self.view addSubview:self.bottomToolBarView];
    [self.view addSubview:self.editCollectionView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.navigationController.navigationBarHidden != YES) {
        [self.navigationController setNavigationBarHidden:YES animated:animated];
    }
    
    if (!_singleCheckMode) {
        FWAsset *imageAsset = self.imagesAssetArray[self.imagePreviewView.currentImageIndex];
        self.checkboxButton.selected = [self.selectedImageAssetArray containsObject:imageAsset];
    }
    [self updateOriginImageCheckboxButtonWithIndex:self.imagePreviewView.currentImageIndex];
    [self updateImageCountAndCollectionView:NO];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.topToolBarView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), UIScreen.fw_topBarHeight);
    CGFloat topToolbarPaddingTop = self.view.safeAreaInsets.top;
    CGFloat topToolbarContentHeight = CGRectGetHeight(self.topToolBarView.bounds) - topToolbarPaddingTop;
    self.backButton.fw_origin = CGPointMake(self.toolBarPaddingHorizontal + self.view.safeAreaInsets.left, topToolbarPaddingTop + (topToolbarContentHeight - CGRectGetHeight(self.backButton.frame)) / 2.0);
    if (!self.checkboxButton.hidden) {
        self.checkboxButton.fw_origin = CGPointMake(CGRectGetWidth(self.topToolBarView.frame) - self.toolBarPaddingHorizontal - self.view.safeAreaInsets.right - CGRectGetWidth(self.checkboxButton.frame), topToolbarPaddingTop + (topToolbarContentHeight - CGRectGetHeight(self.checkboxButton.frame)) / 2.0);
    }
    
    CGFloat bottomToolBarHeight = self.bottomToolBarHeight;
    CGFloat bottomToolBarContentHeight = bottomToolBarHeight - self.view.safeAreaInsets.bottom;
    self.bottomToolBarView.frame = CGRectMake(0, CGRectGetHeight(self.view.bounds) - bottomToolBarHeight, CGRectGetWidth(self.view.bounds), bottomToolBarHeight);
    [self updateSendButtonLayout];
    
    self.editButton.fw_origin = CGPointMake(self.toolBarPaddingHorizontal + self.view.safeAreaInsets.left, (bottomToolBarContentHeight - CGRectGetHeight(self.editButton.frame)) / 2.0);
    if (self.showsEditButton) {
        self.originImageCheckboxButton.fw_origin = CGPointMake((CGRectGetWidth(self.bottomToolBarView.frame) - CGRectGetWidth(self.originImageCheckboxButton.frame)) / 2.0, (bottomToolBarContentHeight - CGRectGetHeight(self.originImageCheckboxButton.frame)) / 2.0);
    } else {
        self.originImageCheckboxButton.fw_origin = CGPointMake(self.toolBarPaddingHorizontal + self.view.safeAreaInsets.left, (bottomToolBarContentHeight - CGRectGetHeight(self.originImageCheckboxButton.frame)) / 2.0);
    }
    
    self.editCollectionView.frame = CGRectMake(0, CGRectGetMinY(self.bottomToolBarView.frame) - self.editCollectionViewHeight, CGRectGetWidth(self.view.bounds), self.editCollectionViewHeight);
    UIEdgeInsets contentInset = UIEdgeInsetsMake(0, self.editCollectionView.safeAreaInsets.left, 0, self.editCollectionView.safeAreaInsets.right);
    if (!UIEdgeInsetsEqualToEdgeInsets(self.editCollectionView.contentInset, contentInset)) {
        self.editCollectionView.contentInset = contentInset;
    }
}

- (BOOL)preferredNavigationBarHidden {
    return YES;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark - Getters & Setters

@synthesize editCollectionViewLayout = _editCollectionViewLayout;
- (UICollectionViewFlowLayout *)editCollectionViewLayout {
    if (!_editCollectionViewLayout) {
        _editCollectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
        _editCollectionViewLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _editCollectionViewLayout.sectionInset = UIEdgeInsetsMake(10, 16, 10, 16);
        _editCollectionViewLayout.minimumLineSpacing = _editCollectionViewLayout.sectionInset.bottom;
        _editCollectionViewLayout.minimumInteritemSpacing = _editCollectionViewLayout.sectionInset.left;
    }
    return _editCollectionViewLayout;
}

@synthesize editCollectionView = _editCollectionView;
- (UICollectionView *)editCollectionView {
    if (!_editCollectionView) {
        _editCollectionView = [[UICollectionView alloc] initWithFrame:self.isViewLoaded ? self.view.bounds : CGRectZero collectionViewLayout:self.editCollectionViewLayout];
        _editCollectionView.backgroundColor = self.toolBarBackgroundColor;
        _editCollectionView.hidden = YES;
        _editCollectionView.delegate = self;
        _editCollectionView.dataSource = self;
        _editCollectionView.showsHorizontalScrollIndicator = NO;
        _editCollectionView.showsVerticalScrollIndicator = NO;
        _editCollectionView.alwaysBounceHorizontal = YES;
        [_editCollectionView registerClass:[FWImagePickerPreviewCollectionCell class] forCellWithReuseIdentifier:@"cell"];
        _editCollectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    return _editCollectionView;
}

@synthesize topToolBarView = _topToolBarView;
- (UIView *)topToolBarView {
    if (!_topToolBarView) {
        _topToolBarView = [[UIView alloc] init];
        _topToolBarView.backgroundColor = self.toolBarBackgroundColor;
        _topToolBarView.tintColor = self.toolBarTintColor;
        [_topToolBarView addSubview:self.backButton];
        [_topToolBarView addSubview:self.checkboxButton];
    }
    return _topToolBarView;
}

@synthesize backButton = _backButton;
- (UIButton *)backButton {
    if (!_backButton) {
        _backButton = [[UIButton alloc] init];
        [_backButton setImage:FWAppBundle.navBackImage forState:UIControlStateNormal];
        [_backButton sizeToFit];
        [_backButton addTarget:self action:@selector(handleCancelButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        _backButton.fw_touchInsets = UIEdgeInsetsMake(30, 20, 50, 80);
        _backButton.fw_disabledAlpha = 0.3;
        _backButton.fw_highlightedAlpha = 0.5;
    }
    return _backButton;
}

@synthesize checkboxButton = _checkboxButton;
- (UIButton *)checkboxButton {
    if (!_checkboxButton) {
        _checkboxButton = [[UIButton alloc] init];
        [_checkboxButton setImage:self.checkboxImage forState:UIControlStateNormal];
        [_checkboxButton setImage:self.checkboxCheckedImage forState:UIControlStateSelected];
        [_checkboxButton setImage:self.checkboxCheckedImage forState:UIControlStateSelected|UIControlStateHighlighted];
        [_checkboxButton sizeToFit];
        [_checkboxButton addTarget:self action:@selector(handleCheckButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        _checkboxButton.fw_touchInsets = UIEdgeInsetsMake(10, 10, 10, 10);
        _checkboxButton.fw_disabledAlpha = 0.3;
        _checkboxButton.fw_highlightedAlpha = 0.5;
    }
    return _checkboxButton;
}

@synthesize bottomToolBarView = _bottomToolBarView;
- (UIView *)bottomToolBarView {
    if (!_bottomToolBarView) {
        _bottomToolBarView = [[UIView alloc] init];
        _bottomToolBarView.backgroundColor = self.toolBarBackgroundColor;
        [_bottomToolBarView addSubview:self.editButton];
        [_bottomToolBarView addSubview:self.sendButton];
        [_bottomToolBarView addSubview:self.originImageCheckboxButton];
    }
    return _bottomToolBarView;
}

- (CGFloat)bottomToolBarHeight {
    return _bottomToolBarHeight > 0 ? _bottomToolBarHeight : UIScreen.fw_toolBarHeight;
}

@synthesize editButton = _editButton;
- (UIButton *)editButton {
    if (!_editButton) {
        _editButton = [[UIButton alloc] init];
        _editButton.hidden = !self.showsEditButton;
        _editButton.fw_touchInsets = UIEdgeInsetsMake(10, 10, 10, 10);
        [_editButton setTitle:FWAppBundle.editButton forState:UIControlStateNormal];
        _editButton.titleLabel.font = [UIFont systemFontOfSize:16];
        [_editButton sizeToFit];
        _editButton.fw_disabledAlpha = 0.3;
        _editButton.fw_highlightedAlpha = 0.5;
        [_editButton addTarget:self action:@selector(handleEditButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _editButton;
}

@synthesize sendButton = _sendButton;
- (UIButton *)sendButton {
    if (!_sendButton) {
        _sendButton = [[UIButton alloc] init];
        _sendButton.fw_touchInsets = UIEdgeInsetsMake(10, 10, 10, 10);
        [_sendButton setTitle:FWAppBundle.doneButton forState:UIControlStateNormal];
        _sendButton.titleLabel.font = [UIFont systemFontOfSize:16];
        [_sendButton sizeToFit];
        _sendButton.fw_disabledAlpha = 0.3;
        _sendButton.fw_highlightedAlpha = 0.5;
        [_sendButton addTarget:self action:@selector(handleSendButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _sendButton;
}

@synthesize originImageCheckboxButton = _originImageCheckboxButton;
- (UIButton *)originImageCheckboxButton {
    if (!_originImageCheckboxButton) {
        _originImageCheckboxButton = [[UIButton alloc] init];
        _originImageCheckboxButton.hidden = !self.showsOriginImageCheckboxButton;
        _originImageCheckboxButton.titleLabel.font = [UIFont systemFontOfSize:16];
        [_originImageCheckboxButton setImage:self.originImageCheckboxImage forState:UIControlStateNormal];
        [_originImageCheckboxButton setImage:self.originImageCheckboxCheckedImage forState:UIControlStateSelected];
        [_originImageCheckboxButton setImage:self.originImageCheckboxCheckedImage forState:UIControlStateSelected|UIControlStateHighlighted];
        [_originImageCheckboxButton setTitle:FWAppBundle.originalButton forState:UIControlStateNormal];
        [_originImageCheckboxButton setImageEdgeInsets:UIEdgeInsetsMake(0, -5.0f, 0, 5.0f)];
        [_originImageCheckboxButton setContentEdgeInsets:UIEdgeInsetsMake(0, 5.0f, 0, 0)];
        [_originImageCheckboxButton sizeToFit];
        _originImageCheckboxButton.fw_touchInsets = UIEdgeInsetsMake(10, 10, 10, 10);
        _originImageCheckboxButton.fw_disabledAlpha = 0.3;
        _originImageCheckboxButton.fw_highlightedAlpha = 0.5;
        [_originImageCheckboxButton addTarget:self action:@selector(handleOriginImageCheckboxButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _originImageCheckboxButton;
}

- (NSMutableArray<FWAsset *> *)editImageAssetArray {
    if (_previewMode) {
        return self.imagesAssetArray;
    } else {
        return self.selectedImageAssetArray;
    }
}

- (void)setToolBarBackgroundColor:(UIColor *)toolBarBackgroundColor {
    _toolBarBackgroundColor = toolBarBackgroundColor;
    self.topToolBarView.backgroundColor = self.toolBarBackgroundColor;
    self.bottomToolBarView.backgroundColor = self.toolBarBackgroundColor;
}

- (void)setToolBarTintColor:(UIColor *)toolBarTintColor {
    _toolBarTintColor = toolBarTintColor;
    self.topToolBarView.tintColor = toolBarTintColor;
    self.bottomToolBarView.tintColor = toolBarTintColor;
}

- (void)setShowsEditButton:(BOOL)showsEditButton {
    _showsEditButton = showsEditButton;
    self.editButton.hidden = !showsEditButton;
}

- (void)setShowsOriginImageCheckboxButton:(BOOL)showsOriginImageCheckboxButton {
    _showsOriginImageCheckboxButton = showsOriginImageCheckboxButton;
    self.shouldUseOriginImage = !showsOriginImageCheckboxButton;
    self.originImageCheckboxButton.hidden = !showsOriginImageCheckboxButton;
}

- (void)setDownloadStatus:(FWAssetDownloadStatus)downloadStatus {
    _downloadStatus = downloadStatus;
    if (!_singleCheckMode) {
        self.checkboxButton.hidden = NO;
    }
}

- (void)updateImagePickerPreviewViewWithImagesAssetArray:(NSMutableArray<FWAsset *> *)imageAssetArray
                                 selectedImageAssetArray:(NSMutableArray<FWAsset *> *)selectedImageAssetArray
                                       currentImageIndex:(NSInteger)currentImageIndex
                                         singleCheckMode:(BOOL)singleCheckMode
                                             previewMode:(BOOL)previewMode {
    self.imagesAssetArray = imageAssetArray;
    self.selectedImageAssetArray = selectedImageAssetArray;
    self.imagePreviewView.currentImageIndex = currentImageIndex;
    self.shouldResetPreviewView = YES;
    _singleCheckMode = singleCheckMode;
    _previewMode = previewMode;
    if (singleCheckMode) {
        self.checkboxButton.hidden = YES;
    }
}

#pragma mark - <__FWImagePreviewViewDelegate>

- (NSInteger)numberOfImagesInImagePreviewView:(__FWImagePreviewView *)imagePreviewView {
    return [self.imagesAssetArray count];
}

- (__FWImagePreviewMediaType)imagePreviewView:(__FWImagePreviewView *)imagePreviewView assetTypeAtIndex:(NSInteger)index {
    FWAsset *imageAsset = [self.imagesAssetArray objectAtIndex:index];
    if (imageAsset.assetType == FWAssetTypeImage) {
        if (imageAsset.assetSubType == FWAssetSubTypeLivePhoto) {
            BOOL checkLivePhoto = (self.imagePickerController.filterType & FWImagePickerFilterTypeLivePhoto) || self.imagePickerController.filterType < 1;
            if (checkLivePhoto) return __FWImagePreviewMediaTypeLivePhoto;
        }
        return __FWImagePreviewMediaTypeImage;
    } else if (imageAsset.assetType == FWAssetTypeVideo) {
        return __FWImagePreviewMediaTypeVideo;
    } else {
        return __FWImagePreviewMediaTypeOthers;
    }
}

- (BOOL)imagePreviewView:(__FWImagePreviewView *)imagePreviewView shouldResetZoomImageView:(__FWZoomImageView *)zoomImageView atIndex:(NSInteger)index {
    if (self.shouldResetPreviewView) {
        // 刷新数据源时需重置zoomImageView，清空当前显示内容
        self.shouldResetPreviewView = NO;
        return YES;
    } else {
        // 为了防止切换图片时产生闪烁，快速切换时只重置videoPlayerItem，加载失败时需清空显示
        zoomImageView.videoPlayerItem = nil;
        return NO;
    }
}

- (void)imagePreviewView:(__FWImagePreviewView *)imagePreviewView renderZoomImageView:(__FWZoomImageView *)zoomImageView atIndex:(NSInteger)index {
    [self requestImageForZoomImageView:zoomImageView withIndex:index];
    
    UIEdgeInsets insets = zoomImageView.videoToolbarMargins;
    insets.bottom = [__FWZoomImageView appearance].videoToolbarMargins.bottom + CGRectGetHeight(self.bottomToolBarView.frame) - imagePreviewView.safeAreaInsets.bottom;
    zoomImageView.videoToolbarMargins = insets;// videToolbarMargins 是利用 UIAppearance 赋值的，也即意味着要在 addSubview 之后才会被赋值，而在 renderZoomImageView 里，zoomImageView 可能尚未被添加到 view 层级里，所以无法通过 zoomImageView.videoToolbarMargins 获取到原来的值，因此只能通过 [__FWZoomImageView appearance] 的方式获取
}

- (void)imagePreviewView:(__FWImagePreviewView *)imagePreviewView willScrollHalfToIndex:(NSInteger)index {
    FWAsset *imageAsset = self.imagesAssetArray[index];
    if (!_singleCheckMode) {
        self.checkboxButton.selected = [self.selectedImageAssetArray containsObject:imageAsset];
    }
    
    [self updateOriginImageCheckboxButtonWithIndex:index];
    [self updateCollectionViewCheckedIndex:[self.editImageAssetArray indexOfObject:imageAsset]];
}

- (void)requestImageForZoomImageView:(__FWZoomImageView *)imageView withIndex:(NSInteger)index {
    // 如果是走 PhotoKit 的逻辑，那么这个 block 会被多次调用，并且第一次调用时返回的图片是一张小图，
    // 拉取图片的过程中可能会多次返回结果，且图片尺寸越来越大，因此这里 contentMode为ScaleAspectFit 以防止图片大小跳动
    FWAsset *imageAsset = [self.imagesAssetArray objectAtIndex:index];
    if (imageAsset.editedImage) {
        imageView.image = imageAsset.editedImage;
        return;
    }
    
    // 获取资源图片的预览图，这是一张适合当前设备屏幕大小的图片，最终展示时把图片交给组件控制最终展示出来的大小。
    // 系统相册本质上也是这么处理的，因此无论是系统相册，还是这个系列组件，由始至终都没有显示照片原图，
    // 这也是系统相册能加载这么快的原因。
    // 另外这里采用异步请求获取图片，避免获取图片时 UI 卡顿
    PHAssetImageProgressHandler phProgressHandler = ^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
        imageAsset.downloadProgress = progress;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.downloadStatus != FWAssetDownloadStatusDownloading) {
                self.downloadStatus = FWAssetDownloadStatusDownloading;
                imageView.progress = 0;
            }
            // 拉取资源的初期，会有一段时间没有进度，猜测是发出网络请求以及与 iCloud 建立连接的耗时，这时预先给个 0.02 的进度值，看上去好看些
            float targetProgress = fmax(0.02, progress);
            if (targetProgress < imageView.progress) {
                imageView.progress = targetProgress;
            } else {
                imageView.progress = fmax(0.02, progress);
            }
            if (error) {
                self.downloadStatus = FWAssetDownloadStatusFailed;
                imageView.progress = 0;
            }
        });
    };
    if (imageAsset.assetType == FWAssetTypeVideo) {
        imageView.tag = -1;
        imageAsset.requestID = [imageAsset requestPlayerItemWithCompletion:^(AVPlayerItem *playerItem, NSDictionary *info) {
            // 这里可能因为 imageView 复用，导致前面的请求得到的结果显示到别的 imageView 上，
            // 因此判断如果是新请求（无复用问题）或者是当前的请求才把获得的图片结果展示出来
            dispatch_async(dispatch_get_main_queue(), ^{
                BOOL isCurrentRequest = (imageView.tag == -1 && imageAsset.requestID == 0) || imageView.tag == imageAsset.requestID;
                BOOL loadICloudImageFault = !playerItem || info[PHImageErrorKey];
                if (isCurrentRequest && !loadICloudImageFault) {
                    imageView.videoPlayerItem = playerItem;
                } else if (isCurrentRequest) {
                    imageView.image = nil;
                    imageView.livePhoto = nil;
                }
            });
        } withProgressHandler:phProgressHandler];
        imageView.tag = imageAsset.requestID;
    } else {
        if (imageAsset.assetType != FWAssetTypeImage) {
            return;
        }
        
        // 这么写是为了消除 Xcode 的 API available warning
        BOOL isLivePhoto = NO;
        BOOL checkLivePhoto = (self.imagePickerController.filterType & FWImagePickerFilterTypeLivePhoto) || self.imagePickerController.filterType < 1;
        if (imageAsset.assetSubType == FWAssetSubTypeLivePhoto && checkLivePhoto) {
            isLivePhoto = YES;
            imageView.tag = -1;
            imageAsset.requestID = [imageAsset requestLivePhotoWithCompletion:^void(PHLivePhoto *livePhoto, NSDictionary *info, BOOL finished) {
                // 这里可能因为 imageView 复用，导致前面的请求得到的结果显示到别的 imageView 上，
                // 因此判断如果是新请求（无复用问题）或者是当前的请求才把获得的图片结果展示出来
                dispatch_async(dispatch_get_main_queue(), ^{
                    BOOL isCurrentRequest = (imageView.tag == -1 && imageAsset.requestID == 0) || imageView.tag == imageAsset.requestID;
                    BOOL loadICloudImageFault = !livePhoto || info[PHImageErrorKey];
                    if (isCurrentRequest && !loadICloudImageFault) {
                        // 如果是走 PhotoKit 的逻辑，那么这个 block 会被多次调用，并且第一次调用时返回的图片是一张小图，
                        // 这时需要把图片放大到跟屏幕一样大，避免后面加载大图后图片的显示会有跳动
                        imageView.livePhoto = livePhoto;
                    } else if (isCurrentRequest) {
                        imageView.image = nil;
                        imageView.livePhoto = nil;
                    }
                    if (finished && livePhoto) {
                        // 资源资源已经在本地或下载成功
                        [imageAsset updateDownloadStatusWithDownloadResult:YES];
                        self.downloadStatus = FWAssetDownloadStatusSucceed;
                        imageView.progress = 1;
                    } else if (finished) {
                        // 下载错误
                        [imageAsset updateDownloadStatusWithDownloadResult:NO];
                        self.downloadStatus = FWAssetDownloadStatusFailed;
                        imageView.progress = 0;
                    }
                });
            } withProgressHandler:phProgressHandler];
            imageView.tag = imageAsset.requestID;
        }
        
        if (isLivePhoto) {
        } else if (imageAsset.assetSubType == FWAssetSubTypeGIF) {
            [imageAsset requestImageDataWithCompletion:^(NSData *imageData, NSDictionary<NSString *,id> *info, BOOL isGIF, BOOL isHEIC) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    UIImage *resultImage = [UIImage fw_imageWithData:imageData];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (resultImage) {
                            imageView.image = resultImage;
                        } else {
                            imageView.image = nil;
                            imageView.livePhoto = nil;
                        }
                    });
                });
            }];
        } else {
            imageView.tag = -1;
            imageAsset.requestID = [imageAsset requestOriginImageWithCompletion:^void(UIImage *result, NSDictionary *info, BOOL finished) {
                // 这里可能因为 imageView 复用，导致前面的请求得到的结果显示到别的 imageView 上，
                // 因此判断如果是新请求（无复用问题）或者是当前的请求才把获得的图片结果展示出来
                dispatch_async(dispatch_get_main_queue(), ^{
                    BOOL isCurrentRequest = (imageView.tag == -1 && imageAsset.requestID == 0) || imageView.tag == imageAsset.requestID;
                    BOOL loadICloudImageFault = !result || info[PHImageErrorKey];
                    if (isCurrentRequest && !loadICloudImageFault) {
                        imageView.image = result;
                    } else if (isCurrentRequest) {
                        imageView.image = nil;
                        imageView.livePhoto = nil;
                    }
                    if (finished && result) {
                        // 资源资源已经在本地或下载成功
                        [imageAsset updateDownloadStatusWithDownloadResult:YES];
                        self.downloadStatus = FWAssetDownloadStatusSucceed;
                        imageView.progress = 1;
                    } else if (finished) {
                        // 下载错误
                        [imageAsset updateDownloadStatusWithDownloadResult:NO];
                        self.downloadStatus = FWAssetDownloadStatusFailed;
                        imageView.progress = 0;
                    }
                });
            } withProgressHandler:phProgressHandler];
            imageView.tag = imageAsset.requestID;
        }
    }
}

#pragma mark - <__FWZoomImageViewDelegate>

- (void)singleTouchInZoomingImageView:(__FWZoomImageView *)zoomImageView location:(CGPoint)location {
    self.topToolBarView.hidden = !self.topToolBarView.hidden;
    self.bottomToolBarView.hidden = !self.bottomToolBarView.hidden;
    if (!_singleCheckMode && self.showsEditCollectionView) {
        self.editCollectionView.hidden = !self.editCollectionView.hidden || self.editImageAssetArray.count < 1;
    }
}

- (void)zoomImageView:(__FWZoomImageView *)imageView didHideVideoToolbar:(BOOL)didHide {
    self.topToolBarView.hidden = didHide;
    self.bottomToolBarView.hidden = didHide;
    if (!_singleCheckMode && self.showsEditCollectionView) {
        self.editCollectionView.hidden = didHide || self.editImageAssetArray.count < 1;
    }
}

#pragma mark - <UICollectionViewDelegate, UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.editImageAssetArray count];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return self.editCollectionCellSize;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    FWAsset *imageAsset = [self.editImageAssetArray objectAtIndex:indexPath.item];
    FWImagePickerPreviewCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    CGSize referenceSize = CGSizeMake(self.editCollectionCellSize.width - cell.imageViewInsets.left - cell.imageViewInsets.right, self.editCollectionCellSize.height - cell.imageViewInsets.top - cell.imageViewInsets.bottom);
    [cell renderWithAsset:imageAsset referenceSize:referenceSize];
    cell.checked = indexPath.item == _editCheckedIndex;
    cell.disabled = ![self.selectedImageAssetArray containsObject:imageAsset];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(imagePickerPreviewController:customCell:atIndexPath:)]) {
        [self.delegate imagePickerPreviewController:self customCell:cell atIndexPath:indexPath];
    } else if (self.customCellBlock) {
        self.customCellBlock(cell, indexPath);
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    FWAsset *imageAsset = [self.editImageAssetArray objectAtIndex:indexPath.item];
    NSInteger imageIndex = [self.imagesAssetArray indexOfObject:imageAsset];
    if (imageIndex != NSNotFound && self.imagePreviewView.currentImageIndex != imageIndex) {
        self.imagePreviewView.currentImageIndex = imageIndex;
        [self updateOriginImageCheckboxButtonWithIndex:imageIndex];
    }
    
    [self updateCollectionViewCheckedIndex:indexPath.item];
}

#pragma mark - 按钮点击回调

- (void)handleCancelButtonClick:(UIButton *)button {
    if (self.navigationController) {
        [self.navigationController popViewControllerAnimated:YES];
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(imagePickerPreviewControllerDidCancel:)]) {
        [self.delegate imagePickerPreviewControllerDidCancel:self];
    }
}

- (void)handleCheckButtonClick:(UIButton *)button {
    if (button.selected) {
        if ([self.delegate respondsToSelector:@selector(imagePickerPreviewController:willUncheckImageAtIndex:)]) {
            [self.delegate imagePickerPreviewController:self willUncheckImageAtIndex:self.imagePreviewView.currentImageIndex];
        }
        
        button.selected = NO;
        FWAsset *imageAsset = self.imagesAssetArray[self.imagePreviewView.currentImageIndex];
        [self.selectedImageAssetArray removeObject:imageAsset];
        [self updateImageCountAndCollectionView:YES];
        
        if ([self.delegate respondsToSelector:@selector(imagePickerPreviewController:didUncheckImageAtIndex:)]) {
            [self.delegate imagePickerPreviewController:self didUncheckImageAtIndex:self.imagePreviewView.currentImageIndex];
        }
    } else {
        if ([self.selectedImageAssetArray count] >= self.maximumSelectImageCount) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(imagePickerPreviewControllerWillShowExceed:)]) {
                [self.delegate imagePickerPreviewControllerWillShowExceed:self];
            } else {
                [self fw_showAlertWithTitle:[NSString stringWithFormat:FWAppBundle.pickerExceedTitle, @(self.maximumSelectImageCount)] message:nil cancel:FWAppBundle.closeButton cancelBlock:nil];
            }
            return;
        }
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(imagePickerPreviewController:willCheckImageAtIndex:)]) {
            [self.delegate imagePickerPreviewController:self willCheckImageAtIndex:self.imagePreviewView.currentImageIndex];
        }
        
        button.selected = YES;
        FWAsset *imageAsset = [self.imagesAssetArray objectAtIndex:self.imagePreviewView.currentImageIndex];
        [self.selectedImageAssetArray addObject:imageAsset];
        [self updateImageCountAndCollectionView:YES];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(imagePickerPreviewController:didCheckImageAtIndex:)]) {
            [self.delegate imagePickerPreviewController:self didCheckImageAtIndex:self.imagePreviewView.currentImageIndex];
        }
    }
}

- (void)handleEditButtonClick:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(imagePickerPreviewController:willEditImageAtIndex:)]) {
        [self.delegate imagePickerPreviewController:self willEditImageAtIndex:self.imagePreviewView.currentImageIndex];
        return;
    }
    
    __FWZoomImageView *imageView = [self.imagePreviewView currentZoomImageView];
    FWAsset *imageAsset = self.imagesAssetArray[self.imagePreviewView.currentImageIndex];
    [imageAsset requestOriginImageWithCompletion:^(UIImage * _Nullable result, NSDictionary<NSString *,id> * _Nullable info, BOOL finished) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (finished && result) {
                // 资源资源已经在本地或下载成功
                [imageAsset updateDownloadStatusWithDownloadResult:YES];
                self.downloadStatus = FWAssetDownloadStatusSucceed;
                imageView.progress = 1;
                
                [self beginEditImageAsset:imageAsset image:result];
            } else if (finished) {
                // 下载错误
                [imageAsset updateDownloadStatusWithDownloadResult:NO];
                self.downloadStatus = FWAssetDownloadStatusFailed;
                imageView.progress = 0;
            }
        });
    } withProgressHandler:^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
        imageAsset.downloadProgress = progress;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.downloadStatus != FWAssetDownloadStatusDownloading) {
                self.downloadStatus = FWAssetDownloadStatusDownloading;
                imageView.progress = 0;
            }
            // 拉取资源的初期，会有一段时间没有进度，猜测是发出网络请求以及与 iCloud 建立连接的耗时，这时预先给个 0.02 的进度值，看上去好看些
            float targetProgress = fmax(0.02, progress);
            if (targetProgress < imageView.progress) {
                imageView.progress = targetProgress;
            } else {
                imageView.progress = fmax(0.02, progress);
            }
            if (error) {
                self.downloadStatus = FWAssetDownloadStatusFailed;
                imageView.progress = 0;
            }
        });
    }];
}

- (void)handleSendButtonClick:(UIButton *)sender {
    sender.userInteractionEnabled = NO;
    if (self.selectedImageAssetArray.count == 0) {
        // 如果没选中任何一张，则点击发送按钮直接发送当前这张大图
        FWAsset *currentAsset = self.imagesAssetArray[self.imagePreviewView.currentImageIndex];
        [self.selectedImageAssetArray addObject:currentAsset];
    }
    
    if (self.imagePickerController.shouldRequestImage) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(imagePickerPreviewControllerWillStartLoading:)]) {
            [self.delegate imagePickerPreviewControllerWillStartLoading:self];
        } else if (self.showsDefaultLoading) {
            [self fw_showLoadingWithText:nil cancel:nil];
        }
        [FWImagePickerController requestImagesAssetArray:self.selectedImageAssetArray filterType:self.imagePickerController.filterType useOrigin:self.shouldUseOriginImage completion:^{
            if (self.delegate && [self.delegate respondsToSelector:@selector(imagePickerPreviewControllerDidFinishLoading:)]) {
                [self.delegate imagePickerPreviewControllerDidFinishLoading:self];
            } else if (self.showsDefaultLoading) {
                [self fw_hideLoading];
            }
            
            [self dismissViewControllerAnimated:YES completion:^(void) {
                if (self.delegate && [self.delegate respondsToSelector:@selector(imagePickerPreviewController:didFinishPickingImageWithImagesAssetArray:)]) {
                    [self.delegate imagePickerPreviewController:self didFinishPickingImageWithImagesAssetArray:self.selectedImageAssetArray.copy];
                } else {
                    if (self.imagePickerController.imagePickerControllerDelegate && [self.imagePickerController.imagePickerControllerDelegate respondsToSelector:@selector(imagePickerController:didFinishPickingImageWithImagesAssetArray:)]) {
                        [self.imagePickerController.imagePickerControllerDelegate imagePickerController:self.imagePickerController didFinishPickingImageWithImagesAssetArray:self.selectedImageAssetArray.copy];
                    } else if (self.imagePickerController.didFinishPicking) {
                        self.imagePickerController.didFinishPicking(self.selectedImageAssetArray.copy);
                    }
                }
                [self.imagePickerController.selectedImageAssetArray removeAllObjects];
            }];
        }];
    } else {
        [self dismissViewControllerAnimated:YES completion:^(void) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(imagePickerPreviewController:didFinishPickingImageWithImagesAssetArray:)]) {
                [self.delegate imagePickerPreviewController:self didFinishPickingImageWithImagesAssetArray:self.selectedImageAssetArray.copy];
            } else {
                if (self.imagePickerController.imagePickerControllerDelegate && [self.imagePickerController.imagePickerControllerDelegate respondsToSelector:@selector(imagePickerController:didFinishPickingImageWithImagesAssetArray:)]) {
                    [self.imagePickerController.imagePickerControllerDelegate imagePickerController:self.imagePickerController didFinishPickingImageWithImagesAssetArray:self.selectedImageAssetArray.copy];
                } else if (self.imagePickerController.didFinishPicking) {
                    self.imagePickerController.didFinishPicking(self.selectedImageAssetArray.copy);
                }
            }
            [self.imagePickerController.selectedImageAssetArray removeAllObjects];
        }];
    }
}

- (void)handleOriginImageCheckboxButtonClick:(UIButton *)button {
    if (button.selected) {
        button.selected = NO;
        [button setTitle:FWAppBundle.originalButton forState:UIControlStateNormal];
        [button sizeToFit];
        [self.bottomToolBarView setNeedsLayout];
    } else {
        button.selected = YES;
        [self updateOriginImageCheckboxButtonWithIndex:self.imagePreviewView.currentImageIndex];
        if (!self.checkboxButton.selected) {
            [self.checkboxButton sendActionsForControlEvents:UIControlEventTouchUpInside];
        }
    }
    self.shouldUseOriginImage = button.selected;
}

- (void)updateOriginImageCheckboxButtonWithIndex:(NSInteger)index {
    FWAsset *asset = self.imagesAssetArray[index];
    if (asset.assetType == FWAssetTypeAudio || asset.assetType == FWAssetTypeVideo) {
        self.originImageCheckboxButton.hidden = YES;
        if (self.showsEditButton) {
            self.editButton.hidden = YES;
        }
    } else {
        if (self.showsOriginImageCheckboxButton) {
            self.originImageCheckboxButton.hidden = NO;
        }
        if (self.showsEditButton) {
            self.editButton.hidden = NO;
        }
    }
}

- (void)beginEditImageAsset:(FWAsset *)imageAsset image:(UIImage *)image {
    FWImageCropController *cropController;
    if (self.delegate && [self.delegate respondsToSelector:@selector(imageCropControllerForPreviewController:image:)]) {
        cropController = [self.delegate imageCropControllerForPreviewController:self image:image];
    } else if (self.cropControllerBlock) {
        cropController = self.cropControllerBlock(image);
    } else {
        cropController = [[FWImageCropController alloc] initWithImage:image];
    }
    if (imageAsset.editedImage) {
        cropController.imageCropFrame = imageAsset.pickerCroppedRect;
        cropController.angle = imageAsset.pickerCroppedAngle;
    }
    __weak __typeof__(self) self_weak_ = self;
    cropController.onDidCropToRect = ^(UIImage * _Nonnull editedImage, CGRect cropRect, NSInteger angle) {
        __typeof__(self) self = self_weak_;
        imageAsset.editedImage = (editedImage != image) ? editedImage : nil;
        imageAsset.pickerCroppedRect = cropRect;
        imageAsset.pickerCroppedAngle = angle;
        [self.presentedViewController dismissViewControllerAnimated:NO completion:nil];
    };
    cropController.onDidFinishCancelled = ^(BOOL isFinished) {
        __typeof__(self) self = self_weak_;
        [self.presentedViewController dismissViewControllerAnimated:NO completion:nil];
    };
    [self presentViewController:cropController animated:NO completion:nil];
}

- (void)updateSendButtonLayout {
    CGFloat bottomToolBarContentHeight = self.bottomToolBarHeight - self.view.safeAreaInsets.bottom;
    [self.sendButton sizeToFit];
    self.sendButton.fw_origin = CGPointMake(CGRectGetWidth(self.bottomToolBarView.frame) - self.toolBarPaddingHorizontal - CGRectGetWidth(self.sendButton.frame) - self.view.safeAreaInsets.right, (bottomToolBarContentHeight - CGRectGetHeight(self.sendButton.frame)) / 2.0);
}

- (void)updateImageCountAndCollectionView:(BOOL)animated {
    if (!_singleCheckMode) {
        NSUInteger selectedCount = [self.selectedImageAssetArray count];
        if (selectedCount > 0) {
            self.sendButton.enabled = selectedCount >= self.minimumSelectImageCount;
            [self.sendButton setTitle:[NSString stringWithFormat:@"%@(%@)", FWAppBundle.doneButton, @(selectedCount)] forState:UIControlStateNormal];
        } else {
            self.sendButton.enabled = self.minimumSelectImageCount <= 1;
            [self.sendButton setTitle:FWAppBundle.doneButton forState:UIControlStateNormal];
        }
        if (self.delegate && [self.delegate respondsToSelector:@selector(imagePickerPreviewController:willChangeCheckedCount:)]) {
            [self.delegate imagePickerPreviewController:self willChangeCheckedCount:selectedCount];
        }
        [self updateSendButtonLayout];
    }
    
    if (!_singleCheckMode && self.showsEditCollectionView) {
        FWAsset *currentAsset = self.imagesAssetArray[self.imagePreviewView.currentImageIndex];
        _editCheckedIndex = [self.editImageAssetArray indexOfObject:currentAsset];
        self.editCollectionView.hidden = self.editImageAssetArray.count < 1;
        [self.editCollectionView reloadData];
        if (_editCheckedIndex != NSNotFound) {
            [self.editCollectionView performBatchUpdates:^{} completion:^(BOOL finished) {
                if ([self.editCollectionView numberOfItemsInSection:0] > self.editCheckedIndex) {
                    [self.editCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.editCheckedIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
                }
            }];
        }
    } else {
        self.editCollectionView.hidden = YES;
    }
}

- (void)updateCollectionViewCheckedIndex:(NSInteger)index {
    if (_editCheckedIndex != NSNotFound) {
        FWImagePickerPreviewCollectionCell *cell = (FWImagePickerPreviewCollectionCell *)[self.editCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:_editCheckedIndex inSection:0]];
        cell.checked = NO;
    }
    
    _editCheckedIndex = index;
    if (_editCheckedIndex != NSNotFound) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:_editCheckedIndex inSection:0];
        FWImagePickerPreviewCollectionCell *cell = (FWImagePickerPreviewCollectionCell *)[self.editCollectionView cellForItemAtIndexPath:indexPath];
        cell.checked = YES;
        if ([self.editCollectionView numberOfItemsInSection:0] > _editCheckedIndex) {
            [self.editCollectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
        }
    }
}

@end

#pragma mark - FWImagePickerCollectionCell

@interface FWImagePickerCollectionCell ()

@property(nonatomic, strong, readwrite) UIButton *checkboxButton;
@property(nonatomic, strong, readwrite) UILabel *checkedIndexLabel;

@end

@implementation FWImagePickerCollectionCell {
    BOOL _showsEditedIcon;
    BOOL _showsVideoIcon;
}

@synthesize maskView = _maskView;
@synthesize videoDurationLabel = _videoDurationLabel;
@synthesize iconImageView = _iconImageView;

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self setDefaultAppearance];
    });
}

+ (void)setDefaultAppearance {
    [FWImagePickerCollectionCell appearance].checkboxImage = FWAppBundle.pickerCheckImage;
    [FWImagePickerCollectionCell appearance].checkboxCheckedImage = FWAppBundle.pickerCheckedImage;
    [FWImagePickerCollectionCell appearance].checkboxButtonMargins = UIEdgeInsetsMake(6, 6, 6, 6);
    [FWImagePickerCollectionCell appearance].disabledMaskColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
    [FWImagePickerCollectionCell appearance].checkedMaskColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3];
    [FWImagePickerCollectionCell appearance].videoDurationLabelFont = [UIFont systemFontOfSize:12];
    [FWImagePickerCollectionCell appearance].videoDurationLabelTextColor = UIColor.whiteColor;
    [FWImagePickerCollectionCell appearance].videoDurationLabelMargins = UIEdgeInsetsMake(5, 5, 5, 7);
    [FWImagePickerCollectionCell appearance].checkedIndexLabelFont = [UIFont boldSystemFontOfSize:13];
    [FWImagePickerCollectionCell appearance].checkedIndexLabelTextColor = [UIColor whiteColor];
    [FWImagePickerCollectionCell appearance].checkedIndexLabelSize = CGSizeMake(20, 20);
    [FWImagePickerCollectionCell appearance].checkedIndexLabelMargins = UIEdgeInsetsMake(6, 6, 6, 6);
    [FWImagePickerCollectionCell appearance].checkedIndexLabelBackgroundColor = [UIColor colorWithRed:7/255.f green:193/255.f blue:96/255.f alpha:1.0];
    [FWImagePickerCollectionCell appearance].iconImageViewMargins = UIEdgeInsetsMake(5, 7, 5, 5);
    [FWImagePickerCollectionCell appearance].showsVideoDurationLabel = YES;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _checkedIndex = NSNotFound;
        [self didInitialize];
        [self fw_applyAppearance];
    }
    return self;
}

- (void)didInitialize {
    _contentImageView = [[UIImageView alloc] init];
    self.contentImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.contentImageView.clipsToBounds = YES;
    [self.contentView addSubview:self.contentImageView];
    
    _maskView = [[UIView alloc] init];
    [self.contentView addSubview:self.maskView];
    
    _iconImageView = [[UIImageView alloc] init];
    self.iconImageView.hidden = YES;
    [self.contentView addSubview:self.iconImageView];
    
    self.checkboxButton = [[UIButton alloc] init];
    self.checkboxButton.fw_touchInsets = UIEdgeInsetsMake(10, 10, 10, 10);
    self.checkboxButton.hidden = YES;
    [self.contentView addSubview:self.checkboxButton];
}

- (void)renderWithAsset:(FWAsset *)asset referenceSize:(CGSize)referenceSize {
    self.assetIdentifier = asset.identifier;
    if (asset.editedImage) {
        self.contentImageView.image = asset.editedImage;
    } else {
        [asset requestThumbnailImageWithSize:referenceSize completion:^(UIImage *result, NSDictionary *info, BOOL finished) {
            if ([self.assetIdentifier isEqualToString:asset.identifier]) {
                self.contentImageView.image = result;
            }
        }];
    }
    
    if (self.showsCheckedIndexLabel) {
        [self initCheckedIndexLabelIfNeeded];
    } else {
        self.checkedIndexLabel.hidden = YES;
    }
    
    if (asset.assetType == FWAssetTypeVideo && self.showsVideoDurationLabel) {
        [self initVideoDurationLabelIfNeeded];
        NSUInteger min = floor(asset.duration / 60);
        NSUInteger sec = floor(asset.duration - min * 60);
        self.videoDurationLabel.text = [NSString stringWithFormat:@"%02ld:%02ld", (long)min, (long)sec];
        self.videoDurationLabel.hidden = NO;
    } else {
        self.videoDurationLabel.hidden = YES;
    }
    
    _showsEditedIcon = asset.editedImage != nil;
    _showsVideoIcon = asset.assetType == FWAssetTypeVideo;
    [self updateIconImageView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.contentImageView.frame = self.contentView.bounds;
    self.maskView.frame = self.contentImageView.frame;
    
    if (_selectable) {
        // 经测试checkboxButton图片视图未完全占满UIButton，导致无法对齐，修复之
        CGSize checkboxButtonSize = self.checkboxButton.imageView.bounds.size;
        if (CGSizeEqualToSize(checkboxButtonSize, CGSizeZero)) {
            checkboxButtonSize = self.checkboxButton.bounds.size;
        }
        self.checkboxButton.frame = CGRectMake(CGRectGetWidth(self.contentView.bounds) - self.checkboxButtonMargins.right - checkboxButtonSize.width, self.checkboxButtonMargins.top, checkboxButtonSize.width, checkboxButtonSize.height);
    }
    
    if (self.checkedIndexLabel) {
        self.checkedIndexLabel.layer.cornerRadius = self.checkedIndexLabelSize.width / 2.0;
        self.checkedIndexLabel.frame = CGRectMake(CGRectGetWidth(self.contentView.bounds) - self.checkedIndexLabelMargins.right - self.checkedIndexLabelSize.width, self.checkedIndexLabelMargins.top, self.checkedIndexLabelSize.width, self.checkedIndexLabelSize.height);
    }
    
    if (self.videoDurationLabel && !self.videoDurationLabel.hidden) {
        [self.videoDurationLabel sizeToFit];
        self.videoDurationLabel.fw_origin = CGPointMake(CGRectGetWidth(self.contentView.bounds) - self.videoDurationLabelMargins.right - CGRectGetWidth(self.videoDurationLabel.frame), CGRectGetHeight(self.contentView.bounds) - self.videoDurationLabelMargins.bottom - CGRectGetHeight(self.videoDurationLabel.frame));
    }
    
    if (!self.iconImageView.hidden) {
        [self.iconImageView sizeToFit];
        self.iconImageView.fw_origin = CGPointMake(self.iconImageViewMargins.left, CGRectGetHeight(self.contentView.bounds) - self.iconImageViewMargins.bottom - CGRectGetHeight(self.iconImageView.frame));
    }
}

- (void)setCheckboxImage:(UIImage *)checkboxImage {
    if (![self.checkboxImage isEqual:checkboxImage]) {
        [self.checkboxButton setImage:checkboxImage forState:UIControlStateNormal];
        [self.checkboxButton sizeToFit];
        [self setNeedsLayout];
    }
    _checkboxImage = checkboxImage;
}

- (void)setCheckboxCheckedImage:(UIImage *)checkboxCheckedImage {
    if (![self.checkboxCheckedImage isEqual:checkboxCheckedImage]) {
        [self.checkboxButton setImage:checkboxCheckedImage forState:UIControlStateSelected];
        [self.checkboxButton setImage:checkboxCheckedImage forState:UIControlStateSelected|UIControlStateHighlighted];
        [self.checkboxButton sizeToFit];
        [self setNeedsLayout];
    }
    _checkboxCheckedImage = checkboxCheckedImage;
}

- (void)setVideoDurationLabelFont:(UIFont *)videoDurationLabelFont {
    if (![self.videoDurationLabelFont isEqual:videoDurationLabelFont]) {
        _videoDurationLabel.font = videoDurationLabelFont;
        _videoDurationLabel.text = @"测";
        [_videoDurationLabel sizeToFit];
        _videoDurationLabel.text = nil;
        [self setNeedsLayout];
    }
    _videoDurationLabelFont = videoDurationLabelFont;
}

- (void)setVideoDurationLabelTextColor:(UIColor *)videoDurationLabelTextColor {
    if (![self.videoDurationLabelTextColor isEqual:videoDurationLabelTextColor]) {
        _videoDurationLabel.textColor = videoDurationLabelTextColor;
    }
    _videoDurationLabelTextColor = videoDurationLabelTextColor;
}

- (void)setCheckedIndexLabelFont:(UIFont *)checkedIndexLabelFont {
    _checkedIndexLabelFont = checkedIndexLabelFont;
    self.checkedIndexLabel.font = checkedIndexLabelFont;
}

- (void)setCheckedIndexLabelTextColor:(UIColor *)checkedIndexLabelTextColor {
    _checkedIndexLabelTextColor = checkedIndexLabelTextColor;
    self.checkedIndexLabel.textColor = checkedIndexLabelTextColor;
}

- (void)setCheckedIndexLabelSize:(CGSize)checkedIndexLabelSize {
    _checkedIndexLabelSize = checkedIndexLabelSize;
    [self setNeedsLayout];
}

- (void)setCheckedIndexLabelMargins:(UIEdgeInsets)checkedIndexLabelMargins {
    _checkedIndexLabelMargins = checkedIndexLabelMargins;
    [self setNeedsLayout];
}

- (void)setCheckedIndexLabelBackgroundColor:(UIColor *)checkedIndexLabelBackgroundColor {
    _checkedIndexLabelBackgroundColor = checkedIndexLabelBackgroundColor;
    self.checkedIndexLabel.backgroundColor = checkedIndexLabelBackgroundColor;
}

- (void)setShowsCheckedIndexLabel:(BOOL)showsCheckedIndexLabel {
    _showsCheckedIndexLabel = showsCheckedIndexLabel;
    if (showsCheckedIndexLabel) {
        [self initCheckedIndexLabelIfNeeded];
    } else {
        self.checkedIndexLabel.hidden = YES;
    }
}

- (void)setShowsVideoDurationLabel:(BOOL)showsVideoDurationLabel {
    _showsVideoDurationLabel = showsVideoDurationLabel;
    self.videoDurationLabel.hidden = !showsVideoDurationLabel || !_showsVideoIcon;
}

- (void)setDisabled:(BOOL)disabled {
    _disabled = disabled;
    if (_selectable) {
        if (disabled) {
            [self.contentView bringSubviewToFront:self.maskView];
        } else {
            [self.contentView insertSubview:self.maskView aboveSubview:self.contentImageView];
        }
        [self updateMaskView];
    }
}

- (void)setChecked:(BOOL)checked {
    _checked = checked;
    if (_selectable) {
        self.checkboxButton.selected = checked;
        [self updateMaskView];
        [self updateCheckedIndexLabel];
    }
}

- (void)setCheckedIndex:(NSInteger)checkedIndex {
    _checkedIndex = checkedIndex;
    if (_selectable) {
        if (checkedIndex != NSNotFound && checkedIndex >= 0) {
            self.checkedIndexLabel.text = [NSString stringWithFormat:@"%@", @(checkedIndex + 1)];
        } else {
            self.checkedIndexLabel.text = nil;
        }
        [self updateCheckedIndexLabel];
    }
}

- (void)setSelectable:(BOOL)editing {
    _selectable = editing;
    if (self.downloadStatus == FWAssetDownloadStatusSucceed) {
        self.checkboxButton.hidden = !_selectable;
        [self updateCheckedIndexLabel];
    }
}

- (void)setDownloadStatus:(FWAssetDownloadStatus)downloadStatus {
    _downloadStatus = downloadStatus;
    if (_selectable) {
        self.checkboxButton.hidden = !_selectable;
        [self updateCheckedIndexLabel];
    }
}

- (void)setDisabledMaskColor:(UIColor *)disabledMaskColor {
    _disabledMaskColor = disabledMaskColor;
    if (_selectable) {
        [self updateMaskView];
    }
}

- (void)setCheckedMaskColor:(UIColor *)checkedMaskColor {
    _checkedMaskColor = checkedMaskColor;
    if (_selectable) {
        [self updateMaskView];
    }
}

- (void)setEditedIconImage:(UIImage *)editedIconImage {
    _editedIconImage = editedIconImage;
    [self updateIconImageView];
}

- (void)setVideoIconImage:(UIImage *)videoIconImage {
    _videoIconImage = videoIconImage;
    [self updateIconImageView];
}

- (void)updateCheckedIndexLabel {
    if (self.showsCheckedIndexLabel && self.selectable && self.checked
        && self.checkedIndex != NSNotFound && self.checkedIndex >= 0) {
        self.checkedIndexLabel.hidden = NO;
    } else {
        self.checkedIndexLabel.hidden = YES;
    }
}

- (void)updateMaskView {
    if (self.checked) {
        self.maskView.backgroundColor = self.checkedMaskColor;
    } else if (self.disabled) {
        self.maskView.backgroundColor = self.disabledMaskColor;
    } else {
        self.maskView.backgroundColor = nil;
    }
}

- (void)updateIconImageView {
    UIImage *iconImage = nil;
    if (_showsEditedIcon && self.editedIconImage) {
        iconImage = self.editedIconImage;
    } else if (_showsVideoIcon && self.videoIconImage) {
        iconImage = self.videoIconImage;
    }
    self.iconImageView.image = iconImage;
    self.iconImageView.hidden = !iconImage;
    [self setNeedsLayout];
}

- (void)initVideoDurationLabelIfNeeded {
    if (!self.videoDurationLabel) {
        _videoDurationLabel = [[UILabel alloc] init];
        _videoDurationLabel.font = self.videoDurationLabelFont;
        _videoDurationLabel.textColor = self.videoDurationLabelTextColor;
        [self.contentView addSubview:_videoDurationLabel];
        [self setNeedsLayout];
    }
}

- (void)initCheckedIndexLabelIfNeeded {
    if (!self.checkedIndexLabel) {
        _checkedIndexLabel = [[UILabel alloc] init];
        _checkedIndexLabel.textAlignment = NSTextAlignmentCenter;
        _checkedIndexLabel.font = self.checkedIndexLabelFont;
        _checkedIndexLabel.textColor = self.checkedIndexLabelTextColor;
        _checkedIndexLabel.backgroundColor = self.checkedIndexLabelBackgroundColor;
        _checkedIndexLabel.hidden = YES;
        _checkedIndexLabel.clipsToBounds = YES;
        [self.contentView addSubview:_checkedIndexLabel];
        [self setNeedsLayout];
    }
}

@end

#pragma mark - FWImagePickerController

static NSString * const kVideoCellIdentifier = @"video";
static NSString * const kImageOrUnknownCellIdentifier = @"imageorunknown";

#pragma mark - FWImagePickerController

@interface FWImagePickerController () <FWToolbarTitleViewDelegate>

@property(nonatomic, strong) FWImagePickerPreviewController *imagePickerPreviewController;
@property(nonatomic, weak) FWImageAlbumController *albumController;
@property(nonatomic, assign) BOOL isImagesAssetLoaded;
@property(nonatomic, assign) BOOL isImagesAssetLoading;
@property(nonatomic, assign) BOOL hasScrollToInitialPosition;

@end

@implementation FWImagePickerController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self didInitialize];
    }
    return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self didInitialize];
    }
    return self;
}

- (void)didInitialize {
    self.minimumImageWidth = 75;
    _toolBarBackgroundColor = [UIColor colorWithRed:27/255.f green:27/255.f blue:27/255.f alpha:1.f];
    _toolBarTintColor = UIColor.whiteColor;

    _allowsMultipleSelection = YES;
    _maximumSelectImageCount = 9;
    _minimumSelectImageCount = 0;
    _toolBarPaddingHorizontal = 16;
    _showsDefaultLoading = YES;
    
    FWToolbarTitleView *titleView = [[FWToolbarTitleView alloc] init];
    _titleView = titleView;
    titleView.delegate = self;
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.navigationItem.titleView = titleView;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:FWAppBundle.navCloseImage style:UIBarButtonItemStylePlain target:self action:@selector(handleCancelButtonClick:)];
}

- (void)setToolBarBackgroundColor:(UIColor *)toolBarBackgroundColor {
    _toolBarBackgroundColor = toolBarBackgroundColor;
    self.navigationController.navigationBar.fw_backgroundColor = toolBarBackgroundColor;
}

- (void)setToolBarTintColor:(UIColor *)toolBarTintColor {
    _toolBarTintColor = toolBarTintColor;
    self.navigationController.navigationBar.fw_foregroundColor = toolBarTintColor;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = self.collectionView.backgroundColor;
    [self.view addSubview:self.collectionView];
    if (self.allowsMultipleSelection) {
        [self.view addSubview:self.operationToolBarView];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.navigationController.navigationBarHidden != NO) {
        [self.navigationController setNavigationBarHidden:NO animated:animated];
    }
    self.navigationController.navigationBar.fw_isTranslucent = NO;
    self.navigationController.navigationBar.fw_shadowColor = nil;
    self.navigationController.navigationBar.fw_backgroundColor = self.toolBarBackgroundColor;
    self.navigationController.navigationBar.fw_foregroundColor = self.toolBarTintColor;
    
    // 由于被选中的图片 selectedImageAssetArray 可以由外部改变，因此检查一下图片被选中的情况，并刷新 collectionView
    if (self.allowsMultipleSelection) {
        [self updateImageCountAndCheckLimited:YES];
    } else {
        [self.collectionView reloadData];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    CGFloat operationToolBarViewHeight = 0;
    if (self.allowsMultipleSelection) {
        operationToolBarViewHeight = self.operationToolBarHeight;
        self.operationToolBarView.frame = CGRectMake(0, CGRectGetHeight(self.view.bounds) - operationToolBarViewHeight, CGRectGetWidth(self.view.bounds), operationToolBarViewHeight);
        self.previewButton.fw_origin = CGPointMake(self.toolBarPaddingHorizontal + self.view.safeAreaInsets.left, (CGRectGetHeight(self.operationToolBarView.bounds) - self.view.safeAreaInsets.bottom - CGRectGetHeight(self.previewButton.frame)) / 2.0);
        [self updateSendButtonLayout];
        operationToolBarViewHeight = CGRectGetHeight(self.operationToolBarView.frame);
    }
    
    if (!CGSizeEqualToSize(self.collectionView.frame.size, self.view.bounds.size)) {
        self.collectionView.frame = self.view.bounds;
    }
    UIEdgeInsets contentInset = UIEdgeInsetsMake(UIScreen.fw_topBarHeight, self.collectionView.safeAreaInsets.left, MAX(operationToolBarViewHeight, self.collectionView.safeAreaInsets.bottom), self.collectionView.safeAreaInsets.right);
    if (!UIEdgeInsetsEqualToEdgeInsets(self.collectionView.contentInset, contentInset)) {
        self.collectionView.contentInset = contentInset;
        // 放在这里是因为有时候会先走完 refreshWithAssetsGroup 里的 completion 再走到这里，此时前者不会导致 scollToInitialPosition 的滚动，所以在这里再调用一次保证一定会滚
        [self scrollToInitialPositionIfNeeded];
    }
}

- (void)dealloc {
    _collectionView.dataSource = nil;
    _collectionView.delegate = nil;
}

- (void)refreshWithAssetsGroup:(FWAssetGroup *)assetsGroup {
    _assetsGroup = assetsGroup;
    if (!self.imagesAssetArray) {
        _imagesAssetArray = [[NSMutableArray alloc] init];
        _selectedImageAssetArray = [[NSMutableArray alloc] init];
    } else {
        [self.imagesAssetArray removeAllObjects];
    }
    // 通过 FWAssetGroup 获取该相册所有的图片 FWAsset，并且储存到数组中
    FWAlbumSortType albumSortType = FWAlbumSortTypePositive;
    // 从 delegate 中获取相册内容的排序方式，如果没有实现这个 delegate，则使用 FWAlbumSortType 的默认值，即最新的内容排在最后面
    if (self.imagePickerControllerDelegate && [self.imagePickerControllerDelegate respondsToSelector:@selector(albumSortTypeForImagePickerController:)]) {
        albumSortType = [self.imagePickerControllerDelegate albumSortTypeForImagePickerController:self];
    }
    // 遍历相册内的资源较为耗时，交给子线程去处理，因此这里需要显示 Loading
    if (!self.isImagesAssetLoading) {
        self.isImagesAssetLoading = YES;
        if ([self.imagePickerControllerDelegate respondsToSelector:@selector(imagePickerControllerWillStartLoading:)]) {
            [self.imagePickerControllerDelegate imagePickerControllerWillStartLoading:self];
        } else if (self.showsDefaultLoading) {
            [self fw_showLoadingWithText:nil cancel:nil];
        }
    }
    if (!assetsGroup) {
        [self refreshCollectionView];
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [assetsGroup enumerateAssetsWithOptions:albumSortType usingBlock:^(FWAsset *resultAsset) {
            // 这里需要对 UI 进行操作，因此放回主线程处理
            dispatch_async(dispatch_get_main_queue(), ^{
                if (resultAsset) {
                    self.isImagesAssetLoaded = NO;
                    [self.imagesAssetArray addObject:resultAsset];
                } else {
                    [self refreshCollectionView];
                }
            });
        }];
    });
}

- (void)refreshWithFilterType:(FWImagePickerFilterType)filterType {
    _filterType = filterType;
    if ([self.imagePickerControllerDelegate respondsToSelector:@selector(imagePickerControllerWillStartLoading:)]) {
        [self.imagePickerControllerDelegate imagePickerControllerWillStartLoading:self];
    } else if (self.showsDefaultLoading) {
        [self fw_showLoadingWithText:nil cancel:nil];
    }
    self.isImagesAssetLoading = YES;
    [self initAlbumControllerIfNeeded];
}

- (void)refreshCollectionView {
    // result 为 nil，即遍历相片或视频完毕
    self.isImagesAssetLoaded = YES;
    if ([self.imagePickerControllerDelegate respondsToSelector:@selector(imagePickerControllerDidFinishLoading:)]) {
        [self.imagePickerControllerDelegate imagePickerControllerDidFinishLoading:self];
    } else if (self.showsDefaultLoading) {
        [self fw_hideLoading];
    }
    self.isImagesAssetLoading = NO;
    if (self.imagesAssetArray.count > 0) {
        self.collectionView.hidden = YES;
        [self.collectionView reloadData];
        self.hasScrollToInitialPosition = NO;
        [self.collectionView performBatchUpdates:^{
            [self scrollToInitialPositionIfNeeded];
        } completion:^(BOOL finished) {
            self.collectionView.hidden = NO;
        }];
    } else {
        [self.collectionView reloadData];
        if ([FWAssetManager authorizationStatus] == FWAssetAuthorizationStatusNotAuthorized) {
            if ([self.imagePickerControllerDelegate respondsToSelector:@selector(imagePickerControllerWillShowEmpty:)]) {
                [self.imagePickerControllerDelegate imagePickerControllerWillShowDenied:self];
            } else {
                NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
                NSString *appName = infoDictionary[@"CFBundleDisplayName"] ?: infoDictionary[(NSString *)kCFBundleNameKey];
                NSString *tipText = [NSString stringWithFormat:FWAppBundle.pickerDeniedTitle, appName];
                [self fw_showEmptyViewWithText:tipText];
            }
        } else {
            if ([self.imagePickerControllerDelegate respondsToSelector:@selector(imagePickerControllerWillShowEmpty:)]) {
                [self.imagePickerControllerDelegate imagePickerControllerWillShowEmpty:self];
            } else {
                [self fw_showEmptyViewWithText:FWAppBundle.pickerEmptyTitle];
            }
        }
    }
}

- (void)initPreviewViewControllerIfNeeded {
    if (self.imagePickerPreviewController) return;
    
    if ([self.imagePickerControllerDelegate respondsToSelector:@selector(imagePickerPreviewControllerForImagePickerController:)]) {
        self.imagePickerPreviewController = [self.imagePickerControllerDelegate imagePickerPreviewControllerForImagePickerController:self];
    } else if (self.previewControllerBlock) {
        self.imagePickerPreviewController = self.previewControllerBlock();
    }
    self.imagePickerPreviewController.imagePickerController = self;
    self.imagePickerPreviewController.maximumSelectImageCount = self.maximumSelectImageCount;
    self.imagePickerPreviewController.minimumSelectImageCount = self.minimumSelectImageCount;
}

- (CGSize)referenceImageSize {
    CGFloat collectionViewWidth = CGRectGetWidth(self.collectionView.bounds);
    CGFloat collectionViewContentSpacing = collectionViewWidth - (self.collectionView.contentInset.left + self.collectionView.contentInset.right) - (self.collectionViewLayout.sectionInset.left + self.collectionViewLayout.sectionInset.right);
    CGFloat referenceImageWidth = self.minimumImageWidth;
    NSInteger columnCount = self.imageColumnCount;
    if (columnCount < 1) {
        columnCount = floor(collectionViewContentSpacing / self.minimumImageWidth);
        BOOL isSpacingEnoughWhenDisplayInMinImageSize = (self.minimumImageWidth + self.collectionViewLayout.minimumInteritemSpacing) * columnCount - self.collectionViewLayout.minimumInteritemSpacing <= collectionViewContentSpacing;
        if (!isSpacingEnoughWhenDisplayInMinImageSize) {
            // 算上图片之间的间隙后发现其实还是放不下啦，所以得把列数减少，然后放大图片以撑满剩余空间
            columnCount -= 1;
        }
    }
    referenceImageWidth = floor((collectionViewContentSpacing - self.collectionViewLayout.minimumInteritemSpacing * (columnCount - 1)) / columnCount);
    return CGSizeMake(referenceImageWidth, referenceImageWidth);
}

- (void)setMinimumImageWidth:(CGFloat)minimumImageWidth {
    _minimumImageWidth = minimumImageWidth;
    [self referenceImageSize];
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (void)setImageColumnCount:(NSInteger)imageColumnCount {
    _imageColumnCount = imageColumnCount;
    [self referenceImageSize];
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (void)scrollToInitialPositionIfNeeded {
    if (self.isImagesAssetLoaded && !self.hasScrollToInitialPosition) {
        NSInteger itemsCount = [self.collectionView numberOfItemsInSection:0];
        if ([self.imagePickerControllerDelegate respondsToSelector:@selector(albumSortTypeForImagePickerController:)] && [self.imagePickerControllerDelegate albumSortTypeForImagePickerController:self] == FWAlbumSortTypeReverse) {
            if (itemsCount > 0) {
                [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
            }
        } else {
            if (itemsCount > 0) {
                [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:itemsCount - 1 inSection:0] atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
            }
        }
        self.hasScrollToInitialPosition = YES;
    }
}

- (void)showAlbumControllerAnimated:(BOOL)animated {
    [self initAlbumControllerIfNeeded];
    if (self.imagePickerControllerDelegate && [self.imagePickerControllerDelegate respondsToSelector:@selector(imagePickerController:willShowAlbumController:)]) {
        [self.imagePickerControllerDelegate imagePickerController:self willShowAlbumController:self.albumController];
    }
    
    self.albumController.view.frame = self.view.bounds;
    self.albumController.view.hidden = NO;
    self.albumController.view.alpha = 0;
    CGRect toFrame = CGRectMake(0, 0, self.view.bounds.size.width, self.albumController.tableViewHeight + UIScreen.fw_topBarHeight);
    CGRect fromFrame = toFrame;
    fromFrame.origin.y = -toFrame.size.height;
    self.albumController.tableView.frame = fromFrame;
    [UIView animateWithDuration:animated ? 0.25 : 0 animations:^{
        self.albumController.view.alpha = 1;
        self.albumController.tableView.frame = toFrame;
    }];
}

- (void)hideAlbumControllerAnimated:(BOOL)animated {
    if (!self.albumController) return;
    if (self.imagePickerControllerDelegate && [self.imagePickerControllerDelegate respondsToSelector:@selector(imagePickerController:willHideAlbumController:)]) {
        [self.imagePickerControllerDelegate imagePickerController:self willHideAlbumController:self.albumController];
    }
    
    [self.titleView setActive:NO animated:animated];
    CGRect toFrame = self.albumController.tableView.frame;
    toFrame.origin.y = -toFrame.size.height;
    [UIView animateWithDuration:animated ? 0.25 : 0 animations:^{
        self.albumController.view.alpha = 0;
        self.albumController.tableView.frame = toFrame;
    } completion:^(BOOL finished) {
        self.albumController.view.hidden = YES;
        self.albumController.view.alpha = 1;
    }];
}

- (void)initAlbumControllerIfNeeded {
    if (self.albumController) return;
    
    FWImageAlbumController *albumController;
    if (self.imagePickerControllerDelegate && [self.imagePickerControllerDelegate respondsToSelector:@selector(albumControllerForImagePickerController:)]) {
        albumController = [self.imagePickerControllerDelegate albumControllerForImagePickerController:self];
    } else if (self.albumControllerBlock) {
        albumController = self.albumControllerBlock();
    }
    if (!albumController) return;
    
    self.albumController = albumController;
    albumController.imagePickerController = self;
    albumController.contentType = [FWImagePickerController albumContentTypeWithFilterType:self.filterType];
    __weak __typeof__(self) self_weak_ = self;
    albumController.albumArrayLoaded = ^{
        __typeof__(self) self = self_weak_;
        if (self.albumController.albumsArray.count > 0) {
            FWAssetGroup *assetsGroup = self.albumController.albumsArray.firstObject;
            self.albumController.assetsGroup = assetsGroup;
            self.titleView.userInteractionEnabled = YES;
            if (self.titleAccessoryImage) self.titleView.accessoryImage = self.titleAccessoryImage;
            self.title = [assetsGroup name];
            [self refreshWithAssetsGroup:assetsGroup];
        } else {
            [self refreshWithAssetsGroup:nil];
        }
    };
    albumController.assetsGroupSelected = ^(FWAssetGroup * _Nonnull assetsGroup) {
        __typeof__(self) self = self_weak_;
        self.title = [assetsGroup name];
        [self refreshWithAssetsGroup:assetsGroup];
        [self hideAlbumControllerAnimated:YES];
    };
    
    [self addChildViewController:albumController];
    albumController.view.hidden = YES;
    [self.view addSubview:albumController.view];
    [albumController didMoveToParentViewController:self];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleAlbumButtonClick:)];
    [albumController.backgroundView addGestureRecognizer:tapGesture];
    if (!albumController.backgroundView.backgroundColor) {
        albumController.backgroundView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    }
    if (albumController.maximumTableViewHeight <= 0) {
        albumController.maximumTableViewHeight = albumController.albumTableViewCellHeight * ceil(UIScreen.fw_screenHeight / albumController.albumTableViewCellHeight / 2.0) + albumController.additionalTableViewHeight;
    }
}

#pragma mark - Getters & Setters

@synthesize collectionViewLayout = _collectionViewLayout;
- (UICollectionViewFlowLayout *)collectionViewLayout {
    if (!_collectionViewLayout) {
        _collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
        CGFloat inset = [UIScreen fw_pixelOne] * 2; // no why, just beautiful
        _collectionViewLayout.sectionInset = UIEdgeInsetsMake(inset, inset, inset, inset);
        _collectionViewLayout.minimumLineSpacing = _collectionViewLayout.sectionInset.bottom;
        _collectionViewLayout.minimumInteritemSpacing = _collectionViewLayout.sectionInset.left;
    }
    return _collectionViewLayout;
}

@synthesize collectionView = _collectionView;
- (UICollectionView *)collectionView {
    if (!_collectionView) {
        _collectionView = [[UICollectionView alloc] initWithFrame:self.isViewLoaded ? self.view.bounds : CGRectZero collectionViewLayout:self.collectionViewLayout];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.alwaysBounceVertical = YES;
        [_collectionView registerClass:[FWImagePickerCollectionCell class] forCellWithReuseIdentifier:kVideoCellIdentifier];
        [_collectionView registerClass:[FWImagePickerCollectionCell class] forCellWithReuseIdentifier:kImageOrUnknownCellIdentifier];
        _collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        _collectionView.backgroundColor = UIColor.blackColor;
    }
    return _collectionView;
}

@synthesize operationToolBarView = _operationToolBarView;
- (UIView *)operationToolBarView {
    if (!_operationToolBarView) {
        _operationToolBarView = [[UIView alloc] init];
        _operationToolBarView.backgroundColor = self.toolBarBackgroundColor;
        [_operationToolBarView addSubview:self.sendButton];
        [_operationToolBarView addSubview:self.previewButton];
    }
    return _operationToolBarView;
}

- (CGFloat)operationToolBarHeight {
    if (!self.allowsMultipleSelection) return 0;
    return _operationToolBarHeight > 0 ? _operationToolBarHeight : UIScreen.fw_toolBarHeight;
}

@synthesize sendButton = _sendButton;
- (UIButton *)sendButton {
    if (!_sendButton) {
        _sendButton = [[UIButton alloc] init];
        _sendButton.enabled = NO;
        _sendButton.titleLabel.font = [UIFont systemFontOfSize:16];
        _sendButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        [_sendButton setTitleColor:self.toolBarTintColor forState:UIControlStateNormal];
        [_sendButton setTitle:FWAppBundle.doneButton forState:UIControlStateNormal];
        _sendButton.fw_touchInsets = UIEdgeInsetsMake(12, 20, 12, 20);
        _sendButton.fw_disabledAlpha = 0.3;
        _sendButton.fw_highlightedAlpha = 0.5;
        [_sendButton sizeToFit];
        [_sendButton addTarget:self action:@selector(handleSendButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _sendButton;
}

@synthesize previewButton = _previewButton;
- (UIButton *)previewButton {
    if (!_previewButton) {
        _previewButton = [[UIButton alloc] init];
        _previewButton.enabled = NO;
        _previewButton.titleLabel.font = [UIFont systemFontOfSize:16];
        [_previewButton setTitleColor:self.toolBarTintColor forState:UIControlStateNormal];
        [_previewButton setTitle:FWAppBundle.previewButton forState:UIControlStateNormal];
        _previewButton.fw_touchInsets = UIEdgeInsetsMake(12, 20, 12, 20);
        _previewButton.fw_disabledAlpha = 0.3;
        _previewButton.fw_highlightedAlpha = 0.5;
        [_previewButton sizeToFit];
        [_previewButton addTarget:self action:@selector(handlePreviewButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _previewButton;
}

- (void)setAllowsMultipleSelection:(BOOL)allowsMultipleSelection {
    _allowsMultipleSelection = allowsMultipleSelection;
    if (self.isViewLoaded) {
        if (_allowsMultipleSelection) {
            [self.view addSubview:self.operationToolBarView];
        } else {
            [_operationToolBarView removeFromSuperview];
        }
    }
}

#pragma mark - <UICollectionViewDelegate, UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.imagesAssetArray count];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self referenceImageSize];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    FWAsset *imageAsset = [self.imagesAssetArray objectAtIndex:indexPath.item];
    
    NSString *identifier = nil;
    if (imageAsset.assetType == FWAssetTypeVideo) {
        identifier = kVideoCellIdentifier;
    } else {
        identifier = kImageOrUnknownCellIdentifier;
    }
    FWImagePickerCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    [cell renderWithAsset:imageAsset referenceSize:[self referenceImageSize]];
    
    cell.checkboxButton.tag = indexPath.item;
    [cell.checkboxButton addTarget:self action:@selector(handleCheckBoxButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    cell.selectable = self.allowsMultipleSelection;
    if (cell.selectable) {
        // 如果该图片的 FWAsset 被包含在已选择图片的数组中，则控制该图片被选中
        cell.checked = [self.selectedImageAssetArray containsObject:imageAsset];
        cell.checkedIndex = [self.selectedImageAssetArray indexOfObject:imageAsset];
        cell.disabled = !cell.checked && [self.selectedImageAssetArray count] >= self.maximumSelectImageCount;
    }
    
    if ([self.imagePickerControllerDelegate respondsToSelector:@selector(imagePickerController:customCell:atIndexPath:)]) {
        [self.imagePickerControllerDelegate imagePickerController:self customCell:cell atIndexPath:indexPath];
    } else if (self.customCellBlock) {
        self.customCellBlock(cell, indexPath);
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    FWAsset *imageAsset = self.imagesAssetArray[indexPath.item];
    if (![self.selectedImageAssetArray containsObject:imageAsset] &&
        [self.selectedImageAssetArray count] >= _maximumSelectImageCount) {
        if (self.imagePickerControllerDelegate && [self.imagePickerControllerDelegate respondsToSelector:@selector(imagePickerPreviewControllerWillShowExceed:)]) {
            [self.imagePickerControllerDelegate imagePickerControllerWillShowExceed:self];
        } else {
            [self fw_showAlertWithTitle:[NSString stringWithFormat:FWAppBundle.pickerExceedTitle, @(self.maximumSelectImageCount)] message:nil cancel:FWAppBundle.closeButton cancelBlock:nil];
        }
        return;
    }
    
    if ([self.imagePickerControllerDelegate respondsToSelector:@selector(imagePickerController:didSelectImageWithImagesAsset:afterImagePickerPreviewControllerUpdate:)]) {
        [self.imagePickerControllerDelegate imagePickerController:self didSelectImageWithImagesAsset:imageAsset afterImagePickerPreviewControllerUpdate:self.imagePickerPreviewController];
    }
    
    [self initPreviewViewControllerIfNeeded];
    if (!self.allowsMultipleSelection) {
        // 单选的情况下
        [self.imagePickerPreviewController updateImagePickerPreviewViewWithImagesAssetArray:self.previewScrollDisabled ? @[imageAsset].mutableCopy : self.imagesAssetArray
                                                                    selectedImageAssetArray:self.selectedImageAssetArray
                                                                          currentImageIndex:self.previewScrollDisabled ? 0 : indexPath.item
                                                                            singleCheckMode:YES
                                                                                previewMode:NO];
    } else {
        // cell 处于编辑状态，即图片允许多选
        [self.imagePickerPreviewController updateImagePickerPreviewViewWithImagesAssetArray:self.imagesAssetArray
                                                                    selectedImageAssetArray:self.selectedImageAssetArray
                                                                          currentImageIndex:indexPath.item
                                                                            singleCheckMode:NO
                                                                                previewMode:NO];
    }
    if (self.imagePickerPreviewController) {
        [self.navigationController pushViewController:self.imagePickerPreviewController animated:YES];
    }
}

#pragma mark - FWToolbarTitleViewDelegate

- (void)didTouchTitleView:(FWToolbarTitleView *)titleView isActive:(BOOL)isActive {
    if (isActive) {
        [self showAlbumControllerAnimated:YES];
    } else {
        [self hideAlbumControllerAnimated:YES];
    }
}

#pragma mark - 按钮点击回调

- (void)handleSendButtonClick:(UIButton *)sender {
    sender.userInteractionEnabled = NO;
    if (self.shouldRequestImage) {
        if ([self.imagePickerControllerDelegate respondsToSelector:@selector(imagePickerControllerWillStartLoading:)]) {
            [self.imagePickerControllerDelegate imagePickerControllerWillStartLoading:self];
        } else if (self.showsDefaultLoading) {
            [self fw_showLoadingWithText:nil cancel:nil];
        }
        [self initPreviewViewControllerIfNeeded];
        [FWImagePickerController requestImagesAssetArray:self.selectedImageAssetArray filterType:self.filterType useOrigin:self.imagePickerPreviewController.shouldUseOriginImage completion:^{
            if ([self.imagePickerControllerDelegate respondsToSelector:@selector(imagePickerControllerDidFinishLoading:)]) {
                [self.imagePickerControllerDelegate imagePickerControllerDidFinishLoading:self];
            } else if (self.showsDefaultLoading) {
                [self fw_hideLoading];
            }
            
            [self dismissViewControllerAnimated:YES completion:^{
                if (self.imagePickerControllerDelegate && [self.imagePickerControllerDelegate respondsToSelector:@selector(imagePickerController:didFinishPickingImageWithImagesAssetArray:)]) {
                    [self.imagePickerControllerDelegate imagePickerController:self didFinishPickingImageWithImagesAssetArray:self.selectedImageAssetArray.copy];
                } else if (self.didFinishPicking) {
                    self.didFinishPicking(self.selectedImageAssetArray.copy);
                }
                [self.selectedImageAssetArray removeAllObjects];
            }];
        }];
    } else {
        [self dismissViewControllerAnimated:YES completion:^() {
            if (self.imagePickerControllerDelegate && [self.imagePickerControllerDelegate respondsToSelector:@selector(imagePickerController:didFinishPickingImageWithImagesAssetArray:)]) {
                [self.imagePickerControllerDelegate imagePickerController:self didFinishPickingImageWithImagesAssetArray:self.selectedImageAssetArray.copy];
            } else if (self.didFinishPicking) {
                self.didFinishPicking(self.selectedImageAssetArray.copy);
            }
            [self.selectedImageAssetArray removeAllObjects];
        }];
    }
}

- (void)handlePreviewButtonClick:(id)sender {
    [self initPreviewViewControllerIfNeeded];
    // 手工更新图片预览界面
    [self.imagePickerPreviewController updateImagePickerPreviewViewWithImagesAssetArray:[self.selectedImageAssetArray mutableCopy]
                                                                selectedImageAssetArray:self.selectedImageAssetArray
                                                                      currentImageIndex:0
                                                                        singleCheckMode:NO
                                                                            previewMode:YES];
    if (self.imagePickerPreviewController) {
        [self.navigationController pushViewController:self.imagePickerPreviewController animated:YES];
    }
}

- (void)handleCancelButtonClick:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^() {
        if (self.imagePickerControllerDelegate && [self.imagePickerControllerDelegate respondsToSelector:@selector(imagePickerControllerDidCancel:)]) {
            [self.imagePickerControllerDelegate imagePickerControllerDidCancel:self];
        } else if (self.didCancelPicking) {
            self.didCancelPicking();
        }
        [self.selectedImageAssetArray removeAllObjects];
    }];
}

- (void)handleCheckBoxButtonClick:(UIButton *)checkboxButton {
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:checkboxButton.tag inSection:0];
    if ([self.imagePickerControllerDelegate respondsToSelector:@selector(imagePickerController:shouldCheckImageAtIndex:)] && ![self.imagePickerControllerDelegate imagePickerController:self shouldCheckImageAtIndex:indexPath.item]) {
        return;
    }
    
    FWImagePickerCollectionCell *cell = (FWImagePickerCollectionCell *)[_collectionView cellForItemAtIndexPath:indexPath];
    FWAsset *imageAsset = [self.imagesAssetArray objectAtIndex:indexPath.item];
    if (cell.checked) {
        // 移除选中状态
        if ([self.imagePickerControllerDelegate respondsToSelector:@selector(imagePickerController:willUncheckImageAtIndex:)]) {
            [self.imagePickerControllerDelegate imagePickerController:self willUncheckImageAtIndex:indexPath.item];
        }
        
        [self.selectedImageAssetArray removeObject:imageAsset];
        // 根据选择图片数控制预览和发送按钮的 enable，以及修改已选中的图片数
        if ([self.selectedImageAssetArray count] >= _maximumSelectImageCount - 1) {
            [self updateImageCountAndCheckLimited:YES];
        } else {
            cell.checked = NO;
            cell.checkedIndex = NSNotFound;
            cell.disabled = !cell.checked && [self.selectedImageAssetArray count] >= self.maximumSelectImageCount;
            [self updateImageCountAndCheckLimited:NO];
        }
        
        if ([self.imagePickerControllerDelegate respondsToSelector:@selector(imagePickerController:didUncheckImageAtIndex:)]) {
            [self.imagePickerControllerDelegate imagePickerController:self didUncheckImageAtIndex:indexPath.item];
        }
    } else {
        // 选中该资源
        if ([self.selectedImageAssetArray count] >= _maximumSelectImageCount) {
            if (self.imagePickerControllerDelegate && [self.imagePickerControllerDelegate respondsToSelector:@selector(imagePickerPreviewControllerWillShowExceed:)]) {
                [self.imagePickerControllerDelegate imagePickerControllerWillShowExceed:self];
            } else {
                [self fw_showAlertWithTitle:[NSString stringWithFormat:FWAppBundle.pickerExceedTitle, @(self.maximumSelectImageCount)] message:nil cancel:FWAppBundle.closeButton cancelBlock:nil];
            }
            return;
        }
        
        if ([self.imagePickerControllerDelegate respondsToSelector:@selector(imagePickerController:willCheckImageAtIndex:)]) {
            [self.imagePickerControllerDelegate imagePickerController:self willCheckImageAtIndex:indexPath.item];
        }
        
        [self.selectedImageAssetArray addObject:imageAsset];
        // 根据选择图片数控制预览和发送按钮的 enable，以及修改已选中的图片数
        if ([self.selectedImageAssetArray count] >= _maximumSelectImageCount) {
            [self updateImageCountAndCheckLimited:YES];
        } else {
            cell.checked = YES;
            cell.checkedIndex = [self.selectedImageAssetArray indexOfObject:imageAsset];
            cell.disabled = !cell.checked && [self.selectedImageAssetArray count] >= self.maximumSelectImageCount;
            [self updateImageCountAndCheckLimited:NO];
        }
        
        if ([self.imagePickerControllerDelegate respondsToSelector:@selector(imagePickerController:didCheckImageAtIndex:)]) {
            [self.imagePickerControllerDelegate imagePickerController:self didCheckImageAtIndex:indexPath.item];
        }
        
        // 发出请求获取大图，如果图片在 iCloud，则会发出网络请求下载图片。这里同时保存请求 id，供取消请求使用
        [self requestImageWithIndexPath:indexPath];
    }
}

- (void)requestImageWithIndexPath:(NSIndexPath *)indexPath {
    // 发出请求获取大图，如果图片在 iCloud，则会发出网络请求下载图片。这里同时保存请求 id，供取消请求使用
    FWAsset *imageAsset = [self.imagesAssetArray objectAtIndex:indexPath.item];
    FWImagePickerCollectionCell *cell = (FWImagePickerCollectionCell *)[_collectionView cellForItemAtIndexPath:indexPath];
    imageAsset.requestID = [imageAsset requestOriginImageWithCompletion:^(UIImage *result, NSDictionary *info, BOOL finished) {
        if (finished && result) {
            // 资源资源已经在本地或下载成功
            [imageAsset updateDownloadStatusWithDownloadResult:YES];
            cell.downloadStatus = FWAssetDownloadStatusSucceed;
            
        } else if (finished) {
            // 下载错误
            [imageAsset updateDownloadStatusWithDownloadResult:NO];
            cell.downloadStatus = FWAssetDownloadStatusFailed;
        }
        
    } withProgressHandler:^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
        imageAsset.downloadProgress = progress;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSArray *visibleItemIndexPaths = self.collectionView.indexPathsForVisibleItems;
            BOOL itemVisible = NO;
            for (NSIndexPath *visibleIndexPath in visibleItemIndexPaths) {
                if ([indexPath isEqual:visibleIndexPath]) {
                    itemVisible = YES;
                    break;
                }
            }
            
            if (itemVisible) {
                if (cell.downloadStatus != FWAssetDownloadStatusDownloading) {
                    cell.downloadStatus = FWAssetDownloadStatusDownloading;
                    // 预先设置预览界面的下载状态
                    self.imagePickerPreviewController.downloadStatus = FWAssetDownloadStatusDownloading;
                }
                if (error) {
                    cell.downloadStatus = FWAssetDownloadStatusFailed;
                }
            }
        });
    }];
}

- (void)handleAlbumButtonClick:(id)sender {
    [self hideAlbumControllerAnimated:YES];
}

- (void)updateSendButtonLayout {
    if (!self.allowsMultipleSelection) return;
    [self.sendButton sizeToFit];
    self.sendButton.frame = CGRectMake(CGRectGetWidth(self.operationToolBarView.bounds) - self.toolBarPaddingHorizontal - CGRectGetWidth(self.sendButton.frame) - self.view.safeAreaInsets.right, (CGRectGetHeight(self.operationToolBarView.frame) - self.view.safeAreaInsets.bottom - CGRectGetHeight(self.sendButton.frame)) / 2.0, CGRectGetWidth(self.sendButton.frame), CGRectGetHeight(self.sendButton.frame));
}

- (void)updateImageCountAndCheckLimited:(BOOL)reloadData {
    if (self.allowsMultipleSelection) {
        NSInteger selectedCount = [self.selectedImageAssetArray count];
        if (selectedCount > 0) {
            self.previewButton.enabled = selectedCount >= self.minimumSelectImageCount;
            self.sendButton.enabled = selectedCount >= self.minimumSelectImageCount;
            [self.sendButton setTitle:[NSString stringWithFormat:@"%@(%@)", FWAppBundle.doneButton, @(selectedCount)] forState:UIControlStateNormal];
        } else {
            self.previewButton.enabled = NO;
            self.sendButton.enabled = NO;
            [self.sendButton setTitle:FWAppBundle.doneButton forState:UIControlStateNormal];
        }
        if (self.imagePickerControllerDelegate && [self.imagePickerControllerDelegate respondsToSelector:@selector(imagePickerController:willChangeCheckedCount:)]) {
            [self.imagePickerControllerDelegate imagePickerController:self willChangeCheckedCount:selectedCount];
        }
        [self updateSendButtonLayout];
    }
    
    if (reloadData) {
        [self.collectionView reloadData];
    } else {
        [self.selectedImageAssetArray enumerateObjectsUsingBlock:^(FWAsset *imageAsset, NSUInteger idx, BOOL *stop) {
            NSInteger imageIndex = [self.imagesAssetArray indexOfObject:imageAsset];
            if (imageIndex == NSNotFound) return;
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:imageIndex inSection:0];
            
            FWImagePickerCollectionCell *cell = (FWImagePickerCollectionCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
            if (cell.selectable) {
                cell.checked = YES;
                cell.checkedIndex = [self.selectedImageAssetArray indexOfObject:imageAsset];
                cell.disabled = !cell.checked && [self.selectedImageAssetArray count] >= self.maximumSelectImageCount;
            }
        }];
    }
}

#pragma mark - Request Image

+ (FWAlbumContentType)albumContentTypeWithFilterType:(FWImagePickerFilterType)filterType {
    FWAlbumContentType contentType = filterType < 1 ? FWAlbumContentTypeAll : FWAlbumContentTypeOnlyPhoto;
    if (filterType & FWImagePickerFilterTypeVideo) {
        if (filterType & FWImagePickerFilterTypeImage ||
            filterType & FWImagePickerFilterTypeLivePhoto) {
            contentType = FWAlbumContentTypeAll;
        } else {
            contentType = FWAlbumContentTypeOnlyVideo;
        }
    }
    return contentType;
}

+ (void)requestImagesAssetArray:(NSArray<FWAsset *> *)imagesAssetArray
                     filterType:(FWImagePickerFilterType)filterType
                      useOrigin:(BOOL)useOrigin
                     completion:(void (^)(void))completion {
    if (imagesAssetArray.count < 1) {
        if (completion) completion();
        return;
    }
    
    NSInteger totalCount = imagesAssetArray.count;
    __block NSInteger finishCount = 0;
    void (^completionHandler)(FWAsset *asset, id _Nullable object, NSDictionary * _Nullable info) = ^(FWAsset *asset, id _Nullable object, NSDictionary * _Nullable info){
        asset.requestObject = object;
        asset.requestInfo = info;
        
        finishCount += 1;
        if (finishCount == totalCount) {
            if (completion) completion();
        }
    };
    
    BOOL checkLivePhoto = (filterType & FWImagePickerFilterTypeLivePhoto) || filterType < 1;
    BOOL checkVideo = (filterType & FWImagePickerFilterTypeVideo) || filterType < 1;
    [imagesAssetArray enumerateObjectsUsingBlock:^(FWAsset *asset, NSUInteger index, BOOL *stop) {
        if (checkVideo && asset.assetType == FWAssetTypeVideo) {
            NSString *filePath = [PHPhotoLibrary fw_pickerControllerVideoCachePath];
            [[NSFileManager defaultManager] createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
            filePath = [[filePath stringByAppendingPathComponent:[self md5EncodeString:[NSUUID UUID].UUIDString]] stringByAppendingPathExtension:@"mp4"];
            NSURL *fileURL = [NSURL fileURLWithPath:filePath];
            [asset requestVideoURLWithOutputURL:fileURL exportPreset:useOrigin ? AVAssetExportPresetHighestQuality : AVAssetExportPresetMediumQuality completion:^(NSURL * _Nullable videoURL, NSDictionary<NSString *,id> * _Nullable info) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(asset, videoURL, info);
                });
            } withProgressHandler:nil];
        } else if (asset.assetType == FWAssetTypeImage) {
            if (asset.editedImage) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(asset, asset.editedImage, nil);
                });
                return;
            }
            
            if (checkLivePhoto && asset.assetSubType == FWAssetSubTypeLivePhoto) {
                [asset requestLivePhotoWithCompletion:^void(PHLivePhoto *livePhoto, NSDictionary *info, BOOL finished) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (finished) completionHandler(asset, livePhoto, info);
                    });
                } withProgressHandler:nil];
            } else if (asset.assetSubType == FWAssetSubTypeGIF) {
                [asset requestImageDataWithCompletion:^(NSData *imageData, NSDictionary<NSString *,id> *info, BOOL isGIF, BOOL isHEIC) {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        UIImage *resultImage = imageData ? [UIImage fw_imageWithData:imageData] : nil;
                        dispatch_async(dispatch_get_main_queue(), ^{
                            completionHandler(asset, resultImage, info);
                        });
                    });
                }];
            } else {
                if (useOrigin) {
                    [asset requestOriginImageWithCompletion:^(UIImage *result, NSDictionary<NSString *,id> *info, BOOL finished) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (finished) completionHandler(asset, result, info);
                        });
                    } withProgressHandler:nil];
                } else {
                    [asset requestPreviewImageWithCompletion:^(UIImage *result, NSDictionary<NSString *,id> *info, BOOL finished) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (finished) completionHandler(asset, result, info);
                        });
                    } withProgressHandler:nil];
                }
            }
        }
    }];
}

+ (NSString *)md5EncodeString:(NSString *)string {
    const char *cStr = [string UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), digest);
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++){
        [output appendFormat:@"%02x", digest[i]];
    }
    return [NSString stringWithString:output];
}

@end
