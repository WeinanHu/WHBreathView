//
//  WHBreathView.h
//  WHBreathView
//
//  Created by huweinan on 2019/10/25.
//  Copyright © 2019 hwn. All rights reserved.
//


#import <UIKit/UIKit.h>
typedef NS_ENUM(NSInteger, BreathType) {
    ThreePoint,
    TwoPoint,
    FourPoint
};
NS_ASSUME_NONNULL_BEGIN

@interface WHBreathView : UIView
-(instancetype)initWithFrame:(CGRect)frame ;

//设置类型,默认TwoPoint
@property(nonatomic,assign) BreathType breathType;
//设置文字，默认空
@property(nonatomic,strong) NSArray<NSString*>* breathWordTipStringArray;
//点的角度，默认均分角度
@property(nonatomic,strong) NSArray<NSNumber*>* breathPointAangleArray;
//颜色数组,默认粉色 0xe71995 -> 0xd611e7
@property(nonatomic,strong) NSArray<UIColor*>* breathViewColorArray;
//运动小球颜色,默认白色
@property(nonatomic,strong) UIColor* moveBallColor;
//静止小球颜色,默认蓝色 0x00a0e9
@property(nonatomic,strong) UIColor* staticBallColor;
//滚一圈时间(默认8秒)
@property(nonatomic,assign) CGFloat oneCircleDuration;

//开始呼吸动画,开始呼吸后，不要再修改属性
-(void)startBreath;

@end

NS_ASSUME_NONNULL_END
