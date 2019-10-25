//
//  WHBreathView.m
//  WHBreathView
//
//  Created by huweinan on 2019/10/25.
//  Copyright © 2019 hwn. All rights reserved.
//

#import "WHBreathView.h"
#define HEXCOLOR(hex) [UIColor colorWithRed:((float)((hex & 0xFF0000) >> 16)) / 255.0 green:((float)((hex & 0xFF00) >> 8)) / 255.0 blue:((float)(hex & 0xFF)) / 255.0 alpha:1]

#define SCALE_W(X)  (X/209.0*self.frame.size.width)

@interface WHBreathView()<CAAnimationDelegate>
@property(nonatomic,strong) CAGradientLayer *gradientlayer;
@property(nonatomic,strong) CAShapeLayer *shapeLayer;
@property(nonatomic,strong) CAShapeLayer *moveBallLayer;
@property(nonatomic,strong) CALayer *moveBallContainerLayer;
@property(nonatomic,assign) CATransform3D moveBallContainerOriginTransform3D;

//@property(nonatomic,strong) CATextLayer *centerLayer;
@property(nonatomic,strong) NSMutableArray <CATextLayer*>*labelLayerArray;

@property(nonatomic,strong) NSMutableArray *ballArray;
@property(nonatomic,strong) NSMutableArray *grayLineArray;
@property(nonatomic,assign) BOOL isAnimation;

@property(nonatomic,strong) NSTimer *timer;

@end
@implementation WHBreathView
-(instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self setUpView];
        
        self.oneCircleDuration = 8;
    }
    return self;
}
//设置label
-(void)setUpLabel{
    for (CALayer *layer in self.labelLayerArray) {
        [layer removeAllAnimations];
        [layer removeFromSuperlayer];
    }
    if (self.breathType == TwoPoint && self.breathWordTipStringArray.count!=2) {
        _breathWordTipStringArray = @[@"breath in",@"breath out"];
    }else if(self.breathType == ThreePoint && self.breathWordTipStringArray.count!=3){
        _breathWordTipStringArray = @[@"breath in",@"hold",@"breath out"];
    }else if(self.breathType == FourPoint && self.breathWordTipStringArray.count!=4){
        _breathWordTipStringArray = @[@"breath in",@"hold",@"breath out",@"hold"];
    }
    self.labelLayerArray = [NSMutableArray array];
    for (NSInteger i = 0; i< self.breathWordTipStringArray.count; i++) {
        
        CATextLayer *centerLayer = [CATextLayer layer];
        
        centerLayer.string = self.breathWordTipStringArray[i];
//        centerLayer.font = CGFontCreateWithFontName((__bridge CFStringRef)(@"Georgia"));
        centerLayer.fontSize = SCALE_W(20);
        centerLayer.frame = CGRectMake(0, (self.bounds.size.height-centerLayer.fontSize*1.5)/2.0, self.bounds.size.width, centerLayer.fontSize*1.5);
        centerLayer.backgroundColor = [UIColor clearColor].CGColor;
        centerLayer.foregroundColor = [UIColor whiteColor].CGColor;         //文字颜色，普通字符串时可以使用该属性
        centerLayer.wrapped = YES;                               //为yes时自动换行
        centerLayer.alignmentMode = kCAAlignmentCenter;
        centerLayer.truncationMode = kCATruncationMiddle;
        centerLayer.contentsScale = [UIScreen mainScreen].scale;  //按当前的屏幕分辨率显示   否则字体会模糊
        centerLayer.foregroundColor = [[UIColor whiteColor]colorWithAlphaComponent:0].CGColor;
        [self.layer addSublayer:centerLayer];
        [self.labelLayerArray addObject:centerLayer];
    }

}
//根据配置设置view
-(void)setUpView{
    for (CALayer *layer in self.grayLineArray) {
        [layer removeFromSuperlayer];
    }
    self.grayLineArray = [NSMutableArray array];
    
    for (CALayer *layer in self.ballArray) {
        [layer removeFromSuperlayer];
    }
    self.ballArray = [NSMutableArray array];
    
    CGFloat lineWidth = SCALE_W(5.0);

    if (self.shapeLayer == nil) {
        self.shapeLayer = [CAShapeLayer layer];
        self.shapeLayer.frame = self.bounds;
        UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(self.bounds.size.width/2.0, self.bounds.size.height/2.0) radius:self.frame.size.width/2.0-lineWidth/2.0 startAngle:0 endAngle:4*M_PI_2 clockwise:YES];
        self.shapeLayer.path = path.CGPath;
        self.shapeLayer.lineWidth = lineWidth;
        self.shapeLayer.strokeColor = [UIColor whiteColor].CGColor;
        self.shapeLayer.fillColor = [UIColor clearColor].CGColor;
        
        CAShapeLayer *shapeInLayer = [CAShapeLayer layer];
        shapeInLayer.frame = self.bounds;
        
        UIBezierPath *pathIn = [UIBezierPath bezierPathWithArcCenter:CGPointMake(self.bounds.size.width/2.0, self.bounds.size.height/2.0) radius:(self.frame.size.width/2.0-SCALE_W(20)) startAngle:0 endAngle:4*M_PI_2 clockwise:YES];
        shapeInLayer.path = pathIn.CGPath;
        shapeInLayer.lineWidth = 1;
        shapeInLayer.fillColor = [UIColor whiteColor].CGColor;
        shapeInLayer.strokeColor = [UIColor whiteColor].CGColor;
        [self.shapeLayer addSublayer:shapeInLayer];
        NSMutableArray *colors = [NSMutableArray array];
        if (self.breathViewColorArray.count == 0) {
            self.breathViewColorArray = @[HEXCOLOR(0xe71995),HEXCOLOR(0xd611e7)];
        }
        for (UIColor *color in self.breathViewColorArray) {
            [colors addObject:(id)color.CGColor];
        }
        self.gradientlayer = [CAGradientLayer layer];
        self.gradientlayer.frame = self.bounds;
        self.gradientlayer.colors = colors;
        self.gradientlayer.startPoint = CGPointMake(0, 1);
        self.gradientlayer.endPoint = CGPointMake(1, 0);
        self.gradientlayer.mask = self.shapeLayer;
        [self.layer addSublayer:self.gradientlayer];
    }
    
    //画背景阴影和节点球
    if (self.ballArray == nil) {
        self.ballArray = [NSMutableArray array];
    }
    if (self.grayLineArray == nil) {
        self.grayLineArray = [NSMutableArray array];
    }
    NSArray *pointAngleArray = nil;
    if (self.breathType == ThreePoint) {
        if (self.breathPointAangleArray == nil && self.breathPointAangleArray.count == 3) {
            pointAngleArray = [self.breathPointAangleArray copy];
        }else{
            pointAngleArray = @[@(0),@(0.7*M_PI),@(1.3*M_PI)];
        }
        //灰阴影
        CAShapeLayer *shapeLayer = [CAShapeLayer layer];
        shapeLayer.frame = self.bounds;
        UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(self.bounds.size.width/2.0, self.bounds.size.height/2.0) radius:self.frame.size.width/2.0-lineWidth/2.0 startAngle:[pointAngleArray[1] floatValue]-M_PI_2 endAngle:[pointAngleArray[2] floatValue]-M_PI_2 clockwise:YES];
        shapeLayer.path = path.CGPath;
        shapeLayer.lineWidth = lineWidth;
        shapeLayer.strokeColor = HEXCOLOR(0xd2d2d2).CGColor;
        shapeLayer.fillColor = [UIColor clearColor].CGColor;
        [self.layer addSublayer:shapeLayer];
        [self.grayLineArray addObject:shapeLayer];
        //画球
        for (NSNumber *angle in pointAngleArray) {
            CALayer *layer = [CALayer layer];
            layer.frame = self.bounds;
            layer.backgroundColor = [UIColor clearColor].CGColor;
            CAShapeLayer *pointLayer = [CAShapeLayer layer];
            CGFloat ballRadius = SCALE_W(4);
            pointLayer.frame = CGRectMake(self.frame.size.width/2.0-ballRadius, 0+lineWidth/2-ballRadius, ballRadius*2, ballRadius*2);
            UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:pointLayer.bounds];
            pointLayer.fillColor = (self.staticBallColor?self.staticBallColor:[UIColor whiteColor]).CGColor;
            pointLayer.path = path.CGPath;
            [layer addSublayer:pointLayer];
            layer.transform = CATransform3DMakeRotation(angle.floatValue, 0, 0, 1);
            [self.layer addSublayer:layer];
            [self.ballArray addObject:layer];
        }
    }else if (self.breathType == TwoPoint) {
        if (self.breathPointAangleArray == nil && self.breathPointAangleArray.count == 2) {
            pointAngleArray = [self.breathPointAangleArray copy];
        }else{
            pointAngleArray = @[@(0),@(M_PI)];
        }
        //画球
        for (NSNumber *angle in pointAngleArray) {
            CALayer *layer = [CALayer layer];
            layer.frame = self.bounds;
            layer.backgroundColor = [UIColor clearColor].CGColor;
            CAShapeLayer *pointLayer = [CAShapeLayer layer];
            CGFloat ballRadius = 6;
            pointLayer.frame = CGRectMake(self.frame.size.width/2.0-ballRadius, 0+lineWidth/2-ballRadius, ballRadius*2, ballRadius*2);
            UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:pointLayer.bounds];
            pointLayer.fillColor = (self.staticBallColor?self.staticBallColor:[UIColor whiteColor]).CGColor;
            pointLayer.path = path.CGPath;
            [layer addSublayer:pointLayer];
            layer.transform = CATransform3DMakeRotation(angle.floatValue, 0, 0, 1);
            [self.layer addSublayer:layer];
            [self.ballArray addObject:layer];
        }
    }else if (self.breathType == FourPoint) {
        if (self.breathPointAangleArray == nil && self.breathPointAangleArray.count == 4) {
            pointAngleArray = [self.breathPointAangleArray copy];
        }else{
            pointAngleArray = @[@(0),@(0.5*M_PI),@(1*M_PI),@(1.5*M_PI)];
        }
        //灰阴影
        CAShapeLayer *shapeLayer = [CAShapeLayer layer];
        shapeLayer.frame = self.bounds;
        UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(self.bounds.size.width/2.0, self.bounds.size.height/2.0) radius:self.frame.size.width/2.0-lineWidth/2.0 startAngle:[pointAngleArray[1] floatValue]-M_PI_2 endAngle:[pointAngleArray[2] floatValue]-M_PI_2 clockwise:YES];
        shapeLayer.path = path.CGPath;
        shapeLayer.lineWidth = lineWidth;
        shapeLayer.strokeColor = HEXCOLOR(0xd2d2d2).CGColor;
        shapeLayer.fillColor = [UIColor clearColor].CGColor;
        [self.layer addSublayer:shapeLayer];
        [self.grayLineArray addObject:shapeLayer];
        
        CAShapeLayer *shapeLayer2 = [CAShapeLayer layer];
        shapeLayer2.frame = self.bounds;
        UIBezierPath *path2 = [UIBezierPath bezierPathWithArcCenter:CGPointMake(self.bounds.size.width/2.0, self.bounds.size.height/2.0) radius:self.frame.size.width/2.0-lineWidth/2.0 startAngle:[pointAngleArray[3] floatValue]-M_PI_2 endAngle:[pointAngleArray[0] floatValue]+M_PI*2-M_PI_2 clockwise:YES];
        shapeLayer2.path = path2.CGPath;
        shapeLayer2.lineWidth = lineWidth;
        shapeLayer2.strokeColor = HEXCOLOR(0xd2d2d2).CGColor;
        shapeLayer2.fillColor = [UIColor clearColor].CGColor;
        [self.layer addSublayer:shapeLayer2];
        [self.grayLineArray addObject:shapeLayer2];
        
        //画球
        for (NSNumber *angle in pointAngleArray) {
            CALayer *layer = [CALayer layer];
            layer.frame = self.bounds;
            layer.backgroundColor = [UIColor clearColor].CGColor;
            CAShapeLayer *pointLayer = [CAShapeLayer layer];
            CGFloat ballRadius = 6;
            pointLayer.frame = CGRectMake(self.frame.size.width/2.0-ballRadius, 0+lineWidth/2-ballRadius, ballRadius*2, ballRadius*2);
            UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:pointLayer.bounds];
            pointLayer.fillColor = (self.staticBallColor?self.staticBallColor:[UIColor whiteColor]).CGColor;
            pointLayer.path = path.CGPath;
            [layer addSublayer:pointLayer];
            layer.transform = CATransform3DMakeRotation(angle.floatValue, 0, 0, 1);
            [self.layer addSublayer:layer];
            [self.ballArray addObject:layer];
        }
    }
    _breathPointAangleArray = pointAngleArray;

    //画运动球
    if (self.moveBallContainerLayer.superlayer) {
        [self.moveBallContainerLayer removeAllAnimations];
        [self.moveBallContainerLayer removeFromSuperlayer];
        self.moveBallContainerLayer = nil;
    }
    if (self.moveBallContainerLayer == nil){
        self.moveBallContainerLayer = [CALayer layer];
        self.moveBallContainerLayer.frame = self.bounds;
        self.moveBallLayer = [CAShapeLayer layer];
        CGFloat ballRadius = SCALE_W(6);
        self.moveBallLayer.frame = CGRectMake(self.frame.size.width/2.0-ballRadius, 0+lineWidth/2-ballRadius, ballRadius*2, ballRadius*2);
        UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:self.moveBallLayer.bounds];
        self.moveBallLayer.fillColor = (self.moveBallColor?self.moveBallColor:HEXCOLOR(0x00a0e9)).CGColor;
        self.moveBallLayer.path = path.CGPath;
        [self.moveBallContainerLayer addSublayer:self.moveBallLayer];
        self.moveBallContainerOriginTransform3D = self.moveBallContainerLayer.transform;
    }
    if (self.moveBallContainerLayer.superlayer) {
        [self.moveBallContainerLayer removeFromSuperlayer];
    }
    [self.layer addSublayer:self.moveBallContainerLayer];
    
    //设置文本
    [self setUpLabel];
}
-(void)moveBallToAngle:(CGFloat)angle{
    self.moveBallContainerLayer.transform = CATransform3DRotate(self.moveBallContainerOriginTransform3D, angle, 0, 0, 1);
}
-(void)setBreathType:(BreathType)breathType{
    if (_breathType != breathType) {
        _breathType = breathType;
        [self setUpView];
    }
}
-(void)setBreathPointAangleArray:(NSArray<NSNumber *> *)breathPointAangleArray{
    if (_breathPointAangleArray != breathPointAangleArray) {
        _breathPointAangleArray = breathPointAangleArray;
        [self setUpView];
    }
}
-(void)setBreathViewColorArray:(NSArray<UIColor *> *)breathViewColorArray{
    if (_breathViewColorArray != breathViewColorArray) {
        _breathViewColorArray = breathViewColorArray;
        NSMutableArray *colors = [NSMutableArray array];
        if (_breathViewColorArray.count == 0) {
            _breathViewColorArray = @[HEXCOLOR(0xe71995),HEXCOLOR(0xd611e7)];
        }
        for (UIColor *color in self.breathViewColorArray) {
            [colors addObject:(id)color.CGColor];
        }
        self.gradientlayer.colors = colors;

    }
}
-(void)setBreathWordTipStringArray:(NSArray<NSString *> *)breathWordTipStringArray{
    if (_breathWordTipStringArray != breathWordTipStringArray) {
        _breathWordTipStringArray = breathWordTipStringArray;
        [self setUpView];
    }
}
-(void)setMoveBallColor:(UIColor *)moveBallColor{
    if (_moveBallColor != moveBallColor) {
        _moveBallColor = moveBallColor;
        [self setUpView];
    }
}
-(void)setStaticBallColor:(UIColor *)staticBallColor{
    if (_staticBallColor != staticBallColor) {
        _moveBallColor = staticBallColor;
        [self setUpView];
    }
}
//@property(nonatomic,strong) NSArray<NSNumber*>* breathPointAangleArray;
////颜色数组,默认粉色 0xe71995 -> 0xd611e7
//@property(nonatomic,strong) NSArray<UIColor*>* breathViewColorArray;
////运动小球颜色,默认白色
//@property(nonatomic,strong) UIColor* moveBallColor;
////静止小球颜色,默认蓝色 0x00a0e9
//@property(nonatomic,strong) UIColor* staticBallColor;
-(void)startBreath{
    [self endBreath];
    self.isAnimation = YES;
    [self makeAnimation];
//    self.timer = [NSTimer scheduledTimerWithTimeInterval:self.oneCircleDuration target:self selector:@selector(makeAnimation) userInfo:nil repeats:YES];
//    [self.timer fire];
}
-(void)makeAnimation{
    CGFloat repeatCount = MAXFLOAT;
    if (self.breathType == ThreePoint) {
        CABasicAnimation *scaleAnimation1 = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        scaleAnimation1.fromValue = [NSNumber numberWithFloat:0.618];
        scaleAnimation1.toValue = [NSNumber numberWithFloat:1.0];
        scaleAnimation1.fillMode = kCAFillModeForwards;
        CGFloat duration = [self.breathPointAangleArray[1] floatValue]/(M_PI*2) * self.oneCircleDuration;
        scaleAnimation1.duration = duration;
        
        CABasicAnimation *scaleAnimation2 = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        scaleAnimation2.fromValue = [NSNumber numberWithFloat:1.0];
        scaleAnimation2.toValue = [NSNumber numberWithFloat:1.0];
        scaleAnimation2.fillMode = kCAFillModeForwards;
        scaleAnimation2.beginTime = [self.breathPointAangleArray[1] floatValue]/(M_PI*2) * self.oneCircleDuration;
        duration = [self.breathPointAangleArray[2] floatValue]/(M_PI*2) * self.oneCircleDuration - scaleAnimation2.beginTime;
        scaleAnimation2.duration = duration;
        
        CABasicAnimation *scaleAnimation3 = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        scaleAnimation3.fromValue = [NSNumber numberWithFloat:1.0];
        scaleAnimation3.toValue = [NSNumber numberWithFloat:0.618];
        scaleAnimation3.fillMode = kCAFillModeForwards;
        scaleAnimation3.beginTime = [self.breathPointAangleArray[2] floatValue]/(M_PI*2) * self.oneCircleDuration;
        duration = self.oneCircleDuration - scaleAnimation3.beginTime;
        scaleAnimation3.duration = duration;
        //组合动画
        CAAnimationGroup *groupAnnimation = [CAAnimationGroup animation];
        groupAnnimation.duration = self.oneCircleDuration;
        groupAnnimation.animations = @[scaleAnimation1, scaleAnimation2, scaleAnimation3];
        groupAnnimation.repeatCount = repeatCount;
        groupAnnimation.removedOnCompletion = NO;
        //        groupAnnimation.delegate = self;
        [self.layer addAnimation:groupAnnimation forKey:@"groupAnimation"];
        //旋转
        CABasicAnimation *rotateAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        rotateAnimation.fromValue = [NSNumber numberWithFloat:0];
        rotateAnimation.toValue = [NSNumber numberWithFloat:2*M_PI];
        rotateAnimation.fillMode = kCAFillModeForwards;
        rotateAnimation.repeatCount = repeatCount;
        rotateAnimation.removedOnCompletion = NO;
        rotateAnimation.duration = self.oneCircleDuration;
        rotateAnimation.delegate = self;
        [self.moveBallContainerLayer addAnimation:rotateAnimation forKey:@"rotateAnimation"];
        //修改label字
        for (NSInteger i = 0; i<self.breathPointAangleArray.count; i++) {
            CAAnimationGroup *groupAnimation = [self labelGroupAnimationWithIndex:i];
            NSMutableArray *allTextAnimationArray = [NSMutableArray array];
            [allTextAnimationArray addObject:groupAnimation];
            CAAnimationGroup *groupLabelAnnimation = [CAAnimationGroup animation];
            groupLabelAnnimation.duration = self.oneCircleDuration;
            groupLabelAnnimation.animations = allTextAnimationArray;
            groupLabelAnnimation.repeatCount = repeatCount;
            groupLabelAnnimation.fillMode = kCAFillModeForwards;
            groupLabelAnnimation.removedOnCompletion = NO;
            [self.labelLayerArray[i] addAnimation:groupLabelAnnimation forKey:[NSString stringWithFormat:@"groupLabelAnnimation%@",@(i)]];
        }
    }else if (self.breathType == TwoPoint) {
        CABasicAnimation *scaleAnimation1 = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        scaleAnimation1.fromValue = [NSNumber numberWithFloat:0.618];
        scaleAnimation1.toValue = [NSNumber numberWithFloat:1.0];
        scaleAnimation1.fillMode = kCAFillModeForwards;
        CGFloat duration = [self.breathPointAangleArray[1] floatValue]/(M_PI*2) * self.oneCircleDuration;
        scaleAnimation1.duration = duration;
        
        CABasicAnimation *scaleAnimation2 = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        scaleAnimation2.fromValue = [NSNumber numberWithFloat:1.0];
        scaleAnimation2.toValue = [NSNumber numberWithFloat:0.618];
        scaleAnimation2.fillMode = kCAFillModeForwards;
        scaleAnimation2.beginTime = [self.breathPointAangleArray[1] floatValue]/(M_PI*2) * self.oneCircleDuration;
        duration = self.oneCircleDuration - scaleAnimation2.beginTime;
        scaleAnimation2.duration = duration;
        
        //组合动画
        CAAnimationGroup *groupAnnimation = [CAAnimationGroup animation];
        groupAnnimation.duration = self.oneCircleDuration;
        groupAnnimation.animations = @[scaleAnimation1, scaleAnimation2];
        groupAnnimation.repeatCount = repeatCount;
        groupAnnimation.removedOnCompletion = NO;
        //        groupAnnimation.delegate = self;
        [self.layer addAnimation:groupAnnimation forKey:@"groupAnimation"];
        //旋转
        CABasicAnimation *rotateAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        rotateAnimation.fromValue = [NSNumber numberWithFloat:0];
        rotateAnimation.toValue = [NSNumber numberWithFloat:2*M_PI];
        rotateAnimation.fillMode = kCAFillModeForwards;
        rotateAnimation.repeatCount = repeatCount;
        rotateAnimation.removedOnCompletion = NO;
        rotateAnimation.duration = self.oneCircleDuration;
        rotateAnimation.delegate = self;
        [self.moveBallContainerLayer addAnimation:rotateAnimation forKey:@"rotateAnimation"];
        //修改label字
        for (NSInteger i = 0; i<self.breathPointAangleArray.count; i++) {
            CAAnimationGroup *groupAnimation = [self labelGroupAnimationWithIndex:i];
            NSMutableArray *allTextAnimationArray = [NSMutableArray array];
            [allTextAnimationArray addObject:groupAnimation];
            CAAnimationGroup *groupLabelAnnimation = [CAAnimationGroup animation];
            groupLabelAnnimation.duration = self.oneCircleDuration;
            groupLabelAnnimation.animations = allTextAnimationArray;
            groupLabelAnnimation.repeatCount = repeatCount;
            groupLabelAnnimation.fillMode = kCAFillModeForwards;
            groupLabelAnnimation.removedOnCompletion = NO;
            [self.labelLayerArray[i] addAnimation:groupLabelAnnimation forKey:[NSString stringWithFormat:@"groupLabelAnnimation%@",@(i)]];
        }
    }else if (self.breathType == FourPoint) {
        
        CABasicAnimation *scaleAnimation1 = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        scaleAnimation1.fromValue = [NSNumber numberWithFloat:0.618];
        scaleAnimation1.toValue = [NSNumber numberWithFloat:1.0];
        scaleAnimation1.fillMode = kCAFillModeForwards;
        CGFloat duration = [self.breathPointAangleArray[1] floatValue]/(M_PI*2) * self.oneCircleDuration;
        scaleAnimation1.duration = duration;
        
        CABasicAnimation *scaleAnimation2 = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        scaleAnimation2.fromValue = [NSNumber numberWithFloat:1.0];
        scaleAnimation2.toValue = [NSNumber numberWithFloat:1.0];
        scaleAnimation2.fillMode = kCAFillModeForwards;
        scaleAnimation2.beginTime = [self.breathPointAangleArray[1] floatValue]/(M_PI*2) * self.oneCircleDuration;
        duration = [self.breathPointAangleArray[2] floatValue]/(M_PI*2) * self.oneCircleDuration - scaleAnimation2.beginTime;
        scaleAnimation2.duration = duration;
        
        CABasicAnimation *scaleAnimation3 = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        scaleAnimation3.fromValue = [NSNumber numberWithFloat:1.0];
        scaleAnimation3.toValue = [NSNumber numberWithFloat:0.618];
        scaleAnimation3.fillMode = kCAFillModeForwards;
        scaleAnimation3.beginTime = [self.breathPointAangleArray[2] floatValue]/(M_PI*2) * self.oneCircleDuration;
        duration = [self.breathPointAangleArray[3] floatValue]/(M_PI*2) * self.oneCircleDuration - scaleAnimation3.beginTime;
        scaleAnimation3.duration = duration;
        
        CABasicAnimation *scaleAnimation4 = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        scaleAnimation4.fromValue = [NSNumber numberWithFloat:0.618];
        scaleAnimation4.toValue = [NSNumber numberWithFloat:0.618];
        scaleAnimation4.fillMode = kCAFillModeForwards;
        scaleAnimation4.beginTime = [self.breathPointAangleArray[3] floatValue]/(M_PI*2) * self.oneCircleDuration;
        duration = self.oneCircleDuration - scaleAnimation4.beginTime;
        scaleAnimation4.duration = duration;
        
        //组合动画
        CAAnimationGroup *groupAnnimation = [CAAnimationGroup animation];
        groupAnnimation.duration = self.oneCircleDuration;
        groupAnnimation.animations = @[scaleAnimation1, scaleAnimation2, scaleAnimation3, scaleAnimation4];
        groupAnnimation.repeatCount = repeatCount;
        groupAnnimation.removedOnCompletion = NO;
        //        groupAnnimation.delegate = self;
        [self.layer addAnimation:groupAnnimation forKey:@"groupAnimation"];
        //旋转
        CABasicAnimation *rotateAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        rotateAnimation.fromValue = [NSNumber numberWithFloat:0];
        rotateAnimation.toValue = [NSNumber numberWithFloat:2*M_PI];
        rotateAnimation.fillMode = kCAFillModeForwards;
        rotateAnimation.repeatCount = repeatCount;
        rotateAnimation.removedOnCompletion = NO;
        rotateAnimation.duration = self.oneCircleDuration;
        rotateAnimation.delegate = self;
        [self.moveBallContainerLayer addAnimation:rotateAnimation forKey:@"rotateAnimation"];
        //修改label字
        for (NSInteger i = 0; i<self.breathPointAangleArray.count; i++) {
            CAAnimationGroup *groupAnimation = [self labelGroupAnimationWithIndex:i];
            NSMutableArray *allTextAnimationArray = [NSMutableArray array];
            [allTextAnimationArray addObject:groupAnimation];
            CAAnimationGroup *groupLabelAnnimation = [CAAnimationGroup animation];
            groupLabelAnnimation.duration = self.oneCircleDuration;
            groupLabelAnnimation.animations = allTextAnimationArray;
            groupLabelAnnimation.repeatCount = repeatCount;
            groupLabelAnnimation.fillMode = kCAFillModeForwards;
            groupLabelAnnimation.removedOnCompletion = NO;
            [self.labelLayerArray[i] addAnimation:groupLabelAnnimation forKey:[NSString stringWithFormat:@"groupLabelAnnimation%@",@(i)]];
        }
    }
}

-(CAAnimationGroup*)labelGroupAnimationWithIndex:(NSInteger)index{
    CGFloat alphaDurationPercent = 0.1;
    CGFloat beginTime = 0;
    beginTime = [self.breathPointAangleArray[index] floatValue]/(M_PI*2) * self.oneCircleDuration;
    CGFloat duration = 0;
    if (self.breathPointAangleArray.count - 1 == index) {
        duration = self.oneCircleDuration-beginTime;
    }else{
        duration = [self.breathPointAangleArray[index+1] floatValue]/(M_PI*2) * self.oneCircleDuration - beginTime;
    }
    CGFloat beginTimeInGroup = 0;
    NSMutableArray *textAnimationsArray = [NSMutableArray array];

    {
        CABasicAnimation *textOpacityAnimation1 = [CABasicAnimation animationWithKeyPath:@"foregroundColor"];
        textOpacityAnimation1.fromValue = (id)([[UIColor whiteColor]colorWithAlphaComponent:0].CGColor);
        textOpacityAnimation1.toValue = (id)([UIColor whiteColor].CGColor);
        textOpacityAnimation1.fillMode = kCAFillModeForwards;
        textOpacityAnimation1.beginTime = beginTimeInGroup;
        textOpacityAnimation1.duration = duration * alphaDurationPercent;
        CABasicAnimation *textOpacityAnimation2 = [CABasicAnimation animationWithKeyPath:@"foregroundColor"];
        textOpacityAnimation2.fromValue = (id)([UIColor whiteColor].CGColor);
        textOpacityAnimation2.toValue = (id)([UIColor whiteColor].CGColor);
        textOpacityAnimation2.fillMode = kCAFillModeForwards;
        textOpacityAnimation2.beginTime = textOpacityAnimation1.beginTime + textOpacityAnimation1.duration;
        textOpacityAnimation2.duration = duration * (1-alphaDurationPercent*2);
        CABasicAnimation *textOpacityAnimation3 = [CABasicAnimation animationWithKeyPath:@"foregroundColor"];
        textOpacityAnimation3.fromValue = (id)([UIColor whiteColor].CGColor);
        textOpacityAnimation3.toValue = (id)([[UIColor whiteColor]colorWithAlphaComponent:0].CGColor);
        textOpacityAnimation3.fillMode = kCAFillModeForwards;
        textOpacityAnimation3.beginTime = textOpacityAnimation2.beginTime + textOpacityAnimation2.duration;
        textOpacityAnimation3.duration = duration * alphaDurationPercent;
        [textAnimationsArray addObject:textOpacityAnimation1];
        [textAnimationsArray addObject:textOpacityAnimation2];
        [textAnimationsArray addObject:textOpacityAnimation3];
    }
    CAAnimationGroup *groupLabelAnnimation = [CAAnimationGroup animation];
    groupLabelAnnimation.duration = duration;
    groupLabelAnnimation.beginTime = beginTime;
    groupLabelAnnimation.animations = textAnimationsArray;
    groupLabelAnnimation.fillMode = kCAFillModeForwards;
    groupLabelAnnimation.removedOnCompletion = NO;
    return groupLabelAnnimation;
}

-(void)endBreath{
    if (self.isAnimation) {
        self.isAnimation = NO;
        [self.timer invalidate];
        self.timer = nil;
        [self.layer removeAllAnimations];
        [self.moveBallContainerLayer removeAllAnimations];
        [self.moveBallContainerLayer removeObserver:self forKeyPath:@"transform.rotation.z"];
    }
}


@end
