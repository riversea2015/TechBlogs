//
//  HHViewController.m
//  HHYYModelStudy
//
//  Created by hehai on 2019/1/4.
//  Copyright © 2019 hehai. All rights reserved.
//

#import "HHViewController.h"

@interface HHViewController ()

@end

@implementation HHViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleExecutableKey];
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(100, 200, 100, 100)];
    view.backgroundColor = [UIColor redColor];
    [[UIApplication sharedApplication].keyWindow addSubview:view];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UIViewController *vc = [[UIViewController alloc] init];
    vc.view.backgroundColor = [UIColor greenColor];
    [self presentViewController:vc animated:YES completion:nil];
}

@end
