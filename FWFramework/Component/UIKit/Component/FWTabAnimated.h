/*!
 @header     FWTabAnimated.h
 @indexgroup FWFramework
 @brief      FWTabAnimated
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/12/13
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 这个文件存放的是`热插拔`的动画，集成不需要关心的文件
 你也可以使用该文件的方法，为你的工程添加相应的动画
 */

typedef enum : NSUInteger {
    FWTabShimmerDirectionToRight = 0,    // 从左往右
    FWTabShimmerDirectionToLeft,         // 从右往左
} FWTabShimmerDirection;                 // 闪光灯方向

typedef enum : NSUInteger {
    FWTabShimmerPropertyStartPoint = 0,
    FWTabShimmerPropertyEndPoint,
} FWTabShimmerProperty;

typedef struct {
    CGPoint startValue;
    CGPoint endValue;
} FWTabShimmerTransition;

@interface FWTabAnimationMethod : NSObject

/**
 伸缩动画
 
 @param duration 伸缩（一来一回）时长
 @param toValue 伸缩的比例
 @return 动画对象
 */
+ (CABasicAnimation *)scaleXAnimationDuration:(CGFloat)duration
                                      toValue:(CGFloat)toValue;

/**
 CALayer加入闪光灯动画

 @param layer 目标layer
 @param duration 一次闪烁时长
 @param key 指定key
 @param direction 闪烁方向
 */
+ (void)addShimmerAnimationToLayer:(CALayer *)layer
                          duration:(CGFloat)duration
                               key:(NSString *)key
                         direction:(FWTabShimmerDirection)direction;

/**
 UIView加入呼吸灯动画

 @param view 目标view
 @param duration 单次呼吸时长
 @param key 指定key
 */
+ (void)addAlphaAnimation:(UIView *)view
                 duration:(CGFloat)duration
                      key:(NSString *)key;

/**
 CALayer加入豆瓣下坠效果，该方法需要配合计算使用。

 @param layer 目标layer
 @param index 所处集合下标
 @param duration 时长
 @param count 下坠总数
 @param stayTime 停留时间
 @param deepColor 变色值
 @param key 指定key
 */
+ (void)addDropAnimation:(CALayer *)layer
                   index:(NSInteger)index
                duration:(CGFloat)duration
                   count:(NSInteger)count
                stayTime:(CGFloat)stayTime
               deepColor:(UIColor *)deepColor
                     key:(NSString *)key;

/**
 UIView加入呼吸灯动画

 @param view 目标view
 */
+ (void)addEaseOutAnimation:(UIView *)view;


@end

@class FWTabComponentManager, FWTabTableAnimated, FWTabCollectionAnimated;

extern NSString * const FWTabCacheManagerFolderName;

@interface FWTabAnimatedCacheManager : NSObject

// 当前App版本
@property (nonatomic, copy, readonly) NSString *currentSystemVersion;
// 本地的缓存
@property (nonatomic, strong, readonly) NSMutableArray *cacheModelArray;
// 内存中的骨架屏管理单元
@property (nonatomic, strong, readonly) NSMutableDictionary *cacheManagerDict;

/**
 * 加载该用户常点击的骨架屏plist文件到内存
 * 按`loadCount`降序排列
 */
- (void)install;

/**
 * 存储骨架屏管理单元到指定沙盒目录
 * @param manager 骨架屏管理单元
 */
- (void)cacheComponentManager:(FWTabComponentManager *)manager;

/**
 * 获取指定骨架屏管理单元
 * @param fileName 文件名
 */
- (nullable FWTabComponentManager *)getComponentManagerWithFileName:(NSString *)fileName;

/**
 * 更新该viewAnimated下所有骨架屏管理单元的loadCount
 * @param viewAnimated 骨架屏配置对象
 */
- (void)updateCacheModelLoadCountWithTableAnimated:(FWTabTableAnimated *)viewAnimated;

/**
 * 更新该viewAnimated下所有骨架屏管理单元的loadCount
 * @param viewAnimated 骨架屏配置对象
 */
- (void)updateCacheModelLoadCountWithCollectionAnimated:(FWTabCollectionAnimated *)viewAnimated;

@end

@interface FWTabAnimatedCacheModel : NSObject<NSSecureCoding>

@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, assign) NSInteger loadCount;

@end

@interface FWTabAnimatedDocumentMethod : NSObject

+ (void)writeToFileWithData:(id)data
                   filePath:(NSString *)filePath;

+ (id)getCacheData:(NSString *)filePath
       targetClass:(Class)targetClass;

+ (NSArray <NSString *> *)getAllFileNameWithFolderPath:(NSString *)folderPath;

// 获取Documents目录下对应一级目录和文件名，不创建
+ (NSString *)getPathByCreateDocumentFile:(NSString *)filePacketName
                             documentName:(NSString *)documentName;

// 获取Documents目录下对应的文件名，不创建
+ (NSString *)getPathByCreateDocumentName:(NSString *)documentName;

// 获取FWTabCache下对应filePacketName目录
+ (NSString *)getFWTabPathByFilePacketName:(NSString *)filePacketName;

// 创建文件/文件夹
+ (BOOL)createFile:(NSString *)file
             isDir:(BOOL)isdir;

// 判断文件/文件夹是否存在
+ (BOOL)isExistFile:(NSString *)path
              isDir:(BOOL)isDir;

@end

@class FWTabViewAnimated, FWTabBaseComponent, FWTabComponentManager;

@interface UIView (FWTabAnimated)

// 控制视图持有
@property (nonatomic, strong) FWTabViewAnimated * _Nullable fwTabAnimated;

// 骨架屏管理单元持有
@property (nonatomic, strong) FWTabComponentManager * _Nullable fwTabComponentManager;

// 是否禁用骨架屏
@property (nonatomic, assign) BOOL fwTabDisabled;

@end

@class FWTabTableAnimated;

@interface UITableView (FWTabAnimated)

// 控制视图持有的配置管理对象
@property (nonatomic, strong) FWTabTableAnimated * _Nullable fwTabAnimated;

@end

@class FWTabCollectionAnimated;

@interface UICollectionView (FWTabAnimated)

// 控制视图持有的配置管理对象
@property (nonatomic, strong) FWTabCollectionAnimated * _Nullable fwTabAnimated;

@end

@interface UIView (FWTabControlAnimation)

#pragma mark - General

/**
 * 开启动画, 建议使用下面的方法
 *
 * `[self fwTabStartAnimation]`即使多次调用，也只会生效一次。
 * 如有其他需要，请自行修改`FWTabViewAnimated`中的`canLoadAgain`属性，解除限制。
 */
- (void)fwTabStartAnimation;

/**
 * 使用原有的启动动画方法`fwTabStartAnimation`时发现了一个问题:
 * 在网络非常好的情况下，动画基本没机会展示出来，甚至会有一闪而过的视觉差，所以体验会不好。
 * 起初用`fwTabStartAnimation`方法配合MJRefresh，则会减缓这样的问题，原因是MJRefresh本身有一个延迟效果（为了说明，这么称呼的），大概是0.4秒。
 * 所以，增加了一个带有延迟时间的启动方法，默认为0.4s
 * 这样的话，在网络卡的情况下，0.4秒并不会造成太大的影响，在网络不卡的情况下，可以有一个短暂的视觉停留效果。
 *
 * @param completion 在回调中加载数据
 */
- (void)fwTabStartAnimationWithCompletion:(void (^)(void))completion;

/**
 * 与上述方法功能相同，可以自定义延迟时间。
 *
 * @param delayTime 自定义延迟时间
 * @param completion 在回调中加载数据
 */
- (void)fwTabStartAnimationWithDelayTime:(CGFloat)delayTime
                             completion:(void (^)(void))completion;

/**
 * 结束动画, 默认不加入任何动画效果
 */
- (void)fwTabEndAnimation;

/**
 * 结束动画, 加入淡入淡出效果
 */
- (void)fwTabEndAnimationEaseOut;

#pragma mark - Section Mode

/**
 * 启动动画并指定section
 *
 * @param section UITableView或者UICollectionView的section
 */
- (void)fwTabStartAnimationWithSection:(NSInteger)section;

/**
 * 启动动画并指定section，默认延迟时间0.4s
 *
 * @param section UITableView或者UICollectionView的section
 * @param completion 延迟回调
 */
- (void)fwTabStartAnimationWithSection:(NSInteger)section
                           completion:(void (^)(void))completion;

/**
 * 启动动画并指定section，同时可以自定义延迟时间
 *
 * @param section UITableView或者UICollectionView的section
 * @param delayTime 自定义的延迟时间
 * @param completion 完成回调
 */
- (void)fwTabStartAnimationWithSection:(NSInteger)section
                            delayTime:(CGFloat)delayTime
                           completion:(void (^)(void))completion;

/**
 * 指定分区结束动画，当表格的所有分区都不存在动画，会自动置为结束动画的状态
 *
 * @param section 被指定的section的值
 */
- (void)fwTabEndAnimationWithSection:(NSInteger)section;

#pragma mark - Row Mode

/**
 * 指定row开启动画
 *
 * @param row 被指定的row的值
 */
- (void)fwTabStartAnimationWithRow:(NSInteger)row;

/**
 * 启动动画并指定row，默认延迟时间0.4s
 *
 * @param row UITableView或者UICollectionView的row
 * @param completion 延迟回调
*/
- (void)fwTabStartAnimationWithRow:(NSInteger)row
                       completion:(void (^)(void))completion;

/**
 * 启动动画并指定row，同时可以自定义延迟时间
 *
 * @param row UITableView或者UICollectionView的row
 * @param delayTime 自定义的延迟时间
 * @param completion 完成回调
 */
- (void)fwTabStartAnimationWithRow:(NSInteger)row
                        delayTime:(CGFloat)delayTime
                       completion:(void (^)(void))completion;
/**
 * 指定row结束动画
 *
 * @param row 被指定的row的值
 */
- (void)fwTabEndAnimationWithRow:(NSInteger)row;

@end

/**
 链式语法相关的文件
 */
@class FWTabBaseComponent;

@interface NSArray (FWTabAnimated)

typedef NSArray <FWTabBaseComponent *> * _Nullable (^FWTabAnimatedArrayFloatBlock)(CGFloat);
typedef NSArray <FWTabBaseComponent *> * _Nullable (^FWTabAnimatedArrayIntBlock)(NSInteger);
typedef NSArray <FWTabBaseComponent *> * _Nullable (^FWTabAnimatedArrayBlock)(void);
typedef NSArray <FWTabBaseComponent *> * _Nullable (^FWTabAnimatedArrayStringBlock)(NSString *);
typedef NSArray <FWTabBaseComponent *> * _Nullable (^FWTabAnimatedArrayColorBlock)(UIColor *);

/**
 所有元素向左平移
 
 @return 目标动画元素数组
 */
- (FWTabAnimatedArrayFloatBlock)left NS_SWIFT_NAME(_oc_left());

/**
 所有元素向右平移

 @return 目标动画元素数组
 */
- (FWTabAnimatedArrayFloatBlock)right NS_SWIFT_NAME(_oc_right());

/**
 所有元素向上平移

 @return 目标动画元素数组
 */
- (FWTabAnimatedArrayFloatBlock)up NS_SWIFT_NAME(_oc_up());

/**
 所有元素向下平移

 @return 目标动画元素数组
 */
- (FWTabAnimatedArrayFloatBlock)down NS_SWIFT_NAME(_oc_down());

/**
 设置所有元素的宽度
 
 @return 目标动画元素数组
 */
- (FWTabAnimatedArrayFloatBlock)width NS_SWIFT_NAME(_oc_width());

/**
 设置所有元素的高度

 * @return 目标动画元素数组
 */
- (FWTabAnimatedArrayFloatBlock)height NS_SWIFT_NAME(_oc_height());

/**
 设置所有元素的圆角
 
 @return 目标动画元素数组
 */
- (FWTabAnimatedArrayFloatBlock)radius NS_SWIFT_NAME(_oc_radius());

/**
 减少的宽度：与当前宽度相比，所减少的宽度，负数则增加。

 @return 目标动画元素数组
 */
- (FWTabAnimatedArrayFloatBlock)reducedWidth NS_SWIFT_NAME(_oc_reducedWidth());

/**
 减少的高度：与当前高度相比，所减少的高度，负数则增加。

 @return 目标动画元素数组
 */
- (FWTabAnimatedArrayFloatBlock)reducedHeight NS_SWIFT_NAME(_oc_reducedHeight());

/**
 减少的圆角：与当前圆角相比，所减少的圆角，负数则增加。
 
 @return 目标动画元素数组
 */
- (FWTabAnimatedArrayFloatBlock)reducedRadius NS_SWIFT_NAME(_oc_reducedRadius());

/**
 设置行数
 
 @return 目标动画元素数组
 */
- (FWTabAnimatedArrayIntBlock)line NS_SWIFT_NAME(_oc_line());

/**
 间距，行数超过1时生效，默认为8.0。
 
 @return 目标动画元素数组
 */
- (FWTabAnimatedArrayFloatBlock)space NS_SWIFT_NAME(_oc_space());

/**
 移除该动画组件数组中的所有组件

 @return 目标动画元素数组
 */
- (FWTabAnimatedArrayBlock)remove NS_SWIFT_NAME(_oc_remove());

/**
 添加占位图，不支持圆角，建议切图使用圆角

 @return 目标动画元素数组
 */
- (FWTabAnimatedArrayStringBlock)placeholder NS_SWIFT_NAME(_oc_placeholder());

/**
 设置横坐标

 @return 目标动画元素数组
 */
- (FWTabAnimatedArrayFloatBlock)x NS_SWIFT_NAME(_oc_x());

/**
 设置纵坐标

 @return 目标动画元素数组
 */
- (FWTabAnimatedArrayFloatBlock)y NS_SWIFT_NAME(_oc_y());

/**
 设置层级，默认0，值越小层级越低
 
 @return 目标动画元素数组
 */
- (FWTabAnimatedArrayFloatBlock)z NS_SWIFT_NAME(_oc_z());

/**
 设置动画数组颜色
 
 @return 目标动画元素数组
 */
- (FWTabAnimatedArrayColorBlock)color NS_SWIFT_NAME(_oc_color());

#pragma mark - Drop Animation 以下属性均针对豆瓣动画

/**
 豆瓣动画变色下标，一起变色的元素，设置同一个下标即可。
 
 @return 目标动画元素数组
 */
- (FWTabAnimatedArrayIntBlock)dropIndex NS_SWIFT_NAME(_oc_dropIndex());

/**
 适用于多行的动画元素,
 比如设置 dropFromIndex(3), 那么多行动画组中的第一个动画的下标是3，第二个就是4，依次类推。
 
 @return 目标动画元素数组
 */
- (FWTabAnimatedArrayIntBlock)dropFromIndex NS_SWIFT_NAME(_oc_dropFromIndex());

/**
 将动画层移出豆瓣动画队列，不参与变色。
 
 @return 目标动画元素数组
 */
- (FWTabAnimatedArrayBlock)removeOnDrop NS_SWIFT_NAME(_oc_removeOnDrop());

/**
 豆瓣动画变色停留时间比，默认是0.2。
 
 @return 目标动画元素数组
 */
- (FWTabAnimatedArrayFloatBlock)dropStayTime NS_SWIFT_NAME(_oc_dropStayTime());

@end

@class FWTabComponentLayer;

@interface FWTabBaseComponent : NSObject

typedef FWTabBaseComponent * _Nullable (^FWTabBaseComponentVoidBlock)(void);
typedef FWTabBaseComponent * _Nullable (^FWTabBaseComponentIntegerBlock)(NSInteger);
typedef FWTabBaseComponent * _Nullable (^FWTabBaseComponentFloatBlock)(CGFloat);
typedef FWTabBaseComponent * _Nullable (^FWTabBaseComponentStringBlock)(NSString *);
typedef FWTabBaseComponent * _Nullable (^FWTabBaseComponentColorBlock)(UIColor *);

#pragma mark - 基础属性

/**
 向左平移

 @return 目标动画元素
 */
- (FWTabBaseComponentFloatBlock)left NS_SWIFT_NAME(_oc_left());

/**
 向右平移

 @return 目标动画元素
 */
- (FWTabBaseComponentFloatBlock)right NS_SWIFT_NAME(_oc_right());

/**
 向上平移

 @return 目标动画元素
 */
- (FWTabBaseComponentFloatBlock)up NS_SWIFT_NAME(_oc_up());

/**
 向下平移

 @return 目标动画元素
 */
- (FWTabBaseComponentFloatBlock)down NS_SWIFT_NAME(_oc_down());

/**
 设置动画元素的宽度

 @return 目标动画元素
 */
- (FWTabBaseComponentFloatBlock)width NS_SWIFT_NAME(_oc_width());

/**
 设置动画元素的高度

 @return 目标动画元素
 */
- (FWTabBaseComponentFloatBlock)height NS_SWIFT_NAME(_oc_height());

/**
 设置动画元素的圆角
 
 @return 目标动画元素
 */
- (FWTabBaseComponentFloatBlock)radius NS_SWIFT_NAME(_oc_radius());

/**
 需要减少的宽度：与当前宽度相比，所减少的宽度
 负数则为增加
 
 @return 目标动画元素
 */
- (FWTabBaseComponentFloatBlock)reducedWidth NS_SWIFT_NAME(_oc_reducedWidth());

/**
 减少的高度：与当前高度相比，所减少的高度
 负数则为增加
 
 @return 目标动画元素
 */
- (FWTabBaseComponentFloatBlock)reducedHeight NS_SWIFT_NAME(_oc_reducedHeight());

/**
 减少的圆角
 
 @return 目标动画元素
 */
- (FWTabBaseComponentFloatBlock)reducedRadius NS_SWIFT_NAME(_oc_reducedRadius());

/**
 设置横坐标
 
 @return 目标动画元素
 */
- (FWTabBaseComponentFloatBlock)x NS_SWIFT_NAME(_oc_x());

/**
 设置纵坐标
 
 @return 目标动画元素
 */
- (FWTabBaseComponentFloatBlock)y NS_SWIFT_NAME(_oc_y());

/**
 设置层级，默认0，值越小层级越低
 
 @return 目标动画元素
 */
- (FWTabBaseComponentFloatBlock)z NS_SWIFT_NAME(_oc_z());

/**
 设置动画元素的行数

 @return 目标动画元素
 */
- (FWTabBaseComponentIntegerBlock)line NS_SWIFT_NAME(_oc_line());

/**
 设置多行动画元素的间距，即行数超过1时生效，默认为8.0。
 
 @return 目标动画元素
 */
- (FWTabBaseComponentFloatBlock)space NS_SWIFT_NAME(_oc_space());

/**
 对于`行数` > 1的动画元素，设置最后一行的宽度比例，默认是0.5，即原宽度的一半。
 
 @return 目标动画元素
 */
- (FWTabBaseComponentFloatBlock)lastLineScale NS_SWIFT_NAME(_oc_lastLineScale());

/**
 从动画组中移除
 
 @return 目标动画元素
 */
- (FWTabBaseComponentVoidBlock)remove NS_SWIFT_NAME(_oc_remove());

/**
 添加占位图，不支持圆角，建议切图使用圆角
 
 @return 目标动画元素
 */
- (FWTabBaseComponentStringBlock)placeholder NS_SWIFT_NAME(_oc_placeholder());

/**
 赋予动画元素画由长到短的动画
 
 @return 目标动画元素
 */
- (FWTabBaseComponentVoidBlock)toLongAnimation NS_SWIFT_NAME(_oc_toLongAnimation());

/**
 赋予动画元素画由短到长的动画
 
 @return 目标动画元素
 */
- (FWTabBaseComponentVoidBlock)toShortAnimation NS_SWIFT_NAME(_oc_toShortAnimation());

/**
 如果动画元素来自居中文本，设置后取消居中显示，
 
 @return 目标动画元素
 */
- (FWTabBaseComponentVoidBlock)cancelAlignCenter NS_SWIFT_NAME(_oc_cancelAlignCenter());

/**
 设置动画元素颜色

 @return 目标动画元素
 */
- (FWTabBaseComponentColorBlock)color NS_SWIFT_NAME(_oc_color());

#pragma mark - 豆瓣动画需要用到的属性

/**
 豆瓣动画 - 变色下标，一起变色的元素，设置同一个下标即可。
 
 @return 目标动画元素
 */
- (FWTabBaseComponentIntegerBlock)dropIndex NS_SWIFT_NAME(_oc_dropIndex());

/**
 豆瓣动画 - 用于多行的动画元素,
 比如设置 dropFromIndex(3), 那么多行动画组中的第一行的下标是3，第二行就是4，依次类推。
 
 @return 目标动画元素
 */
- (FWTabBaseComponentIntegerBlock)dropFromIndex NS_SWIFT_NAME(_oc_dropFromIndex());

/**
 豆瓣动画 - 将动画层移出豆瓣动画队列，不参与变色。
 
 @return 目标动画元素
 */
- (FWTabBaseComponentVoidBlock)removeOnDrop NS_SWIFT_NAME(_oc_removeOnDrop());

/**
 豆瓣动画 - 豆瓣动画变色停留时间比，默认是0.2。
 
 @return 目标动画元素
 */
- (FWTabBaseComponentFloatBlock)dropStayTime NS_SWIFT_NAME(_oc_dropStayTime());

+ (instancetype)initWithComponentLayer:(FWTabComponentLayer *)layer;

@property (nonatomic, strong, readonly) FWTabComponentLayer *layer;

@end

@interface FWTabComponentLayer : CAGradientLayer <NSCopying, NSSecureCoding>

/**
 如果控制视图开启的动画，那么该控制视图下的所有subViews将被设置为`FWTabViewLoadAnimationWithOnlySkeleton`

 - FWTabViewLoadAnimationWithOnlySkeleton: 基础骨架
 - FWTabViewLoadAnimationToLong: 伸缩先变长
 - FWTabViewLoadAnimationToShort: 伸缩先变短
 - FWTabViewLoadAnimationRemove: 从动画队列移除
 */
typedef NS_ENUM(NSInteger,FWTabViewLoadAnimationStyle) {
    FWTabViewLoadAnimationWithOnlySkeleton,
    FWTabViewLoadAnimationToLong,
    FWTabViewLoadAnimationToShort,
    FWTabViewLoadAnimationRemove,
};

#pragma mark - 属性

/**
 * 如果控制视图开启的动画，那么该控制视图下的所有subViews将被设置为`FWTabViewLoadAnimationWithOnlySkeleton`
 */
@property (nonatomic, assign) FWTabViewLoadAnimationStyle loadStyle;

/**
 * 动画元素来自居中文本
 */
@property (nonatomic, assign) BOOL fromCenterLabel;

/**
 * 动画元素来自居中文本,取消居中显示
 */
@property (nonatomic, assign) BOOL isCancelAlignCenter;

/**
 * 动画来自UIImageView。
 */
@property (nonatomic, assign) BOOL fromImageView;

/**
 * 动画时组件高度，
 * 如果你觉得动画不够漂亮，可以使用这个属性进行调整。
 */
@property (nonatomic, assign) CGFloat tabViewHeight;

/**
 * 该动画元素所处的index
 */
@property (nonatomic, assign) NSInteger tagIndex;

#pragma mark - 配置成多行的动画元素

/**
 * 此属性的值是根据UILabel组件的numberOflines属性的值映射出来的。
 * 由其他类型组件映射出的动画元素，该属性会被设置为1，你可以对其更改，达到多行的效果。
 */
@property (nonatomic, assign) NSInteger numberOflines;

/**
 * 对于`numberOflines` > 1的动画元素，设置行与行之间的间距，默认是8.0。
 */
@property (nonatomic, assign) CGFloat lineSpace;

/**
 * 对于`numberOflines` > 1的动画元素，设置最后一行的宽度比例，默认是0.5，即原宽度的一半。
 */
@property (nonatomic, assign) CGFloat lastScale;

#pragma mark - Only used to drop animation

/**
 * 该动画元素在豆瓣动画队列中的下标
 */
@property (nonatomic, assign) NSInteger dropAnimationIndex;

/**
 * 对于多行的动画元素，在豆瓣动画队列中，设置它的起点下标
 */
@property (nonatomic, assign) NSInteger dropAnimationFromIndex;

/**
 * 是否将该元素从豆瓣动画队列中移除
 */
@property (nonatomic, assign) BOOL removeOnDropAnimation;

/**
 * 豆瓣动画间隔时间，默认0.2。
 */
@property (nonatomic, assign) CGFloat dropAnimationStayTime;

/**
 * 当前应该显示的颜色，用于适配暗黑模式
 */
@property (nonatomic, strong) UIColor *currentColor;

/**
 * 该动画元素最终的frame
 */
@property (nonatomic, strong) NSValue *resultFrameValue;

/**
 * 该动画元素显示的图片名
 */
@property (nonatomic, copy) NSString *placeholderName;

@end

@class FWTabViewAnimated, FWTabBaseComponent, FWTabSentryView;

typedef FWTabBaseComponent * _Nullable (^FWTabBaseComponentBlock)(NSInteger);
typedef NSArray <FWTabBaseComponent *> * _Nullable (^FWTabBaseComponentArrayBlock)(NSInteger location, NSInteger length);
typedef NSArray <FWTabBaseComponent *> * _Nullable (^FWTabBaseComponentArrayWithIndexsBlock)(NSInteger index,...);

@interface FWTabComponentManager : NSObject <NSCopying, NSSecureCoding>

/**
 获取单个动画元素
 使用方式：.animation(x)
 
 @return FWTabBaseComponent对象
 */
- (FWTabBaseComponentBlock _Nullable)animation NS_SWIFT_NAME(_oc_animation());

/**
 获取多个动画元素，需要传递2个参数
 第一个参数为起始下标
 第二个参数长度
 使用方式：.animations(x,x)
 
 @return 装有`FWTabBaseComponent`类型的数组
 */
- (FWTabBaseComponentArrayBlock _Nullable)animations NS_SWIFT_NAME(_oc_animations());

/**
 获取不定量动画元素，参数 >= 1
 例如: animationsWithIndexs(1,5,7)，意为获取下标为1，5，7的动画元素
 
 @return 装有`FWTabBaseComponent`类型的数组
 */
- (FWTabBaseComponentArrayWithIndexsBlock)animationsWithIndexs;
- (NSArray<FWTabBaseComponent *> * _Nullable (^)(NSArray *indexs))_oc_animationsWithIndexs;

#pragma mark - 相关属性

/**
 * 绑定的cell的class，用于在预处理回调中区分class
 */
@property (nonatomic) Class tabTargetClass;

/**
 * cell中覆盖在最底层的layer
 */
@property (nonatomic, strong) FWTabComponentLayer *tabLayer;

/**
 * 设置该属性后，统一设置该cell内所有动画元素的内容颜色
 * 优先级高于全局的内容颜色，低于动画元素自定义的内容颜色
 */
@property (nonatomic, strong) UIColor *animatedColor;

/**
 * 设置该属性后，统一设置该cell的背景颜色
 */
@property (nonatomic, strong) UIColor *animatedBackgroundColor;

/**
 * 设置该属性后，统一设置该cell内所有动画元素的高度
 * 优先级高于全局的高度，低于动画元素自定义的高度
 */
@property (nonatomic, assign) CGFloat animatedHeight;

/**
 * 设置该属性后，统一设置该cell内所有动画元素的圆角
 * 优先级高于全局的圆角，低于动画元素自定义的圆角
 */
@property (nonatomic, assign) CGFloat animatedCornerRadius;

/**
 * 设置该属性后，统一设置取消cell内所有动画元素的圆角
 * 优先级高于全局的取消圆角属性，低于动画元素自定义的取消圆角属性
 */
@property (nonatomic, assign) BOOL cancelGlobalCornerRadius;

/**
 * 哨兵视图，用于监听暗黑模式
 */
@property (nonatomic, weak, readonly, nullable) FWTabSentryView *sentryView;

/**
 * 最初始动画组
 */
@property (nonatomic, strong, readonly) NSMutableArray <FWTabComponentLayer *> *componentLayerArray;

/**
 * 最初的动画组包装类
 */
@property (nonatomic, strong, readonly) NSMutableArray <FWTabBaseComponent *> *baseComponentArray;

/**
 * 最终显示在屏幕上的动画组
 */
@property (nonatomic, strong, readonly) NSMutableArray <FWTabComponentLayer *> *resultLayerArray;

/**
 * 暂存被嵌套的表格视图
 */
@property (nonatomic, weak) UIView *nestView;

/**
 * 是否已经装载并加载过动画
 */
@property (nonatomic, assign) BOOL isLoad;

/**
 * 对于表格视图的cell和头尾视图，当前所处section
 */
@property (nonatomic, assign) NSInteger currentSection;

/**
 * 对于表格视图的cell和头尾视图，当前所处row
 * 用于对于某一个cell的特殊处理
 */
@property (nonatomic, assign) NSInteger currentRow;

/**
 * 豆瓣动画组动画元素的数量
 */
@property (nonatomic, assign, readonly) NSInteger dropAnimationCount;

/**
 * 豆瓣动画
 */
@property (nonatomic, strong) NSMutableArray <NSArray *> *entireIndexArray;

/**
 * 该cell类型存储到本地的文件名
 */
@property (nonatomic, copy) NSString *fileName;

/**
 * 该cell类型映射到本地文件的最后一次版本号
 */
@property (nonatomic, copy) NSString *version;

/**
 * 框架会自动为该属性赋值
 * 不要手动改变它的值
 */
@property (nonatomic, assign) BOOL needChangeRowStatus;

/**
 * 框架会自动为该属性赋值
 * 不要手动改变它的值
 */
@property (nonatomic, assign, readonly) BOOL needUpdate;

+ (instancetype)initWithView:(UIView *)view
                   superView:(UIView *)superView
                 tabAnimated:(FWTabViewAnimated *)tabAnimated;

- (void)installBaseComponentArray:(NSArray <FWTabComponentLayer *> *)array;

- (void)updateComponentLayers;

- (void)addSentryView:(UIView *)view
            superView:(UIView *)superView;

- (void)reAddToView:(UIView *)view
          superView:(UIView *)superView;

@end

@interface FWTabTableDeDaSelfModel : NSObject

@property (nonatomic, copy) NSString *targetClassName;
@property (nonatomic, assign) BOOL isExhangeDelegate;
@property (nonatomic, assign) BOOL isExhangeDataSource;

@end

@interface FWTabCollectionDeDaSelfModel : NSObject

@property (nonatomic, copy) NSString *targetClassName;
@property (nonatomic, assign) BOOL isExhangeDelegate;
@property (nonatomic, assign) BOOL isExhangeDataSource;

@end

/**
 集成时，开发者不需要关心。
 该文件用于管理动画上层依赖的view。
 */

@class FWTabComponentManager, FWTabComponentLayer;

@interface FWTabManagerMethod : NSObject

/**
 填充数据
 
 @param view 上层view
 */
+ (void)fullData:(UIView *)view;

/**
 恢复数据
 
 @param view 上层view
 */
+ (void)resetData:(UIView *)view;

/**
 映射出所view中的FWTabComponentLayer，组装起来，并加入约定好的动画

 @param view 需要映射的view
 @param superView view的父视图
 @param rootView 根view
 @param rootSuperView 根view的父视图
 @param array 得到的FWTabComponentLayer集合
 */
+ (void)getNeedAnimationSubViews:(UIView *)view
                   withSuperView:(UIView *)superView
                    withRootView:(UIView *)rootView
               withRootSuperView:(UIView *)rootSuperView
                    isInNestView:(BOOL)isInNestView
                           array:(NSMutableArray <FWTabComponentLayer *> *)array;

/**
 排除部分不符合条件的view
 
 @param view 目标view
 @return 判断结果
 */
+ (BOOL)judgeViewIsNeedAddAnimation:(UIView *)view;

/**
 是否可以添加闪光灯动画
 
 @param view 目标view
 @return 判断结果
 */
+ (BOOL)canAddShimmer:(UIView *)view;

/**
 是否可以添加呼吸灯动画
 
 @param view 目标view
 @return 判断结果
 */
+ (BOOL)canAddBinAnimation:(UIView *)view;

/**
 是否可以添加跳跃动画
 
 @param view 目标view
 @return 判断结果
 */
+ (BOOL)canAddDropAnimation:(UIView *)view;

/**
 结束被嵌套视图的动画
 
 @param view 目标view
 */
+ (void)endAnimationToSubViews:(UIView *)view;

+ (void)startAnimationToSubViews:(UIView *)view
                        rootView:(UIView *)rootView;

+ (void)hiddenAllView:(UIView *)view;

+ (void)removeAllFWTabLayersFromView:(UIView *)view;

+ (void)removeMask:(UIView *)view;

+ (void)removeSubLayers:(NSArray *)subLayers;

+ (void)addExtraAnimationWithSuperView:(UIView *)superView
                            targetView:(UIView *)targetView
                               manager:(FWTabComponentManager *)manager;

+ (void)runAnimationWithSuperView:(UIView *)superView
                       targetView:(UIView *)targetView
                           isCell:(BOOL)isCell
                          manager:(FWTabComponentManager *)manager;

+ (UIColor *)brightenedColor:(UIColor *)color
                  brightness:(CGFloat)brightness;

@end

typedef void(^FWTabSentryViewCallBack)(void);

@interface FWTabSentryView : UIView

@property (nonatomic, copy) FWTabSentryViewCallBack traitCollectionDidChangeBack;

@end

extern const NSInteger FWTabViewAnimatedErrorCode;

extern NSString * const FWTabViewAnimatedHeaderPrefixString;
extern NSString * const FWTabViewAnimatedFooterPrefixString;
extern NSString * const FWTabViewAnimatedDefaultSuffixString;

@class FWTabComponentManager;

/**
 * the state of animation
 * 动画状态枚举
 */
typedef NS_ENUM(NSInteger,FWTabViewAnimationStyle) {
    /// default, nothing happen
    /// 默认，无事发生
    FWTabViewAnimationDefault = 0,
    /// start to load animation
    /// 可以开启动画
    FWTabViewAnimationStart,
    /// animation runing
    /// 动画加载完毕
    FWTabViewAnimationRunning,
    /// animation close
    /// 动画已关闭
    FWTabViewAnimationEnd,
};

/**
 控制视图设置此属性后，动画类型覆盖全局动画类型，加载该属性指定的动画
 */
typedef NS_ENUM(NSInteger,FWTabViewSuperAnimationType) {
    FWTabViewSuperAnimationTypeDefault = 0,                    // 默认, 不覆盖全局属性处理，使用全局属性
    FWTabViewSuperAnimationTypeOnlySkeleton,                   // 骨架层
    FWTabViewSuperAnimationTypeBinAnimation,                   // 呼吸灯
    FWTabViewSuperAnimationTypeShimmer,                        // 闪光灯
    FWTabViewSuperAnimationTypeDrop,                           // 豆瓣下坠动画
};

/**
 表格视图配置
 */
typedef enum : NSUInteger {
    
    /**
     以section为单位配置动画 - Section Mode
     
     视图结构必须满足以下情况:
     section和cell样式一一对应
     */
    FWTabAnimatedRunBySection = 0,
    
    /**
    以row为单位配置动画 - Row Mode
     
    视图结构必须满足以下情况:
    1. 视图只有1个section
    2. 1个section对应多个cell
    3. row的数量必须要是定值
     */
    FWTabAnimatedRunByRow,
    
} FWTabAnimatedRunMode;

/**
 * 新预处理回调
 *
 * @param manager 管理动画组对象
 */
typedef void(^FWTabAdjustBlock)(FWTabComponentManager *manager);

/**
 * 适用于多cell, 建议使用该回调
 * 默认情况下，cellArray的下标就是section的值
 * 指定section的情况，就是你所指定的值
 *
 * @param manager 管理动画组对象
 * @param targetClass 多cell情况，对应的数组下标
 */
typedef void(^FWTabAdjustWithClassBlock)(FWTabComponentManager *manager, Class targetClass);

@interface FWTabViewAnimated : NSObject

/**
 * v2.2.0新预处理回调, 职责更明确
 * 可以在其中使用链式语法便捷调整每一个动画元素
 */
@property (nonatomic, copy) FWTabAdjustBlock adjustBlock;

/**
 * v2.2.0新预处理回调, 职责更明确
 * 可以在其中使用链式语法便捷调整每一个动画元素,
 * section是指数组中不同cell的下标
 */
@property (nonatomic, copy) FWTabAdjustWithClassBlock adjustWithClassBlock;

/**
 * 动画状态，可重置
 */
@property (nonatomic, assign) FWTabViewAnimationStyle state;

/**
 * 使用该属性时，全局动画类型失效，目标视图将更改为当前属性指定的动画类型。
 */
@property (nonatomic, assign) FWTabViewSuperAnimationType superAnimationType;

/**
 * 一个section对应一种cell
 */
@property (nonatomic, copy) NSArray <Class> *cellClassArray;

/**
 * 多个section使用该属性，设置动画时row数量
 * 当数组数量大于section数量，多余数据将舍弃
 * 当数组数量小于seciton数量，剩余部分动画时row的数量为默认值
 */
@property (nonatomic, copy) NSArray <NSNumber *> *animatedCountArray;

/**
 * 当前视图动画内容颜色
 */
@property (nonatomic, strong) UIColor *animatedColor;

/**
 * 当前视图动画背景颜色
 */
@property (nonatomic, strong) UIColor *animatedBackgroundColor;

/**
 * 当前视图暗黑模式下动画内容颜色
 */
@property (nonatomic, strong) UIColor *darkAnimatedColor;

/**
 * 当前视图暗黑模式下动画背景颜色
 */
@property (nonatomic, strong) UIColor *darkAnimatedBackgroundColor;

/**
 * 如果开启了全局圆角，当该属性设置为YES，则该控制视图下圆角将取消，
 * 但是视图本身如果有圆角，则保持不变。
 */
@property (nonatomic, assign) BOOL cancelGlobalCornerRadius;

/**
 * 决定当前视图动画元素圆角
 */
@property (nonatomic, assign) CGFloat animatedCornerRadius;

/**
 * 如果你的背景视图的圆角失效了，请使用这个属性设置其圆角
 */
@property (nonatomic, assign) CGFloat animatedBackViewCornerRadius;

/**
 * 决定当前视图动画高度
 */
@property (nonatomic, assign) CGFloat animatedHeight;

/**
 * 是否在动画中，在普通模式中，用于快速判断
 */
@property (nonatomic, assign) BOOL isAnimating;

/**
 * 是否是嵌套在内部的表格视图
 */
@property (nonatomic, assign) BOOL isNest;

/**
 * 是否可以重复开启动画，默认开启只生效一次。
 */
@property (nonatomic, assign) BOOL canLoadAgain;

//@property (nonatomic, assign) BOOL oldEnable;

#pragma mark - 过滤条件

/**
 * 过滤子视图条件，默认为CGSizeZero。
 * 如果width为0，则不过滤width
 * 如果height为0，则不过滤height
 * 如果width为5，则过滤掉`width <= 5`的子视图
 * 如果height为5，则过滤掉`height <= 5`的子视图
 * 如果width, height条件同时存在，两种条件都会被过滤。
 *
 * PS：width为原始宽度，height为原始高度，不受全局属性`animatedHeightCoefficient`的影响
 */
@property (nonatomic, assign) CGSize filterSubViewSize;

#pragma mark - 豆瓣动画属性

/**
 * 豆瓣动画变色时长，无默认，默认读取全局属性
 */
@property (nonatomic, assign) CGFloat dropAnimationDuration;

/**
 * 豆瓣动画变色值
 */
@property (nonatomic, strong) UIColor *dropAnimationDeepColor;

/**
 * 暗黑模式下，豆瓣动画变色值
 */
@property (nonatomic, strong) UIColor *dropAnimationDeepColorInDarkMode;

#pragma mark - Other

/**
 * 控制视图所处的控制器类型
 */
@property (nonatomic, copy) NSString *targetControllerClassName;

- (BOOL)currentIndexIsAnimatingWithIndex:(NSInteger)index;

@end

@class FWTabComponentManager;

@interface FWTabTableAnimated : FWTabViewAnimated

#pragma mark - readwrite

/**
 1种cell样式时，UITableView的cellHeight
 */
@property (nonatomic, assign) CGFloat cellHeight;

/**
 cell样式  > 1 时，UITableView的cellHeight集合
 */
@property (nonatomic, copy) NSArray <NSNumber *> *cellHeightArray;

/**
 仅用于动态section，即section的数量是根据获取到的数据而变化的。
 */
@property (nonatomic, assign) NSInteger animatedSectionCount;

/**
 设置单个section单个cell样式时动画的数量，默认填充屏幕为准
 */
@property (nonatomic, assign) NSInteger animatedCount;

/**
 UITableView动画启动时，同时启动UITableViewHeaderView
 */
@property (nonatomic, assign) BOOL showTableHeaderView;

/**
 UITableView动画启动时，同时启动UITableViewFooterView
 */
@property (nonatomic, assign) BOOL showTableFooterView;

/**
 头视图动画对象
 */
@property (nonatomic, weak) FWTabViewAnimated *tabHeadViewAnimated;

/**
 尾视图动画对象
 */
@property (nonatomic, weak) FWTabViewAnimated *tabFooterViewAnimated;

#pragma mark - readonly, 不建议重写的属性

/**
 你不需要手动赋值，但是你需要知道当前视图的结构，
 从而选择初始化方法和启动方法。
 */
@property (nonatomic, assign, readonly) FWTabAnimatedRunMode runMode;

/**
 指定cell样式加载动画的集合
 集合内为cell样式所在的indexPath
 */
@property (nonatomic, copy) NSArray <NSNumber *> *animatedIndexArray;

/**
 当前正在动画中的index
 如果是section mode，则为section的值
 如果是row mode，则为row的值
 */
@property (nonatomic, strong) NSMutableArray <NSNumber *> *runAnimationIndexArray;

/**
 缓存自适应高度值
 */
@property (nonatomic, assign) CGFloat oldEstimatedRowHeight;

/**
 是否已经交换了delegate的IMP地址
 */
@property (nonatomic, assign, readonly) BOOL isExhangeDelegateIMP;

/**
 是否已经交换了dataSource的IMP地址
 */
@property (nonatomic, assign, readonly) BOOL isExhangeDataSourceIMP;

/**
 存储头视图相关
 */
@property (nonatomic, strong, readonly) NSMutableArray <Class> *headerClassArray;
@property (nonatomic, strong, readonly) NSMutableArray <NSNumber *> *headerHeightArray;
@property (nonatomic, strong, readonly) NSMutableArray <NSNumber *> *headerSectionArray;

/**
 存储尾视图相关
 */
@property (nonatomic, strong, readonly) NSMutableArray <Class> *footerClassArray;
@property (nonatomic, strong, readonly) NSMutableArray <NSNumber *> *footerHeightArray;
@property (nonatomic, strong, readonly) NSMutableArray <NSNumber *> *footerSectionArray;

#pragma mark - 以下均为以section为单位的初始化方法

/**
 单section表格组件初始化方式，row值以填充contentSize的数量为标
 
 @param cellClass cell，以填充contentSize的数量为标准
 @param cellHeight  cell的高度
 @return object
 */
+ (instancetype)animatedWithCellClass:(Class)cellClass
                           cellHeight:(CGFloat)cellHeight;

/**
 单section表格组件初始化方式，row值以animatedCount为准
 
 @param cellClass 目标cell
 @param animatedCount 动画时row的数量
 @return object
 */
+ (instancetype)animatedWithCellClass:(Class)cellClass
                           cellHeight:(CGFloat)cellHeight
                        animatedCount:(NSInteger)animatedCount;

/**
 指定某个section，且与row无关，使用该初始化方法
 动画数量以填充contentSize的数量为准
 
 @param cellClass 注册的cell类型
 @param cellHeight 动画时cell高度
 @param section 被指定的section
 @return object
 */
+ (instancetype)animatedWithCellClass:(Class)cellClass
                           cellHeight:(CGFloat)cellHeight
                            toSection:(NSInteger)section;

/**
 如果原UITableView是多个section，但是只想指定一个section启动动画，使用该初始化方法
 
 @param cellClass 注册的cell类型
 @param cellHeight 动画时cell高度
 @param animatedCount 指定section的动画数量
 @param section 被指定的section
 @return object
 */
+ (instancetype)animatedWithCellClass:(Class)cellClass
                           cellHeight:(CGFloat)cellHeight
                        animatedCount:(NSInteger)animatedCount
                            toSection:(NSInteger)section;

/**
 视图结构要求：section和cell样式一一对应
 
 @param cellClassArray 目标cell数组
 @param animatedCountArray 动画时row的数量集合
 @return object
 */
+ (instancetype)animatedWithCellClassArray:(NSArray <Class> *)cellClassArray
                           cellHeightArray:(NSArray <NSNumber *> *)cellHeightArray
                        animatedCountArray:(NSArray <NSNumber *> *)animatedCountArray;

/**
 视图结构要求：section和cell样式一一对应
 
 上一个初始化方式，section和数组元素顺序对应，所有section都会有动画
 现在可以根据animatedSectionArray指定section，不指定的section没有动画。
 
 举个例子：
 比如 animatedSectionArray = @[@(3),@(4)];
 意思是 cellHeightArray,animatedCountArray,cellClassArray数组中的第一个元素，是 section == 3 的动画数据
 
 @param cellClassArray 目标cell数组
 @param cellHeightArray 目标cell对应高度
 @param animatedCountArray 对应section动画数量
 @param animatedSectionArray animatedSectionArray
 @return object
 */
+ (instancetype)animatedWithCellClassArray:(NSArray <Class> *)cellClassArray
                           cellHeightArray:(NSArray <NSNumber *> *)cellHeightArray
                        animatedCountArray:(NSArray <NSNumber *> *)animatedCountArray
                      animatedSectionArray:(NSArray <NSNumber *> *)animatedSectionArray;

#pragma mark - 以下均为以row为单位的初始化方法

/**
 视图结构要求：1个section对应多个cell，且只有1个section
 
 指定某个row配置动画
 animatedCount只能为1，无法设置animatedCount，只能为1
 
 @param cellClass 注册的cell类型
 @param cellHeight 动画时cell高度
 @param row 被指定的row
 @return object
 */
+ (instancetype)animatedInRowModeWithCellClass:(Class)cellClass
                                    cellHeight:(CGFloat)cellHeight
                                         toRow:(NSInteger)row;

/**
 视图结构要求：1个section对应多个cell，且只有1个section
 
 该section中所有row均会配置动画
 animatedCount只能为1，无法设置animatedCount，只能为1
 
 @param cellClassArray 目标cell数组
 @param cellHeightArray 目标cell对应高度
 @return object
 */
+ (instancetype)animatedInRowModeWithCellClassArray:(NSArray <Class> *)cellClassArray
                                    cellHeightArray:(NSArray <NSNumber *> *)cellHeightArray;

/**
 视图结构要求：1个section对应多个cell，且只有1个section
 
 指定row集合，不指定的row会执行你的代理方法。
 
 @param cellClassArray 目标cell数组
 @param cellHeightArray 目标cell对应高度
 @param rowArray rowArray
 @return object
 */
+ (instancetype)animatedInRowModeWithCellClassArray:(NSArray <Class> *)cellClassArray
                                    cellHeightArray:(NSArray <NSNumber *> *)cellHeightArray
                                           rowArray:(NSArray <NSNumber *> *)rowArray;

#pragma mark - 自适应高度的初始化方法

/**
 满足以下两个条件使用该初始化方法：
 1. 自适应高度
 2. section数量为1，且只有一种cell
 
 @param cellClass 目标cell
 @return object
 */
+ (instancetype)animatedWithCellClass:(Class)cellClass;

#pragma mark - 添加 header / footer

/**
 添加区头动画，指定section
 
 @param headerViewClass 区头类对象
 @param viewHeight 区头高度
 @param section 指定的section
 */
- (void)addHeaderViewClass:(__nonnull Class)headerViewClass
                viewHeight:(CGFloat)viewHeight
                 toSection:(NSInteger)section;

/**
 添加区头动画
 不指定section，意味着所有section都会加入该区头动画，
 仅设置animatedSectionCount属性生效
 
 @param headerViewClass 区头类对象
 @param viewHeight 区头高度
 */
- (void)addHeaderViewClass:(__nonnull Class)headerViewClass
                viewHeight:(CGFloat)viewHeight;

/**
 添加区尾动画，指定section

 @param footerViewClass 区尾类对象
 @param viewHeight 区尾高度
 @param section 指定的section
 */
- (void)addFooterViewClass:(__nonnull Class)footerViewClass
                viewHeight:(CGFloat)viewHeight
                 toSection:(NSInteger)section;

/**
 添加区尾动画
 不指定section，意味着所有section都会加入该区尾动画，
 仅设置animatedSectionCount属性生效
 
 @param footerViewClass 区尾类对象
 @param viewHeight 区尾高度
 */
- (void)addFooterViewClass:(__nonnull Class)footerViewClass
                viewHeight:(CGFloat)viewHeight;

#pragma mark -

- (NSInteger)headerNeedAnimationOnSection:(NSInteger)section;

- (NSInteger)footerNeedAnimationOnSection:(NSInteger)section;

- (void)exchangeTableViewDelegate:(UITableView *)target;

- (void)exchangeTableViewDataSource:(UITableView *)target;

@end

#pragma mark -

@interface FWTabEstimatedTableViewDelegate : NSObject

@end

@interface FWTabCollectionAnimated : FWTabViewAnimated

#pragma mark - readwrite

/**
 cell样式 == 1时，UICollectionView的cellSize。
 */
@property (nonatomic, assign) CGSize cellSize;

/**
 cell样式 > 1时，UICollectionView的cellSize集合。
 */
@property (nonatomic, copy) NSArray <NSValue *> *cellSizeArray;

/**
 特殊情况下才需要使用，
 仅用于动态section，即section的数量是根据获取到的数据而变化的。
 */
@property (nonatomic, assign) NSInteger animatedSectionCount;

/**
 设置单section动画时row数量，默认填充屏幕为准
 **/
@property (nonatomic, assign) NSInteger animatedCount;

#pragma mark - readonly, 不建议重写的属性

/**
 你不需要手动赋值，但是你需要知道当前视图的结构，
 从而选择初始化方法和启动方法。
 */
@property (nonatomic, assign, readonly) FWTabAnimatedRunMode runMode;

/**
 指定某些section / row加载动画集合
 不设置默认为工程中所有的section。
 */
@property (nonatomic, copy) NSArray <NSNumber *> *animatedIndexArray;

/**
 当前正在动画中的分区
 */
@property (nonatomic, strong) NSMutableArray <NSNumber *> *runAnimationIndexArray;

/**
 是否已经交换了delegate的IMP地址
 */
@property (nonatomic, assign, readonly) BOOL isExhangeDelegateIMP;

/**
 是否已经交换了dataSource的IMP地址
 */
@property (nonatomic, assign, readonly) BOOL isExhangeDataSourceIMP;

/**
 存储头视图相关，在完全理解原理的情况下，可以采用直接赋值
 否则建议使用`addHeaderViewClass:viewSize:toSection`
 */
@property (nonatomic, strong, readonly) NSMutableArray <Class> *headerClassArray;
@property (nonatomic, strong, readonly) NSMutableArray <NSValue *> *headerSizeArray;
@property (nonatomic, strong, readonly) NSMutableArray <NSNumber *> *headerSectionArray;

/**
 存储尾视图相关，在完全理解原理的情况下，可以采用直接赋值
 否则建议使用`addFooterViewClass:viewSize:toSection`
 */
@property (nonatomic, strong, readonly) NSMutableArray <Class> *footerClassArray;
@property (nonatomic, strong, readonly) NSMutableArray <NSValue *> *footerSizeArray;
@property (nonatomic, strong, readonly) NSMutableArray <NSNumber *> *footerSectionArray;

#pragma mark -

/**
 单section表格组件初始化方式，row值以填充contentSize的数量为标准
 
 @param cellClass cell，以填充contentSize的数量为标准
 @param cellSize  cell的高度
 @return 目标对象
 */
+ (instancetype)animatedWithCellClass:(Class)cellClass
                             cellSize:(CGSize)cellSize;

/**
 单section表格组件初始化方式，row值以填充contentSize的数量为标准
 
 @param cellClass 模版cell
 @param animatedCount 动画时row值
 @return 目标对象
 */
+ (instancetype)animatedWithCellClass:(Class)cellClass
                             cellSize:(CGSize)cellSize
                        animatedCount:(NSInteger)animatedCount;

#pragma mark - 以下均为以section为单位的初始化方法

/**
 如果原UICollectionView是多个section，但是只想指定一个section启动动画，使用该初始化方法
 动画数量以填充contentSize的数量为标准
 
 @param cellClass 注册的cell类型
 @param cellSize 动画时cell的size
 @param section 被指定的section
 @return 目标对象
 */
+ (instancetype)animatedWithCellClass:(Class)cellClass
                             cellSize:(CGSize)cellSize
                            toSection:(NSInteger)section;

/**
 如果原UICollectionView是多个section，但是只想指定一个section启动动画，使用该初始化方法
 
 @param cellClass 注册的cell类型
 @param cellSize 动画时cell的size
 @param animatedCount 指定section的动画数量
 @param section 被指定的section
 @return 目标对象
 */
+ (instancetype)animatedWithCellClass:(Class)cellClass
                             cellSize:(CGSize)cellSize
                        animatedCount:(NSInteger)animatedCount
                            toSection:(NSInteger)section;

/**
 视图结构要求：section和cell样式一一对应
 
 @param cellClassArray 模版cell数组
 @param animatedCountArray 动画时row值的集合
 @return 目标对象
 */
+ (instancetype)animatedWithCellClassArray:(NSArray <Class> *)cellClassArray
                             cellSizeArray:(NSArray <NSValue *> *)cellSizeArray
                        animatedCountArray:(NSArray <NSNumber *> *)animatedCountArray;

/**
 视图结构要求：section和cell样式一一对应
 
 上一个初始化方式，section和数组元素依次对应，所有section都会有动画
 现在可以根据animatedSectionArray指定section，不指定的section没有动画。
 
 举个例子：
 比如 animatedSectionArray = @[@(3),@(4)];
 意思是 cellSizeArray,animatedCountArray,cellClassArray数组中的第一个元素，是 section == 3 的动画数据
 
 @param cellClassArray 模版cell数组
 @param cellSizeArray 模版cell对应size
 @param animatedCountArray 对应section动画数量
 @param animatedSectionArray animatedSectionArray
 @return 目标对象
 */
+ (instancetype)animatedWithCellClassArray:(NSArray <Class> *)cellClassArray
                             cellSizeArray:(NSArray <NSValue *> *)cellSizeArray
                        animatedCountArray:(NSArray <NSNumber *> *)animatedCountArray
                      animatedSectionArray:(NSArray <NSNumber *> *)animatedSectionArray;

#pragma mark - 以下均为以row为单位的初始化方法

/**
 视图结构要求：1个section对应多个cell，且只有1个section
 
 指定row配置动画
 animatedCount只能为1，无法设置animatedCount，只能为1
 
 @param cellClass 注册的cell类型
 @param cellSize 动画时cell size
 @param row 被指定的row
 @return object
 */
+ (instancetype)animatedInRowModeWithCellClass:(Class)cellClass
                                      cellSize:(CGSize)cellSize
                                         toRow:(NSInteger)row;

/**
 视图结构要求：1个section对应多个cell，且只有1个section
 
 该section中所有row均会配置动画
 animatedCount只能为1，无法设置animatedCount，只能为1
 
 @param cellClassArray 目标cell数组
 @param cellSizeArray 目标cell对应size集合
 @return object
 */
+ (instancetype)animatedInRowModeWithCellClassArray:(NSArray <Class> *)cellClassArray
                                      cellSizeArray:(NSArray <NSValue *> *)cellSizeArray;

/**
 视图结构要求：1个section对应多个cell，且只有1个section
 
 此初始化指定row，不指定的row会执行你的代理方法。
 
 举个例子：
 比如 animatedRowArray = @[@(3),@(4)];
 意思是 cellHeightArray，animatedCountArray，cellClassArray数组中的第一个元素，是 row == 3 的动画数据
 
 @param cellClassArray 目标cell数组
 @param cellSizeArray 目标cell对应size
 @param rowArray rowArray
 @return object
 */
+ (instancetype)animatedInRowModeWithCellClassArray:(NSArray <Class> *)cellClassArray
                                      cellSizeArray:(NSArray <NSValue *> *)cellSizeArray
                                           rowArray:(NSArray <NSNumber *> *)rowArray;

#pragma mark - Header / Footer

/**
 添加区头动画，指定section
 
 @param headerViewClass 区头类对象
 @param viewSize 区头size
 @param section 指定的section
 */
- (void)addHeaderViewClass:(_Nonnull Class)headerViewClass
                  viewSize:(CGSize)viewSize
                 toSection:(NSInteger)section;

/**
 添加区头动画
 不指定section，意味着所有section都会加入该区头动画，
 仅设置animatedSectionCount属性生效
 
 @param headerViewClass 区头类对象
 @param viewSize 区头size
 */
- (void)addHeaderViewClass:(_Nonnull Class)headerViewClass
                  viewSize:(CGSize)viewSize;

/**
 添加区尾动画，指定section
 
 @param footerViewClass 区尾类对象
 @param viewSize 区尾size
 @param section 指定的section
 */
- (void)addFooterViewClass:(_Nonnull Class)footerViewClass
                  viewSize:(CGSize)viewSize
                 toSection:(NSInteger)section;

/**
 添加区尾动画
 不指定section，意味着所有section都会加入该区尾动画，
 仅设置animatedSectionCount属性生效
 
 @param footerViewClass 区尾类对象
 @param viewSize 区尾size
 */
- (void)addFooterViewClass:(_Nonnull Class)footerViewClass
                  viewSize:(CGSize)viewSize;

#pragma mark -

- (NSInteger)headerFooterNeedAnimationOnSection:(NSInteger)section
                                           kind:(NSString *)kind;

- (void)exchangeCollectionViewDelegate:(UICollectionView *)target;

- (void)exchangeCollectionViewDataSource:(UICollectionView *)target;

@end

extern NSString * const FWTabAnimatedAlphaAnimation;  /// the key of bin animation
extern NSString * const FWTabAnimatedLocationAnimation;  /// the key of flex animation
extern NSString * const FWTabAnimatedShimmerAnimation;  ///the key of shimmer animation
extern NSString * const FWTabAnimatedDropAnimation;   /// the key of drop animation

@class FWTabTableDeDaSelfModel, FWTabCollectionDeDaSelfModel, FWTabAnimatedCacheManager;

/**
 * Gobal animation type,
 * which determines whether you need to add additional animations on top of the skeleton layer.
 *
 * Besides `FWTabAnimationTypeOnlySkeleton` outside value, can add additional an animation.
 *
 * When you have a specified view that doesn't need a global animation type that's already set,
 * You can use a `FWTabViewSuperAnimationType` covering the local properties `FWTabAnimationType` values.
 *
 * 全局动画类型，它决定了你是否需要在骨架层的基础之上，增加额外的动画。
 *
 * 除了`FWTabAnimationTypeOnlySkeleton`以外的值，都会添加额外的一种动画。
 *
 * 当你有一个指定的view不需要已经设置好的全局的动画类型时，
 * 你可以使用`FWTabViewSuperAnimationType`这个局部属性覆盖`FWTabAnimationType`的值。
 */
typedef NS_ENUM(NSInteger, FWTabAnimationType) {
    
    /// only contain the skeleton of your view created by CALayer
    /// 骨架层
    FWTabAnimationTypeOnlySkeleton = 0,
    
    /// the skeleton of your view with bin animation
    /// 骨架层 + 呼吸灯动画
    FWTabAnimationTypeBinAnimation,
    
    /// the skeleton of your view with shimmer animation
    /// 骨架层 + 闪光灯
    FWTabAnimationTypeShimmer,
    
    /// the skeleton of your view with drop animation
    /// 骨架层 + 豆瓣下坠动画
    FWTabAnimationTypeDrop
};

/**
 * Control some global attributes,
 * including breath lamp animation, flash animation, douban drop animation global parameter Settings.
 * At the same time, there are auxiliary development, debugging parameter Settings.
 *
 * Init types of methods, must be in `didFinishLaunchingWithOptions` first use.
 *
 * 控制一些全局的属性，包含了呼吸灯动画、闪光灯动画、豆瓣下坠动画的全局参数设置。
 * 同时还有辅助开发、调试的参数设置。
 *
 * init类型的方法，必须要在`didFinishLaunchingWithOptions`首先使用
 *
 * @see https://github.com/tigerAndBull/TABAnimated
 */
@interface FWTabAnimated : NSObject

/**
 * Global animation type
 *
 * Default is to include the skeleton layer.
 * The last three values are based on the skeleton layer, with additional animations added by default.
 *
 * 全局动画类型
 *
 * 默认是只有骨架层，后三者是在骨架层的基础之上，还会默认加上额外的动画。
 * 优先级：全局动画类型 < 控制视图声明的动画类型
 */
@property (nonatomic, assign) FWTabAnimationType animationType;

/**
 * The ratio of the height of the animation to the original height of the view,
 * This property is valid for all subviews except for the type 'UIImageView'.
 *
 * In practice, it is found that for UILabel, UIButton and other views, when the height of animation is the same as the height of the original
 * view, the effect is not beautiful (too thick).
 * Keep the ratio around 0.75, the animation effect will look more beautiful, the specific coefficient can be modified according to your own
 * aesthetic.
 *
 * 动画高度与视图原有高度的比例系数，
 * 该属性对除了`UIImageView`类型的所有子视图生效。
 *
 * 在实践中发现，对于UILabel, UIButton等视图，当动画的高度与原视图的高度一致时，效果并不美观（太粗）。
 * 大概保持在原高度的0.75的比例，动画效果会看起来比较美观，具体系数可以根据你自己的审美进行修改。
 */
@property (nonatomic, assign) CGFloat animatedHeightCoefficient;

/**
 * Global animation content color, default value 0xEEEEEE
 *
 * 全局动画内容颜色，默认值为0xEEEEEE
 */
@property (nonatomic, strong) UIColor *animatedColor;

/**
 * Global animation background color, the default value is UIColor.whiteColor
 *
 * 全局动画背景颜色，默认值为UIColor.whiteColor
 */
@property (nonatomic, strong) UIColor *animatedBackgroundColor;

/**
 * Whether global rounded corners are enabled.
 * When enabled, global rounded corners default to animation height / 2.0.
 *
 * 是否开启全局圆角
 * 开启后，全局圆角默认值为: 动画高度/2.0
 */
@property (nonatomic, assign) BOOL useGlobalCornerRadius;

/**
 * Global rounded corner value
 *
 * priority: this property < view's own rounded corner
 *
 * When you need to personalize rounded corners,
 * you can override the value of this property by chain-syntax '.radius(x)'.
 *
 * 全局圆角的值
 *
 * 优先级：此属性 < view自身的圆角
 *
 * 当需要个性化设置圆角的时候，你可以通过链式语法`.radius(x)`覆盖此属性的值。
 */
@property (nonatomic, assign) CGFloat animatedCornerRadius;

/**
 * It determines whether setting the global animation height
 * After use it, all animation elements except those based on the 'UIImageView' type mapping are set to the value of 'animatedHeight'.
 *
 * When the developer sets 'animatedHeight' in 'FWTabViewAnimated', the change will be overwritten,
 * When developers use the chain function '.height(x)' to set the height, it has the highest priority.
 *
 * Priority: global height animatedHeight < FWTabViewAnimated animatedHeight < the height of a single animation element
 *
 * 是否需要全局动画高度，
 * 使用后，所有除了基于`UIImageView`类型映射的动画元素，高度都会设置为`animatedHeight`的高度。
 *
 * 当开发者设置了`FWTabViewAnimated`中的`animatedHeight`时，将会覆盖改值，
 * 当开发者使用链式语法`.height(x)`设置高度时，则具有最高优先级
 *
 * 优先级：全局高度animatedHeight < FWTabViewAnimated中animatedHeight < 单个设置动画元素的高度
 */
@property (nonatomic, assign) BOOL useGlobalAnimatedHeight;

/**
 * Global animation height
 * Set to take effect, and does not contain animation elements that are mapped by the 'UIImageView' type.
 *
 * 全局动画高度
 * 设置后生效，且不包含`UIImageView`类型映射出的动画元素。
 */
@property (nonatomic, assign) CGFloat animatedHeight;

/**
 * An object that manages  skeleton screen cache.
 * 管理骨架屏缓存的全局对象
 */
@property (nonatomic, strong, readonly) FWTabAnimatedCacheManager *cacheManager;

#pragma mark - Other

/**
 * Whether to turn on console Log reminder, default is NO.
 * 是否开启控制台Log提醒，默认不开启
 */
@property (nonatomic, assign) BOOL openLog;

/**
 * Whether to turn on the animation subscript mark, default is NO.
 * This property, even if it is 'YES', will only take effect in the debug environment.
 *
 * When opened, a red number will be added to each animation element, which represents the subscript of the animation element, so as
 *  to quickly locate an animation element.
 *
 * 是否开启动画下标标记，默认不开启
 * 这个属性即使是`YES`，也仅会在debug环境下生效。
 *
 * 开启后，会在每一个动画元素上增加一个红色的数字，该数字表示该动画元素所在的下标，方便快速定位某个动画元素。
 */
@property (nonatomic, assign) BOOL openAnimationTag;

/**
 * 关闭缓存功能
 * DEBUG环境下，默认关闭缓存功能（为了方便调试预处理回调），即为YES
 * RELEASE环境下，默认开启缓存功能，即为NO
 *
 * 如果你想在DEBUG环境下测试缓存功能，可以手动置为YES
 * 如果你始终都不想使用缓存功能，可以手动置为NO
 */
@property (nonatomic, assign) BOOL closeCache;

#pragma mark - Dark Mode

/**
 * set the backgroundColor of animations in dark mode.
 * 暗黑模式下，动画背景色
 */
@property (nonatomic, strong) UIColor *darkAnimatedBackgroundColor;

/**
 * set the contentColor of animations in dark mode.
 * 暗黑模式下，动画内容的颜色
 */
@property (nonatomic, strong) UIColor *darkAnimatedColor;

#pragma mark - Flex Animation

/**
 * Flex animation back and forth duration
 * 伸缩动画来回时长
 */
@property (nonatomic, assign) CGFloat animatedDuration;

/**
 * Variable length scaling
 * 变长伸缩比例
 */
@property (nonatomic, assign) CGFloat longToValue;

/**
 * Shortening scaling
 * 变短伸缩比例
 */
@property (nonatomic, assign) CGFloat shortToValue;

#pragma mark - Bin Animation

/**
 * Bin animation duration, default is 1s.
 * 呼吸灯动画的时长，默认是1s。
 */
@property (nonatomic, assign) CGFloat animatedDurationBin;

#pragma mark - Shimmer Animation

/**
 * Shimmer animation duration, default is 1s.
 * 闪光灯动画的时长，默认是1s。
 */
@property (nonatomic, assign) CGFloat animatedDurationShimmer;

/**
 * Shimmer animation direction,
 * The default is `FWTabShimmerDirectionToRight`, means from left to right.
 *
 * 闪光灯动画的方向，
 * 默认是`FWTabShimmerDirectionToRight`,意思为从左往右。
 */
@property (nonatomic, assign) FWTabShimmerDirection shimmerDirection;

/**
 * Shimmer animation color change value, default 0xDFDFDF.
 * 闪光灯变色值，默认值0xDFDFDF
 */
@property (nonatomic, strong) UIColor *shimmerBackColor;

/**
 * the brightness of Shimmer animation, default 0.92.
 * 闪光灯亮度，默认值0.92
 */
@property (nonatomic, assign) CGFloat shimmerBrightness;

/**
 * the backgroundColor of shimmer animation in dark mode.
 * 暗黑模式下，全局闪光灯背景色
 */
@property (nonatomic, strong) UIColor *shimmerBackColorInDarkMode;

/**
 * the bightness of shimmer animation in dark mode.
 * 暗黑模式下，全局闪光灯颜色亮度
*/
@property (nonatomic, assign) CGFloat shimmerBrightnessInDarkMode;

#pragma mark - Douban animation

/**
 * Douban animation frame length,
 * the default value is 0.4, you can understand as 'discoloration speed'.
 *
 * 豆瓣动画帧时长，默认值为0.4，你可以理解为`变色速度`。
 */
@property (nonatomic, assign) CGFloat dropAnimationDuration;

/**
 * Douban animation color change value, default value is 0xE1E1E1.
 * 豆瓣动画变色值，默认值为0xE1E1E1
 */
@property (nonatomic, strong) UIColor *dropAnimationDeepColor;

/**
 * Douban animation color change value in dark mode.
 * 暗黑模式下豆瓣动画变色值
*/
@property (nonatomic, strong) UIColor *dropAnimationDeepColorInDarkMode;

#pragma mark - `self.delegate = self`

@property (nonatomic, strong, readonly) NSMutableArray <FWTabTableDeDaSelfModel *> *tableDeDaSelfModelArray;
@property (nonatomic, strong, readonly) NSMutableArray <FWTabCollectionDeDaSelfModel *> *collectionDeDaSelfModelArray;

- (FWTabTableDeDaSelfModel *)getTableDeDaModelAboutDeDaSelfWithClassName:(NSString *)className;
- (FWTabCollectionDeDaSelfModel *)getCollectionDeDaModelAboutDeDaSelfWithClassName:(NSString *)className;

#pragma mark - Init Method

/**
 * SingleTon
 * 单例模式
 *
 * @return return object
 */
+ (FWTabAnimated *)sharedAnimated;

/**
 * Only contain the skeleton of your view created by CALayer.
 * 骨架层
 */
- (void)initWithOnlySkeleton;

/**
 * the skeleton layer + bin animation
 * 全局呼吸灯动画
 */
- (void)initWithBinAnimation;

/**
 * the skeleton layer + shimmer animation
 * 全局闪光灯动画
 */
- (void)initWithShimmerAnimated;

/**
 * the skeleton layer + shimmer animation
 * 全局闪光灯动画
 *
 * @param duration 时长 (duration of one trip)
 * @param color 动画内容颜色 (animation content color)
 */
- (void)initWithShimmerAnimatedDuration:(CGFloat)duration
                              withColor:(UIColor *)color;

/**
 * the skeleton layer + drop animation
 * 全局豆瓣动画
 */
- (void)initWithDropAnimated;

@end

NS_ASSUME_NONNULL_END
