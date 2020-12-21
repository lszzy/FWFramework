/*!
 @header     FWTabBarController.h
 @indexgroup FWFramework
 @brief      FWTabBarController
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/12/21
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWTabBarController

@class FWTabBar, FWTabBarItem, FWTabBarController;

@protocol FWTabBarDelegate <NSObject>

- (BOOL)tabBar:(FWTabBar *)tabBar shouldSelectItemAtIndex:(NSInteger)index;

- (void)tabBar:(FWTabBar *)tabBar didSelectItemAtIndex:(NSInteger)index;

@end

@protocol FWTabBarControllerDelegate <NSObject>

@optional

- (BOOL)tabBarController:(FWTabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController;

- (void)tabBarController:(FWTabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController;

- (void)tabBarController:(FWTabBarController *)tabBarController didSelectItemAtIndex:(NSInteger)index;

@end

/*!
 @brief 自定义TabBar控制器，支持嵌入UINavigationController和设置Badge提醒灯
 
 @see https://github.com/robbdimitrov/RDVTabBarController
 */
@interface FWTabBarController : UIViewController <FWTabBarDelegate>

@property (nonatomic, weak, nullable) id<FWTabBarControllerDelegate> delegate;

@property (nonatomic, copy, nullable) IBOutletCollection(UIViewController) NSArray *viewControllers;

@property (nonatomic, readonly) FWTabBar *tabBar;

@property (nonatomic, weak, nullable) UIViewController *selectedViewController;

@property (nonatomic) NSUInteger selectedIndex;

@property (nonatomic, getter=isTabBarHidden) BOOL tabBarHidden;

- (void)setTabBarHidden:(BOOL)hidden animated:(BOOL)animated;

@end

@interface UIViewController (FWTabBarController)

@property(nonatomic, nullable) FWTabBarItem *fwTabBarItem;

@property(nonatomic, readonly, nullable) FWTabBarController *fwTabBarController;

@end

#pragma mark - FWTabBar

@interface FWTabBar : UIView

@property (nonatomic, weak, nullable) id <FWTabBarDelegate> delegate;

@property (nonatomic, copy, nullable) NSArray *items;

@property (nonatomic, weak, nullable) FWTabBarItem *selectedItem;

@property (nonatomic, readonly) UIView *backgroundView;

@property UIEdgeInsets contentEdgeInsets;

- (void)setHeight:(CGFloat)height;

- (CGFloat)minimumContentHeight;

@property (nonatomic, getter=isTranslucent) BOOL translucent;

@end

#pragma mark - FWTabBarItem

@interface FWTabBarItem : UIControl

@property CGFloat itemHeight;

#pragma mark - Title configuration

@property (nonatomic, copy, nullable) NSString *title;

@property (nonatomic) UIOffset titlePositionAdjustment;

@property (copy, nullable) NSDictionary *unselectedTitleAttributes;

@property (copy, nullable) NSDictionary *selectedTitleAttributes;

#pragma mark - Image configuration

@property (nonatomic) UIOffset imagePositionAdjustment;

- (nullable UIImage *)finishedSelectedImage;

- (nullable UIImage *)finishedUnselectedImage;

- (void)setFinishedSelectedImage:(nullable UIImage *)selectedImage withFinishedUnselectedImage:(nullable UIImage *)unselectedImage;

#pragma mark - Background configuration

- (nullable UIImage *)backgroundSelectedImage;

- (nullable UIImage *)backgroundUnselectedImage;

- (void)setBackgroundSelectedImage:(nullable UIImage *)selectedImage withUnselectedImage:(nullable UIImage *)unselectedImage;

#pragma mark - Badge configuration

@property (nonatomic, copy, nullable) NSString *badgeValue;

@property (strong, nullable) UIImage *badgeBackgroundImage;

@property (strong) UIColor *badgeBackgroundColor;

@property (strong) UIColor *badgeTextColor;

@property (nonatomic) UIOffset badgePositionAdjustment;

@property (nonatomic) UIFont *badgeTextFont;

@end

NS_ASSUME_NONNULL_END
