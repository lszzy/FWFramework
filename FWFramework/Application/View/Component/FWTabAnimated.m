/*!
 @header     FWTabAnimated.m
 @indexgroup FWFramework
 @brief      FWTabAnimated
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/12/13
 */

#import "FWTabAnimated.h"
#import <objc/runtime.h>

@implementation FWTabAnimationMethod

+ (CABasicAnimation *)scaleXAnimationDuration:(CGFloat)duration
                                      toValue:(CGFloat)toValue {
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.scale.x"];
    animation.removedOnCompletion = NO;
    animation.duration = duration;
    animation.autoreverses = YES;
    animation.repeatCount = HUGE_VALF;
    animation.toValue = (toValue == 0.)?@0.6:@(toValue);
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    return animation;
}

+ (void)addAlphaAnimation:(UIView *)view
                 duration:(CGFloat)duration
                      key:(NSString *)key {
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation.fromValue = [NSNumber numberWithFloat:1.1f];
    animation.toValue = [NSNumber numberWithFloat:0.6f];
    animation.autoreverses = YES;
    animation.duration = duration;
    animation.repeatCount = HUGE_VALF;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    [view.layer addAnimation:animation forKey:key];
}

+ (void)addShimmerAnimationToLayer:(CALayer *)layer
                          duration:(CGFloat)duration
                               key:(NSString *)key
                         direction:(FWTabShimmerDirection)direction {
    
    FWTabShimmerTransition startPointTransition = transitionMaker(direction, FWTabShimmerPropertyStartPoint);
    FWTabShimmerTransition endPointTransition = transitionMaker(direction, FWTabShimmerPropertyEndPoint);
    
    CABasicAnimation *startPointAnim = [CABasicAnimation animationWithKeyPath:@"startPoint"];
    startPointAnim.fromValue = [NSValue valueWithCGPoint:startPointTransition.startValue];
    startPointAnim.toValue = [NSValue valueWithCGPoint:startPointTransition.endValue];
    
    CABasicAnimation *endPointAnim = [CABasicAnimation animationWithKeyPath:@"endPoint"];
    endPointAnim.fromValue = [NSValue valueWithCGPoint:endPointTransition.startValue];
    endPointAnim.toValue = [NSValue valueWithCGPoint:endPointTransition.endValue];
    
    CAAnimationGroup *animGroup = [[CAAnimationGroup alloc] init];
    animGroup.animations = @[startPointAnim, endPointAnim];
    animGroup.duration = duration;
    animGroup.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    animGroup.repeatCount = HUGE_VALF;
    animGroup.removedOnCompletion = NO;
    
    [layer addAnimation:animGroup forKey:key];
}

+ (void)addDropAnimation:(CALayer *)layer
                   index:(NSInteger)index
                duration:(CGFloat)duration
                   count:(NSInteger)count
                stayTime:(CGFloat)stayTime
               deepColor:(UIColor *)deepColor
                     key:(NSString *)key {
    
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"backgroundColor"];
    animation.values = @[
                         (id)deepColor.CGColor,
                         (id)layer.backgroundColor,
                         (id)layer.backgroundColor,
                         (id)deepColor.CGColor
                         ];
    
    animation.keyTimes = @[@0,@(stayTime),@1,@1];
    // count+3 为了增加末尾的等待时间，不然显得很急促
    animation.beginTime = CACurrentMediaTime() + index*(duration/(count+3));
    animation.duration = duration;
    animation.removedOnCompletion = NO;
    animation.repeatCount = HUGE_VALF;
    animation.fillMode = kCAFillModeForwards;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [layer addAnimation:animation forKey:key];
}

+ (void)addEaseOutAnimation:(UIView *)view {
    CATransition *animation = [CATransition animation];
    animation.duration = 0.2;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.type = kCATransitionFade;
    [view.layer addAnimation:animation forKey:@"animation"];
}

static FWTabShimmerTransition transitionMaker(FWTabShimmerDirection dir, FWTabShimmerProperty position) {
    
    if (dir == FWTabShimmerDirectionToLeft) {
        FWTabShimmerTransition transition;
        if (position == FWTabShimmerPropertyStartPoint) {
            transition.startValue = CGPointMake(1, 0.5);
            transition.endValue = CGPointMake(-1, 0.5);
        }else {
            transition.startValue = CGPointMake(2, 0.5);
            transition.endValue = CGPointMake(0, 0.5);
        }
        
        return transition;
    }
    
    FWTabShimmerTransition transition;
    if (position == FWTabShimmerPropertyStartPoint) {
        transition.startValue = CGPointMake(-1, 0.5);
        transition.endValue = CGPointMake(1, 0.5);
    }else {
        transition.startValue = CGPointMake(0, 0.5);
        transition.endValue = CGPointMake(2, 0.5);
    }
    
    return transition;
}

@end

NSString * const FWTabCacheManagerFolderName = @"FWTabAnimated";
NSString * const FWTabCacheManagerCacheModelFolderName = @"CacheModel";
NSString * const FWTabCacheManagerCacheManagerFolderName = @"CacheManager";

static const NSInteger kMemeoryModelMaxCount = 20;

@interface FWTabAnimatedCacheManager()

@property (nonatomic, strong) NSRecursiveLock *lock;

// 当前App版本
@property (nonatomic, copy, readwrite) NSString *currentSystemVersion;
// 本地的缓存
@property (nonatomic, strong, readwrite) NSMutableArray *cacheModelArray;
// 内存中的骨架屏管理单元
@property (nonatomic, strong, readwrite) NSMutableDictionary *cacheManagerDict;

@end

@implementation FWTabAnimatedCacheManager

+ (dispatch_queue_t)updateQueue {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("com.tigerAndBull.FWTabAnimated.updateQueue", DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(queue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
    });
    return queue;
}

+ (void)updateThreadMain:(id)object {
    @autoreleasepool {
        [[NSThread currentThread] setName:@"com.tigerAndBull.FWTabAnimated.updateThread"];
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
        [runLoop run];
    }
}

+ (NSThread *)updateThread {
    static NSThread *thread = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        thread = [[NSThread alloc] initWithTarget:self selector:@selector(updateThreadMain:) object:nil];
        if ([thread respondsToSelector:@selector(setQualityOfService:)]) {
            thread.qualityOfService = NSQualityOfServiceBackground;
        }
        [thread start];
    });
    return thread;
}

- (instancetype)init {
    if (self = [super init]) {
        _cacheModelArray = @[].mutableCopy;
        _cacheManagerDict = @{}.mutableCopy;
        _lock = [NSRecursiveLock new];
    }
    return self;
}

#pragma mark - Public Methods

- (void)install {
    
    // 获取App版本
    NSString *currentVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    if (currentVersion == nil && currentVersion.length <= 0) {
        return;
    }
    _currentSystemVersion = currentVersion;
    

    NSString *documentDir = [FWTabAnimatedDocumentMethod getFWTabPathByFilePacketName:FWTabCacheManagerFolderName];
    if (![FWTabAnimatedDocumentMethod isExistFile:documentDir
                                          isDir:YES]) {
        [FWTabAnimatedDocumentMethod createFile:documentDir
                                        isDir:YES];
    }

    NSString *modelDirPath = [documentDir stringByAppendingPathComponent:FWTabCacheManagerCacheModelFolderName];
    NSString *managerDirPath = [documentDir stringByAppendingPathComponent:FWTabCacheManagerCacheManagerFolderName];
    
    if (![FWTabAnimatedDocumentMethod isExistFile:modelDirPath
                                          isDir:YES] ||
        ![FWTabAnimatedDocumentMethod isExistFile:managerDirPath
                                          isDir:YES]) {
        [FWTabAnimatedDocumentMethod createFile:modelDirPath
                                        isDir:YES];
        [FWTabAnimatedDocumentMethod createFile:managerDirPath
                                        isDir:YES];
    }else {
        dispatch_async([self.class updateQueue], ^{
            [self performSelector:@selector(_loadDataToMemory:)
                         onThread:[self.class updateThread]
                       withObject:modelDirPath
                    waitUntilDone:NO];
        });
    }
}

- (void)cacheComponentManager:(FWTabComponentManager *)manager {
    
    if ((manager == nil) ||
        (manager.fileName == nil) ||
        (manager.fileName.length == 0)) return;
    
    if ((_currentSystemVersion == nil) ||
        (_currentSystemVersion.length == 0)) return;
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) self = weakSelf;
        [self.lock lock];
        manager.version = self.currentSystemVersion.copy;
        [self.cacheManagerDict setObject:manager.copy forKey:manager.fileName];
        
        FWTabAnimatedCacheModel *cacheModel = FWTabAnimatedCacheModel.new;
        cacheModel.fileName = manager.fileName;
        [self.cacheModelArray addObject:cacheModel];
        [self.lock unlock];
        
        NSArray *writeArray = @[cacheModel,manager];
        dispatch_async([self.class updateQueue], ^{
            [self performSelector:@selector(didReceiveWriteRequest:)
                         onThread:[self.class updateThread]
                       withObject:writeArray
                    waitUntilDone:NO];
        });
    });
}

- (nullable FWTabComponentManager *)getComponentManagerWithFileName:(NSString *)fileName {
    
    if ([FWTabAnimated sharedAnimated].closeCache) return nil;
    
    // 从内存中查找
    FWTabComponentManager *manager;
    manager = [self.cacheManagerDict objectForKey:fileName];
    if (manager) {
        if (!manager.needUpdate) {
            return manager.copy;
        }
        return nil;
    }
    
    // 从沙盒中读取，并存储到内存中
    NSString *filePath = [self _getCacheManagerFilePathWithFileName:fileName];
    if (filePath != nil && filePath.length > 0) {
        FWTabComponentManager *manager = (FWTabComponentManager *)[FWTabAnimatedDocumentMethod getCacheData:filePath targetClass:[FWTabComponentManager class]];
        if (manager) {
            if (!manager.needUpdate) {
                [self.cacheManagerDict setObject:manager.copy forKey:manager.fileName];
                return manager.copy;
            }else {
                return nil;
            }
        }else {
            return nil;
        }
    }
    
    return nil;
}

- (void)updateCacheModelLoadCountWithTableAnimated:(FWTabTableAnimated *)viewAnimated {

    if (viewAnimated == nil) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (viewAnimated == nil) return;
        
        NSString *controllerName = viewAnimated.targetControllerClassName;
        
        for (Class class in viewAnimated.cellClassArray) {
            [self updateCacheModelLoadCountWithClass:class controllerName:controllerName];
        }
        
        for (Class class in viewAnimated.headerClassArray) {
            [self updateCacheModelLoadCountWithClass:class controllerName:controllerName];
        }
        
        for (Class class in viewAnimated.footerClassArray) {
            [self updateCacheModelLoadCountWithClass:class controllerName:controllerName];
        }
    });
}

- (void)updateCacheModelLoadCountWithCollectionAnimated:(FWTabCollectionAnimated *)viewAnimated {
    
    if (viewAnimated == nil) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{

        if (viewAnimated == nil) return;
        
        NSString *controllerName = viewAnimated.targetControllerClassName;
    
        for (Class class in viewAnimated.cellClassArray) {
            [self updateCacheModelLoadCountWithClass:class controllerName:controllerName];
        }
        
        for (Class class in viewAnimated.headerClassArray) {
            [self updateCacheModelLoadCountWithClass:class controllerName:controllerName];
        }
        
        for (Class class in viewAnimated.footerClassArray) {
            [self updateCacheModelLoadCountWithClass:class controllerName:controllerName];
        }
    });
}

#pragma mark - Private Method

- (void)_loadDataToMemory:(NSString *)modelDirPath {

    if (modelDirPath == nil ||
        modelDirPath.length == 0) return;
    
    NSError *error;
    NSArray <NSString *> *fileArray =
    [[NSFileManager defaultManager] contentsOfDirectoryAtPath:modelDirPath
                                                        error:&error];
    
    if (error) return;
    
    @autoreleasepool {
        
        [_lock lock];
        
        NSMutableArray *cacheModelArray = @[].mutableCopy;
        for (NSString *filePath in fileArray) {
            NSString *resultFilePath = [[FWTabAnimatedDocumentMethod getFWTabPathByFilePacketName:FWTabCacheManagerFolderName] stringByAppendingString:[NSString stringWithFormat:@"/%@/%@",FWTabCacheManagerCacheModelFolderName,filePath]];
            FWTabAnimatedCacheModel *model =
            (FWTabAnimatedCacheModel *)[FWTabAnimatedDocumentMethod
                                           getCacheData:resultFilePath
                                            targetClass:[FWTabAnimatedCacheModel class]];
            if (model) {
                [cacheModelArray addObject:model];
            }
        }
        
        _cacheModelArray = [NSMutableArray arrayWithArray:[cacheModelArray sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            FWTabAnimatedCacheModel *model1 = obj1;
            FWTabAnimatedCacheModel *model2 = obj2;
            if (model1.loadCount > model2.loadCount) {
                return NSOrderedAscending;
            }else{
                return NSOrderedDescending;
            }
        }]];

        [_lock unlock];
        
        if (_cacheModelArray == nil || _cacheModelArray.count == 0) return;
        
        NSInteger maxCount = (_cacheModelArray.count > kMemeoryModelMaxCount) ? kMemeoryModelMaxCount : _cacheModelArray.count;
        
        for (NSInteger i = 0; i < maxCount; i++) {
            
            FWTabAnimatedCacheModel *model = _cacheModelArray[i];
            NSString *filePath = [self _getCacheManagerFilePathWithFileName:model.fileName];
            
            [_lock lock];
            FWTabComponentManager *manager =
            (FWTabComponentManager *)[FWTabAnimatedDocumentMethod getCacheData:filePath
                                                               targetClass:[FWTabComponentManager class]];
            if (manager &&
                manager.fileName &&
                manager.fileName.length > 0) {
                [_cacheManagerDict setObject:manager.copy forKey:manager.fileName];
            }
            [_lock unlock];
        }
    }
}

- (void)updateCacheModelLoadCountWithClass:(Class)class
                            controllerName:(NSString *)controllerName {
    if (class) {
        NSString *fileName = [NSStringFromClass(class) stringByAppendingString:[NSString stringWithFormat:@"_%@",controllerName]];
        if (fileName) {
            dispatch_async([self.class updateQueue], ^{
                [self performSelector:@selector(updateCacheModelLoadCountWithTargetFileName:)
                             onThread:[self.class updateThread]
                           withObject:fileName
                        waitUntilDone:NO];
            });
        }
    }
}

- (void)updateCacheModelLoadCountWithTargetFileName:(NSString *)targetFileName {
    
    if (targetFileName == nil || targetFileName.length == 0) return;
    
    [_lock lock];
    
    FWTabAnimatedCacheModel *targetCacheModel;
    for (FWTabAnimatedCacheModel *model in self.cacheModelArray) {
        if ([model.fileName isEqualToString:targetFileName]) {
            targetCacheModel = model;
            break;
        }
    }
    
    if (targetCacheModel) {
        
        ++targetCacheModel.loadCount;
        
        NSString *filePath = [self _getCacheModelFilePathWithFileName:targetCacheModel.fileName];
        if (filePath && filePath.length > 0) {
            if ([FWTabAnimatedDocumentMethod isExistFile:filePath
                                                  isDir:NO]) {
                [FWTabAnimatedDocumentMethod writeToFileWithData:targetCacheModel
                                                      filePath:filePath];
            }
        }
    }
    
    [_lock unlock];
}

- (void)didReceiveWriteRequest:(NSArray *)array {
    
    if (array == nil || array.count != 2) return;
    
    [_lock lock];
    FWTabAnimatedCacheModel *cacheModel = array[0];
    FWTabComponentManager *manager = array[1];
    if (manager && cacheModel) {
        NSString *managerFilePath = [self _getCacheManagerFilePathWithFileName:manager.fileName];
        [FWTabAnimatedDocumentMethod writeToFileWithData:manager
                                              filePath:managerFilePath];
        NSString *modelFilePath = [self _getCacheModelFilePathWithFileName:manager.fileName];
        [FWTabAnimatedDocumentMethod writeToFileWithData:cacheModel
                                              filePath:modelFilePath];
    }
    [_lock unlock];
}

- (NSString *)_getCacheManagerFilePathWithFileName:(NSString *)fileName {
    return [FWTabAnimatedDocumentMethod getFWTabPathByFilePacketName:[NSString stringWithFormat:@"/%@/%@/%@.plist",FWTabCacheManagerFolderName,FWTabCacheManagerCacheManagerFolderName,fileName]];
}

- (NSString *)_getCacheModelFilePathWithFileName:(NSString *)fileName {
    return [FWTabAnimatedDocumentMethod getFWTabPathByFilePacketName:[NSString stringWithFormat:@"/%@/%@/%@.plist",FWTabCacheManagerFolderName,FWTabCacheManagerCacheModelFolderName,fileName]];
}

@end

@interface FWTabAnimatedCacheModel()

@property (nonatomic, assign, readwrite) BOOL needUpdate;

@end

@implementation FWTabAnimatedCacheModel

- (instancetype)init {
    if (self = [super init]) {
        _loadCount = 1;
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_fileName forKey:@"fileName"];
    [aCoder encodeInteger:_loadCount forKey:@"loadCount"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.fileName = [aDecoder decodeObjectForKey:@"fileName"];
        self.loadCount = [aDecoder decodeIntegerForKey:@"loadCount"];
    }
    return self;
}

@end

#define kAnimatedFileManager [NSFileManager defaultManager]

@implementation FWTabAnimatedDocumentMethod

+ (NSString *)documentPath {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

+ (NSString *)getFWTabPathByFilePacketName:(NSString *)filePacketName {
    return [[self documentPath] stringByAppendingPathComponent:filePacketName];
}

+ (void)writeToFileWithData:(id)data
                   filePath:(NSString *)filePath {
    if (@available(iOS 11.0, *)) {
        NSData *newData = [NSKeyedArchiver archivedDataWithRootObject:data requiringSecureCoding:YES error:NULL];
        if (newData) {
            [newData writeToFile:filePath atomically:YES];
        }
    }else {
        [NSKeyedArchiver archiveRootObject:data toFile:filePath];
    }
}

+ (id)getCacheData:(NSString *)filePath
       targetClass:(nonnull Class)targetClass {
    if (@available(iOS 11.0, *)) {
        NSData *data = [NSData dataWithContentsOfFile:filePath];
        return [NSKeyedUnarchiver unarchivedObjectOfClass:targetClass
                                                 fromData:data
                                                    error:NULL];
    }
    return [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
}

+ (NSArray <NSString *> *)getAllFileNameWithFolderPath:(NSString *)folderPath {
    NSError *error = nil;
    NSArray *fileList = [kAnimatedFileManager contentsOfDirectoryAtPath:folderPath error:&error];
    if (error) {
        return nil;
    }
    return fileList;
}

+ (NSString *)getPathByCreateDocumentFile:(NSString *)filePacketName
                             documentName:(NSString *)documentName {
    NSString *documentPath = [self documentPath];
    NSString *path = [documentPath stringByAppendingPathComponent:filePacketName];
    NSString *filePath = [path stringByAppendingPathComponent:documentName];
    return filePath;
}

+ (NSString *)getPathByCreateDocumentName:(NSString *)documentName {
    NSString *documentPath = [self documentPath];
    NSString *filePath = [documentPath stringByAppendingPathComponent:documentName];
    return filePath;
}

+ (BOOL)createFile:(NSString *)file
             isDir:(BOOL)isDir {
    
    if (![FWTabAnimatedDocumentMethod isExistFile:file
                                          isDir:isDir]) {
        if (isDir) {
            return [kAnimatedFileManager createDirectoryAtPath:file
                                   withIntermediateDirectories:YES
                                                    attributes:nil
                                                         error:nil];
        }else {
            return [kAnimatedFileManager createFileAtPath:file
                                                 contents:nil
                                               attributes:nil];
        }
    }
    
    return YES;
}

+ (BOOL)isExistFile:(NSString *)path
              isDir:(BOOL)isDir {
    isDir = [kAnimatedFileManager fileExistsAtPath:path
                                 isDirectory:&isDir];
    return isDir;
}

@end

#define tabAnimatedLog(x) {if([FWTabAnimated sharedAnimated].openLog) NSLog(x);}
#define tab_kColor(s) [UIColor colorWithRed:(((s&0xFF0000)>>16))/255.0 green:(((s&0xFF00)>>8))/255.0 blue:((s&0xFF))/255.0 alpha:1.]
#define tab_RGB(R,G,B) [UIColor colorWithRed:R/255.0 green:G/255.0 blue:B/255.0 alpha:1.]

@implementation UIView (FWTabAnimated)

#pragma mark - Getter/Setter

- (FWTabViewAnimated *)fwTabAnimated {
    return objc_getAssociatedObject(self, @selector(fwTabAnimated));
}

- (void)setFwTabAnimated:(FWTabViewAnimated *)fwTabAnimated {
    objc_setAssociatedObject(self, @selector(fwTabAnimated),fwTabAnimated, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (FWTabComponentManager *)fwTabComponentManager {
    return objc_getAssociatedObject(self, @selector(fwTabComponentManager));
}

- (void)setFwTabComponentManager:(FWTabComponentManager *)fwTabComponentManager {
    objc_setAssociatedObject(self, @selector(fwTabComponentManager),fwTabComponentManager, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation UITableView (FWTabAnimated)

- (FWTabTableAnimated *)fwTabAnimated {
    return objc_getAssociatedObject(self, @selector(fwTabAnimated));
}

- (void)setFwTabAnimated:(FWTabTableAnimated *)fwTabAnimated {
    objc_setAssociatedObject(self, @selector(fwTabAnimated),fwTabAnimated, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if (self.tableHeaderView != nil && self.tableHeaderView.fwTabAnimated == nil) {
        self.tableHeaderView.fwTabAnimated = FWTabViewAnimated.new;
        self.fwTabAnimated.tabHeadViewAnimated = self.tableHeaderView.fwTabAnimated;
    }
    
    if (self.tableFooterView != nil && self.tableFooterView.fwTabAnimated == nil) {
        self.tableFooterView.fwTabAnimated = FWTabViewAnimated.new;
        self.fwTabAnimated.tabFooterViewAnimated = self.tableFooterView.fwTabAnimated;
    }
}

@end

@implementation UICollectionView (FWTabAnimated)

- (FWTabCollectionAnimated *)fwTabAnimated {
    return objc_getAssociatedObject(self, @selector(fwTabAnimated));
}

- (void)setFwTabAnimated:(FWTabCollectionAnimated *)fwTabAnimated {
    objc_setAssociatedObject(self, @selector(fwTabAnimated),fwTabAnimated, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

static const NSTimeInterval kDelayReloadDataTime = .4;

@implementation UIView (FWTabControlAnimation)

#pragma mark - 启动动画

- (void)fwTabStartAnimation {
    
    if (self.fwTabAnimated.state == FWTabViewAnimationEnd && !self.fwTabAnimated.canLoadAgain) {
        return;
    }
    
    self.fwTabAnimated.isAnimating = YES;
    self.fwTabAnimated.state = FWTabViewAnimationStart;
    
    [self startAnimationIsAll:YES index:0];
}

- (void)fwTabStartAnimationWithCompletion:(void (^)(void))completion {
    [self fwTabStartAnimationWithDelayTime:kDelayReloadDataTime
                               completion:completion];
}

- (void)fwTabStartAnimationWithDelayTime:(CGFloat)delayTime
                             completion:(void (^)(void))completion {
    
    if (!self.fwTabAnimated.canLoadAgain &&
        self.fwTabAnimated.state == FWTabViewAnimationEnd) {
        if (completion) {
            completion();
        }
        return;
    }
    
    self.fwTabAnimated.state = FWTabViewAnimationStart;
    
    if (!self.fwTabAnimated.isAnimating) {
        [self startAnimationIsAll:YES index:0];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC*delayTime), dispatch_get_main_queue(), ^{
            if (completion) {
                completion();
            }
        });
    }
    
    self.fwTabAnimated.isAnimating = YES;
}

- (void)fwTabStartAnimationWithSection:(NSInteger)section {
    
    if (!self.fwTabAnimated.canLoadAgain &&
        self.fwTabAnimated.state == FWTabViewAnimationEnd) {
        return;
    }
    
    self.fwTabAnimated.isAnimating = YES;
    self.fwTabAnimated.state = FWTabViewAnimationStart;
    
    [self startAnimationIsAll:NO index:section];
}

- (void)fwTabStartAnimationWithSection:(NSInteger)section
                           completion:(void (^)(void))completion {
    [self fwTabStartAnimationWithSection:section
                              delayTime:kDelayReloadDataTime
                             completion:completion];
}

- (void)fwTabStartAnimationWithSection:(NSInteger)section
                            delayTime:(CGFloat)delayTime
                           completion:(void (^)(void))completion {
    if (!self.fwTabAnimated.canLoadAgain &&
        self.fwTabAnimated.state == FWTabViewAnimationEnd) {
        if (completion) {
            completion();
        }
        return;
    }
    
    self.fwTabAnimated.state = FWTabViewAnimationStart;
    
    if (!self.fwTabAnimated.isAnimating) {
        [self startAnimationIsAll:NO index:section];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC*delayTime), dispatch_get_main_queue(), ^{
            if (completion) {
                completion();
            }
        });
    }
    
    self.fwTabAnimated.isAnimating = YES;
}

#pragma mark -

- (void)fwTabStartAnimationWithRow:(NSInteger)row {
    
    if (!self.fwTabAnimated.canLoadAgain &&
        self.fwTabAnimated.state == FWTabViewAnimationEnd) {
        return;
    }
    
    self.fwTabAnimated.isAnimating = YES;
    self.fwTabAnimated.state = FWTabViewAnimationStart;
    
    [self startAnimationIsAll:NO index:row];
}

- (void)fwTabStartAnimationWithRow:(NSInteger)row
                       completion:(void (^)(void))completion {
    [self fwTabStartAnimationWithRow:row
                          delayTime:kDelayReloadDataTime
                         completion:completion];
}

- (void)fwTabStartAnimationWithRow:(NSInteger)row
                        delayTime:(CGFloat)delayTime
                       completion:(void (^)(void))completion {
    if (!self.fwTabAnimated.canLoadAgain &&
        self.fwTabAnimated.state == FWTabViewAnimationEnd) {
        if (completion) {
            completion();
        }
        return;
    }
    
    self.fwTabAnimated.state = FWTabViewAnimationStart;
    
    if (!self.fwTabAnimated.isAnimating) {
        [self startAnimationIsAll:NO index:row];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC*delayTime), dispatch_get_main_queue(), ^{
            if (completion) {
                completion();
            }
        });
    }
    
    self.fwTabAnimated.isAnimating = YES;
}

#pragma mark -

- (void)startAnimationIsAll:(BOOL)isAll
                      index:(NSInteger)index {
    
    if (self.fwTabAnimated.targetControllerClassName == nil ||
        self.fwTabAnimated.targetControllerClassName.length == 0) {
        UIViewController *controller = [self tab_viewController];
        if (controller) {
            self.fwTabAnimated.targetControllerClassName = NSStringFromClass(controller.class);
        }
    }
    
    if ([self isKindOfClass:[UICollectionView class]]) {
        
        UICollectionView *collectionView = (UICollectionView *)self;
        
        for (Class class in self.fwTabAnimated.cellClassArray) {
            
            NSString *classString = NSStringFromClass(class);
            if ([classString containsString:@"."]) {
                NSRange range = [classString rangeOfString:@"."];
                classString = [classString substringFromIndex:range.location+1];
            }
            
            NSString *nibPath = [[NSBundle mainBundle] pathForResource:classString ofType:@"nib"];
            if (nil != nibPath && nibPath.length > 0) {
                [collectionView registerNib:[UINib nibWithNibName:classString bundle:[NSBundle mainBundle]] forCellWithReuseIdentifier:[NSString stringWithFormat:@"tab_%@",classString]];
                [collectionView registerNib:[UINib nibWithNibName:classString bundle:[NSBundle mainBundle]] forCellWithReuseIdentifier:classString];
            }else {
                [collectionView registerClass:class forCellWithReuseIdentifier:[NSString stringWithFormat:@"tab_%@",classString]];
                [collectionView registerClass:class forCellWithReuseIdentifier:classString];
            }
        }
        
        FWTabCollectionAnimated *tabAnimated = (FWTabCollectionAnimated *)(collectionView.fwTabAnimated);
        [tabAnimated exchangeCollectionViewDelegate:collectionView];
        [tabAnimated exchangeCollectionViewDataSource:collectionView];
        
        if (tabAnimated.headerClassArray.count > 0) {
            [self registerHeaderOrFooter:YES tabAnimated:tabAnimated];
        }
        
        if (tabAnimated.footerClassArray.count > 0) {
            [self registerHeaderOrFooter:NO tabAnimated:tabAnimated];
        }

        [tabAnimated.runAnimationIndexArray removeAllObjects];
        
        if (isAll) {
            
            if (tabAnimated.animatedIndexArray.count > 0) {
                for (NSNumber *num in tabAnimated.animatedIndexArray) {
                    [tabAnimated.runAnimationIndexArray addObject:num];
                }
            }else {
                NSInteger sectionCount = [collectionView numberOfSections];
                for (NSInteger i = 0; i < sectionCount; i++) {
                    [tabAnimated.runAnimationIndexArray addObject:[NSNumber numberWithInteger:i]];
                }
            }
            
            if (tabAnimated.headerClassArray.count > 0 && tabAnimated.headerSectionArray.count == 0) {
                for (int i = 0; i < tabAnimated.runAnimationIndexArray.count; i++) {
                    [tabAnimated.headerSectionArray addObject:tabAnimated.runAnimationIndexArray[i]];
                }
            }

            if (tabAnimated.footerClassArray.count > 0 && tabAnimated.footerSectionArray.count == 0) {
                for (int i = 0; i < tabAnimated.runAnimationIndexArray.count; i++) {
                    [tabAnimated.footerSectionArray addObject:tabAnimated.runAnimationIndexArray[i]];
                }
            }
            
            [collectionView reloadData];
            
        }else {
            [tabAnimated.runAnimationIndexArray addObject:@(index)];
            [collectionView reloadSections:[NSIndexSet indexSetWithIndex:index]];
        }
        
        // 更新loadCount
        dispatch_async(dispatch_get_main_queue(), ^{
            [[FWTabAnimated sharedAnimated].cacheManager updateCacheModelLoadCountWithCollectionAnimated:collectionView.fwTabAnimated];
        });
        
    }else if ([self isKindOfClass:[UITableView class]]) {
        
        UITableView *tableView = (UITableView *)self;
        FWTabTableAnimated *tabAnimated = (FWTabTableAnimated *)(tableView.fwTabAnimated);
        [tabAnimated exchangeTableViewDelegate:tableView];
        [tabAnimated exchangeTableViewDataSource:tableView];
        
        for (Class class in self.fwTabAnimated.cellClassArray) {
            
            NSString *classString = NSStringFromClass(class);
            if ([classString containsString:@"."]) {
                NSRange range = [classString rangeOfString:@"."];
                classString = [classString substringFromIndex:range.location+1];
            }
            
            NSString *nibPath = [[NSBundle mainBundle] pathForResource:classString ofType:@"nib"];
            if (nil != nibPath && nibPath.length > 0) {
                [tableView registerNib:[UINib nibWithNibName:classString bundle:[NSBundle mainBundle]] forCellReuseIdentifier:[NSString stringWithFormat:@"tab_%@",classString]];
                [tableView registerNib:[UINib nibWithNibName:classString bundle:[NSBundle mainBundle]] forCellReuseIdentifier:classString];
            }else {
                [tableView registerClass:class forCellReuseIdentifier:[NSString stringWithFormat:@"tab_%@",classString]];
                [tableView registerClass:class forCellReuseIdentifier:classString];
            }
        }
        
        if (tableView.estimatedRowHeight != UITableViewAutomaticDimension ||
            tableView.estimatedRowHeight != 0) {
            tabAnimated.oldEstimatedRowHeight = tableView.estimatedRowHeight;
            tableView.estimatedRowHeight = UITableViewAutomaticDimension;
            if ([tableView numberOfSections] == 1) {
                tabAnimated.animatedHeight = ceilf([UIScreen mainScreen].bounds.size.height/tableView.estimatedRowHeight*1.0);
            }
        }
        
        if (tabAnimated.showTableHeaderView && tableView.tableHeaderView.fwTabAnimated) {
            tableView.tableHeaderView.fwTabAnimated.superAnimationType = tableView.fwTabAnimated.superAnimationType;
            [tableView.tableHeaderView fwTabStartAnimation];
        }
        
        if (tabAnimated.showTableFooterView && tableView.tableFooterView.fwTabAnimated) {
            tableView.tableFooterView.fwTabAnimated.superAnimationType = tableView.fwTabAnimated.superAnimationType;
            [tableView.tableFooterView fwTabStartAnimation];
        }
        
        [tabAnimated.runAnimationIndexArray removeAllObjects];
        if (isAll) {
            if (tabAnimated.animatedIndexArray.count > 0) {
                for (NSNumber *num in tabAnimated.animatedIndexArray) {
                    [tabAnimated.runAnimationIndexArray addObject:num];
                }
            }else {
                if (tabAnimated.runMode == FWTabAnimatedRunBySection) {
                    for (NSInteger i = 0; i < [tableView numberOfSections]; i++) {
                        [tabAnimated.runAnimationIndexArray addObject:[NSNumber numberWithInteger:i]];
                    }
                }else {
                    if (tabAnimated.runMode == FWTabAnimatedRunByRow) {
                        for (NSInteger i = 0; i < [tableView numberOfRowsInSection:0]; i++) {
                            [tabAnimated.runAnimationIndexArray addObject:[NSNumber numberWithInteger:i]];
                        }
                    }
                }
            }
            
            if (tabAnimated.headerClassArray.count > 0 && tabAnimated.headerSectionArray.count == 0) {
                for (int i = 0; i < tabAnimated.runAnimationIndexArray.count; i++) {
                    [tabAnimated.headerSectionArray addObject:tabAnimated.runAnimationIndexArray[i]];
                }
            }

            if (tabAnimated.footerClassArray.count > 0 && tabAnimated.footerSectionArray.count == 0) {
                for (int i = 0; i < tabAnimated.runAnimationIndexArray.count; i++) {
                    [tabAnimated.footerSectionArray addObject:tabAnimated.runAnimationIndexArray[i]];
                }
            }
            
            [tableView reloadData];
            
        }else {
            
            [tabAnimated.runAnimationIndexArray addObject:@(index)];
            
            if (tabAnimated.runMode == FWTabAnimatedRunBySection) {
                [tableView reloadSections:[NSIndexSet indexSetWithIndex:index] withRowAnimation:UITableViewRowAnimationNone];
            }else {
                if (tabAnimated.runMode == FWTabAnimatedRunByRow) {
                    [tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
                }
            }
        }
        
        // 更新loadCount
        dispatch_async(dispatch_get_main_queue(), ^{
            [[FWTabAnimated sharedAnimated].cacheManager updateCacheModelLoadCountWithTableAnimated:tableView.fwTabAnimated];
        });
        
    }else {
        if (nil == self.fwTabComponentManager) {
            
            UIView *targetView;
            if (self.superview && self.superview.fwTabAnimated) {
                targetView = self.superview;
            }else {
                targetView = self;
            }
            
//            self.fwTabAnimated.oldEnable = self.userInteractionEnabled;
//            self.userInteractionEnabled = NO;
            
            [FWTabManagerMethod fullData:self];
            [self setNeedsLayout];
            self.fwTabComponentManager = [FWTabComponentManager initWithView:self
                                                               superView:targetView
                                                             tabAnimated:self.fwTabAnimated];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (nil != self.fwTabAnimated) {
                    [FWTabManagerMethod runAnimationWithSuperView:self
                                                     targetView:self
                                                         isCell:NO
                                                        manager:self.fwTabComponentManager];
                }
            });
        }else {
            if (self.fwTabComponentManager.tabLayer.hidden)
                self.fwTabComponentManager.tabLayer.hidden = NO;
        }
    }
}

#pragma mark - 结束动画

- (void)fwTabEndAnimationIsEaseOut:(BOOL)isEaseOut {
    
    if (!self.fwTabAnimated) {
        tabAnimatedLog(@"FWTabAnimated提醒 - 动画对象已被提前释放");
        return;
    }
    
    if (self.fwTabAnimated.state == FWTabViewAnimationEnd) {
        return;
    }
    
    self.fwTabAnimated.state = FWTabViewAnimationEnd;
    self.fwTabAnimated.isAnimating = NO;
    
    if ([self isKindOfClass:[UITableView class]]) {
        
        UITableView *tableView = (UITableView *)self;
        FWTabTableAnimated *tabAnimated = (FWTabTableAnimated *)(tableView.fwTabAnimated);
        
        if (tabAnimated.oldEstimatedRowHeight > 0) {
            tableView.estimatedRowHeight = tabAnimated.oldEstimatedRowHeight;
            tableView.rowHeight = UITableViewAutomaticDimension;
        }
        [tabAnimated.runAnimationIndexArray removeAllObjects];
        
        self.fwTabAnimated = tabAnimated;
        
        if (tableView.tableHeaderView != nil &&
            tableView.tableHeaderView.fwTabAnimated != nil) {
            [tableView.tableHeaderView fwTabEndAnimation];
        }
        
        if (tableView.tableFooterView != nil &&
            tableView.tableFooterView.fwTabAnimated != nil) {
            [tableView.tableFooterView fwTabEndAnimation];
        }
        
        [tableView reloadData];
        
    }else {
        if ([self isKindOfClass:[UICollectionView class]]) {
            
            FWTabCollectionAnimated *tabAnimated = (FWTabCollectionAnimated *)((UICollectionView *)self.fwTabAnimated);
            [tabAnimated.runAnimationIndexArray removeAllObjects];
            self.fwTabAnimated = tabAnimated;
            
            [(UICollectionView *)self reloadData];
            
        }else {
            
//            self.userInteractionEnabled = self.fwTabAnimated.oldEnable;
            
            [FWTabManagerMethod resetData:self];
            [FWTabManagerMethod removeMask:self];
            [FWTabManagerMethod endAnimationToSubViews:self];
        }
    }
    
    if (isEaseOut) {
        [FWTabAnimationMethod addEaseOutAnimation:self];
    }
}

- (void)fwTabEndAnimation {
    [self fwTabEndAnimationIsEaseOut:NO];
}

- (void)fwTabEndAnimationEaseOut {
    [self fwTabEndAnimationIsEaseOut:YES];
}

- (void)fwTabEndAnimationWithRow:(NSInteger)row {
    [self fwTabEndAnimationWithSection:row];
}
    
- (void)fwTabEndAnimationWithSection:(NSInteger)section {
    
    if (![self isKindOfClass:[UITableView class]] &&
        ![self isKindOfClass:[UICollectionView class]]) {
        tabAnimatedLog(@"FWTabAnimated提醒 - 该类型view不支持局部结束动画");
        return;
    }
    
    NSInteger maxIndex = 0;
    if ([self isKindOfClass:[UITableView class]]) {
        FWTabTableAnimated *tabAnimated = (FWTabTableAnimated *)self.fwTabAnimated;
        if (tabAnimated.runMode == FWTabAnimatedRunBySection) {
            maxIndex = [(UITableView *)self numberOfSections] - 1;
        }else {
            maxIndex = [(UITableView *)self numberOfRowsInSection:0] - 1;
        }
    }else {
        FWTabCollectionAnimated *tabAnimated = (FWTabCollectionAnimated *)self.fwTabAnimated;
        if (tabAnimated.runMode == FWTabAnimatedRunBySection) {
            maxIndex = [(UICollectionView *)self numberOfSections] - 1;
        }else {
            maxIndex = [(UICollectionView *)self numberOfItemsInSection:0] - 1;
        }
    }
    
    if (section > maxIndex) {
        tabAnimatedLog(@"FWTabAnimated提醒 - 超过当前最大分区数");
        return;
    }
    
    if ([self isKindOfClass:[UICollectionView class]]) {
        
        FWTabCollectionAnimated *tabAnimated = (FWTabCollectionAnimated *)((UICollectionView *)self.fwTabAnimated);
        
        for (NSInteger i = 0; i < tabAnimated.runAnimationIndexArray.count; i++) {
            if (section == [tabAnimated.runAnimationIndexArray[i] integerValue]) {
                [self tab_removeObjectAtIndex:i
                                    withArray:tabAnimated.runAnimationIndexArray];
                break;
            }
        }
        
        self.fwTabAnimated = tabAnimated;
        
        if (tabAnimated.runMode == FWTabAnimatedRunBySection) {
            [(UICollectionView *)self reloadSections:[NSIndexSet indexSetWithIndex:section]];
        }else {
            [(UICollectionView *)self reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:section inSection:0]]];
        }
        
    }else if ([self isKindOfClass:[UITableView class]]) {
        
        FWTabTableAnimated *tabAnimated = (FWTabTableAnimated *)((UITableView *)self.fwTabAnimated);
        
        for (NSInteger i = 0; i < tabAnimated.runAnimationIndexArray.count; i++) {
            if (section == [tabAnimated.runAnimationIndexArray[i] integerValue]) {
                [self tab_removeObjectAtIndex:i
                                    withArray:tabAnimated.runAnimationIndexArray];
                break;
            }
        }
        
        self.fwTabAnimated = tabAnimated;
        
        if (tabAnimated.runMode == FWTabAnimatedRunBySection) {
            [(UITableView *)self reloadSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:UITableViewRowAnimationNone];
        }else {
            [(UITableView *)self reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:section inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        }
    }
}

#pragma mark - Private Method

- (UIViewController*)tab_viewController {
    for (UIView *next = [self superview]; next; next = next.superview) {
        UIResponder *nextResponder = [next nextResponder];
        if ([nextResponder isKindOfClass:[UIViewController class]]) {
            return (UIViewController*)nextResponder;
        }
    }
    return nil;
}

- (void)tab_removeObjectAtIndex:(NSInteger)index
                      withArray:(NSMutableArray *)array {
    [array removeObjectAtIndex:index];
    if (array.count == 0) {
        self.fwTabAnimated.state = FWTabViewAnimationEnd;
        self.fwTabAnimated.isAnimating = NO;
    }
}

- (void)registerHeaderOrFooter:(BOOL)isHeader
                   tabAnimated:(FWTabCollectionAnimated *)tabAnimated {
    
    UICollectionView *collectionView = (UICollectionView *)self;
    NSString *defaultPrefix = nil;
    NSMutableArray *classArray;
    NSString *kind = nil;
    
    if (isHeader) {
        defaultPrefix = FWTabViewAnimatedHeaderPrefixString;
        classArray = tabAnimated.headerClassArray;
        kind = UICollectionElementKindSectionHeader;
    }else {
        defaultPrefix = FWTabViewAnimatedFooterPrefixString;
        classArray = tabAnimated.footerClassArray;
        kind = UICollectionElementKindSectionFooter;
    }
    
    [collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:kind withReuseIdentifier:[NSString stringWithFormat:@"%@%@",defaultPrefix,FWTabViewAnimatedDefaultSuffixString]];
    
    for (Class class in classArray) {
        
        NSString *classString = NSStringFromClass(class);
        if ([classString containsString:@"."]) {
            NSRange range = [classString rangeOfString:@"."];
            classString = [classString substringFromIndex:range.location+1];
        }
        
        NSString *nibPath = [[NSBundle mainBundle] pathForResource:classString ofType:@"nib"];
        
        if (nil != nibPath && nibPath.length > 0) {
            [collectionView registerNib:[UINib nibWithNibName:classString
                                                       bundle:[NSBundle mainBundle]]
             forSupplementaryViewOfKind:kind
                    withReuseIdentifier:[NSString stringWithFormat:@"%@%@",defaultPrefix,classString]];
            [collectionView registerNib:[UINib nibWithNibName:classString
                                                       bundle:[NSBundle mainBundle]]
             forSupplementaryViewOfKind:kind
                    withReuseIdentifier:classString];
        }else {
            [collectionView registerClass:class
               forSupplementaryViewOfKind:kind
                      withReuseIdentifier:[NSString stringWithFormat:@"%@%@",defaultPrefix,classString]];
            [collectionView registerClass:class
               forSupplementaryViewOfKind:kind
                      withReuseIdentifier:classString];
        }
    }
}

@end

@implementation NSArray (FWTabAnimated)

- (FWTabAnimatedArrayFloatBlock)fwTabUp {
    return ^NSArray <FWTabBaseComponent *> *(CGFloat offset) {
        for (FWTabBaseComponent *component in self) {
            component.up(offset);
        }
        return self;
    };
}

- (FWTabAnimatedArrayFloatBlock)fwTabDown {
    return ^NSArray <FWTabBaseComponent *> *(CGFloat offset) {
        for (FWTabBaseComponent *component in self) {
            component.down(offset);
        }
        return self;
    };
}

- (FWTabAnimatedArrayFloatBlock)fwTabLeft {
    return ^NSArray <FWTabBaseComponent *> *(CGFloat offset) {
        for (FWTabBaseComponent *component in self) {
            component.left(offset);
        }
        return self;
    };
}

- (FWTabAnimatedArrayFloatBlock)fwTabRight {
    return ^NSArray <FWTabBaseComponent *> *(CGFloat offset) {
        for (FWTabBaseComponent *component in self) {
            component.right(offset);
        }
        return self;
    };
}

- (FWTabAnimatedArrayFloatBlock)fwTabWidth {
    return ^NSArray <FWTabBaseComponent *> *(CGFloat offset) {
        for (FWTabBaseComponent *component in self) {
            component.width(offset);
        }
        return self;
    };
}

- (FWTabAnimatedArrayFloatBlock)fwTabHeight {
    return ^NSArray <FWTabBaseComponent *> *(CGFloat offset) {
        for (FWTabBaseComponent *component in self) {
            component.height(offset);
        }
        return self;
    };
}

- (FWTabAnimatedArrayFloatBlock)fwTabReducedWidth {
    return ^NSArray <FWTabBaseComponent *> *(CGFloat offset) {
        for (FWTabBaseComponent *component in self) {
            component.reducedWidth(offset);
        }
        return self;
    };
}

- (FWTabAnimatedArrayFloatBlock)fwTabReducedHeight {
    return ^NSArray <FWTabBaseComponent *> *(CGFloat offset) {
        for (FWTabBaseComponent *component in self) {
            component.reducedHeight(offset);
        }
        return self;
    };
}

- (FWTabAnimatedArrayFloatBlock)fwTabReducedRadius {
    return ^NSArray <FWTabBaseComponent *> *(CGFloat offset) {
        for (FWTabBaseComponent *component in self) {
            component.reducedRadius(offset);
        }
        return self;
    };
}

- (FWTabAnimatedArrayFloatBlock)fwTabRadius {
    return ^NSArray <FWTabBaseComponent *> *(CGFloat offset) {
        for (FWTabBaseComponent *component in self) {
            component.radius(offset);
        }
        return self;
    };
}

- (FWTabAnimatedArrayIntBlock)fwTabLine {
    return ^NSArray <FWTabBaseComponent *> *(NSInteger value) {
        for (FWTabBaseComponent *component in self) {
            component.line(value);
        }
        return self;
    };
}

- (FWTabAnimatedArrayFloatBlock)fwTabSpace {
    return ^NSArray <FWTabBaseComponent *> *(CGFloat offset) {
        for (FWTabBaseComponent *component in self) {
            component.space(offset);
        }
        return self;
    };
}

- (FWTabAnimatedArrayBlock)fwTabRemove {
    return ^NSArray <FWTabBaseComponent *> *(void) {
        for (FWTabBaseComponent *component in self) {
            component.remove();
        }
        return self;
    };
}

- (FWTabAnimatedArrayStringBlock)fwTabPlaceholder {
    return ^NSArray <FWTabBaseComponent *> *(NSString *string) {
        for (FWTabBaseComponent *component in self) {
            component.placeholder(string);
        }
        return self;
    };
}

- (FWTabAnimatedArrayFloatBlock)fwTabX {
    return ^NSArray <FWTabBaseComponent *> *(CGFloat offset) {
        for (FWTabBaseComponent *component in self) {
            component.x(offset);
        }
        return self;
    };
}

- (FWTabAnimatedArrayFloatBlock)fwTabY {
    return ^NSArray <FWTabBaseComponent *> *(CGFloat offset) {
        for (FWTabBaseComponent *component in self) {
            component.y(offset);
        }
        return self;
    };
}

- (FWTabAnimatedArrayColorBlock)fwTabColor {
    return ^NSArray <FWTabBaseComponent *> *(UIColor *color) {
        for (FWTabBaseComponent *component in self) {
            component.color(color);
        }
        return self;
    };
}

#pragma mark - Drop Animation

- (FWTabAnimatedArrayIntBlock)fwTabDropIndex {
    return ^NSArray <FWTabBaseComponent *> *(NSInteger value) {
        for (FWTabBaseComponent *component in self) {
            component.dropIndex(value);
        }
        return self;
    };
}

- (FWTabAnimatedArrayIntBlock)fwTabDropFromIndex {
    return ^NSArray <FWTabBaseComponent *> *(NSInteger value) {
        for (FWTabBaseComponent *component in self) {
            component.dropFromIndex(value);
        }
        return self;
    };
}

- (FWTabAnimatedArrayBlock)fwTabRemoveOnDrop {
    return ^NSArray <FWTabBaseComponent *> *(void) {
        for (FWTabBaseComponent *component in self) {
            component.removeOnDrop();
        }
        return self;
    };
}

- (FWTabAnimatedArrayFloatBlock)fwTabDropStayTime {
    return ^NSArray <FWTabBaseComponent *> *(CGFloat offset) {
        for (FWTabBaseComponent *component in self) {
            component.dropStayTime(offset);
        }
        return self;
    };
}

@end

@interface FWTabBaseComponent()

@property (nonatomic, strong, readwrite) FWTabComponentLayer *layer;

@end

@implementation FWTabBaseComponent

+ (instancetype)initWithComponentLayer:(FWTabComponentLayer *)layer {
    FWTabBaseComponent *component = FWTabBaseComponent.new;
    component.layer = layer;
    return component;
}

#pragma mark - left

- (FWTabBaseComponentFloatBlock)left {
    return ^FWTabBaseComponent *(CGFloat offset) {
        [self result_left:offset];
        return self;
    };
}

- (void)preview_left:(NSNumber *)number {
    [self result_left:[number floatValue]];
}

- (void)result_left:(CGFloat)offset {
    self.layer.frame = CGRectMake(self.layer.frame.origin.x - offset, self.layer.frame.origin.y, self.layer.frame.size.width, self.layer.frame.size.height);
}

#pragma mark - right

- (FWTabBaseComponentFloatBlock)right {
    return ^FWTabBaseComponent *(CGFloat offset) {
        [self result_right:offset];
        return self;
    };
}

- (void)preview_right:(NSNumber *)number {
    [self result_right:[number floatValue]];
}

- (void)result_right:(CGFloat)offset {
    self.layer.frame = CGRectMake(self.layer.frame.origin.x + offset, self.layer.frame.origin.y, self.layer.frame.size.width, self.layer.frame.size.height);
}

#pragma mark - up

- (FWTabBaseComponentFloatBlock)up {
    return ^FWTabBaseComponent *(CGFloat offset) {
        [self result_up:offset];
        return self;
    };
}

- (void)preview_up:(NSNumber *)number {
    [self result_up:[number floatValue]];
}

- (void)result_up:(CGFloat)offset {
    self.layer.frame = CGRectMake(self.layer.frame.origin.x, self.layer.frame.origin.y - offset, self.layer.frame.size.width, self.layer.frame.size.height);
}

#pragma mark - down

- (FWTabBaseComponentFloatBlock)down {
    return ^FWTabBaseComponent *(CGFloat offset) {
        [self result_down:offset];
        return self;
    };
}

- (void)preview_down:(NSNumber *)number {
    [self result_down:[number floatValue]];
}

- (void)result_down:(CGFloat)offset {
    self.layer.frame = CGRectMake(self.layer.frame.origin.x, self.layer.frame.origin.y + offset, self.layer.frame.size.width, self.layer.frame.size.height);
}

#pragma mark - width

- (FWTabBaseComponentFloatBlock)width {
    return ^FWTabBaseComponent *(CGFloat offset) {
        
        if (offset <= 0) {
            return self;
        }
        
        [self result_width:offset];
        
        return self;
    };
}

- (void)preview_width:(NSNumber *)number {
    [self result_width:[number floatValue]];
}

- (void)result_width:(CGFloat)offset {
    self.layer.frame = CGRectMake(self.layer.frame.origin.x, self.layer.frame.origin.y, offset, self.layer.frame.size.height);
}

#pragma mark - height

- (FWTabBaseComponentFloatBlock)height {
    return ^FWTabBaseComponent *(CGFloat offset) {
        
        if (offset <= 0) {
            return self;
        }
        
        [self result_height:offset];
        
        return self;
    };
}

- (void)preview_height:(NSNumber *)number {
    [self result_height:[number floatValue]];
}

- (void)result_height:(CGFloat)offset {
    self.layer.tabViewHeight = offset;
}

#pragma mark - radius

- (FWTabBaseComponentFloatBlock)radius {
    return ^FWTabBaseComponent *(CGFloat offset) {
        [self result_radius:offset];
        return self;
    };
}

- (void)preview_radius:(NSNumber *)number {
    [self result_radius:[number floatValue]];
}

- (void)result_radius:(CGFloat)offset {
    self.layer.cornerRadius = offset;
}

#pragma mark - reducedWidth

- (FWTabBaseComponentFloatBlock)reducedWidth {
    return ^FWTabBaseComponent *(CGFloat offset) {
        [self result_reducedWidth:offset];
        return self;
    };
}

- (void)preview_reducedWidth:(NSNumber *)number {
    [self result_reducedWidth:[number floatValue]];
}

- (void)result_reducedWidth:(CGFloat)offset {
    self.layer.frame = CGRectMake(self.layer.frame.origin.x, self.layer.frame.origin.y, self.layer.frame.size.width - offset, self.layer.frame.size.height);
}

#pragma mark - reducedHeight

- (FWTabBaseComponentFloatBlock)reducedHeight {
    return ^FWTabBaseComponent *(CGFloat offset) {
        [self result_reducedHeight:offset];
        return self;
    };
}

- (void)preview_reducedHeight:(NSNumber *)number {
    [self result_reducedHeight:[number floatValue]];
}

- (void)result_reducedHeight:(CGFloat)offset {
    self.layer.tabViewHeight = self.layer.frame.size.height - offset;
}

#pragma mark - reducedRadius

- (FWTabBaseComponentFloatBlock)reducedRadius {
    return ^FWTabBaseComponent *(CGFloat offset) {
        [self result_reducedRadius:offset];
        return self;
    };
}

- (void)preview_reducedRadius:(NSNumber *)number {
    [self result_reducedRadius:[number floatValue]];
}

- (void)result_reducedRadius:(CGFloat)offset {
    self.layer.cornerRadius = self.layer.cornerRadius - offset;
}

#pragma mark - x

- (FWTabBaseComponentFloatBlock)x {
    return ^FWTabBaseComponent *(CGFloat offset) {
        [self result_x:offset];
        return self;
    };
}

- (void)preview_x:(NSNumber *)number {
    [self result_x:[number floatValue]];
}

- (void)result_x:(CGFloat)offset {
    self.layer.frame = CGRectMake(offset, self.layer.frame.origin.y, self.layer.frame.size.width, self.layer.frame.size.height);
}

#pragma mark - y

- (FWTabBaseComponentFloatBlock)y {
    return ^FWTabBaseComponent *(CGFloat offset) {
        [self result_y:offset];
        return self;
    };
}

- (void)preview_y:(NSNumber *)number {
    [self result_y:[number floatValue]];
}

- (void)result_y:(CGFloat)offset {
    self.layer.frame = CGRectMake(self.layer.frame.origin.x, offset, self.layer.frame.size.width, self.layer.frame.size.height);
}

#pragma mark - line

- (FWTabBaseComponentIntegerBlock)line {
    return ^FWTabBaseComponent *(NSInteger value) {
        [self result_line:value];
        return self;
    };
}

- (void)preview_line:(NSNumber *)number {
    [self result_line:[number floatValue]];
}

- (void)result_line:(CGFloat)offset {
    self.layer.numberOflines = offset;
}

#pragma mark - space

- (FWTabBaseComponentFloatBlock)space {
    return ^FWTabBaseComponent *(CGFloat value) {
        [self result_space:value];
        return self;
    };
}

- (void)preview_space:(NSNumber *)number {
    [self result_space:[number floatValue]];
}

- (void)result_space:(CGFloat)offset {
    self.layer.lineSpace = offset;
}

#pragma mark - lastLineScale

- (FWTabBaseComponentFloatBlock)lastLineScale {
    return ^FWTabBaseComponent *(CGFloat value) {
        [self result_lastLineScale:value];
        return self;
    };
}

- (void)preview_lastLineScale:(NSNumber *)number {
    [self result_lastLineScale:[number floatValue]];
}

- (void)result_lastLineScale:(CGFloat)offset {
    self.layer.lastScale = offset;
}

#pragma mark - remove

- (FWTabBaseComponentVoidBlock)remove {
    return ^FWTabBaseComponent *(void) {
        [self result_remove];
        return self;
    };
}

- (void)preview_remove {
    [self result_remove];
}

- (void)result_remove {
    self.layer.loadStyle = FWTabViewLoadAnimationRemove;
}

#pragma mark - placeholder

- (FWTabBaseComponentStringBlock)placeholder {
    return ^FWTabBaseComponent *(NSString *string) {
        [self result_placeholder:string];
        return self;
    };
}

- (void)preview_placeholder:(NSString *)value {
    [self result_placeholder:value];
}

- (void)result_placeholder:(NSString *)value {
    self.layer.placeholderName = value;
    self.layer.contents = (id)[UIImage imageNamed:value].CGImage;
}

#pragma mark - toLongAnimation

- (FWTabBaseComponentVoidBlock)toLongAnimation {
    return ^FWTabBaseComponent *(void) {
        [self result_toLongAnimation];
        return self;
    };
}

- (void)preview_toLongAnimation {
    [self result_toLongAnimation];
}

- (void)result_toLongAnimation {
    self.layer.loadStyle = FWTabViewLoadAnimationToLong;
}

#pragma mark - toShortAnimation

- (FWTabBaseComponentVoidBlock)toShortAnimation {
    return ^FWTabBaseComponent *(void) {
        [self result_toShortAnimation];
        return self;
    };
}

- (void)preview_toShortAnimation {
    [self result_toShortAnimation];
}

- (void)result_toShortAnimation {
    self.layer.loadStyle = FWTabViewLoadAnimationToShort;
}

#pragma mark - cancelAlignCenter

- (FWTabBaseComponentVoidBlock)cancelAlignCenter {
    return ^FWTabBaseComponent *(void) {
        [self result_cancelAlignCenter];
        return self;
    };
}

- (void)preview_cancelAlignCenter {
    [self result_cancelAlignCenter];
}

- (void)result_cancelAlignCenter {
    self.layer.isCancelAlignCenter = YES;
}

#pragma mark - color

- (FWTabBaseComponentColorBlock)color {
    return ^FWTabBaseComponent *(UIColor *color) {
        [self result_color:color];
        return self;
    };
}

- (void)preview_color:(UIColor *)color {
    [self result_color:color];
}

- (void)result_color:(UIColor *)color {
    self.layer.backgroundColor = color.CGColor;
}

#pragma mark - 豆瓣动画
#pragma mark - dropIndex

- (FWTabBaseComponentIntegerBlock)dropIndex {
    return ^FWTabBaseComponent *(NSInteger value) {
        [self result_dropIndex:value];
        return self;
    };
}

- (void)preview_dropIndex:(NSNumber *)number {
    [self result_dropIndex:[number integerValue]];
}

- (void)result_dropIndex:(NSInteger)value {
    self.layer.dropAnimationIndex = value;
}

#pragma mark - dropFromIndex

- (FWTabBaseComponentIntegerBlock)dropFromIndex {
    return ^FWTabBaseComponent *(NSInteger value) {
        [self result_dropFromIndex:value];
        return self;
    };
}

- (void)preview_dropFromIndex:(NSNumber *)number {
    [self result_dropFromIndex:[number integerValue]];
}

- (void)result_dropFromIndex:(NSInteger)value {
    self.layer.dropAnimationFromIndex = value;
}

#pragma mark - removeOnDrop

- (FWTabBaseComponentVoidBlock)removeOnDrop {
    return ^FWTabBaseComponent *(void) {
        [self result_removeOnDrop];
        return self;
    };
}

- (void)preview_removeOnDrop {
    [self result_removeOnDrop];
}

- (void)result_removeOnDrop {
    self.layer.removeOnDropAnimation = YES;
}

#pragma mark - dropStayTime

- (FWTabBaseComponentFloatBlock)dropStayTime {
    return ^FWTabBaseComponent *(CGFloat value) {
        [self result_dropStayTime:value];
        return self;
    };
}

- (void)preview_dropStayTime:(NSNumber *)number {
    [self result_dropStayTime:[number floatValue]];
}

- (void)result_dropStayTime:(CGFloat)value {
    self.layer.dropAnimationStayTime = value;
}

@end

extern const NSInteger FWTabViewAnimatedErrorCode;

@implementation FWTabComponentLayer

- (instancetype)init {
    if (self = [super init]) {
        self.name = @"FWTabLayer";
        self.anchorPoint = CGPointMake(0, 0);
        self.position = CGPointMake(0, 0);
        self.opaque = YES;
        self.contentsGravity = kCAGravityResizeAspect;
        
        self.tagIndex = FWTabViewAnimatedErrorCode;
        self.dropAnimationStayTime = 0.2;
        self.lastScale = 0.5;
        self.dropAnimationFromIndex = -1;
        self.dropAnimationIndex = -1;
        self.removeOnDropAnimation = NO;
    }
    return self;
}

- (CGFloat)lineSpace {
    if (_lineSpace == 0.) {
        return 8.;
    }
    return _lineSpace;
}

#pragma mark - NSCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (id)copyWithZone:(NSZone *)zone {
    FWTabComponentLayer *layer = [[[self class] allocWithZone:zone] init];
    
    layer.loadStyle = self.loadStyle;
    layer.fromImageView = self.fromImageView;
    layer.fromCenterLabel = self.fromCenterLabel;
    layer.isCancelAlignCenter = self.isCancelAlignCenter;
    layer.tabViewHeight = self.tabViewHeight;
    layer.numberOflines = self.numberOflines;
    layer.lineSpace = self.lineSpace;
    layer.lastScale = self.lastScale;
    
    layer.dropAnimationIndex = self.dropAnimationIndex;
    layer.dropAnimationFromIndex = self.dropAnimationFromIndex;
    layer.removeOnDropAnimation = self.removeOnDropAnimation;
    layer.dropAnimationStayTime = self.dropAnimationStayTime;
    
    if (self.contents) {
        layer.contents = self.contents;
    }
    layer.placeholderName = self.placeholderName;
    
    layer.tagIndex = self.tagIndex;
    
    layer.frame = self.frame;
    layer.resultFrameValue = [NSValue valueWithCGRect:self.frame];
    layer.backgroundColor = self.backgroundColor;
    layer.shadowOffset = self.shadowOffset;
    layer.shadowColor = self.shadowColor;
    layer.shadowRadius = self.shadowRadius;
    layer.shadowOpacity = self.shadowOpacity;
    layer.cornerRadius = self.cornerRadius;
    layer.anchorPoint = self.anchorPoint;
    layer.position = self.position;
    layer.opaque = self.opaque;
    layer.contentsScale = self.contentsScale;
    
    return layer;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:[NSValue valueWithCGRect:self.frame] forKey:@"resultFrameValue"];
    [aCoder encodeObject:[UIColor colorWithCGColor:self.backgroundColor] forKey:@"backgroundColor"];
    [aCoder encodeFloat:self.cornerRadius forKey:@"cornerRadius"];
    
    [aCoder encodeInteger:_tagIndex forKey:@"tagIndex"];
    [aCoder encodeInteger:_loadStyle forKey:@"loadStyle"];
    [aCoder encodeBool:_fromImageView forKey:@"fromImageView"];
    [aCoder encodeBool:_fromCenterLabel forKey:@"fromCenterLabel"];
    [aCoder encodeBool:_isCancelAlignCenter forKey:@"isCancelAlignCenter"];
    [aCoder encodeFloat:_tabViewHeight forKey:@"tabViewHeight"];
    [aCoder encodeInteger:_numberOflines forKey:@"numberOflines"];
    [aCoder encodeFloat:_lineSpace forKey:@"lineSpace"];
    [aCoder encodeFloat:_lastScale forKey:@"lastScale"];
    
    [aCoder encodeInteger:_dropAnimationIndex forKey:@"dropAnimationIndex"];
    [aCoder encodeInteger:_dropAnimationFromIndex forKey:@"dropAnimationFromIndex"];
    [aCoder encodeBool:_removeOnDropAnimation forKey:@"removeOnDropAnimation"];
    [aCoder encodeFloat:_dropAnimationStayTime forKey:@"dropAnimationStayTime"];
    
    [aCoder encodeObject:_placeholderName forKey:@"placeholderName"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.name = @"FWTabLayer";
        self.anchorPoint = CGPointMake(0, 0);
        self.position = CGPointMake(0, 0);
        self.opaque = YES;
        self.contentsGravity = kCAGravityResizeAspect;
        
        self.resultFrameValue = [aDecoder decodeObjectForKey:@"resultFrameValue"];
        self.frame = [self.resultFrameValue CGRectValue];
        self.backgroundColor = [(UIColor *)[aDecoder decodeObjectForKey:@"backgroundColor"] CGColor];
        self.cornerRadius = [aDecoder decodeFloatForKey:@"cornerRadius"];
        
        self.tagIndex = [aDecoder decodeIntegerForKey:@"tagIndex"];
        self.loadStyle = [aDecoder decodeIntegerForKey:@"loadStyle"];
        self.fromImageView = [aDecoder decodeBoolForKey:@"fromImageView"];
        self.fromCenterLabel = [aDecoder decodeBoolForKey:@"fromCenterLabel"];
        self.isCancelAlignCenter = [aDecoder decodeBoolForKey:@"isCancelAlignCenter"];
        self.tabViewHeight = [aDecoder decodeFloatForKey:@"tabViewHeight"];
        self.numberOflines = [aDecoder decodeIntegerForKey:@"numberOflines"];
        self.lineSpace = [aDecoder decodeFloatForKey:@"lineSpace"];
        self.lastScale = [aDecoder decodeFloatForKey:@"lastScale"];
        
        self.dropAnimationIndex = [aDecoder decodeIntegerForKey:@"dropAnimationIndex"];
        self.dropAnimationFromIndex = [aDecoder decodeIntegerForKey:@"dropAnimationFromIndex"];
        self.removeOnDropAnimation = [aDecoder decodeBoolForKey:@"removeOnDropAnimation"];
        self.dropAnimationStayTime = [aDecoder decodeFloatForKey:@"dropAnimationStayTime"];
        
        self.placeholderName = [aDecoder decodeObjectForKey:@"placeholderName"];
    }
    return self;
}

@end

static const CGFloat kDefaultHeight = 16.f;
static const CGFloat kTagDefaultFontSize = 12.f;

static NSString * const kTagDefaultFontName = @"HiraKakuProN-W3";

@interface FWTabComponentManager()

@property (nonatomic, strong) NSMutableArray <FWTabBaseComponent *> *baseComponentArray;
@property (nonatomic, strong, readwrite) NSMutableArray <FWTabComponentLayer *> *componentLayerArray;
@property (nonatomic, strong, readwrite) NSMutableArray <FWTabComponentLayer *> *resultLayerArray;

@property (nonatomic, assign, readwrite) NSInteger dropAnimationCount;
@property (nonatomic, assign, readwrite) BOOL haveCachedWithDisk;

@property (nonatomic, weak) UIView *superView;
@property (nonatomic, weak, readwrite, nullable) FWTabSentryView *sentryView;

@end

@implementation FWTabComponentManager

#pragma mark - Init Method

+ (instancetype)initWithView:(UIView *)view
                   superView:(UIView *)superView
                 tabAnimated:(FWTabViewAnimated *)tabAnimated {
    FWTabComponentManager *manager = [self initWithView:view
                                            superView:superView];
    manager.animatedHeight = tabAnimated.animatedHeight;
    manager.animatedCornerRadius = tabAnimated.animatedCornerRadius;
    manager.cancelGlobalCornerRadius = tabAnimated.cancelGlobalCornerRadius;
    [manager setRadiusAndColorWithView:view
                             superView:superView
                           tabAnimated:tabAnimated];
    return manager;
}

+ (instancetype)initWithView:(UIView *)view
                   superView:(UIView *)superView {
    FWTabComponentManager *manager = [[FWTabComponentManager alloc] init];
    manager.superView = superView;
    if (view.frame.size.width > 0.) {
        if (superView && [superView isKindOfClass:[UITableView class]]) {
            UITableView *tableView = (UITableView *)superView;
            if (view.frame.size.width != [UIScreen mainScreen].bounds.size.width) {
                manager.tabLayer.frame = CGRectMake(view.bounds.origin.x, view.bounds.origin.y, [UIScreen mainScreen].bounds.size.width, tableView.rowHeight);
            }else {
                manager.tabLayer.frame = view.bounds;
            }
        }else {
            manager.tabLayer.frame = view.bounds;
        }
    }else {
        manager.tabLayer.frame = CGRectMake(view.bounds.origin.x, view.bounds.origin.y, [UIScreen mainScreen].bounds.size.width, view.bounds.size.height);
    }
    [view.layer addSublayer:manager.tabLayer];
    
    if (view && superView) {
        // 添加哨兵视图
        [manager addSentryView:view
                     superView:superView];
    }
    return manager;
}

- (instancetype)init {
    if (self = [super init]) {
        _resultLayerArray = @[].mutableCopy;
        _baseComponentArray = @[].mutableCopy;
        _componentLayerArray = @[].mutableCopy;
        
        _tabLayer = FWTabComponentLayer.new;
        _tabLayer.opaque = YES;
        _tabLayer.name = @"FWTabLayer";
        _tabLayer.position = CGPointMake(0, 0);
        _tabLayer.anchorPoint = CGPointMake(0, 0);
        _tabLayer.contentsScale = ([[UIScreen mainScreen] scale] > 3.0) ? [[UIScreen mainScreen] scale]:3.0;
    }
    return self;
}

- (void)reAddToView:(UIView *)view
          superView:(UIView *)superView {
    
    self.superView = superView;
    
    if (view.frame.size.width > 0.) {
        self.tabLayer.frame = view.bounds;
    }else {
        self.tabLayer.frame = CGRectMake(view.bounds.origin.x, view.bounds.origin.y, [UIScreen mainScreen].bounds.size.width, view.bounds.size.height);
    }
    [view.layer addSublayer:self.tabLayer];
    
    [self addSentryView:view
              superView:superView];
    
    [self setRadiusAndColorWithView:view
                          superView:superView
                        tabAnimated:superView.fwTabAnimated];
    [self updateComponentLayersWithArray:self.resultLayerArray];
}

#pragma mark - Public Method

- (FWTabBaseComponentBlock _Nullable)animation {
    return ^FWTabBaseComponent *(NSInteger index) {
        if (index >= self.baseComponentArray.count) {
            NSAssert(NO, @"Array bound, please check it carefully.");
            return [FWTabBaseComponent initWithComponentLayer:FWTabComponentLayer.new];
        }
        return self.baseComponentArray[index];
    };
}

- (FWTabBaseComponentArrayBlock _Nullable)animations {
    return ^NSArray <FWTabBaseComponent *> *(NSInteger location, NSInteger length) {
        
        if (location + length > self.baseComponentArray.count) {
            NSAssert(NO, @"Array bound, please check it carefully.");
            return NSArray.new;
        }
        
        NSMutableArray <FWTabBaseComponent *> *tempArray = @[].mutableCopy;
        for (NSInteger i = location; i < location+length; i++) {
            FWTabBaseComponent *layer = self.baseComponentArray[i];
            [tempArray addObject:layer];
        }
        
        // 修改添加  需要查看数组内容  length == 0 && location == 0 是返回整个数组   xiaoxin
        if (length == 0 && location == 0) {
            tempArray = self.baseComponentArray.mutableCopy;
        }
        
        return tempArray.mutableCopy;
    };
}

- (FWTabBaseComponentArrayWithIndexsBlock)animationsWithIndexs {
    return ^NSArray <FWTabBaseComponent *> *(NSInteger index,...) {
        
        NSMutableArray <FWTabBaseComponent *> *resultArray = @[].mutableCopy;
        
        if (index >= self.baseComponentArray.count) {
            NSAssert(NO, @"Array bound, please check it carefully.");
            [resultArray addObject:[FWTabBaseComponent initWithComponentLayer:FWTabComponentLayer.new]];
        }else {
            if(index < 0) {
                NSAssert(NO, @"Input data contains a number < 0, please check it carefully.");
                [resultArray addObject:[FWTabBaseComponent initWithComponentLayer:FWTabComponentLayer.new]];
            }else {
                [resultArray addObject:self.baseComponentArray[index]];
            }
        }
        
        // 定义一个指向个数可变的参数列表指针
        va_list args;
        // 用于存放取出的参数
        NSInteger arg;
        // 初始化上面定义的va_list变量，这个宏的第二个参数是第一个可变参数的前一个参数，是一个固定的参数
        va_start(args, index);
        // 遍历全部参数 va_arg返回可变的参数(a_arg的第二个参数是你要返回的参数的类型)
        while ((arg = va_arg(args, NSInteger))) {
            
            if(arg >= 0) {
                
                if (arg > 1000) {
                    break;
                }
                
                if (arg >= self.baseComponentArray.count) {
                    NSAssert(NO, @"Array bound, please check it carefully.");
                    [resultArray addObject:[FWTabBaseComponent initWithComponentLayer:FWTabComponentLayer.new]];
                }else {
                    if(arg < 0) {
                        NSAssert(NO, @"Input data contains a number < 0, please check it carefully.");
                        [resultArray addObject:[FWTabBaseComponent initWithComponentLayer:FWTabComponentLayer.new]];
                    }else {
                        [resultArray addObject:self.baseComponentArray[arg]];
                    }
                }
            }
        }
        // 清空参数列表，并置参数指针args无效
        va_end(args);
        return resultArray.copy;
    };
}

#pragma mark -

- (void)addSentryView:(UIView *)view
            superView:(UIView *)superView {
    if (@available(iOS 13.0, *)) {
        FWTabSentryView *sentryView = FWTabSentryView.new;
        _sentryView = sentryView;
        // avoid retain cycle
        __weak typeof(self) weakSelf = self;
        __weak typeof(superView) weakSuperView = superView;
        self.sentryView.traitCollectionDidChangeBack = ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            __strong typeof(weakSuperView) strongSuperView = weakSuperView;
            [strongSelf tab_traitCollectionDidChange:strongSuperView];
        };
        [view addSubview:sentryView];
    }
}

- (void)installBaseComponentArray:(NSArray <FWTabComponentLayer *> *)array {
    self.componentLayerArray = array.mutableCopy;
    [self.baseComponentArray removeAllObjects];
    for (NSInteger i = 0; i < array.count; i++) {
        FWTabBaseComponent *component = [FWTabBaseComponent initWithComponentLayer:array[i]];
        [self.baseComponentArray addObject:component];
    }
}

- (void)updateComponentLayersWithArray:(NSMutableArray <FWTabComponentLayer *> *)componentLayerArray {
    for (int i = 0; i < componentLayerArray.count; i++) {
        FWTabComponentLayer *layer = componentLayerArray[i];
        layer.backgroundColor = self.animatedColor.CGColor;
        
        if (layer.placeholderName && layer.placeholderName.length > 0) {
            layer.contents = (id)[UIImage imageNamed:layer.placeholderName].CGImage;
        }
        
        // 设置伸缩动画
        if (layer.loadStyle != FWTabViewLoadAnimationWithOnlySkeleton) {
            [layer addAnimation:[self getAnimationWithLoadStyle:layer.loadStyle] forKey:FWTabAnimatedLocationAnimation];
        }
        
        if (self.dropAnimationCount < layer.dropAnimationIndex) {
            self.dropAnimationCount = layer.dropAnimationIndex;
        }
        
        [self.tabLayer addSublayer:layer];
        
        // 添加红色标记
#ifdef DEBUG
        if ([FWTabAnimated sharedAnimated].openAnimationTag) {
            BOOL isFromLines = (layer.numberOflines != 1) ? YES : NO;
            if (layer.tagIndex != FWTabViewAnimatedErrorCode) {
                [self addAnimatedTagWithComponentLayer:layer
                                                 index:layer.tagIndex
                                          isFromeLines:isFromLines];
            }
        }
#endif
    }
}

- (void)updateComponentLayers {
    
    [self.resultLayerArray removeAllObjects];
    
    for (NSInteger i = 0; i < self.baseComponentArray.count; i++) {
        
        FWTabBaseComponent *component = self.baseComponentArray[i];
        FWTabComponentLayer *layer = component.layer;
        
        if (layer.loadStyle == FWTabViewLoadAnimationRemove) {
            continue;
        }
        
        CGRect rect = [self resetFrame:layer
                                  rect:layer.frame];
        layer.frame = rect;
        
        CGFloat cornerRadius = layer.cornerRadius;
        NSInteger labelLines = layer.numberOflines;
        
        if (labelLines != 1) {
            [self addLayers:rect
               cornerRadius:cornerRadius
                      lines:labelLines
                      space:layer.lineSpace
                  lastScale:layer.lastScale
                  fromIndex:layer.dropAnimationFromIndex
               removeOnDrop:layer.removeOnDropAnimation
                  tabHeight:layer.tabViewHeight
                  loadStyle:layer.loadStyle
                      index:i];
        }else {
            
            layer.tagIndex = i;
            if (layer.contents) {
                layer.backgroundColor = UIColor.clearColor.CGColor;
            }else {
                if (layer.backgroundColor == nil) {
                    layer.backgroundColor = self.animatedColor.CGColor;
                }
            }
            
            // 设置动画
            if (layer.loadStyle != FWTabAnimationTypeOnlySkeleton) {
                [layer addAnimation:[self getAnimationWithLoadStyle:layer.loadStyle] forKey:FWTabAnimatedLocationAnimation];
            }
            
            BOOL isImageView = layer.fromImageView;
            if (!isImageView) {
                // 设置圆角
                if (cornerRadius == 0.) {
                    if (self.cancelGlobalCornerRadius) {
                        layer.cornerRadius = self.animatedCornerRadius;
                    }else {
                        if ([FWTabAnimated sharedAnimated].useGlobalCornerRadius) {
                            if ([FWTabAnimated sharedAnimated].animatedCornerRadius != 0.) {
                                layer.cornerRadius = [FWTabAnimated sharedAnimated].animatedCornerRadius;
                            }else {
                                layer.cornerRadius = layer.frame.size.height/2.0;
                            }
                        }
                    }
                }else {
                    layer.cornerRadius = cornerRadius;
                }
            }
            
            if (!layer.removeOnDropAnimation) {
                if (layer.dropAnimationIndex == -1) {
                    layer.dropAnimationIndex = self.resultLayerArray.count;
                }
                
                if (self.dropAnimationCount < layer.dropAnimationIndex) {
                    self.dropAnimationCount = layer.dropAnimationIndex;
                }
            }
            
            [self.tabLayer addSublayer:layer];
            [self.resultLayerArray addObject:layer];
        }
        
        // 添加红色标记
#ifdef DEBUG
        if ([FWTabAnimated sharedAnimated].openAnimationTag) {
            [self addAnimatedTagWithComponentLayer:layer
                                             index:i
                                      isFromeLines:NO];
        }
#endif
    }
}

#pragma mark - Private

- (void)tab_traitCollectionDidChange:(UIView *)superView {
    
    if (@available(iOS 13.0, *)) {
        
        if (!superView) {
            return;
        }
        
        // avoid retain cycle
        __weak typeof(superView) weakSuperView = superView;
        self.animatedBackgroundColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            __strong typeof(weakSuperView) strongSuperView = weakSuperView;
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return strongSuperView.fwTabAnimated.darkAnimatedBackgroundColor;
            }else {
                return strongSuperView.fwTabAnimated.animatedBackgroundColor;
            }
        }];

        self.animatedColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            __strong typeof(weakSuperView) strongSuperView = weakSuperView;
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return strongSuperView.fwTabAnimated.darkAnimatedColor;
            }else {
                return strongSuperView.fwTabAnimated.animatedColor;
            }
        }];
        
        for (FWTabComponentLayer *layer in self.resultLayerArray) {
            layer.backgroundColor = self.animatedColor.CGColor;
            if (layer.contents && layer.placeholderName && layer.placeholderName.length > 0) {
                layer.contents = (id)[UIImage imageNamed:layer.placeholderName].CGImage;
            }
        }
        
        if ([FWTabManagerMethod canAddShimmer:superView]) {
            
            __block CGFloat brigtness = 0.;
            UIColor *baseColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
                if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                    brigtness = [FWTabAnimated sharedAnimated].shimmerBrightnessInDarkMode;
                    return [FWTabAnimated sharedAnimated].shimmerBackColorInDarkMode;
                }else {
                    brigtness = [FWTabAnimated sharedAnimated].shimmerBrightness;
                    return [FWTabAnimated sharedAnimated].shimmerBackColor;
                }
            }];
            
            for (FWTabComponentLayer *layer in self.resultLayerArray) {
                if (layer.colors && [layer animationForKey:FWTabAnimatedShimmerAnimation]) {
                    if (baseColor) {
                        layer.colors = @[
                        (id)baseColor.CGColor,
                        (id)[FWTabManagerMethod brightenedColor:baseColor
                                                   brightness:brigtness].CGColor,
                        (id)baseColor.CGColor
                        ];
                    }
                }
            }
        }
        
        if ([FWTabManagerMethod canAddDropAnimation:superView]) {
            
            UIColor *deepColor;
            if (@available(iOS 13.0, *)) {
                if (superView.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                    if (superView.fwTabAnimated.dropAnimationDeepColorInDarkMode) {
                        deepColor = superView.fwTabAnimated.dropAnimationDeepColorInDarkMode;
                    }else {
                        deepColor = [FWTabAnimated sharedAnimated].dropAnimationDeepColorInDarkMode;
                    }
                }else {
                    if (superView.fwTabAnimated.dropAnimationDeepColor) {
                        deepColor = superView.fwTabAnimated.dropAnimationDeepColor;
                    }else {
                        deepColor = [FWTabAnimated sharedAnimated].dropAnimationDeepColor;
                    }
                }
            } else {
                if (superView.fwTabAnimated.dropAnimationDeepColor) {
                    deepColor = superView.fwTabAnimated.dropAnimationDeepColor;
                }else {
                    deepColor = [FWTabAnimated sharedAnimated].dropAnimationDeepColor;
                }
            }
            
            for (FWTabComponentLayer *layer in self.resultLayerArray) {
                if ([layer animationForKey:FWTabAnimatedDropAnimation]) {
                    CAKeyframeAnimation *animation = [layer animationForKey:FWTabAnimatedDropAnimation].copy;
                    animation.values = @[
                                         (id)deepColor.CGColor,
                                         (id)layer.backgroundColor,
                                         (id)layer.backgroundColor,
                                         (id)deepColor.CGColor
                                         ];
                    [layer removeAnimationForKey:FWTabAnimatedDropAnimation];
                    [layer addAnimation:animation forKey:FWTabAnimatedDropAnimation];
                }
            }
        }
    }
}

- (void)setRadiusAndColorWithView:(UIView *)view
                        superView:(UIView *)superView
                      tabAnimated:(__kindof FWTabViewAnimated *)tabAnimated {
    
    if (@available(iOS 13.0, *)) {
        if (superView.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            self.animatedColor = tabAnimated.darkAnimatedColor;
            self.animatedBackgroundColor = tabAnimated.darkAnimatedBackgroundColor;
        }else {
            self.animatedColor = tabAnimated.animatedColor;
            self.animatedBackgroundColor = tabAnimated.animatedBackgroundColor;
        }
    }else {
        self.animatedColor = tabAnimated.animatedColor;
        self.animatedBackgroundColor = tabAnimated.animatedBackgroundColor;
    }
    
    if (tabAnimated.animatedBackViewCornerRadius > 0) {
        self.tabLayer.cornerRadius = tabAnimated.animatedBackViewCornerRadius;
    }else {
        if (view.layer.cornerRadius > 0.) {
            self.tabLayer.cornerRadius = view.layer.cornerRadius;
        }else {
            if ([view isKindOfClass:[UITableViewCell class]]) {
                UITableViewCell *cell = (UITableViewCell *)view;
                if (cell.contentView.layer.cornerRadius > 0.) {
                    self.tabLayer.cornerRadius = cell.contentView.layer.cornerRadius;
                }
            }else {
                if ([view isKindOfClass:[UICollectionViewCell class]]) {
                    UICollectionViewCell *cell = (UICollectionViewCell *)view;
                    if (cell.contentView.layer.cornerRadius > 0.) {
                        self.tabLayer.cornerRadius = cell.contentView.layer.cornerRadius;
                    }
                }
            }
        }
    }
}

- (void)addAnimatedTagWithComponentLayer:(FWTabComponentLayer *)layer
                                   index:(NSInteger)index
                            isFromeLines:(BOOL)isFromeLines {
    CATextLayer *textLayer = [CATextLayer layer];
    textLayer.string = [NSString stringWithFormat:@"%ld",(long)index];
    
    if (isFromeLines) {
        textLayer.frame = CGRectMake(0, 0, layer.frame.size.width, 20);
    }else {
        if (!layer.fromImageView) {
            textLayer.bounds = CGRectMake(layer.bounds.origin.x, layer.bounds.origin.y, layer.bounds.size.width, 20);
        }else {
            textLayer.frame = CGRectMake(0, layer.frame.size.height/2.0, layer.frame.size.width, 20);
        }
    }
    
    textLayer.contentsScale = ([[UIScreen mainScreen] scale] > 3.0) ? [[UIScreen mainScreen] scale]:3.0;
    textLayer.font = (__bridge CFTypeRef)(kTagDefaultFontName);
    textLayer.fontSize = kTagDefaultFontSize;
    textLayer.alignmentMode = kCAAlignmentRight;
    textLayer.foregroundColor = [UIColor redColor].CGColor;
    [layer addSublayer:textLayer];
}

- (void)addLayers:(CGRect)frame
     cornerRadius:(CGFloat)cornerRadius
            lines:(NSInteger)lines
            space:(CGFloat)space
        lastScale:(CGFloat)lastScale
        fromIndex:(NSInteger)fromIndex
     removeOnDrop:(BOOL)removeOnDrop
        tabHeight:(CGFloat)tabHeight
        loadStyle:(FWTabViewLoadAnimationStyle)loadStyle
            index:(NSInteger)index {
    
    CGFloat textHeight = kDefaultHeight*[FWTabAnimated sharedAnimated].animatedHeightCoefficient;
    
    if (self.animatedHeight > 0.) {
        textHeight = self.animatedHeight;
    }
    
    if (tabHeight > 0.) {
        textHeight = tabHeight;
    }
    
    if (lines == 0) {
        lines = (frame.size.height*1.0)/(textHeight+space);
        if (lines >= 0 && lines <= 1) {
            tabAnimatedLog(@"FWTabAnimated提醒 - 监测到多行文本高度为0，动画时将使用默认行数3");
            lines = 3;
        }
    }
    
    for (NSInteger i = 0; i < lines; i++) {
        
        CGRect rect;
        if (i != lines - 1) {
            rect = CGRectMake(frame.origin.x, frame.origin.y+i*(textHeight+space), frame.size.width, textHeight);
        }else {
            rect = CGRectMake(frame.origin.x, frame.origin.y+i*(textHeight+space), frame.size.width*lastScale, textHeight);
        }
        
        FWTabComponentLayer *layer = [[FWTabComponentLayer alloc]init];
        layer.anchorPoint = CGPointMake(0, 0);
        layer.position = CGPointMake(0, 0);
        layer.frame = rect;
        
        if (layer.contents) {
            layer.backgroundColor = UIColor.clearColor.CGColor;
        }else {
            if (layer.backgroundColor == nil) {
                layer.backgroundColor = self.animatedColor.CGColor;
            }
        }
        
        if (cornerRadius == 0.) {
            if (self.cancelGlobalCornerRadius) {
                layer.cornerRadius = self.animatedCornerRadius;
            }else {
                if ([FWTabAnimated sharedAnimated].useGlobalCornerRadius) {
                    if ([FWTabAnimated sharedAnimated].animatedCornerRadius != 0.) {
                        layer.cornerRadius = [FWTabAnimated sharedAnimated].animatedCornerRadius;
                    }else {
                        layer.cornerRadius = layer.frame.size.height/2.0;
                    }
                }
            }
        }else {
            layer.cornerRadius = cornerRadius;
        }
        
        if (i == lines - 1) {
            
            layer.tagIndex = index;
            
            if (loadStyle != FWTabViewLoadAnimationWithOnlySkeleton) {
                [layer addAnimation:[self getAnimationWithLoadStyle:loadStyle] forKey:FWTabAnimatedLocationAnimation];
            }
            
#ifdef DEBUG
            // 添加红色标记
            if ([FWTabAnimated sharedAnimated].openAnimationTag) {
                [self addAnimatedTagWithComponentLayer:layer
                                                 index:index
                                          isFromeLines:YES];
            }
#endif
        }else {
            layer.tagIndex = FWTabViewAnimatedErrorCode;
        }
        
        if (!removeOnDrop) {
            if (fromIndex != -1) {
                layer.dropAnimationIndex = fromIndex+i;
            }else {
                layer.dropAnimationIndex = self.resultLayerArray.count;
            }
            
            if (self.dropAnimationCount < layer.dropAnimationIndex) {
                self.dropAnimationCount = layer.dropAnimationIndex;
            }
        }
        
        [self.tabLayer addSublayer:layer];
        [self.resultLayerArray addObject:layer];
    }
}

- (CABasicAnimation *)getAnimationWithLoadStyle:(FWTabViewLoadAnimationStyle)loadStyle {
    CGFloat duration = [FWTabAnimated sharedAnimated].animatedDuration;
    CGFloat value = 0.;
    
    if (loadStyle == FWTabViewLoadAnimationToLong) {
        value = [FWTabAnimated sharedAnimated].longToValue;
    }else {
        value = [FWTabAnimated sharedAnimated].shortToValue;
    }
    
    return [FWTabAnimationMethod scaleXAnimationDuration:duration toValue:value];
}

- (CGRect)resetFrame:(FWTabComponentLayer *)layer
                rect:(CGRect)rect {
    
    BOOL isImageView = layer.fromImageView;
    
    CGFloat height = 0.;
    // 修改拿掉 isImageView 限制 开放 tabViewHeight  需要可以修改 imageView的高度 xiaoxin
    if (layer.tabViewHeight > 0.) {
        height = layer.tabViewHeight;
        rect = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, height);
    }else if (!isImageView) {
        if (self.animatedHeight > 0.) {
            height = self.animatedHeight;
        }else {
            if ([FWTabAnimated sharedAnimated].useGlobalAnimatedHeight) {
                height = [FWTabAnimated sharedAnimated].animatedHeight;
            }else {
                if (!isImageView) {
                    height = rect.size.height*[FWTabAnimated sharedAnimated].animatedHeightCoefficient;
                    if (layer.cornerRadius > 0) {
                        CGFloat originScale = layer.cornerRadius/rect.size.height;
                        if (originScale == .5 && rect.size.width == rect.size.height) {
                            rect = CGRectMake(rect.origin.x, rect.origin.y, height, height);
                        }
                        layer.cornerRadius = height*originScale;
                    }
                }
            }
        }
        rect = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, height);
    }
    
    BOOL isCenterLab = layer.fromCenterLabel;
    if (isCenterLab && !layer.isCancelAlignCenter) {
        rect = CGRectMake((self.tabLayer.frame.size.width - rect.size.width)/2.0, rect.origin.y, rect.size.width, rect.size.height);
    }
    
    return rect;
}

#pragma mark - NSSecureCoding / NSCopying

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (id)copyWithZone:(NSZone *)zone {
    
    FWTabComponentManager *manager = [[[self class] allocWithZone:zone] init];
    manager.fileName = self.fileName;
    
    manager.resultLayerArray = @[].mutableCopy;
    for (FWTabComponentLayer *layer in self.resultLayerArray) {
        [manager.resultLayerArray addObject:layer.copy];
    }
    
    manager.animatedColor = self.animatedColor;
    manager.animatedBackgroundColor = self.animatedBackgroundColor;
    manager.animatedHeight = self.animatedHeight;
    manager.animatedCornerRadius = self.animatedCornerRadius;
    manager.cancelGlobalCornerRadius = self.cancelGlobalCornerRadius;
    manager.dropAnimationCount = self.dropAnimationCount;
    manager.entireIndexArray = self.entireIndexArray.mutableCopy;
    manager.version = self.version;
    manager.needChangeRowStatus = self.needChangeRowStatus;

    return manager;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_fileName forKey:@"fileName"];
    [aCoder encodeObject:_resultLayerArray forKey:@"resultLayerArray"];
    
    [aCoder encodeObject:_animatedColor forKey:@"animatedColor"];
    [aCoder encodeObject:_animatedBackgroundColor forKey:@"animatedBackgroundColor"];
    [aCoder encodeFloat:_animatedHeight forKey:@"animatedHeight"];
    [aCoder encodeFloat:_animatedCornerRadius forKey:@"animatedCornerRadius"];
    [aCoder encodeBool:_cancelGlobalCornerRadius forKey:@"cancelGlobalCornerRadius"];
    
    [aCoder encodeInteger:_dropAnimationCount forKey:@"dropAnimationCount"];
    [aCoder encodeObject:_entireIndexArray forKey:@"entireIndexArray"];
    
    [aCoder encodeObject:_version forKey:@"version"];
    [aCoder encodeBool:_needChangeRowStatus forKey:@"needChangeRowStatus"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.fileName = [aDecoder decodeObjectForKey:@"fileName"];
        self.resultLayerArray = [aDecoder decodeObjectForKey:@"resultLayerArray"];
        
        self.animatedColor = [aDecoder decodeObjectForKey:@"animatedColor"];
        self.animatedBackgroundColor = [aDecoder decodeObjectForKey:@"animatedBackgroundColor"];
        self.animatedHeight = [aDecoder decodeFloatForKey:@"animatedHeight"];
        self.animatedCornerRadius = [aDecoder decodeFloatForKey:@"animatedCornerRadius"];
        self.cancelGlobalCornerRadius = [aDecoder decodeBoolForKey:@"cancelGlobalCornerRadius"];
        
        self.dropAnimationCount = [aDecoder decodeIntegerForKey:@"dropAnimationCount"];
        self.entireIndexArray = [aDecoder decodeObjectForKey:@"entireIndexArray"];
        
        self.version = [aDecoder decodeObjectForKey:@"version"];
        self.needChangeRowStatus = [aDecoder decodeBoolForKey:@"needChangeRowStatus"];
    }
    return self;
}

#pragma mark - Getter / Setter

- (BOOL)needUpdate {
    if (self.version && self.version.length > 0 &&
        [FWTabAnimated sharedAnimated].cacheManager.currentSystemVersion &&
        [FWTabAnimated sharedAnimated].cacheManager.currentSystemVersion.length > 0) {
        if ([self.version isEqualToString:[FWTabAnimated sharedAnimated].cacheManager.currentSystemVersion]) {
            return NO;
        }
        return YES;
    }
    return YES;
}

- (NSInteger)currentRow {
    _needChangeRowStatus = YES;
    return _currentRow;
}

- (void)setAnimatedBackgroundColor:(UIColor *)animatedBackgroundColor {
    _animatedBackgroundColor = animatedBackgroundColor;
    if (_tabLayer && animatedBackgroundColor) {
        _tabLayer.backgroundColor = animatedBackgroundColor.CGColor;
    }
}

@end

@implementation FWTabTableDeDaSelfModel

- (NSInteger)tab_deda_numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView.fwTabAnimated.state == FWTabViewAnimationStart) {
        
        if (tableView.fwTabAnimated.animatedSectionCount != 0) {
            return tableView.fwTabAnimated.animatedSectionCount;
        }

        NSInteger count = [self tab_deda_numberOfSectionsInTableView:tableView];
        if (count == 0) {
            count = tableView.fwTabAnimated.cellClassArray.count;
        }

        if (count == 0) return 1;
        
        return count;
    }
    
    return [self tab_deda_numberOfSectionsInTableView:tableView];
}

- (NSInteger)tab_deda_tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (tableView.fwTabAnimated.runMode == FWTabAnimatedRunByRow) {
        NSInteger count = [self tab_deda_tableView:tableView numberOfRowsInSection:section];
        if (count == 0) {
            return tableView.fwTabAnimated.cellClassArray.count;
        }
        return count;
    }
    
    // If the animation running, return animatedCount.
    if ([tableView.fwTabAnimated currentIndexIsAnimatingWithIndex:section]) {
        
        // 开发者指定section/row
        if (tableView.fwTabAnimated.animatedIndexArray.count > 0) {
            
            // 没有获取到动画时row数量
            if (tableView.fwTabAnimated.animatedCountArray.count == 0) {
                return 0;
            }
            
            // 匹配当前section
            for (NSNumber *num in tableView.fwTabAnimated.animatedIndexArray) {
                if ([num integerValue] == section) {
                    NSInteger index = [tableView.fwTabAnimated.animatedIndexArray indexOfObject:num];
                    if (index > tableView.fwTabAnimated.animatedCountArray.count - 1) {
                        return [[tableView.fwTabAnimated.animatedCountArray lastObject] integerValue];
                    }else {
                        return [tableView.fwTabAnimated.animatedCountArray[index] integerValue];
                    }
                }
                
                // 没有匹配到指定的数量
                if ([num isEqual:[tableView.fwTabAnimated.animatedIndexArray lastObject]]) {
                    return 0;
                }
            }
        }
        
        if (tableView.fwTabAnimated.animatedCountArray.count > 0) {
            if (section > tableView.fwTabAnimated.animatedCountArray.count - 1) {
                return tableView.fwTabAnimated.animatedCount;
            }
            return [tableView.fwTabAnimated.animatedCountArray[section] integerValue];
        }
        return tableView.fwTabAnimated.animatedCount;
    }
    return [self tab_deda_tableView:tableView numberOfRowsInSection:section];
}

- (CGFloat)tab_deda_tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger index;
    switch (tableView.fwTabAnimated.runMode) {
        case FWTabAnimatedRunBySection: {
            index = indexPath.section;
        }
            break;
        case FWTabAnimatedRunByRow: {
            index = indexPath.row;
        }
            break;
    }
    
    if ([tableView.fwTabAnimated currentIndexIsAnimatingWithIndex:index]) {
        
        // 开发者指定section
        if (tableView.fwTabAnimated.animatedIndexArray.count > 0) {
            
            // 匹配当前section
            for (NSNumber *num in tableView.fwTabAnimated.animatedIndexArray) {
                if ([num integerValue] == index) {
                    NSInteger currentIndex = [tableView.fwTabAnimated.animatedIndexArray indexOfObject:num];
                    if (currentIndex > tableView.fwTabAnimated.cellHeightArray.count - 1) {
                        index = [tableView.fwTabAnimated.cellHeightArray count] - 1;
                    }else {
                        index = currentIndex;
                    }
                    break;
                }
                
                // 没有匹配到注册的cell
                if ([num isEqual:[tableView.fwTabAnimated.animatedIndexArray lastObject]]) {
                    return 1.;
                }
            }
        }else {
            if (index > (tableView.fwTabAnimated.cellClassArray.count - 1)) {
                index = tableView.fwTabAnimated.cellClassArray.count - 1;
                tabAnimatedLog(@"FWTabAnimated提醒 - section的数量和指定分区的数量不一致，超出的section，将使用最后一个分区cell加载");
            }
        }
        
        return [tableView.fwTabAnimated.cellHeightArray[index] floatValue];
    }
    return [self tab_deda_tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (UITableViewCell *)tab_deda_tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger index;
    switch (tableView.fwTabAnimated.runMode) {
        case FWTabAnimatedRunBySection: {
            index = indexPath.section;
        }
            break;
        case FWTabAnimatedRunByRow: {
            index = indexPath.row;
        }
            break;
    }
    
    if ([tableView.fwTabAnimated currentIndexIsAnimatingWithIndex:index]) {
        
        // 开发者指定index
        if (tableView.fwTabAnimated.animatedIndexArray.count > 0) {
            
            if (tableView.fwTabAnimated.cellClassArray.count == 0) {
                return UITableViewCell.new;
            }
            
            // 匹配当前section
            for (NSNumber *num in tableView.fwTabAnimated.animatedIndexArray) {
                if ([num integerValue] == index) {
                    NSInteger currentIndex = [tableView.fwTabAnimated.animatedIndexArray indexOfObject:num];
                    if (currentIndex > tableView.fwTabAnimated.cellClassArray.count - 1) {
                        index = [tableView.fwTabAnimated.cellClassArray count] - 1;
                    }else {
                        index = currentIndex;
                    }
                    break;
                }
                
                if ([num isEqual:[tableView.fwTabAnimated.animatedIndexArray lastObject]]) {
                    return UITableViewCell.new;
                }
            }
        }else {
            if (index > (tableView.fwTabAnimated.cellClassArray.count - 1)) {
                index = tableView.fwTabAnimated.cellClassArray.count - 1;
                tabAnimatedLog(@"FWTabAnimated - section的数量和指定分区的数量不一致，超出的section，将使用最后一个分区cell加载");
            }
        }
        
        Class currentClass = tableView.fwTabAnimated.cellClassArray[index];
        NSString *className = NSStringFromClass(currentClass);
        if ([className containsString:@"."]) {
            NSRange range = [className rangeOfString:@"."];
            className = [className substringFromIndex:range.location+1];
        }
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[NSString stringWithFormat:@"tab_%@",className] forIndexPath:indexPath];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        NSString *fileName = [className stringByAppendingString:[NSString stringWithFormat:@"_%@",tableView.fwTabAnimated.targetControllerClassName]];
        
        if (nil == cell.fwTabComponentManager) {
            
            FWTabComponentManager *manager = [[FWTabAnimated sharedAnimated].cacheManager getComponentManagerWithFileName:fileName];

            if (manager &&
                !manager.needChangeRowStatus) {
                
                manager.fileName = fileName;
                manager.isLoad = YES;
                manager.tabTargetClass = currentClass;
                manager.currentSection = indexPath.section;
                cell.fwTabComponentManager = manager;
                
                [manager reAddToView:cell
                           superView:tableView];
                
                [FWTabManagerMethod startAnimationToSubViews:cell
                                                  rootView:cell];
                [FWTabManagerMethod addExtraAnimationWithSuperView:tableView
                                                      targetView:cell
                                                         manager:cell.fwTabComponentManager];
            }else {
                
                [FWTabManagerMethod fullData:cell];
                cell.fwTabComponentManager = [FWTabComponentManager initWithView:cell
                                                                   superView:tableView tabAnimated:tableView.fwTabAnimated];
                cell.fwTabComponentManager.currentSection = indexPath.section;
                cell.fwTabComponentManager.fileName = fileName;
                cell.fwTabComponentManager.tabTargetClass = currentClass;
            
                __weak typeof(cell) weakCell = cell;
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    FWTabTableAnimated *tabAnimated = (FWTabTableAnimated *)tableView.fwTabAnimated;
                    
                    if (weakCell && tabAnimated && weakCell.fwTabComponentManager) {
                        [FWTabManagerMethod runAnimationWithSuperView:tableView
                                                         targetView:weakCell
                                                             isCell:YES
                                                            manager:weakCell.fwTabComponentManager];
                    }
                });
            }
        
        }else {
            if (cell.fwTabComponentManager.tabLayer.hidden) {
                cell.fwTabComponentManager.tabLayer.hidden = NO;
            }
        }
        cell.fwTabComponentManager.currentRow = indexPath.row;
        
        if (tableView.fwTabAnimated.oldEstimatedRowHeight > 0) {
            [FWTabManagerMethod fullData:cell];
            __weak typeof(cell) weakCell = cell;
            dispatch_async(dispatch_get_main_queue(), ^{
                weakCell.fwTabComponentManager.tabLayer.frame = weakCell.bounds;
                [FWTabManagerMethod resetData:weakCell];
            });
        }
        
        return cell;
    }
    return [self tab_deda_tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (void)tab_deda_tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger index;
    switch (tableView.fwTabAnimated.runMode) {
        case FWTabAnimatedRunBySection: {
            index = indexPath.section;
        }
            break;
        case FWTabAnimatedRunByRow: {
            index = indexPath.row;
        }
            break;
    }
    
    if ([tableView.fwTabAnimated currentIndexIsAnimatingWithIndex:index]) {
        return;
    }
    [self tab_deda_tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
}

- (void)tab_deda_tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger index;
    switch (tableView.fwTabAnimated.runMode) {
        case FWTabAnimatedRunBySection: {
            index = indexPath.section;
        }
            break;
        case FWTabAnimatedRunByRow: {
            index = indexPath.row;
        }
            break;
    }
    
    if ([tableView.fwTabAnimated currentIndexIsAnimatingWithIndex:index]) {
        return;
    }
    [self tab_deda_tableView:tableView didSelectRowAtIndexPath:indexPath];
}

#pragma mark - About HeaderFooterView

- (CGFloat)tab_deda_tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if ([tableView.fwTabAnimated currentIndexIsAnimatingWithIndex:section]) {
        NSInteger index = [tableView.fwTabAnimated headerNeedAnimationOnSection:section];
        if (index != FWTabViewAnimatedErrorCode) {
            NSNumber *value = nil;
            if (index > tableView.fwTabAnimated.headerHeightArray.count - 1) {
                value = tableView.fwTabAnimated.headerHeightArray.lastObject;
            }else {
                value = tableView.fwTabAnimated.headerHeightArray[index];
            }
            return [value floatValue];
        }
        return [self tab_deda_tableView:tableView heightForHeaderInSection:section];
    }
    return [self tab_deda_tableView:tableView heightForHeaderInSection:section];
}

- (CGFloat)tab_deda_tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if ([tableView.fwTabAnimated currentIndexIsAnimatingWithIndex:section]) {
        NSInteger index = [tableView.fwTabAnimated footerNeedAnimationOnSection:section];
        if (index != FWTabViewAnimatedErrorCode) {
            NSNumber *value = nil;
            if (index > tableView.fwTabAnimated.footerHeightArray.count - 1) {
                value = tableView.fwTabAnimated.footerHeightArray.lastObject;
            }else {
                value = tableView.fwTabAnimated.footerHeightArray[index];
            }
            return [value floatValue];
        }
        return [self tab_deda_tableView:tableView heightForFooterInSection:section];
    }
    return [self tab_deda_tableView:tableView heightForFooterInSection:section];
}

- (nullable UIView *)tab_deda_tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if ([tableView.fwTabAnimated currentIndexIsAnimatingWithIndex:section]) {
        NSInteger index = [tableView.fwTabAnimated headerNeedAnimationOnSection:section];
        if (index != FWTabViewAnimatedErrorCode) {
            
            Class class;
            if (index > tableView.fwTabAnimated.headerClassArray.count - 1) {
                class = tableView.fwTabAnimated.headerClassArray.lastObject;
            }else {
                class = tableView.fwTabAnimated.headerClassArray[index];
            }
            
            UIView *headerFooterView = class.new;
            headerFooterView.fwTabAnimated = FWTabViewAnimated.new;
            [headerFooterView fwTabStartAnimation];
            
            NSString *fileName = [NSStringFromClass(class) stringByAppendingString:[NSString stringWithFormat:@"_%@",tableView.fwTabAnimated.targetControllerClassName]];
            
            if (nil == headerFooterView.fwTabComponentManager) {
                
                FWTabComponentManager *manager = [[FWTabAnimated sharedAnimated].cacheManager getComponentManagerWithFileName:fileName];
                
                if (manager) {
                    manager.fileName = fileName;
                    manager.isLoad = YES;
                    manager.tabTargetClass = class;
                    manager.currentSection = section;
                    [manager reAddToView:headerFooterView
                               superView:tableView];
                    headerFooterView.fwTabComponentManager = manager;
                    [FWTabManagerMethod startAnimationToSubViews:headerFooterView
                                                      rootView:headerFooterView];
                    [FWTabManagerMethod addExtraAnimationWithSuperView:tableView
                                                          targetView:headerFooterView
                                                             manager:headerFooterView.fwTabComponentManager];
                }else {
                    [FWTabManagerMethod fullData:headerFooterView];
                    headerFooterView.fwTabComponentManager = [FWTabComponentManager initWithView:headerFooterView superView:tableView tabAnimated:tableView.fwTabAnimated];
                    headerFooterView.fwTabComponentManager.currentSection = section;
                    headerFooterView.fwTabComponentManager.fileName = fileName;
                    
                    __weak typeof(headerFooterView) weakView = headerFooterView;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (weakView && weakView.fwTabComponentManager) {
                            
                            BOOL isCell = NO;
                            if ([weakView isKindOfClass:[UITableViewHeaderFooterView class]]) {
                                isCell = YES;
                            }
                            
                            [FWTabManagerMethod runAnimationWithSuperView:tableView
                                                             targetView:weakView
                                                                 isCell:isCell
                                                                manager:weakView.fwTabComponentManager];
                        }
                    });
                }
            }else {
                if (headerFooterView.fwTabComponentManager.tabLayer.hidden) {
                    headerFooterView.fwTabComponentManager.tabLayer.hidden = NO;
                }
            }
            headerFooterView.fwTabComponentManager.tabTargetClass = class;
            if (tableView.fwTabAnimated.oldEstimatedRowHeight > 0) {
                [FWTabManagerMethod fullData:headerFooterView];
                __weak typeof(headerFooterView) weakView = headerFooterView;
                dispatch_async(dispatch_get_main_queue(), ^{
                    weakView.fwTabComponentManager.tabLayer.frame = weakView.bounds;
                    [FWTabManagerMethod resetData:weakView];
                });
            }

            return headerFooterView;
        }
        return [self tab_deda_tableView:tableView viewForHeaderInSection:section];
    }
    return [self tab_deda_tableView:tableView viewForHeaderInSection:section];
}

- (nullable UIView *)tab_deda_tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if ([tableView.fwTabAnimated currentIndexIsAnimatingWithIndex:section]) {
        NSInteger index = [tableView.fwTabAnimated footerNeedAnimationOnSection:section];
        if (index != FWTabViewAnimatedErrorCode) {
            
            Class class;
            if (index > tableView.fwTabAnimated.footerClassArray.count - 1) {
                class = tableView.fwTabAnimated.footerClassArray.lastObject;
            }else {
                class = tableView.fwTabAnimated.footerClassArray[index];
            }
            
            UIView *headerFooterView = class.new;
            headerFooterView.fwTabAnimated = FWTabViewAnimated.new;
            [headerFooterView fwTabStartAnimation];
            
            NSString *fileName = [NSStringFromClass(class) stringByAppendingString:[NSString stringWithFormat:@"_%@",tableView.fwTabAnimated.targetControllerClassName]];
            
            if (nil == headerFooterView.fwTabComponentManager) {
                
                FWTabComponentManager *manager = [[FWTabAnimated sharedAnimated].cacheManager getComponentManagerWithFileName:fileName];
                
                if (manager) {
                    manager.fileName = fileName;
                    manager.isLoad = YES;
                    manager.tabTargetClass = class;
                    manager.currentSection = section;
                    [manager reAddToView:headerFooterView
                               superView:tableView];
                    headerFooterView.fwTabComponentManager = manager;
                    
                    [FWTabManagerMethod startAnimationToSubViews:headerFooterView
                                                      rootView:headerFooterView];
                    [FWTabManagerMethod addExtraAnimationWithSuperView:tableView
                                                          targetView:headerFooterView
                                                             manager:headerFooterView.fwTabComponentManager];
                    
                }else {
                    [FWTabManagerMethod fullData:headerFooterView];
                    headerFooterView.fwTabComponentManager = [FWTabComponentManager initWithView:headerFooterView superView:tableView tabAnimated:tableView.fwTabAnimated];
                    headerFooterView.fwTabComponentManager.currentSection = section;
                    headerFooterView.fwTabComponentManager.fileName = fileName;
                    
                    __weak typeof(headerFooterView) weakView = headerFooterView;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (weakView && weakView.fwTabComponentManager) {
                            
                            BOOL isCell = NO;
                            if ([weakView isKindOfClass:[UITableViewHeaderFooterView class]]) {
                                isCell = YES;
                            }
                            
                            [FWTabManagerMethod runAnimationWithSuperView:tableView
                                                             targetView:weakView
                                                                 isCell:isCell
                                                                manager:weakView.fwTabComponentManager];
                        }
                    });
                }
            }else {
                if (headerFooterView.fwTabComponentManager.tabLayer.hidden) {
                    headerFooterView.fwTabComponentManager.tabLayer.hidden = NO;
                }
            }
            
            headerFooterView.fwTabComponentManager.tabTargetClass = class;
            
            if (tableView.fwTabAnimated.oldEstimatedRowHeight > 0) {
                [FWTabManagerMethod fullData:headerFooterView];
                __weak typeof(headerFooterView) weakView = headerFooterView;
                dispatch_async(dispatch_get_main_queue(), ^{
                    weakView.fwTabComponentManager.tabLayer.frame = weakView.bounds;
                    [FWTabManagerMethod resetData:weakView];
                });
            }
            
            return headerFooterView;
        }
        return [self tab_deda_tableView:tableView viewForFooterInSection:section];
    }
    return [self tab_deda_tableView:tableView viewForFooterInSection:section];
}


@end

@implementation FWTabCollectionDeDaSelfModel

- (NSInteger)tab_deda_numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    
    if (collectionView.fwTabAnimated.state == FWTabViewAnimationStart) {
        
        if (collectionView.fwTabAnimated.animatedSectionCount != 0) {
            return collectionView.fwTabAnimated.animatedSectionCount;
        }

        NSInteger count = [self tab_deda_numberOfSectionsInCollectionView:collectionView];
        if (count == 0) {
            count = collectionView.fwTabAnimated.cellClassArray.count;
        }

        if (count == 0) return 1;
        
        return count;
    }
    
    return [self tab_deda_numberOfSectionsInCollectionView:collectionView];
}

- (NSInteger)tab_deda_collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    if (collectionView.fwTabAnimated.runMode == FWTabAnimatedRunByRow) {
        NSInteger count = [self tab_deda_collectionView:collectionView numberOfItemsInSection:section];
        if (count == 0) {
            return collectionView.fwTabAnimated.cellClassArray.count;
        }
        return count;
    }
    
    if ([collectionView.fwTabAnimated currentIndexIsAnimatingWithIndex:section]) {
        
        // 开发者指定section
        if (collectionView.fwTabAnimated.animatedIndexArray.count > 0) {
            
            // 匹配当前section
            for (NSNumber *num in collectionView.fwTabAnimated.animatedIndexArray) {
                if ([num integerValue] == section) {
                    NSInteger index = [collectionView.fwTabAnimated.animatedIndexArray indexOfObject:num];
                    if (index > collectionView.fwTabAnimated.animatedCountArray.count - 1) {
                        return [[collectionView.fwTabAnimated.animatedCountArray lastObject] integerValue];
                    }else {
                        return [collectionView.fwTabAnimated.animatedCountArray[index] integerValue];
                    }
                }
                
                if ([num isEqual:[collectionView.fwTabAnimated.animatedIndexArray lastObject]]) {
                    return [self tab_deda_collectionView:collectionView numberOfItemsInSection:section];
                }
            }
        }
        
        if (collectionView.fwTabAnimated.animatedCountArray.count > 0) {
            if (section > collectionView.fwTabAnimated.animatedCountArray.count - 1) {
                return collectionView.fwTabAnimated.animatedCount;
            }
            return [collectionView.fwTabAnimated.animatedCountArray[section] integerValue];
        }
        return collectionView.fwTabAnimated.animatedCount;
    }
    return [self tab_deda_collectionView:collectionView numberOfItemsInSection:section];
}

- (CGSize)tab_deda_collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger index;
    switch (collectionView.fwTabAnimated.runMode) {
        case FWTabAnimatedRunBySection: {
            index = indexPath.section;
        }
            break;
        case FWTabAnimatedRunByRow: {
            index = indexPath.row;
        }
            break;
    }
    
    if ([collectionView.fwTabAnimated currentIndexIsAnimatingWithIndex:index]) {
        
        // 开发者指定section
        if (collectionView.fwTabAnimated.animatedIndexArray.count > 0) {
            
            // 匹配当前section
            for (NSNumber *num in collectionView.fwTabAnimated.animatedIndexArray) {
                if ([num integerValue] == index) {
                    NSInteger currentIndex = [collectionView.fwTabAnimated.animatedIndexArray indexOfObject:num];
                    if (currentIndex > collectionView.fwTabAnimated.cellSizeArray.count - 1) {
                        index = [collectionView.fwTabAnimated.cellSizeArray count] - 1;
                    }else {
                        index = currentIndex;
                    }
                    break;
                }
                
                if ([num isEqual:[collectionView.fwTabAnimated.animatedIndexArray lastObject]]) {
                    return [self tab_deda_collectionView:collectionView layout:collectionViewLayout sizeForItemAtIndexPath:indexPath];
                }
            }
        }else {
            if (index > (collectionView.fwTabAnimated.cellSizeArray.count - 1)) {
                index = collectionView.fwTabAnimated.cellSizeArray.count - 1;
                tabAnimatedLog(@"FWTabAnimated提醒 - 获取到的分区的数量和设置的分区数量不一致，超出的分区值部分，将使用最后一个分区cell加载");
            }
        }
        
        CGSize size = [collectionView.fwTabAnimated.cellSizeArray[index] CGSizeValue];
        return size;
    }
    return [self tab_deda_collectionView:collectionView layout:collectionViewLayout sizeForItemAtIndexPath:indexPath];
}

- (UICollectionViewCell *)tab_deda_collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger index;
    switch (collectionView.fwTabAnimated.runMode) {
        case FWTabAnimatedRunBySection: {
            index = indexPath.section;
        }
            break;
        case FWTabAnimatedRunByRow: {
            index = indexPath.row;
        }
            break;
    }
    
    if ([collectionView.fwTabAnimated currentIndexIsAnimatingWithIndex:index]) {
        
        // 开发者指定section
        if (collectionView.fwTabAnimated.animatedIndexArray.count > 0) {
            
            // 匹配当前section
            for (NSNumber *num in collectionView.fwTabAnimated.animatedIndexArray) {
                if ([num integerValue] == index) {
                    NSInteger currentIndex = [collectionView.fwTabAnimated.animatedIndexArray indexOfObject:num];
                    if (currentIndex > collectionView.fwTabAnimated.cellClassArray.count - 1) {
                        index = [collectionView.fwTabAnimated.cellClassArray count] - 1;
                    }else {
                        index = currentIndex;
                    }
                    break;
                }
                
                if ([num isEqual:[collectionView.fwTabAnimated.animatedIndexArray lastObject]]) {
                    return [self tab_deda_collectionView:collectionView cellForItemAtIndexPath:indexPath];
                }
            }
        }else {
            if (index > (collectionView.fwTabAnimated.cellClassArray.count - 1)) {
                index = collectionView.fwTabAnimated.cellClassArray.count - 1;
                tabAnimatedLog(@"FWTabAnimated提醒 - 获取到的分区的数量和设置的分区数量不一致，超出的分区值部分，将使用最后一个分区cell加载");
            }
        }
        
        Class currentClass = collectionView.fwTabAnimated.cellClassArray[index];
        NSString *className = NSStringFromClass(currentClass);
        if ([className containsString:@"."]) {
            NSRange range = [className rangeOfString:@"."];
            className = [className substringFromIndex:range.location+1];
        }
        
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[NSString stringWithFormat:@"tab_%@",className] forIndexPath:indexPath];
        
        NSString *fileName = [className stringByAppendingString:[NSString stringWithFormat:@"_%@",collectionView.fwTabAnimated.targetControllerClassName]];
        
        if (nil == cell.fwTabComponentManager) {
            
            FWTabComponentManager *manager = [[FWTabAnimated sharedAnimated].cacheManager getComponentManagerWithFileName:fileName];

            if (manager &&
                !manager.needChangeRowStatus) {
                manager.fileName = fileName;
                manager.isLoad = YES;
                manager.tabTargetClass = currentClass;
                manager.currentSection = indexPath.section;
                cell.fwTabComponentManager = manager;
                [manager reAddToView:cell
                           superView:collectionView];
                [FWTabManagerMethod startAnimationToSubViews:cell
                                                  rootView:cell];
                [FWTabManagerMethod addExtraAnimationWithSuperView:collectionView
                                                      targetView:cell
                                                         manager:cell.fwTabComponentManager];

            }else {
                [FWTabManagerMethod fullData:cell];
                cell.fwTabComponentManager =
                [FWTabComponentManager initWithView:cell
                                        superView:collectionView  tabAnimated:collectionView.fwTabAnimated];
                cell.fwTabComponentManager.currentSection = indexPath.section;
                cell.fwTabComponentManager.fileName = fileName;
                
                __weak typeof(cell) weakCell = cell;
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (weakCell && weakCell.fwTabComponentManager) {
                        weakCell.fwTabComponentManager.tabTargetClass = weakCell.class;
                        // 加载动画
                        [FWTabManagerMethod runAnimationWithSuperView:collectionView
                                                         targetView:weakCell
                                                             isCell:YES
                                                            manager:weakCell.fwTabComponentManager];
                    }
                });
            }
        
        }else {
            if (cell.fwTabComponentManager.tabLayer.hidden) {
                cell.fwTabComponentManager.tabLayer.hidden = NO;
            }
        }
        cell.fwTabComponentManager.currentRow = indexPath.row;
        
        return cell;
    }
    return [self tab_deda_collectionView:collectionView cellForItemAtIndexPath:indexPath];
}

- (void)tab_deda_collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger index;
    switch (collectionView.fwTabAnimated.runMode) {
        case FWTabAnimatedRunBySection: {
            index = indexPath.section;
        }
            break;
        case FWTabAnimatedRunByRow: {
            index = indexPath.row;
        }
            break;
    }
    
    if ([collectionView.fwTabAnimated currentIndexIsAnimatingWithIndex:index]) {
        return;
    }
    [self tab_deda_collectionView:collectionView willDisplayCell:cell forItemAtIndexPath:indexPath];
}

- (void)tab_deda_collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger index;
    switch (collectionView.fwTabAnimated.runMode) {
        case FWTabAnimatedRunBySection: {
            index = indexPath.section;
        }
            break;
        case FWTabAnimatedRunByRow: {
            index = indexPath.row;
        }
            break;
    }
    
    if ([collectionView.fwTabAnimated currentIndexIsAnimatingWithIndex:index] ||
        collectionView.fwTabAnimated.state == FWTabViewAnimationRunning) {
        return;
    }
    [self tab_deda_collectionView:collectionView didSelectItemAtIndexPath:indexPath];
}

#pragma mark - About HeaderFooterView

- (CGSize)tab_deda_collectionView:(UICollectionView *)collectionView
                      layout:(UICollectionViewLayout*)collectionViewLayout
referenceSizeForHeaderInSection:(NSInteger)section {
    
    if ([collectionView.fwTabAnimated currentIndexIsAnimatingWithIndex:section]) {
        NSInteger index = [collectionView.fwTabAnimated headerFooterNeedAnimationOnSection:section
                                                                                    kind:UICollectionElementKindSectionHeader];
        if (index != FWTabViewAnimatedErrorCode) {
            NSValue *value = nil;
            if (index > collectionView.fwTabAnimated.headerSizeArray.count - 1) {
                value = collectionView.fwTabAnimated.headerSizeArray.lastObject;
            }else {
                value = collectionView.fwTabAnimated.headerSizeArray[index];
            }
            return [value CGSizeValue];
        }
        return [self tab_deda_collectionView:collectionView
                                 layout:collectionViewLayout
        referenceSizeForHeaderInSection:section];
    }
    
    return [self tab_deda_collectionView:collectionView
                             layout:collectionViewLayout
    referenceSizeForHeaderInSection:section];
}

- (CGSize)tab_deda_collectionView:(UICollectionView *)collectionView
                      layout:(UICollectionViewLayout*)collectionViewLayout
referenceSizeForFooterInSection:(NSInteger)section {
    
    if ([collectionView.fwTabAnimated currentIndexIsAnimatingWithIndex:section]) {
        NSInteger index = [collectionView.fwTabAnimated headerFooterNeedAnimationOnSection:section
                                                                                    kind:UICollectionElementKindSectionFooter];
        if (index != FWTabViewAnimatedErrorCode) {
            NSValue *value = nil;
            if (index > collectionView.fwTabAnimated.footerSizeArray.count - 1) {
                value = collectionView.fwTabAnimated.footerSizeArray.lastObject;
            }else {
                value = collectionView.fwTabAnimated.footerSizeArray[index];
            }
            return [value CGSizeValue];
        }
        return [self tab_deda_collectionView:collectionView
                                 layout:collectionViewLayout
        referenceSizeForFooterInSection:section];
    }
    
    return [self tab_deda_collectionView:collectionView
                             layout:collectionViewLayout
    referenceSizeForFooterInSection:section];
}

- (UICollectionReusableView *)tab_deda_collectionView:(UICollectionView *)collectionView
               viewForSupplementaryElementOfKind:(NSString *)kind
                                     atIndexPath:(NSIndexPath *)indexPath {
    if ([collectionView.fwTabAnimated currentIndexIsAnimatingWithIndex:indexPath.section]) {
        
        NSInteger index = [collectionView.fwTabAnimated headerFooterNeedAnimationOnSection:indexPath.section
                                                                                    kind:kind];
        
        if (index == FWTabViewAnimatedErrorCode) {
            return [self tab_deda_collectionView:collectionView
          viewForSupplementaryElementOfKind:kind
                                atIndexPath:indexPath];
        }
        
        Class resuableClass = nil;
        NSString *identifier = nil;
        NSString *defaultPredix = nil;
        
        if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
            if (index > collectionView.fwTabAnimated.headerClassArray.count - 1) {
                resuableClass = collectionView.fwTabAnimated.headerClassArray.lastObject;
            }else {
                resuableClass = collectionView.fwTabAnimated.headerClassArray[index];
            }
            defaultPredix = FWTabViewAnimatedHeaderPrefixString;
            identifier = [NSString stringWithFormat:@"%@%@",FWTabViewAnimatedHeaderPrefixString,NSStringFromClass(resuableClass)];
        }else {
            if (index > collectionView.fwTabAnimated.footerClassArray.count - 1) {
                resuableClass = collectionView.fwTabAnimated.footerClassArray.lastObject;
            }else {
                resuableClass = collectionView.fwTabAnimated.footerClassArray[index];
            }
            defaultPredix = FWTabViewAnimatedFooterPrefixString;
            identifier = [NSString stringWithFormat:@"%@%@",FWTabViewAnimatedFooterPrefixString,NSStringFromClass(resuableClass)];
        }
        
        if (resuableClass == nil) {
            return [self tab_deda_collectionView:collectionView
          viewForSupplementaryElementOfKind:kind
                                atIndexPath:indexPath];
        }
        
        UIView *view = resuableClass.new;
        UICollectionReusableView *reusableView;
        
        if (![view isKindOfClass:[UICollectionReusableView class]]) {
            reusableView = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                              withReuseIdentifier:[NSString stringWithFormat:@"%@%@",defaultPredix,FWTabViewAnimatedDefaultSuffixString]
                                                                     forIndexPath:indexPath];
            for (UIView *view in reusableView.subviews) {
                [view removeFromSuperview];
            }
            view.frame = reusableView.bounds;
            [reusableView addSubview:view];
        }else {
            reusableView = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                              withReuseIdentifier:identifier
                                                                     forIndexPath:indexPath];
        }
        
        NSString *fileName = [NSStringFromClass(resuableClass) stringByAppendingString:[NSString stringWithFormat:@"_%@",collectionView.fwTabAnimated.targetControllerClassName]];
        
        if (nil == reusableView.fwTabComponentManager) {
            
            FWTabComponentManager *manager = [[FWTabAnimated sharedAnimated].cacheManager getComponentManagerWithFileName:fileName];
            
            if (manager &&
                !manager.needChangeRowStatus) {
                manager.fileName = fileName;
                manager.isLoad = YES;
                manager.tabTargetClass = resuableClass;
                manager.currentSection = indexPath.section;
                [manager reAddToView:reusableView
                           superView:collectionView];
                reusableView.fwTabComponentManager = manager;
                [FWTabManagerMethod startAnimationToSubViews:reusableView
                                                  rootView:reusableView];
                [FWTabManagerMethod addExtraAnimationWithSuperView:collectionView
                                                      targetView:reusableView
                                                         manager:reusableView.fwTabComponentManager];
            }else {
                [FWTabManagerMethod fullData:reusableView];
                reusableView.fwTabComponentManager =
                [FWTabComponentManager initWithView:reusableView
                                        superView:collectionView
                                      tabAnimated:collectionView.fwTabAnimated];
                reusableView.fwTabComponentManager.currentSection = indexPath.section;
                reusableView.fwTabComponentManager.tabTargetClass = resuableClass;
                reusableView.fwTabComponentManager.fileName = fileName;
                
                __weak typeof(reusableView) weakView = reusableView;
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (weakView && weakView.fwTabComponentManager) {
                        
                        BOOL isCell = NO;
                        if ([weakView isKindOfClass:[UICollectionReusableView class]]) {
                            isCell = YES;
                        }
                        
                        [FWTabManagerMethod runAnimationWithSuperView:collectionView
                                                         targetView:weakView
                                                             isCell:isCell
                                                            manager:weakView.fwTabComponentManager];
                    }
                });
            }
        }else {
            if (reusableView.fwTabComponentManager.tabLayer.hidden) {
                reusableView.fwTabComponentManager.tabLayer.hidden = NO;
            }
        }
        reusableView.fwTabComponentManager.currentRow = indexPath.row;
        
        return reusableView;
        
    }
    return [self tab_deda_collectionView:collectionView viewForSupplementaryElementOfKind:kind atIndexPath:indexPath];
}

@end

static NSString * const kShortDataString = @"tab_testtesttest";
static NSString * const kLongDataString = @"tab_testtesttesttesttesttesttesttesttesttesttest";

@implementation FWTabManagerMethod

+ (void)fullData:(UIView *)view {
    
    if ([view isKindOfClass:[UITableView class]] ||
        [view isKindOfClass:[UICollectionView class]]) {
        return;
    }
    
    NSArray *subViews = [view subviews];
    if ([subViews count] == 0) {
        return;
    }
    
    for (int i = 0; i < subViews.count;i++) {
        
        UIView *subV = subViews[i];
        [self fullData:subV];
        
        if ([subV isKindOfClass:[UITableView class]] ||
            [subV isKindOfClass:[UICollectionView class]]) {
            continue;
        }
        
        if ([subV isKindOfClass:[UILabel class]]) {
            UILabel *lab = (UILabel *)subV;
            if (lab.text == nil || [lab.text isEqualToString:@""]) {
                if (lab.numberOfLines == 1) {
                    lab.text = kShortDataString;
                }else {
                    lab.text = kLongDataString;
                }
            }
        }else {
            if ([subV isKindOfClass:[UIButton class]]) {
                UIButton *btn = (UIButton *)subV;
                if (btn.titleLabel.text == nil && btn.imageView.image == nil) {
                    [btn setTitle:kShortDataString forState:UIControlStateNormal];
                }
            }
        }
    }
}

+ (void)resetData:(UIView *)view {
    
    if ([view isKindOfClass:[UITableView class]] ||
        [view isKindOfClass:[UICollectionView class]]) {
        return;
    }
    
    NSArray *subViews = [view subviews];
    if ([subViews count] == 0) {
        return;
    }
    
    for (int i = 0; i < subViews.count;i++) {
        
        UIView *subV = subViews[i];
        [self resetData:subV];
        
        if ([subV isKindOfClass:[UILabel class]]) {
            UILabel *lab = (UILabel *)subV;
            if ([lab.text isEqualToString:kLongDataString] ||
                [lab.text isEqualToString:kShortDataString]) {
                lab.text = @"";
            }
        }else {
            if ([subV isKindOfClass:[UIButton class]]) {
                UIButton *btn = (UIButton *)subV;
                if ([btn.titleLabel.text isEqualToString:kLongDataString] ||
                    [btn.titleLabel.text isEqualToString:kShortDataString]) {
                    [btn setTitle:@"" forState:UIControlStateNormal];
                }
            }
        }
    }
}

+ (void)hiddenAllView:(UIView *)view {
    
    NSArray *subViews = [view subviews];
    if ([subViews count] == 0) {
        return;
    }
    
    for (int i = 0; i < subViews.count;i++) {
        
        UIView *subV = subViews[i];
        [self hiddenAllView:subV];
        
        if (CGSizeEqualToSize(subV.layer.shadowOffset, CGSizeMake(0, -3))) {
            subV.hidden = YES;
        }
    }
}

+ (void)getNeedAnimationSubViews:(UIView *)view
                   withSuperView:(UIView *)superView
                    withRootView:(UIView *)rootView
               withRootSuperView:(UIView *)rootSuperView
                    isInNestView:(BOOL)isInNestView
                           array:(NSMutableArray <FWTabComponentLayer *> *)array {
    
    NSArray *subViews = [view subviews];
    if ([subViews count] == 0) {
        return;
    }
    
    if (view.fwTabComponentManager == nil
        && rootSuperView.fwTabComponentManager &&
        ![view isKindOfClass:[UIButton class]]
        && ![view isKindOfClass:[UITableViewCell class]]
        && ![view isKindOfClass:[UICollectionViewCell class]]) {

        CALayer *layer = CALayer.new;
        layer.name = @"FWTabLayer";
        CGRect rect = [rootView convertRect:view.frame
                                   fromView:view.superview];
        layer.frame = rect;
        layer.backgroundColor = view.backgroundColor.CGColor;
        layer.shadowOffset = view.layer.shadowOffset;
        layer.shadowColor = view.layer.shadowColor;
        layer.shadowRadius = view.layer.shadowRadius;
        layer.shadowOpacity = view.layer.shadowOpacity;
        layer.cornerRadius = view.layer.cornerRadius;
        [rootSuperView.fwTabComponentManager.tabLayer addSublayer:layer];
    }
    
    for (int i = 0; i < subViews.count;i++) {
        
        UIView *subV = subViews[i];
        
        if (subV.fwTabAnimated.isNest &&
            ![subV isEqual:rootSuperView]) {
            
            if (rootSuperView.fwTabAnimated.targetControllerClassName) {
                subV.fwTabAnimated.targetControllerClassName = rootSuperView.fwTabAnimated.targetControllerClassName;
            }
            
            rootView.fwTabComponentManager.nestView = subV;
            
            CGRect cutRect = [rootView convertRect:subV.frame
                                          fromView:subV.superview];
            UIBezierPath *path = [UIBezierPath bezierPathWithRect:rootView.bounds];
            [path appendPath:[[UIBezierPath bezierPathWithRoundedRect:cutRect
                                                         cornerRadius:0.]bezierPathByReversingPath]];
            CAShapeLayer *shapeLayer = [CAShapeLayer layer];
            shapeLayer.path = path.CGPath;
            [rootView.fwTabComponentManager.tabLayer setMask:shapeLayer];
            
            isInNestView = YES;
        }
        
        [self getNeedAnimationSubViews:subV
                         withSuperView:subV.superview
                          withRootView:rootView
                     withRootSuperView:rootSuperView
                          isInNestView:isInNestView
                                 array:array];
        
        // 标记移除：生成动画对象，但是会被设置为移除状态
        BOOL needRemove = NO;
        
        // 分割线需要标记移除
        if ([subV isKindOfClass:[NSClassFromString(@"_UITableViewCellSeparatorView") class]] ||
            [subV isKindOfClass:[NSClassFromString(@"_UITableViewHeaderFooterContentView") class]] ||
            [subV isKindOfClass:[NSClassFromString(@"_UITableViewHeaderFooterViewBackground") class]]) {
            needRemove = YES;
        }
        
        // 通过过滤条件标记移除移除
        if (rootSuperView.fwTabAnimated.filterSubViewSize.width > 0) {
            if (subV.frame.size.width <= rootSuperView.fwTabAnimated.filterSubViewSize.width) {
                needRemove = YES;
            }
        }
        
        if (rootSuperView.fwTabAnimated.filterSubViewSize.height > 0) {
            if (subV.frame.size.height <= rootSuperView.fwTabAnimated.filterSubViewSize.height) {
                needRemove = YES;
            }
        }
        
        // 彻底移除：不生成动画对象
        // 移除默认的contentView
        if ([subV.superview isKindOfClass:[UITableViewCell class]] ||
            [subV.superview isKindOfClass:[UICollectionViewCell class]]) {
            if (i == 0) {
                continue;
            }
        }
        
        // 移除UITableView/UICollectionView的滚动条
        if ([view isKindOfClass:[UIScrollView class]]) {
            if (((subV.frame.size.height < 3.) || (subV.frame.size.width < 3.)) &&
                subV.alpha == 0.) {
                continue;
            }
        }
        
        if (isInNestView) {
            break;
        }
        
        if ([FWTabManagerMethod judgeViewIsNeedAddAnimation:subV]) {
            
            FWTabComponentLayer *layer = FWTabComponentLayer.new;
            
            if (needRemove) {
                layer.loadStyle = FWTabViewLoadAnimationRemove;
            }
            
            CGRect rect = [rootView convertRect:subV.frame fromView:subV.superview];
            layer.cornerRadius = subV.layer.cornerRadius;
            layer.frame = rect;
            
            if ([subV isKindOfClass:[UILabel class]]) {
                UILabel *lab = (UILabel *)subV;
                
                if (lab.textAlignment == NSTextAlignmentCenter) {
                    layer.fromCenterLabel = YES;
                }else {
                    layer.fromCenterLabel = NO;
                }
                
                if (lab.numberOfLines == 0 || lab.numberOfLines > 1) {
                    layer.numberOflines = lab.numberOfLines;
                }else {
                    layer.numberOflines = 1;
                }
            }else {
                layer.fromCenterLabel = NO;
                layer.numberOflines = 1;
            }
            
            if ([subV isKindOfClass:[UIImageView class]]) {
                layer.fromImageView = YES;
            }else {
                layer.fromImageView = NO;
            }
            
            [array addObject:layer];
        }
    }
}

+ (void)endAnimationToSubViews:(UIView *)view {
    
    NSArray *subViews = [view subviews];
    if ([subViews count] == 0) {
        return;
    }
    
    for (int i = 0; i < subViews.count;i++) {
        
        UIView *subV = subViews[i];
        [self endAnimationToSubViews:subV];
        
        if (subV.fwTabAnimated) {
            [subV fwTabEndAnimation];
        }
    }
}

+ (void)startAnimationToSubViews:(UIView *)view
                        rootView:(UIView *)rootView {
    
    NSArray *subViews = [view subviews];
    if ([subViews count] == 0) {
        return;
    }
    
    for (int i = 0; i < subViews.count;i++) {
        
        UIView *subV = subViews[i];
        [self startAnimationToSubViews:subV
                              rootView:rootView];
        
        if (subV.fwTabAnimated) {
            
            subV.fwTabAnimated.targetControllerClassName = rootView.fwTabAnimated.targetControllerClassName;
            
            dispatch_after(DISPATCH_TIME_NOW, dispatch_get_main_queue(), ^{
                CGRect cutRect = [rootView convertRect:subV.frame
                                              fromView:subV.superview];
                UIBezierPath *path = [UIBezierPath bezierPathWithRect:rootView.bounds];
                [path appendPath:[[UIBezierPath bezierPathWithRoundedRect:cutRect
                                                             cornerRadius:0.] bezierPathByReversingPath]];
                CAShapeLayer *shapeLayer = [CAShapeLayer layer];
                shapeLayer.path = path.CGPath;
                [rootView.fwTabComponentManager.tabLayer setMask:shapeLayer];
            });
        
            [subV fwTabStartAnimation];
        }
    }
}

+ (BOOL)judgeViewIsNeedAddAnimation:(UIView *)view {
    
    if ([view isKindOfClass:[UICollectionView class]] ||
        [view isKindOfClass:[UITableView class]]) {
        // 判断view为tableview/collectionview时，若有设置骨架动画，则返回NO；否则返回YES，允许设置绘制骨架图
        if (view.fwTabAnimated) {
            return NO;
        }else {
            return YES;
        }
        return NO;
    }
    
    // 将UIButton中的UILabel移除动画队列
    if ([view.superview isKindOfClass:[UIButton class]]) {
        return NO;
    }
    
    if ([view isKindOfClass:[UIButton class]]) {
        // UIButtonLabel has one subLayer.
        if (view.layer.sublayers.count >= 1) {
            return YES;
        }else {
            return NO;
        }
    }else {
        
        if (view.layer.sublayers.count == 0) {
            return YES;
        }else {
            if ([view isKindOfClass:[UILabel class]] ||
                [view isKindOfClass:[UIImageView class]]) {
                return YES;
            }else {
                if ([view isKindOfClass:[UIView class]] && !CGSizeEqualToSize(view.layer.shadowOffset, CGSizeMake(0, -3))) {
                    return YES;
                }
            }
            return NO;
        }
    }
}

+ (void)runAnimationWithSuperView:(UIView *)superView
                       targetView:(UIView *)targetView
                           isCell:(BOOL)isCell
                          manager:(FWTabComponentManager *)manager {
    
    if (superView.fwTabAnimated.state == FWTabViewAnimationStart &&
        !targetView.fwTabComponentManager.isLoad) {
        
        NSMutableArray <FWTabComponentLayer *> *array = @[].mutableCopy;
        // start animations
        [FWTabManagerMethod getNeedAnimationSubViews:targetView
                                     withSuperView:superView
                                      withRootView:targetView
                                 withRootSuperView:superView
                                      isInNestView:NO
                                             array:array];
        
        [targetView.fwTabComponentManager installBaseComponentArray:array.copy];
        
        if (targetView.fwTabComponentManager.baseComponentArray.count != 0) {
            __weak typeof(targetView) weakSelf = targetView;
            
            if (superView.fwTabAnimated.adjustBlock) {
                superView.fwTabAnimated.adjustBlock(weakSelf.fwTabComponentManager);
            }
            
            if (superView.fwTabAnimated.adjustWithClassBlock) {
                superView.fwTabAnimated.adjustWithClassBlock(weakSelf.fwTabComponentManager, weakSelf.fwTabComponentManager.tabTargetClass);
            }
        }
        
        [targetView.fwTabComponentManager updateComponentLayers];
        
        [FWTabManagerMethod addExtraAnimationWithSuperView:superView
                                              targetView:targetView
                                                 manager:targetView.fwTabComponentManager];
        
        if (isCell && !targetView.fwTabComponentManager.nestView) {
            [FWTabManagerMethod hiddenAllView:targetView];
        }else {
            [FWTabManagerMethod resetData:targetView];
        }
        targetView.fwTabComponentManager.isLoad = YES;
        
        if (targetView.fwTabComponentManager.nestView) {
            [targetView.fwTabComponentManager.nestView fwTabStartAnimation];
        }
        
        [[FWTabAnimated sharedAnimated].cacheManager cacheComponentManager:targetView.fwTabComponentManager];
    }

    // 结束动画
    if (superView.fwTabAnimated.state == FWTabViewAnimationEnd) {
        [FWTabManagerMethod endAnimationToSubViews:targetView];
        [FWTabManagerMethod removeMask:targetView];
    }
}

+ (void)addExtraAnimationWithSuperView:(UIView *)superView
                            targetView:(UIView *)targetView
                               manager:(FWTabComponentManager *)manager {
    // add shimmer animation
    if ([FWTabManagerMethod canAddShimmer:superView]) {
        
        for (NSInteger i = 0; i < manager.resultLayerArray.count; i++) {
            FWTabComponentLayer *layer = manager.resultLayerArray[i];
            
            UIColor *baseColor;
            CGFloat brigtness;
            
            if (@available(iOS 13.0, *)) {
                if (superView.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                    baseColor = [FWTabAnimated sharedAnimated].shimmerBackColorInDarkMode;
                    brigtness = [FWTabAnimated sharedAnimated].shimmerBrightnessInDarkMode;
                }else {
                    baseColor = [FWTabAnimated sharedAnimated].shimmerBackColor;
                    brigtness = [FWTabAnimated sharedAnimated].shimmerBrightness;
                }
            } else {
                baseColor = [FWTabAnimated sharedAnimated].shimmerBackColor;
                brigtness = [FWTabAnimated sharedAnimated].shimmerBrightness;
            }
            
            if (baseColor == nil) {
                return;
            }
            
            layer.colors = @[
                             (id)baseColor.CGColor,
                             (id)[FWTabManagerMethod brightenedColor:baseColor brightness:brigtness].CGColor,
                             (id)baseColor.CGColor
                             ];
            
            [FWTabAnimationMethod addShimmerAnimationToLayer:layer
                                                  duration:[FWTabAnimated sharedAnimated].animatedDurationShimmer
                                                       key:FWTabAnimatedShimmerAnimation
                                                 direction:[FWTabAnimated sharedAnimated].shimmerDirection];
            
        }
    }
    
    if (!superView.fwTabAnimated.isNest) {
        
        // add bin animation
        if ([FWTabManagerMethod canAddBinAnimation:superView]) {
            [FWTabAnimationMethod addAlphaAnimation:targetView
                                         duration:[FWTabAnimated sharedAnimated].animatedDurationBin
                                              key:FWTabAnimatedAlphaAnimation];
        }
        
        // add drop animation
        if ([FWTabManagerMethod canAddDropAnimation:superView]) {
            
            UIColor *deepColor;
            
            if (@available(iOS 13.0, *)) {
                if (superView.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                    
                    if (superView.fwTabAnimated.dropAnimationDeepColorInDarkMode) {
                        deepColor = superView.fwTabAnimated.dropAnimationDeepColorInDarkMode;
                    }else {
                        deepColor = [FWTabAnimated sharedAnimated].dropAnimationDeepColorInDarkMode;
                    }
                }else {
                    if (superView.fwTabAnimated.dropAnimationDeepColor) {
                        deepColor = superView.fwTabAnimated.dropAnimationDeepColor;
                    }else {
                        deepColor = [FWTabAnimated sharedAnimated].dropAnimationDeepColor;
                    }
                }
            } else {
                if (superView.fwTabAnimated.dropAnimationDeepColor) {
                    deepColor = superView.fwTabAnimated.dropAnimationDeepColor;
                }else {
                    deepColor = [FWTabAnimated sharedAnimated].dropAnimationDeepColor;
                }
            }
            
            if (deepColor == nil) {
                return;
            }
            
            CGFloat duration = 0;
            CGFloat cutTime = 0.02;
            CGFloat allCutTime = cutTime*(manager.resultLayerArray.count-1)*(manager.resultLayerArray.count)/2.0;
            if (superView.fwTabAnimated.dropAnimationDuration != 0.) {
                duration = superView.fwTabAnimated.dropAnimationDuration;
            }else {
                duration = [FWTabAnimated sharedAnimated].dropAnimationDuration;
            }
            
            for (NSInteger i = 0; i < manager.resultLayerArray.count; i++) {
                FWTabComponentLayer *layer = manager.resultLayerArray[i];
                if (layer.removeOnDropAnimation) {
                    continue;
                }
                [FWTabAnimationMethod addDropAnimation:layer
                                               index:layer.dropAnimationIndex
                                            duration:duration*(manager.dropAnimationCount+1)-allCutTime
                 
                                               count:manager.dropAnimationCount+1
                                            stayTime:layer.dropAnimationStayTime-i*cutTime
                                           deepColor:deepColor
                                                 key:FWTabAnimatedDropAnimation];
            }
        }
        
    }
}

+ (BOOL)canAddShimmer:(UIView *)view {
    
    if (view.fwTabAnimated.superAnimationType == FWTabViewSuperAnimationTypeShimmer) {
        return YES;
    }
    
    if ([FWTabAnimated sharedAnimated].animationType == FWTabAnimationTypeShimmer &&
        view.fwTabAnimated.superAnimationType == FWTabViewSuperAnimationTypeDefault) {
        return YES;
    }
    
    return NO;
}

+ (BOOL)canAddBinAnimation:(UIView *)view {
    
    if (view.fwTabAnimated.superAnimationType == FWTabViewSuperAnimationTypeBinAnimation) {
        return YES;
    }
    
    if ([FWTabAnimated sharedAnimated].animationType == FWTabAnimationTypeBinAnimation &&
        view.fwTabAnimated.superAnimationType == FWTabViewSuperAnimationTypeDefault) {
        return YES;
    }
    
    return NO;
}

+ (BOOL)canAddDropAnimation:(UIView *)view {
    
    if (view.fwTabAnimated.superAnimationType == FWTabViewSuperAnimationTypeDrop) {
        return YES;
    }
    
    if ([FWTabAnimated sharedAnimated].animationType == FWTabAnimationTypeDrop &&
        view.fwTabAnimated.superAnimationType == FWTabViewSuperAnimationTypeDefault) {
        return YES;
    }
    
    return NO;
}

+ (void)removeAllFWTabLayersFromView:(UIView *)view {
    
    NSArray *subViews = [view subviews];
    if ([subViews count] == 0) {
        return;
    }
    
    for (int i = 0; i < subViews.count; i++) {
        
        UIView *v = subViews[i];
        [self removeAllFWTabLayersFromView:v];
        
        if (v.layer.sublayers.count > 0) {
            NSArray<CALayer *> *subLayers = v.layer.sublayers;
            [self removeSubLayers:subLayers];
        }
    }
    
    [self removeMask:view];
}

+ (void)removeMask:(UIView *)view {
    if (view.fwTabComponentManager.tabLayer) {
        view.fwTabComponentManager.tabLayer.hidden = YES;
    }
}

+ (void)removeSubLayers:(NSArray *)subLayers {
    
    NSArray <CALayer *> *removedLayers = [subLayers filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return YES;
    }]];
    
    [removedLayers enumerateObjectsUsingBlock:^(CALayer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperlayer];
    }];
}

#pragma mark - Private Method

/**
 改变UIColor的亮度
 
 @param color 目标颜色
 @param brightness 亮度
 @return 改变亮度后颜色
 */
+ (UIColor *)brightenedColor:(UIColor *)color
                  brightness:(CGFloat)brightness {
    CGFloat h,s,b,a;
    [color getHue:&h saturation:&s brightness:&b alpha:&a];
    return [UIColor colorWithHue:h saturation:s brightness:b*brightness alpha:a];
}

@end

@implementation FWTabSentryView

- (instancetype)init {
    if (self = [super init]) {
        self.frame = CGRectMake(0, 0, .1, .1);
        self.backgroundColor = UIColor.clearColor;
    }
    return self;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if (self.traitCollectionDidChangeBack) {
        self.traitCollectionDidChangeBack();
    }
}

@end

const NSInteger FWTabViewAnimatedErrorCode = -1000;

NSString * const FWTabViewAnimatedHeaderPrefixString = @"tab_header_";
NSString * const FWTabViewAnimatedFooterPrefixString = @"tab_footer_";
NSString * const FWTabViewAnimatedDefaultSuffixString = @"default_resuable_view";

@implementation FWTabViewAnimated

- (instancetype)init {
    if (self = [super init]) {
        _animatedCountArray = @[].mutableCopy;
        _cellClassArray = @[].mutableCopy;
        _superAnimationType = FWTabViewSuperAnimationTypeDefault;
        _dropAnimationDuration = 0;
        _filterSubViewSize = CGSizeZero;
    }
    return self;
}

- (BOOL)currentIndexIsAnimatingWithIndex:(NSInteger)index {
    return YES;
}

- (UIColor *)animatedColor {
    if (_animatedColor) {
        return _animatedColor;
    }
    return [FWTabAnimated sharedAnimated].animatedColor;
}

- (UIColor *)animatedBackgroundColor {
    if (_animatedBackgroundColor) {
        return _animatedBackgroundColor;
    }
    return [FWTabAnimated sharedAnimated].animatedBackgroundColor;
}

- (UIColor *)darkAnimatedColor {
    if (_darkAnimatedColor) {
        return _darkAnimatedColor;
    }
    return [FWTabAnimated sharedAnimated].darkAnimatedColor;
}

- (UIColor *)darkAnimatedBackgroundColor {
    if (_darkAnimatedBackgroundColor) {
        return _darkAnimatedBackgroundColor;
    }
    return [FWTabAnimated sharedAnimated].darkAnimatedBackgroundColor;
}

@end

@interface FWTabTableAnimated()

@property (nonatomic, strong, readwrite) NSMutableArray <Class> *headerClassArray;
@property (nonatomic, strong, readwrite) NSMutableArray <NSNumber *> *headerHeightArray;
@property (nonatomic, strong, readwrite) NSMutableArray <NSNumber *> *headerSectionArray;

@property (nonatomic, strong, readwrite) NSMutableArray <Class> *footerClassArray;
@property (nonatomic, strong, readwrite) NSMutableArray <NSNumber *> *footerHeightArray;
@property (nonatomic, strong, readwrite) NSMutableArray <NSNumber *> *footerSectionArray;

@property (nonatomic, assign, readwrite) BOOL isExhangeDelegateIMP;
@property (nonatomic, assign, readwrite) BOOL isExhangeDataSourceIMP;

@property (nonatomic, assign, readwrite) FWTabAnimatedRunMode runMode;

@end

@implementation FWTabTableAnimated

+ (instancetype)animatedWithCellClass:(Class)cellClass
                           cellHeight:(CGFloat)cellHeight {
    FWTabTableAnimated *obj = [[FWTabTableAnimated alloc] init];
    obj.cellClassArray = @[cellClass];
    obj.cellHeight = cellHeight;
    obj.animatedCount = ceilf([UIScreen mainScreen].bounds.size.height/cellHeight*1.0);
    return obj;
}

+ (instancetype)animatedWithCellClass:(Class)cellClass
                           cellHeight:(CGFloat)cellHeight
                        animatedCount:(NSInteger)animatedCount {
    FWTabTableAnimated *obj = [self animatedWithCellClass:cellClass cellHeight:cellHeight];
    obj.animatedCount = animatedCount;
    return obj;
}

+ (instancetype)animatedWithCellClass:(Class)cellClass
                           cellHeight:(CGFloat)cellHeight
                            toSection:(NSInteger)section {
    FWTabTableAnimated *obj = [self animatedWithCellClass:cellClass cellHeight:cellHeight];
    obj.animatedCountArray = @[@(ceilf([UIScreen mainScreen].bounds.size.height/cellHeight*1.0))];
    obj.animatedIndexArray = @[@(section)];
    return obj;
}

+ (instancetype)animatedWithCellClass:(Class)cellClass
                           cellHeight:(CGFloat)cellHeight
                        animatedCount:(NSInteger)animatedCount
                            toSection:(NSInteger)section {
    FWTabTableAnimated *obj = [self animatedWithCellClass:cellClass cellHeight:cellHeight];
    obj.animatedCountArray = @[@(animatedCount)];
    obj.animatedIndexArray = @[@(section)];
    return obj;
}

+ (instancetype)animatedWithCellClassArray:(NSArray<Class> *)cellClassArray
                           cellHeightArray:(NSArray<NSNumber *> *)cellHeightArray
                        animatedCountArray:(NSArray<NSNumber *> *)animatedCountArray {
    FWTabTableAnimated *obj = [[FWTabTableAnimated alloc] init];
    obj.animatedCountArray = animatedCountArray;
    obj.cellHeightArray = cellHeightArray;
    obj.cellClassArray = cellClassArray;
    return obj;
}

+ (instancetype)animatedWithCellClassArray:(NSArray <Class> *)cellClassArray
                           cellHeightArray:(NSArray <NSNumber *> *)cellHeightArray
                        animatedCountArray:(NSArray <NSNumber *> *)animatedCountArray
                      animatedSectionArray:(NSArray <NSNumber *> *)animatedSectionArray {
    FWTabTableAnimated *obj = [self animatedWithCellClassArray:cellClassArray
                                             cellHeightArray:cellHeightArray
                                          animatedCountArray:animatedCountArray];
    obj.animatedIndexArray = animatedSectionArray;
    return obj;
}

#pragma mark -

+ (instancetype)animatedInRowModeWithCellClassArray:(NSArray <Class> *)cellClassArray
                                    cellHeightArray:(NSArray <NSNumber *> *)cellHeightArray {
    FWTabTableAnimated *obj = [[FWTabTableAnimated alloc] init];
    obj.cellHeightArray = cellHeightArray;
    obj.cellClassArray = cellClassArray;
    obj.runMode = FWTabAnimatedRunByRow;
    return obj;
}

+ (instancetype)animatedInRowModeWithCellClassArray:(NSArray <Class> *)cellClassArray
                                    cellHeightArray:(NSArray <NSNumber *> *)cellHeightArray
                                           rowArray:(NSArray <NSNumber *> *)rowArray {
    FWTabTableAnimated *obj = [FWTabTableAnimated animatedInRowModeWithCellClassArray:cellClassArray
                                                                  cellHeightArray:cellHeightArray];
    obj.animatedIndexArray = rowArray;
    return obj;
}

+ (instancetype)animatedInRowModeWithCellClass:(Class)cellClass
                                    cellHeight:(CGFloat)cellHeight
                                         toRow:(NSInteger)row {
    FWTabTableAnimated *obj = [self animatedWithCellClass:cellClass
                                             cellHeight:cellHeight];
    obj.runMode = FWTabAnimatedRunByRow;
    obj.animatedCountArray = @[@(1)];
    obj.animatedIndexArray = @[@(row)];
    return obj;
}

#pragma mark - 自适应高度

+ (instancetype)animatedWithCellClass:(Class)cellClass {
    FWTabTableAnimated *obj = [[FWTabTableAnimated alloc] init];
    obj.cellClassArray = @[cellClass];
    return obj;
}

- (instancetype)init {
    if (self = [super init]) {
        _runAnimationIndexArray = @[].mutableCopy;
        _animatedSectionCount = 0;
        _animatedCount = 1;
        
        _headerClassArray = @[].mutableCopy;
        _headerHeightArray = @[].mutableCopy;
        _headerSectionArray = @[].mutableCopy;
        
        _footerClassArray = @[].mutableCopy;
        _footerHeightArray = @[].mutableCopy;
        _footerSectionArray = @[].mutableCopy;
    }
    return self;
}

#pragma mark - Public Method

- (void)addHeaderViewClass:(__nonnull Class)headerViewClass
                viewHeight:(CGFloat)viewHeight
                 toSection:(NSInteger)section {
    BOOL isAdd = false;
    for (int i = 0; i < _headerSectionArray.count; i++) {
        NSInteger oldSection = [_headerSectionArray[i] integerValue];
        if (oldSection == section) {
            isAdd = YES;
            [_headerClassArray replaceObjectAtIndex:i withObject:headerViewClass];
            [_headerHeightArray replaceObjectAtIndex:i withObject:@(viewHeight)];
            [_headerSectionArray replaceObjectAtIndex:i withObject:@(section)];
        }
    }
    
    if (!isAdd) {
        [_headerClassArray addObject:headerViewClass];
        [_headerHeightArray addObject:@(viewHeight)];
        [_headerSectionArray addObject:@(section)];
    }
}

- (void)addHeaderViewClass:(__nonnull Class)headerViewClass
                viewHeight:(CGFloat)viewHeight {
    [_headerClassArray addObject:headerViewClass];
    [_headerHeightArray addObject:@(viewHeight)];
}

- (void)addFooterViewClass:(__nonnull Class)footerViewClass
                viewHeight:(CGFloat)viewHeight
                 toSection:(NSInteger)section {
    BOOL isAdd = false;
    for (int i = 0; i < _footerSectionArray.count; i++) {
        NSInteger oldSection = [_footerSectionArray[i] integerValue];
        if (oldSection == section) {
            isAdd = YES;
            [_footerClassArray replaceObjectAtIndex:i withObject:footerViewClass];
            [_footerHeightArray replaceObjectAtIndex:i withObject:@(viewHeight)];
            [_footerSectionArray replaceObjectAtIndex:i withObject:@(section)];
        }
    }
    
    if (!isAdd) {
        [_footerClassArray addObject:footerViewClass];
        [_footerHeightArray addObject:@(viewHeight)];
        [_footerSectionArray addObject:@(section)];
    }
}

- (void)addFooterViewClass:(__nonnull Class)footerViewClass
                viewHeight:(CGFloat)viewHeight {
    [_footerClassArray addObject:footerViewClass];
    [_footerHeightArray addObject:@(viewHeight)];
}

#pragma mark -

- (void)setCellHeight:(CGFloat)cellHeight {
    _cellHeight = cellHeight;
    _cellHeightArray = @[[NSNumber numberWithFloat:cellHeight]];
}

- (BOOL)currentIndexIsAnimatingWithIndex:(NSInteger)index {
    for (NSNumber *num in self.runAnimationIndexArray) {
        if ([num integerValue] == index) {
            return YES;
        }
    }
    return NO;
}

- (NSInteger)headerNeedAnimationOnSection:(NSInteger)section {
    
    if (self.headerSectionArray.count == 0) {
        return FWTabViewAnimatedErrorCode;
    }
    
    for (NSInteger i = 0; i < self.headerSectionArray.count; i++) {
        NSNumber *num = self.headerSectionArray[i];
        if ([num integerValue] == section) {
            return i;
        }
    }
    
    return FWTabViewAnimatedErrorCode;
}

- (NSInteger)footerNeedAnimationOnSection:(NSInteger)section {
    
    if (self.footerSectionArray.count == 0) {
        return FWTabViewAnimatedErrorCode;
    }
    
    for (NSInteger i = 0; i < self.footerSectionArray.count; i++) {
        NSNumber *num = self.footerSectionArray[i];
        if ([num integerValue] == section) {
            return i;
        }
    }
    
    return FWTabViewAnimatedErrorCode;
}

- (void)exchangeTableViewDelegate:(UITableView *)target {
    if (!_isExhangeDelegateIMP) {
        _isExhangeDelegateIMP = YES;
        id <UITableViewDelegate> delegate = target.delegate;
        
        if ([target isEqual:delegate]) {
            
            FWTabTableDeDaSelfModel *model = [[FWTabAnimated sharedAnimated] getTableDeDaModelAboutDeDaSelfWithClassName:NSStringFromClass(delegate.class)];
            if (!model.isExhangeDelegate) {
                [self exchangeDelegateMethods:delegate
                                       target:target
                                        model:model];
                model.isExhangeDelegate = YES;
            }
            
        }else {
            [self exchangeDelegateMethods:delegate
                                   target:target
                                    model:nil];
        }
    }
}

- (void)exchangeTableViewDataSource:(UITableView *)target {
    if (!_isExhangeDataSourceIMP) {
        
        _isExhangeDataSourceIMP = YES;
        
        id <UITableViewDataSource> dataSource = target.dataSource;
        
        if ([target isEqual:dataSource]) {
            FWTabTableDeDaSelfModel *model = [[FWTabAnimated sharedAnimated] getTableDeDaModelAboutDeDaSelfWithClassName:NSStringFromClass(dataSource.class)];
            if (!model.isExhangeDataSource) {
                [self exchangeDataSourceMethods:dataSource
                                         target:target
                                          model:model];
                model.isExhangeDataSource = YES;
            }
        }else {
            [self exchangeDataSourceMethods:dataSource
                                     target:target
                                      model:nil];
        }
    }
}

#pragma mark - Private Methods

- (void)exchangeDelegateMethods:(id<UITableViewDelegate>)delegate
                         target:(id)target
                          model:(FWTabTableDeDaSelfModel *)model {
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    SEL oldClickDelegate = @selector(tableView:didSelectRowAtIndexPath:);
    SEL newClickDelegate;
    if (model) {
        newClickDelegate = @selector(tab_deda_tableView:didSelectRowAtIndexPath:);
    }else {
        newClickDelegate = @selector(tab_tableView:didSelectRowAtIndexPath:);
    }
    [self exchangeDelegateOldSel:oldClickDelegate
                      withNewSel:newClickDelegate
                      withTarget:target
                    withDelegate:delegate
                           model:model];
    
    SEL oldHeightDelegate = @selector(tableView:heightForRowAtIndexPath:);
    SEL newHeightDelegate;
    if (model) {
        newHeightDelegate = @selector(tab_deda_tableView:heightForRowAtIndexPath:);
    }else {
        newHeightDelegate = @selector(tab_tableView:heightForRowAtIndexPath:);
    }
    
    SEL estimatedHeightDelegateSel = @selector(tableView:estimatedHeightForRowAtIndexPath:);
    
    if ([delegate respondsToSelector:estimatedHeightDelegateSel] &&
        ![delegate respondsToSelector:oldHeightDelegate]) {
        FWTabEstimatedTableViewDelegate *edelegate = FWTabEstimatedTableViewDelegate.new;
        Method method = class_getInstanceMethod([edelegate class], oldHeightDelegate);
        BOOL isVictory = class_addMethod([delegate class], oldHeightDelegate, class_getMethodImplementation([edelegate class], oldHeightDelegate), method_getTypeEncoding(method));
        if (isVictory) {
            [self exchangeDelegateOldSel:oldHeightDelegate
                              withNewSel:newHeightDelegate
                              withTarget:target
                            withDelegate:delegate
                                   model:model];
        }
        ((UITableView *)target).delegate = delegate;
    }else {
        [self exchangeDelegateOldSel:oldHeightDelegate
                          withNewSel:newHeightDelegate
                          withTarget:target
                        withDelegate:delegate
                               model:model];
    }
    
    SEL oldHeadViewDelegate = @selector(tableView:viewForHeaderInSection:);
    SEL newHeadViewDelegate;
    if (model) {
        newHeadViewDelegate= @selector(tab_deda_tableView:viewForHeaderInSection:);
    }else {
        newHeadViewDelegate= @selector(tab_tableView:viewForHeaderInSection:);
    }
    [self exchangeDelegateOldSel:oldHeadViewDelegate
                      withNewSel:newHeadViewDelegate
                      withTarget:target
                    withDelegate:delegate
                           model:model];
    
    SEL oldFooterViewDelegate = @selector(tableView:viewForFooterInSection:);
    SEL newFooterViewDelegate;
    if (model) {
        newFooterViewDelegate = @selector(tab_deda_tableView:viewForFooterInSection:);
    }else {
        newFooterViewDelegate = @selector(tab_tableView:viewForFooterInSection:);
    }
    [self exchangeDelegateOldSel:oldFooterViewDelegate
                      withNewSel:newFooterViewDelegate
                      withTarget:target
                    withDelegate:delegate
                           model:model];
    
    SEL oldHeadHeightDelegate = @selector(tableView:heightForHeaderInSection:);
    SEL newHeadHeightDelegate;
    if (model) {
        newHeadHeightDelegate = @selector(tab_deda_tableView:heightForHeaderInSection:);
    }else {
        newHeadHeightDelegate = @selector(tab_tableView:heightForHeaderInSection:);
    }
    [self exchangeDelegateOldSel:oldHeadHeightDelegate
                      withNewSel:newHeadHeightDelegate
                      withTarget:target
                    withDelegate:delegate
                           model:model];
    
    SEL oldFooterHeightDelegate = @selector(tableView:heightForFooterInSection:);
    SEL newFooterHeightDelegate;
    if (model) {
        newFooterHeightDelegate = @selector(tab_deda_tableView:heightForFooterInSection:);
    }else {
        newFooterHeightDelegate = @selector(tab_tableView:heightForFooterInSection:);
    }
    [self exchangeDelegateOldSel:oldFooterHeightDelegate
                      withNewSel:newFooterHeightDelegate
                      withTarget:target
                    withDelegate:delegate
                           model:model];
#pragma clang diagnostic pop
}

- (void)exchangeDataSourceMethods:(id<UITableViewDataSource>)dataSource
                           target:(id)target
                            model:(FWTabTableDeDaSelfModel *)model {
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    
    SEL oldSectionSelector = @selector(numberOfSectionsInTableView:);
    SEL newSectionSelector;
    if (model) {
        newSectionSelector = @selector(tab_deda_numberOfSectionsInTableView:);
    }else {
        newSectionSelector = @selector(tab_numberOfSectionsInTableView:);
    }
    
    SEL oldSelector = @selector(tableView:numberOfRowsInSection:);
    SEL newSelector;
    if (model) {
        newSelector = @selector(tab_deda_tableView:numberOfRowsInSection:);
    }else {
        newSelector = @selector(tab_tableView:numberOfRowsInSection:);
    }
    
    SEL oldCell = @selector(tableView:cellForRowAtIndexPath:);
    SEL newCell;
    if (model) {
        newCell = @selector(tab_deda_tableView:cellForRowAtIndexPath:);
    }else {
        newCell = @selector(tab_tableView:cellForRowAtIndexPath:);
    }
    
    SEL old = @selector(tableView:willDisplayCell:forRowAtIndexPath:);
    SEL new;
    if (model) {
        new = @selector(tab_deda_tableView:willDisplayCell:forRowAtIndexPath:);
    }else {
        new = @selector(tab_tableView:willDisplayCell:forRowAtIndexPath:);
    }
#pragma clang diagnostic pop
    
    [self exchangeDelegateOldSel:oldSectionSelector
                      withNewSel:newSectionSelector
                      withTarget:target
                    withDelegate:dataSource
                           model:model];
    
    [self exchangeDelegateOldSel:oldSelector
                      withNewSel:newSelector
                      withTarget:target
                    withDelegate:dataSource
                           model:model];
    
    [self exchangeDelegateOldSel:old
                      withNewSel:new
                      withTarget:target
                    withDelegate:dataSource
                           model:model];
    
    [self exchangeDelegateOldSel:oldCell
                      withNewSel:newCell
                      withTarget:target
                    withDelegate:dataSource
                           model:model];
}

/**
 exchange method
 
 @param oldSelector old method's sel
 @param newSelector new method's sel
 @param delegate return nil
 */
- (void)exchangeDelegateOldSel:(SEL)oldSelector
                    withNewSel:(SEL)newSelector
                    withTarget:(id)target
                  withDelegate:(id)delegate
                         model:(FWTabTableDeDaSelfModel *)model {
    
    if (![delegate respondsToSelector:oldSelector]) {
        return;
    }
    
    Class targetClass;
    if (model) {
        targetClass = [model class];
    }else {
        targetClass = [self class];
    }
    
    Method newMethod = class_getInstanceMethod(targetClass, newSelector);
    if (newMethod == nil) {
        return;
    }
    
    Method oldMethod = class_getInstanceMethod([delegate class], oldSelector);
    
    BOOL isVictory = class_addMethod([delegate class], newSelector, class_getMethodImplementation([delegate class], oldSelector), method_getTypeEncoding(oldMethod));
    
    if (isVictory) {
        class_replaceMethod([delegate class], oldSelector, class_getMethodImplementation(targetClass, newSelector), method_getTypeEncoding(newMethod));
    }
}

#pragma mark - FWTabTableViewDataSource / Delegate

- (NSInteger)tab_numberOfSectionsInTableView:(UITableView *)tableView {
    
    if (tableView.fwTabAnimated.state == FWTabViewAnimationStart) {
        
        if (tableView.fwTabAnimated.animatedSectionCount != 0) {
            return tableView.fwTabAnimated.animatedSectionCount;
        }

        NSInteger count = [self tab_numberOfSectionsInTableView:tableView];
        if (count == 0) {
            count = tableView.fwTabAnimated.cellClassArray.count;
        }

        if (count == 0) return 1;
        
        return count;
    }
    
    return [self tab_numberOfSectionsInTableView:tableView];
}

- (NSInteger)tab_tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (tableView.fwTabAnimated.runMode == FWTabAnimatedRunByRow) {
        NSInteger count = [self tab_tableView:tableView numberOfRowsInSection:section];
        if (count == 0) {
            return tableView.fwTabAnimated.cellClassArray.count;
        }
        return count;
    }
    
    // If the animation running, return animatedCount.
    if ([tableView.fwTabAnimated currentIndexIsAnimatingWithIndex:section]) {
        
        // 开发者指定section/row
        if (tableView.fwTabAnimated.animatedIndexArray.count > 0) {
            
            // 没有获取到动画时row数量
            if (tableView.fwTabAnimated.animatedCountArray.count == 0) {
                return 0;
            }
            
            // 匹配当前section
            for (NSNumber *num in tableView.fwTabAnimated.animatedIndexArray) {
                if ([num integerValue] == section) {
                    NSInteger index = [tableView.fwTabAnimated.animatedIndexArray indexOfObject:num];
                    if (index > tableView.fwTabAnimated.animatedCountArray.count - 1) {
                        return [[tableView.fwTabAnimated.animatedCountArray lastObject] integerValue];
                    }else {
                        return [tableView.fwTabAnimated.animatedCountArray[index] integerValue];
                    }
                }
                
                // 没有匹配到指定的数量
                if ([num isEqual:[tableView.fwTabAnimated.animatedIndexArray lastObject]]) {
                    return 0;
                }
            }
        }
        
        if (tableView.fwTabAnimated.animatedCountArray.count > 0) {
            if (section > tableView.fwTabAnimated.animatedCountArray.count - 1) {
                return tableView.fwTabAnimated.animatedCount;
            }
            return [tableView.fwTabAnimated.animatedCountArray[section] integerValue];
        }
        return tableView.fwTabAnimated.animatedCount;
    }
    return [self tab_tableView:tableView numberOfRowsInSection:section];
}

- (CGFloat)tab_tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger index;
    switch (tableView.fwTabAnimated.runMode) {
        case FWTabAnimatedRunBySection: {
            index = indexPath.section;
        }
            break;
        case FWTabAnimatedRunByRow: {
            index = indexPath.row;
        }
            break;
    }
    
    if ([tableView.fwTabAnimated currentIndexIsAnimatingWithIndex:index]) {
        
        // 开发者指定section
        if (tableView.fwTabAnimated.animatedIndexArray.count > 0) {
            
            // 匹配当前section
            for (NSNumber *num in tableView.fwTabAnimated.animatedIndexArray) {
                if ([num integerValue] == index) {
                    NSInteger currentIndex = [tableView.fwTabAnimated.animatedIndexArray indexOfObject:num];
                    if (currentIndex > tableView.fwTabAnimated.cellHeightArray.count - 1) {
                        index = [tableView.fwTabAnimated.cellHeightArray count] - 1;
                    }else {
                        index = currentIndex;
                    }
                    break;
                }
                
                // 没有匹配到注册的cell
                if ([num isEqual:[tableView.fwTabAnimated.animatedIndexArray lastObject]]) {
                    return 1.;
                }
            }
        }else {
            if (index > (tableView.fwTabAnimated.cellClassArray.count - 1)) {
                index = tableView.fwTabAnimated.cellClassArray.count - 1;
                tabAnimatedLog(@"FWTabAnimated提醒 - section的数量和指定分区的数量不一致，超出的section，将使用最后一个分区cell加载");
            }
        }
        
        return [tableView.fwTabAnimated.cellHeightArray[index] floatValue];
    }
    return [self tab_tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (UITableViewCell *)tab_tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger index;
    switch (tableView.fwTabAnimated.runMode) {
        case FWTabAnimatedRunBySection: {
            index = indexPath.section;
        }
            break;
        case FWTabAnimatedRunByRow: {
            index = indexPath.row;
        }
            break;
    }
    
    if ([tableView.fwTabAnimated currentIndexIsAnimatingWithIndex:index]) {
        
        // 开发者指定index
        if (tableView.fwTabAnimated.animatedIndexArray.count > 0) {
            
            if (tableView.fwTabAnimated.cellClassArray.count == 0) {
                return UITableViewCell.new;
            }
            
            // 匹配当前section
            for (NSNumber *num in tableView.fwTabAnimated.animatedIndexArray) {
                if ([num integerValue] == index) {
                    NSInteger currentIndex = [tableView.fwTabAnimated.animatedIndexArray indexOfObject:num];
                    if (currentIndex > tableView.fwTabAnimated.cellClassArray.count - 1) {
                        index = [tableView.fwTabAnimated.cellClassArray count] - 1;
                    }else {
                        index = currentIndex;
                    }
                    break;
                }
                
                if ([num isEqual:[tableView.fwTabAnimated.animatedIndexArray lastObject]]) {
                    return UITableViewCell.new;
                }
            }
        }else {
            if (index > (tableView.fwTabAnimated.cellClassArray.count - 1)) {
                index = tableView.fwTabAnimated.cellClassArray.count - 1;
                tabAnimatedLog(@"FWTabAnimated - section的数量和指定分区的数量不一致，超出的section，将使用最后一个分区cell加载");
            }
        }
        
        Class currentClass = tableView.fwTabAnimated.cellClassArray[index];
        NSString *className = NSStringFromClass(currentClass);
        if ([className containsString:@"."]) {
            NSRange range = [className rangeOfString:@"."];
            className = [className substringFromIndex:range.location+1];
        }
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[NSString stringWithFormat:@"tab_%@",className] forIndexPath:indexPath];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        NSString *fileName = [className stringByAppendingString:[NSString stringWithFormat:@"_%@",tableView.fwTabAnimated.targetControllerClassName]];
        
        if (nil == cell.fwTabComponentManager) {
            
            FWTabComponentManager *manager = [[FWTabAnimated sharedAnimated].cacheManager getComponentManagerWithFileName:fileName];

            if (manager && !manager.needChangeRowStatus) {
                
                manager.fileName = fileName;
                manager.isLoad = YES;
                manager.tabTargetClass = currentClass;
                manager.currentSection = indexPath.section;
                cell.fwTabComponentManager = manager;
                
                [manager reAddToView:cell
                           superView:tableView];
                
                [FWTabManagerMethod hiddenAllView:cell];
                [FWTabManagerMethod startAnimationToSubViews:cell
                                                  rootView:cell];
                [FWTabManagerMethod addExtraAnimationWithSuperView:tableView
                                                      targetView:cell
                                                         manager:cell.fwTabComponentManager];
            }else {
                
                [FWTabManagerMethod fullData:cell];
                
                cell.fwTabComponentManager = [FWTabComponentManager initWithView:cell
                                                                   superView:tableView tabAnimated:tableView.fwTabAnimated];
                cell.fwTabComponentManager.currentSection = indexPath.section;
                cell.fwTabComponentManager.fileName = fileName;
                cell.fwTabComponentManager.tabTargetClass = currentClass;
            
                __weak typeof(cell) weakCell = cell;
                dispatch_async(dispatch_get_main_queue(), ^{
                    FWTabTableAnimated *tabAnimated = (FWTabTableAnimated *)tableView.fwTabAnimated;
                    if (weakCell && tabAnimated && weakCell.fwTabComponentManager) {
                        [FWTabManagerMethod runAnimationWithSuperView:tableView
                                                         targetView:weakCell
                                                             isCell:YES
                                                            manager:weakCell.fwTabComponentManager];
                    }
                });
            }
        
        }else {
            if (cell.fwTabComponentManager.tabLayer.hidden) {
                cell.fwTabComponentManager.tabLayer.hidden = NO;
            }
        }
        cell.fwTabComponentManager.currentRow = indexPath.row;
        
        if (tableView.fwTabAnimated.oldEstimatedRowHeight > 0) {
            [FWTabManagerMethod fullData:cell];
            __weak typeof(cell) weakCell = cell;
            dispatch_async(dispatch_get_main_queue(), ^{
                weakCell.fwTabComponentManager.tabLayer.frame = weakCell.bounds;
                [FWTabManagerMethod resetData:weakCell];
            });
        }
        
        return cell;
    }
    return [self tab_tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (void)tab_tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger index;
    switch (tableView.fwTabAnimated.runMode) {
        case FWTabAnimatedRunBySection: {
            index = indexPath.section;
        }
            break;
        case FWTabAnimatedRunByRow: {
            index = indexPath.row;
        }
            break;
    }
    
    if ([tableView.fwTabAnimated currentIndexIsAnimatingWithIndex:index]) {
        return;
    }
    [self tab_tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
}

- (void)tab_tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger index;
    switch (tableView.fwTabAnimated.runMode) {
        case FWTabAnimatedRunBySection: {
            index = indexPath.section;
        }
            break;
        case FWTabAnimatedRunByRow: {
            index = indexPath.row;
        }
            break;
    }
    
    if ([tableView.fwTabAnimated currentIndexIsAnimatingWithIndex:index]) {
        return;
    }
    [self tab_tableView:tableView didSelectRowAtIndexPath:indexPath];
}

#pragma mark - About HeaderFooterView

- (CGFloat)tab_tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if ([tableView.fwTabAnimated currentIndexIsAnimatingWithIndex:section]) {
        NSInteger index = [tableView.fwTabAnimated headerNeedAnimationOnSection:section];
        if (index != FWTabViewAnimatedErrorCode) {
            NSNumber *value = nil;
            if (index > tableView.fwTabAnimated.headerHeightArray.count - 1) {
                value = tableView.fwTabAnimated.headerHeightArray.lastObject;
            }else {
                value = tableView.fwTabAnimated.headerHeightArray[index];
            }
            return [value floatValue];
        }
        return [self tab_tableView:tableView heightForHeaderInSection:section];
    }
    return [self tab_tableView:tableView heightForHeaderInSection:section];
}

- (CGFloat)tab_tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if ([tableView.fwTabAnimated currentIndexIsAnimatingWithIndex:section]) {
        NSInteger index = [tableView.fwTabAnimated footerNeedAnimationOnSection:section];
        if (index != FWTabViewAnimatedErrorCode) {
            NSNumber *value = nil;
            if (index > tableView.fwTabAnimated.footerHeightArray.count - 1) {
                value = tableView.fwTabAnimated.footerHeightArray.lastObject;
            }else {
                value = tableView.fwTabAnimated.footerHeightArray[index];
            }
            return [value floatValue];
        }
        return [self tab_tableView:tableView heightForFooterInSection:section];
    }
    return [self tab_tableView:tableView heightForFooterInSection:section];
}

- (nullable UIView *)tab_tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if ([tableView.fwTabAnimated currentIndexIsAnimatingWithIndex:section]) {
        NSInteger index = [tableView.fwTabAnimated headerNeedAnimationOnSection:section];
        if (index != FWTabViewAnimatedErrorCode) {
            
            Class class;
            if (index > tableView.fwTabAnimated.headerClassArray.count - 1) {
                class = tableView.fwTabAnimated.headerClassArray.lastObject;
            }else {
                class = tableView.fwTabAnimated.headerClassArray[index];
            }
            
            UIView *headerFooterView = class.new;
            headerFooterView.fwTabAnimated = FWTabViewAnimated.new;
            [headerFooterView fwTabStartAnimation];
            
            NSString *fileName = [NSStringFromClass(class) stringByAppendingString:[NSString stringWithFormat:@"_%@",tableView.fwTabAnimated.targetControllerClassName]];
            
            if (nil == headerFooterView.fwTabComponentManager) {
                
                FWTabComponentManager *manager = [[FWTabAnimated sharedAnimated].cacheManager getComponentManagerWithFileName:fileName];
                
                if (manager) {
                    manager.fileName = fileName;
                    manager.isLoad = YES;
                    manager.tabTargetClass = class;
                    manager.currentSection = section;
                    [manager reAddToView:headerFooterView
                               superView:tableView];
                    headerFooterView.fwTabComponentManager = manager;
                    [FWTabManagerMethod startAnimationToSubViews:headerFooterView
                                                      rootView:headerFooterView];
                    [FWTabManagerMethod addExtraAnimationWithSuperView:tableView
                                                          targetView:headerFooterView
                                                             manager:headerFooterView.fwTabComponentManager];
                }else {
                    [FWTabManagerMethod fullData:headerFooterView];
                    headerFooterView.fwTabComponentManager =
                    [FWTabComponentManager initWithView:headerFooterView
                                            superView:tableView
                                          tabAnimated:tableView.fwTabAnimated];
                    headerFooterView.fwTabComponentManager.currentSection = section;
                    headerFooterView.fwTabComponentManager.fileName = fileName;
                    headerFooterView.fwTabComponentManager.tabTargetClass = class;
                    
                    __weak typeof(headerFooterView) weakView = headerFooterView;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (weakView && weakView.fwTabComponentManager) {
                            
                            BOOL isCell = NO;
                            if ([weakView isKindOfClass:[UITableViewHeaderFooterView class]]) {
                                isCell = YES;
                            }
                            
                            [FWTabManagerMethod runAnimationWithSuperView:tableView
                                                             targetView:weakView
                                                                 isCell:isCell
                                                                manager:weakView.fwTabComponentManager];
                        }
                    });
                }
            }else {
                if (headerFooterView.fwTabComponentManager.tabLayer.hidden) {
                    headerFooterView.fwTabComponentManager.tabLayer.hidden = NO;
                }
            }
            
            if (tableView.fwTabAnimated.oldEstimatedRowHeight > 0) {
                [FWTabManagerMethod fullData:headerFooterView];
                __weak typeof(headerFooterView) weakView = headerFooterView;
                dispatch_async(dispatch_get_main_queue(), ^{
                    weakView.fwTabComponentManager.tabLayer.frame = weakView.bounds;
                    [FWTabManagerMethod resetData:weakView];
                });
            }

            return headerFooterView;
        }
        return [self tab_tableView:tableView viewForHeaderInSection:section];
    }
    return [self tab_tableView:tableView viewForHeaderInSection:section];
}

- (nullable UIView *)tab_tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if ([tableView.fwTabAnimated currentIndexIsAnimatingWithIndex:section]) {
        NSInteger index = [tableView.fwTabAnimated footerNeedAnimationOnSection:section];
        if (index != FWTabViewAnimatedErrorCode) {
            
            Class class;
            if (index > tableView.fwTabAnimated.footerClassArray.count - 1) {
                class = tableView.fwTabAnimated.footerClassArray.lastObject;
            }else {
                class = tableView.fwTabAnimated.footerClassArray[index];
            }
            
            UIView *headerFooterView = class.new;
            headerFooterView.fwTabAnimated = FWTabViewAnimated.new;
            [headerFooterView fwTabStartAnimation];
            
            NSString *fileName = [NSStringFromClass(class) stringByAppendingString:[NSString stringWithFormat:@"_%@",tableView.fwTabAnimated.targetControllerClassName]];
            
            if (nil == headerFooterView.fwTabComponentManager) {
                
                FWTabComponentManager *manager = [[FWTabAnimated sharedAnimated].cacheManager getComponentManagerWithFileName:fileName];
                
                if (manager) {
                    manager.fileName = fileName;
                    manager.isLoad = YES;
                    manager.tabTargetClass = class;
                    manager.currentSection = section;
                    [manager reAddToView:headerFooterView
                               superView:tableView];
                    headerFooterView.fwTabComponentManager = manager;
                    
                    [FWTabManagerMethod startAnimationToSubViews:headerFooterView
                                                      rootView:headerFooterView];
                    [FWTabManagerMethod addExtraAnimationWithSuperView:tableView
                                                          targetView:headerFooterView
                                                             manager:headerFooterView.fwTabComponentManager];
                    
                }else {
                    [FWTabManagerMethod fullData:headerFooterView];
                    headerFooterView.fwTabComponentManager = [FWTabComponentManager initWithView:headerFooterView superView:tableView tabAnimated:tableView.fwTabAnimated];
                    headerFooterView.fwTabComponentManager.currentSection = section;
                    headerFooterView.fwTabComponentManager.fileName = fileName;
                    
                    __weak typeof(headerFooterView) weakView = headerFooterView;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (weakView && weakView.fwTabComponentManager) {
                            
                            BOOL isCell = NO;
                            if ([weakView isKindOfClass:[UITableViewHeaderFooterView class]]) {
                                isCell = YES;
                            }
                            
                            [FWTabManagerMethod runAnimationWithSuperView:tableView
                                                             targetView:weakView
                                                                 isCell:isCell
                                                                manager:weakView.fwTabComponentManager];
                        }
                    });
                }
            }else {
                if (headerFooterView.fwTabComponentManager.tabLayer.hidden) {
                    headerFooterView.fwTabComponentManager.tabLayer.hidden = NO;
                }
            }
            
            headerFooterView.fwTabComponentManager.tabTargetClass = class;
            
            if (tableView.fwTabAnimated.oldEstimatedRowHeight > 0) {
                [FWTabManagerMethod fullData:headerFooterView];
                __weak typeof(headerFooterView) weakView = headerFooterView;
                dispatch_async(dispatch_get_main_queue(), ^{
                    weakView.fwTabComponentManager.tabLayer.frame = weakView.bounds;
                    [FWTabManagerMethod resetData:weakView];
                });
            }
            
            return headerFooterView;
        }
        return [self tab_tableView:tableView viewForFooterInSection:section];
    }
    return [self tab_tableView:tableView viewForFooterInSection:section];
}

@end

@implementation FWTabEstimatedTableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

@end

@interface FWTabCollectionAnimated()

@property (nonatomic, strong, readwrite) NSMutableArray <Class> *headerClassArray;
@property (nonatomic, strong, readwrite) NSMutableArray <NSValue *> *headerSizeArray;
@property (nonatomic, strong, readwrite) NSMutableArray <NSNumber *> *headerSectionArray;

@property (nonatomic, strong, readwrite) NSMutableArray <Class> *footerClassArray;
@property (nonatomic, strong, readwrite) NSMutableArray <NSValue *> *footerSizeArray;
@property (nonatomic, strong, readwrite) NSMutableArray <NSNumber *> *footerSectionArray;

@property (nonatomic, assign, readwrite) FWTabAnimatedRunMode runMode;

@end

@implementation FWTabCollectionAnimated

+ (instancetype)animatedWithCellClass:(Class)cellClass
                             cellSize:(CGSize)cellSize {
    FWTabCollectionAnimated *obj = [[FWTabCollectionAnimated alloc] init];
    obj.cellClassArray = @[cellClass];
    obj.cellSize = cellSize;
    obj.animatedCount = ceilf([UIScreen mainScreen].bounds.size.height/cellSize.height*1.0);
    return obj;
}

+ (instancetype)animatedWithCellClass:(Class)cellClass
                             cellSize:(CGSize)cellSize
                        animatedCount:(NSInteger)animatedCount {
    FWTabCollectionAnimated *obj = [self animatedWithCellClass:cellClass cellSize:cellSize];
    obj.animatedCount = animatedCount;
    return obj;
}

+ (instancetype)animatedWithCellClass:(Class)cellClass
                             cellSize:(CGSize)cellSize
                            toSection:(NSInteger)section {
    FWTabCollectionAnimated *obj = [self animatedWithCellClass:cellClass cellSize:cellSize];
    obj.animatedCountArray = @[@(ceilf([UIScreen mainScreen].bounds.size.height/cellSize.height*1.0))];
    obj.animatedIndexArray = @[@(section)];
    return obj;
}

+ (instancetype)animatedWithCellClass:(Class)cellClass
                             cellSize:(CGSize)cellSize
                        animatedCount:(NSInteger)animatedCount
                            toSection:(NSInteger)section {
    FWTabCollectionAnimated *obj = [self animatedWithCellClass:cellClass cellSize:cellSize];
    obj.animatedCountArray = @[@(animatedCount)];
    obj.animatedIndexArray = @[@(section)];
    return obj;
}

+ (instancetype)animatedWithCellClassArray:(NSArray <Class> *)cellClassArray
                             cellSizeArray:(NSArray <NSValue *> *)cellSizeArray
                        animatedCountArray:(NSArray <NSNumber *> *)animatedCountArray {
    FWTabCollectionAnimated *obj = [[FWTabCollectionAnimated alloc] init];
    obj.animatedCountArray = animatedCountArray;
    obj.cellSizeArray = cellSizeArray;
    obj.cellClassArray = cellClassArray;
    return obj;
}

+ (instancetype)animatedWithCellClassArray:(NSArray <Class> *)cellClassArray
                             cellSizeArray:(NSArray <NSValue *> *)cellSizeArray
                        animatedCountArray:(NSArray <NSNumber *> *)animatedCountArray
                      animatedSectionArray:(NSArray <NSNumber *> *)animatedSectionArray {
    FWTabCollectionAnimated *obj = [self animatedWithCellClassArray:cellClassArray
                                                    cellSizeArray:cellSizeArray
                                               animatedCountArray:animatedCountArray];
    obj.animatedIndexArray = animatedSectionArray;
    return obj;
}

#pragma mark -

+ (instancetype)animatedInRowModeWithCellClassArray:(NSArray <Class> *)cellClassArray
                                      cellSizeArray:(NSArray <NSValue *> *)cellSizeArray {
    FWTabCollectionAnimated *obj = [[FWTabCollectionAnimated alloc] init];
    obj.cellSizeArray = cellSizeArray;
    obj.cellClassArray = cellClassArray;
    obj.runMode = FWTabAnimatedRunByRow;
    return obj;
}

+ (instancetype)animatedInRowModeWithCellClassArray:(NSArray <Class> *)cellClassArray
                                      cellSizeArray:(NSArray <NSValue *> *)cellSizeArray
                                           rowArray:(NSArray <NSNumber *> *)rowArray {
    FWTabCollectionAnimated *obj = [FWTabCollectionAnimated animatedInRowModeWithCellClassArray:cellSizeArray cellSizeArray:cellSizeArray];
    obj.animatedIndexArray = rowArray;
    return obj;
}

+ (instancetype)animatedInRowModeWithCellClass:(Class)cellClass
                                      cellSize:(CGSize)cellSize
                                         toRow:(NSInteger)row {
    FWTabCollectionAnimated *obj = [self animatedWithCellClass:cellClass cellSize:cellSize];
    obj.runMode = FWTabAnimatedRunByRow;
    obj.animatedCountArray = @[@(1)];
    obj.animatedIndexArray = @[@(row)];
    return obj;
}

- (instancetype)init {
    if (self = [super init]) {
        _runAnimationIndexArray = @[].mutableCopy;
        _animatedSectionCount = 0;
        _animatedCount = 1;
        
        _headerSizeArray = @[].mutableCopy;
        _headerClassArray = @[].mutableCopy;
        _headerSectionArray = @[].mutableCopy;
        
        _footerSizeArray = @[].mutableCopy;
        _footerClassArray = @[].mutableCopy;
        _footerSectionArray = @[].mutableCopy;
    }
    return self;
}

- (void)setCellSize:(CGSize)cellSize {
    _cellSize = cellSize;
    _cellSizeArray = @[[NSValue valueWithCGSize:cellSize]];
}

- (BOOL)currentIndexIsAnimatingWithIndex:(NSInteger)index {
    for (NSNumber *num in self.runAnimationIndexArray) {
        if ([num integerValue] == index) {
            return YES;
        }
    }
    return NO;
}

- (NSInteger)headerFooterNeedAnimationOnSection:(NSInteger)section
                                           kind:(NSString *)kind {
    
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        
        if (self.headerSectionArray.count == 0) {
            return FWTabViewAnimatedErrorCode;
        }
        
        for (NSInteger i = 0; i < self.headerSectionArray.count; i++) {
            NSNumber *num = self.headerSectionArray[i];
            if ([num integerValue] == section) {
                return i;
            }
        }
        
        return FWTabViewAnimatedErrorCode;
    }
    
    if (self.footerSectionArray.count == 0) {
        return FWTabViewAnimatedErrorCode;
    }
    
    for (NSInteger i = 0; i < self.footerSectionArray.count; i++) {
        NSNumber *num = self.footerSectionArray[i];
        if ([num integerValue] == section) {
            return i;
        }
    }
    
    return FWTabViewAnimatedErrorCode;
}

- (void)addHeaderViewClass:(_Nonnull Class)headerViewClass
                  viewSize:(CGSize)viewSize {
    [_headerClassArray addObject:headerViewClass];
    [_headerSizeArray addObject:@(viewSize)];
}

- (void)addHeaderViewClass:(_Nonnull Class)headerViewClass
                  viewSize:(CGSize)viewSize
                 toSection:(NSInteger)section {
    BOOL isAdd = false;
    for (int i = 0; i < _headerSectionArray.count; i++) {
        NSInteger oldSection = [_headerSectionArray[i] integerValue];
        if (oldSection == section) {
            isAdd = YES;
            [_headerClassArray replaceObjectAtIndex:i withObject:headerViewClass];
            [_headerSizeArray replaceObjectAtIndex:i withObject:@(viewSize)];
            [_headerSectionArray replaceObjectAtIndex:i withObject:@(section)];
        }
    }
    
    if (!isAdd) {
        [_headerClassArray addObject:headerViewClass];
        [_headerSizeArray addObject:@(viewSize)];
        [_headerSectionArray addObject:@(section)];
    }
}

- (void)addFooterViewClass:(_Nonnull Class)footerViewClass
                  viewSize:(CGSize)viewSize {
    [_footerClassArray addObject:footerViewClass];
    [_footerSizeArray addObject:@(viewSize)];
}

- (void)addFooterViewClass:(_Nonnull Class)footerViewClass
                  viewSize:(CGSize)viewSize
                 toSection:(NSInteger)section {
    BOOL isAdd = false;
    for (int i = 0; i < _footerSectionArray.count; i++) {
        NSInteger oldSection = [_footerSectionArray[i] integerValue];
        if (oldSection == section) {
            isAdd = YES;
            [_footerClassArray replaceObjectAtIndex:i withObject:footerViewClass];
            [_footerSizeArray replaceObjectAtIndex:i withObject:@(viewSize)];
            [_footerSectionArray replaceObjectAtIndex:i withObject:@(section)];
        }
    }
    
    if (!isAdd) {
        [_footerClassArray addObject:footerViewClass];
        [_footerSizeArray addObject:@(viewSize)];
        [_footerSectionArray addObject:@(section)];
    }
}

- (void)exchangeCollectionViewDelegate:(UICollectionView *)target {
    
    id <UICollectionViewDelegate> delegate = target.delegate;
    
    if (!_isExhangeDelegateIMP) {
        _isExhangeDelegateIMP = YES;
        
        if ([target isEqual:delegate]) {
            FWTabCollectionDeDaSelfModel *model = [[FWTabAnimated sharedAnimated] getCollectionDeDaModelAboutDeDaSelfWithClassName:NSStringFromClass(delegate.class)];
            if (!model.isExhangeDelegate) {
                [self exchangeDelegateMethods:delegate
                                       target:target
                                        model:model];
                model.isExhangeDelegate = YES;
            }
        }else {
            [self exchangeDelegateMethods:delegate
                                   target:target
                                    model:nil];
        }
    }
}

- (void)exchangeCollectionViewDataSource:(UICollectionView *)target {
    
    id <UICollectionViewDataSource> dataSource = target.dataSource;
    
    if (!_isExhangeDataSourceIMP) {
        _isExhangeDataSourceIMP = YES;
        if ([target isEqual:dataSource]) {
            FWTabCollectionDeDaSelfModel *model = [[FWTabAnimated sharedAnimated] getCollectionDeDaModelAboutDeDaSelfWithClassName:NSStringFromClass(dataSource.class)];
            if (!model.isExhangeDataSource) {
                [self exchangeDataSourceMethods:dataSource
                                         target:target
                                          model:model];
                model.isExhangeDataSource = YES;
            }
        }else {
            [self exchangeDataSourceMethods:dataSource
                                     target:target
                                      model:nil];
        }
    }
}

#pragma mark - Private Methods

- (void)exchangeDelegateMethods:(id<UICollectionViewDelegate>)delegate
                         target:(id)target
                          model:(FWTabCollectionDeDaSelfModel *)model {
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    
    SEL oldHeightSel = @selector(collectionView:layout:sizeForItemAtIndexPath:);
    SEL newHeightSel;
    if (model) {
        newHeightSel = @selector(tab_deda_collectionView:layout:sizeForItemAtIndexPath:);
    }else {
        newHeightSel = @selector(tab_collectionView:layout:sizeForItemAtIndexPath:);
    }
    [self exchangeDelegateOldSel:oldHeightSel
                      withNewSel:newHeightSel
                      withTarget:target
                    withDelegate:delegate
                           model:model];
    
    SEL oldDisplaySel = @selector(collectionView:willDisplayCell:forItemAtIndexPath:);
    SEL newDisplaySel;
    if (model) {
        newDisplaySel = @selector(tab_deda_collectionView:willDisplayCell:forItemAtIndexPath:);
    }else {
        newDisplaySel = @selector(tab_collectionView:willDisplayCell:forItemAtIndexPath:);
    }
    [self exchangeDelegateOldSel:oldDisplaySel
                      withNewSel:newDisplaySel
                      withTarget:target
                    withDelegate:delegate
                           model:model];
    
    SEL oldClickSel = @selector(collectionView:didSelectItemAtIndexPath:);
    SEL newClickSel;
    if (model) {
        newClickSel = @selector(tab_deda_collectionView:didSelectItemAtIndexPath:);
    }else {
        newClickSel = @selector(tab_collectionView:didSelectItemAtIndexPath:);
    }
    [self exchangeDelegateOldSel:oldClickSel
                      withNewSel:newClickSel
                      withTarget:target
                    withDelegate:delegate
                           model:model];
    
#pragma clang diagnostic pop
    
}

- (void)exchangeDataSourceMethods:(id<UICollectionViewDataSource>)dataSource
                           target:(id)target
                            model:(FWTabCollectionDeDaSelfModel *)model {
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    
    SEL oldSectionsSel = @selector(numberOfSectionsInCollectionView:);
    SEL newSectionsSel;
    if (model) {
        newSectionsSel = @selector(tab_deda_numberOfSectionsInCollectionView:);
    }else {
        newSectionsSel = @selector(tab_numberOfSectionsInCollectionView:);
    }
    [self exchangeDelegateOldSel:oldSectionsSel
                      withNewSel:newSectionsSel
                      withTarget:target
                    withDelegate:dataSource
                           model:model];
    
    SEL oldItemsSel = @selector(collectionView:numberOfItemsInSection:);
    SEL newItemsSel;
    if (model) {
        newItemsSel = @selector(tab_deda_collectionView:numberOfItemsInSection:);
    }else {
        newItemsSel = @selector(tab_collectionView:numberOfItemsInSection:);
    }
    [self exchangeDelegateOldSel:oldItemsSel
                      withNewSel:newItemsSel
                      withTarget:target
                    withDelegate:dataSource
                           model:model];
    
    SEL oldCellSel = @selector(collectionView:cellForItemAtIndexPath:);
    SEL newCellSel;
    if (model) {
        newCellSel = @selector(tab_deda_collectionView:cellForItemAtIndexPath:);
    }else {
        newCellSel = @selector(tab_collectionView:cellForItemAtIndexPath:);
    }
    [self exchangeDelegateOldSel:oldCellSel
                      withNewSel:newCellSel
                      withTarget:target
                    withDelegate:dataSource
                           model:model];
    
    SEL oldReuseableCellSel = @selector(collectionView:viewForSupplementaryElementOfKind:atIndexPath:);
    SEL newReuseableCellSel;
    if (model) {
        newReuseableCellSel = @selector(tab_deda_collectionView:viewForSupplementaryElementOfKind:atIndexPath:);
    }else {
        newReuseableCellSel = @selector(tab_collectionView:viewForSupplementaryElementOfKind:atIndexPath:);
    }
    [self exchangeDelegateOldSel:oldReuseableCellSel
                      withNewSel:newReuseableCellSel
                      withTarget:target
                    withDelegate:dataSource
                           model:model];
    
    SEL oldHeaderCellSel = @selector(collectionView:layout:referenceSizeForHeaderInSection:);
    SEL newHeaderCellSel;
    if (model) {
        newHeaderCellSel = @selector(tab_deda_collectionView:layout:referenceSizeForHeaderInSection:);
    }else {
        newHeaderCellSel = @selector(tab_collectionView:layout:referenceSizeForHeaderInSection:);
    }
    [self exchangeDelegateOldSel:oldHeaderCellSel
                      withNewSel:newHeaderCellSel
                      withTarget:target
                    withDelegate:dataSource
                           model:model];
    
    SEL oldFooterCellSel = @selector(collectionView:layout:referenceSizeForFooterInSection:);
    SEL newFooterCellSel;
    if (model) {
        newFooterCellSel = @selector(tab_deda_collectionView:layout:referenceSizeForFooterInSection:);
    }else {
        newFooterCellSel = @selector(tab_collectionView:layout:referenceSizeForFooterInSection:);
    }
    [self exchangeDelegateOldSel:oldFooterCellSel
                      withNewSel:newFooterCellSel
                      withTarget:target
                    withDelegate:dataSource
                           model:model];
    
#pragma clang diagnostic pop
    
}

/**
 exchange method
 
 @param oldSelector old method's sel
 @param newSelector new method's sel
 @param delegate return nil
 */
- (void)exchangeDelegateOldSel:(SEL)oldSelector
                    withNewSel:(SEL)newSelector
                    withTarget:(id)target
                  withDelegate:(id)delegate
                         model:(FWTabCollectionDeDaSelfModel *)model {
    
    if (![delegate respondsToSelector:oldSelector]) {
        return;
    }
    
    Class targetClass;
    if (model) {
        targetClass = [model class];
    }else {
        targetClass = [self class];
    }
    
    Method newMethod = class_getInstanceMethod(targetClass, newSelector);
    if (newMethod == nil) {
        return;
    }
    
    Method oldMethod = class_getInstanceMethod([delegate class], oldSelector);
    
    BOOL isVictory = class_addMethod([delegate class], newSelector, class_getMethodImplementation([delegate class], oldSelector), method_getTypeEncoding(oldMethod));
    if (isVictory) {
        class_replaceMethod([delegate class], oldSelector, class_getMethodImplementation(targetClass, newSelector), method_getTypeEncoding(newMethod));
    }
}

#pragma mark - FWTabCollectionViewDelegate

- (NSInteger)tab_numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    if (collectionView.fwTabAnimated.state == FWTabViewAnimationStart) {
        
        if (collectionView.fwTabAnimated.animatedSectionCount != 0) {
            return collectionView.fwTabAnimated.animatedSectionCount;
        }

        NSInteger count = [self tab_numberOfSectionsInCollectionView:collectionView];
        if (count == 0) {
            count = collectionView.fwTabAnimated.cellClassArray.count;
        }

        if (count == 0) return 1;
        
        return count;
    }
    
    return [self tab_numberOfSectionsInCollectionView:collectionView];
}

- (NSInteger)tab_collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    if (collectionView.fwTabAnimated.runMode == FWTabAnimatedRunByRow) {
        NSInteger count = [self tab_collectionView:collectionView numberOfItemsInSection:section];
        if (count == 0) {
            return collectionView.fwTabAnimated.cellClassArray.count;
        }
        return count;
    }
    
    if ([collectionView.fwTabAnimated currentIndexIsAnimatingWithIndex:section]) {
        
        // 开发者指定section
        if (collectionView.fwTabAnimated.animatedIndexArray.count > 0) {
            
            // 匹配当前section
            for (NSNumber *num in collectionView.fwTabAnimated.animatedIndexArray) {
                if ([num integerValue] == section) {
                    NSInteger index = [collectionView.fwTabAnimated.animatedIndexArray indexOfObject:num];
                    if (index > collectionView.fwTabAnimated.animatedCountArray.count - 1) {
                        return [[collectionView.fwTabAnimated.animatedCountArray lastObject] integerValue];
                    }else {
                        return [collectionView.fwTabAnimated.animatedCountArray[index] integerValue];
                    }
                }
                
                if ([num isEqual:[collectionView.fwTabAnimated.animatedIndexArray lastObject]]) {
                    return [self tab_collectionView:collectionView numberOfItemsInSection:section];
                }
            }
        }
        
        if (collectionView.fwTabAnimated.animatedCountArray.count > 0) {
            if (section > collectionView.fwTabAnimated.animatedCountArray.count - 1) {
                return collectionView.fwTabAnimated.animatedCount;
            }
            return [collectionView.fwTabAnimated.animatedCountArray[section] integerValue];
        }
        return collectionView.fwTabAnimated.animatedCount;
    }
    return [self tab_collectionView:collectionView numberOfItemsInSection:section];
}

- (CGSize)tab_collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger index;
    switch (collectionView.fwTabAnimated.runMode) {
        case FWTabAnimatedRunBySection: {
            index = indexPath.section;
        }
            break;
        case FWTabAnimatedRunByRow: {
            index = indexPath.row;
        }
            break;
    }
    
    if ([collectionView.fwTabAnimated currentIndexIsAnimatingWithIndex:index]) {
        
        // 开发者指定section
        if (collectionView.fwTabAnimated.animatedIndexArray.count > 0) {
            
            // 匹配当前section
            for (NSNumber *num in collectionView.fwTabAnimated.animatedIndexArray) {
                if ([num integerValue] == index) {
                    NSInteger currentIndex = [collectionView.fwTabAnimated.animatedIndexArray indexOfObject:num];
                    if (currentIndex > collectionView.fwTabAnimated.cellSizeArray.count - 1) {
                        index = [collectionView.fwTabAnimated.cellSizeArray count] - 1;
                    }else {
                        index = currentIndex;
                    }
                    break;
                }
                
                if ([num isEqual:[collectionView.fwTabAnimated.animatedIndexArray lastObject]]) {
                    return [self tab_collectionView:collectionView layout:collectionViewLayout sizeForItemAtIndexPath:indexPath];
                }
            }
        }else {
            if (index > (collectionView.fwTabAnimated.cellSizeArray.count - 1)) {
                index = collectionView.fwTabAnimated.cellSizeArray.count - 1;
                tabAnimatedLog(@"FWTabAnimated提醒 - 获取到的分区的数量和设置的分区数量不一致，超出的分区值部分，将使用最后一个分区cell加载");
            }
        }
        
        CGSize size = [collectionView.fwTabAnimated.cellSizeArray[index] CGSizeValue];
        return size;
    }
    return [self tab_collectionView:collectionView layout:collectionViewLayout sizeForItemAtIndexPath:indexPath];
}

- (UICollectionViewCell *)tab_collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger index;
    switch (collectionView.fwTabAnimated.runMode) {
        case FWTabAnimatedRunBySection: {
            index = indexPath.section;
        }
            break;
        case FWTabAnimatedRunByRow: {
            index = indexPath.row;
        }
            break;
    }
    
    if ([collectionView.fwTabAnimated currentIndexIsAnimatingWithIndex:index]) {
        
        // 开发者指定section
        if (collectionView.fwTabAnimated.animatedIndexArray.count > 0) {
            
            // 匹配当前section
            for (NSNumber *num in collectionView.fwTabAnimated.animatedIndexArray) {
                if ([num integerValue] == index) {
                    NSInteger currentIndex = [collectionView.fwTabAnimated.animatedIndexArray indexOfObject:num];
                    if (currentIndex > collectionView.fwTabAnimated.cellClassArray.count - 1) {
                        index = [collectionView.fwTabAnimated.cellClassArray count] - 1;
                    }else {
                        index = currentIndex;
                    }
                    break;
                }
                
                if ([num isEqual:[collectionView.fwTabAnimated.animatedIndexArray lastObject]]) {
                    return [self tab_collectionView:collectionView cellForItemAtIndexPath:indexPath];
                }
            }
        }else {
            if (index > (collectionView.fwTabAnimated.cellClassArray.count - 1)) {
                index = collectionView.fwTabAnimated.cellClassArray.count - 1;
                tabAnimatedLog(@"FWTabAnimated提醒 - 获取到的分区的数量和设置的分区数量不一致，超出的分区值部分，将使用最后一个分区cell加载");
            }
        }
        
        Class currentClass = collectionView.fwTabAnimated.cellClassArray[index];
        NSString *className = NSStringFromClass(currentClass);
        if ([className containsString:@"."]) {
            NSRange range = [className rangeOfString:@"."];
            className = [className substringFromIndex:range.location+1];
        }
        
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[NSString stringWithFormat:@"tab_%@",className] forIndexPath:indexPath];
        
        NSString *fileName = [className stringByAppendingString:[NSString stringWithFormat:@"_%@",collectionView.fwTabAnimated.targetControllerClassName]];
        
        if (nil == cell.fwTabComponentManager) {
            
            FWTabComponentManager *manager = [[FWTabAnimated sharedAnimated].cacheManager getComponentManagerWithFileName:fileName];

            if (manager &&
                !manager.needChangeRowStatus) {
                manager.fileName = fileName;
                manager.isLoad = YES;
                manager.tabTargetClass = currentClass;
                manager.currentSection = indexPath.section;
                cell.fwTabComponentManager = manager;
                [manager reAddToView:cell
                           superView:collectionView];
                [FWTabManagerMethod startAnimationToSubViews:cell
                                                  rootView:cell];
                [FWTabManagerMethod addExtraAnimationWithSuperView:collectionView
                                                      targetView:cell
                                                         manager:cell.fwTabComponentManager];

            }else {
                [FWTabManagerMethod fullData:cell];
                cell.fwTabComponentManager =
                [FWTabComponentManager initWithView:cell
                                        superView:collectionView
                                      tabAnimated:collectionView.fwTabAnimated];
                cell.fwTabComponentManager.currentSection = indexPath.section;
                cell.fwTabComponentManager.fileName = fileName;
                
                __weak typeof(cell) weakCell = cell;
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (weakCell && weakCell.fwTabComponentManager) {
                        weakCell.fwTabComponentManager.tabTargetClass = weakCell.class;
                        // 加载动画
                        [FWTabManagerMethod runAnimationWithSuperView:collectionView
                                                         targetView:weakCell
                                                             isCell:YES
                                                            manager:weakCell.fwTabComponentManager];
                    }
                });
            }
        
        }else {
            if (cell.fwTabComponentManager.tabLayer.hidden) {
                cell.fwTabComponentManager.tabLayer.hidden = NO;
            }
        }
        cell.fwTabComponentManager.currentRow = indexPath.row;
        
        return cell;
    }
    return [self tab_collectionView:collectionView cellForItemAtIndexPath:indexPath];
}

- (void)tab_collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger index;
    switch (collectionView.fwTabAnimated.runMode) {
        case FWTabAnimatedRunBySection: {
            index = indexPath.section;
        }
            break;
        case FWTabAnimatedRunByRow: {
            index = indexPath.row;
        }
            break;
    }
    
    if ([collectionView.fwTabAnimated currentIndexIsAnimatingWithIndex:index]) {
        return;
    }
    [self tab_collectionView:collectionView willDisplayCell:cell forItemAtIndexPath:indexPath];
}

- (void)tab_collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger index;
    switch (collectionView.fwTabAnimated.runMode) {
        case FWTabAnimatedRunBySection: {
            index = indexPath.section;
        }
            break;
        case FWTabAnimatedRunByRow: {
            index = indexPath.row;
        }
            break;
    }
    
    if ([collectionView.fwTabAnimated currentIndexIsAnimatingWithIndex:index] ||
        collectionView.fwTabAnimated.state == FWTabViewAnimationRunning) {
        return;
    }
    [self tab_collectionView:collectionView didSelectItemAtIndexPath:indexPath];
}

#pragma mark - About HeaderFooterView

- (CGSize)tab_collectionView:(UICollectionView *)collectionView
                      layout:(UICollectionViewLayout*)collectionViewLayout
referenceSizeForHeaderInSection:(NSInteger)section {
    
    if ([collectionView.fwTabAnimated currentIndexIsAnimatingWithIndex:section]) {
        NSInteger index = [collectionView.fwTabAnimated headerFooterNeedAnimationOnSection:section
                                                                                    kind:UICollectionElementKindSectionHeader];
        if (index != FWTabViewAnimatedErrorCode) {
            NSValue *value = nil;
            if (index > collectionView.fwTabAnimated.headerSizeArray.count - 1) {
                value = collectionView.fwTabAnimated.headerSizeArray.lastObject;
            }else {
                value = collectionView.fwTabAnimated.headerSizeArray[index];
            }
            return [value CGSizeValue];
        }
        return [self tab_collectionView:collectionView
                                 layout:collectionViewLayout
        referenceSizeForHeaderInSection:section];
    }
    
    return [self tab_collectionView:collectionView
                             layout:collectionViewLayout
    referenceSizeForHeaderInSection:section];
}

- (CGSize)tab_collectionView:(UICollectionView *)collectionView
                      layout:(UICollectionViewLayout*)collectionViewLayout
referenceSizeForFooterInSection:(NSInteger)section {
    
    if ([collectionView.fwTabAnimated currentIndexIsAnimatingWithIndex:section]) {
        NSInteger index = [collectionView.fwTabAnimated headerFooterNeedAnimationOnSection:section
                                                                                    kind:UICollectionElementKindSectionFooter];
        if (index != FWTabViewAnimatedErrorCode) {
            NSValue *value = nil;
            if (index > collectionView.fwTabAnimated.footerSizeArray.count - 1) {
                value = collectionView.fwTabAnimated.footerSizeArray.lastObject;
            }else {
                value = collectionView.fwTabAnimated.footerSizeArray[index];
            }
            return [value CGSizeValue];
        }
        return [self tab_collectionView:collectionView
                                 layout:collectionViewLayout
        referenceSizeForFooterInSection:section];
    }
    
    return [self tab_collectionView:collectionView
                             layout:collectionViewLayout
    referenceSizeForFooterInSection:section];
}

- (UICollectionReusableView *)tab_collectionView:(UICollectionView *)collectionView
               viewForSupplementaryElementOfKind:(NSString *)kind
                                     atIndexPath:(NSIndexPath *)indexPath {
    if ([collectionView.fwTabAnimated currentIndexIsAnimatingWithIndex:indexPath.section]) {
        
        NSInteger index = [collectionView.fwTabAnimated headerFooterNeedAnimationOnSection:indexPath.section
                                                                                    kind:kind];
        
        if (index == FWTabViewAnimatedErrorCode) {
            return [self tab_collectionView:collectionView
          viewForSupplementaryElementOfKind:kind
                                atIndexPath:indexPath];
        }
        
        Class resuableClass = nil;
        NSString *identifier = nil;
        NSString *defaultPredix = nil;
        
        if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
            if (index > collectionView.fwTabAnimated.headerClassArray.count - 1) {
                resuableClass = collectionView.fwTabAnimated.headerClassArray.lastObject;
            }else {
                resuableClass = collectionView.fwTabAnimated.headerClassArray[index];
            }
            defaultPredix = FWTabViewAnimatedHeaderPrefixString;
            identifier = [NSString stringWithFormat:@"%@%@",FWTabViewAnimatedHeaderPrefixString,NSStringFromClass(resuableClass)];
        }else {
            if (index > collectionView.fwTabAnimated.footerClassArray.count - 1) {
                resuableClass = collectionView.fwTabAnimated.footerClassArray.lastObject;
            }else {
                resuableClass = collectionView.fwTabAnimated.footerClassArray[index];
            }
            defaultPredix = FWTabViewAnimatedFooterPrefixString;
            identifier = [NSString stringWithFormat:@"%@%@",FWTabViewAnimatedFooterPrefixString,NSStringFromClass(resuableClass)];
        }
        
        if (resuableClass == nil) {
            return [self tab_collectionView:collectionView
          viewForSupplementaryElementOfKind:kind
                                atIndexPath:indexPath];
        }
        
        UIView *view = resuableClass.new;
        UICollectionReusableView *reusableView;
        
        if (![view isKindOfClass:[UICollectionReusableView class]]) {
            reusableView = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                              withReuseIdentifier:[NSString stringWithFormat:@"%@%@",defaultPredix,FWTabViewAnimatedDefaultSuffixString]
                                                                     forIndexPath:indexPath];
            for (UIView *view in reusableView.subviews) {
                [view removeFromSuperview];
            }
            view.frame = reusableView.bounds;
            [reusableView addSubview:view];
        }else {
            reusableView = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                              withReuseIdentifier:identifier
                                                                     forIndexPath:indexPath];
        }
        
        NSString *fileName = [NSStringFromClass(resuableClass) stringByAppendingString:[NSString stringWithFormat:@"_%@",collectionView.fwTabAnimated.targetControllerClassName]];
        
        if (nil == reusableView.fwTabComponentManager) {
            
            FWTabComponentManager *manager = [[FWTabAnimated sharedAnimated].cacheManager getComponentManagerWithFileName:fileName];
            
            if (manager &&
                !manager.needChangeRowStatus) {
                manager.fileName = fileName;
                manager.isLoad = YES;
                manager.tabTargetClass = resuableClass;
                manager.currentSection = indexPath.section;
                [manager reAddToView:reusableView
                           superView:collectionView];
                reusableView.fwTabComponentManager = manager;
                [FWTabManagerMethod startAnimationToSubViews:reusableView
                                                  rootView:reusableView];
                [FWTabManagerMethod addExtraAnimationWithSuperView:collectionView
                                                      targetView:reusableView
                                                         manager:reusableView.fwTabComponentManager];
            }else {
                [FWTabManagerMethod fullData:reusableView];
                reusableView.fwTabComponentManager =
                [FWTabComponentManager initWithView:reusableView
                                        superView:collectionView
                                      tabAnimated:collectionView.fwTabAnimated];
                reusableView.fwTabComponentManager.currentSection = indexPath.section;
                reusableView.fwTabComponentManager.tabTargetClass = resuableClass;
                reusableView.fwTabComponentManager.fileName = fileName;
                
                __weak typeof(reusableView) weakView = reusableView;
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (weakView && weakView.fwTabComponentManager) {
                        
                        BOOL isCell = NO;
                        if ([weakView isKindOfClass:[UICollectionReusableView class]]) {
                            isCell = YES;
                        }
                        
                        [FWTabManagerMethod runAnimationWithSuperView:collectionView
                                                         targetView:weakView
                                                             isCell:isCell
                                                            manager:weakView.fwTabComponentManager];
                    }
                });
            }
        }else {
            if (reusableView.fwTabComponentManager.tabLayer.hidden) {
                reusableView.fwTabComponentManager.tabLayer.hidden = NO;
            }
        }
        reusableView.fwTabComponentManager.currentRow = indexPath.row;
        
        return reusableView;
        
    }
    return [self tab_collectionView:collectionView viewForSupplementaryElementOfKind:kind atIndexPath:indexPath];
}

@end

#define tab_kBackColor tab_kColor(0xEEEEEE)
#define tab_kDarkBackColor tab_kColor(0x282828)
#define tab_kShimmerBackColor tab_kColor(0xDFDFDF)

NSString * const FWTabAnimatedAlphaAnimation = @"FWTabAlphaAnimation";
NSString * const FWTabAnimatedLocationAnimation = @"FWTabLocationAnimation";
NSString * const FWTabAnimatedShimmerAnimation = @"FWTabShimmerAnimation";
NSString * const FWTabAnimatedDropAnimation = @"FWTabDropAnimation";

@interface FWTabAnimated()

@property (nonatomic, strong, readwrite) NSMutableArray <FWTabTableDeDaSelfModel *> *tableDeDaSelfModelArray;
@property (nonatomic, strong, readwrite) NSMutableArray <FWTabCollectionDeDaSelfModel *> *collectionDeDaSelfModelArray;

@property (nonatomic, strong, readwrite) FWTabAnimatedCacheManager *cacheManager;

@end

@implementation FWTabAnimated

#pragma mark - Initize Method

+ (FWTabAnimated *)sharedAnimated {
    static dispatch_once_t token;
    static FWTabAnimated *tabAnimated;
    dispatch_once(&token, ^{
        tabAnimated = [[FWTabAnimated alloc] init];
    });
    return tabAnimated;
}

- (instancetype)init {
    if (self = [super init]) {
        
        _tableDeDaSelfModelArray = @[].mutableCopy;
        _collectionDeDaSelfModelArray = @[].mutableCopy;
        
        _animationType = FWTabAnimationTypeOnlySkeleton;
        [FWTabAnimatedDocumentMethod createFile:FWTabCacheManagerFolderName
                                        isDir:YES];
#ifdef DEBUG
        _closeCache = YES;
#endif
        
        _cacheManager = FWTabAnimatedCacheManager.new;
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.cacheManager install];
        });
    }
    return self;
}

- (void)initWithOnlySkeleton {
    if (self) {
        _animationType = FWTabAnimationTypeOnlySkeleton;
    }
}

- (void)initWithBinAnimation {
    if (self) {
        _animationType = FWTabAnimationTypeBinAnimation;
    }
}

- (void)initWithShimmerAnimated {
    if (self) {
        _animationType = FWTabAnimationTypeShimmer;
        _animatedDurationShimmer = 1.;
        _shimmerDirection = FWTabShimmerDirectionToRight;
        _shimmerBackColor = tab_kShimmerBackColor;
        _shimmerBrightness = 0.92;
    }
}

- (void)initWithShimmerAnimatedDuration:(CGFloat)duration
                              withColor:(UIColor *)color {
    if (self) {
        _animatedDurationShimmer = duration;
        _animatedColor = color;
        _animationType = FWTabAnimationTypeShimmer;
        _shimmerDirection = FWTabShimmerDirectionToRight;
        _shimmerBackColor = tab_kShimmerBackColor;
        _shimmerBrightness = 0.92;
    }
}

- (void)initWithDropAnimated {
    if (self) {
        _animationType = FWTabAnimationTypeDrop;
    }
}

#pragma mark - Other Method

- (FWTabTableDeDaSelfModel *)getTableDeDaModelAboutDeDaSelfWithClassName:(NSString *)className {
    for (FWTabTableDeDaSelfModel *model in self.tableDeDaSelfModelArray) {
        if ([model.targetClassName isEqualToString:className]) {
            return model;
        }
    }
    
    FWTabTableDeDaSelfModel *newModel = FWTabTableDeDaSelfModel.new;
    newModel.targetClassName = className;
    [self.tableDeDaSelfModelArray addObject:newModel];
    return newModel;
}

- (FWTabCollectionDeDaSelfModel *)getCollectionDeDaModelAboutDeDaSelfWithClassName:(NSString *)className {
    for (FWTabCollectionDeDaSelfModel *model in self.collectionDeDaSelfModelArray) {
        if ([model.targetClassName isEqualToString:className]) {
            return model;
        }
    }
    
    FWTabCollectionDeDaSelfModel *newModel = FWTabCollectionDeDaSelfModel.new;
    newModel.targetClassName = className;
    [self.collectionDeDaSelfModelArray addObject:newModel];
    return newModel;
}

#pragma mark - Getter / Setter

- (CGFloat)animatedHeightCoefficient {
    if (_animatedHeightCoefficient == 0.) {
        return 0.75f;
    }
    return _animatedHeightCoefficient;
}

- (CGFloat)animatedHeight {
    if (_animatedHeight == 0.) {
        return 12.f;
    }
    return _animatedHeight;
}

- (UIColor *)animatedColor {
    if (_animatedColor) {
        return _animatedColor;
    }
    return tab_kBackColor;
}

- (UIColor *)darkAnimatedColor {
    if (_darkAnimatedColor) {
        return _darkAnimatedColor;
    }
    return tab_kDarkBackColor;
}

- (UIColor *)animatedBackgroundColor {
    if (_animatedBackgroundColor) {
        return _animatedBackgroundColor;
    }
    return UIColor.whiteColor;
}

- (UIColor *)darkAnimatedBackgroundColor {
    if (_darkAnimatedBackgroundColor) {
        return _darkAnimatedBackgroundColor;
    }
    
    if (@available(iOS 13.0, *)) {
        return UIColor.secondarySystemBackgroundColor;
    }
    return UIColor.whiteColor;
}

- (UIColor *)dropAnimationDeepColor {
    if (_dropAnimationDeepColor) {
        return _dropAnimationDeepColor;
    }
    return tab_kColor(0xE1E1E1);
}

- (UIColor *)dropAnimationDeepColorInDarkMode {
    if (_dropAnimationDeepColorInDarkMode) {
        return _dropAnimationDeepColorInDarkMode;
    }
    return tab_kColor(0x323232);
}

- (CGFloat)dropAnimationDuration {
    if (_dropAnimationDuration) {
        return _dropAnimationDuration;
    }
    return 0.4;
}

- (CGFloat)animatedDuration {
    if (_animatedDuration == 0.) {
        return 0.7;
    }
    return _animatedDuration;
}

- (CGFloat)animatedDurationBin {
    if (_animatedDurationBin == 0.) {
        return 1.0;
    }
    return _animatedDurationBin;
}

- (CGFloat)longToValue {
    if (_longToValue == 0.) {
        return 1.9;
    }
    return _longToValue;
}

- (CGFloat)shortToValue {
    if (_shortToValue == 0.) {
        return 0.6;
    }
    return _shortToValue;
}

- (UIColor *)shimmerBackColor {
    if (_shimmerBackColor == nil) {
        return tab_kShimmerBackColor;
    }
    return _shimmerBackColor;
}

- (CGFloat)shimmerBrightness {
    if (_shimmerBrightness == 0.) {
        return 0.92;
    }
    return _shimmerBrightness;
}

- (UIColor *)shimmerBackColorInDarkMode {
    if (_shimmerBackColorInDarkMode == nil) {
        return tab_kDarkBackColor;
    }
    return _shimmerBackColorInDarkMode;
}

- (CGFloat)shimmerBrightnessInDarkMode {
    if (_shimmerBrightnessInDarkMode == 0.) {
        return 0.5;
    }
    return _shimmerBrightnessInDarkMode;
}

- (CGFloat)animatedDurationShimmer {
    if (_animatedDurationShimmer == 0.) {
        return 1.;
    }
    return _animatedDurationShimmer;
}

@end
