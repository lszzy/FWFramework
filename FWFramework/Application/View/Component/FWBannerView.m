/*!
 @header     FWBannerView.m
 @indexgroup FWFramework
 @brief      FWBannerView
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/12/13
 */

#import "FWBannerView.h"
#import "UIView+FWAutoLayout.h"
#import "UIPageControl+FWFramework.h"
#import "UIImage+FWFramework.h"
#import "UIImageView+FWFramework.h"
#import "FWPageControl.h"

#pragma mark - FWBannerViewFlowLayout

@interface FWBannerViewFlowLayout : UICollectionViewFlowLayout

@property (nonatomic, assign) BOOL pagingEnabled;
@property (nonatomic, assign) BOOL pagingCenter;

@property (nonatomic, assign) CGSize lastCollectionViewSize;
@property (nonatomic, assign) UICollectionViewScrollDirection lastScrollDirection;
@property (nonatomic, assign) CGSize lastItemSize;

@end

@implementation FWBannerViewFlowLayout

#pragma mark - Lifecycle

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _lastScrollDirection = self.scrollDirection;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _lastScrollDirection = self.scrollDirection;
    }
    return self;
}

#pragma mark - Public

- (CGFloat)pageWidth
{
    if (self.scrollDirection == UICollectionViewScrollDirectionHorizontal) {
        return self.itemSize.width + self.minimumLineSpacing;
    } else {
        return self.itemSize.height + self.minimumLineSpacing;
    }
}

- (NSInteger)currentPage
{
    if (!self.collectionView) return 0;
    if (self.collectionView.frame.size.width == 0 || self.collectionView.frame.size.height == 0) return 0;
    
    if (!self.pagingEnabled) {
        NSInteger currentPage = 0;
        if (self.scrollDirection == UICollectionViewScrollDirectionHorizontal) {
            currentPage = (self.collectionView.contentOffset.x + self.itemSize.width * 0.5) / self.itemSize.width;
        } else {
            currentPage = (self.collectionView.contentOffset.y + self.itemSize.height * 0.5) / self.itemSize.height;
        }
        return MAX(0, currentPage);
    }
    
    CGPoint currentPoint = CGPointMake(self.collectionView.contentOffset.x + self.collectionView.bounds.size.width / 2, self.collectionView.contentOffset.y + self.collectionView.bounds.size.height / 2);
    return [self.collectionView indexPathForItemAtPoint:currentPoint].row;
}

- (void)scrollToPage:(NSInteger)index animated:(BOOL)animated
{
    if (!self.collectionView) return;
    
    if (!self.pagingEnabled) {
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:animated];
        return;
    }
    
    CGPoint proposedContentOffset;
    BOOL shouldAnimate;
    if (self.scrollDirection == UICollectionViewScrollDirectionHorizontal) {
        CGFloat pageOffset = [self pageWidth] * index - self.collectionView.contentInset.left;
        proposedContentOffset = CGPointMake(pageOffset, self.collectionView.contentOffset.y);
        shouldAnimate = fabs(self.collectionView.contentOffset.x - pageOffset) > 1 ? animated : NO;
    } else {
        CGFloat pageOffset = [self pageWidth] * index - self.collectionView.contentInset.top;
        proposedContentOffset = CGPointMake(self.collectionView.contentOffset.x, pageOffset);
        shouldAnimate = fabs(self.collectionView.contentOffset.y - pageOffset) > 1 ? animated : NO;
    }
    [self.collectionView setContentOffset:proposedContentOffset animated:shouldAnimate];
}

#pragma mark - Protected

- (void)invalidateLayoutWithContext:(UICollectionViewLayoutInvalidationContext *)context
{
    [super invalidateLayoutWithContext:context];
    if (!self.pagingEnabled || !self.collectionView) return;
    
    CGSize currentCollectionViewSize = self.collectionView.bounds.size;
    if (!CGSizeEqualToSize(currentCollectionViewSize, self.lastCollectionViewSize) ||
        self.lastScrollDirection != self.scrollDirection ||
        !CGSizeEqualToSize(self.lastItemSize, self.itemSize)) {
        if (self.scrollDirection == UICollectionViewScrollDirectionHorizontal) {
            CGFloat inset = self.pagingCenter ? (currentCollectionViewSize.width - self.itemSize.width) / 2 : self.minimumLineSpacing;
            self.collectionView.contentInset = UIEdgeInsetsMake(0, inset, 0, inset);
            self.collectionView.contentOffset = CGPointMake(-inset, 0);
        } else {
            CGFloat inset = self.pagingCenter ? (currentCollectionViewSize.height - self.itemSize.height) / 2 : self.minimumLineSpacing;
            self.collectionView.contentInset = UIEdgeInsetsMake(inset, 0, inset, 0);
            self.collectionView.contentOffset = CGPointMake(0, -inset);
        }
        self.lastCollectionViewSize = currentCollectionViewSize;
        self.lastScrollDirection = self.scrollDirection;
        self.lastItemSize = self.itemSize;
    }
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity
{
    if (!self.pagingEnabled) return [super targetContentOffsetForProposedContentOffset:proposedContentOffset withScrollingVelocity:velocity];
    if (!self.collectionView) return proposedContentOffset;
    
    CGRect proposedRect = [self determineProposedRect:proposedContentOffset];
    NSArray *layoutAttributes = [self layoutAttributesForElementsInRect:proposedRect];
    if (!layoutAttributes) {
        return proposedContentOffset;
    }
    UICollectionViewLayoutAttributes *candidateAttributesForRect = [self attributesForRect:layoutAttributes proposedContentOffset:proposedContentOffset];
    if (!candidateAttributesForRect) {
        return proposedContentOffset;
    }
    
    CGFloat newOffset;
    CGFloat offset;
    if (self.scrollDirection == UICollectionViewScrollDirectionHorizontal) {
        newOffset = self.pagingCenter ? (candidateAttributesForRect.center.x - self.collectionView.bounds.size.width / 2) : (candidateAttributesForRect.frame.origin.x - self.minimumLineSpacing);
        offset = newOffset - self.collectionView.contentOffset.x;
        if ((velocity.x < 0 && offset > 0) || (velocity.x > 0 && offset < 0)) {
            newOffset += velocity.x > 0 ? [self pageWidth] : -[self pageWidth];
        }
        return CGPointMake(newOffset, proposedContentOffset.y);
    } else {
        newOffset = self.pagingCenter ? (candidateAttributesForRect.center.y - self.collectionView.bounds.size.height / 2) : (candidateAttributesForRect.frame.origin.y - self.minimumLineSpacing);
        offset = newOffset - self.collectionView.contentOffset.y;
        if ((velocity.y < 0 && offset > 0) || (velocity.y > 0 && offset < 0)) {
            newOffset += velocity.y > 0 ? [self pageWidth] : -[self pageWidth];
        }
        return CGPointMake(proposedContentOffset.x, newOffset);
    }
}

#pragma mark - Private

- (CGRect)determineProposedRect:(CGPoint)proposedContentOffset
{
    CGPoint origin = CGPointZero;
    if (self.scrollDirection == UICollectionViewScrollDirectionHorizontal) {
        origin = CGPointMake(proposedContentOffset.x, self.collectionView.contentOffset.y);
    } else {
        origin = CGPointMake(self.collectionView.contentOffset.x, proposedContentOffset.y);
    }
    return CGRectMake(origin.x, origin.y, self.collectionView.bounds.size.width, self.collectionView.bounds.size.height);
}

- (UICollectionViewLayoutAttributes *)attributesForRect:(NSArray *)layoutAttributes proposedContentOffset:(CGPoint)proposedContentOffset
{
    UICollectionViewLayoutAttributes *candidateAttributes = nil;
    CGFloat proposedCenterOffset = 0;
    if (self.scrollDirection == UICollectionViewScrollDirectionHorizontal) {
        proposedCenterOffset = self.pagingCenter ? (proposedContentOffset.x + self.collectionView.bounds.size.width / 2) : (proposedContentOffset.x + self.minimumLineSpacing);
    } else {
        proposedCenterOffset = self.pagingCenter ? (proposedContentOffset.y + self.collectionView.bounds.size.height / 2) : (proposedContentOffset.y + self.minimumLineSpacing);
    }
    
    for (UICollectionViewLayoutAttributes *attributes in layoutAttributes) {
        if (attributes.representedElementCategory != UICollectionElementCategoryCell) {
            continue;
        }
        if (!candidateAttributes) {
            candidateAttributes = attributes;
            continue;
        }
        
        if (self.scrollDirection == UICollectionViewScrollDirectionHorizontal) {
            if (self.pagingCenter) {
                if (fabs(attributes.center.x - proposedCenterOffset) < fabs(candidateAttributes.center.x - proposedCenterOffset)) {
                    candidateAttributes = attributes;
                }
            } else {
                if (fabs(attributes.frame.origin.x - proposedCenterOffset) < fabs(candidateAttributes.frame.origin.x - proposedCenterOffset)) {
                    candidateAttributes = attributes;
                }
            }
        } else {
            if (self.pagingCenter) {
                if (fabs(attributes.center.y - proposedCenterOffset) < fabs(candidateAttributes.center.y - proposedCenterOffset)) {
                    candidateAttributes = attributes;
                }
            } else {
                if (fabs(attributes.frame.origin.y - proposedCenterOffset) < fabs(candidateAttributes.frame.origin.y - proposedCenterOffset)) {
                    candidateAttributes = attributes;
                }
            }
        }
    }
    return candidateAttributes;
}

@end

#pragma mark - FWBannerView

NSString * const FWBannerViewCellID = @"FWBannerViewCell";

@interface FWBannerView () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, weak) UICollectionView *mainView;
@property (nonatomic, weak) FWBannerViewFlowLayout *flowLayout;
@property (nonatomic, strong) NSArray *imagePathsGroup;
@property (nonatomic, weak) NSTimer *timer;
@property (nonatomic, assign) NSInteger totalItemsCount;
@property (nonatomic, weak) UIControl *pageControl;

@end

@implementation FWBannerView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self initialization];
        [self setupMainView];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self initialization];
    [self setupMainView];
}

- (void)initialization
{
    _pageControlAlignment = FWBannerViewPageControlAlignmentCenter;
    _autoScrollTimeInterval = 2.0;
    _titleLabelTextColor = [UIColor whiteColor];
    _titleLabelTextFont= [UIFont systemFontOfSize:14];
    _titleLabelBackgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    _titleLabelHeight = 30;
    _titleLabelTextAlignment = NSTextAlignmentLeft;
    _contentViewInset = UIEdgeInsetsZero;
    _contentViewCornerRadius = 0;
    _autoScroll = YES;
    _infiniteLoop = YES;
    _showPageControl = YES;
    _pageControlDotSize = CGSizeMake(10, 10);
    _pageControlDotSpacing = 0;
    _pageControlBottomOffset = 0;
    _pageControlRightOffset = 0;
    _pageControlStyle = FWBannerViewPageControlStyleSystem;
    _hidesForSinglePage = YES;
    _currentPageDotColor = [UIColor whiteColor];
    _pageDotColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
    _bannerImageViewContentMode = UIViewContentModeScaleAspectFill;
    
    self.backgroundColor = [UIColor clearColor];
}

+ (instancetype)bannerViewWithFrame:(CGRect)frame imageNamesGroup:(NSArray *)imageNamesGroup
{
    FWBannerView *bannerView = [[self alloc] initWithFrame:frame];
    bannerView.localizationImageNamesGroup = [NSMutableArray arrayWithArray:imageNamesGroup];
    return bannerView;
}

+ (instancetype)bannerViewWithFrame:(CGRect)frame shouldInfiniteLoop:(BOOL)infiniteLoop imageNamesGroup:(NSArray *)imageNamesGroup
{
    FWBannerView *bannerView = [[self alloc] initWithFrame:frame];
    bannerView.infiniteLoop = infiniteLoop;
    bannerView.localizationImageNamesGroup = [NSMutableArray arrayWithArray:imageNamesGroup];
    return bannerView;
}

+ (instancetype)bannerViewWithFrame:(CGRect)frame imageURLStringsGroup:(NSArray *)imageURLStringsGroup
{
    FWBannerView *bannerView = [[self alloc] initWithFrame:frame];
    bannerView.imageURLStringsGroup = [NSMutableArray arrayWithArray:imageURLStringsGroup];
    return bannerView;
}

+ (instancetype)bannerViewWithFrame:(CGRect)frame delegate:(id<FWBannerViewDelegate>)delegate placeholderImage:(UIImage *)placeholderImage
{
    FWBannerView *bannerView = [[self alloc] initWithFrame:frame];
    bannerView.delegate = delegate;
    bannerView.placeholderImage = placeholderImage;
    return bannerView;
}

- (void)setupMainView
{
    FWBannerViewFlowLayout *flowLayout = [[FWBannerViewFlowLayout alloc] init];
    _flowLayout = flowLayout;
    flowLayout.minimumLineSpacing = 0;
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    
    UICollectionView *mainView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:flowLayout];
    _mainView = mainView;
    mainView.backgroundColor = [UIColor clearColor];
    mainView.pagingEnabled = YES;
    mainView.showsHorizontalScrollIndicator = NO;
    mainView.showsVerticalScrollIndicator = NO;
    if (@available(iOS 11.0, *)) {
        mainView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    [mainView registerClass:[FWBannerViewCell class] forCellWithReuseIdentifier:FWBannerViewCellID];
    
    mainView.dataSource = self;
    mainView.delegate = self;
    mainView.scrollsToTop = NO;
    [self addSubview:mainView];
    [mainView fwPinEdgesToSuperview];
}

#pragma mark - properties

- (void)setDelegate:(id<FWBannerViewDelegate>)delegate
{
    _delegate = delegate;
    
    if ([self.delegate respondsToSelector:@selector(customCellClassForBannerView:)] && [self.delegate customCellClassForBannerView:self]) {
        [self.mainView registerClass:[self.delegate customCellClassForBannerView:self] forCellWithReuseIdentifier:FWBannerViewCellID];
    }else if ([self.delegate respondsToSelector:@selector(customCellNibForBannerView:)] && [self.delegate customCellNibForBannerView:self]) {
        [self.mainView registerNib:[self.delegate customCellNibForBannerView:self] forCellWithReuseIdentifier:FWBannerViewCellID];
    }
}

- (void)setPageControlDotSize:(CGSize)pageControlDotSize
{
    _pageControlDotSize = pageControlDotSize;
    [self setupPageControl];
    if ([self.pageControl isKindOfClass:[FWPageControl class]]) {
        FWPageControl *pageContol = (FWPageControl *)_pageControl;
        pageContol.dotSize = pageControlDotSize;
    }
}

- (void)setPageControlDotSpacing:(CGFloat)pageControlDotSpacing
{
    _pageControlDotSpacing = pageControlDotSpacing;
    
    if ([self.pageControl isKindOfClass:[FWPageControl class]]) {
        FWPageControl *pageContol = (FWPageControl *)_pageControl;
        pageContol.spacingBetweenDots = pageControlDotSpacing;
    }
}

- (void)setShowPageControl:(BOOL)showPageControl
{
    _showPageControl = showPageControl;
    
    _pageControl.hidden = !showPageControl;
}

- (void)setCurrentPageDotColor:(UIColor *)currentPageDotColor
{
    _currentPageDotColor = currentPageDotColor;
    
    if ([self.pageControl isKindOfClass:[FWPageControl class]]) {
        FWPageControl *pageControl = (FWPageControl *)_pageControl;
        pageControl.currentDotColor = currentPageDotColor;
    } else {
        UIPageControl *pageControl = (UIPageControl *)_pageControl;
        pageControl.currentPageIndicatorTintColor = currentPageDotColor;
    }
}

- (void)setPageDotColor:(UIColor *)pageDotColor
{
    _pageDotColor = pageDotColor;
    
    if ([self.pageControl isKindOfClass:[FWPageControl class]]) {
        FWPageControl *pageControl = (FWPageControl *)_pageControl;
        pageControl.dotColor = pageDotColor;
    } else {
        UIPageControl *pageControl = (UIPageControl *)_pageControl;
        pageControl.pageIndicatorTintColor = pageDotColor;
    }
}

- (void)setCurrentPageDotImage:(UIImage *)currentPageDotImage
{
    _currentPageDotImage = currentPageDotImage;
    
    if (self.pageControlStyle != FWBannerViewPageControlStyleCustom) {
        self.pageControlStyle = FWBannerViewPageControlStyleCustom;
    }
    
    [self setCustomPageControlDotImage:currentPageDotImage isCurrentPageDot:YES];
}

- (void)setPageDotImage:(UIImage *)pageDotImage
{
    _pageDotImage = pageDotImage;
    
    if (self.pageControlStyle != FWBannerViewPageControlStyleCustom) {
        self.pageControlStyle = FWBannerViewPageControlStyleCustom;
    }
    
    [self setCustomPageControlDotImage:pageDotImage isCurrentPageDot:NO];
}

- (void)setCustomPageControlDotImage:(UIImage *)image isCurrentPageDot:(BOOL)isCurrentPageDot
{
    if (!image || !self.pageControl) return;
    
    if ([self.pageControl isKindOfClass:[FWPageControl class]]) {
        FWPageControl *pageControl = (FWPageControl *)_pageControl;
        if (isCurrentPageDot) {
            pageControl.currentDotImage = image;
        } else {
            pageControl.dotImage = image;
        }
    }
}

- (void)setPageDotViewClass:(Class)pageDotViewClass
{
    _pageDotViewClass = pageDotViewClass;
    
    if (self.pageControlStyle != FWBannerViewPageControlStyleCustom) {
        self.pageControlStyle = FWBannerViewPageControlStyleCustom;
    }
    
    if (self.pageControl && [self.pageControl isKindOfClass:[FWPageControl class]]) {
        FWPageControl *pageControl = (FWPageControl *)_pageControl;
        pageControl.dotViewClass = pageDotViewClass;
    }
}

- (void)setInfiniteLoop:(BOOL)infiniteLoop
{
    _infiniteLoop = infiniteLoop;
    
    if (self.imagePathsGroup.count) {
        self.imagePathsGroup = self.imagePathsGroup;
    }
}

-(void)setAutoScroll:(BOOL)autoScroll{
    _autoScroll = autoScroll;
    
    [self invalidateTimer];
    
    if (_autoScroll) {
        [self setupTimer];
    }
}

- (void)setScrollDirection:(UICollectionViewScrollDirection)scrollDirection
{
    _scrollDirection = scrollDirection;
    
    _flowLayout.scrollDirection = scrollDirection;
}

- (void)setItemPagingEnabled:(BOOL)itemPagingEnabled
{
    _itemPagingEnabled = itemPagingEnabled;
    
    if (itemPagingEnabled) {
        _mainView.pagingEnabled = NO;
        _mainView.decelerationRate = UIScrollViewDecelerationRateFast;
        _flowLayout.pagingEnabled = YES;
        
        // 兼容自动布局，避免_mainView的frame为0
        if (CGSizeEqualToSize(_mainView.bounds.size, CGSizeZero)) {
            [self setNeedsLayout];
            [self layoutIfNeeded];
        }
    } else {
        _mainView.pagingEnabled = YES;
        _flowLayout.pagingEnabled = NO;
    }
}

- (void)setItemSize:(CGSize)itemSize
{
    _itemSize = itemSize;
    
    _flowLayout.itemSize = itemSize;
    if (!self.itemPagingEnabled) {
        self.itemPagingEnabled = YES;
    }
}

- (void)setItemSpacing:(CGFloat)itemSpacing
{
    _itemSpacing = itemSpacing;
    
    _flowLayout.minimumLineSpacing = itemSpacing;
    if (!self.itemPagingEnabled) {
        self.itemPagingEnabled = YES;
    }
}

- (void)setItemPagingCenter:(BOOL)itemPagingCenter
{
    _itemPagingCenter = itemPagingCenter;
    
    _flowLayout.pagingCenter = itemPagingCenter;
    if (!self.itemPagingEnabled) {
        self.itemPagingEnabled = YES;
    }
}

- (void)setAutoScrollTimeInterval:(CGFloat)autoScrollTimeInterval
{
    _autoScrollTimeInterval = autoScrollTimeInterval;
    
    [self setAutoScroll:self.autoScroll];
}

- (void)setImagePathsGroup:(NSArray *)imagePathsGroup
{
    [self invalidateTimer];
    
    _imagePathsGroup = imagePathsGroup;
    _totalItemsCount = self.infiniteLoop && imagePathsGroup.count > 1 ? self.imagePathsGroup.count * 100 : self.imagePathsGroup.count;
    
    if (imagePathsGroup.count > 1) {
        self.mainView.scrollEnabled = YES;
        [self setAutoScroll:self.autoScroll];
    } else {
        self.mainView.scrollEnabled = NO;
        [self invalidateTimer];
    }
    
    [self setupPageControl];
    [self.mainView reloadData];
}

- (void)setImageURLStringsGroup:(NSArray *)imageURLStringsGroup
{
    _imageURLStringsGroup = imageURLStringsGroup;
    
    NSMutableArray *imagePaths = [NSMutableArray new];
    [_imageURLStringsGroup enumerateObjectsUsingBlock:^(NSString * obj, NSUInteger idx, BOOL * stop) {
        if ([obj isKindOfClass:[NSString class]]) {
            [imagePaths addObject:obj];
        } else if ([obj isKindOfClass:[NSURL class]]) {
            NSString *urlString = ((NSURL *)obj).absoluteString;
            if (urlString) {
                [imagePaths addObject:urlString];
            }
        } else if ([obj isKindOfClass:[UIImage class]]) {
            [imagePaths addObject:obj];
        }
    }];
    self.imagePathsGroup = [imagePaths copy];
}

- (void)setLocalizationImageNamesGroup:(NSArray *)localizationImageNamesGroup
{
    _localizationImageNamesGroup = localizationImageNamesGroup;
    self.imagePathsGroup = [localizationImageNamesGroup copy];
}

- (void)setTitlesGroup:(NSArray *)titlesGroup
{
    _titlesGroup = titlesGroup;
    if (self.onlyDisplayText) {
        NSMutableArray *temp = [NSMutableArray new];
        for (int i = 0; i < _titlesGroup.count; i++) {
            [temp addObject:@""];
        }
        self.backgroundColor = [UIColor clearColor];
        self.imageURLStringsGroup = [temp copy];
    }
}

- (void)disableScrollGesture
{
    self.mainView.canCancelContentTouches = NO;
    for (UIGestureRecognizer *gesture in self.mainView.gestureRecognizers) {
        if ([gesture isKindOfClass:[UIPanGestureRecognizer class]]) {
            [self.mainView removeGestureRecognizer:gesture];
        }
    }
}

#pragma mark - actions

- (void)setupTimer
{
    [self invalidateTimer];
    
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:self.autoScrollTimeInterval target:self selector:@selector(automaticScroll) userInfo:nil repeats:YES];
    _timer = timer;
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

- (void)invalidateTimer
{
    [_timer invalidate];
    _timer = nil;
}

- (void)setupPageControl
{
    if (_pageControl) [_pageControl removeFromSuperview];
    
    if (self.imagePathsGroup.count == 0 || self.onlyDisplayText) return;
    if ((self.imagePathsGroup.count == 1) && self.hidesForSinglePage) return;
    
    NSInteger indexOnPageControl = [self pageControlIndexWithCurrentCellIndex:[_flowLayout currentPage]];

    switch (self.pageControlStyle) {
        case FWBannerViewPageControlStyleCustom: {
            FWPageControl *pageControl = [[FWPageControl alloc] init];
            pageControl.numberOfPages = self.imagePathsGroup.count;
            pageControl.dotColor = self.pageDotColor;
            pageControl.currentDotColor = self.currentPageDotColor;
            pageControl.userInteractionEnabled = NO;
            pageControl.currentPage = indexOnPageControl;
            if (self.pageDotViewClass != NULL) {
                pageControl.dotViewClass = self.pageDotViewClass;
            }
            if (self.pageControlDotSpacing > 0) {
                pageControl.spacingBetweenDots = self.pageControlDotSpacing;
            }
            [self addSubview:pageControl];
            _pageControl = pageControl;
        }
            break;
            
        case FWBannerViewPageControlStyleSystem: {
            UIPageControl *pageControl = [[UIPageControl alloc] init];
            pageControl.numberOfPages = self.imagePathsGroup.count;
            pageControl.currentPageIndicatorTintColor = self.currentPageDotColor;
            pageControl.pageIndicatorTintColor = self.pageDotColor;
            pageControl.userInteractionEnabled = NO;
            pageControl.currentPage = indexOnPageControl;
            [pageControl fwSetIndicatorSize:self.pageControlDotSize];
            [self addSubview:pageControl];
            _pageControl = pageControl;
        }
            break;
            
        default:
            break;
    }
    
    if (self.currentPageDotImage) {
        self.currentPageDotImage = self.currentPageDotImage;
    }
    if (self.pageDotImage) {
        self.pageDotImage = self.pageDotImage;
    }
}

- (void)automaticScroll
{
    if (0 == _totalItemsCount) return;
    NSInteger targetIndex = [_flowLayout currentPage] + 1;;
    [self scrollToIndex:targetIndex];
}

- (void)scrollToIndex:(NSInteger)targetIndex
{
    if (targetIndex >= _totalItemsCount) {
        if (self.infiniteLoop) {
            targetIndex = _totalItemsCount * 0.5;
            [_flowLayout scrollToPage:targetIndex animated:NO];
        }
        return;
    }
    [_flowLayout scrollToPage:targetIndex animated:YES];
}

- (NSInteger)pageControlIndexWithCurrentCellIndex:(NSInteger)index
{
    return index % self.imagePathsGroup.count;
}

#pragma mark - life circles

- (void)layoutSubviews
{
    self.delegate = self.delegate;
    
    [super layoutSubviews];
    
    if (CGSizeEqualToSize(_itemSize, CGSizeZero)) {
        if (_flowLayout.scrollDirection == UICollectionViewScrollDirectionHorizontal) {
            _flowLayout.itemSize = CGSizeMake(self.frame.size.width - _flowLayout.minimumLineSpacing * 2, self.frame.size.height);
        } else {
            _flowLayout.itemSize = CGSizeMake(self.frame.size.width, self.frame.size.height - _flowLayout.minimumLineSpacing * 2);
        }
    }
    
    _mainView.frame = self.bounds;
    BOOL needScroll = NO;
    if (_flowLayout.scrollDirection == UICollectionViewScrollDirectionHorizontal) {
        needScroll = _mainView.contentOffset.x <= 0;
    } else {
        needScroll = _mainView.contentOffset.y <= 0;
    }
    if (needScroll &&  _totalItemsCount) {
        int targetIndex = 0;
        if (self.infiniteLoop) {
            targetIndex = _totalItemsCount * 0.5;
        }else{
            targetIndex = 0;
        }
        [_flowLayout scrollToPage:targetIndex animated:NO];
    }
    
    CGSize size = CGSizeZero;
    if ([self.pageControl isKindOfClass:[FWPageControl class]]) {
        FWPageControl *pageControl = (FWPageControl *)_pageControl;
        if (!(self.pageDotImage && self.currentPageDotImage && CGSizeEqualToSize(CGSizeMake(10, 10), self.pageControlDotSize))) {
            pageControl.dotSize = self.pageControlDotSize;
        }
        size = [pageControl sizeForNumberOfPages:self.imagePathsGroup.count];
    } else {
        size = CGSizeMake(self.imagePathsGroup.count * self.pageControlDotSize.width * 1.5, self.pageControlDotSize.height);
    }
    CGFloat x = (self.frame.size.width - size.width) * 0.5;
    if (self.pageControlAlignment == FWBannerViewPageControlAlignmentRight) {
        x = self.mainView.frame.size.width - size.width - 10;
    }
    CGFloat y = self.mainView.frame.size.height - size.height - 10;
    
    if ([self.pageControl isKindOfClass:[FWPageControl class]]) {
        FWPageControl *pageControl = (FWPageControl *)_pageControl;
        [pageControl sizeToFit];
    }
    
    CGRect pageControlFrame = CGRectMake(x, y, size.width, size.height);
    pageControlFrame.origin.y -= self.pageControlBottomOffset;
    pageControlFrame.origin.x -= self.pageControlRightOffset;
    self.pageControl.frame = pageControlFrame;
    self.pageControl.hidden = !_showPageControl;
}

//解决当父View释放时，当前视图因为被Timer强引用而不能释放的问题
- (void)willMoveToSuperview:(UIView *)newSuperview
{
    if (!newSuperview) {
        [self invalidateTimer];
    }
}

//解决当timer释放后 回调scrollViewDidScroll时访问野指针导致崩溃
- (void)dealloc {
    _mainView.delegate = nil;
    _mainView.dataSource = nil;
}

#pragma mark - public actions

- (void)adjustWhenControllerViewWillAppear
{
    NSInteger targetIndex = [_flowLayout currentPage];
    if (targetIndex < _totalItemsCount) {
        [_flowLayout scrollToPage:targetIndex animated:NO];
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _totalItemsCount;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    FWBannerViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:FWBannerViewCellID forIndexPath:indexPath];
    
    long itemIndex = [self pageControlIndexWithCurrentCellIndex:indexPath.item];
    
    if ([self.delegate respondsToSelector:@selector(bannerView:customCell:forIndex:)] &&
        [self.delegate respondsToSelector:@selector(customCellClassForBannerView:)] && [self.delegate customCellClassForBannerView:self]) {
        [self.delegate bannerView:self customCell:cell forIndex:itemIndex];
        return cell;
    }else if ([self.delegate respondsToSelector:@selector(bannerView:customCell:forIndex:)] &&
              [self.delegate respondsToSelector:@selector(customCellNibForBannerView:)] && [self.delegate customCellNibForBannerView:self]) {
        [self.delegate bannerView:self customCell:cell forIndex:itemIndex];
        return cell;
    }
    
    NSString *imagePath = self.imagePathsGroup[itemIndex];
    
    if (!self.onlyDisplayText && [imagePath isKindOfClass:[NSString class]]) {
        if ([imagePath hasPrefix:@"http"]) {
            [cell.imageView fwSetImageWithURL:[NSURL URLWithString:imagePath] placeholderImage:self.placeholderImage];
        } else {
            UIImage *image = nil;
            if ([imagePath hasSuffix:@".gif"]) {
                image = [UIImage fwGifImageWithFile:imagePath];
                if (!image) image = [UIImage fwGifImageWithName:[imagePath substringToIndex:imagePath.length - 4]];
            } else {
                image = [UIImage imageNamed:imagePath];
                if (!image) image = [UIImage fwImageWithFile:imagePath];
            }
            cell.imageView.fwImage = image ?: self.placeholderImage;
        }
    } else if (!self.onlyDisplayText && [imagePath isKindOfClass:[UIImage class]]) {
        cell.imageView.fwImage = (UIImage *)imagePath;
    }
    
    if (_titlesGroup.count && itemIndex < _titlesGroup.count) {
        cell.title = _titlesGroup[itemIndex];
    }
    
    if ([self.delegate respondsToSelector:@selector(bannerView:customCell:forIndex:)]) {
        [self.delegate bannerView:self customCell:cell forIndex:itemIndex];
    }
    
    if (!cell.hasConfigured) {
        cell.titleLabelBackgroundColor = self.titleLabelBackgroundColor;
        cell.titleLabelHeight = self.titleLabelHeight;
        cell.titleLabelTextAlignment = self.titleLabelTextAlignment;
        cell.titleLabelTextColor = self.titleLabelTextColor;
        cell.titleLabelTextFont = self.titleLabelTextFont;
        cell.contentViewInset = self.contentViewInset;
        cell.contentViewCornerRadius = self.contentViewCornerRadius;
        cell.hasConfigured = YES;
        cell.imageView.contentMode = self.bannerImageViewContentMode;
        cell.onlyDisplayText = self.onlyDisplayText;
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.delegate respondsToSelector:@selector(bannerView:didSelectItemAtIndex:)]) {
        [self.delegate bannerView:self didSelectItemAtIndex:[self pageControlIndexWithCurrentCellIndex:indexPath.item]];
    }
    if (self.clickItemOperationBlock) {
        self.clickItemOperationBlock([self pageControlIndexWithCurrentCellIndex:indexPath.item]);
    }
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (!self.imagePathsGroup.count) return; // 解决清除timer时偶尔会出现的问题
    NSInteger itemIndex = [_flowLayout currentPage];
    NSInteger indexOnPageControl = [self pageControlIndexWithCurrentCellIndex:itemIndex];
    
    if ([self.pageControl isKindOfClass:[FWPageControl class]]) {
        FWPageControl *pageControl = (FWPageControl *)_pageControl;
        pageControl.currentPage = indexOnPageControl;
    } else {
        UIPageControl *pageControl = (UIPageControl *)_pageControl;
        pageControl.currentPage = indexOnPageControl;
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (self.autoScroll) {
        [self invalidateTimer];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (self.autoScroll) {
        [self setupTimer];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self scrollViewDidEndScrollingAnimation:self.mainView];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    if (!self.imagePathsGroup.count) return; // 解决清除timer时偶尔会出现的问题
    NSInteger itemIndex = [_flowLayout currentPage];
    NSInteger indexOnPageControl = [self pageControlIndexWithCurrentCellIndex:itemIndex];
    
    if ([self.delegate respondsToSelector:@selector(bannerView:didScrollToIndex:)]) {
        [self.delegate bannerView:self didScrollToIndex:indexOnPageControl];
    } else if (self.itemDidScrollOperationBlock) {
        self.itemDidScrollOperationBlock(indexOnPageControl);
    }
}

- (void)makeScrollViewScrollToIndex:(NSInteger)index{
    if (self.autoScroll) {
        [self invalidateTimer];
    }
    if (0 == _totalItemsCount) return;
    
    [self scrollToIndex:(NSInteger)(_totalItemsCount * 0.5 + index)];
    
    if (self.autoScroll) {
        [self setupTimer];
    }
}

@end

#pragma mark - FWBannerViewCell

@implementation FWBannerViewCell
{
    __weak UIView *_insetView;
    __weak UILabel *_titleLabel;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setupInsetView];
        [self setupImageView];
        [self setupTitleLabel];
    }
    return self;
}

- (void)setTitleLabelBackgroundColor:(UIColor *)titleLabelBackgroundColor
{
    _titleLabelBackgroundColor = titleLabelBackgroundColor;
    _titleLabel.backgroundColor = titleLabelBackgroundColor;
}

- (void)setTitleLabelTextColor:(UIColor *)titleLabelTextColor
{
    _titleLabelTextColor = titleLabelTextColor;
    _titleLabel.textColor = titleLabelTextColor;
}

- (void)setTitleLabelTextFont:(UIFont *)titleLabelTextFont
{
    _titleLabelTextFont = titleLabelTextFont;
    _titleLabel.font = titleLabelTextFont;
}

- (void)setupInsetView
{
    UIView *insetView = [[UIView alloc] init];
    _insetView = insetView;
    insetView.layer.masksToBounds = YES;
    [self.contentView addSubview:insetView];
}

- (void)setupImageView
{
    UIImageView *imageView = [[UIImageView alloc] init];
    _imageView = imageView;
    imageView.layer.masksToBounds = YES;
    [_insetView addSubview:imageView];
}

- (void)setupTitleLabel
{
    UILabel *titleLabel = [[UILabel alloc] init];
    _titleLabel = titleLabel;
    _titleLabel.hidden = YES;
    [_insetView addSubview:titleLabel];
}

- (void)setTitle:(NSString *)title
{
    _title = [title copy];
    _titleLabel.text = [NSString stringWithFormat:@"   %@", title];
    if (_titleLabel.hidden) {
        _titleLabel.hidden = NO;
    }
}

-(void)setTitleLabelTextAlignment:(NSTextAlignment)titleLabelTextAlignment
{
    _titleLabelTextAlignment = titleLabelTextAlignment;
    _titleLabel.textAlignment = titleLabelTextAlignment;
}

- (void)setContentViewCornerRadius:(CGFloat)contentViewCornerRadius
{
    _contentViewCornerRadius = contentViewCornerRadius;
    _insetView.layer.cornerRadius = contentViewCornerRadius;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect frame = CGRectMake(self.contentViewInset.left, self.contentViewInset.top, self.bounds.size.width - self.contentViewInset.left - self.contentViewInset.right, self.bounds.size.height - self.contentViewInset.top - self.contentViewInset.bottom);
    _insetView.frame = frame;
    
    if (self.onlyDisplayText) {
        _titleLabel.frame = _insetView.bounds;
    } else {
        _imageView.frame = _insetView.bounds;
        _titleLabel.frame = CGRectMake(0, _insetView.frame.size.height - _titleLabelHeight, _insetView.frame.size.width, _titleLabelHeight);
    }
}

@end
