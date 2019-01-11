//
//  ViewController.m
//  HHMLeaksFinderStudy
//
//  Created by hehai on 2019/1/8.
//  Copyright © 2019 hehai. All rights reserved.
//

#import "ViewController.h"
#import "HHLeaksViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    HHLeaksViewController *leaksVC = [[HHLeaksViewController alloc] init];
    [self.navigationController pushViewController:leaksVC animated:YES];
}

@end
