/*!
 @header     FWTabBarController.m
 @indexgroup FWFramework
 @brief      FWTabBarController
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/12/21
 */

#import "FWTabBarController.h"
#import "FWAdaptive.h"
#import "FWTheme.h"
#import <objc/runtime.h>

#pragma mark - FWTabBarController

@interface FWTabBarController () {
    UIView *_contentView;
}

@property (nonatomic, readwrite) FWTabBar *tabBar;

- (NSInteger)indexForViewController:(UIViewController *)viewController;

@end

@implementation UIViewController (FWTabBarController)

- (FWTabBarController *)fwTabBarController {
    FWTabBarController *tabBarController = objc_getAssociatedObject(self, @selector(fwTabBarController));
    if (!tabBarController && self.parentViewController) {
        tabBarController = [self.parentViewController fwTabBarController];
    }
    return tabBarController;
}

- (void)setFwTabBarController:(FWTabBarController *)tabBarController {
    objc_setAssociatedObject(self, @selector(fwTabBarController), tabBarController, OBJC_ASSOCIATION_ASSIGN);
}

- (FWTabBarItem *)fwTabBarItem {
    FWTabBarController *tabBarController = [self fwTabBarController];
    NSInteger index = [tabBarController indexForViewController:self];
    return [[[tabBarController tabBar] items] objectAtIndex:index];
}

- (void)setFwTabBarItem:(FWTabBarItem *)tabBarItem {
    FWTabBarController *tabBarController = [self fwTabBarController];
    if (!tabBarController) return;
    
    FWTabBar *tabBar = [tabBarController tabBar];
    NSInteger index = [tabBarController indexForViewController:self];
    NSMutableArray *tabBarItems = [[NSMutableArray alloc] initWithArray:[tabBar items]];
    [tabBarItems replaceObjectAtIndex:index withObject:tabBarItem];
    [tabBar setItems:tabBarItems];
}

@end

@implementation FWTabBarController

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:[self contentView]];
    [self.view addSubview:[self tabBar]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self setSelectedIndex:[self selectedIndex]];
}

-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    CGSize viewSize = self.view.bounds.size;
    CGFloat tabBarStartingY = viewSize.height;
    CGFloat contentViewHeight = viewSize.height;
    CGFloat tabBarHeight = CGRectGetHeight([[self tabBar] frame]);
    if (!tabBarHeight) {
        tabBarHeight = FWTabBarHeight;
    }

    if (!self.tabBarHidden) {
        tabBarStartingY = viewSize.height - tabBarHeight;
        if (![[self tabBar] isTranslucent]) {
            contentViewHeight -= ([[self tabBar] minimumContentHeight] ?: tabBarHeight);
        }
    }

    [[self tabBar] setFrame:CGRectMake(0, tabBarStartingY, viewSize.width, tabBarHeight)];
    [[self contentView] setFrame:CGRectMake(0, 0, viewSize.width, contentViewHeight)];
    [[[self selectedViewController] view] setFrame:[[self contentView] bounds]];
}

- (BOOL)prefersStatusBarHidden {
    return self.selectedViewController.prefersStatusBarHidden;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return self.selectedViewController.preferredStatusBarStyle;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return self.selectedViewController.preferredStatusBarUpdateAnimation;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    UIInterfaceOrientationMask orientationMask = UIInterfaceOrientationMaskAll;
    for (UIViewController *viewController in [self viewControllers]) {
        if (![viewController respondsToSelector:@selector(supportedInterfaceOrientations)]) {
            return UIInterfaceOrientationMaskPortrait;
        }
        
        UIInterfaceOrientationMask supportedOrientations = [viewController supportedInterfaceOrientations];
        
        if (orientationMask > supportedOrientations) {
            orientationMask = supportedOrientations;
        }
    }
    return orientationMask;
}

#pragma mark - Methods

- (UIViewController *)selectedViewController {
    return [[self viewControllers] objectAtIndex:[self selectedIndex]];
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex {
    if (selectedIndex >= self.viewControllers.count) return;
    
    if ([self selectedViewController]) {
        [[self selectedViewController] willMoveToParentViewController:nil];
        [[[self selectedViewController] view] removeFromSuperview];
        [[self selectedViewController] removeFromParentViewController];
    }
    
    _selectedIndex = selectedIndex;
    [[self tabBar] setSelectedItem:[[self tabBar] items][selectedIndex]];
    
    [self setSelectedViewController:[[self viewControllers] objectAtIndex:selectedIndex]];
    [self addChildViewController:[self selectedViewController]];
    [[[self selectedViewController] view] setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [[self contentView] addSubview:[[self selectedViewController] view]];
    [[self selectedViewController] didMoveToParentViewController:self];

    [self.view setNeedsLayout];
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)setViewControllers:(NSArray<UIViewController *> *)viewControllers {
    if (_viewControllers && _viewControllers.count) {
        for (UIViewController *viewController in _viewControllers) {
            [viewController willMoveToParentViewController:nil];
            [viewController.view removeFromSuperview];
            [viewController removeFromParentViewController];
        }
    }

    if (viewControllers && [viewControllers isKindOfClass:[NSArray class]]) {
        _viewControllers = [viewControllers copy];
        
        NSMutableArray *tabBarItems = [[NSMutableArray alloc] init];
        
        for (UIViewController *viewController in viewControllers) {
            FWTabBarItem *tabBarItem = [[FWTabBarItem alloc] init];
            [tabBarItem setTitle:viewController.title];
            [tabBarItems addObject:tabBarItem];
            [viewController setFwTabBarController:self];
        }
        
        [[self tabBar] setItems:tabBarItems];
    } else {
        for (UIViewController *viewController in _viewControllers) {
            [viewController setFwTabBarController:nil];
        }
        
        _viewControllers = nil;
    }
}

- (NSInteger)indexForViewController:(UIViewController *)viewController {
    UIViewController *searchedController = viewController;
    while (searchedController.parentViewController != nil && searchedController.parentViewController != self) {
        searchedController = searchedController.parentViewController;
    }
    return [[self viewControllers] indexOfObject:searchedController];
}

- (FWTabBar *)tabBar {
    if (!_tabBar) {
        _tabBar = [[FWTabBar alloc] init];
        [_tabBar setBackgroundColor:[UIColor clearColor]];
        [_tabBar setAutoresizingMask:(UIViewAutoresizingFlexibleWidth|
                                      UIViewAutoresizingFlexibleTopMargin|
                                      UIViewAutoresizingFlexibleLeftMargin|
                                      UIViewAutoresizingFlexibleRightMargin|
                                      UIViewAutoresizingFlexibleBottomMargin)];
        [_tabBar setDelegate:self];
    }
    return _tabBar;
}

- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [[UIView alloc] init];
        [_contentView setBackgroundColor:[UIColor whiteColor]];
        [_contentView setAutoresizingMask:(UIViewAutoresizingFlexibleWidth|
                                           UIViewAutoresizingFlexibleHeight)];
    }
    return _contentView;
}

- (void)setTabBarHidden:(BOOL)hidden animated:(BOOL)animated {
    [self.view layoutIfNeeded];

    _tabBarHidden = hidden;
    
    [self.view setNeedsLayout];

    if (!_tabBarHidden) {
        [[self tabBar] setHidden:NO];
    }

    [UIView animateWithDuration:(animated ? 0.24 : 0) animations:^{
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished){
        if (self.tabBarHidden) {
            [[self tabBar] setHidden:YES];
        }
    }];
}

- (void)setTabBarHidden:(BOOL)hidden {
    [self setTabBarHidden:hidden animated:NO];
}

#pragma mark - FWTabBarDelegate

- (BOOL)tabBar:(FWTabBar *)tabBar shouldSelectItemAtIndex:(NSInteger)index {
    if ([[self delegate] respondsToSelector:@selector(tabBarController:shouldSelectViewController:)]) {
        if (![[self delegate] tabBarController:self shouldSelectViewController:[self viewControllers][index]]) {
            return NO;
        }
    }
    
    if ([self selectedViewController] == [self viewControllers][index]) {
        if ([[self delegate] respondsToSelector:@selector(tabBarController:didSelectItemAtIndex:)]) {
            [[self delegate] tabBarController:self didSelectItemAtIndex:index];
        }
        
        if ([[self selectedViewController] isKindOfClass:[UINavigationController class]]) {
            UINavigationController *selectedController = (UINavigationController *)[self selectedViewController];
            
            if ([selectedController topViewController] != [selectedController viewControllers][0]) {
                [selectedController popToRootViewControllerAnimated:YES];
            }
        }
        
        return NO;
    }
    
    return YES;
}

- (void)tabBar:(FWTabBar *)tabBar didSelectItemAtIndex:(NSInteger)index {
    if (index < 0 || index >= [[self viewControllers] count]) {
        return;
    }
    
    [self setSelectedIndex:index];
    
    if ([[self delegate] respondsToSelector:@selector(tabBarController:didSelectViewController:)]) {
        [[self delegate] tabBarController:self didSelectViewController:[self viewControllers][index]];
    }
}

@end

#pragma mark - FWTabBar

@interface FWTabBar ()

@property (nonatomic) CGFloat itemWidth;
@property (nonatomic) UIView *backgroundView;

@end

@implementation FWTabBar

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInitialization];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInitialization];
    }
    return self;
}

- (id)init {
    return [self initWithFrame:CGRectZero];
}

- (void)commonInitialization {
    _contentEdgeInsets = UIEdgeInsetsMake(0, 0, UIScreen.fwSafeAreaInsets.bottom, 0);
    _backgroundView = [[UIView alloc] init];
    [self addSubview:_backgroundView];
    
    [self setTranslucent:NO];
}

- (void)layoutSubviews {
    CGSize frameSize = self.frame.size;
    CGFloat minimumContentHeight = [self minimumContentHeight];
    
    [[self backgroundView] setFrame:CGRectMake(0, frameSize.height - minimumContentHeight,
                                            frameSize.width, frameSize.height)];
    
    [self setItemWidth:roundf((frameSize.width - [self contentEdgeInsets].left -
                               [self contentEdgeInsets].right) / [[self items] count])];
    
    NSInteger index = 0;
    
    for (FWTabBarItem *item in [self items]) {
        CGFloat itemHeight = [item itemHeight];
        
        if (!itemHeight) {
            itemHeight = frameSize.height;
        }
        
        [item setFrame:CGRectMake(self.contentEdgeInsets.left + (index * self.itemWidth),
                                  roundf(frameSize.height - itemHeight) - self.contentEdgeInsets.top,
                                  self.itemWidth, itemHeight - self.contentEdgeInsets.bottom)];
        [item setNeedsDisplay];
        
        index++;
    }
}

#pragma mark - Configuration

- (void)setItemWidth:(CGFloat)itemWidth {
    if (itemWidth > 0) {
        _itemWidth = itemWidth;
    }
}

- (void)setItems:(NSArray<FWTabBarItem *> *)items {
    for (FWTabBarItem *item in _items) {
        [item removeFromSuperview];
    }
    
    _items = [items copy];
    for (FWTabBarItem *item in _items) {
        [item addTarget:self action:@selector(tabBarItemWasSelected:) forControlEvents:UIControlEventTouchDown];
        [self addSubview:item];
    }
}

- (void)setHeight:(CGFloat)height {
    [self setFrame:CGRectMake(CGRectGetMinX(self.frame), CGRectGetMinY(self.frame),
                              CGRectGetWidth(self.frame), height)];
}

- (CGFloat)minimumContentHeight {
    CGFloat minimumTabBarContentHeight = CGRectGetHeight([self frame]);
    
    for (FWTabBarItem *item in [self items]) {
        CGFloat itemHeight = [item itemHeight];
        if (itemHeight && (itemHeight < minimumTabBarContentHeight)) {
            minimumTabBarContentHeight = itemHeight;
        }
    }
    
    return minimumTabBarContentHeight;
}

#pragma mark - Item selection

- (void)tabBarItemWasSelected:(id)sender {
    if ([[self delegate] respondsToSelector:@selector(tabBar:shouldSelectItemAtIndex:)]) {
        NSInteger index = [self.items indexOfObject:sender];
        if (![[self delegate] tabBar:self shouldSelectItemAtIndex:index]) {
            return;
        }
    }
    
    [self setSelectedItem:sender];
    
    if ([[self delegate] respondsToSelector:@selector(tabBar:didSelectItemAtIndex:)]) {
        NSInteger index = [self.items indexOfObject:self.selectedItem];
        [[self delegate] tabBar:self didSelectItemAtIndex:index];
    }
}

- (void)setSelectedItem:(FWTabBarItem *)selectedItem {
    if (selectedItem == _selectedItem) {
        return;
    }
    [_selectedItem setSelected:NO];
    
    _selectedItem = selectedItem;
    [_selectedItem setSelected:YES];
}

#pragma mark - Translucency

- (void)setTranslucent:(BOOL)translucent {
    _translucent = translucent;
    
    CGFloat alpha = (translucent ? 0.9 : 1.0);
    
    [_backgroundView setBackgroundColor:[UIColor fwThemeLight:[UIColor colorWithRed:245/255.0
                                                                              green:245/255.0
                                                                               blue:245/255.0
                                                                              alpha:alpha]
                                                         dark:[UIColor colorWithRed:18/255.0
                                                                              green:18/255.0
                                                                               blue:18/255.0
                                                                              alpha:alpha]]];
}

#pragma mark - Accessibility

- (BOOL)isAccessibilityElement{
    return NO;
}

- (NSInteger)accessibilityElementCount{
    return self.items.count;
}

- (id)accessibilityElementAtIndex:(NSInteger)index{
    return self.items[index];
}

- (NSInteger)indexOfAccessibilityElement:(id)element{
    return [self.items indexOfObject:element];
}

@end

#pragma mark - FWTabBarItem

@interface FWTabBarItem () {
    NSString *_title;
    UIOffset _imagePositionAdjustment;
    NSDictionary *_unselectedTitleAttributes;
    NSDictionary *_selectedTitleAttributes;
}

@property UIImage *unselectedBackgroundImage;
@property UIImage *selectedBackgroundImage;
@property UIImage *unselectedImage;
@property UIImage *selectedImage;

@end

@implementation FWTabBarItem

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInitialization];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInitialization];
    }
    return self;
}

- (id)init {
    return [self initWithFrame:CGRectZero];
}

- (void)commonInitialization {
    [self setBackgroundColor:[UIColor clearColor]];
    
    _title = @"";
    _titlePositionAdjustment = UIOffsetZero;
    _unselectedTitleAttributes = @{
        NSFontAttributeName: [UIFont systemFontOfSize:12],
        NSForegroundColorAttributeName: [UIColor colorWithRed:146/255.0
                                                        green:146/255.0
                                                         blue:146/255.0
                                                        alpha:1.0],
    };
    _selectedTitleAttributes = @{
        NSFontAttributeName: [UIFont systemFontOfSize:12],
        NSForegroundColorAttributeName: [UIColor fwThemeLight:[UIColor blackColor]
                                                         dark:[UIColor whiteColor]],
    };
    _badgeBackgroundColor = [UIColor redColor];
    _badgeTextColor = [UIColor whiteColor];
    _badgeTextFont = [UIFont systemFontOfSize:12];
    _badgePositionAdjustment = UIOffsetZero;
}

- (void)drawRect:(CGRect)rect {
    CGSize frameSize = self.frame.size;
    CGSize imageSize = CGSizeZero;
    CGSize titleSize = CGSizeZero;
    NSDictionary *titleAttributes = nil;
    UIImage *backgroundImage = nil;
    UIImage *image = nil;
    CGFloat imageStartingY = 0.0f;
    
    if ([self isSelected]) {
        image = [self selectedImage];
        backgroundImage = [self selectedBackgroundImage];
        titleAttributes = [self selectedTitleAttributes];
        
        if (!titleAttributes) {
            titleAttributes = [self unselectedTitleAttributes];
        }
    } else {
        image = [self unselectedImage];
        backgroundImage = [self unselectedBackgroundImage];
        titleAttributes = [self unselectedTitleAttributes];
    }
    
    imageSize = [image size];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    
    [backgroundImage drawInRect:self.bounds];
    
    if (![_title length]) {
        [image drawInRect:CGRectMake(roundf(frameSize.width / 2 - imageSize.width / 2) +
                                     _imagePositionAdjustment.horizontal,
                                     roundf(frameSize.height / 2 - imageSize.height / 2) +
                                     _imagePositionAdjustment.vertical,
                                     imageSize.width, imageSize.height)];
    } else {
        titleSize = [_title boundingRectWithSize:CGSizeMake(frameSize.width, 20)
                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      attributes:titleAttributes
                                         context:nil].size;
        
        imageStartingY = roundf((frameSize.height - imageSize.height - titleSize.height) / 2);
        
        [image drawInRect:CGRectMake(roundf(frameSize.width / 2 - imageSize.width / 2) +
                                     _imagePositionAdjustment.horizontal,
                                     imageStartingY + _imagePositionAdjustment.vertical,
                                     imageSize.width, imageSize.height)];
        
        CGContextSetFillColorWithColor(context, [titleAttributes[NSForegroundColorAttributeName] CGColor]);
        
        [_title drawInRect:CGRectMake(roundf(frameSize.width / 2 - titleSize.width / 2) +
                                      _titlePositionAdjustment.horizontal,
                                      imageStartingY + imageSize.height + _titlePositionAdjustment.vertical,
                                      titleSize.width, titleSize.height)
            withAttributes:titleAttributes];
    }
    
    if ([self badgeDot] || [[self badgeValue] length] > 0) {
        CGSize badgeSize = CGSizeMake(6, 6);
        if (![self badgeDot]) {
            badgeSize = [_badgeValue boundingRectWithSize:CGSizeMake(frameSize.width, 20)
                                                  options:NSStringDrawingUsesLineFragmentOrigin
                                               attributes:@{NSFontAttributeName: [self badgeTextFont]}
                                                  context:nil].size;
        }
        
        CGFloat textOffset = 2.0f;
        
        if (badgeSize.width < badgeSize.height) {
            badgeSize = CGSizeMake(badgeSize.height, badgeSize.height);
        }
        
        CGRect badgeBackgroundFrame = CGRectMake(roundf(frameSize.width / 2 + (image.size.width / 2) * 0.9) +
                                                 [self badgePositionAdjustment].horizontal,
                                                 textOffset + [self badgePositionAdjustment].vertical,
                                                 badgeSize.width + 2 * textOffset, badgeSize.height + 2 * textOffset);
        
        if ([self badgeBackgroundColor]) {
            CGContextSetFillColorWithColor(context, [[self badgeBackgroundColor] CGColor]);
            
            CGContextFillEllipseInRect(context, badgeBackgroundFrame);
        } else if ([self badgeBackgroundImage]) {
            [[self badgeBackgroundImage] drawInRect:badgeBackgroundFrame];
        }
        
        if (![self badgeDot]) {
            CGContextSetFillColorWithColor(context, [[self badgeTextColor] CGColor]);
            
            NSMutableParagraphStyle *badgeTextStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
            [badgeTextStyle setLineBreakMode:NSLineBreakByWordWrapping];
            [badgeTextStyle setAlignment:NSTextAlignmentCenter];
            
            NSDictionary *badgeTextAttributes = @{
                                                  NSFontAttributeName: [self badgeTextFont],
                                                  NSForegroundColorAttributeName: [self badgeTextColor],
                                                  NSParagraphStyleAttributeName: badgeTextStyle,
                                                  };
            
            [[self badgeValue] drawInRect:CGRectMake(CGRectGetMinX(badgeBackgroundFrame) + textOffset,
                                                     CGRectGetMinY(badgeBackgroundFrame) + textOffset,
                                                     badgeSize.width, badgeSize.height)
                withAttributes:badgeTextAttributes];
        }
    }
    
    CGContextRestoreGState(context);
}

#pragma mark - Image configuration

- (UIImage *)finishedSelectedImage {
    return [self selectedImage];
}

- (UIImage *)finishedUnselectedImage {
    return [self unselectedImage];
}

- (void)setFinishedSelectedImage:(UIImage *)selectedImage withFinishedUnselectedImage:(UIImage *)unselectedImage {
    if (selectedImage && (selectedImage != [self selectedImage])) {
        [self setSelectedImage:selectedImage];
    }
    
    if (unselectedImage && (unselectedImage != [self unselectedImage])) {
        [self setUnselectedImage:unselectedImage];
    }
}

- (void)setBadgeValue:(NSString *)badgeValue {
    _badgeValue = badgeValue;
    
    [self setNeedsDisplay];
}

- (void)setBadgeDot:(BOOL)badgeDot {
    _badgeDot = badgeDot;
    
    [self setNeedsDisplay];
}

#pragma mark - Background configuration

- (UIImage *)backgroundSelectedImage {
    return [self selectedBackgroundImage];
}

- (UIImage *)backgroundUnselectedImage {
    return [self unselectedBackgroundImage];
}

- (void)setBackgroundSelectedImage:(UIImage *)selectedImage withUnselectedImage:(UIImage *)unselectedImage {
    if (selectedImage && (selectedImage != [self selectedBackgroundImage])) {
        [self setSelectedBackgroundImage:selectedImage];
    }
    
    if (unselectedImage && (unselectedImage != [self unselectedBackgroundImage])) {
        [self setUnselectedBackgroundImage:unselectedImage];
    }
}

#pragma mark - Accessibility

- (NSString *)accessibilityLabel{
    return @"tabbarItem";
}

- (BOOL)isAccessibilityElement
{
    return YES;
}

@end
