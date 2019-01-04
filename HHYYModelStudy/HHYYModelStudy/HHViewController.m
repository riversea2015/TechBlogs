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
    
    
}


@end
