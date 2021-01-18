//
//  TestDrawViewController.m
//  Example
//
//  Created by wuyong on 2020/9/28.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

#import "TestDrawViewController.h"

@interface LJBaseModel : NSObject<NSCopying,NSCoding,FWModel>

-(void)encodeWithCoder:(NSCoder *)aCoder;

-(id)initWithCoder:(NSCoder *)aDecoder;

-(id)copyWithZone:(NSZone *)zone;

-(NSUInteger)hash;

-(BOOL)isEqual:(id)object;

@end

@interface LSDrawModel : LJBaseModel

@property (nonatomic, assign) NSInteger modelType;

@end

@interface LSPointModel : LSDrawModel

@property (nonatomic, assign) CGFloat xPoint;

@property (nonatomic, assign) CGFloat yPoint;

@property (nonatomic, assign) double timeOffset;

@end

@interface LSBrushModel : LSDrawModel

@property (nonatomic, copy) UIColor *brushColor;

@property (nonatomic, assign) CGFloat brushWidth;

@property (nonatomic, assign) NSInteger shapeType;

@property (nonatomic, assign) BOOL isEraser;

@property (nonatomic, copy) LSPointModel *beginPoint;

@property (nonatomic, copy) LSPointModel *endPoint;

@end

typedef NS_ENUM(NSInteger, LSDrawAction)
{
    LSDrawActionUnKnown = 1,
    LSDrawActionUndo,
    LSDrawActionRedo,
    LSDrawActionSave,
    LSDrawActionClean,
    LSDrawActionOther,
};

@interface LSActionModel : LSDrawModel

@property (nonatomic, assign) LSDrawAction ActionType;

@end

@interface LSDrawPackage : LJBaseModel

@property (nonatomic, strong) NSMutableArray<LSDrawModel*> *pointOrBrushArray;

@end


@interface LSDrawFile : LJBaseModel

@property (nonatomic, strong) NSMutableArray<LSDrawPackage*> *packageArray;

@end

@implementation LJBaseModel

-(void)encodeWithCoder:(NSCoder *)aCoder{
    [self fwModelEncodeWithCoder:aCoder];

}

-(id)initWithCoder:(NSCoder *)aDecoder{
    
    self = [super init];
    return [self fwModelInitWithCoder:aDecoder];
    
}

-(id)copyWithZone:(NSZone *)zone{
    
    return [self fwModelCopy];
    
}
-(NSUInteger)hash{
    
    return [self fwModelHash];
    
}

-(BOOL)isEqual:(id)object{

    return [self fwModelIsEqual:object];
    
}

+ (NSDictionary<NSString *,id> *)fwModelPropertyMapper {
    return @{@"Id" : @"id",
             @"Description" : @"description",
             };
}

@end

@implementation LSDrawModel


@end

@implementation LSPointModel


@end

@implementation LSBrushModel


@end

@implementation LSActionModel


@end

@implementation LSDrawPackage


@end

@implementation LSDrawFile


@end

/*
 这个demo主要是参考了下面两个项目
 
 https://github.com/WillieWu/HBDrawingBoardDemo
 
 https://github.com/Nicejinux/NXDrawKit
 
 也针对这两个demo做了相应的优化
 
 
 结构：由上至下
 
 1、最上层的UIView(LSCanvas)
 使用CAShapeLayer，提高绘制时的效率
 
 2、第二层的UIImageview是用来合成LSCanvas用的
 
 这样画很多次的时候，也不会占用很高的cpu
 
 3、第三层是UIImageview，是用来放背景图的
 
 ps:
 没使用drawrect
 
 关于录制脚本：
 1、//linyl 标记的代码都是跟录制脚本和绘制脚本相关
 2、录制后需要重新跑程序，因为这只是个demo
 
 还需要优化的地方：
 1、当前的记录方式是用归档的方式，每次有动作（撤销，重做，保存，清空）和每次的touchsend
 后，都会记录成一个LSDrawPackage对象，如果想使用socket时，这里可以改为每0.5秒一个LSDrawPackage对象
 ，也就是说，每个LSDrawPackage对象都是一段时间内的绘制和操作。
 
 2、线程处理
    demo中使用的是performselector的方式，这里还需要优化。
 
 3、当前的绘制端和显示端公用了很多的内部结构
 
 */

#import <UIKit/UIKit.h>

#define MAX_UNDO_COUNT   10

#define LSDEF_BRUSH_COLOR [UIColor colorWithRed:255 green:0 blue:0 alpha:1.0]

#define LSDEF_BRUSH_WIDTH 3

#define LSDEF_BRUSH_SHAPE LSShapeCurve

//画笔形状
typedef NS_ENUM(NSInteger, LSShapeType)
{
    LSShapeCurve = 0,//曲线(默认)
    LSShapeLine,//直线
    LSShapeEllipse,//椭圆
    LSShapeRect,//矩形
    
};
/////////////////////////////////////////////////////////////////////

//封装的画笔类
@interface LSBrush: NSObject

//画笔颜色
@property (nonatomic, strong) UIColor *brushColor;

//画笔宽度
@property (nonatomic, assign) NSInteger brushWidth;

//是否是橡皮擦
@property (nonatomic, assign) BOOL isEraser;

//形状
@property (nonatomic, assign) LSShapeType shapeType;

//路径
@property (nonatomic, strong) UIBezierPath *bezierPath;

//起点
@property (nonatomic, assign) CGPoint beginPoint;
//终点
@property (nonatomic, assign) CGPoint endPoint;

@end

////////////////////////////////////////////////////////////////////



@interface LSCanvas : UIView

- (void)setBrush:(LSBrush *)brush;

@end
/////////////////////////////////////////////////////////////////////

@interface LSDrawView : UIView

//颜色
@property (strong, nonatomic) UIColor *brushColor;
//是否是橡皮擦
@property (assign, nonatomic) BOOL isEraser;
//宽度
@property (assign, nonatomic) NSInteger brushWidth;
//形状
@property (assign, nonatomic) LSShapeType shapeType;
//背景图
@property (assign, nonatomic) UIImage *backgroundImage;

//撤销
- (void)unDo;
//重做
- (void)reDo;
//保存到相册
- (void)save;
//清除绘制
- (void)clean;


//录制脚本
- (void)testRecToFile;
//绘制脚本
- (void)testPlayFromFile;

@end

/////////////////////////////////////////////////////////////////////////////////////
@implementation LSBrush


@end

/////////////////////////////////////////////////////////////////////////////////////
@implementation LSCanvas

+ (Class)layerClass
{
    return ([CAShapeLayer class]);
}

- (void)setBrush:(LSBrush *)brush
{
    CAShapeLayer *shapeLayer = (CAShapeLayer *)self.layer;
    
    shapeLayer.strokeColor = brush.brushColor.CGColor;
    shapeLayer.fillColor = [UIColor clearColor].CGColor;
    shapeLayer.lineJoin = kCALineJoinRound;
    shapeLayer.lineCap = kCALineCapRound;
    shapeLayer.lineWidth = brush.brushWidth;
    
    if (!brush.isEraser)
    {
        ((CAShapeLayer *)self.layer).path = brush.bezierPath.CGPath;
    }
   
}

@end

/////////////////////////////////////////////////////////////////////////////////////

@interface LSDrawView()
{
    CGPoint pts[5];
    uint ctr;
}

//背景View
@property (nonatomic, strong) UIImageView *bgImgView;
//画板View
@property (nonatomic, strong) LSCanvas *canvasView;
//合成View
@property (nonatomic, strong) UIImageView *composeView;
//画笔容器
@property (nonatomic, strong) NSMutableArray *brushArray;
//撤销容器
@property (nonatomic, strong) NSMutableArray *undoArray;
//重做容器
@property (nonatomic, strong) NSMutableArray *redoArray;


//linyl
//记录脚本用
@property (nonatomic, strong) LSDrawFile *dwawFile;

//每次touchsbegin的时间，后续为计算偏移量用
@property (nonatomic, strong) NSDate *beginDate;

//绘制脚本用
@property (nonatomic, strong) NSMutableArray *recPackageArray;

@end

@implementation LSDrawView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
        
        _brushArray = [NSMutableArray new];
        _undoArray = [NSMutableArray new];
        _redoArray = [NSMutableArray new];
        
        _bgImgView = [UIImageView new];
        _bgImgView.frame = self.bounds;
        [self addSubview:_bgImgView];
        
        _composeView = [UIImageView new];
        _composeView.frame = self.bounds;
        [self addSubview:_composeView];
        
        _canvasView = [LSCanvas new];
        _canvasView.frame = _composeView.bounds;
        
        [_composeView addSubview:_canvasView];
        
        _brushColor = LSDEF_BRUSH_COLOR;
        _brushWidth = LSDEF_BRUSH_WIDTH;
        _isEraser = NO;
        _shapeType = LSDEF_BRUSH_SHAPE;
        
        //linyl
        _dwawFile = [LSDrawFile new];
        _dwawFile.packageArray = [NSMutableArray new];

    }
    return self;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    CGPoint point = [[touches anyObject] locationInView:self];
    
    LSBrush *brush = [LSBrush new];
    brush.brushColor = _brushColor;
    brush.brushWidth = _brushWidth;
    brush.isEraser = _isEraser;
    brush.shapeType = _shapeType;
    brush.beginPoint = point;
    
    brush.bezierPath = [UIBezierPath new];
    [brush.bezierPath moveToPoint:point];
    
    
    [_brushArray addObject:brush];
    
    //每次画线前，都清除重做列表。
    [self cleanRedoArray];
    
    ctr = 0;
    pts[0] = point;
    
    
    //linyl
    _beginDate = [NSDate date];
    
    LSBrushModel *brushModel = [LSBrushModel new];
    brushModel.brushColor = _brushColor;
    brushModel.brushWidth = _brushWidth;
    brushModel.shapeType = _shapeType;
    brushModel.isEraser = _isEraser;
    brushModel.beginPoint = [LSPointModel new];
    brushModel.beginPoint.xPoint = point.x;
    brushModel.beginPoint.yPoint = point.y;
    brushModel.beginPoint.timeOffset = 0;
    

    [self addModelToPackage:brushModel];
    //linyl

}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    CGPoint point = [[touches anyObject] locationInView:self];
    
    LSBrush *brush = [_brushArray lastObject];
    
    //linyl
    LSDrawPackage *drawPackage = [_dwawFile.packageArray lastObject];
    
    LSPointModel *pointModel = [LSPointModel new];
    pointModel.xPoint = point.x;
    pointModel.yPoint = point.y;
    pointModel.timeOffset = fabs(_beginDate.timeIntervalSinceNow);
    
    [drawPackage.pointOrBrushArray addObject:pointModel];
    //linyl
    
    if (_isEraser)
    {
        [brush.bezierPath addLineToPoint:point];
        [self setEraserMode:brush];
    }
    else
    {
        switch (_shapeType)
        {
            case LSShapeCurve:
//                [brush.bezierPath addLineToPoint:point];
            
                ctr++;
                pts[ctr] = point;
                if (ctr == 4)
                {
                    pts[3] = CGPointMake((pts[2].x + pts[4].x)/2.0, (pts[2].y + pts[4].y)/2.0);
                    
                    [brush.bezierPath moveToPoint:pts[0]];
                    [brush.bezierPath addCurveToPoint:pts[3] controlPoint1:pts[1] controlPoint2:pts[2]];
                    pts[0] = pts[3];
                    pts[1] = pts[4];
                    ctr = 1;
                }
                
                break;
                
            case LSShapeLine:
                [brush.bezierPath removeAllPoints];
                [brush.bezierPath moveToPoint:brush.beginPoint];
                [brush.bezierPath addLineToPoint:point];
                break;
                
                case LSShapeEllipse:
                brush.bezierPath = [UIBezierPath bezierPathWithOvalInRect:[self getRectWithStartPoint:brush.beginPoint endPoint:point]];
                break;
                
            case LSShapeRect:
                
                brush.bezierPath = [UIBezierPath bezierPathWithRect:[self getRectWithStartPoint:brush.beginPoint endPoint:point]];
                break;
                
            default:
                break;
        }
    }
    
    //在画布上画线
    [_canvasView setBrush:brush];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    uint count = ctr;
    if (count <= 4 && _shapeType == LSShapeCurve)
    {
        for (int i = 4; i > count; i--)
        {
            [self touchesMoved:touches withEvent:event];
        }
        ctr = 0;
    }
    else
    {
        [self touchesMoved:touches withEvent:event];
    }
    
//    CGPoint point = [[touches anyObject] locationInView:self];
//    LSBrush *brush = [_brushArray lastObject];
//    brush.endPoint = point;
    
    //画布view与合成view 合成为一张图（使用融合卡）
    UIImage *img = [self composeBrushToImage];
    //清空画布
    [_canvasView setBrush:nil];
    //保存到存储，撤销用。
    [self saveTempPic:img];
    
    
    //linyl
    CGPoint point = [[touches anyObject] locationInView:self];
    
    LSBrushModel *brushModel = [LSBrushModel new];
    brushModel.brushColor = _brushColor;
    brushModel.brushWidth = _brushWidth;
    brushModel.shapeType = _shapeType;
    brushModel.isEraser = _isEraser;
    brushModel.endPoint = [LSPointModel new];
    brushModel.endPoint.xPoint = point.x;
    brushModel.endPoint.yPoint = point.y;
    brushModel.endPoint.timeOffset = fabs(_beginDate.timeIntervalSinceNow);;
   
    LSDrawPackage *drawPackage = [_dwawFile.packageArray lastObject];
    
    [drawPackage.pointOrBrushArray addObject:brushModel];
    
//    NSLog(@"end-offset:%f",brushModel.endPoint.timeOffset);
    //linyl
    
    
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self touchesEnded:touches withEvent:event];
}

- (CGRect)getRectWithStartPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint
{
    CGFloat x = startPoint.x <= endPoint.x ? startPoint.x: endPoint.x;
    CGFloat y = startPoint.y <= endPoint.y ? startPoint.y : endPoint.y;
    CGFloat width = fabs(startPoint.x - endPoint.x);
    CGFloat height = fabs(startPoint.y - endPoint.y);
    
    return CGRectMake(x , y , width, height);
}

- (UIImage *)composeBrushToImage
{
    UIGraphicsBeginImageContextWithOptions(self.frame.size, NO, 0.0);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    [_composeView.layer renderInContext:context];
    
    UIImage *getImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    _composeView.image = getImage;
    
    return getImage;
    
}

- (void)save
{
    UIGraphicsBeginImageContextWithOptions(self.frame.size, NO, 0.0);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [self.layer renderInContext:context];
    
    UIImage *getImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIImageWriteToSavedPhotosAlbum(getImage, nil, nil, nil);
    UIGraphicsEndImageContext();
    
    //linyl
    LSActionModel *actionModel = [LSActionModel new];
    actionModel.ActionType = LSDrawActionSave;
    
    [self addModelToPackage:actionModel];
    //linyl
}

- (void)setEraserMode:(LSBrush*)brush
{
    UIGraphicsBeginImageContextWithOptions(self.frame.size, false, 0);
    
    [_composeView.image drawInRect:self.bounds];
    
    [[UIColor clearColor] set];
    
    brush.bezierPath.lineWidth = _brushWidth;
    [brush.bezierPath strokeWithBlendMode:kCGBlendModeClear alpha:1.0];
    
    [brush.bezierPath stroke];
    
    _composeView.image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
}




- (void)clean
{
    _composeView.image = nil;
    
    [_brushArray removeAllObjects];
    
    //删除存储的文件
    [self cleanUndoArray];
    [self cleanRedoArray];
    
    
    //linyl
    LSActionModel *actionModel = [LSActionModel new];
    actionModel.ActionType = LSDrawActionClean;
    
    [self addModelToPackage:actionModel];
    //linyl
}

- (void)saveTempPic:(UIImage*)img
{
    if (img)
    {
        //这里切换线程处理
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            NSDate *date = [NSDate date];
            NSDateFormatter *dateformatter = [[NSDateFormatter alloc] init];
            [dateformatter setDateFormat:@"HHmmssSSS"];
            NSString *now = [dateformatter stringFromDate:date];
            
            NSString *picPath = [NSString stringWithFormat:@"%@%@",[NSHomeDirectory() stringByAppendingFormat:@"/tmp/"], now];
            NSLog(@"存贮于   = %@",picPath);
            
            BOOL bSucc = NO;
            NSData *imgData = UIImagePNGRepresentation(img);
            
            
            if (imgData)
            {
                bSucc = [imgData writeToFile:picPath atomically:YES];
            }
            
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (bSucc)
                {
                    [_undoArray addObject:picPath];
                }
                
            });
        });
    }
    
}

- (void)unDo
{
    if (_undoArray.count > 0)
    {
        NSString *lastPath = [_undoArray lastObject];
        
        [_undoArray removeLastObject];
        
        [_redoArray addObject:lastPath];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
           
            UIImage *unDoImage = nil;
            if (_undoArray.count > 0)
            {
                NSString *unDoPicStr = [_undoArray lastObject];
                NSData *imgData = [NSData dataWithContentsOfFile:unDoPicStr];
                if (imgData)
                {
                    unDoImage = [UIImage imageWithData:imgData];
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                _composeView.image = unDoImage;
                
            });
        });
        
        //linyl
        LSActionModel *actionModel = [LSActionModel new];
        actionModel.ActionType = LSDrawActionUndo;
        
        [self addModelToPackage:actionModel];
        //linyl
    }
}

- (void)reDo
{
    if (_redoArray.count > 0)
    {
        NSString *lastPath = [_redoArray lastObject];
        [_redoArray removeLastObject];
        
        [_undoArray addObject:lastPath];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            UIImage *unDoImage = nil;
            NSData *imgData = [NSData dataWithContentsOfFile:lastPath];
            if (imgData)
            {
                unDoImage = [UIImage imageWithData:imgData];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (unDoImage)
                {
                    _composeView.image = unDoImage;
                }
            });
            
        });
        
        //linyl
        LSActionModel *actionModel = [LSActionModel new];
        actionModel.ActionType = LSDrawActionRedo;
        
        [self addModelToPackage:actionModel];
        //linyl
    }
}

- (void)deleteTempPic:(NSString *)picPath
{
    NSFileManager* fileManager=[NSFileManager defaultManager];
     [fileManager removeItemAtPath:picPath error:nil];
}

- (void)cleanUndoArray
{
    for(NSString *picPath in _undoArray)
    {
        [self deleteTempPic:picPath];
    }
    
    [_undoArray removeAllObjects];
}

- (void)cleanRedoArray
{
    for(NSString *picPath in _redoArray)
    {
        [self deleteTempPic:picPath];
    }
    
    [_redoArray removeAllObjects];
}

- (void)dealloc
{
    [self clean];
}

- (void)setBackgroundImage:(UIImage *)backgroundImage
{
    if (backgroundImage)
    {
        _bgImgView.image = backgroundImage;
    }
}

- (void)layoutSubviews
{
    _bgImgView.frame = self.bounds;
    _composeView.frame = self.bounds;
    _canvasView.frame = self.bounds;
}



//linyl
- (void)drawNextPackage
{
    if(!_recPackageArray)
    {
        NSString *filePath = [NSString stringWithFormat:@"%@%@",NSTemporaryDirectory(), @"drawFile"];
        LSDrawFile *drawFile = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
        if (drawFile)
        {
            _recPackageArray = drawFile.packageArray;
        }
    }
    
    if (_recPackageArray.count > 0)
    {
        LSDrawPackage *pack = [_recPackageArray firstObject];
        [_recPackageArray removeObjectAtIndex:0];
        
        for (LSDrawModel *drawModel in pack.pointOrBrushArray)
        {
            if (drawModel)
            {
                
//                dispatch_async(dispatch_get_main_queue(), ^{
                
                    double packageOffset = 0.0;
                    if ([drawModel isKindOfClass:[LSPointModel class]])
                    {
                        LSPointModel *pointModel = (LSPointModel *)drawModel;
                        [self performSelector:@selector(drawWithPointModel:) withObject:drawModel afterDelay:pointModel.timeOffset];
                    }
                    else if([drawModel isKindOfClass:[LSBrushModel class]])
                    {
                        LSBrushModel *brushModel = (LSBrushModel*)drawModel;
                        
                        if (brushModel.beginPoint)
                        {
                            packageOffset = brushModel.beginPoint.timeOffset;
                        }
                        else
                        {
                            packageOffset = brushModel.endPoint.timeOffset;
                        }
                        [self performSelector:@selector(drawWithBrushModel:) withObject:drawModel afterDelay:packageOffset];
                    }
                    else if([drawModel isKindOfClass:[LSActionModel class]])
                    {
                        LSActionModel *actionModel = (LSActionModel*)drawModel;
                        switch (actionModel.ActionType)
                        {
                            case LSDrawActionRedo:
                                [self performSelector:@selector(actionReDo) withObject:nil afterDelay:0.5];
                                break;
                                
                            case LSDrawActionUndo:
                                [self performSelector:@selector(actionUnDo) withObject:nil afterDelay:0.5];
                                break;
                            case LSDrawActionSave:
                                [self performSelector:@selector(actionSave) withObject:nil afterDelay:0.5];
                                break;
                            case LSDrawActionClean:
                                [self performSelector:@selector(actionClean) withObject:nil afterDelay:0.5];
                                break;
                                
                            default:
                                break;
                        }
                    }
                    
                
//                });
                
                
            }
        }
    }
}

- (void)drawWithBrushModel:(LSDrawModel*)drawModel
{
    LSBrushModel *brushModel = (LSBrushModel*)drawModel;
    if (brushModel.beginPoint)
    {
        [self setDrawingBrush:brushModel];
        [self drawBeginPoint:CGPointMake(brushModel.beginPoint.xPoint, brushModel.beginPoint.yPoint)];
    }
    else
    {
        [self drawEndPoint:CGPointMake(brushModel.endPoint.xPoint, brushModel.endPoint.yPoint)];
    }
}


- (void)drawWithPointModel:(LSDrawModel*)drawModel
{
    LSPointModel *pointModel = (LSPointModel*)drawModel;
    [self drawMovePoint:CGPointMake(pointModel.xPoint, pointModel.yPoint)];
}

- (void)setDrawingBrush:(LSBrushModel*) brushModel
{

    if (brushModel)
    {
        _brushColor = brushModel.brushColor;
        _brushWidth = brushModel.brushWidth;
        _shapeType  = brushModel.shapeType;
        _isEraser   = brushModel.isEraser;
    }

}

- (void)drawBeginPoint:(CGPoint) point
{
//    NSLog(@"drawBeginPoint");
    LSBrush *brush = [LSBrush new];
    brush.brushColor = _brushColor;
    brush.brushWidth = _brushWidth;
    brush.isEraser = _isEraser;
    brush.shapeType = _shapeType;
    brush.beginPoint = point;
    
    brush.bezierPath = [UIBezierPath new];
    [brush.bezierPath moveToPoint:point];
    
    
    [_brushArray addObject:brush];
    
    //每次画线前，都清除重做列表。
//    [self cleanRedoArray];
    
    ctr = 0;
    pts[0] = point;
    
    
}

- (void)drawMovePoint:(CGPoint) point
{
    LSBrush *brush = [_brushArray lastObject];
    
    if (_isEraser)
    {
        [brush.bezierPath addLineToPoint:point];
        [self setEraserMode:brush];
    }
    else
    {
        switch (_shapeType)
        {
            case LSShapeCurve:
                
                ctr++;
                pts[ctr] = point;
                if (ctr == 4)
                {
                    pts[3] = CGPointMake((pts[2].x + pts[4].x)/2.0, (pts[2].y + pts[4].y)/2.0);
                    
                    [brush.bezierPath moveToPoint:pts[0]];
                    [brush.bezierPath addCurveToPoint:pts[3] controlPoint1:pts[1] controlPoint2:pts[2]];
                    pts[0] = pts[3];
                    pts[1] = pts[4];
                    ctr = 1;
                }
                
                break;
                
            case LSShapeLine:
                [brush.bezierPath removeAllPoints];
                [brush.bezierPath moveToPoint:brush.beginPoint];
                [brush.bezierPath addLineToPoint:point];
                break;
                
            case LSShapeEllipse:
                brush.bezierPath = [UIBezierPath bezierPathWithOvalInRect:[self getRectWithStartPoint:brush.beginPoint endPoint:point]];
                break;
                
            case LSShapeRect:
                
                brush.bezierPath = [UIBezierPath bezierPathWithRect:[self getRectWithStartPoint:brush.beginPoint endPoint:point]];
                break;
                
            default:
                break;
        }
    }
    
    //在画布上画线
    [_canvasView setBrush:brush];
}

- (void)drawEndPoint:(CGPoint) point
{
    
    uint count = ctr;
    if (count <= 4 && _shapeType == LSShapeCurve)
    {
        for (int i = 4; i > count; i--)
        {
            [self drawMovePoint:point];
        }
        ctr = 0;
    }
    else
    {
        [self drawMovePoint:point];
    }
    
    //画布view与合成view 合成为一张图（使用融合卡）
    UIImage *img = [self composeBrushToImage];
    //清空画布
    [_canvasView setBrush:nil];
    //保存到存储，撤销用。
    [self saveTempPic:img];
    
    [self drawNextPackage];
}

//录制脚本
- (void)testRecToFile
{
    NSString *filePath = [NSString stringWithFormat:@"%@%@",NSTemporaryDirectory(), @"drawFile"];
    
    NSLog(@"drawfile:%@",filePath);
    
    BOOL bRet = [NSKeyedArchiver archiveRootObject:_dwawFile toFile:filePath];
    
    if (bRet)
    {
        NSLog(@"archive Succ");
    }

}
//绘制脚本
- (void)testPlayFromFile
{
    [self drawNextPackage];
}

- (void)addModelToPackage:(LSDrawModel*)drawModel
{
    LSDrawPackage *drawPackage = [LSDrawPackage new];
    drawPackage.pointOrBrushArray = [NSMutableArray new];
    
    [drawPackage.pointOrBrushArray addObject:drawModel];
    [_dwawFile.packageArray addObject:drawPackage];
}

- (void)actionUnDo
{
    if (_undoArray.count > 0)
    {
        NSString *lastPath = [_undoArray lastObject];
        
        [_undoArray removeLastObject];
        
        [_redoArray addObject:lastPath];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            UIImage *unDoImage = nil;
            if (_undoArray.count > 0)
            {
                NSString *unDoPicStr = [_undoArray lastObject];
                NSData *imgData = [NSData dataWithContentsOfFile:unDoPicStr];
                if (imgData)
                {
                    unDoImage = [UIImage imageWithData:imgData];
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                _composeView.image = unDoImage;
                
            });
        });
        
        [self drawNextPackage];
    }
}

- (void)actionReDo
{
    if (_redoArray.count > 0)
    {
        NSString *lastPath = [_redoArray lastObject];
        [_redoArray removeLastObject];
        
        [_undoArray addObject:lastPath];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            UIImage *unDoImage = nil;
            NSData *imgData = [NSData dataWithContentsOfFile:lastPath];
            if (imgData)
            {
                unDoImage = [UIImage imageWithData:imgData];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (unDoImage)
                {
                    _composeView.image = unDoImage;
                }
            });
            
        });
        
        
        [self drawNextPackage];
    }
}
- (void)actionSave
{
    UIGraphicsBeginImageContextWithOptions(self.frame.size, NO, 0.0);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [self.layer renderInContext:context];
    
    UIImage *getImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIImageWriteToSavedPhotosAlbum(getImage, nil, nil, nil);
    UIGraphicsEndImageContext();
    
    [self drawNextPackage];
}

- (void)actionClean
{
    _composeView.image = nil;
    
    [_brushArray removeAllObjects];
    
    //删除存储的文件
    [self cleanUndoArray];
    [self cleanRedoArray];
    
    
    //linyl
    [self drawNextPackage];
    
}

@end

@interface TestDrawViewController () {
    LSDrawView *drawView;
}

@end

@implementation TestDrawViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    drawView = [[LSDrawView alloc] initWithFrame:self.view.bounds];
    drawView.brushColor = [UIColor blueColor];
    drawView.brushWidth = 3;
    drawView.shapeType = LSShapeCurve;
    
    drawView.backgroundImage = [TestBundle imageNamed:@"public_picture"];
    
    [self.view addSubview:drawView];
    
    //工具栏
    
    UIButton *btnUndo = [UIButton buttonWithType:UIButtonTypeCustom];
    btnUndo.backgroundColor = [UIColor orangeColor];
    btnUndo.frame = CGRectMake(20, 20, 60, 20);
    [btnUndo setTitle:@"撤销" forState:UIControlStateNormal];
    
    [btnUndo addTarget:self action:@selector(btnUndoClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:btnUndo];
    
    
    UIButton *btnRedo = [UIButton buttonWithType:UIButtonTypeCustom];
    btnRedo.backgroundColor = [UIColor orangeColor];
    btnRedo.frame = CGRectMake(100, 20, 60, 20);
    [btnRedo setTitle:@"重做" forState:UIControlStateNormal];
    
    [btnRedo addTarget:self action:@selector(btnRedoClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:btnRedo];
    
    
    UIButton *btnSave = [UIButton buttonWithType:UIButtonTypeCustom];
    btnSave.backgroundColor = [UIColor orangeColor];
    btnSave.frame = CGRectMake(180, 20, 60, 20);
    [btnSave setTitle:@"保存" forState:UIControlStateNormal];
    
    [btnSave addTarget:self action:@selector(btnSaveClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:btnSave];
    
    UIButton *btnClean = [UIButton buttonWithType:UIButtonTypeCustom];
    btnClean.backgroundColor = [UIColor orangeColor];
    btnClean.frame = CGRectMake(260, 20, 60, 20);
    [btnClean setTitle:@"清除" forState:UIControlStateNormal];
    
    [btnClean addTarget:self action:@selector(btnCleanClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:btnClean];
    
    
    
    UIButton *btnCurve = [UIButton buttonWithType:UIButtonTypeCustom];
    btnCurve.backgroundColor = [UIColor orangeColor];
    btnCurve.frame = CGRectMake(20, 50, 60, 20);
    [btnCurve setTitle:@"曲线" forState:UIControlStateNormal];
    
    [btnCurve addTarget:self action:@selector(btnCurveClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:btnCurve];
    
    
    UIButton *btnLine = [UIButton buttonWithType:UIButtonTypeCustom];
    btnLine.backgroundColor = [UIColor orangeColor];
    btnLine.frame = CGRectMake(100, 50, 60, 20);
    [btnLine setTitle:@"直线" forState:UIControlStateNormal];
    
    [btnLine addTarget:self action:@selector(btnLineClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:btnLine];
    
    
    UIButton *btnEllipse = [UIButton buttonWithType:UIButtonTypeCustom];
    btnEllipse.backgroundColor = [UIColor orangeColor];
    btnEllipse.frame = CGRectMake(180, 50, 60, 20);
    [btnEllipse setTitle:@"椭圆" forState:UIControlStateNormal];
    
    [btnEllipse addTarget:self action:@selector(btnEllipseClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:btnEllipse];
    
    
    UIButton *btnRect = [UIButton buttonWithType:UIButtonTypeCustom];
    btnRect.backgroundColor = [UIColor orangeColor];
    btnRect.frame = CGRectMake(260, 50, 60, 20);
    [btnRect setTitle:@"矩形" forState:UIControlStateNormal];
    
    [btnRect addTarget:self action:@selector(btnRectClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:btnRect];
    
    
    UIButton *btnRec = [UIButton buttonWithType:UIButtonTypeCustom];
    btnRec.backgroundColor = [UIColor orangeColor];
    btnRec.frame = CGRectMake(20, 80, 60, 20);
    [btnRec setTitle:@"录制" forState:UIControlStateNormal];
    
    [btnRec addTarget:self action:@selector(btnRecClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:btnRec];
    
    UIButton *btnPlay = [UIButton buttonWithType:UIButtonTypeCustom];
    btnPlay.backgroundColor = [UIColor orangeColor];
    btnPlay.frame = CGRectMake(100, 80, 60, 20);
    [btnPlay setTitle:@"绘制" forState:UIControlStateNormal];
    
    [btnPlay addTarget:self action:@selector(btnPlayClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:btnPlay];
    
    UIButton *btnEraser = [UIButton buttonWithType:UIButtonTypeCustom];
    btnEraser.backgroundColor = [UIColor orangeColor];
    btnEraser.frame = CGRectMake(180, 80, 60, 20);
    [btnEraser setTitle:@"橡皮擦" forState:UIControlStateNormal];
    [btnEraser setTitle:@"画笔" forState:UIControlStateSelected];
    
    [btnEraser addTarget:self action:@selector(btnEraserClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:btnEraser];
    
    
}

- (void)btnRecClicked:(id)sender
{
    [drawView testRecToFile];
}

- (void)btnPlayClicked:(id)sender
{
    [drawView testPlayFromFile];
}


- (void)btnSaveClicked:(id)sender
{
    [drawView save];
}

- (void)btnCleanClicked:(id)sender
{
    [drawView clean];
}


- (void)btnRectClicked:(id)sender
{
    drawView.shapeType = LSShapeRect;
}

- (void)btnEllipseClicked:(id)sender
{
    drawView.shapeType = LSShapeEllipse;
}

- (void)btnLineClicked:(id)sender
{
    drawView.shapeType = LSShapeLine;
}

- (void)btnCurveClicked:(id)sender
{
    drawView.shapeType = LSShapeCurve;
}

- (void)btnEraserClicked:(id)sender
{
    UIButton *btn = (UIButton*)sender;
    if (btn.selected)
    {
        btn.selected = NO;
        
        //使用画笔
        drawView.isEraser = NO;
    }
    else
    {
        btn.selected = YES;
        
        //使用橡皮擦
        drawView.isEraser = YES;
    }
}

- (void)btnUndoClicked:(id)sender
{
    [drawView unDo];
}

- (void)btnRedoClicked:(id)sender
{
    [drawView reDo];
}

@end
