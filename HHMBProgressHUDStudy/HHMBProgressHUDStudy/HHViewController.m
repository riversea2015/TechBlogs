//
//  HHViewController.m
//  HHMBProgressHUDStudy
//
//  Created by hehai on 2018/12/14.
//  Copyright © 2018 hehai. All rights reserved.
//

#import "HHViewController.h"
#import <MBProgressHUD/MBProgressHUD.h>

@interface HHViewController ()

@end

@implementation HHViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleExecutableKey];
    
}

@end
