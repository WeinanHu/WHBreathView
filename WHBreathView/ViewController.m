//
//  ViewController.m
//  WHBreathView
//
//  Created by huweinan on 2019/10/25.
//  Copyright © 2019 hwn. All rights reserved.
//

#import "ViewController.h"
#import "WHBreathView.h"

@interface ViewController ()


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor lightGrayColor];
    
    WHBreathView *breathView = [[WHBreathView alloc]initWithFrame:CGRectMake(20, 100, 300, 300)];
    breathView.breathType = FourPoint;
    [self.view addSubview:breathView];
    [breathView startBreath];
    
}


@end
