//
//  HHLeaksViewController.m
//  HHMLeaksFinderStudy
//
//  Created by hehai on 2019/1/11.
//  Copyright © 2019 hehai. All rights reserved.
//

#import "HHLeaksViewController.h"

@interface HHLeaksViewController ()

@end

@implementation HHLeaksViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor lightGrayColor];
    
    // 构建循环引用
    [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(scheduledAction) userInfo:nil repeats:YES];
}

- (void)scheduledAction {
    
}

@end
