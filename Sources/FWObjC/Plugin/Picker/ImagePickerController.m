//
//  ImagePickerController.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "ImagePickerController.h"
#import "ImageCropController.h"
#import "ToolbarView.h"
#import <objc/runtime.h>
#import <CommonCrypto/CommonDigest.h>
#import <FWFramework/FWFramework-Swift.h>

#pragma mark - __FWImageAlbumController

@interface __FWImageAlbumController ()

@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong) NSMutableArray<__FWAssetGroup *> *albumsArray;
@property(nonatomic, strong) __FWAssetGroup *assetsGroup;
@property(nonatomic, weak) __FWImagePickerController *imagePickerController;
@property(nonatomic, copy) void (^assetsGroupSelected)(__FWAssetGroup *assetsGroup);
@property(nonatomic, copy) void (^albumArrayLoaded)(void);

@end

@implementation __FWImageAlbumController

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
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[NSObject __fw_bundleImage:@"fw.navClose"] style:UIBarButtonItemStylePlain target:self action:@selector(handleCancelButtonClick:)];
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
    self.navigationController.navigationBar.__fw_backgroundColor = toolBarBackgroundColor;
}

- (void)setToolBarTintColor:(UIColor *)toolBarTintColor {
    _toolBarTintColor = toolBarTintColor;
    self.navigationController.navigationBar.__fw_foregroundColor = toolBarTintColor;
}

- (void)setAssetsGroup:(__FWAssetGroup *)assetsGroup {
    if (self.assetsGroup) {
        __FWImageAlbumTableCell *cell = (__FWImageAlbumTableCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.albumsArray indexOfObject:self.assetsGroup] inSection:0]];
        cell.checked = NO;
    }
    _assetsGroup = assetsGroup;
    __FWImageAlbumTableCell *cell = (__FWImageAlbumTableCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.albumsArray indexOfObject:assetsGroup] inSection:0]];
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
    self.navigationController.navigationBar.__fw_backImage = [NSObject __fw_bundleImage:@"fw.navBack"];
    if (!self.title) self.title = [NSObject __fw_bundleString:@"fw.pickerAlbum"];
    [self.view addSubview:self.backgroundView];
    [self.view addSubview:self.tableView];
    
    __FWAssetAuthorizationStatus authorizationStatus = [__FWAssetManager authorizationStatus];
    if (authorizationStatus == __FWAssetAuthorizationStatusNotDetermined) {
        [__FWAssetManager requestAuthorizationWithCompletion:^(__FWAssetAuthorizationStatus status) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (status == __FWAssetAuthorizationStatusNotAuthorized) {
                    [self showDeniedView];
                } else {
                    [self loadAlbumArray];
                }
            });
        }];
    } else if (authorizationStatus == __FWAssetAuthorizationStatusNotAuthorized) {
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
    self.navigationController.navigationBar.__fw_isTranslucent = NO;
    self.navigationController.navigationBar.__fw_shadowColor = nil;
    self.navigationController.navigationBar.__fw_backgroundColor = self.toolBarBackgroundColor;
    self.navigationController.navigationBar.__fw_foregroundColor = self.toolBarTintColor;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    self.backgroundView.frame = self.view.bounds;
    UIEdgeInsets contentInset = UIEdgeInsetsMake(UIScreen.__fw_topBarHeight, self.tableView.safeAreaInsets.left, self.tableView.safeAreaInsets.bottom, self.tableView.safeAreaInsets.right);
    if (!UIEdgeInsetsEqualToEdgeInsets(self.tableView.contentInset, contentInset)) {
        self.tableView.contentInset = contentInset;
    }
}

- (void)loadAlbumArray {
    if ([self.albumControllerDelegate respondsToSelector:@selector(albumControllerWillStartLoading:)]) {
        [self.albumControllerDelegate albumControllerWillStartLoading:self];
    } else if (self.showsDefaultLoading) {
        [self __fw_showLoadingWithText:nil cancelBlock:nil];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[__FWAssetManager shared] enumerateAllAlbumsWithAlbumContentType:(AlbumContentType)self.contentType showEmptyAlbum:NO showSmartAlbum:YES using:^(__FWAssetGroup *resultAssetsGroup) {
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
    __block __FWAssetGroup *hiddenGroup = nil;
    [self.albumsArray enumerateObjectsUsingBlock:^(__FWAssetGroup * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
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
        [self __fw_hideLoadingWithDelayed:NO];
    }
    
    if (self.maximumTableViewHeight > 0) {
        CGRect tableFrame = self.tableView.frame;
        tableFrame.size.height = self.tableViewHeight + UIScreen.__fw_topBarHeight;
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
            [self __fw_showEmptyViewWithText:[NSObject __fw_bundleString:@"fw.pickerEmpty"] detail:nil image:nil action:nil block:nil];
        }
    }
    
    if (self.albumArrayLoaded) {
        self.albumArrayLoaded();
    }
}

- (void)showDeniedView {
    if (self.maximumTableViewHeight > 0) {
        CGRect tableFrame = self.tableView.frame;
        tableFrame.size.height = self.tableViewHeight + UIScreen.__fw_topBarHeight;
        self.tableView.frame = tableFrame;
    }
    
    if ([self.albumControllerDelegate respondsToSelector:@selector(albumControllerWillShowDenied:)]) {
        [self.albumControllerDelegate albumControllerWillShowDenied:self];
    } else {
        NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
        NSString *appName = infoDictionary[@"CFBundleDisplayName"] ?: infoDictionary[(NSString *)kCFBundleNameKey];
        NSString *tipText = [NSString stringWithFormat:[NSObject __fw_bundleString:@"fw.pickerDenied"], appName];
        [self __fw_showEmptyViewWithText:tipText detail:nil image:nil action:nil block:nil];
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

- (void)pickAlbumsGroup:(__FWAssetGroup *)assetsGroup animated:(BOOL)animated {
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
    
    __FWImagePickerController *imagePickerController;
    if ([self.albumControllerDelegate respondsToSelector:@selector(imagePickerControllerForAlbumController:)]) {
        imagePickerController = [self.albumControllerDelegate imagePickerControllerForAlbumController:self];
    } else if (self.pickerControllerBlock) {
        imagePickerController = self.pickerControllerBlock();
    }
    if (imagePickerController) {
        // 清空imagePickerController导航栏左侧按钮并添加默认按钮
        if (imagePickerController.navigationItem.leftBarButtonItem) {
            imagePickerController.navigationItem.leftBarButtonItem = nil;
            imagePickerController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[NSObject __fw_bundleString:@"fw.cancel"] style:UIBarButtonItemStylePlain target:imagePickerController action:@selector(handleCancelButtonClick:)];
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
    __FWImageAlbumTableCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifer];
    if (!cell) {
        cell = [[__FWImageAlbumTableCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kCellIdentifer];
    }
    __FWAssetGroup *assetsGroup = self.albumsArray[indexPath.row];
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

#pragma mark - __FWImagePickerPreviewController

@interface __FWImagePickerPreviewController ()

@property(nonatomic, weak) __FWImagePickerController *imagePickerController;
@property(nonatomic, assign) NSInteger editCheckedIndex;
@property(nonatomic, assign) BOOL shouldResetPreviewView;

@end

@implementation __FWImagePickerPreviewController {
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
        
        _checkboxImage = [NSObject __fw_bundleImage:@"fw.pickerCheck"];
        _checkboxCheckedImage = [NSObject __fw_bundleImage:@"fw.pickerChecked"];
        _originImageCheckboxImage = [[NSObject __fw_bundleImage:@"fw.pickerCheck"] __fw_imageWithScaleSize:CGSizeMake(18, 18)];
        _originImageCheckboxCheckedImage = [[NSObject __fw_bundleImage:@"fw.pickerChecked"] __fw_imageWithScaleSize:CGSizeMake(18, 18)];
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
        __FWAsset *imageAsset = self.imagesAssetArray[self.imagePreviewView.currentImageIndex];
        self.checkboxButton.selected = [self.selectedImageAssetArray containsObject:imageAsset];
    }
    [self updateOriginImageCheckboxButtonWithIndex:self.imagePreviewView.currentImageIndex];
    [self updateImageCountAndCollectionView:NO];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.topToolBarView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), UIScreen.__fw_topBarHeight);
    CGFloat topToolbarPaddingTop = self.view.safeAreaInsets.top;
    CGFloat topToolbarContentHeight = CGRectGetHeight(self.topToolBarView.bounds) - topToolbarPaddingTop;
    CGRect backButtonFrame = self.backButton.frame;
    backButtonFrame.origin = CGPointMake(self.toolBarPaddingHorizontal + self.view.safeAreaInsets.left, topToolbarPaddingTop + (topToolbarContentHeight - CGRectGetHeight(self.backButton.frame)) / 2.0);
    self.backButton.frame = backButtonFrame;
    if (!self.checkboxButton.hidden) {
        CGRect checkboxButtonFrame = self.checkboxButton.frame;
        checkboxButtonFrame.origin = CGPointMake(CGRectGetWidth(self.topToolBarView.frame) - self.toolBarPaddingHorizontal - self.view.safeAreaInsets.right - CGRectGetWidth(self.checkboxButton.frame), topToolbarPaddingTop + (topToolbarContentHeight - CGRectGetHeight(self.checkboxButton.frame)) / 2.0);
        self.checkboxButton.frame = checkboxButtonFrame;
    }
    
    CGFloat bottomToolBarHeight = self.bottomToolBarHeight;
    CGFloat bottomToolBarContentHeight = bottomToolBarHeight - self.view.safeAreaInsets.bottom;
    self.bottomToolBarView.frame = CGRectMake(0, CGRectGetHeight(self.view.bounds) - bottomToolBarHeight, CGRectGetWidth(self.view.bounds), bottomToolBarHeight);
    [self updateSendButtonLayout];
    
    CGRect editButtonFrame = self.editButton.frame;
    editButtonFrame.origin = CGPointMake(self.toolBarPaddingHorizontal + self.view.safeAreaInsets.left, (bottomToolBarContentHeight - CGRectGetHeight(self.editButton.frame)) / 2.0);
    self.editButton.frame = editButtonFrame;
    if (self.showsEditButton) {
        CGRect originImageCheckboxButtonFrame = self.originImageCheckboxButton.frame;
        originImageCheckboxButtonFrame.origin = CGPointMake((CGRectGetWidth(self.bottomToolBarView.frame) - CGRectGetWidth(self.originImageCheckboxButton.frame)) / 2.0, (bottomToolBarContentHeight - CGRectGetHeight(self.originImageCheckboxButton.frame)) / 2.0);
        self.originImageCheckboxButton.frame = originImageCheckboxButtonFrame;
    } else {
        CGRect originImageCheckboxButtonFrame = self.originImageCheckboxButton.frame;
        originImageCheckboxButtonFrame.origin = CGPointMake(self.toolBarPaddingHorizontal + self.view.safeAreaInsets.left, (bottomToolBarContentHeight - CGRectGetHeight(self.originImageCheckboxButton.frame)) / 2.0);
        self.originImageCheckboxButton.frame = originImageCheckboxButtonFrame;
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
        [_editCollectionView registerClass:[__FWImagePickerPreviewCollectionCell class] forCellWithReuseIdentifier:@"cell"];
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
        [_backButton setImage:[NSObject __fw_bundleImage:@"fw.navBack"] forState:UIControlStateNormal];
        [_backButton sizeToFit];
        [_backButton addTarget:self action:@selector(handleCancelButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        _backButton.__fw_touchInsets = UIEdgeInsetsMake(30, 20, 50, 80);
        _backButton.__fw_disabledAlpha = UIButton.__fw_disabledAlpha;
        _backButton.__fw_highlightedAlpha = UIButton.__fw_highlightedAlpha;
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
        _checkboxButton.__fw_touchInsets = UIEdgeInsetsMake(10, 10, 10, 10);
        _checkboxButton.__fw_disabledAlpha = UIButton.__fw_disabledAlpha;
        _checkboxButton.__fw_highlightedAlpha = UIButton.__fw_highlightedAlpha;
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
    return _bottomToolBarHeight > 0 ? _bottomToolBarHeight : UIScreen.__fw_toolBarHeight;
}

@synthesize editButton = _editButton;
- (UIButton *)editButton {
    if (!_editButton) {
        _editButton = [[UIButton alloc] init];
        _editButton.hidden = !self.showsEditButton;
        _editButton.__fw_touchInsets = UIEdgeInsetsMake(10, 10, 10, 10);
        [_editButton setTitle:[NSObject __fw_bundleString:@"fw.edit"] forState:UIControlStateNormal];
        _editButton.titleLabel.font = [UIFont systemFontOfSize:16];
        [_editButton sizeToFit];
        _editButton.__fw_disabledAlpha = UIButton.__fw_disabledAlpha;
        _editButton.__fw_highlightedAlpha = UIButton.__fw_highlightedAlpha;
        [_editButton addTarget:self action:@selector(handleEditButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _editButton;
}

@synthesize sendButton = _sendButton;
- (UIButton *)sendButton {
    if (!_sendButton) {
        _sendButton = [[UIButton alloc] init];
        _sendButton.__fw_touchInsets = UIEdgeInsetsMake(10, 10, 10, 10);
        [_sendButton setTitle:[NSObject __fw_bundleString:@"fw.done"] forState:UIControlStateNormal];
        _sendButton.titleLabel.font = [UIFont systemFontOfSize:16];
        [_sendButton sizeToFit];
        _sendButton.__fw_disabledAlpha = UIButton.__fw_disabledAlpha;
        _sendButton.__fw_highlightedAlpha = UIButton.__fw_highlightedAlpha;
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
        [_originImageCheckboxButton setTitle:[NSObject __fw_bundleString:@"fw.original"] forState:UIControlStateNormal];
        [_originImageCheckboxButton setImageEdgeInsets:UIEdgeInsetsMake(0, -5.0f, 0, 5.0f)];
        [_originImageCheckboxButton setContentEdgeInsets:UIEdgeInsetsMake(0, 5.0f, 0, 0)];
        [_originImageCheckboxButton sizeToFit];
        _originImageCheckboxButton.__fw_touchInsets = UIEdgeInsetsMake(10, 10, 10, 10);
        _originImageCheckboxButton.__fw_disabledAlpha = UIButton.__fw_disabledAlpha;
        _originImageCheckboxButton.__fw_highlightedAlpha = UIButton.__fw_highlightedAlpha;
        [_originImageCheckboxButton addTarget:self action:@selector(handleOriginImageCheckboxButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _originImageCheckboxButton;
}

- (NSMutableArray<__FWAsset *> *)editImageAssetArray {
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

- (void)setDownloadStatus:(__FWAssetDownloadStatus)downloadStatus {
    _downloadStatus = downloadStatus;
    if (!_singleCheckMode) {
        self.checkboxButton.hidden = NO;
    }
}

- (void)updateImagePickerPreviewViewWithImagesAssetArray:(NSMutableArray<__FWAsset *> *)imageAssetArray
                                 selectedImageAssetArray:(NSMutableArray<__FWAsset *> *)selectedImageAssetArray
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
    __FWAsset *imageAsset = [self.imagesAssetArray objectAtIndex:index];
    if (imageAsset.assetType == __FWAssetTypeImage) {
        if (imageAsset.assetSubType == __FWAssetSubTypeLivePhoto) {
            BOOL checkLivePhoto = (self.imagePickerController.filterType & __FWImagePickerFilterTypeLivePhoto) || self.imagePickerController.filterType < 1;
            if (checkLivePhoto) return __FWImagePreviewMediaTypeLivePhoto;
        }
        return __FWImagePreviewMediaTypeImage;
    } else if (imageAsset.assetType == __FWAssetTypeVideo) {
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
    __FWAsset *imageAsset = self.imagesAssetArray[index];
    if (!_singleCheckMode) {
        self.checkboxButton.selected = [self.selectedImageAssetArray containsObject:imageAsset];
    }
    
    [self updateOriginImageCheckboxButtonWithIndex:index];
    [self updateCollectionViewCheckedIndex:[self.editImageAssetArray indexOfObject:imageAsset]];
}

- (void)requestImageForZoomImageView:(__FWZoomImageView *)imageView withIndex:(NSInteger)index {
    // 如果是走 PhotoKit 的逻辑，那么这个 block 会被多次调用，并且第一次调用时返回的图片是一张小图，
    // 拉取图片的过程中可能会多次返回结果，且图片尺寸越来越大，因此这里 contentMode为ScaleAspectFit 以防止图片大小跳动
    __FWAsset *imageAsset = [self.imagesAssetArray objectAtIndex:index];
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
            if (self.downloadStatus != __FWAssetDownloadStatusDownloading) {
                self.downloadStatus = __FWAssetDownloadStatusDownloading;
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
                self.downloadStatus = __FWAssetDownloadStatusFailed;
                imageView.progress = 0;
            }
        });
    };
    if (imageAsset.assetType == __FWAssetTypeVideo) {
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
        } progressHandler:phProgressHandler];
        imageView.tag = imageAsset.requestID;
    } else {
        if (imageAsset.assetType != __FWAssetTypeImage) {
            return;
        }
        
        // 这么写是为了消除 Xcode 的 API available warning
        BOOL isLivePhoto = NO;
        BOOL checkLivePhoto = (self.imagePickerController.filterType & __FWImagePickerFilterTypeLivePhoto) || self.imagePickerController.filterType < 1;
        if (imageAsset.assetSubType == __FWAssetSubTypeLivePhoto && checkLivePhoto) {
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
                        self.downloadStatus = __FWAssetDownloadStatusSucceed;
                        imageView.progress = 1;
                    } else if (finished) {
                        // 下载错误
                        [imageAsset updateDownloadStatusWithDownloadResult:NO];
                        self.downloadStatus = __FWAssetDownloadStatusFailed;
                        imageView.progress = 0;
                    }
                });
            } progressHandler:phProgressHandler];
            imageView.tag = imageAsset.requestID;
        }
        
        if (isLivePhoto) {
        } else if (imageAsset.assetSubType == __FWAssetSubTypeGif) {
            [imageAsset requestImageDataWithCompletion:^(NSData *imageData, NSDictionary<NSString *,id> *info, BOOL isGIF, BOOL isHEIC) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    UIImage *resultImage = [UIImage __fw_imageWithData:imageData scale:1 options:nil];
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
                        self.downloadStatus = __FWAssetDownloadStatusSucceed;
                        imageView.progress = 1;
                    } else if (finished) {
                        // 下载错误
                        [imageAsset updateDownloadStatusWithDownloadResult:NO];
                        self.downloadStatus = __FWAssetDownloadStatusFailed;
                        imageView.progress = 0;
                    }
                });
            } progressHandler:phProgressHandler];
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
    __FWAsset *imageAsset = [self.editImageAssetArray objectAtIndex:indexPath.item];
    __FWImagePickerPreviewCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
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
    __FWAsset *imageAsset = [self.editImageAssetArray objectAtIndex:indexPath.item];
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
        __FWAsset *imageAsset = self.imagesAssetArray[self.imagePreviewView.currentImageIndex];
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
                [self __fw_showAlertWithTitle:[NSString stringWithFormat:[NSObject __fw_bundleString:@"fw.pickerExceed"], @(self.maximumSelectImageCount)] message:nil cancel:[NSObject __fw_bundleString:@"fw.close"] cancelBlock:nil];
            }
            return;
        }
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(imagePickerPreviewController:willCheckImageAtIndex:)]) {
            [self.delegate imagePickerPreviewController:self willCheckImageAtIndex:self.imagePreviewView.currentImageIndex];
        }
        
        button.selected = YES;
        __FWAsset *imageAsset = [self.imagesAssetArray objectAtIndex:self.imagePreviewView.currentImageIndex];
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
    __FWAsset *imageAsset = self.imagesAssetArray[self.imagePreviewView.currentImageIndex];
    [imageAsset requestOriginImageWithCompletion:^(UIImage * _Nullable result, NSDictionary<NSString *,id> * _Nullable info, BOOL finished) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (finished && result) {
                // 资源资源已经在本地或下载成功
                [imageAsset updateDownloadStatusWithDownloadResult:YES];
                self.downloadStatus = __FWAssetDownloadStatusSucceed;
                imageView.progress = 1;
                
                [self beginEditImageAsset:imageAsset image:result];
            } else if (finished) {
                // 下载错误
                [imageAsset updateDownloadStatusWithDownloadResult:NO];
                self.downloadStatus = __FWAssetDownloadStatusFailed;
                imageView.progress = 0;
            }
        });
    } progressHandler:^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
        imageAsset.downloadProgress = progress;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.downloadStatus != __FWAssetDownloadStatusDownloading) {
                self.downloadStatus = __FWAssetDownloadStatusDownloading;
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
                self.downloadStatus = __FWAssetDownloadStatusFailed;
                imageView.progress = 0;
            }
        });
    }];
}

- (void)handleSendButtonClick:(UIButton *)sender {
    sender.userInteractionEnabled = NO;
    if (self.selectedImageAssetArray.count == 0) {
        // 如果没选中任何一张，则点击发送按钮直接发送当前这张大图
        __FWAsset *currentAsset = self.imagesAssetArray[self.imagePreviewView.currentImageIndex];
        [self.selectedImageAssetArray addObject:currentAsset];
    }
    
    if (self.imagePickerController.shouldRequestImage) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(imagePickerPreviewControllerWillStartLoading:)]) {
            [self.delegate imagePickerPreviewControllerWillStartLoading:self];
        } else if (self.showsDefaultLoading) {
            [self __fw_showLoadingWithText:nil cancelBlock:nil];
        }
        [__FWImagePickerController requestImagesAssetArray:self.selectedImageAssetArray filterType:self.imagePickerController.filterType useOrigin:self.shouldUseOriginImage completion:^{
            if (self.delegate && [self.delegate respondsToSelector:@selector(imagePickerPreviewControllerDidFinishLoading:)]) {
                [self.delegate imagePickerPreviewControllerDidFinishLoading:self];
            } else if (self.showsDefaultLoading) {
                [self __fw_hideLoadingWithDelayed:NO];
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
        [button setTitle:[NSObject __fw_bundleString:@"fw.original"] forState:UIControlStateNormal];
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
    __FWAsset *asset = self.imagesAssetArray[index];
    if (asset.assetType == __FWAssetTypeAudio || asset.assetType == __FWAssetTypeVideo) {
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

- (void)beginEditImageAsset:(__FWAsset *)imageAsset image:(UIImage *)image {
    __FWImageCropController *cropController;
    if (self.delegate && [self.delegate respondsToSelector:@selector(imageCropControllerForPreviewController:image:)]) {
        cropController = [self.delegate imageCropControllerForPreviewController:self image:image];
    } else if (self.cropControllerBlock) {
        cropController = self.cropControllerBlock(image);
    } else {
        cropController = [[__FWImageCropController alloc] initWithImage:image];
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
    CGRect sendButtonFrame = self.sendButton.frame;
    sendButtonFrame.origin = CGPointMake(CGRectGetWidth(self.bottomToolBarView.frame) - self.toolBarPaddingHorizontal - CGRectGetWidth(self.sendButton.frame) - self.view.safeAreaInsets.right, (bottomToolBarContentHeight - CGRectGetHeight(self.sendButton.frame)) / 2.0);
    self.sendButton.frame = sendButtonFrame;
}

- (void)updateImageCountAndCollectionView:(BOOL)animated {
    if (!_singleCheckMode) {
        NSUInteger selectedCount = [self.selectedImageAssetArray count];
        if (selectedCount > 0) {
            self.sendButton.enabled = selectedCount >= self.minimumSelectImageCount;
            [self.sendButton setTitle:[NSString stringWithFormat:@"%@(%@)", [NSObject __fw_bundleString:@"fw.done"], @(selectedCount)] forState:UIControlStateNormal];
        } else {
            self.sendButton.enabled = self.minimumSelectImageCount <= 1;
            [self.sendButton setTitle:[NSObject __fw_bundleString:@"fw.done"] forState:UIControlStateNormal];
        }
        if (self.delegate && [self.delegate respondsToSelector:@selector(imagePickerPreviewController:willChangeCheckedCount:)]) {
            [self.delegate imagePickerPreviewController:self willChangeCheckedCount:selectedCount];
        }
        [self updateSendButtonLayout];
    }
    
    if (!_singleCheckMode && self.showsEditCollectionView) {
        __FWAsset *currentAsset = self.imagesAssetArray[self.imagePreviewView.currentImageIndex];
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
        __FWImagePickerPreviewCollectionCell *cell = (__FWImagePickerPreviewCollectionCell *)[self.editCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:_editCheckedIndex inSection:0]];
        cell.checked = NO;
    }
    
    _editCheckedIndex = index;
    if (_editCheckedIndex != NSNotFound) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:_editCheckedIndex inSection:0];
        __FWImagePickerPreviewCollectionCell *cell = (__FWImagePickerPreviewCollectionCell *)[self.editCollectionView cellForItemAtIndexPath:indexPath];
        cell.checked = YES;
        if ([self.editCollectionView numberOfItemsInSection:0] > _editCheckedIndex) {
            [self.editCollectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
        }
    }
}

@end

#pragma mark - __FWImagePickerController

static NSString * const kVideoCellIdentifier = @"video";
static NSString * const kImageOrUnknownCellIdentifier = @"imageorunknown";

#pragma mark - __FWImagePickerController

@interface __FWImagePickerController () <__FWToolbarTitleViewDelegate>

@property(nonatomic, strong) __FWImagePickerPreviewController *imagePickerPreviewController;
@property(nonatomic, weak) __FWImageAlbumController *albumController;
@property(nonatomic, assign) BOOL isImagesAssetLoaded;
@property(nonatomic, assign) BOOL isImagesAssetLoading;
@property(nonatomic, assign) BOOL hasScrollToInitialPosition;

@end

@implementation __FWImagePickerController

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
    
    __FWToolbarTitleView *titleView = [[__FWToolbarTitleView alloc] init];
    _titleView = titleView;
    titleView.delegate = self;
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.navigationItem.titleView = titleView;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[NSObject __fw_bundleImage:@"fw.navClose"] style:UIBarButtonItemStylePlain target:self action:@selector(handleCancelButtonClick:)];
}

- (void)setToolBarBackgroundColor:(UIColor *)toolBarBackgroundColor {
    _toolBarBackgroundColor = toolBarBackgroundColor;
    self.navigationController.navigationBar.__fw_backgroundColor = toolBarBackgroundColor;
}

- (void)setToolBarTintColor:(UIColor *)toolBarTintColor {
    _toolBarTintColor = toolBarTintColor;
    self.navigationController.navigationBar.__fw_foregroundColor = toolBarTintColor;
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
    self.navigationController.navigationBar.__fw_isTranslucent = NO;
    self.navigationController.navigationBar.__fw_shadowColor = nil;
    self.navigationController.navigationBar.__fw_backgroundColor = self.toolBarBackgroundColor;
    self.navigationController.navigationBar.__fw_foregroundColor = self.toolBarTintColor;
    
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
        CGRect previewButtonFrame = self.previewButton.frame;
        previewButtonFrame.origin = CGPointMake(self.toolBarPaddingHorizontal + self.view.safeAreaInsets.left, (CGRectGetHeight(self.operationToolBarView.bounds) - self.view.safeAreaInsets.bottom - CGRectGetHeight(self.previewButton.frame)) / 2.0);
        self.previewButton.frame = previewButtonFrame;
        [self updateSendButtonLayout];
        operationToolBarViewHeight = CGRectGetHeight(self.operationToolBarView.frame);
    }
    
    if (!CGSizeEqualToSize(self.collectionView.frame.size, self.view.bounds.size)) {
        self.collectionView.frame = self.view.bounds;
    }
    UIEdgeInsets contentInset = UIEdgeInsetsMake(UIScreen.__fw_topBarHeight, self.collectionView.safeAreaInsets.left, MAX(operationToolBarViewHeight, self.collectionView.safeAreaInsets.bottom), self.collectionView.safeAreaInsets.right);
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

- (void)refreshWithAssetsGroup:(__FWAssetGroup *)assetsGroup {
    _assetsGroup = assetsGroup;
    if (!self.imagesAssetArray) {
        _imagesAssetArray = [[NSMutableArray alloc] init];
        _selectedImageAssetArray = [[NSMutableArray alloc] init];
    } else {
        [self.imagesAssetArray removeAllObjects];
    }
    // 通过 __FWAssetGroup 获取该相册所有的图片 __FWAsset，并且储存到数组中
    __FWAlbumSortType albumSortType = __FWAlbumSortTypePositive;
    // 从 delegate 中获取相册内容的排序方式，如果没有实现这个 delegate，则使用 __FWAlbumSortType 的默认值，即最新的内容排在最后面
    if (self.imagePickerControllerDelegate && [self.imagePickerControllerDelegate respondsToSelector:@selector(albumSortTypeForImagePickerController:)]) {
        albumSortType = [self.imagePickerControllerDelegate albumSortTypeForImagePickerController:self];
    }
    // 遍历相册内的资源较为耗时，交给子线程去处理，因此这里需要显示 Loading
    if (!self.isImagesAssetLoading) {
        self.isImagesAssetLoading = YES;
        if ([self.imagePickerControllerDelegate respondsToSelector:@selector(imagePickerControllerWillStartLoading:)]) {
            [self.imagePickerControllerDelegate imagePickerControllerWillStartLoading:self];
        } else if (self.showsDefaultLoading) {
            [self __fw_showLoadingWithText:nil cancelBlock:nil];
        }
    }
    if (!assetsGroup) {
        [self refreshCollectionView];
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [assetsGroup enumerateAssetsWithOptions:(AlbumSortType)albumSortType using:^(__FWAsset *resultAsset) {
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

- (void)refreshWithFilterType:(__FWImagePickerFilterType)filterType {
    _filterType = filterType;
    if ([self.imagePickerControllerDelegate respondsToSelector:@selector(imagePickerControllerWillStartLoading:)]) {
        [self.imagePickerControllerDelegate imagePickerControllerWillStartLoading:self];
    } else if (self.showsDefaultLoading) {
        [self __fw_showLoadingWithText:nil cancelBlock:nil];
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
        [self __fw_hideLoadingWithDelayed:NO];
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
        if ([__FWAssetManager authorizationStatus] == __FWAssetAuthorizationStatusNotAuthorized) {
            if ([self.imagePickerControllerDelegate respondsToSelector:@selector(imagePickerControllerWillShowEmpty:)]) {
                [self.imagePickerControllerDelegate imagePickerControllerWillShowDenied:self];
            } else {
                NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
                NSString *appName = infoDictionary[@"CFBundleDisplayName"] ?: infoDictionary[(NSString *)kCFBundleNameKey];
                NSString *tipText = [NSString stringWithFormat:[NSObject __fw_bundleString:@"fw.pickerDenied"], appName];
                [self __fw_showEmptyViewWithText:tipText detail:nil image:nil action:nil block:nil];
            }
        } else {
            if ([self.imagePickerControllerDelegate respondsToSelector:@selector(imagePickerControllerWillShowEmpty:)]) {
                [self.imagePickerControllerDelegate imagePickerControllerWillShowEmpty:self];
            } else {
                [self __fw_showEmptyViewWithText:[NSObject __fw_bundleString:@"fw.pickerEmpty"] detail:nil image:nil action:nil block:nil];
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
        if ([self.imagePickerControllerDelegate respondsToSelector:@selector(albumSortTypeForImagePickerController:)] && [self.imagePickerControllerDelegate albumSortTypeForImagePickerController:self] == __FWAlbumSortTypeReverse) {
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
    CGRect toFrame = CGRectMake(0, 0, self.view.bounds.size.width, self.albumController.tableViewHeight + UIScreen.__fw_topBarHeight);
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
    
    __FWImageAlbumController *albumController;
    if (self.imagePickerControllerDelegate && [self.imagePickerControllerDelegate respondsToSelector:@selector(albumControllerForImagePickerController:)]) {
        albumController = [self.imagePickerControllerDelegate albumControllerForImagePickerController:self];
    } else if (self.albumControllerBlock) {
        albumController = self.albumControllerBlock();
    }
    if (!albumController) return;
    
    self.albumController = albumController;
    albumController.imagePickerController = self;
    albumController.contentType = [__FWImagePickerController albumContentTypeWithFilterType:self.filterType];
    __weak __typeof__(self) self_weak_ = self;
    albumController.albumArrayLoaded = ^{
        __typeof__(self) self = self_weak_;
        if (self.albumController.albumsArray.count > 0) {
            __FWAssetGroup *assetsGroup = self.albumController.albumsArray.firstObject;
            self.albumController.assetsGroup = assetsGroup;
            self.titleView.userInteractionEnabled = YES;
            if (self.titleAccessoryImage) self.titleView.accessoryImage = self.titleAccessoryImage;
            self.title = [assetsGroup name];
            [self refreshWithAssetsGroup:assetsGroup];
        } else {
            [self refreshWithAssetsGroup:nil];
        }
    };
    albumController.assetsGroupSelected = ^(__FWAssetGroup * _Nonnull assetsGroup) {
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
        albumController.maximumTableViewHeight = albumController.albumTableViewCellHeight * ceil(UIScreen.mainScreen.bounds.size.height / albumController.albumTableViewCellHeight / 2.0) + albumController.additionalTableViewHeight;
    }
}

#pragma mark - Getters & Setters

@synthesize collectionViewLayout = _collectionViewLayout;
- (UICollectionViewFlowLayout *)collectionViewLayout {
    if (!_collectionViewLayout) {
        _collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
        CGFloat inset = 2.0 / UIScreen.mainScreen.scale; // no why, just beautiful
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
        [_collectionView registerClass:[__FWImagePickerCollectionCell class] forCellWithReuseIdentifier:kVideoCellIdentifier];
        [_collectionView registerClass:[__FWImagePickerCollectionCell class] forCellWithReuseIdentifier:kImageOrUnknownCellIdentifier];
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
    return _operationToolBarHeight > 0 ? _operationToolBarHeight : UIScreen.__fw_toolBarHeight;
}

@synthesize sendButton = _sendButton;
- (UIButton *)sendButton {
    if (!_sendButton) {
        _sendButton = [[UIButton alloc] init];
        _sendButton.enabled = NO;
        _sendButton.titleLabel.font = [UIFont systemFontOfSize:16];
        _sendButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        [_sendButton setTitleColor:self.toolBarTintColor forState:UIControlStateNormal];
        [_sendButton setTitle:[NSObject __fw_bundleString:@"fw.done"] forState:UIControlStateNormal];
        _sendButton.__fw_touchInsets = UIEdgeInsetsMake(12, 20, 12, 20);
        _sendButton.__fw_disabledAlpha = UIButton.__fw_disabledAlpha;
        _sendButton.__fw_highlightedAlpha = UIButton.__fw_highlightedAlpha;
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
        [_previewButton setTitle:[NSObject __fw_bundleString:@"fw.preview"] forState:UIControlStateNormal];
        _previewButton.__fw_touchInsets = UIEdgeInsetsMake(12, 20, 12, 20);
        _previewButton.__fw_disabledAlpha = UIButton.__fw_disabledAlpha;
        _previewButton.__fw_highlightedAlpha = UIButton.__fw_highlightedAlpha;
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
    __FWAsset *imageAsset = [self.imagesAssetArray objectAtIndex:indexPath.item];
    
    NSString *identifier = nil;
    if (imageAsset.assetType == __FWAssetTypeVideo) {
        identifier = kVideoCellIdentifier;
    } else {
        identifier = kImageOrUnknownCellIdentifier;
    }
    __FWImagePickerCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    [cell renderWithAsset:imageAsset referenceSize:[self referenceImageSize]];
    
    cell.checkboxButton.tag = indexPath.item;
    [cell.checkboxButton addTarget:self action:@selector(handleCheckBoxButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    cell.selectable = self.allowsMultipleSelection;
    if (cell.selectable) {
        // 如果该图片的 __FWAsset 被包含在已选择图片的数组中，则控制该图片被选中
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
    __FWAsset *imageAsset = self.imagesAssetArray[indexPath.item];
    if (![self.selectedImageAssetArray containsObject:imageAsset] &&
        [self.selectedImageAssetArray count] >= _maximumSelectImageCount) {
        if (self.imagePickerControllerDelegate && [self.imagePickerControllerDelegate respondsToSelector:@selector(imagePickerPreviewControllerWillShowExceed:)]) {
            [self.imagePickerControllerDelegate imagePickerControllerWillShowExceed:self];
        } else {
            [self __fw_showAlertWithTitle:[NSString stringWithFormat:[NSObject __fw_bundleString:@"fw.pickerExceed"], @(self.maximumSelectImageCount)] message:nil cancel:[NSObject __fw_bundleString:@"fw.close"] cancelBlock:nil];
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

#pragma mark - __FWToolbarTitleViewDelegate

- (void)didTouchTitleView:(__FWToolbarTitleView *)titleView isActive:(BOOL)isActive {
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
            [self __fw_showLoadingWithText:nil cancelBlock:nil];
        }
        [self initPreviewViewControllerIfNeeded];
        [__FWImagePickerController requestImagesAssetArray:self.selectedImageAssetArray filterType:self.filterType useOrigin:self.imagePickerPreviewController.shouldUseOriginImage completion:^{
            if ([self.imagePickerControllerDelegate respondsToSelector:@selector(imagePickerControllerDidFinishLoading:)]) {
                [self.imagePickerControllerDelegate imagePickerControllerDidFinishLoading:self];
            } else if (self.showsDefaultLoading) {
                [self __fw_hideLoadingWithDelayed:NO];
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
    
    __FWImagePickerCollectionCell *cell = (__FWImagePickerCollectionCell *)[_collectionView cellForItemAtIndexPath:indexPath];
    __FWAsset *imageAsset = [self.imagesAssetArray objectAtIndex:indexPath.item];
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
                [self __fw_showAlertWithTitle:[NSString stringWithFormat:[NSObject __fw_bundleString:@"fw.pickerExceed"], @(self.maximumSelectImageCount)] message:nil cancel:[NSObject __fw_bundleString:@"fw.close"] cancelBlock:nil];
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
    __FWAsset *imageAsset = [self.imagesAssetArray objectAtIndex:indexPath.item];
    __FWImagePickerCollectionCell *cell = (__FWImagePickerCollectionCell *)[_collectionView cellForItemAtIndexPath:indexPath];
    imageAsset.requestID = [imageAsset requestOriginImageWithCompletion:^(UIImage *result, NSDictionary *info, BOOL finished) {
        if (finished && result) {
            // 资源资源已经在本地或下载成功
            [imageAsset updateDownloadStatusWithDownloadResult:YES];
            cell.downloadStatus = __FWAssetDownloadStatusSucceed;
            
        } else if (finished) {
            // 下载错误
            [imageAsset updateDownloadStatusWithDownloadResult:NO];
            cell.downloadStatus = __FWAssetDownloadStatusFailed;
        }
        
    } progressHandler:^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
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
                if (cell.downloadStatus != __FWAssetDownloadStatusDownloading) {
                    cell.downloadStatus = __FWAssetDownloadStatusDownloading;
                    // 预先设置预览界面的下载状态
                    self.imagePickerPreviewController.downloadStatus = __FWAssetDownloadStatusDownloading;
                }
                if (error) {
                    cell.downloadStatus = __FWAssetDownloadStatusFailed;
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
            [self.sendButton setTitle:[NSString stringWithFormat:@"%@(%@)", [NSObject __fw_bundleString:@"fw.done"], @(selectedCount)] forState:UIControlStateNormal];
        } else {
            self.previewButton.enabled = NO;
            self.sendButton.enabled = NO;
            [self.sendButton setTitle:[NSObject __fw_bundleString:@"fw.done"] forState:UIControlStateNormal];
        }
        if (self.imagePickerControllerDelegate && [self.imagePickerControllerDelegate respondsToSelector:@selector(imagePickerController:willChangeCheckedCount:)]) {
            [self.imagePickerControllerDelegate imagePickerController:self willChangeCheckedCount:selectedCount];
        }
        [self updateSendButtonLayout];
    }
    
    if (reloadData) {
        [self.collectionView reloadData];
    } else {
        [self.selectedImageAssetArray enumerateObjectsUsingBlock:^(__FWAsset *imageAsset, NSUInteger idx, BOOL *stop) {
            NSInteger imageIndex = [self.imagesAssetArray indexOfObject:imageAsset];
            if (imageIndex == NSNotFound) return;
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:imageIndex inSection:0];
            
            __FWImagePickerCollectionCell *cell = (__FWImagePickerCollectionCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
            if (cell.selectable) {
                cell.checked = YES;
                cell.checkedIndex = [self.selectedImageAssetArray indexOfObject:imageAsset];
                cell.disabled = !cell.checked && [self.selectedImageAssetArray count] >= self.maximumSelectImageCount;
            }
        }];
    }
}

#pragma mark - Request Image

+ (__FWAlbumContentType)albumContentTypeWithFilterType:(__FWImagePickerFilterType)filterType {
    __FWAlbumContentType contentType = filterType < 1 ? __FWAlbumContentTypeAll : __FWAlbumContentTypeOnlyPhoto;
    if (filterType & __FWImagePickerFilterTypeVideo) {
        if (filterType & __FWImagePickerFilterTypeImage ||
            filterType & __FWImagePickerFilterTypeLivePhoto) {
            contentType = __FWAlbumContentTypeAll;
        } else {
            contentType = __FWAlbumContentTypeOnlyVideo;
        }
    } else if (filterType & __FWImagePickerFilterTypeLivePhoto &&
               !(filterType & __FWImagePickerFilterTypeImage)) {
        contentType = __FWAlbumContentTypeOnlyLivePhoto;
    }
    return contentType;
}

+ (void)requestImagesAssetArray:(NSArray<__FWAsset *> *)imagesAssetArray
                     filterType:(__FWImagePickerFilterType)filterType
                      useOrigin:(BOOL)useOrigin
                     completion:(void (^)(void))completion {
    if (imagesAssetArray.count < 1) {
        if (completion) completion();
        return;
    }
    
    NSInteger totalCount = imagesAssetArray.count;
    __block NSInteger finishCount = 0;
    void (^completionHandler)(__FWAsset *asset, id _Nullable object, NSDictionary * _Nullable info) = ^(__FWAsset *asset, id _Nullable object, NSDictionary * _Nullable info){
        asset.requestObject = object;
        asset.requestInfo = info;
        
        finishCount += 1;
        if (finishCount == totalCount) {
            if (completion) completion();
        }
    };
    
    BOOL checkLivePhoto = (filterType & __FWImagePickerFilterTypeLivePhoto) || filterType < 1;
    BOOL checkVideo = (filterType & __FWImagePickerFilterTypeVideo) || filterType < 1;
    [imagesAssetArray enumerateObjectsUsingBlock:^(__FWAsset *asset, NSUInteger index, BOOL *stop) {
        if (checkVideo && asset.assetType == __FWAssetTypeVideo) {
            NSString *filePath = [__FWAssetManager cachePath];
            [[NSFileManager defaultManager] createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
            filePath = [[filePath stringByAppendingPathComponent:[self md5EncodeString:[NSUUID UUID].UUIDString]] stringByAppendingPathExtension:@"mp4"];
            NSURL *fileURL = [NSURL fileURLWithPath:filePath];
            [asset requestVideoURLWithOutputURL:fileURL exportPreset:useOrigin ? AVAssetExportPresetHighestQuality : AVAssetExportPresetMediumQuality completion:^(NSURL * _Nullable videoURL, NSDictionary<NSString *,id> * _Nullable info) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(asset, videoURL, info);
                });
            } progressHandler:nil];
        } else if (asset.assetType == __FWAssetTypeImage) {
            if (asset.editedImage) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(asset, asset.editedImage, nil);
                });
                return;
            }
            
            if (checkLivePhoto && asset.assetSubType == __FWAssetSubTypeLivePhoto) {
                [asset requestLivePhotoWithCompletion:^void(PHLivePhoto *livePhoto, NSDictionary *info, BOOL finished) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (finished) completionHandler(asset, livePhoto, info);
                    });
                } progressHandler:nil];
            } else if (asset.assetSubType == __FWAssetSubTypeGif) {
                [asset requestImageDataWithCompletion:^(NSData *imageData, NSDictionary<NSString *,id> *info, BOOL isGIF, BOOL isHEIC) {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        UIImage *resultImage = imageData ? [UIImage __fw_imageWithData:imageData scale:1 options:nil] : nil;
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
                    } progressHandler:nil];
                } else {
                    [asset requestPreviewImageWithCompletion:^(UIImage *result, NSDictionary<NSString *,id> *info, BOOL finished) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (finished) completionHandler(asset, result, info);
                        });
                    } progressHandler:nil];
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
