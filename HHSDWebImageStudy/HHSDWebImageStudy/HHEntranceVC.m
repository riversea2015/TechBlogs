//
//  HHEntranceVC.m
//  HHSDWebImageStudy
//
//  Created by hehai on 2018/7/17.
//  Copyright © 2018 hehai. All rights reserved.
//

#import "HHEntranceVC.h"
#import "HHImageViewController.h"
#import "HHWebImageViewController.h"

static const NSInteger HHBtnTagBase = 20180717;

@interface HHEntranceVC ()

@end

@implementation HHEntranceVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSStringFromClass([self class]);
    
    for (int i = 0; i < 3; i++) {
        [self createBtnWithTag:i title:nil];
    }
    [self createBtnWithTag:4 title:@"自己实现的缓存示例"];
    
    UILabel *warnLab = [[UILabel alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY(self.view.frame)-150, self.view.bounds.size.width-20, 100)];
    warnLab.textColor = [UIColor redColor];
    warnLab.text = @"注意：请勿直接点击 Demo 中的方案 A，可以先点击 B 或 C，然后再点击 A，否则可能导致 B 和 C 的动图变成静态图，此问题暂未解决 😓😓😓";
    warnLab.numberOfLines = 3;
    [self.view addSubview:warnLab];
}

- (UIButton *)createBtnWithTag:(NSInteger)tag title:(NSString *)strTitle {
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(10, 100+(100+10)*tag, 200, 100);
    btn.tag = tag + HHBtnTagBase;
    btn.backgroundColor = (tag % 2 == 1) ? [UIColor greenColor] : [UIColor redColor];
    if (strTitle) {
        [btn setTitle:strTitle forState:UIControlStateNormal];
    } else {
        [btn setTitle:[NSString stringWithFormat:@"方案 <%ld>", tag+1] forState:UIControlStateNormal];
    }
    [btn addTarget:self action:@selector(clickBtn:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:btn];
    
    return btn;
}

- (void)clickBtn:(UIButton *)sender {
    
    if (sender.tag == HHBtnTagBase + 4) {
        HHWebImageViewController *vc = [HHWebImageViewController new];
        [self.navigationController pushViewController:vc animated:YES];
        return;
    }
    
    HHImageViewController *vc = [HHImageViewController new];
    vc.type = sender.tag-HHBtnTagBase;
    [self.navigationController pushViewController:vc animated:YES];
}

@end
